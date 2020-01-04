
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
  Call_AcceptInvitation_601979 = ref object of OpenApiRestCall_601389
proc url_AcceptInvitation_601981(protocol: Scheme; host: string; base: string;
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

proc validate_AcceptInvitation_601980(path: JsonNode; query: JsonNode;
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
  var valid_601982 = header.getOrDefault("X-Amz-Signature")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-Signature", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-Content-Sha256", valid_601983
  var valid_601984 = header.getOrDefault("X-Amz-Date")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "X-Amz-Date", valid_601984
  var valid_601985 = header.getOrDefault("X-Amz-Credential")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "X-Amz-Credential", valid_601985
  var valid_601986 = header.getOrDefault("X-Amz-Security-Token")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "X-Amz-Security-Token", valid_601986
  var valid_601987 = header.getOrDefault("X-Amz-Algorithm")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Algorithm", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-SignedHeaders", valid_601988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601990: Call_AcceptInvitation_601979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ## 
  let valid = call_601990.validator(path, query, header, formData, body)
  let scheme = call_601990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601990.url(scheme.get, call_601990.host, call_601990.base,
                         call_601990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601990, url, valid)

proc call*(call_601991: Call_AcceptInvitation_601979; body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ##   body: JObject (required)
  var body_601992 = newJObject()
  if body != nil:
    body_601992 = body
  result = call_601991.call(nil, nil, nil, nil, body_601992)

var acceptInvitation* = Call_AcceptInvitation_601979(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_AcceptInvitation_601980, base: "/",
    url: url_AcceptInvitation_601981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_601727 = ref object of OpenApiRestCall_601389
proc url_GetMasterAccount_601729(protocol: Scheme; host: string; base: string;
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

proc validate_GetMasterAccount_601728(path: JsonNode; query: JsonNode;
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
  var valid_601841 = header.getOrDefault("X-Amz-Signature")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Signature", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Content-Sha256", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Date")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Date", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Credential")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Credential", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Security-Token")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Security-Token", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Algorithm")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Algorithm", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-SignedHeaders", valid_601847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601870: Call_GetMasterAccount_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the Security Hub master account to the current member account. 
  ## 
  let valid = call_601870.validator(path, query, header, formData, body)
  let scheme = call_601870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601870.url(scheme.get, call_601870.host, call_601870.base,
                         call_601870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601870, url, valid)

proc call*(call_601941: Call_GetMasterAccount_601727): Recallable =
  ## getMasterAccount
  ## Provides the details for the Security Hub master account to the current member account. 
  result = call_601941.call(nil, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_601727(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_GetMasterAccount_601728, base: "/",
    url: url_GetMasterAccount_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisableStandards_601994 = ref object of OpenApiRestCall_601389
proc url_BatchDisableStandards_601996(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDisableStandards_601995(path: JsonNode; query: JsonNode;
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
  var valid_601997 = header.getOrDefault("X-Amz-Signature")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Signature", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Content-Sha256", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-Date")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Date", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Credential")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Credential", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Security-Token")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Security-Token", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Algorithm")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Algorithm", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-SignedHeaders", valid_602003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602005: Call_BatchDisableStandards_601994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_602005.validator(path, query, header, formData, body)
  let scheme = call_602005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602005.url(scheme.get, call_602005.host, call_602005.base,
                         call_602005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602005, url, valid)

proc call*(call_602006: Call_BatchDisableStandards_601994; body: JsonNode): Recallable =
  ## batchDisableStandards
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_602007 = newJObject()
  if body != nil:
    body_602007 = body
  result = call_602006.call(nil, nil, nil, nil, body_602007)

var batchDisableStandards* = Call_BatchDisableStandards_601994(
    name: "batchDisableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/deregister",
    validator: validate_BatchDisableStandards_601995, base: "/",
    url: url_BatchDisableStandards_601996, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchEnableStandards_602008 = ref object of OpenApiRestCall_601389
proc url_BatchEnableStandards_602010(protocol: Scheme; host: string; base: string;
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

proc validate_BatchEnableStandards_602009(path: JsonNode; query: JsonNode;
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
  var valid_602011 = header.getOrDefault("X-Amz-Signature")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Signature", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Content-Sha256", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Date")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Date", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Credential")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Credential", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Security-Token")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Security-Token", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Algorithm")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Algorithm", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-SignedHeaders", valid_602017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602019: Call_BatchEnableStandards_602008; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_602019.validator(path, query, header, formData, body)
  let scheme = call_602019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602019.url(scheme.get, call_602019.host, call_602019.base,
                         call_602019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602019, url, valid)

proc call*(call_602020: Call_BatchEnableStandards_602008; body: JsonNode): Recallable =
  ## batchEnableStandards
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_602021 = newJObject()
  if body != nil:
    body_602021 = body
  result = call_602020.call(nil, nil, nil, nil, body_602021)

var batchEnableStandards* = Call_BatchEnableStandards_602008(
    name: "batchEnableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/register",
    validator: validate_BatchEnableStandards_602009, base: "/",
    url: url_BatchEnableStandards_602010, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchImportFindings_602022 = ref object of OpenApiRestCall_601389
proc url_BatchImportFindings_602024(protocol: Scheme; host: string; base: string;
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

proc validate_BatchImportFindings_602023(path: JsonNode; query: JsonNode;
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
  var valid_602025 = header.getOrDefault("X-Amz-Signature")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Signature", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Content-Sha256", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Date")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Date", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Credential")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Credential", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Security-Token")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Security-Token", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Algorithm")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Algorithm", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-SignedHeaders", valid_602031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602033: Call_BatchImportFindings_602022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ## 
  let valid = call_602033.validator(path, query, header, formData, body)
  let scheme = call_602033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602033.url(scheme.get, call_602033.host, call_602033.base,
                         call_602033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602033, url, valid)

proc call*(call_602034: Call_BatchImportFindings_602022; body: JsonNode): Recallable =
  ## batchImportFindings
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ##   body: JObject (required)
  var body_602035 = newJObject()
  if body != nil:
    body_602035 = body
  result = call_602034.call(nil, nil, nil, nil, body_602035)

var batchImportFindings* = Call_BatchImportFindings_602022(
    name: "batchImportFindings", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/findings/import",
    validator: validate_BatchImportFindings_602023, base: "/",
    url: url_BatchImportFindings_602024, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActionTarget_602036 = ref object of OpenApiRestCall_601389
proc url_CreateActionTarget_602038(protocol: Scheme; host: string; base: string;
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

proc validate_CreateActionTarget_602037(path: JsonNode; query: JsonNode;
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
  var valid_602039 = header.getOrDefault("X-Amz-Signature")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Signature", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Content-Sha256", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Date")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Date", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Credential")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Credential", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Security-Token")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Security-Token", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Algorithm")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Algorithm", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-SignedHeaders", valid_602045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602047: Call_CreateActionTarget_602036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ## 
  let valid = call_602047.validator(path, query, header, formData, body)
  let scheme = call_602047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602047.url(scheme.get, call_602047.host, call_602047.base,
                         call_602047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602047, url, valid)

proc call*(call_602048: Call_CreateActionTarget_602036; body: JsonNode): Recallable =
  ## createActionTarget
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ##   body: JObject (required)
  var body_602049 = newJObject()
  if body != nil:
    body_602049 = body
  result = call_602048.call(nil, nil, nil, nil, body_602049)

var createActionTarget* = Call_CreateActionTarget_602036(
    name: "createActionTarget", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets",
    validator: validate_CreateActionTarget_602037, base: "/",
    url: url_CreateActionTarget_602038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInsight_602050 = ref object of OpenApiRestCall_601389
proc url_CreateInsight_602052(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInsight_602051(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602053 = header.getOrDefault("X-Amz-Signature")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Signature", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Content-Sha256", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Date")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Date", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Credential")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Credential", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Security-Token")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Security-Token", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Algorithm")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Algorithm", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-SignedHeaders", valid_602059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602061: Call_CreateInsight_602050; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ## 
  let valid = call_602061.validator(path, query, header, formData, body)
  let scheme = call_602061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602061.url(scheme.get, call_602061.host, call_602061.base,
                         call_602061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602061, url, valid)

proc call*(call_602062: Call_CreateInsight_602050; body: JsonNode): Recallable =
  ## createInsight
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ##   body: JObject (required)
  var body_602063 = newJObject()
  if body != nil:
    body_602063 = body
  result = call_602062.call(nil, nil, nil, nil, body_602063)

var createInsight* = Call_CreateInsight_602050(name: "createInsight",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights", validator: validate_CreateInsight_602051, base: "/",
    url: url_CreateInsight_602052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_602081 = ref object of OpenApiRestCall_601389
proc url_CreateMembers_602083(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMembers_602082(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602084 = header.getOrDefault("X-Amz-Signature")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Signature", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Content-Sha256", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Date")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Date", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Credential")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Credential", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Security-Token")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Security-Token", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Algorithm")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Algorithm", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-SignedHeaders", valid_602090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602092: Call_CreateMembers_602081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ## 
  let valid = call_602092.validator(path, query, header, formData, body)
  let scheme = call_602092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602092.url(scheme.get, call_602092.host, call_602092.base,
                         call_602092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602092, url, valid)

proc call*(call_602093: Call_CreateMembers_602081; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ##   body: JObject (required)
  var body_602094 = newJObject()
  if body != nil:
    body_602094 = body
  result = call_602093.call(nil, nil, nil, nil, body_602094)

var createMembers* = Call_CreateMembers_602081(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/members",
    validator: validate_CreateMembers_602082, base: "/", url: url_CreateMembers_602083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_602064 = ref object of OpenApiRestCall_601389
proc url_ListMembers_602066(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_602065(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602067 = query.getOrDefault("MaxResults")
  valid_602067 = validateParameter(valid_602067, JInt, required = false, default = nil)
  if valid_602067 != nil:
    section.add "MaxResults", valid_602067
  var valid_602068 = query.getOrDefault("NextToken")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "NextToken", valid_602068
  var valid_602069 = query.getOrDefault("OnlyAssociated")
  valid_602069 = validateParameter(valid_602069, JBool, required = false, default = nil)
  if valid_602069 != nil:
    section.add "OnlyAssociated", valid_602069
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
  var valid_602070 = header.getOrDefault("X-Amz-Signature")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Signature", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Content-Sha256", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Date")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Date", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Credential")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Credential", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Security-Token")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Security-Token", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Algorithm")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Algorithm", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-SignedHeaders", valid_602076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602077: Call_ListMembers_602064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  let valid = call_602077.validator(path, query, header, formData, body)
  let scheme = call_602077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602077.url(scheme.get, call_602077.host, call_602077.base,
                         call_602077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602077, url, valid)

proc call*(call_602078: Call_ListMembers_602064; MaxResults: int = 0;
          NextToken: string = ""; OnlyAssociated: bool = false): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current Security Hub master account.
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  ##   NextToken: string
  ##            : Paginates results. Set the value of this parameter to <code>NULL</code> on your first call to the <code>ListMembers</code> operation. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>nextToken</code> from the previous response to continue listing data. 
  ##   OnlyAssociated: bool
  ##                 : Specifies which member accounts the response includes based on their relationship status with the master account. The default value is <code>TRUE</code>. If <code>onlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>. If <code>onlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. 
  var query_602079 = newJObject()
  add(query_602079, "MaxResults", newJInt(MaxResults))
  add(query_602079, "NextToken", newJString(NextToken))
  add(query_602079, "OnlyAssociated", newJBool(OnlyAssociated))
  result = call_602078.call(nil, query_602079, nil, nil, nil)

var listMembers* = Call_ListMembers_602064(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/members",
                                        validator: validate_ListMembers_602065,
                                        base: "/", url: url_ListMembers_602066,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_602095 = ref object of OpenApiRestCall_601389
proc url_DeclineInvitations_602097(protocol: Scheme; host: string; base: string;
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

proc validate_DeclineInvitations_602096(path: JsonNode; query: JsonNode;
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
  var valid_602098 = header.getOrDefault("X-Amz-Signature")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Signature", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Content-Sha256", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Date")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Date", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Credential")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Credential", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Security-Token")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Security-Token", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Algorithm")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Algorithm", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-SignedHeaders", valid_602104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602106: Call_DeclineInvitations_602095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations to become a member account.
  ## 
  let valid = call_602106.validator(path, query, header, formData, body)
  let scheme = call_602106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602106.url(scheme.get, call_602106.host, call_602106.base,
                         call_602106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602106, url, valid)

proc call*(call_602107: Call_DeclineInvitations_602095; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations to become a member account.
  ##   body: JObject (required)
  var body_602108 = newJObject()
  if body != nil:
    body_602108 = body
  result = call_602107.call(nil, nil, nil, nil, body_602108)

var declineInvitations* = Call_DeclineInvitations_602095(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/invitations/decline",
    validator: validate_DeclineInvitations_602096, base: "/",
    url: url_DeclineInvitations_602097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateActionTarget_602137 = ref object of OpenApiRestCall_601389
proc url_UpdateActionTarget_602139(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateActionTarget_602138(path: JsonNode; query: JsonNode;
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
  var valid_602140 = path.getOrDefault("ActionTargetArn")
  valid_602140 = validateParameter(valid_602140, JString, required = true,
                                 default = nil)
  if valid_602140 != nil:
    section.add "ActionTargetArn", valid_602140
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
  var valid_602141 = header.getOrDefault("X-Amz-Signature")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Signature", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Content-Sha256", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Date")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Date", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Credential")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Credential", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Security-Token")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Security-Token", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Algorithm")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Algorithm", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-SignedHeaders", valid_602147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602149: Call_UpdateActionTarget_602137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name and description of a custom action target in Security Hub.
  ## 
  let valid = call_602149.validator(path, query, header, formData, body)
  let scheme = call_602149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602149.url(scheme.get, call_602149.host, call_602149.base,
                         call_602149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602149, url, valid)

proc call*(call_602150: Call_UpdateActionTarget_602137; ActionTargetArn: string;
          body: JsonNode): Recallable =
  ## updateActionTarget
  ## Updates the name and description of a custom action target in Security Hub.
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to update.
  ##   body: JObject (required)
  var path_602151 = newJObject()
  var body_602152 = newJObject()
  add(path_602151, "ActionTargetArn", newJString(ActionTargetArn))
  if body != nil:
    body_602152 = body
  result = call_602150.call(path_602151, nil, nil, nil, body_602152)

var updateActionTarget* = Call_UpdateActionTarget_602137(
    name: "updateActionTarget", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_UpdateActionTarget_602138, base: "/",
    url: url_UpdateActionTarget_602139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActionTarget_602109 = ref object of OpenApiRestCall_601389
proc url_DeleteActionTarget_602111(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteActionTarget_602110(path: JsonNode; query: JsonNode;
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
  var valid_602126 = path.getOrDefault("ActionTargetArn")
  valid_602126 = validateParameter(valid_602126, JString, required = true,
                                 default = nil)
  if valid_602126 != nil:
    section.add "ActionTargetArn", valid_602126
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
  var valid_602127 = header.getOrDefault("X-Amz-Signature")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Signature", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Content-Sha256", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Date")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Date", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Credential")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Credential", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Security-Token")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Security-Token", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Algorithm")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Algorithm", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-SignedHeaders", valid_602133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602134: Call_DeleteActionTarget_602109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ## 
  let valid = call_602134.validator(path, query, header, formData, body)
  let scheme = call_602134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602134.url(scheme.get, call_602134.host, call_602134.base,
                         call_602134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602134, url, valid)

proc call*(call_602135: Call_DeleteActionTarget_602109; ActionTargetArn: string): Recallable =
  ## deleteActionTarget
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to delete.
  var path_602136 = newJObject()
  add(path_602136, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_602135.call(path_602136, nil, nil, nil, nil)

var deleteActionTarget* = Call_DeleteActionTarget_602109(
    name: "deleteActionTarget", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_DeleteActionTarget_602110, base: "/",
    url: url_DeleteActionTarget_602111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInsight_602167 = ref object of OpenApiRestCall_601389
proc url_UpdateInsight_602169(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInsight_602168(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602170 = path.getOrDefault("InsightArn")
  valid_602170 = validateParameter(valid_602170, JString, required = true,
                                 default = nil)
  if valid_602170 != nil:
    section.add "InsightArn", valid_602170
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
  var valid_602171 = header.getOrDefault("X-Amz-Signature")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Signature", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Content-Sha256", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Date")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Date", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Credential")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Credential", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Security-Token")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Security-Token", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Algorithm")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Algorithm", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-SignedHeaders", valid_602177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602179: Call_UpdateInsight_602167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_602179.validator(path, query, header, formData, body)
  let scheme = call_602179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602179.url(scheme.get, call_602179.host, call_602179.base,
                         call_602179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602179, url, valid)

proc call*(call_602180: Call_UpdateInsight_602167; InsightArn: string; body: JsonNode): Recallable =
  ## updateInsight
  ## Updates the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight that you want to update.
  ##   body: JObject (required)
  var path_602181 = newJObject()
  var body_602182 = newJObject()
  add(path_602181, "InsightArn", newJString(InsightArn))
  if body != nil:
    body_602182 = body
  result = call_602180.call(path_602181, nil, nil, nil, body_602182)

var updateInsight* = Call_UpdateInsight_602167(name: "updateInsight",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_UpdateInsight_602168,
    base: "/", url: url_UpdateInsight_602169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInsight_602153 = ref object of OpenApiRestCall_601389
proc url_DeleteInsight_602155(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInsight_602154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602156 = path.getOrDefault("InsightArn")
  valid_602156 = validateParameter(valid_602156, JString, required = true,
                                 default = nil)
  if valid_602156 != nil:
    section.add "InsightArn", valid_602156
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
  var valid_602157 = header.getOrDefault("X-Amz-Signature")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Signature", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Content-Sha256", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Date")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Date", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Credential")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Credential", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Security-Token")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Security-Token", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Algorithm")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Algorithm", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-SignedHeaders", valid_602163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602164: Call_DeleteInsight_602153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ## 
  let valid = call_602164.validator(path, query, header, formData, body)
  let scheme = call_602164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602164.url(scheme.get, call_602164.host, call_602164.base,
                         call_602164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602164, url, valid)

proc call*(call_602165: Call_DeleteInsight_602153; InsightArn: string): Recallable =
  ## deleteInsight
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight to delete.
  var path_602166 = newJObject()
  add(path_602166, "InsightArn", newJString(InsightArn))
  result = call_602165.call(path_602166, nil, nil, nil, nil)

var deleteInsight* = Call_DeleteInsight_602153(name: "deleteInsight",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_DeleteInsight_602154,
    base: "/", url: url_DeleteInsight_602155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_602183 = ref object of OpenApiRestCall_601389
proc url_DeleteInvitations_602185(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInvitations_602184(path: JsonNode; query: JsonNode;
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
  var valid_602186 = header.getOrDefault("X-Amz-Signature")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Signature", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Content-Sha256", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Date")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Date", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Credential")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Credential", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Security-Token")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Security-Token", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Algorithm")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Algorithm", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-SignedHeaders", valid_602192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602194: Call_DeleteInvitations_602183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations received by the AWS account to become a member account.
  ## 
  let valid = call_602194.validator(path, query, header, formData, body)
  let scheme = call_602194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602194.url(scheme.get, call_602194.host, call_602194.base,
                         call_602194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602194, url, valid)

proc call*(call_602195: Call_DeleteInvitations_602183; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations received by the AWS account to become a member account.
  ##   body: JObject (required)
  var body_602196 = newJObject()
  if body != nil:
    body_602196 = body
  result = call_602195.call(nil, nil, nil, nil, body_602196)

var deleteInvitations* = Call_DeleteInvitations_602183(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/invitations/delete", validator: validate_DeleteInvitations_602184,
    base: "/", url: url_DeleteInvitations_602185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_602197 = ref object of OpenApiRestCall_601389
proc url_DeleteMembers_602199(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMembers_602198(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602200 = header.getOrDefault("X-Amz-Signature")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Signature", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Content-Sha256", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Date")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Date", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Credential")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Credential", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Security-Token")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Security-Token", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Algorithm")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Algorithm", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-SignedHeaders", valid_602206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602208: Call_DeleteMembers_602197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified member accounts from Security Hub.
  ## 
  let valid = call_602208.validator(path, query, header, formData, body)
  let scheme = call_602208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602208.url(scheme.get, call_602208.host, call_602208.base,
                         call_602208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602208, url, valid)

proc call*(call_602209: Call_DeleteMembers_602197; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes the specified member accounts from Security Hub.
  ##   body: JObject (required)
  var body_602210 = newJObject()
  if body != nil:
    body_602210 = body
  result = call_602209.call(nil, nil, nil, nil, body_602210)

var deleteMembers* = Call_DeleteMembers_602197(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/delete", validator: validate_DeleteMembers_602198, base: "/",
    url: url_DeleteMembers_602199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActionTargets_602211 = ref object of OpenApiRestCall_601389
proc url_DescribeActionTargets_602213(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeActionTargets_602212(path: JsonNode; query: JsonNode;
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
  var valid_602214 = query.getOrDefault("MaxResults")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "MaxResults", valid_602214
  var valid_602215 = query.getOrDefault("NextToken")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "NextToken", valid_602215
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
  var valid_602216 = header.getOrDefault("X-Amz-Signature")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Signature", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Content-Sha256", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Date")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Date", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Credential")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Credential", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Security-Token")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Security-Token", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Algorithm")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Algorithm", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-SignedHeaders", valid_602222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602224: Call_DescribeActionTargets_602211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the custom action targets in Security Hub in your account.
  ## 
  let valid = call_602224.validator(path, query, header, formData, body)
  let scheme = call_602224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602224.url(scheme.get, call_602224.host, call_602224.base,
                         call_602224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602224, url, valid)

proc call*(call_602225: Call_DescribeActionTargets_602211; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeActionTargets
  ## Returns a list of the custom action targets in Security Hub in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602226 = newJObject()
  var body_602227 = newJObject()
  add(query_602226, "MaxResults", newJString(MaxResults))
  add(query_602226, "NextToken", newJString(NextToken))
  if body != nil:
    body_602227 = body
  result = call_602225.call(nil, query_602226, nil, nil, body_602227)

var describeActionTargets* = Call_DescribeActionTargets_602211(
    name: "describeActionTargets", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets/get",
    validator: validate_DescribeActionTargets_602212, base: "/",
    url: url_DescribeActionTargets_602213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSecurityHub_602242 = ref object of OpenApiRestCall_601389
proc url_EnableSecurityHub_602244(protocol: Scheme; host: string; base: string;
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

proc validate_EnableSecurityHub_602243(path: JsonNode; query: JsonNode;
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
  var valid_602245 = header.getOrDefault("X-Amz-Signature")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Signature", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Content-Sha256", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Date")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Date", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Credential")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Credential", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Security-Token")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Security-Token", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Algorithm")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Algorithm", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-SignedHeaders", valid_602251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602253: Call_EnableSecurityHub_602242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. Enabling Security Hub also enables the CIS AWS Foundations standard. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ## 
  let valid = call_602253.validator(path, query, header, formData, body)
  let scheme = call_602253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602253.url(scheme.get, call_602253.host, call_602253.base,
                         call_602253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602253, url, valid)

proc call*(call_602254: Call_EnableSecurityHub_602242; body: JsonNode): Recallable =
  ## enableSecurityHub
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. Enabling Security Hub also enables the CIS AWS Foundations standard. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_602255 = newJObject()
  if body != nil:
    body_602255 = body
  result = call_602254.call(nil, nil, nil, nil, body_602255)

var enableSecurityHub* = Call_EnableSecurityHub_602242(name: "enableSecurityHub",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/accounts", validator: validate_EnableSecurityHub_602243, base: "/",
    url: url_EnableSecurityHub_602244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHub_602228 = ref object of OpenApiRestCall_601389
proc url_DescribeHub_602230(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeHub_602229(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602231 = query.getOrDefault("HubArn")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "HubArn", valid_602231
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
  var valid_602232 = header.getOrDefault("X-Amz-Signature")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Signature", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Content-Sha256", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Date")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Date", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Credential")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Credential", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Security-Token")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Security-Token", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Algorithm")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Algorithm", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-SignedHeaders", valid_602238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602239: Call_DescribeHub_602228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ## 
  let valid = call_602239.validator(path, query, header, formData, body)
  let scheme = call_602239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602239.url(scheme.get, call_602239.host, call_602239.base,
                         call_602239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602239, url, valid)

proc call*(call_602240: Call_DescribeHub_602228; HubArn: string = ""): Recallable =
  ## describeHub
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ##   HubArn: string
  ##         : The ARN of the Hub resource to retrieve.
  var query_602241 = newJObject()
  add(query_602241, "HubArn", newJString(HubArn))
  result = call_602240.call(nil, query_602241, nil, nil, nil)

var describeHub* = Call_DescribeHub_602228(name: "describeHub",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/accounts",
                                        validator: validate_DescribeHub_602229,
                                        base: "/", url: url_DescribeHub_602230,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSecurityHub_602256 = ref object of OpenApiRestCall_601389
proc url_DisableSecurityHub_602258(protocol: Scheme; host: string; base: string;
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

proc validate_DisableSecurityHub_602257(path: JsonNode; query: JsonNode;
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
  var valid_602259 = header.getOrDefault("X-Amz-Signature")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Signature", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Content-Sha256", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Date")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Date", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Credential")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Credential", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Security-Token")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Security-Token", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Algorithm")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Algorithm", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-SignedHeaders", valid_602265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602266: Call_DisableSecurityHub_602256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  ## 
  let valid = call_602266.validator(path, query, header, formData, body)
  let scheme = call_602266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602266.url(scheme.get, call_602266.host, call_602266.base,
                         call_602266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602266, url, valid)

proc call*(call_602267: Call_DisableSecurityHub_602256): Recallable =
  ## disableSecurityHub
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  result = call_602267.call(nil, nil, nil, nil, nil)

var disableSecurityHub* = Call_DisableSecurityHub_602256(
    name: "disableSecurityHub", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_DisableSecurityHub_602257, base: "/",
    url: url_DisableSecurityHub_602258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProducts_602268 = ref object of OpenApiRestCall_601389
proc url_DescribeProducts_602270(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProducts_602269(path: JsonNode; query: JsonNode;
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
  var valid_602271 = query.getOrDefault("MaxResults")
  valid_602271 = validateParameter(valid_602271, JInt, required = false, default = nil)
  if valid_602271 != nil:
    section.add "MaxResults", valid_602271
  var valid_602272 = query.getOrDefault("NextToken")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "NextToken", valid_602272
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
  var valid_602273 = header.getOrDefault("X-Amz-Signature")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Signature", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Content-Sha256", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Date")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Date", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Credential")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Credential", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Security-Token")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Security-Token", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Algorithm")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Algorithm", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-SignedHeaders", valid_602279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602280: Call_DescribeProducts_602268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ## 
  let valid = call_602280.validator(path, query, header, formData, body)
  let scheme = call_602280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602280.url(scheme.get, call_602280.host, call_602280.base,
                         call_602280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602280, url, valid)

proc call*(call_602281: Call_DescribeProducts_602268; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## describeProducts
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ##   MaxResults: int
  ##             : The maximum number of results to return.
  ##   NextToken: string
  ##            : The token that is required for pagination.
  var query_602282 = newJObject()
  add(query_602282, "MaxResults", newJInt(MaxResults))
  add(query_602282, "NextToken", newJString(NextToken))
  result = call_602281.call(nil, query_602282, nil, nil, nil)

var describeProducts* = Call_DescribeProducts_602268(name: "describeProducts",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/products",
    validator: validate_DescribeProducts_602269, base: "/",
    url: url_DescribeProducts_602270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableImportFindingsForProduct_602283 = ref object of OpenApiRestCall_601389
proc url_DisableImportFindingsForProduct_602285(protocol: Scheme; host: string;
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

proc validate_DisableImportFindingsForProduct_602284(path: JsonNode;
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
  var valid_602286 = path.getOrDefault("ProductSubscriptionArn")
  valid_602286 = validateParameter(valid_602286, JString, required = true,
                                 default = nil)
  if valid_602286 != nil:
    section.add "ProductSubscriptionArn", valid_602286
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
  var valid_602287 = header.getOrDefault("X-Amz-Signature")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Signature", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Content-Sha256", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Date")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Date", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Credential")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Credential", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Security-Token")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Security-Token", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Algorithm")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Algorithm", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-SignedHeaders", valid_602293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602294: Call_DisableImportFindingsForProduct_602283;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ## 
  let valid = call_602294.validator(path, query, header, formData, body)
  let scheme = call_602294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602294.url(scheme.get, call_602294.host, call_602294.base,
                         call_602294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602294, url, valid)

proc call*(call_602295: Call_DisableImportFindingsForProduct_602283;
          ProductSubscriptionArn: string): Recallable =
  ## disableImportFindingsForProduct
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ##   ProductSubscriptionArn: string (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  var path_602296 = newJObject()
  add(path_602296, "ProductSubscriptionArn", newJString(ProductSubscriptionArn))
  result = call_602295.call(path_602296, nil, nil, nil, nil)

var disableImportFindingsForProduct* = Call_DisableImportFindingsForProduct_602283(
    name: "disableImportFindingsForProduct", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com",
    route: "/productSubscriptions/{ProductSubscriptionArn}",
    validator: validate_DisableImportFindingsForProduct_602284, base: "/",
    url: url_DisableImportFindingsForProduct_602285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_602297 = ref object of OpenApiRestCall_601389
proc url_DisassociateFromMasterAccount_602299(protocol: Scheme; host: string;
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

proc validate_DisassociateFromMasterAccount_602298(path: JsonNode; query: JsonNode;
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

proc call*(call_602307: Call_DisassociateFromMasterAccount_602297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current Security Hub member account from the associated master account.
  ## 
  let valid = call_602307.validator(path, query, header, formData, body)
  let scheme = call_602307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602307.url(scheme.get, call_602307.host, call_602307.base,
                         call_602307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602307, url, valid)

proc call*(call_602308: Call_DisassociateFromMasterAccount_602297): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current Security Hub member account from the associated master account.
  result = call_602308.call(nil, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_602297(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_602298, base: "/",
    url: url_DisassociateFromMasterAccount_602299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_602309 = ref object of OpenApiRestCall_601389
proc url_DisassociateMembers_602311(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateMembers_602310(path: JsonNode; query: JsonNode;
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
  var valid_602312 = header.getOrDefault("X-Amz-Signature")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Signature", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Content-Sha256", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Date")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Date", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Credential")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Credential", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Security-Token")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Security-Token", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Algorithm")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Algorithm", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-SignedHeaders", valid_602318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602320: Call_DisassociateMembers_602309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified member accounts from the associated master account.
  ## 
  let valid = call_602320.validator(path, query, header, formData, body)
  let scheme = call_602320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602320.url(scheme.get, call_602320.host, call_602320.base,
                         call_602320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602320, url, valid)

proc call*(call_602321: Call_DisassociateMembers_602309; body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates the specified member accounts from the associated master account.
  ##   body: JObject (required)
  var body_602322 = newJObject()
  if body != nil:
    body_602322 = body
  result = call_602321.call(nil, nil, nil, nil, body_602322)

var disassociateMembers* = Call_DisassociateMembers_602309(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/members/disassociate",
    validator: validate_DisassociateMembers_602310, base: "/",
    url: url_DisassociateMembers_602311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableImportFindingsForProduct_602338 = ref object of OpenApiRestCall_601389
proc url_EnableImportFindingsForProduct_602340(protocol: Scheme; host: string;
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

proc validate_EnableImportFindingsForProduct_602339(path: JsonNode;
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
  var valid_602341 = header.getOrDefault("X-Amz-Signature")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Signature", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Content-Sha256", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-Date")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-Date", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Credential")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Credential", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Security-Token")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Security-Token", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Algorithm")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Algorithm", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-SignedHeaders", valid_602347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602349: Call_EnableImportFindingsForProduct_602338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ## 
  let valid = call_602349.validator(path, query, header, formData, body)
  let scheme = call_602349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602349.url(scheme.get, call_602349.host, call_602349.base,
                         call_602349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602349, url, valid)

proc call*(call_602350: Call_EnableImportFindingsForProduct_602338; body: JsonNode): Recallable =
  ## enableImportFindingsForProduct
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ##   body: JObject (required)
  var body_602351 = newJObject()
  if body != nil:
    body_602351 = body
  result = call_602350.call(nil, nil, nil, nil, body_602351)

var enableImportFindingsForProduct* = Call_EnableImportFindingsForProduct_602338(
    name: "enableImportFindingsForProduct", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_EnableImportFindingsForProduct_602339, base: "/",
    url: url_EnableImportFindingsForProduct_602340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnabledProductsForImport_602323 = ref object of OpenApiRestCall_601389
proc url_ListEnabledProductsForImport_602325(protocol: Scheme; host: string;
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

proc validate_ListEnabledProductsForImport_602324(path: JsonNode; query: JsonNode;
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
  var valid_602326 = query.getOrDefault("MaxResults")
  valid_602326 = validateParameter(valid_602326, JInt, required = false, default = nil)
  if valid_602326 != nil:
    section.add "MaxResults", valid_602326
  var valid_602327 = query.getOrDefault("NextToken")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "NextToken", valid_602327
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
  var valid_602328 = header.getOrDefault("X-Amz-Signature")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Signature", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Content-Sha256", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Date")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Date", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Credential")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Credential", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Security-Token")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Security-Token", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Algorithm")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Algorithm", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-SignedHeaders", valid_602334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602335: Call_ListEnabledProductsForImport_602323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ## 
  let valid = call_602335.validator(path, query, header, formData, body)
  let scheme = call_602335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602335.url(scheme.get, call_602335.host, call_602335.base,
                         call_602335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602335, url, valid)

proc call*(call_602336: Call_ListEnabledProductsForImport_602323;
          MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## listEnabledProductsForImport
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response.
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data.
  var query_602337 = newJObject()
  add(query_602337, "MaxResults", newJInt(MaxResults))
  add(query_602337, "NextToken", newJString(NextToken))
  result = call_602336.call(nil, query_602337, nil, nil, nil)

var listEnabledProductsForImport* = Call_ListEnabledProductsForImport_602323(
    name: "listEnabledProductsForImport", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_ListEnabledProductsForImport_602324, base: "/",
    url: url_ListEnabledProductsForImport_602325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnabledStandards_602352 = ref object of OpenApiRestCall_601389
proc url_GetEnabledStandards_602354(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnabledStandards_602353(path: JsonNode; query: JsonNode;
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
  var valid_602355 = header.getOrDefault("X-Amz-Signature")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Signature", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Content-Sha256", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Date")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Date", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Credential")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Credential", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Security-Token")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Security-Token", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Algorithm")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Algorithm", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-SignedHeaders", valid_602361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602363: Call_GetEnabledStandards_602352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the standards that are currently enabled.
  ## 
  let valid = call_602363.validator(path, query, header, formData, body)
  let scheme = call_602363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602363.url(scheme.get, call_602363.host, call_602363.base,
                         call_602363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602363, url, valid)

proc call*(call_602364: Call_GetEnabledStandards_602352; body: JsonNode): Recallable =
  ## getEnabledStandards
  ## Returns a list of the standards that are currently enabled.
  ##   body: JObject (required)
  var body_602365 = newJObject()
  if body != nil:
    body_602365 = body
  result = call_602364.call(nil, nil, nil, nil, body_602365)

var getEnabledStandards* = Call_GetEnabledStandards_602352(
    name: "getEnabledStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/get",
    validator: validate_GetEnabledStandards_602353, base: "/",
    url: url_GetEnabledStandards_602354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_602366 = ref object of OpenApiRestCall_601389
proc url_GetFindings_602368(protocol: Scheme; host: string; base: string;
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

proc validate_GetFindings_602367(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602369 = query.getOrDefault("MaxResults")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "MaxResults", valid_602369
  var valid_602370 = query.getOrDefault("NextToken")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "NextToken", valid_602370
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
  var valid_602371 = header.getOrDefault("X-Amz-Signature")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Signature", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Content-Sha256", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Date")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Date", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Credential")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Credential", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Security-Token")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Security-Token", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Algorithm")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Algorithm", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-SignedHeaders", valid_602377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602379: Call_GetFindings_602366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of findings that match the specified criteria.
  ## 
  let valid = call_602379.validator(path, query, header, formData, body)
  let scheme = call_602379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602379.url(scheme.get, call_602379.host, call_602379.base,
                         call_602379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602379, url, valid)

proc call*(call_602380: Call_GetFindings_602366; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFindings
  ## Returns a list of findings that match the specified criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602381 = newJObject()
  var body_602382 = newJObject()
  add(query_602381, "MaxResults", newJString(MaxResults))
  add(query_602381, "NextToken", newJString(NextToken))
  if body != nil:
    body_602382 = body
  result = call_602380.call(nil, query_602381, nil, nil, body_602382)

var getFindings* = Call_GetFindings_602366(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/findings",
                                        validator: validate_GetFindings_602367,
                                        base: "/", url: url_GetFindings_602368,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_602383 = ref object of OpenApiRestCall_601389
proc url_UpdateFindings_602385(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFindings_602384(path: JsonNode; query: JsonNode;
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
  var valid_602386 = header.getOrDefault("X-Amz-Signature")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Signature", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Content-Sha256", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-Date")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Date", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-Credential")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Credential", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Security-Token")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Security-Token", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Algorithm")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Algorithm", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-SignedHeaders", valid_602392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602394: Call_UpdateFindings_602383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ## 
  let valid = call_602394.validator(path, query, header, formData, body)
  let scheme = call_602394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602394.url(scheme.get, call_602394.host, call_602394.base,
                         call_602394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602394, url, valid)

proc call*(call_602395: Call_UpdateFindings_602383; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ##   body: JObject (required)
  var body_602396 = newJObject()
  if body != nil:
    body_602396 = body
  result = call_602395.call(nil, nil, nil, nil, body_602396)

var updateFindings* = Call_UpdateFindings_602383(name: "updateFindings",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_UpdateFindings_602384, base: "/",
    url: url_UpdateFindings_602385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsightResults_602397 = ref object of OpenApiRestCall_601389
proc url_GetInsightResults_602399(protocol: Scheme; host: string; base: string;
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

proc validate_GetInsightResults_602398(path: JsonNode; query: JsonNode;
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
  var valid_602400 = path.getOrDefault("InsightArn")
  valid_602400 = validateParameter(valid_602400, JString, required = true,
                                 default = nil)
  if valid_602400 != nil:
    section.add "InsightArn", valid_602400
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
  var valid_602401 = header.getOrDefault("X-Amz-Signature")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Signature", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Content-Sha256", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Date")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Date", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Credential")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Credential", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Security-Token")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Security-Token", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Algorithm")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Algorithm", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-SignedHeaders", valid_602407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602408: Call_GetInsightResults_602397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_602408.validator(path, query, header, formData, body)
  let scheme = call_602408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602408.url(scheme.get, call_602408.host, call_602408.base,
                         call_602408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602408, url, valid)

proc call*(call_602409: Call_GetInsightResults_602397; InsightArn: string): Recallable =
  ## getInsightResults
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight whose results you want to see.
  var path_602410 = newJObject()
  add(path_602410, "InsightArn", newJString(InsightArn))
  result = call_602409.call(path_602410, nil, nil, nil, nil)

var getInsightResults* = Call_GetInsightResults_602397(name: "getInsightResults",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/insights/results/{InsightArn}",
    validator: validate_GetInsightResults_602398, base: "/",
    url: url_GetInsightResults_602399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsights_602411 = ref object of OpenApiRestCall_601389
proc url_GetInsights_602413(protocol: Scheme; host: string; base: string;
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

proc validate_GetInsights_602412(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602414 = query.getOrDefault("MaxResults")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "MaxResults", valid_602414
  var valid_602415 = query.getOrDefault("NextToken")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "NextToken", valid_602415
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
  var valid_602416 = header.getOrDefault("X-Amz-Signature")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Signature", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Content-Sha256", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Date")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Date", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Credential")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Credential", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Security-Token")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Security-Token", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Algorithm")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Algorithm", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-SignedHeaders", valid_602422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602424: Call_GetInsights_602411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists and describes insights that insight ARNs specify.
  ## 
  let valid = call_602424.validator(path, query, header, formData, body)
  let scheme = call_602424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602424.url(scheme.get, call_602424.host, call_602424.base,
                         call_602424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602424, url, valid)

proc call*(call_602425: Call_GetInsights_602411; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getInsights
  ## Lists and describes insights that insight ARNs specify.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602426 = newJObject()
  var body_602427 = newJObject()
  add(query_602426, "MaxResults", newJString(MaxResults))
  add(query_602426, "NextToken", newJString(NextToken))
  if body != nil:
    body_602427 = body
  result = call_602425.call(nil, query_602426, nil, nil, body_602427)

var getInsights* = Call_GetInsights_602411(name: "getInsights",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/insights/get",
                                        validator: validate_GetInsights_602412,
                                        base: "/", url: url_GetInsights_602413,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_602428 = ref object of OpenApiRestCall_601389
proc url_GetInvitationsCount_602430(protocol: Scheme; host: string; base: string;
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

proc validate_GetInvitationsCount_602429(path: JsonNode; query: JsonNode;
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
  var valid_602431 = header.getOrDefault("X-Amz-Signature")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Signature", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Content-Sha256", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-Date")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Date", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Credential")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Credential", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Security-Token")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Security-Token", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Algorithm")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Algorithm", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-SignedHeaders", valid_602437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602438: Call_GetInvitationsCount_602428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  ## 
  let valid = call_602438.validator(path, query, header, formData, body)
  let scheme = call_602438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602438.url(scheme.get, call_602438.host, call_602438.base,
                         call_602438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602438, url, valid)

proc call*(call_602439: Call_GetInvitationsCount_602428): Recallable =
  ## getInvitationsCount
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  result = call_602439.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_602428(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/invitations/count",
    validator: validate_GetInvitationsCount_602429, base: "/",
    url: url_GetInvitationsCount_602430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_602440 = ref object of OpenApiRestCall_601389
proc url_GetMembers_602442(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMembers_602441(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602443 = header.getOrDefault("X-Amz-Signature")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Signature", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Content-Sha256", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Date")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Date", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Credential")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Credential", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Security-Token")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Security-Token", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Algorithm")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Algorithm", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-SignedHeaders", valid_602449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602451: Call_GetMembers_602440; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ## 
  let valid = call_602451.validator(path, query, header, formData, body)
  let scheme = call_602451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602451.url(scheme.get, call_602451.host, call_602451.base,
                         call_602451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602451, url, valid)

proc call*(call_602452: Call_GetMembers_602440; body: JsonNode): Recallable =
  ## getMembers
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ##   body: JObject (required)
  var body_602453 = newJObject()
  if body != nil:
    body_602453 = body
  result = call_602452.call(nil, nil, nil, nil, body_602453)

var getMembers* = Call_GetMembers_602440(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "securityhub.amazonaws.com",
                                      route: "/members/get",
                                      validator: validate_GetMembers_602441,
                                      base: "/", url: url_GetMembers_602442,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_602454 = ref object of OpenApiRestCall_601389
proc url_InviteMembers_602456(protocol: Scheme; host: string; base: string;
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

proc validate_InviteMembers_602455(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602457 = header.getOrDefault("X-Amz-Signature")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Signature", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Content-Sha256", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Date")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Date", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Credential")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Credential", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Security-Token")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Security-Token", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Algorithm")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Algorithm", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-SignedHeaders", valid_602463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602465: Call_InviteMembers_602454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ## 
  let valid = call_602465.validator(path, query, header, formData, body)
  let scheme = call_602465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602465.url(scheme.get, call_602465.host, call_602465.base,
                         call_602465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602465, url, valid)

proc call*(call_602466: Call_InviteMembers_602454; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ##   body: JObject (required)
  var body_602467 = newJObject()
  if body != nil:
    body_602467 = body
  result = call_602466.call(nil, nil, nil, nil, body_602467)

var inviteMembers* = Call_InviteMembers_602454(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/invite", validator: validate_InviteMembers_602455, base: "/",
    url: url_InviteMembers_602456, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_602468 = ref object of OpenApiRestCall_601389
proc url_ListInvitations_602470(protocol: Scheme; host: string; base: string;
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

proc validate_ListInvitations_602469(path: JsonNode; query: JsonNode;
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
  var valid_602471 = query.getOrDefault("MaxResults")
  valid_602471 = validateParameter(valid_602471, JInt, required = false, default = nil)
  if valid_602471 != nil:
    section.add "MaxResults", valid_602471
  var valid_602472 = query.getOrDefault("NextToken")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "NextToken", valid_602472
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
  var valid_602473 = header.getOrDefault("X-Amz-Signature")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Signature", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Content-Sha256", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Date")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Date", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Credential")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Credential", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Security-Token")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Security-Token", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Algorithm")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Algorithm", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-SignedHeaders", valid_602479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602480: Call_ListInvitations_602468; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  let valid = call_602480.validator(path, query, header, formData, body)
  let scheme = call_602480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602480.url(scheme.get, call_602480.host, call_602480.base,
                         call_602480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602480, url, valid)

proc call*(call_602481: Call_ListInvitations_602468; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## listInvitations
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data. 
  var query_602482 = newJObject()
  add(query_602482, "MaxResults", newJInt(MaxResults))
  add(query_602482, "NextToken", newJString(NextToken))
  result = call_602481.call(nil, query_602482, nil, nil, nil)

var listInvitations* = Call_ListInvitations_602468(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_602469, base: "/",
    url: url_ListInvitations_602470, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602497 = ref object of OpenApiRestCall_601389
proc url_TagResource_602499(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602498(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602500 = path.getOrDefault("ResourceArn")
  valid_602500 = validateParameter(valid_602500, JString, required = true,
                                 default = nil)
  if valid_602500 != nil:
    section.add "ResourceArn", valid_602500
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

proc call*(call_602509: Call_TagResource_602497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a resource.
  ## 
  let valid = call_602509.validator(path, query, header, formData, body)
  let scheme = call_602509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602509.url(scheme.get, call_602509.host, call_602509.base,
                         call_602509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602509, url, valid)

proc call*(call_602510: Call_TagResource_602497; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to apply the tags to.
  ##   body: JObject (required)
  var path_602511 = newJObject()
  var body_602512 = newJObject()
  add(path_602511, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_602512 = body
  result = call_602510.call(path_602511, nil, nil, nil, body_602512)

var tagResource* = Call_TagResource_602497(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_602498,
                                        base: "/", url: url_TagResource_602499,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602483 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602485(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602484(path: JsonNode; query: JsonNode;
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
  var valid_602486 = path.getOrDefault("ResourceArn")
  valid_602486 = validateParameter(valid_602486, JString, required = true,
                                 default = nil)
  if valid_602486 != nil:
    section.add "ResourceArn", valid_602486
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
  var valid_602487 = header.getOrDefault("X-Amz-Signature")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Signature", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Content-Sha256", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Date")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Date", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Credential")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Credential", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Security-Token")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Security-Token", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Algorithm")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Algorithm", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-SignedHeaders", valid_602493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602494: Call_ListTagsForResource_602483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags associated with a resource.
  ## 
  let valid = call_602494.validator(path, query, header, formData, body)
  let scheme = call_602494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602494.url(scheme.get, call_602494.host, call_602494.base,
                         call_602494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602494, url, valid)

proc call*(call_602495: Call_ListTagsForResource_602483; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags for.
  var path_602496 = newJObject()
  add(path_602496, "ResourceArn", newJString(ResourceArn))
  result = call_602495.call(path_602496, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602483(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_602484, base: "/",
    url: url_ListTagsForResource_602485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602513 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602515(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602514(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602516 = path.getOrDefault("ResourceArn")
  valid_602516 = validateParameter(valid_602516, JString, required = true,
                                 default = nil)
  if valid_602516 != nil:
    section.add "ResourceArn", valid_602516
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602517 = query.getOrDefault("tagKeys")
  valid_602517 = validateParameter(valid_602517, JArray, required = true, default = nil)
  if valid_602517 != nil:
    section.add "tagKeys", valid_602517
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

proc call*(call_602525: Call_UntagResource_602513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a resource.
  ## 
  let valid = call_602525.validator(path, query, header, formData, body)
  let scheme = call_602525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602525.url(scheme.get, call_602525.host, call_602525.base,
                         call_602525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602525, url, valid)

proc call*(call_602526: Call_UntagResource_602513; ResourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to remove the tags from.
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  var path_602527 = newJObject()
  var query_602528 = newJObject()
  add(path_602527, "ResourceArn", newJString(ResourceArn))
  if tagKeys != nil:
    query_602528.add "tagKeys", tagKeys
  result = call_602526.call(path_602527, query_602528, nil, nil, nil)

var untagResource* = Call_UntagResource_602513(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_602514,
    base: "/", url: url_UntagResource_602515, schemes: {Scheme.Https, Scheme.Http})
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
