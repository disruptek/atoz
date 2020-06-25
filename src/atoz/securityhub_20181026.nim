
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS SecurityHub
## version: 2018-10-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Security Hub provides you with a comprehensive view of the security state of your AWS environment and resources. It also provides you with the readiness status of your environment based on controls from supported security standards. Security Hub collects security data from AWS accounts, services, and integrated third-party products and helps you analyze security trends in your environment to identify the highest priority security issues. For more information about Security Hub, see the <i> <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html">AWS Security Hub User Guide</a> </i>.</p> <p>When you use operations in the Security Hub API, the requests are executed only in the AWS Region that is currently active or in the specific AWS Region that you specify in your request. Any configuration or settings change that results from the operation is applied only to that Region. To make the same change in other Regions, execute the same command for each Region to apply the change to.</p> <p>For example, if your Region is set to <code>us-west-2</code>, when you use <code> <a>CreateMembers</a> </code> to add a member account to Security Hub, the association of the member account with the master account is created only in the <code>us-west-2</code> Region. Security Hub must be enabled for the member account in the same Region that the invitation was sent from.</p> <p>The following throttling limits apply to using Security Hub API operations.</p> <ul> <li> <p> <code> <a>GetFindings</a> </code> - <code>RateLimit</code> of 3 requests per second. <code>BurstLimit</code> of 6 requests per second.</p> </li> <li> <p> <code> <a>UpdateFindings</a> </code> - <code>RateLimit</code> of 1 request per second. <code>BurstLimit</code> of 5 requests per second.</p> </li> <li> <p>All other operations - <code>RateLimit</code> of 10 requests per second. <code>BurstLimit</code> of 30 requests per second.</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/securityhub/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
    if required:
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AcceptInvitation_21626010 = ref object of OpenApiRestCall_21625435
proc url_AcceptInvitation_21626012(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptInvitation_21626011(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from.</p> <p>When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.</p>
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
  var valid_21626013 = header.getOrDefault("X-Amz-Date")
  valid_21626013 = validateParameter(valid_21626013, JString, required = false,
                                   default = nil)
  if valid_21626013 != nil:
    section.add "X-Amz-Date", valid_21626013
  var valid_21626014 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626014 = validateParameter(valid_21626014, JString, required = false,
                                   default = nil)
  if valid_21626014 != nil:
    section.add "X-Amz-Security-Token", valid_21626014
  var valid_21626015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626015 = validateParameter(valid_21626015, JString, required = false,
                                   default = nil)
  if valid_21626015 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626015
  var valid_21626016 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626016 = validateParameter(valid_21626016, JString, required = false,
                                   default = nil)
  if valid_21626016 != nil:
    section.add "X-Amz-Algorithm", valid_21626016
  var valid_21626017 = header.getOrDefault("X-Amz-Signature")
  valid_21626017 = validateParameter(valid_21626017, JString, required = false,
                                   default = nil)
  if valid_21626017 != nil:
    section.add "X-Amz-Signature", valid_21626017
  var valid_21626018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626018 = validateParameter(valid_21626018, JString, required = false,
                                   default = nil)
  if valid_21626018 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626018
  var valid_21626019 = header.getOrDefault("X-Amz-Credential")
  valid_21626019 = validateParameter(valid_21626019, JString, required = false,
                                   default = nil)
  if valid_21626019 != nil:
    section.add "X-Amz-Credential", valid_21626019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626021: Call_AcceptInvitation_21626010; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from.</p> <p>When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.</p>
  ## 
  let valid = call_21626021.validator(path, query, header, formData, body, _)
  let scheme = call_21626021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626021.makeUrl(scheme.get, call_21626021.host, call_21626021.base,
                               call_21626021.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626021, uri, valid, _)

proc call*(call_21626022: Call_AcceptInvitation_21626010; body: JsonNode): Recallable =
  ## acceptInvitation
  ## <p>Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from.</p> <p>When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.</p>
  ##   body: JObject (required)
  var body_21626023 = newJObject()
  if body != nil:
    body_21626023 = body
  result = call_21626022.call(nil, nil, nil, nil, body_21626023)

var acceptInvitation* = Call_AcceptInvitation_21626010(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_AcceptInvitation_21626011, base: "/",
    makeUrl: url_AcceptInvitation_21626012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetMasterAccount_21625781(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMasterAccount_21625780(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides the details for the Security Hub master account for the current member account. 
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
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Algorithm", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Signature")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Signature", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Credential")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Credential", valid_21625888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625913: Call_GetMasterAccount_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides the details for the Security Hub master account for the current member account. 
  ## 
  let valid = call_21625913.validator(path, query, header, formData, body, _)
  let scheme = call_21625913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625913.makeUrl(scheme.get, call_21625913.host, call_21625913.base,
                               call_21625913.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625913, uri, valid, _)

proc call*(call_21625976: Call_GetMasterAccount_21625779): Recallable =
  ## getMasterAccount
  ## Provides the details for the Security Hub master account for the current member account. 
  result = call_21625976.call(nil, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_21625779(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_GetMasterAccount_21625780, base: "/",
    makeUrl: url_GetMasterAccount_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisableStandards_21626026 = ref object of OpenApiRestCall_21625435
proc url_BatchDisableStandards_21626028(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisableStandards_21626027(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Security Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
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
  var valid_21626029 = header.getOrDefault("X-Amz-Date")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-Date", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Security-Token", valid_21626030
  var valid_21626031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626031
  var valid_21626032 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Algorithm", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Signature")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Signature", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Credential")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Credential", valid_21626035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626037: Call_BatchDisableStandards_21626026;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Security Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
  ## 
  let valid = call_21626037.validator(path, query, header, formData, body, _)
  let scheme = call_21626037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626037.makeUrl(scheme.get, call_21626037.host, call_21626037.base,
                               call_21626037.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626037, uri, valid, _)

proc call*(call_21626038: Call_BatchDisableStandards_21626026; body: JsonNode): Recallable =
  ## batchDisableStandards
  ## <p>Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Security Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
  ##   body: JObject (required)
  var body_21626039 = newJObject()
  if body != nil:
    body_21626039 = body
  result = call_21626038.call(nil, nil, nil, nil, body_21626039)

var batchDisableStandards* = Call_BatchDisableStandards_21626026(
    name: "batchDisableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/deregister",
    validator: validate_BatchDisableStandards_21626027, base: "/",
    makeUrl: url_BatchDisableStandards_21626028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchEnableStandards_21626040 = ref object of OpenApiRestCall_21625435
proc url_BatchEnableStandards_21626042(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchEnableStandards_21626041(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Enables the standards specified by the provided <code>StandardsArn</code>. To obtain the ARN for a standard, use the <code> <a>DescribeStandards</a> </code> operation.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Security Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
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
  var valid_21626043 = header.getOrDefault("X-Amz-Date")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Date", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Security-Token", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Algorithm", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Signature")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Signature", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Credential")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Credential", valid_21626049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626051: Call_BatchEnableStandards_21626040; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables the standards specified by the provided <code>StandardsArn</code>. To obtain the ARN for a standard, use the <code> <a>DescribeStandards</a> </code> operation.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Security Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
  ## 
  let valid = call_21626051.validator(path, query, header, formData, body, _)
  let scheme = call_21626051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626051.makeUrl(scheme.get, call_21626051.host, call_21626051.base,
                               call_21626051.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626051, uri, valid, _)

proc call*(call_21626052: Call_BatchEnableStandards_21626040; body: JsonNode): Recallable =
  ## batchEnableStandards
  ## <p>Enables the standards specified by the provided <code>StandardsArn</code>. To obtain the ARN for a standard, use the <code> <a>DescribeStandards</a> </code> operation.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Security Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
  ##   body: JObject (required)
  var body_21626053 = newJObject()
  if body != nil:
    body_21626053 = body
  result = call_21626052.call(nil, nil, nil, nil, body_21626053)

var batchEnableStandards* = Call_BatchEnableStandards_21626040(
    name: "batchEnableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/register",
    validator: validate_BatchEnableStandards_21626041, base: "/",
    makeUrl: url_BatchEnableStandards_21626042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchImportFindings_21626054 = ref object of OpenApiRestCall_21625435
proc url_BatchImportFindings_21626056(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchImportFindings_21626055(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub.</p> <p>The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.</p>
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
  var valid_21626057 = header.getOrDefault("X-Amz-Date")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Date", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Security-Token", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Algorithm", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Signature")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Signature", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Credential")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Credential", valid_21626063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626065: Call_BatchImportFindings_21626054; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub.</p> <p>The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.</p>
  ## 
  let valid = call_21626065.validator(path, query, header, formData, body, _)
  let scheme = call_21626065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626065.makeUrl(scheme.get, call_21626065.host, call_21626065.base,
                               call_21626065.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626065, uri, valid, _)

proc call*(call_21626066: Call_BatchImportFindings_21626054; body: JsonNode): Recallable =
  ## batchImportFindings
  ## <p>Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub.</p> <p>The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.</p>
  ##   body: JObject (required)
  var body_21626067 = newJObject()
  if body != nil:
    body_21626067 = body
  result = call_21626066.call(nil, nil, nil, nil, body_21626067)

var batchImportFindings* = Call_BatchImportFindings_21626054(
    name: "batchImportFindings", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/findings/import",
    validator: validate_BatchImportFindings_21626055, base: "/",
    makeUrl: url_BatchImportFindings_21626056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActionTarget_21626068 = ref object of OpenApiRestCall_21625435
proc url_CreateActionTarget_21626070(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateActionTarget_21626069(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a custom action target in Security Hub.</p> <p>You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.</p>
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
  var valid_21626071 = header.getOrDefault("X-Amz-Date")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Date", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Security-Token", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Algorithm", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Signature")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Signature", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Credential")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Credential", valid_21626077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626079: Call_CreateActionTarget_21626068; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a custom action target in Security Hub.</p> <p>You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.</p>
  ## 
  let valid = call_21626079.validator(path, query, header, formData, body, _)
  let scheme = call_21626079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626079.makeUrl(scheme.get, call_21626079.host, call_21626079.base,
                               call_21626079.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626079, uri, valid, _)

proc call*(call_21626080: Call_CreateActionTarget_21626068; body: JsonNode): Recallable =
  ## createActionTarget
  ## <p>Creates a custom action target in Security Hub.</p> <p>You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.</p>
  ##   body: JObject (required)
  var body_21626081 = newJObject()
  if body != nil:
    body_21626081 = body
  result = call_21626080.call(nil, nil, nil, nil, body_21626081)

var createActionTarget* = Call_CreateActionTarget_21626068(
    name: "createActionTarget", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets",
    validator: validate_CreateActionTarget_21626069, base: "/",
    makeUrl: url_CreateActionTarget_21626070, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInsight_21626082 = ref object of OpenApiRestCall_21625435
proc url_CreateInsight_21626084(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInsight_21626083(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation.</p> <p>To group the related findings in the insight, use the <code>GroupByAttribute</code>.</p>
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
  var valid_21626085 = header.getOrDefault("X-Amz-Date")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Date", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Security-Token", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Algorithm", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Signature")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Signature", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Credential")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Credential", valid_21626091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626093: Call_CreateInsight_21626082; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation.</p> <p>To group the related findings in the insight, use the <code>GroupByAttribute</code>.</p>
  ## 
  let valid = call_21626093.validator(path, query, header, formData, body, _)
  let scheme = call_21626093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626093.makeUrl(scheme.get, call_21626093.host, call_21626093.base,
                               call_21626093.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626093, uri, valid, _)

proc call*(call_21626094: Call_CreateInsight_21626082; body: JsonNode): Recallable =
  ## createInsight
  ## <p>Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation.</p> <p>To group the related findings in the insight, use the <code>GroupByAttribute</code>.</p>
  ##   body: JObject (required)
  var body_21626095 = newJObject()
  if body != nil:
    body_21626095 = body
  result = call_21626094.call(nil, nil, nil, nil, body_21626095)

var createInsight* = Call_CreateInsight_21626082(name: "createInsight",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights", validator: validate_CreateInsight_21626083, base: "/",
    makeUrl: url_CreateInsight_21626084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_21626116 = ref object of OpenApiRestCall_21625435
proc url_CreateMembers_21626118(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMembers_21626117(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <code> <a>EnableSecurityHub</a> </code> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <code> <a>InviteMembers</a> </code> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <code> <a>DisassociateFromMasterAccount</a> </code> or <code> <a>DisassociateMembers</a> </code> operation.</p>
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
  var valid_21626119 = header.getOrDefault("X-Amz-Date")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Date", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Security-Token", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Algorithm", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Signature")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Signature", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Credential")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Credential", valid_21626125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626127: Call_CreateMembers_21626116; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <code> <a>EnableSecurityHub</a> </code> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <code> <a>InviteMembers</a> </code> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <code> <a>DisassociateFromMasterAccount</a> </code> or <code> <a>DisassociateMembers</a> </code> operation.</p>
  ## 
  let valid = call_21626127.validator(path, query, header, formData, body, _)
  let scheme = call_21626127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626127.makeUrl(scheme.get, call_21626127.host, call_21626127.base,
                               call_21626127.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626127, uri, valid, _)

proc call*(call_21626128: Call_CreateMembers_21626116; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <code> <a>EnableSecurityHub</a> </code> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <code> <a>InviteMembers</a> </code> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <code> <a>DisassociateFromMasterAccount</a> </code> or <code> <a>DisassociateMembers</a> </code> operation.</p>
  ##   body: JObject (required)
  var body_21626129 = newJObject()
  if body != nil:
    body_21626129 = body
  result = call_21626128.call(nil, nil, nil, nil, body_21626129)

var createMembers* = Call_CreateMembers_21626116(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/members",
    validator: validate_CreateMembers_21626117, base: "/",
    makeUrl: url_CreateMembers_21626118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_21626096 = ref object of OpenApiRestCall_21625435
proc url_ListMembers_21626098(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMembers_21626097(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OnlyAssociated: JBool
  ##                 : <p>Specifies which member accounts to include in the response based on their relationship status with the master account. The default value is <code>TRUE</code>.</p> <p>If <code>OnlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>.</p> <p>If <code>OnlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. </p>
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListMembers</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: JInt
  ##             : The maximum number of items to return in the response. 
  section = newJObject()
  var valid_21626099 = query.getOrDefault("OnlyAssociated")
  valid_21626099 = validateParameter(valid_21626099, JBool, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "OnlyAssociated", valid_21626099
  var valid_21626100 = query.getOrDefault("NextToken")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "NextToken", valid_21626100
  var valid_21626101 = query.getOrDefault("MaxResults")
  valid_21626101 = validateParameter(valid_21626101, JInt, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "MaxResults", valid_21626101
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
  var valid_21626102 = header.getOrDefault("X-Amz-Date")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Date", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Security-Token", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Algorithm", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Signature")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Signature", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Credential")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Credential", valid_21626108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626109: Call_ListMembers_21626096; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  let valid = call_21626109.validator(path, query, header, formData, body, _)
  let scheme = call_21626109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626109.makeUrl(scheme.get, call_21626109.host, call_21626109.base,
                               call_21626109.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626109, uri, valid, _)

proc call*(call_21626110: Call_ListMembers_21626096; OnlyAssociated: bool = false;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current Security Hub master account.
  ##   OnlyAssociated: bool
  ##                 : <p>Specifies which member accounts to include in the response based on their relationship status with the master account. The default value is <code>TRUE</code>.</p> <p>If <code>OnlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>.</p> <p>If <code>OnlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. </p>
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListMembers</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: int
  ##             : The maximum number of items to return in the response. 
  var query_21626112 = newJObject()
  add(query_21626112, "OnlyAssociated", newJBool(OnlyAssociated))
  add(query_21626112, "NextToken", newJString(NextToken))
  add(query_21626112, "MaxResults", newJInt(MaxResults))
  result = call_21626110.call(nil, query_21626112, nil, nil, nil)

var listMembers* = Call_ListMembers_21626096(name: "listMembers",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/members",
    validator: validate_ListMembers_21626097, base: "/", makeUrl: url_ListMembers_21626098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_21626130 = ref object of OpenApiRestCall_21625435
proc url_DeclineInvitations_21626132(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeclineInvitations_21626131(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626133 = header.getOrDefault("X-Amz-Date")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Date", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Security-Token", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Algorithm", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Signature")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Signature", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Credential")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Credential", valid_21626139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626141: Call_DeclineInvitations_21626130; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Declines invitations to become a member account.
  ## 
  let valid = call_21626141.validator(path, query, header, formData, body, _)
  let scheme = call_21626141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626141.makeUrl(scheme.get, call_21626141.host, call_21626141.base,
                               call_21626141.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626141, uri, valid, _)

proc call*(call_21626142: Call_DeclineInvitations_21626130; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations to become a member account.
  ##   body: JObject (required)
  var body_21626143 = newJObject()
  if body != nil:
    body_21626143 = body
  result = call_21626142.call(nil, nil, nil, nil, body_21626143)

var declineInvitations* = Call_DeclineInvitations_21626130(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/invitations/decline",
    validator: validate_DeclineInvitations_21626131, base: "/",
    makeUrl: url_DeclineInvitations_21626132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateActionTarget_21626171 = ref object of OpenApiRestCall_21625435
proc url_UpdateActionTarget_21626173(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateActionTarget_21626172(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626174 = path.getOrDefault("ActionTargetArn")
  valid_21626174 = validateParameter(valid_21626174, JString, required = true,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "ActionTargetArn", valid_21626174
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
  var valid_21626175 = header.getOrDefault("X-Amz-Date")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Date", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Security-Token", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Algorithm", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Signature")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Signature", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Credential")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Credential", valid_21626181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626183: Call_UpdateActionTarget_21626171; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the name and description of a custom action target in Security Hub.
  ## 
  let valid = call_21626183.validator(path, query, header, formData, body, _)
  let scheme = call_21626183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626183.makeUrl(scheme.get, call_21626183.host, call_21626183.base,
                               call_21626183.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626183, uri, valid, _)

proc call*(call_21626184: Call_UpdateActionTarget_21626171; body: JsonNode;
          ActionTargetArn: string): Recallable =
  ## updateActionTarget
  ## Updates the name and description of a custom action target in Security Hub.
  ##   body: JObject (required)
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to update.
  var path_21626185 = newJObject()
  var body_21626186 = newJObject()
  if body != nil:
    body_21626186 = body
  add(path_21626185, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_21626184.call(path_21626185, nil, nil, nil, body_21626186)

var updateActionTarget* = Call_UpdateActionTarget_21626171(
    name: "updateActionTarget", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_UpdateActionTarget_21626172, base: "/",
    makeUrl: url_UpdateActionTarget_21626173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActionTarget_21626144 = ref object of OpenApiRestCall_21625435
proc url_DeleteActionTarget_21626146(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteActionTarget_21626145(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626160 = path.getOrDefault("ActionTargetArn")
  valid_21626160 = validateParameter(valid_21626160, JString, required = true,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "ActionTargetArn", valid_21626160
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
  var valid_21626161 = header.getOrDefault("X-Amz-Date")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Date", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Security-Token", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Algorithm", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Signature")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Signature", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Credential")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Credential", valid_21626167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626168: Call_DeleteActionTarget_21626144; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a custom action target from Security Hub.</p> <p>Deleting a custom action target does not affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.</p>
  ## 
  let valid = call_21626168.validator(path, query, header, formData, body, _)
  let scheme = call_21626168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626168.makeUrl(scheme.get, call_21626168.host, call_21626168.base,
                               call_21626168.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626168, uri, valid, _)

proc call*(call_21626169: Call_DeleteActionTarget_21626144; ActionTargetArn: string): Recallable =
  ## deleteActionTarget
  ## <p>Deletes a custom action target from Security Hub.</p> <p>Deleting a custom action target does not affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.</p>
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to delete.
  var path_21626170 = newJObject()
  add(path_21626170, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_21626169.call(path_21626170, nil, nil, nil, nil)

var deleteActionTarget* = Call_DeleteActionTarget_21626144(
    name: "deleteActionTarget", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_DeleteActionTarget_21626145, base: "/",
    makeUrl: url_DeleteActionTarget_21626146, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInsight_21626201 = ref object of OpenApiRestCall_21625435
proc url_UpdateInsight_21626203(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInsight_21626202(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626204 = path.getOrDefault("InsightArn")
  valid_21626204 = validateParameter(valid_21626204, JString, required = true,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "InsightArn", valid_21626204
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
  var valid_21626205 = header.getOrDefault("X-Amz-Date")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-Date", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Security-Token", valid_21626206
  var valid_21626207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Algorithm", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Signature")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Signature", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Credential")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Credential", valid_21626211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626213: Call_UpdateInsight_21626201; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the Security Hub insight identified by the specified insight ARN.
  ## 
  let valid = call_21626213.validator(path, query, header, formData, body, _)
  let scheme = call_21626213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626213.makeUrl(scheme.get, call_21626213.host, call_21626213.base,
                               call_21626213.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626213, uri, valid, _)

proc call*(call_21626214: Call_UpdateInsight_21626201; InsightArn: string;
          body: JsonNode): Recallable =
  ## updateInsight
  ## Updates the Security Hub insight identified by the specified insight ARN.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight that you want to update.
  ##   body: JObject (required)
  var path_21626215 = newJObject()
  var body_21626216 = newJObject()
  add(path_21626215, "InsightArn", newJString(InsightArn))
  if body != nil:
    body_21626216 = body
  result = call_21626214.call(path_21626215, nil, nil, nil, body_21626216)

var updateInsight* = Call_UpdateInsight_21626201(name: "updateInsight",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_UpdateInsight_21626202,
    base: "/", makeUrl: url_UpdateInsight_21626203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInsight_21626187 = ref object of OpenApiRestCall_21625435
proc url_DeleteInsight_21626189(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInsight_21626188(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626190 = path.getOrDefault("InsightArn")
  valid_21626190 = validateParameter(valid_21626190, JString, required = true,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "InsightArn", valid_21626190
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
  var valid_21626191 = header.getOrDefault("X-Amz-Date")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Date", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Security-Token", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Algorithm", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Signature")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Signature", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Credential")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Credential", valid_21626197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626198: Call_DeleteInsight_21626187; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ## 
  let valid = call_21626198.validator(path, query, header, formData, body, _)
  let scheme = call_21626198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626198.makeUrl(scheme.get, call_21626198.host, call_21626198.base,
                               call_21626198.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626198, uri, valid, _)

proc call*(call_21626199: Call_DeleteInsight_21626187; InsightArn: string): Recallable =
  ## deleteInsight
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight to delete.
  var path_21626200 = newJObject()
  add(path_21626200, "InsightArn", newJString(InsightArn))
  result = call_21626199.call(path_21626200, nil, nil, nil, nil)

var deleteInsight* = Call_DeleteInsight_21626187(name: "deleteInsight",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_DeleteInsight_21626188,
    base: "/", makeUrl: url_DeleteInsight_21626189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_21626217 = ref object of OpenApiRestCall_21625435
proc url_DeleteInvitations_21626219(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInvitations_21626218(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626220 = header.getOrDefault("X-Amz-Date")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-Date", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-Security-Token", valid_21626221
  var valid_21626222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626222
  var valid_21626223 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Algorithm", valid_21626223
  var valid_21626224 = header.getOrDefault("X-Amz-Signature")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "X-Amz-Signature", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Credential")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Credential", valid_21626226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626228: Call_DeleteInvitations_21626217; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes invitations received by the AWS account to become a member account.
  ## 
  let valid = call_21626228.validator(path, query, header, formData, body, _)
  let scheme = call_21626228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626228.makeUrl(scheme.get, call_21626228.host, call_21626228.base,
                               call_21626228.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626228, uri, valid, _)

proc call*(call_21626229: Call_DeleteInvitations_21626217; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations received by the AWS account to become a member account.
  ##   body: JObject (required)
  var body_21626230 = newJObject()
  if body != nil:
    body_21626230 = body
  result = call_21626229.call(nil, nil, nil, nil, body_21626230)

var deleteInvitations* = Call_DeleteInvitations_21626217(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/invitations/delete", validator: validate_DeleteInvitations_21626218,
    base: "/", makeUrl: url_DeleteInvitations_21626219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_21626231 = ref object of OpenApiRestCall_21625435
proc url_DeleteMembers_21626233(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMembers_21626232(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626234 = header.getOrDefault("X-Amz-Date")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Date", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Security-Token", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626236
  var valid_21626237 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Algorithm", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Signature")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Signature", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626239
  var valid_21626240 = header.getOrDefault("X-Amz-Credential")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Credential", valid_21626240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626242: Call_DeleteMembers_21626231; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified member accounts from Security Hub.
  ## 
  let valid = call_21626242.validator(path, query, header, formData, body, _)
  let scheme = call_21626242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626242.makeUrl(scheme.get, call_21626242.host, call_21626242.base,
                               call_21626242.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626242, uri, valid, _)

proc call*(call_21626243: Call_DeleteMembers_21626231; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes the specified member accounts from Security Hub.
  ##   body: JObject (required)
  var body_21626244 = newJObject()
  if body != nil:
    body_21626244 = body
  result = call_21626243.call(nil, nil, nil, nil, body_21626244)

var deleteMembers* = Call_DeleteMembers_21626231(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/delete", validator: validate_DeleteMembers_21626232, base: "/",
    makeUrl: url_DeleteMembers_21626233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActionTargets_21626245 = ref object of OpenApiRestCall_21625435
proc url_DescribeActionTargets_21626247(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActionTargets_21626246(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626248 = query.getOrDefault("NextToken")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "NextToken", valid_21626248
  var valid_21626249 = query.getOrDefault("MaxResults")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "MaxResults", valid_21626249
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
  var valid_21626250 = header.getOrDefault("X-Amz-Date")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Date", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Security-Token", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Algorithm", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Signature")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Signature", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Credential")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Credential", valid_21626256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626258: Call_DescribeActionTargets_21626245;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the custom action targets in Security Hub in your account.
  ## 
  let valid = call_21626258.validator(path, query, header, formData, body, _)
  let scheme = call_21626258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626258.makeUrl(scheme.get, call_21626258.host, call_21626258.base,
                               call_21626258.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626258, uri, valid, _)

proc call*(call_21626259: Call_DescribeActionTargets_21626245; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeActionTargets
  ## Returns a list of the custom action targets in Security Hub in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626260 = newJObject()
  var body_21626261 = newJObject()
  add(query_21626260, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626261 = body
  add(query_21626260, "MaxResults", newJString(MaxResults))
  result = call_21626259.call(nil, query_21626260, nil, nil, body_21626261)

var describeActionTargets* = Call_DescribeActionTargets_21626245(
    name: "describeActionTargets", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets/get",
    validator: validate_DescribeActionTargets_21626246, base: "/",
    makeUrl: url_DescribeActionTargets_21626247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSecurityHub_21626276 = ref object of OpenApiRestCall_21625435
proc url_EnableSecurityHub_21626278(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableSecurityHub_21626277(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Enables Security Hub for your account in the current Region or the Region you specify in the request.</p> <p>When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie.</p> <p>When you use the <code>EnableSecurityHub</code> operation to enable Security Hub, you also automatically enable the CIS AWS Foundations standard. You do not enable the Payment Card Industry Data Security Standard (PCI DSS) standard. To enable a standard, use the <code> <a>BatchEnableStandards</a> </code> operation. To disable a standard, use the <code> <a>BatchDisableStandards</a> </code> operation.</p> <p>To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a> in the <i>AWS Security Hub User Guide</i>.</p>
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
  var valid_21626279 = header.getOrDefault("X-Amz-Date")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Date", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Security-Token", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Algorithm", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Signature")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Signature", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Credential")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Credential", valid_21626285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626287: Call_EnableSecurityHub_21626276; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables Security Hub for your account in the current Region or the Region you specify in the request.</p> <p>When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie.</p> <p>When you use the <code>EnableSecurityHub</code> operation to enable Security Hub, you also automatically enable the CIS AWS Foundations standard. You do not enable the Payment Card Industry Data Security Standard (PCI DSS) standard. To enable a standard, use the <code> <a>BatchEnableStandards</a> </code> operation. To disable a standard, use the <code> <a>BatchDisableStandards</a> </code> operation.</p> <p>To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a> in the <i>AWS Security Hub User Guide</i>.</p>
  ## 
  let valid = call_21626287.validator(path, query, header, formData, body, _)
  let scheme = call_21626287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626287.makeUrl(scheme.get, call_21626287.host, call_21626287.base,
                               call_21626287.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626287, uri, valid, _)

proc call*(call_21626288: Call_EnableSecurityHub_21626276; body: JsonNode): Recallable =
  ## enableSecurityHub
  ## <p>Enables Security Hub for your account in the current Region or the Region you specify in the request.</p> <p>When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie.</p> <p>When you use the <code>EnableSecurityHub</code> operation to enable Security Hub, you also automatically enable the CIS AWS Foundations standard. You do not enable the Payment Card Industry Data Security Standard (PCI DSS) standard. To enable a standard, use the <code> <a>BatchEnableStandards</a> </code> operation. To disable a standard, use the <code> <a>BatchDisableStandards</a> </code> operation.</p> <p>To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a> in the <i>AWS Security Hub User Guide</i>.</p>
  ##   body: JObject (required)
  var body_21626289 = newJObject()
  if body != nil:
    body_21626289 = body
  result = call_21626288.call(nil, nil, nil, nil, body_21626289)

var enableSecurityHub* = Call_EnableSecurityHub_21626276(name: "enableSecurityHub",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/accounts", validator: validate_EnableSecurityHub_21626277, base: "/",
    makeUrl: url_EnableSecurityHub_21626278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHub_21626262 = ref object of OpenApiRestCall_21625435
proc url_DescribeHub_21626264(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHub_21626263(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626265 = query.getOrDefault("HubArn")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "HubArn", valid_21626265
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
  var valid_21626266 = header.getOrDefault("X-Amz-Date")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Date", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Security-Token", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Algorithm", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Signature")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Signature", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Credential")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Credential", valid_21626272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626273: Call_DescribeHub_21626262; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ## 
  let valid = call_21626273.validator(path, query, header, formData, body, _)
  let scheme = call_21626273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626273.makeUrl(scheme.get, call_21626273.host, call_21626273.base,
                               call_21626273.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626273, uri, valid, _)

proc call*(call_21626274: Call_DescribeHub_21626262; HubArn: string = ""): Recallable =
  ## describeHub
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ##   HubArn: string
  ##         : The ARN of the Hub resource to retrieve.
  var query_21626275 = newJObject()
  add(query_21626275, "HubArn", newJString(HubArn))
  result = call_21626274.call(nil, query_21626275, nil, nil, nil)

var describeHub* = Call_DescribeHub_21626262(name: "describeHub",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_DescribeHub_21626263, base: "/", makeUrl: url_DescribeHub_21626264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSecurityHub_21626290 = ref object of OpenApiRestCall_21625435
proc url_DisableSecurityHub_21626292(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableSecurityHub_21626291(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub.</p> <p>When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and cannot be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed.</p> <p>If you want to save your existing findings, you must export them before you disable Security Hub.</p>
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
  var valid_21626293 = header.getOrDefault("X-Amz-Date")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Date", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Security-Token", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Algorithm", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Signature")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Signature", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Credential")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Credential", valid_21626299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626300: Call_DisableSecurityHub_21626290; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub.</p> <p>When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and cannot be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed.</p> <p>If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  ## 
  let valid = call_21626300.validator(path, query, header, formData, body, _)
  let scheme = call_21626300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626300.makeUrl(scheme.get, call_21626300.host, call_21626300.base,
                               call_21626300.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626300, uri, valid, _)

proc call*(call_21626301: Call_DisableSecurityHub_21626290): Recallable =
  ## disableSecurityHub
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub.</p> <p>When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and cannot be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed.</p> <p>If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  result = call_21626301.call(nil, nil, nil, nil, nil)

var disableSecurityHub* = Call_DisableSecurityHub_21626290(
    name: "disableSecurityHub", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_DisableSecurityHub_21626291, base: "/",
    makeUrl: url_DisableSecurityHub_21626292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProducts_21626302 = ref object of OpenApiRestCall_21625435
proc url_DescribeProducts_21626304(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProducts_21626303(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the available products that you can subscribe to and integrate with Security Hub in order to consolidate findings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeProducts</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: JInt
  ##             : The maximum number of results to return.
  section = newJObject()
  var valid_21626305 = query.getOrDefault("NextToken")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "NextToken", valid_21626305
  var valid_21626306 = query.getOrDefault("MaxResults")
  valid_21626306 = validateParameter(valid_21626306, JInt, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "MaxResults", valid_21626306
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
  var valid_21626307 = header.getOrDefault("X-Amz-Date")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Date", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Security-Token", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Algorithm", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Signature")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Signature", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Credential")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Credential", valid_21626313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626314: Call_DescribeProducts_21626302; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the available products that you can subscribe to and integrate with Security Hub in order to consolidate findings.
  ## 
  let valid = call_21626314.validator(path, query, header, formData, body, _)
  let scheme = call_21626314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626314.makeUrl(scheme.get, call_21626314.host, call_21626314.base,
                               call_21626314.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626314, uri, valid, _)

proc call*(call_21626315: Call_DescribeProducts_21626302; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## describeProducts
  ## Returns information about the available products that you can subscribe to and integrate with Security Hub in order to consolidate findings.
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeProducts</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: int
  ##             : The maximum number of results to return.
  var query_21626316 = newJObject()
  add(query_21626316, "NextToken", newJString(NextToken))
  add(query_21626316, "MaxResults", newJInt(MaxResults))
  result = call_21626315.call(nil, query_21626316, nil, nil, nil)

var describeProducts* = Call_DescribeProducts_21626302(name: "describeProducts",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/products",
    validator: validate_DescribeProducts_21626303, base: "/",
    makeUrl: url_DescribeProducts_21626304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStandards_21626317 = ref object of OpenApiRestCall_21625435
proc url_DescribeStandards_21626319(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStandards_21626318(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of the available standards in Security Hub.</p> <p>For each standard, the results include the standard ARN, the name, and a description. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeStandards</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: JInt
  ##             : The maximum number of standards to return.
  section = newJObject()
  var valid_21626320 = query.getOrDefault("NextToken")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "NextToken", valid_21626320
  var valid_21626321 = query.getOrDefault("MaxResults")
  valid_21626321 = validateParameter(valid_21626321, JInt, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "MaxResults", valid_21626321
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
  var valid_21626322 = header.getOrDefault("X-Amz-Date")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Date", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Security-Token", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Algorithm", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Signature")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Signature", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Credential")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Credential", valid_21626328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626329: Call_DescribeStandards_21626317; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the available standards in Security Hub.</p> <p>For each standard, the results include the standard ARN, the name, and a description. </p>
  ## 
  let valid = call_21626329.validator(path, query, header, formData, body, _)
  let scheme = call_21626329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626329.makeUrl(scheme.get, call_21626329.host, call_21626329.base,
                               call_21626329.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626329, uri, valid, _)

proc call*(call_21626330: Call_DescribeStandards_21626317; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## describeStandards
  ## <p>Returns a list of the available standards in Security Hub.</p> <p>For each standard, the results include the standard ARN, the name, and a description. </p>
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeStandards</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: int
  ##             : The maximum number of standards to return.
  var query_21626331 = newJObject()
  add(query_21626331, "NextToken", newJString(NextToken))
  add(query_21626331, "MaxResults", newJInt(MaxResults))
  result = call_21626330.call(nil, query_21626331, nil, nil, nil)

var describeStandards* = Call_DescribeStandards_21626317(name: "describeStandards",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/standards", validator: validate_DescribeStandards_21626318, base: "/",
    makeUrl: url_DescribeStandards_21626319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStandardsControls_21626332 = ref object of OpenApiRestCall_21625435
proc url_DescribeStandardsControls_21626334(protocol: Scheme; host: string;
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

proc validate_DescribeStandardsControls_21626333(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of security standards controls.</p> <p>For each control, the results include information about whether it is currently enabled, the severity, and a link to remediation information.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   StandardsSubscriptionArn: JString (required)
  ##                           : The ARN of a resource that represents your subscription to a supported standard.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `StandardsSubscriptionArn` field"
  var valid_21626335 = path.getOrDefault("StandardsSubscriptionArn")
  valid_21626335 = validateParameter(valid_21626335, JString, required = true,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "StandardsSubscriptionArn", valid_21626335
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeStandardsControls</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: JInt
  ##             : The maximum number of security standard controls to return.
  section = newJObject()
  var valid_21626336 = query.getOrDefault("NextToken")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "NextToken", valid_21626336
  var valid_21626337 = query.getOrDefault("MaxResults")
  valid_21626337 = validateParameter(valid_21626337, JInt, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "MaxResults", valid_21626337
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
  var valid_21626338 = header.getOrDefault("X-Amz-Date")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Date", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Security-Token", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Algorithm", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-Signature")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-Signature", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Credential")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-Credential", valid_21626344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626345: Call_DescribeStandardsControls_21626332;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of security standards controls.</p> <p>For each control, the results include information about whether it is currently enabled, the severity, and a link to remediation information.</p>
  ## 
  let valid = call_21626345.validator(path, query, header, formData, body, _)
  let scheme = call_21626345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626345.makeUrl(scheme.get, call_21626345.host, call_21626345.base,
                               call_21626345.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626345, uri, valid, _)

proc call*(call_21626346: Call_DescribeStandardsControls_21626332;
          StandardsSubscriptionArn: string; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## describeStandardsControls
  ## <p>Returns a list of security standards controls.</p> <p>For each control, the results include information about whether it is currently enabled, the severity, and a link to remediation information.</p>
  ##   StandardsSubscriptionArn: string (required)
  ##                           : The ARN of a resource that represents your subscription to a supported standard.
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeStandardsControls</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: int
  ##             : The maximum number of security standard controls to return.
  var path_21626347 = newJObject()
  var query_21626348 = newJObject()
  add(path_21626347, "StandardsSubscriptionArn",
      newJString(StandardsSubscriptionArn))
  add(query_21626348, "NextToken", newJString(NextToken))
  add(query_21626348, "MaxResults", newJInt(MaxResults))
  result = call_21626346.call(path_21626347, query_21626348, nil, nil, nil)

var describeStandardsControls* = Call_DescribeStandardsControls_21626332(
    name: "describeStandardsControls", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com",
    route: "/standards/controls/{StandardsSubscriptionArn}",
    validator: validate_DescribeStandardsControls_21626333, base: "/",
    makeUrl: url_DescribeStandardsControls_21626334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableImportFindingsForProduct_21626349 = ref object of OpenApiRestCall_21625435
proc url_DisableImportFindingsForProduct_21626351(protocol: Scheme; host: string;
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

proc validate_DisableImportFindingsForProduct_21626350(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Disables the integration of the specified product with Security Hub. After the integration is disabled, findings from that product are no longer sent to Security Hub.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ProductSubscriptionArn: JString (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ProductSubscriptionArn` field"
  var valid_21626352 = path.getOrDefault("ProductSubscriptionArn")
  valid_21626352 = validateParameter(valid_21626352, JString, required = true,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "ProductSubscriptionArn", valid_21626352
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
  var valid_21626353 = header.getOrDefault("X-Amz-Date")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Date", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Security-Token", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Algorithm", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-Signature")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Signature", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Credential")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Credential", valid_21626359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626360: Call_DisableImportFindingsForProduct_21626349;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the integration of the specified product with Security Hub. After the integration is disabled, findings from that product are no longer sent to Security Hub.
  ## 
  let valid = call_21626360.validator(path, query, header, formData, body, _)
  let scheme = call_21626360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626360.makeUrl(scheme.get, call_21626360.host, call_21626360.base,
                               call_21626360.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626360, uri, valid, _)

proc call*(call_21626361: Call_DisableImportFindingsForProduct_21626349;
          ProductSubscriptionArn: string): Recallable =
  ## disableImportFindingsForProduct
  ## Disables the integration of the specified product with Security Hub. After the integration is disabled, findings from that product are no longer sent to Security Hub.
  ##   ProductSubscriptionArn: string (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  var path_21626362 = newJObject()
  add(path_21626362, "ProductSubscriptionArn", newJString(ProductSubscriptionArn))
  result = call_21626361.call(path_21626362, nil, nil, nil, nil)

var disableImportFindingsForProduct* = Call_DisableImportFindingsForProduct_21626349(
    name: "disableImportFindingsForProduct", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com",
    route: "/productSubscriptions/{ProductSubscriptionArn}",
    validator: validate_DisableImportFindingsForProduct_21626350, base: "/",
    makeUrl: url_DisableImportFindingsForProduct_21626351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_21626363 = ref object of OpenApiRestCall_21625435
proc url_DisassociateFromMasterAccount_21626365(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateFromMasterAccount_21626364(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626366 = header.getOrDefault("X-Amz-Date")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Date", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Security-Token", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Algorithm", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Signature")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Signature", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Credential")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Credential", valid_21626372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626373: Call_DisassociateFromMasterAccount_21626363;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the current Security Hub member account from the associated master account.
  ## 
  let valid = call_21626373.validator(path, query, header, formData, body, _)
  let scheme = call_21626373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626373.makeUrl(scheme.get, call_21626373.host, call_21626373.base,
                               call_21626373.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626373, uri, valid, _)

proc call*(call_21626374: Call_DisassociateFromMasterAccount_21626363): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current Security Hub member account from the associated master account.
  result = call_21626374.call(nil, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_21626363(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_21626364, base: "/",
    makeUrl: url_DisassociateFromMasterAccount_21626365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_21626375 = ref object of OpenApiRestCall_21625435
proc url_DisassociateMembers_21626377(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateMembers_21626376(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626378 = header.getOrDefault("X-Amz-Date")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Date", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Security-Token", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Algorithm", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Signature")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Signature", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Credential")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Credential", valid_21626384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626386: Call_DisassociateMembers_21626375; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified member accounts from the associated master account.
  ## 
  let valid = call_21626386.validator(path, query, header, formData, body, _)
  let scheme = call_21626386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626386.makeUrl(scheme.get, call_21626386.host, call_21626386.base,
                               call_21626386.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626386, uri, valid, _)

proc call*(call_21626387: Call_DisassociateMembers_21626375; body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates the specified member accounts from the associated master account.
  ##   body: JObject (required)
  var body_21626388 = newJObject()
  if body != nil:
    body_21626388 = body
  result = call_21626387.call(nil, nil, nil, nil, body_21626388)

var disassociateMembers* = Call_DisassociateMembers_21626375(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/members/disassociate",
    validator: validate_DisassociateMembers_21626376, base: "/",
    makeUrl: url_DisassociateMembers_21626377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableImportFindingsForProduct_21626404 = ref object of OpenApiRestCall_21625435
proc url_EnableImportFindingsForProduct_21626406(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableImportFindingsForProduct_21626405(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub.</p> <p>When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.</p>
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
  var valid_21626407 = header.getOrDefault("X-Amz-Date")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Date", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Security-Token", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Algorithm", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Signature")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Signature", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Credential")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Credential", valid_21626413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626415: Call_EnableImportFindingsForProduct_21626404;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub.</p> <p>When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.</p>
  ## 
  let valid = call_21626415.validator(path, query, header, formData, body, _)
  let scheme = call_21626415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626415.makeUrl(scheme.get, call_21626415.host, call_21626415.base,
                               call_21626415.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626415, uri, valid, _)

proc call*(call_21626416: Call_EnableImportFindingsForProduct_21626404;
          body: JsonNode): Recallable =
  ## enableImportFindingsForProduct
  ## <p>Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub.</p> <p>When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.</p>
  ##   body: JObject (required)
  var body_21626417 = newJObject()
  if body != nil:
    body_21626417 = body
  result = call_21626416.call(nil, nil, nil, nil, body_21626417)

var enableImportFindingsForProduct* = Call_EnableImportFindingsForProduct_21626404(
    name: "enableImportFindingsForProduct", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_EnableImportFindingsForProduct_21626405, base: "/",
    makeUrl: url_EnableImportFindingsForProduct_21626406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnabledProductsForImport_21626389 = ref object of OpenApiRestCall_21625435
proc url_ListEnabledProductsForImport_21626391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEnabledProductsForImport_21626390(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists all findings-generating solutions (products) that you are subscribed to receive findings from in Security Hub.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: JInt
  ##             : The maximum number of items to return in the response.
  section = newJObject()
  var valid_21626392 = query.getOrDefault("NextToken")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "NextToken", valid_21626392
  var valid_21626393 = query.getOrDefault("MaxResults")
  valid_21626393 = validateParameter(valid_21626393, JInt, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "MaxResults", valid_21626393
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
  var valid_21626394 = header.getOrDefault("X-Amz-Date")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Date", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Security-Token", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Algorithm", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Signature")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Signature", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Credential")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Credential", valid_21626400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626401: Call_ListEnabledProductsForImport_21626389;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all findings-generating solutions (products) that you are subscribed to receive findings from in Security Hub.
  ## 
  let valid = call_21626401.validator(path, query, header, formData, body, _)
  let scheme = call_21626401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626401.makeUrl(scheme.get, call_21626401.host, call_21626401.base,
                               call_21626401.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626401, uri, valid, _)

proc call*(call_21626402: Call_ListEnabledProductsForImport_21626389;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listEnabledProductsForImport
  ## Lists all findings-generating solutions (products) that you are subscribed to receive findings from in Security Hub.
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: int
  ##             : The maximum number of items to return in the response.
  var query_21626403 = newJObject()
  add(query_21626403, "NextToken", newJString(NextToken))
  add(query_21626403, "MaxResults", newJInt(MaxResults))
  result = call_21626402.call(nil, query_21626403, nil, nil, nil)

var listEnabledProductsForImport* = Call_ListEnabledProductsForImport_21626389(
    name: "listEnabledProductsForImport", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_ListEnabledProductsForImport_21626390, base: "/",
    makeUrl: url_ListEnabledProductsForImport_21626391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnabledStandards_21626418 = ref object of OpenApiRestCall_21625435
proc url_GetEnabledStandards_21626420(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEnabledStandards_21626419(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the standards that are currently enabled.
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
  var valid_21626421 = query.getOrDefault("NextToken")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "NextToken", valid_21626421
  var valid_21626422 = query.getOrDefault("MaxResults")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "MaxResults", valid_21626422
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
  var valid_21626423 = header.getOrDefault("X-Amz-Date")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Date", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Security-Token", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Algorithm", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Signature")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Signature", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Credential")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Credential", valid_21626429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626431: Call_GetEnabledStandards_21626418; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the standards that are currently enabled.
  ## 
  let valid = call_21626431.validator(path, query, header, formData, body, _)
  let scheme = call_21626431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626431.makeUrl(scheme.get, call_21626431.host, call_21626431.base,
                               call_21626431.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626431, uri, valid, _)

proc call*(call_21626432: Call_GetEnabledStandards_21626418; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getEnabledStandards
  ## Returns a list of the standards that are currently enabled.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626433 = newJObject()
  var body_21626434 = newJObject()
  add(query_21626433, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626434 = body
  add(query_21626433, "MaxResults", newJString(MaxResults))
  result = call_21626432.call(nil, query_21626433, nil, nil, body_21626434)

var getEnabledStandards* = Call_GetEnabledStandards_21626418(
    name: "getEnabledStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/get",
    validator: validate_GetEnabledStandards_21626419, base: "/",
    makeUrl: url_GetEnabledStandards_21626420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_21626435 = ref object of OpenApiRestCall_21625435
proc url_GetFindings_21626437(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFindings_21626436(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626438 = query.getOrDefault("NextToken")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "NextToken", valid_21626438
  var valid_21626439 = query.getOrDefault("MaxResults")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "MaxResults", valid_21626439
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
  var valid_21626440 = header.getOrDefault("X-Amz-Date")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Date", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Security-Token", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-Algorithm", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Signature")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Signature", valid_21626444
  var valid_21626445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Credential")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Credential", valid_21626446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626448: Call_GetFindings_21626435; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of findings that match the specified criteria.
  ## 
  let valid = call_21626448.validator(path, query, header, formData, body, _)
  let scheme = call_21626448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626448.makeUrl(scheme.get, call_21626448.host, call_21626448.base,
                               call_21626448.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626448, uri, valid, _)

proc call*(call_21626449: Call_GetFindings_21626435; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getFindings
  ## Returns a list of findings that match the specified criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626450 = newJObject()
  var body_21626451 = newJObject()
  add(query_21626450, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626451 = body
  add(query_21626450, "MaxResults", newJString(MaxResults))
  result = call_21626449.call(nil, query_21626450, nil, nil, body_21626451)

var getFindings* = Call_GetFindings_21626435(name: "getFindings",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_GetFindings_21626436, base: "/",
    makeUrl: url_GetFindings_21626437, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_21626452 = ref object of OpenApiRestCall_21625435
proc url_UpdateFindings_21626454(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFindings_21626453(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626455 = header.getOrDefault("X-Amz-Date")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Date", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Security-Token", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-Algorithm", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Signature")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Signature", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Credential")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Credential", valid_21626461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626463: Call_UpdateFindings_21626452; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ## 
  let valid = call_21626463.validator(path, query, header, formData, body, _)
  let scheme = call_21626463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626463.makeUrl(scheme.get, call_21626463.host, call_21626463.base,
                               call_21626463.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626463, uri, valid, _)

proc call*(call_21626464: Call_UpdateFindings_21626452; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ##   body: JObject (required)
  var body_21626465 = newJObject()
  if body != nil:
    body_21626465 = body
  result = call_21626464.call(nil, nil, nil, nil, body_21626465)

var updateFindings* = Call_UpdateFindings_21626452(name: "updateFindings",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_UpdateFindings_21626453, base: "/",
    makeUrl: url_UpdateFindings_21626454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsightResults_21626466 = ref object of OpenApiRestCall_21625435
proc url_GetInsightResults_21626468(protocol: Scheme; host: string; base: string;
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

proc validate_GetInsightResults_21626467(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626469 = path.getOrDefault("InsightArn")
  valid_21626469 = validateParameter(valid_21626469, JString, required = true,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "InsightArn", valid_21626469
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
  var valid_21626470 = header.getOrDefault("X-Amz-Date")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Date", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Security-Token", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Algorithm", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Signature")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Signature", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Credential")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Credential", valid_21626476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626477: Call_GetInsightResults_21626466; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the results of the Security Hub insight specified by the insight ARN.
  ## 
  let valid = call_21626477.validator(path, query, header, formData, body, _)
  let scheme = call_21626477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626477.makeUrl(scheme.get, call_21626477.host, call_21626477.base,
                               call_21626477.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626477, uri, valid, _)

proc call*(call_21626478: Call_GetInsightResults_21626466; InsightArn: string): Recallable =
  ## getInsightResults
  ## Lists the results of the Security Hub insight specified by the insight ARN.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight for which to return results.
  var path_21626479 = newJObject()
  add(path_21626479, "InsightArn", newJString(InsightArn))
  result = call_21626478.call(path_21626479, nil, nil, nil, nil)

var getInsightResults* = Call_GetInsightResults_21626466(name: "getInsightResults",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/insights/results/{InsightArn}",
    validator: validate_GetInsightResults_21626467, base: "/",
    makeUrl: url_GetInsightResults_21626468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsights_21626480 = ref object of OpenApiRestCall_21625435
proc url_GetInsights_21626482(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInsights_21626481(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists and describes insights for the specified insight ARNs.
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
  var valid_21626483 = query.getOrDefault("NextToken")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "NextToken", valid_21626483
  var valid_21626484 = query.getOrDefault("MaxResults")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "MaxResults", valid_21626484
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
  var valid_21626485 = header.getOrDefault("X-Amz-Date")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Date", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Security-Token", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Algorithm", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Signature")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Signature", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Credential")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Credential", valid_21626491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626493: Call_GetInsights_21626480; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists and describes insights for the specified insight ARNs.
  ## 
  let valid = call_21626493.validator(path, query, header, formData, body, _)
  let scheme = call_21626493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626493.makeUrl(scheme.get, call_21626493.host, call_21626493.base,
                               call_21626493.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626493, uri, valid, _)

proc call*(call_21626494: Call_GetInsights_21626480; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getInsights
  ## Lists and describes insights for the specified insight ARNs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626495 = newJObject()
  var body_21626496 = newJObject()
  add(query_21626495, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626496 = body
  add(query_21626495, "MaxResults", newJString(MaxResults))
  result = call_21626494.call(nil, query_21626495, nil, nil, body_21626496)

var getInsights* = Call_GetInsights_21626480(name: "getInsights",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights/get", validator: validate_GetInsights_21626481, base: "/",
    makeUrl: url_GetInsights_21626482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_21626497 = ref object of OpenApiRestCall_21625435
proc url_GetInvitationsCount_21626499(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInvitationsCount_21626498(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626500 = header.getOrDefault("X-Amz-Date")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Date", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Security-Token", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Algorithm", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Signature")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Signature", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Credential")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Credential", valid_21626506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626507: Call_GetInvitationsCount_21626497; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  ## 
  let valid = call_21626507.validator(path, query, header, formData, body, _)
  let scheme = call_21626507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626507.makeUrl(scheme.get, call_21626507.host, call_21626507.base,
                               call_21626507.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626507, uri, valid, _)

proc call*(call_21626508: Call_GetInvitationsCount_21626497): Recallable =
  ## getInvitationsCount
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  result = call_21626508.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_21626497(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/invitations/count",
    validator: validate_GetInvitationsCount_21626498, base: "/",
    makeUrl: url_GetInvitationsCount_21626499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_21626509 = ref object of OpenApiRestCall_21625435
proc url_GetMembers_21626511(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMembers_21626510(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the details for the Security Hub member accounts for the specified account IDs.
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
  var valid_21626512 = header.getOrDefault("X-Amz-Date")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Date", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Security-Token", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Algorithm", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Signature")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Signature", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Credential")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Credential", valid_21626518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626520: Call_GetMembers_21626509; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the details for the Security Hub member accounts for the specified account IDs.
  ## 
  let valid = call_21626520.validator(path, query, header, formData, body, _)
  let scheme = call_21626520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626520.makeUrl(scheme.get, call_21626520.host, call_21626520.base,
                               call_21626520.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626520, uri, valid, _)

proc call*(call_21626521: Call_GetMembers_21626509; body: JsonNode): Recallable =
  ## getMembers
  ## Returns the details for the Security Hub member accounts for the specified account IDs.
  ##   body: JObject (required)
  var body_21626522 = newJObject()
  if body != nil:
    body_21626522 = body
  result = call_21626521.call(nil, nil, nil, nil, body_21626522)

var getMembers* = Call_GetMembers_21626509(name: "getMembers",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/members/get",
                                        validator: validate_GetMembers_21626510,
                                        base: "/", makeUrl: url_GetMembers_21626511,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_21626523 = ref object of OpenApiRestCall_21625435
proc url_InviteMembers_21626525(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InviteMembers_21626524(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <code> <a>CreateMembers</a> </code> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
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
  var valid_21626526 = header.getOrDefault("X-Amz-Date")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Date", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Security-Token", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Algorithm", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Signature")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Signature", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Credential")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Credential", valid_21626532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626534: Call_InviteMembers_21626523; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <code> <a>CreateMembers</a> </code> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
  ## 
  let valid = call_21626534.validator(path, query, header, formData, body, _)
  let scheme = call_21626534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626534.makeUrl(scheme.get, call_21626534.host, call_21626534.base,
                               call_21626534.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626534, uri, valid, _)

proc call*(call_21626535: Call_InviteMembers_21626523; body: JsonNode): Recallable =
  ## inviteMembers
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <code> <a>CreateMembers</a> </code> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
  ##   body: JObject (required)
  var body_21626536 = newJObject()
  if body != nil:
    body_21626536 = body
  result = call_21626535.call(nil, nil, nil, nil, body_21626536)

var inviteMembers* = Call_InviteMembers_21626523(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/invite", validator: validate_InviteMembers_21626524, base: "/",
    makeUrl: url_InviteMembers_21626525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_21626537 = ref object of OpenApiRestCall_21625435
proc url_ListInvitations_21626539(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_21626538(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: JInt
  ##             : The maximum number of items to return in the response. 
  section = newJObject()
  var valid_21626540 = query.getOrDefault("NextToken")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "NextToken", valid_21626540
  var valid_21626541 = query.getOrDefault("MaxResults")
  valid_21626541 = validateParameter(valid_21626541, JInt, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "MaxResults", valid_21626541
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
  var valid_21626542 = header.getOrDefault("X-Amz-Date")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Date", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Security-Token", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Algorithm", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Signature")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Signature", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Credential")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Credential", valid_21626548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626549: Call_ListInvitations_21626537; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  let valid = call_21626549.validator(path, query, header, formData, body, _)
  let scheme = call_21626549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626549.makeUrl(scheme.get, call_21626549.host, call_21626549.base,
                               call_21626549.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626549, uri, valid, _)

proc call*(call_21626550: Call_ListInvitations_21626537; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## listInvitations
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   MaxResults: int
  ##             : The maximum number of items to return in the response. 
  var query_21626551 = newJObject()
  add(query_21626551, "NextToken", newJString(NextToken))
  add(query_21626551, "MaxResults", newJInt(MaxResults))
  result = call_21626550.call(nil, query_21626551, nil, nil, nil)

var listInvitations* = Call_ListInvitations_21626537(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_21626538, base: "/",
    makeUrl: url_ListInvitations_21626539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626566 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626568(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626567(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626569 = path.getOrDefault("ResourceArn")
  valid_21626569 = validateParameter(valid_21626569, JString, required = true,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "ResourceArn", valid_21626569
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
  var valid_21626570 = header.getOrDefault("X-Amz-Date")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-Date", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Security-Token", valid_21626571
  var valid_21626572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Algorithm", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Signature")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-Signature", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Credential")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Credential", valid_21626576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626578: Call_TagResource_21626566; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds one or more tags to a resource.
  ## 
  let valid = call_21626578.validator(path, query, header, formData, body, _)
  let scheme = call_21626578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626578.makeUrl(scheme.get, call_21626578.host, call_21626578.base,
                               call_21626578.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626578, uri, valid, _)

proc call*(call_21626579: Call_TagResource_21626566; ResourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to apply the tags to.
  ##   body: JObject (required)
  var path_21626580 = newJObject()
  var body_21626581 = newJObject()
  add(path_21626580, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_21626581 = body
  result = call_21626579.call(path_21626580, nil, nil, nil, body_21626581)

var tagResource* = Call_TagResource_21626566(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}", validator: validate_TagResource_21626567,
    base: "/", makeUrl: url_TagResource_21626568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626552 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626554(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21626553(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626555 = path.getOrDefault("ResourceArn")
  valid_21626555 = validateParameter(valid_21626555, JString, required = true,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "ResourceArn", valid_21626555
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
  var valid_21626556 = header.getOrDefault("X-Amz-Date")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Date", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Security-Token", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Algorithm", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Signature")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Signature", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Credential")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Credential", valid_21626562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626563: Call_ListTagsForResource_21626552; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of tags associated with a resource.
  ## 
  let valid = call_21626563.validator(path, query, header, formData, body, _)
  let scheme = call_21626563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626563.makeUrl(scheme.get, call_21626563.host, call_21626563.base,
                               call_21626563.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626563, uri, valid, _)

proc call*(call_21626564: Call_ListTagsForResource_21626552; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags for.
  var path_21626565 = newJObject()
  add(path_21626565, "ResourceArn", newJString(ResourceArn))
  result = call_21626564.call(path_21626565, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626552(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_21626553, base: "/",
    makeUrl: url_ListTagsForResource_21626554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626582 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626584(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626583(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626585 = path.getOrDefault("ResourceArn")
  valid_21626585 = validateParameter(valid_21626585, JString, required = true,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "ResourceArn", valid_21626585
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626586 = query.getOrDefault("tagKeys")
  valid_21626586 = validateParameter(valid_21626586, JArray, required = true,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "tagKeys", valid_21626586
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
  var valid_21626587 = header.getOrDefault("X-Amz-Date")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Date", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Security-Token", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Algorithm", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-Signature")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-Signature", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-Credential")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Credential", valid_21626593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626594: Call_UntagResource_21626582; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags from a resource.
  ## 
  let valid = call_21626594.validator(path, query, header, formData, body, _)
  let scheme = call_21626594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626594.makeUrl(scheme.get, call_21626594.host, call_21626594.base,
                               call_21626594.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626594, uri, valid, _)

proc call*(call_21626595: Call_UntagResource_21626582; tagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to remove the tags from.
  var path_21626596 = newJObject()
  var query_21626597 = newJObject()
  if tagKeys != nil:
    query_21626597.add "tagKeys", tagKeys
  add(path_21626596, "ResourceArn", newJString(ResourceArn))
  result = call_21626595.call(path_21626596, query_21626597, nil, nil, nil)

var untagResource* = Call_UntagResource_21626582(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_21626583,
    base: "/", makeUrl: url_UntagResource_21626584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStandardsControl_21626598 = ref object of OpenApiRestCall_21625435
proc url_UpdateStandardsControl_21626600(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_UpdateStandardsControl_21626599(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Used to control whether an individual security standard control is enabled or disabled.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   StandardsControlArn: JString (required)
  ##                      : The ARN of the security standard control to enable or disable.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `StandardsControlArn` field"
  var valid_21626601 = path.getOrDefault("StandardsControlArn")
  valid_21626601 = validateParameter(valid_21626601, JString, required = true,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "StandardsControlArn", valid_21626601
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
  var valid_21626602 = header.getOrDefault("X-Amz-Date")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Date", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Security-Token", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Algorithm", valid_21626605
  var valid_21626606 = header.getOrDefault("X-Amz-Signature")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "X-Amz-Signature", valid_21626606
  var valid_21626607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626607
  var valid_21626608 = header.getOrDefault("X-Amz-Credential")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-Credential", valid_21626608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626610: Call_UpdateStandardsControl_21626598;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to control whether an individual security standard control is enabled or disabled.
  ## 
  let valid = call_21626610.validator(path, query, header, formData, body, _)
  let scheme = call_21626610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626610.makeUrl(scheme.get, call_21626610.host, call_21626610.base,
                               call_21626610.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626610, uri, valid, _)

proc call*(call_21626611: Call_UpdateStandardsControl_21626598;
          StandardsControlArn: string; body: JsonNode): Recallable =
  ## updateStandardsControl
  ## Used to control whether an individual security standard control is enabled or disabled.
  ##   StandardsControlArn: string (required)
  ##                      : The ARN of the security standard control to enable or disable.
  ##   body: JObject (required)
  var path_21626612 = newJObject()
  var body_21626613 = newJObject()
  add(path_21626612, "StandardsControlArn", newJString(StandardsControlArn))
  if body != nil:
    body_21626613 = body
  result = call_21626611.call(path_21626612, nil, nil, nil, body_21626613)

var updateStandardsControl* = Call_UpdateStandardsControl_21626598(
    name: "updateStandardsControl", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com",
    route: "/standards/control/{StandardsControlArn}",
    validator: validate_UpdateStandardsControl_21626599, base: "/",
    makeUrl: url_UpdateStandardsControl_21626600,
    schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}