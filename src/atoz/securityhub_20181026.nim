
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptInvitation_592955 = ref object of OpenApiRestCall_592364
proc url_AcceptInvitation_592957(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AcceptInvitation_592956(path: JsonNode; query: JsonNode;
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
  var valid_592958 = header.getOrDefault("X-Amz-Signature")
  valid_592958 = validateParameter(valid_592958, JString, required = false,
                                 default = nil)
  if valid_592958 != nil:
    section.add "X-Amz-Signature", valid_592958
  var valid_592959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592959 = validateParameter(valid_592959, JString, required = false,
                                 default = nil)
  if valid_592959 != nil:
    section.add "X-Amz-Content-Sha256", valid_592959
  var valid_592960 = header.getOrDefault("X-Amz-Date")
  valid_592960 = validateParameter(valid_592960, JString, required = false,
                                 default = nil)
  if valid_592960 != nil:
    section.add "X-Amz-Date", valid_592960
  var valid_592961 = header.getOrDefault("X-Amz-Credential")
  valid_592961 = validateParameter(valid_592961, JString, required = false,
                                 default = nil)
  if valid_592961 != nil:
    section.add "X-Amz-Credential", valid_592961
  var valid_592962 = header.getOrDefault("X-Amz-Security-Token")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-Security-Token", valid_592962
  var valid_592963 = header.getOrDefault("X-Amz-Algorithm")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Algorithm", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-SignedHeaders", valid_592964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592966: Call_AcceptInvitation_592955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ## 
  let valid = call_592966.validator(path, query, header, formData, body)
  let scheme = call_592966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592966.url(scheme.get, call_592966.host, call_592966.base,
                         call_592966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592966, url, valid)

proc call*(call_592967: Call_AcceptInvitation_592955; body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ##   body: JObject (required)
  var body_592968 = newJObject()
  if body != nil:
    body_592968 = body
  result = call_592967.call(nil, nil, nil, nil, body_592968)

var acceptInvitation* = Call_AcceptInvitation_592955(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_AcceptInvitation_592956, base: "/",
    url: url_AcceptInvitation_592957, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_592703 = ref object of OpenApiRestCall_592364
proc url_GetMasterAccount_592705(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMasterAccount_592704(path: JsonNode; query: JsonNode;
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
  var valid_592817 = header.getOrDefault("X-Amz-Signature")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Signature", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Content-Sha256", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Date")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Date", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Credential")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Credential", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Security-Token")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Security-Token", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Algorithm")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Algorithm", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-SignedHeaders", valid_592823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592846: Call_GetMasterAccount_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the Security Hub master account to the current member account. 
  ## 
  let valid = call_592846.validator(path, query, header, formData, body)
  let scheme = call_592846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592846.url(scheme.get, call_592846.host, call_592846.base,
                         call_592846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592846, url, valid)

proc call*(call_592917: Call_GetMasterAccount_592703): Recallable =
  ## getMasterAccount
  ## Provides the details for the Security Hub master account to the current member account. 
  result = call_592917.call(nil, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_592703(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_GetMasterAccount_592704, base: "/",
    url: url_GetMasterAccount_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisableStandards_592970 = ref object of OpenApiRestCall_592364
proc url_BatchDisableStandards_592972(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDisableStandards_592971(path: JsonNode; query: JsonNode;
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
  var valid_592973 = header.getOrDefault("X-Amz-Signature")
  valid_592973 = validateParameter(valid_592973, JString, required = false,
                                 default = nil)
  if valid_592973 != nil:
    section.add "X-Amz-Signature", valid_592973
  var valid_592974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592974 = validateParameter(valid_592974, JString, required = false,
                                 default = nil)
  if valid_592974 != nil:
    section.add "X-Amz-Content-Sha256", valid_592974
  var valid_592975 = header.getOrDefault("X-Amz-Date")
  valid_592975 = validateParameter(valid_592975, JString, required = false,
                                 default = nil)
  if valid_592975 != nil:
    section.add "X-Amz-Date", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Credential")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Credential", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Security-Token")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Security-Token", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Algorithm")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Algorithm", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-SignedHeaders", valid_592979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592981: Call_BatchDisableStandards_592970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_592981.validator(path, query, header, formData, body)
  let scheme = call_592981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592981.url(scheme.get, call_592981.host, call_592981.base,
                         call_592981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592981, url, valid)

proc call*(call_592982: Call_BatchDisableStandards_592970; body: JsonNode): Recallable =
  ## batchDisableStandards
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_592983 = newJObject()
  if body != nil:
    body_592983 = body
  result = call_592982.call(nil, nil, nil, nil, body_592983)

var batchDisableStandards* = Call_BatchDisableStandards_592970(
    name: "batchDisableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/deregister",
    validator: validate_BatchDisableStandards_592971, base: "/",
    url: url_BatchDisableStandards_592972, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchEnableStandards_592984 = ref object of OpenApiRestCall_592364
proc url_BatchEnableStandards_592986(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchEnableStandards_592985(path: JsonNode; query: JsonNode;
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
  var valid_592987 = header.getOrDefault("X-Amz-Signature")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Signature", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Content-Sha256", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-Date")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Date", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-Credential")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Credential", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Security-Token")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Security-Token", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Algorithm")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Algorithm", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-SignedHeaders", valid_592993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592995: Call_BatchEnableStandards_592984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_592995.validator(path, query, header, formData, body)
  let scheme = call_592995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592995.url(scheme.get, call_592995.host, call_592995.base,
                         call_592995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592995, url, valid)

proc call*(call_592996: Call_BatchEnableStandards_592984; body: JsonNode): Recallable =
  ## batchEnableStandards
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_592997 = newJObject()
  if body != nil:
    body_592997 = body
  result = call_592996.call(nil, nil, nil, nil, body_592997)

var batchEnableStandards* = Call_BatchEnableStandards_592984(
    name: "batchEnableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/register",
    validator: validate_BatchEnableStandards_592985, base: "/",
    url: url_BatchEnableStandards_592986, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchImportFindings_592998 = ref object of OpenApiRestCall_592364
proc url_BatchImportFindings_593000(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchImportFindings_592999(path: JsonNode; query: JsonNode;
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
  var valid_593001 = header.getOrDefault("X-Amz-Signature")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Signature", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Content-Sha256", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Date")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Date", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Credential")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Credential", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Security-Token")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Security-Token", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Algorithm")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Algorithm", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-SignedHeaders", valid_593007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593009: Call_BatchImportFindings_592998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ## 
  let valid = call_593009.validator(path, query, header, formData, body)
  let scheme = call_593009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593009.url(scheme.get, call_593009.host, call_593009.base,
                         call_593009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593009, url, valid)

proc call*(call_593010: Call_BatchImportFindings_592998; body: JsonNode): Recallable =
  ## batchImportFindings
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ##   body: JObject (required)
  var body_593011 = newJObject()
  if body != nil:
    body_593011 = body
  result = call_593010.call(nil, nil, nil, nil, body_593011)

var batchImportFindings* = Call_BatchImportFindings_592998(
    name: "batchImportFindings", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/findings/import",
    validator: validate_BatchImportFindings_592999, base: "/",
    url: url_BatchImportFindings_593000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActionTarget_593012 = ref object of OpenApiRestCall_592364
proc url_CreateActionTarget_593014(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateActionTarget_593013(path: JsonNode; query: JsonNode;
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
  var valid_593015 = header.getOrDefault("X-Amz-Signature")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Signature", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Content-Sha256", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Date")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Date", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Credential")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Credential", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Security-Token")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Security-Token", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Algorithm")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Algorithm", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-SignedHeaders", valid_593021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593023: Call_CreateActionTarget_593012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ## 
  let valid = call_593023.validator(path, query, header, formData, body)
  let scheme = call_593023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593023.url(scheme.get, call_593023.host, call_593023.base,
                         call_593023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593023, url, valid)

proc call*(call_593024: Call_CreateActionTarget_593012; body: JsonNode): Recallable =
  ## createActionTarget
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ##   body: JObject (required)
  var body_593025 = newJObject()
  if body != nil:
    body_593025 = body
  result = call_593024.call(nil, nil, nil, nil, body_593025)

var createActionTarget* = Call_CreateActionTarget_593012(
    name: "createActionTarget", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets",
    validator: validate_CreateActionTarget_593013, base: "/",
    url: url_CreateActionTarget_593014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInsight_593026 = ref object of OpenApiRestCall_592364
proc url_CreateInsight_593028(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateInsight_593027(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593029 = header.getOrDefault("X-Amz-Signature")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Signature", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Content-Sha256", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Date")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Date", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Credential")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Credential", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Security-Token")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Security-Token", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Algorithm")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Algorithm", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-SignedHeaders", valid_593035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593037: Call_CreateInsight_593026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ## 
  let valid = call_593037.validator(path, query, header, formData, body)
  let scheme = call_593037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593037.url(scheme.get, call_593037.host, call_593037.base,
                         call_593037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593037, url, valid)

proc call*(call_593038: Call_CreateInsight_593026; body: JsonNode): Recallable =
  ## createInsight
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ##   body: JObject (required)
  var body_593039 = newJObject()
  if body != nil:
    body_593039 = body
  result = call_593038.call(nil, nil, nil, nil, body_593039)

var createInsight* = Call_CreateInsight_593026(name: "createInsight",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights", validator: validate_CreateInsight_593027, base: "/",
    url: url_CreateInsight_593028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_593057 = ref object of OpenApiRestCall_592364
proc url_CreateMembers_593059(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMembers_593058(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593060 = header.getOrDefault("X-Amz-Signature")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Signature", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Content-Sha256", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Date")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Date", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Credential")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Credential", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Security-Token")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Security-Token", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Algorithm")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Algorithm", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-SignedHeaders", valid_593066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593068: Call_CreateMembers_593057; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ## 
  let valid = call_593068.validator(path, query, header, formData, body)
  let scheme = call_593068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593068.url(scheme.get, call_593068.host, call_593068.base,
                         call_593068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593068, url, valid)

proc call*(call_593069: Call_CreateMembers_593057; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ##   body: JObject (required)
  var body_593070 = newJObject()
  if body != nil:
    body_593070 = body
  result = call_593069.call(nil, nil, nil, nil, body_593070)

var createMembers* = Call_CreateMembers_593057(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/members",
    validator: validate_CreateMembers_593058, base: "/", url: url_CreateMembers_593059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_593040 = ref object of OpenApiRestCall_592364
proc url_ListMembers_593042(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListMembers_593041(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593043 = query.getOrDefault("MaxResults")
  valid_593043 = validateParameter(valid_593043, JInt, required = false, default = nil)
  if valid_593043 != nil:
    section.add "MaxResults", valid_593043
  var valid_593044 = query.getOrDefault("NextToken")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "NextToken", valid_593044
  var valid_593045 = query.getOrDefault("OnlyAssociated")
  valid_593045 = validateParameter(valid_593045, JBool, required = false, default = nil)
  if valid_593045 != nil:
    section.add "OnlyAssociated", valid_593045
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
  var valid_593046 = header.getOrDefault("X-Amz-Signature")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Signature", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Content-Sha256", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Date")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Date", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Credential")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Credential", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Security-Token")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Security-Token", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Algorithm")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Algorithm", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-SignedHeaders", valid_593052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593053: Call_ListMembers_593040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  let valid = call_593053.validator(path, query, header, formData, body)
  let scheme = call_593053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593053.url(scheme.get, call_593053.host, call_593053.base,
                         call_593053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593053, url, valid)

proc call*(call_593054: Call_ListMembers_593040; MaxResults: int = 0;
          NextToken: string = ""; OnlyAssociated: bool = false): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current Security Hub master account.
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  ##   NextToken: string
  ##            : Paginates results. Set the value of this parameter to <code>NULL</code> on your first call to the <code>ListMembers</code> operation. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>nextToken</code> from the previous response to continue listing data. 
  ##   OnlyAssociated: bool
  ##                 : Specifies which member accounts the response includes based on their relationship status with the master account. The default value is <code>TRUE</code>. If <code>onlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>. If <code>onlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. 
  var query_593055 = newJObject()
  add(query_593055, "MaxResults", newJInt(MaxResults))
  add(query_593055, "NextToken", newJString(NextToken))
  add(query_593055, "OnlyAssociated", newJBool(OnlyAssociated))
  result = call_593054.call(nil, query_593055, nil, nil, nil)

var listMembers* = Call_ListMembers_593040(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/members",
                                        validator: validate_ListMembers_593041,
                                        base: "/", url: url_ListMembers_593042,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_593071 = ref object of OpenApiRestCall_592364
proc url_DeclineInvitations_593073(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeclineInvitations_593072(path: JsonNode; query: JsonNode;
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
  var valid_593074 = header.getOrDefault("X-Amz-Signature")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Signature", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Content-Sha256", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Date")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Date", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Credential")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Credential", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Security-Token")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Security-Token", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Algorithm")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Algorithm", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-SignedHeaders", valid_593080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593082: Call_DeclineInvitations_593071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations to become a member account.
  ## 
  let valid = call_593082.validator(path, query, header, formData, body)
  let scheme = call_593082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593082.url(scheme.get, call_593082.host, call_593082.base,
                         call_593082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593082, url, valid)

proc call*(call_593083: Call_DeclineInvitations_593071; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations to become a member account.
  ##   body: JObject (required)
  var body_593084 = newJObject()
  if body != nil:
    body_593084 = body
  result = call_593083.call(nil, nil, nil, nil, body_593084)

var declineInvitations* = Call_DeclineInvitations_593071(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/invitations/decline",
    validator: validate_DeclineInvitations_593072, base: "/",
    url: url_DeclineInvitations_593073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateActionTarget_593113 = ref object of OpenApiRestCall_592364
proc url_UpdateActionTarget_593115(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateActionTarget_593114(path: JsonNode; query: JsonNode;
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
  var valid_593116 = path.getOrDefault("ActionTargetArn")
  valid_593116 = validateParameter(valid_593116, JString, required = true,
                                 default = nil)
  if valid_593116 != nil:
    section.add "ActionTargetArn", valid_593116
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
  var valid_593117 = header.getOrDefault("X-Amz-Signature")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Signature", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Content-Sha256", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Date")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Date", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Credential")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Credential", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Security-Token")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Security-Token", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Algorithm")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Algorithm", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-SignedHeaders", valid_593123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593125: Call_UpdateActionTarget_593113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name and description of a custom action target in Security Hub.
  ## 
  let valid = call_593125.validator(path, query, header, formData, body)
  let scheme = call_593125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593125.url(scheme.get, call_593125.host, call_593125.base,
                         call_593125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593125, url, valid)

proc call*(call_593126: Call_UpdateActionTarget_593113; ActionTargetArn: string;
          body: JsonNode): Recallable =
  ## updateActionTarget
  ## Updates the name and description of a custom action target in Security Hub.
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to update.
  ##   body: JObject (required)
  var path_593127 = newJObject()
  var body_593128 = newJObject()
  add(path_593127, "ActionTargetArn", newJString(ActionTargetArn))
  if body != nil:
    body_593128 = body
  result = call_593126.call(path_593127, nil, nil, nil, body_593128)

var updateActionTarget* = Call_UpdateActionTarget_593113(
    name: "updateActionTarget", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_UpdateActionTarget_593114, base: "/",
    url: url_UpdateActionTarget_593115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActionTarget_593085 = ref object of OpenApiRestCall_592364
proc url_DeleteActionTarget_593087(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteActionTarget_593086(path: JsonNode; query: JsonNode;
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
  var valid_593102 = path.getOrDefault("ActionTargetArn")
  valid_593102 = validateParameter(valid_593102, JString, required = true,
                                 default = nil)
  if valid_593102 != nil:
    section.add "ActionTargetArn", valid_593102
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
  var valid_593103 = header.getOrDefault("X-Amz-Signature")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Signature", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Content-Sha256", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Date")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Date", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Credential")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Credential", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Security-Token")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Security-Token", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Algorithm")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Algorithm", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-SignedHeaders", valid_593109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593110: Call_DeleteActionTarget_593085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ## 
  let valid = call_593110.validator(path, query, header, formData, body)
  let scheme = call_593110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593110.url(scheme.get, call_593110.host, call_593110.base,
                         call_593110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593110, url, valid)

proc call*(call_593111: Call_DeleteActionTarget_593085; ActionTargetArn: string): Recallable =
  ## deleteActionTarget
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to delete.
  var path_593112 = newJObject()
  add(path_593112, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_593111.call(path_593112, nil, nil, nil, nil)

var deleteActionTarget* = Call_DeleteActionTarget_593085(
    name: "deleteActionTarget", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_DeleteActionTarget_593086, base: "/",
    url: url_DeleteActionTarget_593087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInsight_593143 = ref object of OpenApiRestCall_592364
proc url_UpdateInsight_593145(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateInsight_593144(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593146 = path.getOrDefault("InsightArn")
  valid_593146 = validateParameter(valid_593146, JString, required = true,
                                 default = nil)
  if valid_593146 != nil:
    section.add "InsightArn", valid_593146
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
  var valid_593147 = header.getOrDefault("X-Amz-Signature")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Signature", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-Content-Sha256", valid_593148
  var valid_593149 = header.getOrDefault("X-Amz-Date")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-Date", valid_593149
  var valid_593150 = header.getOrDefault("X-Amz-Credential")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "X-Amz-Credential", valid_593150
  var valid_593151 = header.getOrDefault("X-Amz-Security-Token")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Security-Token", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Algorithm")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Algorithm", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-SignedHeaders", valid_593153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593155: Call_UpdateInsight_593143; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_593155.validator(path, query, header, formData, body)
  let scheme = call_593155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593155.url(scheme.get, call_593155.host, call_593155.base,
                         call_593155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593155, url, valid)

proc call*(call_593156: Call_UpdateInsight_593143; InsightArn: string; body: JsonNode): Recallable =
  ## updateInsight
  ## Updates the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight that you want to update.
  ##   body: JObject (required)
  var path_593157 = newJObject()
  var body_593158 = newJObject()
  add(path_593157, "InsightArn", newJString(InsightArn))
  if body != nil:
    body_593158 = body
  result = call_593156.call(path_593157, nil, nil, nil, body_593158)

var updateInsight* = Call_UpdateInsight_593143(name: "updateInsight",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_UpdateInsight_593144,
    base: "/", url: url_UpdateInsight_593145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInsight_593129 = ref object of OpenApiRestCall_592364
proc url_DeleteInsight_593131(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteInsight_593130(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593132 = path.getOrDefault("InsightArn")
  valid_593132 = validateParameter(valid_593132, JString, required = true,
                                 default = nil)
  if valid_593132 != nil:
    section.add "InsightArn", valid_593132
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
  var valid_593133 = header.getOrDefault("X-Amz-Signature")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Signature", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Content-Sha256", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Date")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Date", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Credential")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Credential", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Security-Token")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Security-Token", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Algorithm")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Algorithm", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-SignedHeaders", valid_593139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593140: Call_DeleteInsight_593129; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ## 
  let valid = call_593140.validator(path, query, header, formData, body)
  let scheme = call_593140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593140.url(scheme.get, call_593140.host, call_593140.base,
                         call_593140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593140, url, valid)

proc call*(call_593141: Call_DeleteInsight_593129; InsightArn: string): Recallable =
  ## deleteInsight
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight to delete.
  var path_593142 = newJObject()
  add(path_593142, "InsightArn", newJString(InsightArn))
  result = call_593141.call(path_593142, nil, nil, nil, nil)

var deleteInsight* = Call_DeleteInsight_593129(name: "deleteInsight",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_DeleteInsight_593130,
    base: "/", url: url_DeleteInsight_593131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_593159 = ref object of OpenApiRestCall_592364
proc url_DeleteInvitations_593161(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteInvitations_593160(path: JsonNode; query: JsonNode;
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
  var valid_593162 = header.getOrDefault("X-Amz-Signature")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Signature", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Content-Sha256", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-Date")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Date", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Credential")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Credential", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Security-Token")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Security-Token", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Algorithm")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Algorithm", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-SignedHeaders", valid_593168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593170: Call_DeleteInvitations_593159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations received by the AWS account to become a member account.
  ## 
  let valid = call_593170.validator(path, query, header, formData, body)
  let scheme = call_593170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593170.url(scheme.get, call_593170.host, call_593170.base,
                         call_593170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593170, url, valid)

proc call*(call_593171: Call_DeleteInvitations_593159; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations received by the AWS account to become a member account.
  ##   body: JObject (required)
  var body_593172 = newJObject()
  if body != nil:
    body_593172 = body
  result = call_593171.call(nil, nil, nil, nil, body_593172)

var deleteInvitations* = Call_DeleteInvitations_593159(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/invitations/delete", validator: validate_DeleteInvitations_593160,
    base: "/", url: url_DeleteInvitations_593161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_593173 = ref object of OpenApiRestCall_592364
proc url_DeleteMembers_593175(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMembers_593174(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593176 = header.getOrDefault("X-Amz-Signature")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Signature", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Content-Sha256", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-Date")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Date", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Credential")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Credential", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Security-Token")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Security-Token", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Algorithm")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Algorithm", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-SignedHeaders", valid_593182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593184: Call_DeleteMembers_593173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified member accounts from Security Hub.
  ## 
  let valid = call_593184.validator(path, query, header, formData, body)
  let scheme = call_593184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593184.url(scheme.get, call_593184.host, call_593184.base,
                         call_593184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593184, url, valid)

proc call*(call_593185: Call_DeleteMembers_593173; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes the specified member accounts from Security Hub.
  ##   body: JObject (required)
  var body_593186 = newJObject()
  if body != nil:
    body_593186 = body
  result = call_593185.call(nil, nil, nil, nil, body_593186)

var deleteMembers* = Call_DeleteMembers_593173(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/delete", validator: validate_DeleteMembers_593174, base: "/",
    url: url_DeleteMembers_593175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActionTargets_593187 = ref object of OpenApiRestCall_592364
proc url_DescribeActionTargets_593189(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeActionTargets_593188(path: JsonNode; query: JsonNode;
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
  var valid_593190 = query.getOrDefault("MaxResults")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "MaxResults", valid_593190
  var valid_593191 = query.getOrDefault("NextToken")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "NextToken", valid_593191
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
  var valid_593192 = header.getOrDefault("X-Amz-Signature")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Signature", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Content-Sha256", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Date")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Date", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Credential")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Credential", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Security-Token")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Security-Token", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Algorithm")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Algorithm", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-SignedHeaders", valid_593198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593200: Call_DescribeActionTargets_593187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the custom action targets in Security Hub in your account.
  ## 
  let valid = call_593200.validator(path, query, header, formData, body)
  let scheme = call_593200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593200.url(scheme.get, call_593200.host, call_593200.base,
                         call_593200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593200, url, valid)

proc call*(call_593201: Call_DescribeActionTargets_593187; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeActionTargets
  ## Returns a list of the custom action targets in Security Hub in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593202 = newJObject()
  var body_593203 = newJObject()
  add(query_593202, "MaxResults", newJString(MaxResults))
  add(query_593202, "NextToken", newJString(NextToken))
  if body != nil:
    body_593203 = body
  result = call_593201.call(nil, query_593202, nil, nil, body_593203)

var describeActionTargets* = Call_DescribeActionTargets_593187(
    name: "describeActionTargets", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets/get",
    validator: validate_DescribeActionTargets_593188, base: "/",
    url: url_DescribeActionTargets_593189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSecurityHub_593218 = ref object of OpenApiRestCall_592364
proc url_EnableSecurityHub_593220(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableSecurityHub_593219(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593221 = header.getOrDefault("X-Amz-Signature")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Signature", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Content-Sha256", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Date")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Date", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Credential")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Credential", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Security-Token")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Security-Token", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Algorithm")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Algorithm", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-SignedHeaders", valid_593227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593229: Call_EnableSecurityHub_593218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ## 
  let valid = call_593229.validator(path, query, header, formData, body)
  let scheme = call_593229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593229.url(scheme.get, call_593229.host, call_593229.base,
                         call_593229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593229, url, valid)

proc call*(call_593230: Call_EnableSecurityHub_593218; body: JsonNode): Recallable =
  ## enableSecurityHub
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_593231 = newJObject()
  if body != nil:
    body_593231 = body
  result = call_593230.call(nil, nil, nil, nil, body_593231)

var enableSecurityHub* = Call_EnableSecurityHub_593218(name: "enableSecurityHub",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/accounts", validator: validate_EnableSecurityHub_593219, base: "/",
    url: url_EnableSecurityHub_593220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHub_593204 = ref object of OpenApiRestCall_592364
proc url_DescribeHub_593206(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeHub_593205(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593207 = query.getOrDefault("HubArn")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "HubArn", valid_593207
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
  var valid_593208 = header.getOrDefault("X-Amz-Signature")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Signature", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Content-Sha256", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Date")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Date", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Credential")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Credential", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-Security-Token")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-Security-Token", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-Algorithm")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Algorithm", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-SignedHeaders", valid_593214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593215: Call_DescribeHub_593204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ## 
  let valid = call_593215.validator(path, query, header, formData, body)
  let scheme = call_593215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593215.url(scheme.get, call_593215.host, call_593215.base,
                         call_593215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593215, url, valid)

proc call*(call_593216: Call_DescribeHub_593204; HubArn: string = ""): Recallable =
  ## describeHub
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ##   HubArn: string
  ##         : The ARN of the Hub resource to retrieve.
  var query_593217 = newJObject()
  add(query_593217, "HubArn", newJString(HubArn))
  result = call_593216.call(nil, query_593217, nil, nil, nil)

var describeHub* = Call_DescribeHub_593204(name: "describeHub",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/accounts",
                                        validator: validate_DescribeHub_593205,
                                        base: "/", url: url_DescribeHub_593206,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSecurityHub_593232 = ref object of OpenApiRestCall_592364
proc url_DisableSecurityHub_593234(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableSecurityHub_593233(path: JsonNode; query: JsonNode;
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
  var valid_593235 = header.getOrDefault("X-Amz-Signature")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Signature", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Content-Sha256", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Date")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Date", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Credential")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Credential", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Security-Token")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Security-Token", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Algorithm")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Algorithm", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-SignedHeaders", valid_593241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593242: Call_DisableSecurityHub_593232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  ## 
  let valid = call_593242.validator(path, query, header, formData, body)
  let scheme = call_593242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593242.url(scheme.get, call_593242.host, call_593242.base,
                         call_593242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593242, url, valid)

proc call*(call_593243: Call_DisableSecurityHub_593232): Recallable =
  ## disableSecurityHub
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  result = call_593243.call(nil, nil, nil, nil, nil)

var disableSecurityHub* = Call_DisableSecurityHub_593232(
    name: "disableSecurityHub", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_DisableSecurityHub_593233, base: "/",
    url: url_DisableSecurityHub_593234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProducts_593244 = ref object of OpenApiRestCall_592364
proc url_DescribeProducts_593246(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProducts_593245(path: JsonNode; query: JsonNode;
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
  var valid_593247 = query.getOrDefault("MaxResults")
  valid_593247 = validateParameter(valid_593247, JInt, required = false, default = nil)
  if valid_593247 != nil:
    section.add "MaxResults", valid_593247
  var valid_593248 = query.getOrDefault("NextToken")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "NextToken", valid_593248
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
  var valid_593249 = header.getOrDefault("X-Amz-Signature")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Signature", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Content-Sha256", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Date")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Date", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Credential")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Credential", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Security-Token")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Security-Token", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Algorithm")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Algorithm", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-SignedHeaders", valid_593255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593256: Call_DescribeProducts_593244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ## 
  let valid = call_593256.validator(path, query, header, formData, body)
  let scheme = call_593256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593256.url(scheme.get, call_593256.host, call_593256.base,
                         call_593256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593256, url, valid)

proc call*(call_593257: Call_DescribeProducts_593244; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## describeProducts
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ##   MaxResults: int
  ##             : The maximum number of results to return.
  ##   NextToken: string
  ##            : The token that is required for pagination.
  var query_593258 = newJObject()
  add(query_593258, "MaxResults", newJInt(MaxResults))
  add(query_593258, "NextToken", newJString(NextToken))
  result = call_593257.call(nil, query_593258, nil, nil, nil)

var describeProducts* = Call_DescribeProducts_593244(name: "describeProducts",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/products",
    validator: validate_DescribeProducts_593245, base: "/",
    url: url_DescribeProducts_593246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableImportFindingsForProduct_593259 = ref object of OpenApiRestCall_592364
proc url_DisableImportFindingsForProduct_593261(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DisableImportFindingsForProduct_593260(path: JsonNode;
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
  var valid_593262 = path.getOrDefault("ProductSubscriptionArn")
  valid_593262 = validateParameter(valid_593262, JString, required = true,
                                 default = nil)
  if valid_593262 != nil:
    section.add "ProductSubscriptionArn", valid_593262
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
  var valid_593263 = header.getOrDefault("X-Amz-Signature")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Signature", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Content-Sha256", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Date")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Date", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-Credential")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-Credential", valid_593266
  var valid_593267 = header.getOrDefault("X-Amz-Security-Token")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-Security-Token", valid_593267
  var valid_593268 = header.getOrDefault("X-Amz-Algorithm")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Algorithm", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-SignedHeaders", valid_593269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593270: Call_DisableImportFindingsForProduct_593259;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ## 
  let valid = call_593270.validator(path, query, header, formData, body)
  let scheme = call_593270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593270.url(scheme.get, call_593270.host, call_593270.base,
                         call_593270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593270, url, valid)

proc call*(call_593271: Call_DisableImportFindingsForProduct_593259;
          ProductSubscriptionArn: string): Recallable =
  ## disableImportFindingsForProduct
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ##   ProductSubscriptionArn: string (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  var path_593272 = newJObject()
  add(path_593272, "ProductSubscriptionArn", newJString(ProductSubscriptionArn))
  result = call_593271.call(path_593272, nil, nil, nil, nil)

var disableImportFindingsForProduct* = Call_DisableImportFindingsForProduct_593259(
    name: "disableImportFindingsForProduct", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com",
    route: "/productSubscriptions/{ProductSubscriptionArn}",
    validator: validate_DisableImportFindingsForProduct_593260, base: "/",
    url: url_DisableImportFindingsForProduct_593261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_593273 = ref object of OpenApiRestCall_592364
proc url_DisassociateFromMasterAccount_593275(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateFromMasterAccount_593274(path: JsonNode; query: JsonNode;
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
  var valid_593276 = header.getOrDefault("X-Amz-Signature")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Signature", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Content-Sha256", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Date")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Date", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Credential")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Credential", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Security-Token")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Security-Token", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-Algorithm")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-Algorithm", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-SignedHeaders", valid_593282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593283: Call_DisassociateFromMasterAccount_593273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current Security Hub member account from the associated master account.
  ## 
  let valid = call_593283.validator(path, query, header, formData, body)
  let scheme = call_593283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593283.url(scheme.get, call_593283.host, call_593283.base,
                         call_593283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593283, url, valid)

proc call*(call_593284: Call_DisassociateFromMasterAccount_593273): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current Security Hub member account from the associated master account.
  result = call_593284.call(nil, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_593273(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_593274, base: "/",
    url: url_DisassociateFromMasterAccount_593275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_593285 = ref object of OpenApiRestCall_592364
proc url_DisassociateMembers_593287(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateMembers_593286(path: JsonNode; query: JsonNode;
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
  var valid_593288 = header.getOrDefault("X-Amz-Signature")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Signature", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Content-Sha256", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Date")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Date", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Credential")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Credential", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Security-Token")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Security-Token", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Algorithm")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Algorithm", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-SignedHeaders", valid_593294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593296: Call_DisassociateMembers_593285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified member accounts from the associated master account.
  ## 
  let valid = call_593296.validator(path, query, header, formData, body)
  let scheme = call_593296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593296.url(scheme.get, call_593296.host, call_593296.base,
                         call_593296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593296, url, valid)

proc call*(call_593297: Call_DisassociateMembers_593285; body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates the specified member accounts from the associated master account.
  ##   body: JObject (required)
  var body_593298 = newJObject()
  if body != nil:
    body_593298 = body
  result = call_593297.call(nil, nil, nil, nil, body_593298)

var disassociateMembers* = Call_DisassociateMembers_593285(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/members/disassociate",
    validator: validate_DisassociateMembers_593286, base: "/",
    url: url_DisassociateMembers_593287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableImportFindingsForProduct_593314 = ref object of OpenApiRestCall_592364
proc url_EnableImportFindingsForProduct_593316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableImportFindingsForProduct_593315(path: JsonNode;
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
  var valid_593317 = header.getOrDefault("X-Amz-Signature")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Signature", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Content-Sha256", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-Date")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Date", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Credential")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Credential", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Security-Token")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Security-Token", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Algorithm")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Algorithm", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-SignedHeaders", valid_593323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593325: Call_EnableImportFindingsForProduct_593314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ## 
  let valid = call_593325.validator(path, query, header, formData, body)
  let scheme = call_593325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593325.url(scheme.get, call_593325.host, call_593325.base,
                         call_593325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593325, url, valid)

proc call*(call_593326: Call_EnableImportFindingsForProduct_593314; body: JsonNode): Recallable =
  ## enableImportFindingsForProduct
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ##   body: JObject (required)
  var body_593327 = newJObject()
  if body != nil:
    body_593327 = body
  result = call_593326.call(nil, nil, nil, nil, body_593327)

var enableImportFindingsForProduct* = Call_EnableImportFindingsForProduct_593314(
    name: "enableImportFindingsForProduct", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_EnableImportFindingsForProduct_593315, base: "/",
    url: url_EnableImportFindingsForProduct_593316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnabledProductsForImport_593299 = ref object of OpenApiRestCall_592364
proc url_ListEnabledProductsForImport_593301(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEnabledProductsForImport_593300(path: JsonNode; query: JsonNode;
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
  var valid_593302 = query.getOrDefault("MaxResults")
  valid_593302 = validateParameter(valid_593302, JInt, required = false, default = nil)
  if valid_593302 != nil:
    section.add "MaxResults", valid_593302
  var valid_593303 = query.getOrDefault("NextToken")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "NextToken", valid_593303
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
  var valid_593304 = header.getOrDefault("X-Amz-Signature")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Signature", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Content-Sha256", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Date")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Date", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Credential")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Credential", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Security-Token")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Security-Token", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Algorithm")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Algorithm", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-SignedHeaders", valid_593310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593311: Call_ListEnabledProductsForImport_593299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ## 
  let valid = call_593311.validator(path, query, header, formData, body)
  let scheme = call_593311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593311.url(scheme.get, call_593311.host, call_593311.base,
                         call_593311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593311, url, valid)

proc call*(call_593312: Call_ListEnabledProductsForImport_593299;
          MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## listEnabledProductsForImport
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response.
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data.
  var query_593313 = newJObject()
  add(query_593313, "MaxResults", newJInt(MaxResults))
  add(query_593313, "NextToken", newJString(NextToken))
  result = call_593312.call(nil, query_593313, nil, nil, nil)

var listEnabledProductsForImport* = Call_ListEnabledProductsForImport_593299(
    name: "listEnabledProductsForImport", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_ListEnabledProductsForImport_593300, base: "/",
    url: url_ListEnabledProductsForImport_593301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnabledStandards_593328 = ref object of OpenApiRestCall_592364
proc url_GetEnabledStandards_593330(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEnabledStandards_593329(path: JsonNode; query: JsonNode;
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
  var valid_593331 = header.getOrDefault("X-Amz-Signature")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Signature", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Content-Sha256", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Date")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Date", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Credential")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Credential", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Security-Token")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Security-Token", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Algorithm")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Algorithm", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-SignedHeaders", valid_593337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593339: Call_GetEnabledStandards_593328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the standards that are currently enabled.
  ## 
  let valid = call_593339.validator(path, query, header, formData, body)
  let scheme = call_593339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593339.url(scheme.get, call_593339.host, call_593339.base,
                         call_593339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593339, url, valid)

proc call*(call_593340: Call_GetEnabledStandards_593328; body: JsonNode): Recallable =
  ## getEnabledStandards
  ## Returns a list of the standards that are currently enabled.
  ##   body: JObject (required)
  var body_593341 = newJObject()
  if body != nil:
    body_593341 = body
  result = call_593340.call(nil, nil, nil, nil, body_593341)

var getEnabledStandards* = Call_GetEnabledStandards_593328(
    name: "getEnabledStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/get",
    validator: validate_GetEnabledStandards_593329, base: "/",
    url: url_GetEnabledStandards_593330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_593342 = ref object of OpenApiRestCall_592364
proc url_GetFindings_593344(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFindings_593343(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593345 = query.getOrDefault("MaxResults")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "MaxResults", valid_593345
  var valid_593346 = query.getOrDefault("NextToken")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "NextToken", valid_593346
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
  var valid_593347 = header.getOrDefault("X-Amz-Signature")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Signature", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Content-Sha256", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Date")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Date", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Credential")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Credential", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Security-Token")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Security-Token", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Algorithm")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Algorithm", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-SignedHeaders", valid_593353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593355: Call_GetFindings_593342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of findings that match the specified criteria.
  ## 
  let valid = call_593355.validator(path, query, header, formData, body)
  let scheme = call_593355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593355.url(scheme.get, call_593355.host, call_593355.base,
                         call_593355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593355, url, valid)

proc call*(call_593356: Call_GetFindings_593342; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFindings
  ## Returns a list of findings that match the specified criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593357 = newJObject()
  var body_593358 = newJObject()
  add(query_593357, "MaxResults", newJString(MaxResults))
  add(query_593357, "NextToken", newJString(NextToken))
  if body != nil:
    body_593358 = body
  result = call_593356.call(nil, query_593357, nil, nil, body_593358)

var getFindings* = Call_GetFindings_593342(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/findings",
                                        validator: validate_GetFindings_593343,
                                        base: "/", url: url_GetFindings_593344,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_593359 = ref object of OpenApiRestCall_592364
proc url_UpdateFindings_593361(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateFindings_593360(path: JsonNode; query: JsonNode;
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
  var valid_593362 = header.getOrDefault("X-Amz-Signature")
  valid_593362 = validateParameter(valid_593362, JString, required = false,
                                 default = nil)
  if valid_593362 != nil:
    section.add "X-Amz-Signature", valid_593362
  var valid_593363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-Content-Sha256", valid_593363
  var valid_593364 = header.getOrDefault("X-Amz-Date")
  valid_593364 = validateParameter(valid_593364, JString, required = false,
                                 default = nil)
  if valid_593364 != nil:
    section.add "X-Amz-Date", valid_593364
  var valid_593365 = header.getOrDefault("X-Amz-Credential")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "X-Amz-Credential", valid_593365
  var valid_593366 = header.getOrDefault("X-Amz-Security-Token")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Security-Token", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Algorithm")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Algorithm", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-SignedHeaders", valid_593368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593370: Call_UpdateFindings_593359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ## 
  let valid = call_593370.validator(path, query, header, formData, body)
  let scheme = call_593370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593370.url(scheme.get, call_593370.host, call_593370.base,
                         call_593370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593370, url, valid)

proc call*(call_593371: Call_UpdateFindings_593359; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ##   body: JObject (required)
  var body_593372 = newJObject()
  if body != nil:
    body_593372 = body
  result = call_593371.call(nil, nil, nil, nil, body_593372)

var updateFindings* = Call_UpdateFindings_593359(name: "updateFindings",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_UpdateFindings_593360, base: "/",
    url: url_UpdateFindings_593361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsightResults_593373 = ref object of OpenApiRestCall_592364
proc url_GetInsightResults_593375(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetInsightResults_593374(path: JsonNode; query: JsonNode;
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
  var valid_593376 = path.getOrDefault("InsightArn")
  valid_593376 = validateParameter(valid_593376, JString, required = true,
                                 default = nil)
  if valid_593376 != nil:
    section.add "InsightArn", valid_593376
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
  var valid_593377 = header.getOrDefault("X-Amz-Signature")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-Signature", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-Content-Sha256", valid_593378
  var valid_593379 = header.getOrDefault("X-Amz-Date")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "X-Amz-Date", valid_593379
  var valid_593380 = header.getOrDefault("X-Amz-Credential")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-Credential", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Security-Token")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Security-Token", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-Algorithm")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Algorithm", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-SignedHeaders", valid_593383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593384: Call_GetInsightResults_593373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_593384.validator(path, query, header, formData, body)
  let scheme = call_593384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593384.url(scheme.get, call_593384.host, call_593384.base,
                         call_593384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593384, url, valid)

proc call*(call_593385: Call_GetInsightResults_593373; InsightArn: string): Recallable =
  ## getInsightResults
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight whose results you want to see.
  var path_593386 = newJObject()
  add(path_593386, "InsightArn", newJString(InsightArn))
  result = call_593385.call(path_593386, nil, nil, nil, nil)

var getInsightResults* = Call_GetInsightResults_593373(name: "getInsightResults",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/insights/results/{InsightArn}",
    validator: validate_GetInsightResults_593374, base: "/",
    url: url_GetInsightResults_593375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsights_593387 = ref object of OpenApiRestCall_592364
proc url_GetInsights_593389(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInsights_593388(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593390 = query.getOrDefault("MaxResults")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "MaxResults", valid_593390
  var valid_593391 = query.getOrDefault("NextToken")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "NextToken", valid_593391
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
  var valid_593392 = header.getOrDefault("X-Amz-Signature")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Signature", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Content-Sha256", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Date")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Date", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Credential")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Credential", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Security-Token")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Security-Token", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Algorithm")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Algorithm", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-SignedHeaders", valid_593398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593400: Call_GetInsights_593387; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists and describes insights that insight ARNs specify.
  ## 
  let valid = call_593400.validator(path, query, header, formData, body)
  let scheme = call_593400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593400.url(scheme.get, call_593400.host, call_593400.base,
                         call_593400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593400, url, valid)

proc call*(call_593401: Call_GetInsights_593387; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getInsights
  ## Lists and describes insights that insight ARNs specify.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593402 = newJObject()
  var body_593403 = newJObject()
  add(query_593402, "MaxResults", newJString(MaxResults))
  add(query_593402, "NextToken", newJString(NextToken))
  if body != nil:
    body_593403 = body
  result = call_593401.call(nil, query_593402, nil, nil, body_593403)

var getInsights* = Call_GetInsights_593387(name: "getInsights",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/insights/get",
                                        validator: validate_GetInsights_593388,
                                        base: "/", url: url_GetInsights_593389,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_593404 = ref object of OpenApiRestCall_592364
proc url_GetInvitationsCount_593406(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInvitationsCount_593405(path: JsonNode; query: JsonNode;
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
  var valid_593407 = header.getOrDefault("X-Amz-Signature")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-Signature", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Content-Sha256", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-Date")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Date", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-Credential")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Credential", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Security-Token")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Security-Token", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Algorithm")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Algorithm", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-SignedHeaders", valid_593413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593414: Call_GetInvitationsCount_593404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  ## 
  let valid = call_593414.validator(path, query, header, formData, body)
  let scheme = call_593414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593414.url(scheme.get, call_593414.host, call_593414.base,
                         call_593414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593414, url, valid)

proc call*(call_593415: Call_GetInvitationsCount_593404): Recallable =
  ## getInvitationsCount
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  result = call_593415.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_593404(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/invitations/count",
    validator: validate_GetInvitationsCount_593405, base: "/",
    url: url_GetInvitationsCount_593406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_593416 = ref object of OpenApiRestCall_592364
proc url_GetMembers_593418(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMembers_593417(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593419 = header.getOrDefault("X-Amz-Signature")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-Signature", valid_593419
  var valid_593420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593420 = validateParameter(valid_593420, JString, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "X-Amz-Content-Sha256", valid_593420
  var valid_593421 = header.getOrDefault("X-Amz-Date")
  valid_593421 = validateParameter(valid_593421, JString, required = false,
                                 default = nil)
  if valid_593421 != nil:
    section.add "X-Amz-Date", valid_593421
  var valid_593422 = header.getOrDefault("X-Amz-Credential")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "X-Amz-Credential", valid_593422
  var valid_593423 = header.getOrDefault("X-Amz-Security-Token")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "X-Amz-Security-Token", valid_593423
  var valid_593424 = header.getOrDefault("X-Amz-Algorithm")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "X-Amz-Algorithm", valid_593424
  var valid_593425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593425 = validateParameter(valid_593425, JString, required = false,
                                 default = nil)
  if valid_593425 != nil:
    section.add "X-Amz-SignedHeaders", valid_593425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593427: Call_GetMembers_593416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ## 
  let valid = call_593427.validator(path, query, header, formData, body)
  let scheme = call_593427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593427.url(scheme.get, call_593427.host, call_593427.base,
                         call_593427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593427, url, valid)

proc call*(call_593428: Call_GetMembers_593416; body: JsonNode): Recallable =
  ## getMembers
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ##   body: JObject (required)
  var body_593429 = newJObject()
  if body != nil:
    body_593429 = body
  result = call_593428.call(nil, nil, nil, nil, body_593429)

var getMembers* = Call_GetMembers_593416(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "securityhub.amazonaws.com",
                                      route: "/members/get",
                                      validator: validate_GetMembers_593417,
                                      base: "/", url: url_GetMembers_593418,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_593430 = ref object of OpenApiRestCall_592364
proc url_InviteMembers_593432(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_InviteMembers_593431(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593433 = header.getOrDefault("X-Amz-Signature")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Signature", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Content-Sha256", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-Date")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-Date", valid_593435
  var valid_593436 = header.getOrDefault("X-Amz-Credential")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-Credential", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-Security-Token")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-Security-Token", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-Algorithm")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-Algorithm", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-SignedHeaders", valid_593439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593441: Call_InviteMembers_593430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ## 
  let valid = call_593441.validator(path, query, header, formData, body)
  let scheme = call_593441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593441.url(scheme.get, call_593441.host, call_593441.base,
                         call_593441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593441, url, valid)

proc call*(call_593442: Call_InviteMembers_593430; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ##   body: JObject (required)
  var body_593443 = newJObject()
  if body != nil:
    body_593443 = body
  result = call_593442.call(nil, nil, nil, nil, body_593443)

var inviteMembers* = Call_InviteMembers_593430(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/invite", validator: validate_InviteMembers_593431, base: "/",
    url: url_InviteMembers_593432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_593444 = ref object of OpenApiRestCall_592364
proc url_ListInvitations_593446(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInvitations_593445(path: JsonNode; query: JsonNode;
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
  var valid_593447 = query.getOrDefault("MaxResults")
  valid_593447 = validateParameter(valid_593447, JInt, required = false, default = nil)
  if valid_593447 != nil:
    section.add "MaxResults", valid_593447
  var valid_593448 = query.getOrDefault("NextToken")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "NextToken", valid_593448
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
  var valid_593449 = header.getOrDefault("X-Amz-Signature")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Signature", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Content-Sha256", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Date")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Date", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Credential")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Credential", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-Security-Token")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-Security-Token", valid_593453
  var valid_593454 = header.getOrDefault("X-Amz-Algorithm")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Algorithm", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-SignedHeaders", valid_593455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593456: Call_ListInvitations_593444; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  let valid = call_593456.validator(path, query, header, formData, body)
  let scheme = call_593456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593456.url(scheme.get, call_593456.host, call_593456.base,
                         call_593456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593456, url, valid)

proc call*(call_593457: Call_ListInvitations_593444; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## listInvitations
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data. 
  var query_593458 = newJObject()
  add(query_593458, "MaxResults", newJInt(MaxResults))
  add(query_593458, "NextToken", newJString(NextToken))
  result = call_593457.call(nil, query_593458, nil, nil, nil)

var listInvitations* = Call_ListInvitations_593444(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_593445, base: "/",
    url: url_ListInvitations_593446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593473 = ref object of OpenApiRestCall_592364
proc url_TagResource_593475(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_593474(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593476 = path.getOrDefault("ResourceArn")
  valid_593476 = validateParameter(valid_593476, JString, required = true,
                                 default = nil)
  if valid_593476 != nil:
    section.add "ResourceArn", valid_593476
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
  var valid_593477 = header.getOrDefault("X-Amz-Signature")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-Signature", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Content-Sha256", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Date")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Date", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-Credential")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-Credential", valid_593480
  var valid_593481 = header.getOrDefault("X-Amz-Security-Token")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-Security-Token", valid_593481
  var valid_593482 = header.getOrDefault("X-Amz-Algorithm")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-Algorithm", valid_593482
  var valid_593483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-SignedHeaders", valid_593483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593485: Call_TagResource_593473; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a resource.
  ## 
  let valid = call_593485.validator(path, query, header, formData, body)
  let scheme = call_593485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593485.url(scheme.get, call_593485.host, call_593485.base,
                         call_593485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593485, url, valid)

proc call*(call_593486: Call_TagResource_593473; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to apply the tags to.
  ##   body: JObject (required)
  var path_593487 = newJObject()
  var body_593488 = newJObject()
  add(path_593487, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_593488 = body
  result = call_593486.call(path_593487, nil, nil, nil, body_593488)

var tagResource* = Call_TagResource_593473(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_593474,
                                        base: "/", url: url_TagResource_593475,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593459 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593461(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_593460(path: JsonNode; query: JsonNode;
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
  var valid_593462 = path.getOrDefault("ResourceArn")
  valid_593462 = validateParameter(valid_593462, JString, required = true,
                                 default = nil)
  if valid_593462 != nil:
    section.add "ResourceArn", valid_593462
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
  var valid_593463 = header.getOrDefault("X-Amz-Signature")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-Signature", valid_593463
  var valid_593464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Content-Sha256", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-Date")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Date", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-Credential")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-Credential", valid_593466
  var valid_593467 = header.getOrDefault("X-Amz-Security-Token")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-Security-Token", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-Algorithm")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-Algorithm", valid_593468
  var valid_593469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-SignedHeaders", valid_593469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593470: Call_ListTagsForResource_593459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags associated with a resource.
  ## 
  let valid = call_593470.validator(path, query, header, formData, body)
  let scheme = call_593470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593470.url(scheme.get, call_593470.host, call_593470.base,
                         call_593470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593470, url, valid)

proc call*(call_593471: Call_ListTagsForResource_593459; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags for.
  var path_593472 = newJObject()
  add(path_593472, "ResourceArn", newJString(ResourceArn))
  result = call_593471.call(path_593472, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_593459(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_593460, base: "/",
    url: url_ListTagsForResource_593461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593489 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593491(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_593490(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593492 = path.getOrDefault("ResourceArn")
  valid_593492 = validateParameter(valid_593492, JString, required = true,
                                 default = nil)
  if valid_593492 != nil:
    section.add "ResourceArn", valid_593492
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_593493 = query.getOrDefault("tagKeys")
  valid_593493 = validateParameter(valid_593493, JArray, required = true, default = nil)
  if valid_593493 != nil:
    section.add "tagKeys", valid_593493
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
  var valid_593494 = header.getOrDefault("X-Amz-Signature")
  valid_593494 = validateParameter(valid_593494, JString, required = false,
                                 default = nil)
  if valid_593494 != nil:
    section.add "X-Amz-Signature", valid_593494
  var valid_593495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "X-Amz-Content-Sha256", valid_593495
  var valid_593496 = header.getOrDefault("X-Amz-Date")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "X-Amz-Date", valid_593496
  var valid_593497 = header.getOrDefault("X-Amz-Credential")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "X-Amz-Credential", valid_593497
  var valid_593498 = header.getOrDefault("X-Amz-Security-Token")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Security-Token", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Algorithm")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Algorithm", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-SignedHeaders", valid_593500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593501: Call_UntagResource_593489; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a resource.
  ## 
  let valid = call_593501.validator(path, query, header, formData, body)
  let scheme = call_593501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593501.url(scheme.get, call_593501.host, call_593501.base,
                         call_593501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593501, url, valid)

proc call*(call_593502: Call_UntagResource_593489; ResourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to remove the tags from.
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  var path_593503 = newJObject()
  var query_593504 = newJObject()
  add(path_593503, "ResourceArn", newJString(ResourceArn))
  if tagKeys != nil:
    query_593504.add "tagKeys", tagKeys
  result = call_593502.call(path_593503, query_593504, nil, nil, nil)

var untagResource* = Call_UntagResource_593489(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_593490,
    base: "/", url: url_UntagResource_593491, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
