
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "securityhub.ap-northeast-1.amazonaws.com", "ap-southeast-1": "securityhub.ap-southeast-1.amazonaws.com", "us-west-2": "securityhub.us-west-2.amazonaws.com", "eu-west-2": "securityhub.eu-west-2.amazonaws.com", "ap-northeast-3": "securityhub.ap-northeast-3.amazonaws.com", "eu-central-1": "securityhub.eu-central-1.amazonaws.com", "us-east-2": "securityhub.us-east-2.amazonaws.com", "us-east-1": "securityhub.us-east-1.amazonaws.com", "cn-northwest-1": "securityhub.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "securityhub.ap-south-1.amazonaws.com", "eu-north-1": "securityhub.eu-north-1.amazonaws.com", "ap-northeast-2": "securityhub.ap-northeast-2.amazonaws.com", "us-west-1": "securityhub.us-west-1.amazonaws.com", "us-gov-east-1": "securityhub.us-gov-east-1.amazonaws.com", "eu-west-3": "securityhub.eu-west-3.amazonaws.com", "cn-north-1": "securityhub.cn-north-1.amazonaws.com.cn", "sa-east-1": "securityhub.sa-east-1.amazonaws.com", "eu-west-1": "securityhub.eu-west-1.amazonaws.com", "us-gov-west-1": "securityhub.us-gov-west-1.amazonaws.com", "ap-southeast-2": "securityhub.ap-southeast-2.amazonaws.com", "ca-central-1": "securityhub.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AcceptInvitation_402656470 = ref object of OpenApiRestCall_402656044
proc url_AcceptInvitation_402656472(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptInvitation_402656471(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656476 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656476 = validateParameter(valid_402656476, JString,
                                      required = false, default = nil)
  if valid_402656476 != nil:
    section.add "X-Amz-Security-Token", valid_402656476
  var valid_402656477 = header.getOrDefault("X-Amz-Signature")
  valid_402656477 = validateParameter(valid_402656477, JString,
                                      required = false, default = nil)
  if valid_402656477 != nil:
    section.add "X-Amz-Signature", valid_402656477
  var valid_402656478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Algorithm", valid_402656479
  var valid_402656480 = header.getOrDefault("X-Amz-Date")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Date", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Credential")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Credential", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656482
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

proc call*(call_402656484: Call_AcceptInvitation_402656470;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from.</p> <p>When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.</p>
                                                                                         ## 
  let valid = call_402656484.validator(path, query, header, formData, body, _)
  let scheme = call_402656484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656484.makeUrl(scheme.get, call_402656484.host, call_402656484.base,
                                   call_402656484.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656484, uri, valid, _)

proc call*(call_402656485: Call_AcceptInvitation_402656470; body: JsonNode): Recallable =
  ## acceptInvitation
  ## <p>Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from.</p> <p>When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.</p>
  ##   
                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656486 = newJObject()
  if body != nil:
    body_402656486 = body
  result = call_402656485.call(nil, nil, nil, nil, body_402656486)

var acceptInvitation* = Call_AcceptInvitation_402656470(
    name: "acceptInvitation", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_AcceptInvitation_402656471, base: "/",
    makeUrl: url_AcceptInvitation_402656472,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_402656294 = ref object of OpenApiRestCall_402656044
proc url_GetMasterAccount_402656296(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMasterAccount_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656375 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "X-Amz-Security-Token", valid_402656375
  var valid_402656376 = header.getOrDefault("X-Amz-Signature")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Signature", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Algorithm", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Date")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Date", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Credential")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Credential", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656395: Call_GetMasterAccount_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides the details for the Security Hub master account for the current member account. 
                                                                                         ## 
  let valid = call_402656395.validator(path, query, header, formData, body, _)
  let scheme = call_402656395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656395.makeUrl(scheme.get, call_402656395.host, call_402656395.base,
                                   call_402656395.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656395, uri, valid, _)

proc call*(call_402656444: Call_GetMasterAccount_402656294): Recallable =
  ## getMasterAccount
  ## Provides the details for the Security Hub master account for the current member account. 
  result = call_402656444.call(nil, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_402656294(
    name: "getMasterAccount", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_GetMasterAccount_402656295, base: "/",
    makeUrl: url_GetMasterAccount_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisableStandards_402656488 = ref object of OpenApiRestCall_402656044
proc url_BatchDisableStandards_402656490(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisableStandards_402656489(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656491 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Security-Token", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Signature")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Signature", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Algorithm", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Date")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Date", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Credential")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Credential", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656497
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

proc call*(call_402656499: Call_BatchDisableStandards_402656488;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Security Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656499.validator(path, query, header, formData, body, _)
  let scheme = call_402656499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656499.makeUrl(scheme.get, call_402656499.host, call_402656499.base,
                                   call_402656499.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656499, uri, valid, _)

proc call*(call_402656500: Call_BatchDisableStandards_402656488; body: JsonNode): Recallable =
  ## batchDisableStandards
  ## <p>Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Security Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656501 = newJObject()
  if body != nil:
    body_402656501 = body
  result = call_402656500.call(nil, nil, nil, nil, body_402656501)

var batchDisableStandards* = Call_BatchDisableStandards_402656488(
    name: "batchDisableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/deregister",
    validator: validate_BatchDisableStandards_402656489, base: "/",
    makeUrl: url_BatchDisableStandards_402656490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchEnableStandards_402656502 = ref object of OpenApiRestCall_402656044
proc url_BatchEnableStandards_402656504(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchEnableStandards_402656503(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656505 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Security-Token", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Signature")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Signature", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Algorithm", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Date")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Date", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Credential")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Credential", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656511
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

proc call*(call_402656513: Call_BatchEnableStandards_402656502;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables the standards specified by the provided <code>StandardsArn</code>. To obtain the ARN for a standard, use the <code> <a>DescribeStandards</a> </code> operation.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Security Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656513.validator(path, query, header, formData, body, _)
  let scheme = call_402656513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656513.makeUrl(scheme.get, call_402656513.host, call_402656513.base,
                                   call_402656513.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656513, uri, valid, _)

proc call*(call_402656514: Call_BatchEnableStandards_402656502; body: JsonNode): Recallable =
  ## batchEnableStandards
  ## <p>Enables the standards specified by the provided <code>StandardsArn</code>. To obtain the ARN for a standard, use the <code> <a>DescribeStandards</a> </code> operation.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Security Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656515 = newJObject()
  if body != nil:
    body_402656515 = body
  result = call_402656514.call(nil, nil, nil, nil, body_402656515)

var batchEnableStandards* = Call_BatchEnableStandards_402656502(
    name: "batchEnableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/register",
    validator: validate_BatchEnableStandards_402656503, base: "/",
    makeUrl: url_BatchEnableStandards_402656504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchImportFindings_402656516 = ref object of OpenApiRestCall_402656044
proc url_BatchImportFindings_402656518(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchImportFindings_402656517(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656519 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Security-Token", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Signature")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Signature", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Algorithm", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Date")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Date", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Credential")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Credential", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656525
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

proc call*(call_402656527: Call_BatchImportFindings_402656516;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub.</p> <p>The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.</p>
                                                                                         ## 
  let valid = call_402656527.validator(path, query, header, formData, body, _)
  let scheme = call_402656527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656527.makeUrl(scheme.get, call_402656527.host, call_402656527.base,
                                   call_402656527.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656527, uri, valid, _)

proc call*(call_402656528: Call_BatchImportFindings_402656516; body: JsonNode): Recallable =
  ## batchImportFindings
  ## <p>Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub.</p> <p>The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.</p>
  ##   
                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656529 = newJObject()
  if body != nil:
    body_402656529 = body
  result = call_402656528.call(nil, nil, nil, nil, body_402656529)

var batchImportFindings* = Call_BatchImportFindings_402656516(
    name: "batchImportFindings", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/findings/import",
    validator: validate_BatchImportFindings_402656517, base: "/",
    makeUrl: url_BatchImportFindings_402656518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActionTarget_402656530 = ref object of OpenApiRestCall_402656044
proc url_CreateActionTarget_402656532(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateActionTarget_402656531(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656533 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Security-Token", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Signature")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Signature", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Algorithm", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Date")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Date", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Credential")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Credential", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656539
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

proc call*(call_402656541: Call_CreateActionTarget_402656530;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a custom action target in Security Hub.</p> <p>You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.</p>
                                                                                         ## 
  let valid = call_402656541.validator(path, query, header, formData, body, _)
  let scheme = call_402656541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656541.makeUrl(scheme.get, call_402656541.host, call_402656541.base,
                                   call_402656541.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656541, uri, valid, _)

proc call*(call_402656542: Call_CreateActionTarget_402656530; body: JsonNode): Recallable =
  ## createActionTarget
  ## <p>Creates a custom action target in Security Hub.</p> <p>You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.</p>
  ##   
                                                                                                                                                                                             ## body: JObject (required)
  var body_402656543 = newJObject()
  if body != nil:
    body_402656543 = body
  result = call_402656542.call(nil, nil, nil, nil, body_402656543)

var createActionTarget* = Call_CreateActionTarget_402656530(
    name: "createActionTarget", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets",
    validator: validate_CreateActionTarget_402656531, base: "/",
    makeUrl: url_CreateActionTarget_402656532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInsight_402656544 = ref object of OpenApiRestCall_402656044
proc url_CreateInsight_402656546(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInsight_402656545(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation.</p> <p>To group the related findings in the insight, use the <code>GroupByAttribute</code>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656547 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Security-Token", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Signature")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Signature", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Algorithm", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Date")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Date", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Credential")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Credential", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656553
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

proc call*(call_402656555: Call_CreateInsight_402656544; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation.</p> <p>To group the related findings in the insight, use the <code>GroupByAttribute</code>.</p>
                                                                                         ## 
  let valid = call_402656555.validator(path, query, header, formData, body, _)
  let scheme = call_402656555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656555.makeUrl(scheme.get, call_402656555.host, call_402656555.base,
                                   call_402656555.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656555, uri, valid, _)

proc call*(call_402656556: Call_CreateInsight_402656544; body: JsonNode): Recallable =
  ## createInsight
  ## <p>Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation.</p> <p>To group the related findings in the insight, use the <code>GroupByAttribute</code>.</p>
  ##   
                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656557 = newJObject()
  if body != nil:
    body_402656557 = body
  result = call_402656556.call(nil, nil, nil, nil, body_402656557)

var createInsight* = Call_CreateInsight_402656544(name: "createInsight",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights", validator: validate_CreateInsight_402656545, base: "/",
    makeUrl: url_CreateInsight_402656546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_402656574 = ref object of OpenApiRestCall_402656044
proc url_CreateMembers_402656576(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMembers_402656575(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <code> <a>EnableSecurityHub</a> </code> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <code> <a>InviteMembers</a> </code> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <code> <a>DisassociateFromMasterAccount</a> </code> or <code> <a>DisassociateMembers</a> </code> operation.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656577 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Security-Token", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Signature")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Signature", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Algorithm", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Date")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Date", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Credential")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Credential", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656583
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

proc call*(call_402656585: Call_CreateMembers_402656574; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <code> <a>EnableSecurityHub</a> </code> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <code> <a>InviteMembers</a> </code> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <code> <a>DisassociateFromMasterAccount</a> </code> or <code> <a>DisassociateMembers</a> </code> operation.</p>
                                                                                         ## 
  let valid = call_402656585.validator(path, query, header, formData, body, _)
  let scheme = call_402656585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656585.makeUrl(scheme.get, call_402656585.host, call_402656585.base,
                                   call_402656585.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656585, uri, valid, _)

proc call*(call_402656586: Call_CreateMembers_402656574; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <code> <a>EnableSecurityHub</a> </code> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <code> <a>InviteMembers</a> </code> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <code> <a>DisassociateFromMasterAccount</a> </code> or <code> <a>DisassociateMembers</a> </code> operation.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656587 = newJObject()
  if body != nil:
    body_402656587 = body
  result = call_402656586.call(nil, nil, nil, nil, body_402656587)

var createMembers* = Call_CreateMembers_402656574(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members", validator: validate_CreateMembers_402656575, base: "/",
    makeUrl: url_CreateMembers_402656576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_402656558 = ref object of OpenApiRestCall_402656044
proc url_ListMembers_402656560(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMembers_402656559(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists details about all member accounts for the current Security Hub master account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : The maximum number of items to return in the response. 
  ##   
                                                                                                          ## NextToken: JString
                                                                                                          ##            
                                                                                                          ## : 
                                                                                                          ## <p>The 
                                                                                                          ## token 
                                                                                                          ## that 
                                                                                                          ## is 
                                                                                                          ## required 
                                                                                                          ## for 
                                                                                                          ## pagination. 
                                                                                                          ## On 
                                                                                                          ## your 
                                                                                                          ## first 
                                                                                                          ## call 
                                                                                                          ## to 
                                                                                                          ## the 
                                                                                                          ## <code>ListMembers</code> 
                                                                                                          ## operation, 
                                                                                                          ## set 
                                                                                                          ## the 
                                                                                                          ## value 
                                                                                                          ## of 
                                                                                                          ## this 
                                                                                                          ## parameter 
                                                                                                          ## to 
                                                                                                          ## <code>NULL</code>.</p> 
                                                                                                          ## <p>For 
                                                                                                          ## subsequent 
                                                                                                          ## calls 
                                                                                                          ## to 
                                                                                                          ## the 
                                                                                                          ## operation, 
                                                                                                          ## to 
                                                                                                          ## continue 
                                                                                                          ## listing 
                                                                                                          ## data, 
                                                                                                          ## set 
                                                                                                          ## the 
                                                                                                          ## value 
                                                                                                          ## of 
                                                                                                          ## this 
                                                                                                          ## parameter 
                                                                                                          ## to 
                                                                                                          ## the 
                                                                                                          ## value 
                                                                                                          ## returned 
                                                                                                          ## from 
                                                                                                          ## the 
                                                                                                          ## previous 
                                                                                                          ## response.</p>
  ##   
                                                                                                                          ## OnlyAssociated: JBool
                                                                                                                          ##                 
                                                                                                                          ## : 
                                                                                                                          ## <p>Specifies 
                                                                                                                          ## which 
                                                                                                                          ## member 
                                                                                                                          ## accounts 
                                                                                                                          ## to 
                                                                                                                          ## include 
                                                                                                                          ## in 
                                                                                                                          ## the 
                                                                                                                          ## response 
                                                                                                                          ## based 
                                                                                                                          ## on 
                                                                                                                          ## their 
                                                                                                                          ## relationship 
                                                                                                                          ## status 
                                                                                                                          ## with 
                                                                                                                          ## the 
                                                                                                                          ## master 
                                                                                                                          ## account. 
                                                                                                                          ## The 
                                                                                                                          ## default 
                                                                                                                          ## value 
                                                                                                                          ## is 
                                                                                                                          ## <code>TRUE</code>.</p> 
                                                                                                                          ## <p>If 
                                                                                                                          ## <code>OnlyAssociated</code> 
                                                                                                                          ## is 
                                                                                                                          ## set 
                                                                                                                          ## to 
                                                                                                                          ## <code>TRUE</code>, 
                                                                                                                          ## the 
                                                                                                                          ## response 
                                                                                                                          ## includes 
                                                                                                                          ## member 
                                                                                                                          ## accounts 
                                                                                                                          ## whose 
                                                                                                                          ## relationship 
                                                                                                                          ## status 
                                                                                                                          ## with 
                                                                                                                          ## the 
                                                                                                                          ## master 
                                                                                                                          ## is 
                                                                                                                          ## set 
                                                                                                                          ## to 
                                                                                                                          ## <code>ENABLED</code> 
                                                                                                                          ## or 
                                                                                                                          ## <code>DISABLED</code>.</p> 
                                                                                                                          ## <p>If 
                                                                                                                          ## <code>OnlyAssociated</code> 
                                                                                                                          ## is 
                                                                                                                          ## set 
                                                                                                                          ## to 
                                                                                                                          ## <code>FALSE</code>, 
                                                                                                                          ## the 
                                                                                                                          ## response 
                                                                                                                          ## includes 
                                                                                                                          ## all 
                                                                                                                          ## existing 
                                                                                                                          ## member 
                                                                                                                          ## accounts. 
                                                                                                                          ## </p>
  section = newJObject()
  var valid_402656561 = query.getOrDefault("MaxResults")
  valid_402656561 = validateParameter(valid_402656561, JInt, required = false,
                                      default = nil)
  if valid_402656561 != nil:
    section.add "MaxResults", valid_402656561
  var valid_402656562 = query.getOrDefault("NextToken")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "NextToken", valid_402656562
  var valid_402656563 = query.getOrDefault("OnlyAssociated")
  valid_402656563 = validateParameter(valid_402656563, JBool, required = false,
                                      default = nil)
  if valid_402656563 != nil:
    section.add "OnlyAssociated", valid_402656563
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656564 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Security-Token", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Signature")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Signature", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Algorithm", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Date")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Date", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Credential")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Credential", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656571: Call_ListMembers_402656558; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists details about all member accounts for the current Security Hub master account.
                                                                                         ## 
  let valid = call_402656571.validator(path, query, header, formData, body, _)
  let scheme = call_402656571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656571.makeUrl(scheme.get, call_402656571.host, call_402656571.base,
                                   call_402656571.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656571, uri, valid, _)

proc call*(call_402656572: Call_ListMembers_402656558; MaxResults: int = 0;
           NextToken: string = ""; OnlyAssociated: bool = false): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current Security Hub master account.
  ##   
                                                                                         ## MaxResults: int
                                                                                         ##             
                                                                                         ## : 
                                                                                         ## The 
                                                                                         ## maximum 
                                                                                         ## number 
                                                                                         ## of 
                                                                                         ## items 
                                                                                         ## to 
                                                                                         ## return 
                                                                                         ## in 
                                                                                         ## the 
                                                                                         ## response. 
  ##   
                                                                                                      ## NextToken: string
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## <p>The 
                                                                                                      ## token 
                                                                                                      ## that 
                                                                                                      ## is 
                                                                                                      ## required 
                                                                                                      ## for 
                                                                                                      ## pagination. 
                                                                                                      ## On 
                                                                                                      ## your 
                                                                                                      ## first 
                                                                                                      ## call 
                                                                                                      ## to 
                                                                                                      ## the 
                                                                                                      ## <code>ListMembers</code> 
                                                                                                      ## operation, 
                                                                                                      ## set 
                                                                                                      ## the 
                                                                                                      ## value 
                                                                                                      ## of 
                                                                                                      ## this 
                                                                                                      ## parameter 
                                                                                                      ## to 
                                                                                                      ## <code>NULL</code>.</p> 
                                                                                                      ## <p>For 
                                                                                                      ## subsequent 
                                                                                                      ## calls 
                                                                                                      ## to 
                                                                                                      ## the 
                                                                                                      ## operation, 
                                                                                                      ## to 
                                                                                                      ## continue 
                                                                                                      ## listing 
                                                                                                      ## data, 
                                                                                                      ## set 
                                                                                                      ## the 
                                                                                                      ## value 
                                                                                                      ## of 
                                                                                                      ## this 
                                                                                                      ## parameter 
                                                                                                      ## to 
                                                                                                      ## the 
                                                                                                      ## value 
                                                                                                      ## returned 
                                                                                                      ## from 
                                                                                                      ## the 
                                                                                                      ## previous 
                                                                                                      ## response.</p>
  ##   
                                                                                                                      ## OnlyAssociated: bool
                                                                                                                      ##                 
                                                                                                                      ## : 
                                                                                                                      ## <p>Specifies 
                                                                                                                      ## which 
                                                                                                                      ## member 
                                                                                                                      ## accounts 
                                                                                                                      ## to 
                                                                                                                      ## include 
                                                                                                                      ## in 
                                                                                                                      ## the 
                                                                                                                      ## response 
                                                                                                                      ## based 
                                                                                                                      ## on 
                                                                                                                      ## their 
                                                                                                                      ## relationship 
                                                                                                                      ## status 
                                                                                                                      ## with 
                                                                                                                      ## the 
                                                                                                                      ## master 
                                                                                                                      ## account. 
                                                                                                                      ## The 
                                                                                                                      ## default 
                                                                                                                      ## value 
                                                                                                                      ## is 
                                                                                                                      ## <code>TRUE</code>.</p> 
                                                                                                                      ## <p>If 
                                                                                                                      ## <code>OnlyAssociated</code> 
                                                                                                                      ## is 
                                                                                                                      ## set 
                                                                                                                      ## to 
                                                                                                                      ## <code>TRUE</code>, 
                                                                                                                      ## the 
                                                                                                                      ## response 
                                                                                                                      ## includes 
                                                                                                                      ## member 
                                                                                                                      ## accounts 
                                                                                                                      ## whose 
                                                                                                                      ## relationship 
                                                                                                                      ## status 
                                                                                                                      ## with 
                                                                                                                      ## the 
                                                                                                                      ## master 
                                                                                                                      ## is 
                                                                                                                      ## set 
                                                                                                                      ## to 
                                                                                                                      ## <code>ENABLED</code> 
                                                                                                                      ## or 
                                                                                                                      ## <code>DISABLED</code>.</p> 
                                                                                                                      ## <p>If 
                                                                                                                      ## <code>OnlyAssociated</code> 
                                                                                                                      ## is 
                                                                                                                      ## set 
                                                                                                                      ## to 
                                                                                                                      ## <code>FALSE</code>, 
                                                                                                                      ## the 
                                                                                                                      ## response 
                                                                                                                      ## includes 
                                                                                                                      ## all 
                                                                                                                      ## existing 
                                                                                                                      ## member 
                                                                                                                      ## accounts. 
                                                                                                                      ## </p>
  var query_402656573 = newJObject()
  add(query_402656573, "MaxResults", newJInt(MaxResults))
  add(query_402656573, "NextToken", newJString(NextToken))
  add(query_402656573, "OnlyAssociated", newJBool(OnlyAssociated))
  result = call_402656572.call(nil, query_402656573, nil, nil, nil)

var listMembers* = Call_ListMembers_402656558(name: "listMembers",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/members", validator: validate_ListMembers_402656559, base: "/",
    makeUrl: url_ListMembers_402656560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_402656588 = ref object of OpenApiRestCall_402656044
proc url_DeclineInvitations_402656590(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeclineInvitations_402656589(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656591 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Security-Token", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Signature")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Signature", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Algorithm", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Date")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Date", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Credential")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Credential", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656597
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

proc call*(call_402656599: Call_DeclineInvitations_402656588;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Declines invitations to become a member account.
                                                                                         ## 
  let valid = call_402656599.validator(path, query, header, formData, body, _)
  let scheme = call_402656599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656599.makeUrl(scheme.get, call_402656599.host, call_402656599.base,
                                   call_402656599.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656599, uri, valid, _)

proc call*(call_402656600: Call_DeclineInvitations_402656588; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations to become a member account.
  ##   body: JObject (required)
  var body_402656601 = newJObject()
  if body != nil:
    body_402656601 = body
  result = call_402656600.call(nil, nil, nil, nil, body_402656601)

var declineInvitations* = Call_DeclineInvitations_402656588(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/invitations/decline",
    validator: validate_DeclineInvitations_402656589, base: "/",
    makeUrl: url_DeclineInvitations_402656590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateActionTarget_402656627 = ref object of OpenApiRestCall_402656044
proc url_UpdateActionTarget_402656629(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ActionTargetArn" in path,
         "`ActionTargetArn` is a required path parameter"
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

proc validate_UpdateActionTarget_402656628(path: JsonNode; query: JsonNode;
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
  var valid_402656630 = path.getOrDefault("ActionTargetArn")
  valid_402656630 = validateParameter(valid_402656630, JString, required = true,
                                      default = nil)
  if valid_402656630 != nil:
    section.add "ActionTargetArn", valid_402656630
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656631 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Security-Token", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Signature")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Signature", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Algorithm", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Date")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Date", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Credential")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Credential", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656637
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

proc call*(call_402656639: Call_UpdateActionTarget_402656627;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the name and description of a custom action target in Security Hub.
                                                                                         ## 
  let valid = call_402656639.validator(path, query, header, formData, body, _)
  let scheme = call_402656639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656639.makeUrl(scheme.get, call_402656639.host, call_402656639.base,
                                   call_402656639.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656639, uri, valid, _)

proc call*(call_402656640: Call_UpdateActionTarget_402656627; body: JsonNode;
           ActionTargetArn: string): Recallable =
  ## updateActionTarget
  ## Updates the name and description of a custom action target in Security Hub.
  ##   
                                                                                ## body: JObject (required)
  ##   
                                                                                                           ## ActionTargetArn: string (required)
                                                                                                           ##                  
                                                                                                           ## : 
                                                                                                           ## The 
                                                                                                           ## ARN 
                                                                                                           ## of 
                                                                                                           ## the 
                                                                                                           ## custom 
                                                                                                           ## action 
                                                                                                           ## target 
                                                                                                           ## to 
                                                                                                           ## update.
  var path_402656641 = newJObject()
  var body_402656642 = newJObject()
  if body != nil:
    body_402656642 = body
  add(path_402656641, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_402656640.call(path_402656641, nil, nil, nil, body_402656642)

var updateActionTarget* = Call_UpdateActionTarget_402656627(
    name: "updateActionTarget", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com",
    route: "/actionTargets/{ActionTargetArn}",
    validator: validate_UpdateActionTarget_402656628, base: "/",
    makeUrl: url_UpdateActionTarget_402656629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActionTarget_402656602 = ref object of OpenApiRestCall_402656044
proc url_DeleteActionTarget_402656604(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ActionTargetArn" in path,
         "`ActionTargetArn` is a required path parameter"
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

proc validate_DeleteActionTarget_402656603(path: JsonNode; query: JsonNode;
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
  var valid_402656616 = path.getOrDefault("ActionTargetArn")
  valid_402656616 = validateParameter(valid_402656616, JString, required = true,
                                      default = nil)
  if valid_402656616 != nil:
    section.add "ActionTargetArn", valid_402656616
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656617 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Security-Token", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Signature")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Signature", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Algorithm", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Date")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Date", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Credential")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Credential", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656624: Call_DeleteActionTarget_402656602;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a custom action target from Security Hub.</p> <p>Deleting a custom action target does not affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.</p>
                                                                                         ## 
  let valid = call_402656624.validator(path, query, header, formData, body, _)
  let scheme = call_402656624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656624.makeUrl(scheme.get, call_402656624.host, call_402656624.base,
                                   call_402656624.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656624, uri, valid, _)

proc call*(call_402656625: Call_DeleteActionTarget_402656602;
           ActionTargetArn: string): Recallable =
  ## deleteActionTarget
  ## <p>Deletes a custom action target from Security Hub.</p> <p>Deleting a custom action target does not affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.</p>
  ##   
                                                                                                                                                                                                                         ## ActionTargetArn: string (required)
                                                                                                                                                                                                                         ##                  
                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                         ## ARN 
                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                         ## custom 
                                                                                                                                                                                                                         ## action 
                                                                                                                                                                                                                         ## target 
                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                         ## delete.
  var path_402656626 = newJObject()
  add(path_402656626, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_402656625.call(path_402656626, nil, nil, nil, nil)

var deleteActionTarget* = Call_DeleteActionTarget_402656602(
    name: "deleteActionTarget", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com",
    route: "/actionTargets/{ActionTargetArn}",
    validator: validate_DeleteActionTarget_402656603, base: "/",
    makeUrl: url_DeleteActionTarget_402656604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInsight_402656657 = ref object of OpenApiRestCall_402656044
proc url_UpdateInsight_402656659(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInsight_402656658(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656660 = path.getOrDefault("InsightArn")
  valid_402656660 = validateParameter(valid_402656660, JString, required = true,
                                      default = nil)
  if valid_402656660 != nil:
    section.add "InsightArn", valid_402656660
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656661 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Security-Token", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Signature")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Signature", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Algorithm", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Date")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Date", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Credential")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Credential", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656667
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

proc call*(call_402656669: Call_UpdateInsight_402656657; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the Security Hub insight identified by the specified insight ARN.
                                                                                         ## 
  let valid = call_402656669.validator(path, query, header, formData, body, _)
  let scheme = call_402656669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656669.makeUrl(scheme.get, call_402656669.host, call_402656669.base,
                                   call_402656669.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656669, uri, valid, _)

proc call*(call_402656670: Call_UpdateInsight_402656657; body: JsonNode;
           InsightArn: string): Recallable =
  ## updateInsight
  ## Updates the Security Hub insight identified by the specified insight ARN.
  ##   
                                                                              ## body: JObject (required)
  ##   
                                                                                                         ## InsightArn: string (required)
                                                                                                         ##             
                                                                                                         ## : 
                                                                                                         ## The 
                                                                                                         ## ARN 
                                                                                                         ## of 
                                                                                                         ## the 
                                                                                                         ## insight 
                                                                                                         ## that 
                                                                                                         ## you 
                                                                                                         ## want 
                                                                                                         ## to 
                                                                                                         ## update.
  var path_402656671 = newJObject()
  var body_402656672 = newJObject()
  if body != nil:
    body_402656672 = body
  add(path_402656671, "InsightArn", newJString(InsightArn))
  result = call_402656670.call(path_402656671, nil, nil, nil, body_402656672)

var updateInsight* = Call_UpdateInsight_402656657(name: "updateInsight",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_UpdateInsight_402656658,
    base: "/", makeUrl: url_UpdateInsight_402656659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInsight_402656643 = ref object of OpenApiRestCall_402656044
proc url_DeleteInsight_402656645(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInsight_402656644(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656646 = path.getOrDefault("InsightArn")
  valid_402656646 = validateParameter(valid_402656646, JString, required = true,
                                      default = nil)
  if valid_402656646 != nil:
    section.add "InsightArn", valid_402656646
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656647 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Security-Token", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Signature")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Signature", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Algorithm", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Date")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Date", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Credential")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Credential", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656654: Call_DeleteInsight_402656643; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the insight specified by the <code>InsightArn</code>.
                                                                                         ## 
  let valid = call_402656654.validator(path, query, header, formData, body, _)
  let scheme = call_402656654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656654.makeUrl(scheme.get, call_402656654.host, call_402656654.base,
                                   call_402656654.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656654, uri, valid, _)

proc call*(call_402656655: Call_DeleteInsight_402656643; InsightArn: string): Recallable =
  ## deleteInsight
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ##   InsightArn: string (required)
                                                                  ##             : The ARN of the insight to delete.
  var path_402656656 = newJObject()
  add(path_402656656, "InsightArn", newJString(InsightArn))
  result = call_402656655.call(path_402656656, nil, nil, nil, nil)

var deleteInsight* = Call_DeleteInsight_402656643(name: "deleteInsight",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_DeleteInsight_402656644,
    base: "/", makeUrl: url_DeleteInsight_402656645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_402656673 = ref object of OpenApiRestCall_402656044
proc url_DeleteInvitations_402656675(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInvitations_402656674(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656676 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Security-Token", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Signature")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Signature", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Algorithm", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Date")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Date", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Credential")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Credential", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656682
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

proc call*(call_402656684: Call_DeleteInvitations_402656673;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes invitations received by the AWS account to become a member account.
                                                                                         ## 
  let valid = call_402656684.validator(path, query, header, formData, body, _)
  let scheme = call_402656684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656684.makeUrl(scheme.get, call_402656684.host, call_402656684.base,
                                   call_402656684.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656684, uri, valid, _)

proc call*(call_402656685: Call_DeleteInvitations_402656673; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations received by the AWS account to become a member account.
  ##   
                                                                                ## body: JObject (required)
  var body_402656686 = newJObject()
  if body != nil:
    body_402656686 = body
  result = call_402656685.call(nil, nil, nil, nil, body_402656686)

var deleteInvitations* = Call_DeleteInvitations_402656673(
    name: "deleteInvitations", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/invitations/delete",
    validator: validate_DeleteInvitations_402656674, base: "/",
    makeUrl: url_DeleteInvitations_402656675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_402656687 = ref object of OpenApiRestCall_402656044
proc url_DeleteMembers_402656689(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMembers_402656688(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified member accounts from Security Hub.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656690 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Security-Token", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Signature")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Signature", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Algorithm", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Date")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Date", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Credential")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Credential", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656696
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

proc call*(call_402656698: Call_DeleteMembers_402656687; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified member accounts from Security Hub.
                                                                                         ## 
  let valid = call_402656698.validator(path, query, header, formData, body, _)
  let scheme = call_402656698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656698.makeUrl(scheme.get, call_402656698.host, call_402656698.base,
                                   call_402656698.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656698, uri, valid, _)

proc call*(call_402656699: Call_DeleteMembers_402656687; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes the specified member accounts from Security Hub.
  ##   body: JObject (required)
  var body_402656700 = newJObject()
  if body != nil:
    body_402656700 = body
  result = call_402656699.call(nil, nil, nil, nil, body_402656700)

var deleteMembers* = Call_DeleteMembers_402656687(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/delete", validator: validate_DeleteMembers_402656688,
    base: "/", makeUrl: url_DeleteMembers_402656689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActionTargets_402656701 = ref object of OpenApiRestCall_402656044
proc url_DescribeActionTargets_402656703(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActionTargets_402656702(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656704 = query.getOrDefault("MaxResults")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "MaxResults", valid_402656704
  var valid_402656705 = query.getOrDefault("NextToken")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "NextToken", valid_402656705
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656706 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Security-Token", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Signature")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Signature", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Algorithm", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Date")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Date", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Credential")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Credential", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656712
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

proc call*(call_402656714: Call_DescribeActionTargets_402656701;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the custom action targets in Security Hub in your account.
                                                                                         ## 
  let valid = call_402656714.validator(path, query, header, formData, body, _)
  let scheme = call_402656714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656714.makeUrl(scheme.get, call_402656714.host, call_402656714.base,
                                   call_402656714.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656714, uri, valid, _)

proc call*(call_402656715: Call_DescribeActionTargets_402656701; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeActionTargets
  ## Returns a list of the custom action targets in Security Hub in your account.
  ##   
                                                                                 ## MaxResults: string
                                                                                 ##             
                                                                                 ## : 
                                                                                 ## Pagination 
                                                                                 ## limit
  ##   
                                                                                         ## body: JObject (required)
  ##   
                                                                                                                    ## NextToken: string
                                                                                                                    ##            
                                                                                                                    ## : 
                                                                                                                    ## Pagination 
                                                                                                                    ## token
  var query_402656716 = newJObject()
  var body_402656717 = newJObject()
  add(query_402656716, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656717 = body
  add(query_402656716, "NextToken", newJString(NextToken))
  result = call_402656715.call(nil, query_402656716, nil, nil, body_402656717)

var describeActionTargets* = Call_DescribeActionTargets_402656701(
    name: "describeActionTargets", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets/get",
    validator: validate_DescribeActionTargets_402656702, base: "/",
    makeUrl: url_DescribeActionTargets_402656703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSecurityHub_402656732 = ref object of OpenApiRestCall_402656044
proc url_EnableSecurityHub_402656734(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableSecurityHub_402656733(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656735 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Security-Token", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Signature")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Signature", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Algorithm", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Date")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Date", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Credential")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Credential", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656741
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

proc call*(call_402656743: Call_EnableSecurityHub_402656732;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables Security Hub for your account in the current Region or the Region you specify in the request.</p> <p>When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie.</p> <p>When you use the <code>EnableSecurityHub</code> operation to enable Security Hub, you also automatically enable the CIS AWS Foundations standard. You do not enable the Payment Card Industry Data Security Standard (PCI DSS) standard. To enable a standard, use the <code> <a>BatchEnableStandards</a> </code> operation. To disable a standard, use the <code> <a>BatchDisableStandards</a> </code> operation.</p> <p>To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a> in the <i>AWS Security Hub User Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656743.validator(path, query, header, formData, body, _)
  let scheme = call_402656743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656743.makeUrl(scheme.get, call_402656743.host, call_402656743.base,
                                   call_402656743.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656743, uri, valid, _)

proc call*(call_402656744: Call_EnableSecurityHub_402656732; body: JsonNode): Recallable =
  ## enableSecurityHub
  ## <p>Enables Security Hub for your account in the current Region or the Region you specify in the request.</p> <p>When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie.</p> <p>When you use the <code>EnableSecurityHub</code> operation to enable Security Hub, you also automatically enable the CIS AWS Foundations standard. You do not enable the Payment Card Industry Data Security Standard (PCI DSS) standard. To enable a standard, use the <code> <a>BatchEnableStandards</a> </code> operation. To disable a standard, use the <code> <a>BatchDisableStandards</a> </code> operation.</p> <p>To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a> in the <i>AWS Security Hub User Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656745 = newJObject()
  if body != nil:
    body_402656745 = body
  result = call_402656744.call(nil, nil, nil, nil, body_402656745)

var enableSecurityHub* = Call_EnableSecurityHub_402656732(
    name: "enableSecurityHub", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_EnableSecurityHub_402656733, base: "/",
    makeUrl: url_EnableSecurityHub_402656734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHub_402656718 = ref object of OpenApiRestCall_402656044
proc url_DescribeHub_402656720(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHub_402656719(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656721 = query.getOrDefault("HubArn")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "HubArn", valid_402656721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656722 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Security-Token", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Signature")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Signature", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Algorithm", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Date")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Date", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Credential")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Credential", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656729: Call_DescribeHub_402656718; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
                                                                                         ## 
  let valid = call_402656729.validator(path, query, header, formData, body, _)
  let scheme = call_402656729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656729.makeUrl(scheme.get, call_402656729.host, call_402656729.base,
                                   call_402656729.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656729, uri, valid, _)

proc call*(call_402656730: Call_DescribeHub_402656718; HubArn: string = ""): Recallable =
  ## describeHub
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ##   
                                                                                                                                          ## HubArn: string
                                                                                                                                          ##         
                                                                                                                                          ## : 
                                                                                                                                          ## The 
                                                                                                                                          ## ARN 
                                                                                                                                          ## of 
                                                                                                                                          ## the 
                                                                                                                                          ## Hub 
                                                                                                                                          ## resource 
                                                                                                                                          ## to 
                                                                                                                                          ## retrieve.
  var query_402656731 = newJObject()
  add(query_402656731, "HubArn", newJString(HubArn))
  result = call_402656730.call(nil, query_402656731, nil, nil, nil)

var describeHub* = Call_DescribeHub_402656718(name: "describeHub",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/accounts", validator: validate_DescribeHub_402656719, base: "/",
    makeUrl: url_DescribeHub_402656720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSecurityHub_402656746 = ref object of OpenApiRestCall_402656044
proc url_DisableSecurityHub_402656748(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableSecurityHub_402656747(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656749 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Security-Token", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Signature")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Signature", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Algorithm", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Date")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Date", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Credential")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Credential", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656756: Call_DisableSecurityHub_402656746;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub.</p> <p>When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and cannot be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed.</p> <p>If you want to save your existing findings, you must export them before you disable Security Hub.</p>
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_DisableSecurityHub_402656746): Recallable =
  ## disableSecurityHub
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub.</p> <p>When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and cannot be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed.</p> <p>If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  result = call_402656757.call(nil, nil, nil, nil, nil)

var disableSecurityHub* = Call_DisableSecurityHub_402656746(
    name: "disableSecurityHub", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_DisableSecurityHub_402656747, base: "/",
    makeUrl: url_DisableSecurityHub_402656748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProducts_402656758 = ref object of OpenApiRestCall_402656044
proc url_DescribeProducts_402656760(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProducts_402656759(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the available products that you can subscribe to and integrate with Security Hub in order to consolidate findings.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : The maximum number of results to return.
  ##   
                                                                                           ## NextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## <p>The 
                                                                                           ## token 
                                                                                           ## that 
                                                                                           ## is 
                                                                                           ## required 
                                                                                           ## for 
                                                                                           ## pagination. 
                                                                                           ## On 
                                                                                           ## your 
                                                                                           ## first 
                                                                                           ## call 
                                                                                           ## to 
                                                                                           ## the 
                                                                                           ## <code>DescribeProducts</code> 
                                                                                           ## operation, 
                                                                                           ## set 
                                                                                           ## the 
                                                                                           ## value 
                                                                                           ## of 
                                                                                           ## this 
                                                                                           ## parameter 
                                                                                           ## to 
                                                                                           ## <code>NULL</code>.</p> 
                                                                                           ## <p>For 
                                                                                           ## subsequent 
                                                                                           ## calls 
                                                                                           ## to 
                                                                                           ## the 
                                                                                           ## operation, 
                                                                                           ## to 
                                                                                           ## continue 
                                                                                           ## listing 
                                                                                           ## data, 
                                                                                           ## set 
                                                                                           ## the 
                                                                                           ## value 
                                                                                           ## of 
                                                                                           ## this 
                                                                                           ## parameter 
                                                                                           ## to 
                                                                                           ## the 
                                                                                           ## value 
                                                                                           ## returned 
                                                                                           ## from 
                                                                                           ## the 
                                                                                           ## previous 
                                                                                           ## response.</p>
  section = newJObject()
  var valid_402656761 = query.getOrDefault("MaxResults")
  valid_402656761 = validateParameter(valid_402656761, JInt, required = false,
                                      default = nil)
  if valid_402656761 != nil:
    section.add "MaxResults", valid_402656761
  var valid_402656762 = query.getOrDefault("NextToken")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "NextToken", valid_402656762
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656763 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Security-Token", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Signature")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Signature", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Algorithm", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Date")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Date", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Credential")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Credential", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656770: Call_DescribeProducts_402656758;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the available products that you can subscribe to and integrate with Security Hub in order to consolidate findings.
                                                                                         ## 
  let valid = call_402656770.validator(path, query, header, formData, body, _)
  let scheme = call_402656770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656770.makeUrl(scheme.get, call_402656770.host, call_402656770.base,
                                   call_402656770.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656770, uri, valid, _)

proc call*(call_402656771: Call_DescribeProducts_402656758; MaxResults: int = 0;
           NextToken: string = ""): Recallable =
  ## describeProducts
  ## Returns information about the available products that you can subscribe to and integrate with Security Hub in order to consolidate findings.
  ##   
                                                                                                                                                 ## MaxResults: int
                                                                                                                                                 ##             
                                                                                                                                                 ## : 
                                                                                                                                                 ## The 
                                                                                                                                                 ## maximum 
                                                                                                                                                 ## number 
                                                                                                                                                 ## of 
                                                                                                                                                 ## results 
                                                                                                                                                 ## to 
                                                                                                                                                 ## return.
  ##   
                                                                                                                                                           ## NextToken: string
                                                                                                                                                           ##            
                                                                                                                                                           ## : 
                                                                                                                                                           ## <p>The 
                                                                                                                                                           ## token 
                                                                                                                                                           ## that 
                                                                                                                                                           ## is 
                                                                                                                                                           ## required 
                                                                                                                                                           ## for 
                                                                                                                                                           ## pagination. 
                                                                                                                                                           ## On 
                                                                                                                                                           ## your 
                                                                                                                                                           ## first 
                                                                                                                                                           ## call 
                                                                                                                                                           ## to 
                                                                                                                                                           ## the 
                                                                                                                                                           ## <code>DescribeProducts</code> 
                                                                                                                                                           ## operation, 
                                                                                                                                                           ## set 
                                                                                                                                                           ## the 
                                                                                                                                                           ## value 
                                                                                                                                                           ## of 
                                                                                                                                                           ## this 
                                                                                                                                                           ## parameter 
                                                                                                                                                           ## to 
                                                                                                                                                           ## <code>NULL</code>.</p> 
                                                                                                                                                           ## <p>For 
                                                                                                                                                           ## subsequent 
                                                                                                                                                           ## calls 
                                                                                                                                                           ## to 
                                                                                                                                                           ## the 
                                                                                                                                                           ## operation, 
                                                                                                                                                           ## to 
                                                                                                                                                           ## continue 
                                                                                                                                                           ## listing 
                                                                                                                                                           ## data, 
                                                                                                                                                           ## set 
                                                                                                                                                           ## the 
                                                                                                                                                           ## value 
                                                                                                                                                           ## of 
                                                                                                                                                           ## this 
                                                                                                                                                           ## parameter 
                                                                                                                                                           ## to 
                                                                                                                                                           ## the 
                                                                                                                                                           ## value 
                                                                                                                                                           ## returned 
                                                                                                                                                           ## from 
                                                                                                                                                           ## the 
                                                                                                                                                           ## previous 
                                                                                                                                                           ## response.</p>
  var query_402656772 = newJObject()
  add(query_402656772, "MaxResults", newJInt(MaxResults))
  add(query_402656772, "NextToken", newJString(NextToken))
  result = call_402656771.call(nil, query_402656772, nil, nil, nil)

var describeProducts* = Call_DescribeProducts_402656758(
    name: "describeProducts", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/products",
    validator: validate_DescribeProducts_402656759, base: "/",
    makeUrl: url_DescribeProducts_402656760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStandards_402656773 = ref object of OpenApiRestCall_402656044
proc url_DescribeStandards_402656775(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStandards_402656774(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of the available standards in Security Hub.</p> <p>For each standard, the results include the standard ARN, the name, and a description. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : The maximum number of standards to return.
  ##   
                                                                                             ## NextToken: JString
                                                                                             ##            
                                                                                             ## : 
                                                                                             ## <p>The 
                                                                                             ## token 
                                                                                             ## that 
                                                                                             ## is 
                                                                                             ## required 
                                                                                             ## for 
                                                                                             ## pagination. 
                                                                                             ## On 
                                                                                             ## your 
                                                                                             ## first 
                                                                                             ## call 
                                                                                             ## to 
                                                                                             ## the 
                                                                                             ## <code>DescribeStandards</code> 
                                                                                             ## operation, 
                                                                                             ## set 
                                                                                             ## the 
                                                                                             ## value 
                                                                                             ## of 
                                                                                             ## this 
                                                                                             ## parameter 
                                                                                             ## to 
                                                                                             ## <code>NULL</code>.</p> 
                                                                                             ## <p>For 
                                                                                             ## subsequent 
                                                                                             ## calls 
                                                                                             ## to 
                                                                                             ## the 
                                                                                             ## operation, 
                                                                                             ## to 
                                                                                             ## continue 
                                                                                             ## listing 
                                                                                             ## data, 
                                                                                             ## set 
                                                                                             ## the 
                                                                                             ## value 
                                                                                             ## of 
                                                                                             ## this 
                                                                                             ## parameter 
                                                                                             ## to 
                                                                                             ## the 
                                                                                             ## value 
                                                                                             ## returned 
                                                                                             ## from 
                                                                                             ## the 
                                                                                             ## previous 
                                                                                             ## response.</p>
  section = newJObject()
  var valid_402656776 = query.getOrDefault("MaxResults")
  valid_402656776 = validateParameter(valid_402656776, JInt, required = false,
                                      default = nil)
  if valid_402656776 != nil:
    section.add "MaxResults", valid_402656776
  var valid_402656777 = query.getOrDefault("NextToken")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "NextToken", valid_402656777
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656778 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Security-Token", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Signature")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Signature", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Algorithm", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Date")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Date", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Credential")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Credential", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656785: Call_DescribeStandards_402656773;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the available standards in Security Hub.</p> <p>For each standard, the results include the standard ARN, the name, and a description. </p>
                                                                                         ## 
  let valid = call_402656785.validator(path, query, header, formData, body, _)
  let scheme = call_402656785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656785.makeUrl(scheme.get, call_402656785.host, call_402656785.base,
                                   call_402656785.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656785, uri, valid, _)

proc call*(call_402656786: Call_DescribeStandards_402656773;
           MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## describeStandards
  ## <p>Returns a list of the available standards in Security Hub.</p> <p>For each standard, the results include the standard ARN, the name, and a description. </p>
  ##   
                                                                                                                                                                    ## MaxResults: int
                                                                                                                                                                    ##             
                                                                                                                                                                    ## : 
                                                                                                                                                                    ## The 
                                                                                                                                                                    ## maximum 
                                                                                                                                                                    ## number 
                                                                                                                                                                    ## of 
                                                                                                                                                                    ## standards 
                                                                                                                                                                    ## to 
                                                                                                                                                                    ## return.
  ##   
                                                                                                                                                                              ## NextToken: string
                                                                                                                                                                              ##            
                                                                                                                                                                              ## : 
                                                                                                                                                                              ## <p>The 
                                                                                                                                                                              ## token 
                                                                                                                                                                              ## that 
                                                                                                                                                                              ## is 
                                                                                                                                                                              ## required 
                                                                                                                                                                              ## for 
                                                                                                                                                                              ## pagination. 
                                                                                                                                                                              ## On 
                                                                                                                                                                              ## your 
                                                                                                                                                                              ## first 
                                                                                                                                                                              ## call 
                                                                                                                                                                              ## to 
                                                                                                                                                                              ## the 
                                                                                                                                                                              ## <code>DescribeStandards</code> 
                                                                                                                                                                              ## operation, 
                                                                                                                                                                              ## set 
                                                                                                                                                                              ## the 
                                                                                                                                                                              ## value 
                                                                                                                                                                              ## of 
                                                                                                                                                                              ## this 
                                                                                                                                                                              ## parameter 
                                                                                                                                                                              ## to 
                                                                                                                                                                              ## <code>NULL</code>.</p> 
                                                                                                                                                                              ## <p>For 
                                                                                                                                                                              ## subsequent 
                                                                                                                                                                              ## calls 
                                                                                                                                                                              ## to 
                                                                                                                                                                              ## the 
                                                                                                                                                                              ## operation, 
                                                                                                                                                                              ## to 
                                                                                                                                                                              ## continue 
                                                                                                                                                                              ## listing 
                                                                                                                                                                              ## data, 
                                                                                                                                                                              ## set 
                                                                                                                                                                              ## the 
                                                                                                                                                                              ## value 
                                                                                                                                                                              ## of 
                                                                                                                                                                              ## this 
                                                                                                                                                                              ## parameter 
                                                                                                                                                                              ## to 
                                                                                                                                                                              ## the 
                                                                                                                                                                              ## value 
                                                                                                                                                                              ## returned 
                                                                                                                                                                              ## from 
                                                                                                                                                                              ## the 
                                                                                                                                                                              ## previous 
                                                                                                                                                                              ## response.</p>
  var query_402656787 = newJObject()
  add(query_402656787, "MaxResults", newJInt(MaxResults))
  add(query_402656787, "NextToken", newJString(NextToken))
  result = call_402656786.call(nil, query_402656787, nil, nil, nil)

var describeStandards* = Call_DescribeStandards_402656773(
    name: "describeStandards", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/standards",
    validator: validate_DescribeStandards_402656774, base: "/",
    makeUrl: url_DescribeStandards_402656775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStandardsControls_402656788 = ref object of OpenApiRestCall_402656044
proc url_DescribeStandardsControls_402656790(protocol: Scheme; host: string;
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

proc validate_DescribeStandardsControls_402656789(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns a list of security standards controls.</p> <p>For each control, the results include information about whether it is currently enabled, the severity, and a link to remediation information.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   StandardsSubscriptionArn: JString (required)
                                 ##                           : The ARN of a resource that represents your subscription to a supported standard.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `StandardsSubscriptionArn` field"
  var valid_402656791 = path.getOrDefault("StandardsSubscriptionArn")
  valid_402656791 = validateParameter(valid_402656791, JString, required = true,
                                      default = nil)
  if valid_402656791 != nil:
    section.add "StandardsSubscriptionArn", valid_402656791
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : The maximum number of security standard controls to return.
  ##   
                                                                                                              ## NextToken: JString
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## <p>The 
                                                                                                              ## token 
                                                                                                              ## that 
                                                                                                              ## is 
                                                                                                              ## required 
                                                                                                              ## for 
                                                                                                              ## pagination. 
                                                                                                              ## On 
                                                                                                              ## your 
                                                                                                              ## first 
                                                                                                              ## call 
                                                                                                              ## to 
                                                                                                              ## the 
                                                                                                              ## <code>DescribeStandardsControls</code> 
                                                                                                              ## operation, 
                                                                                                              ## set 
                                                                                                              ## the 
                                                                                                              ## value 
                                                                                                              ## of 
                                                                                                              ## this 
                                                                                                              ## parameter 
                                                                                                              ## to 
                                                                                                              ## <code>NULL</code>.</p> 
                                                                                                              ## <p>For 
                                                                                                              ## subsequent 
                                                                                                              ## calls 
                                                                                                              ## to 
                                                                                                              ## the 
                                                                                                              ## operation, 
                                                                                                              ## to 
                                                                                                              ## continue 
                                                                                                              ## listing 
                                                                                                              ## data, 
                                                                                                              ## set 
                                                                                                              ## the 
                                                                                                              ## value 
                                                                                                              ## of 
                                                                                                              ## this 
                                                                                                              ## parameter 
                                                                                                              ## to 
                                                                                                              ## the 
                                                                                                              ## value 
                                                                                                              ## returned 
                                                                                                              ## from 
                                                                                                              ## the 
                                                                                                              ## previous 
                                                                                                              ## response.</p>
  section = newJObject()
  var valid_402656792 = query.getOrDefault("MaxResults")
  valid_402656792 = validateParameter(valid_402656792, JInt, required = false,
                                      default = nil)
  if valid_402656792 != nil:
    section.add "MaxResults", valid_402656792
  var valid_402656793 = query.getOrDefault("NextToken")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "NextToken", valid_402656793
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656794 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Security-Token", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Signature")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Signature", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Algorithm", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Date")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Date", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Credential")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Credential", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656801: Call_DescribeStandardsControls_402656788;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of security standards controls.</p> <p>For each control, the results include information about whether it is currently enabled, the severity, and a link to remediation information.</p>
                                                                                         ## 
  let valid = call_402656801.validator(path, query, header, formData, body, _)
  let scheme = call_402656801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656801.makeUrl(scheme.get, call_402656801.host, call_402656801.base,
                                   call_402656801.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656801, uri, valid, _)

proc call*(call_402656802: Call_DescribeStandardsControls_402656788;
           StandardsSubscriptionArn: string; MaxResults: int = 0;
           NextToken: string = ""): Recallable =
  ## describeStandardsControls
  ## <p>Returns a list of security standards controls.</p> <p>For each control, the results include information about whether it is currently enabled, the severity, and a link to remediation information.</p>
  ##   
                                                                                                                                                                                                               ## StandardsSubscriptionArn: string (required)
                                                                                                                                                                                                               ##                           
                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                               ## ARN 
                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                               ## a 
                                                                                                                                                                                                               ## resource 
                                                                                                                                                                                                               ## that 
                                                                                                                                                                                                               ## represents 
                                                                                                                                                                                                               ## your 
                                                                                                                                                                                                               ## subscription 
                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                               ## a 
                                                                                                                                                                                                               ## supported 
                                                                                                                                                                                                               ## standard.
  ##   
                                                                                                                                                                                                                           ## MaxResults: int
                                                                                                                                                                                                                           ##             
                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                           ## maximum 
                                                                                                                                                                                                                           ## number 
                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                           ## security 
                                                                                                                                                                                                                           ## standard 
                                                                                                                                                                                                                           ## controls 
                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                           ## return.
  ##   
                                                                                                                                                                                                                                     ## NextToken: string
                                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                     ## <p>The 
                                                                                                                                                                                                                                     ## token 
                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                     ## is 
                                                                                                                                                                                                                                     ## required 
                                                                                                                                                                                                                                     ## for 
                                                                                                                                                                                                                                     ## pagination. 
                                                                                                                                                                                                                                     ## On 
                                                                                                                                                                                                                                     ## your 
                                                                                                                                                                                                                                     ## first 
                                                                                                                                                                                                                                     ## call 
                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## <code>DescribeStandardsControls</code> 
                                                                                                                                                                                                                                     ## operation, 
                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## value 
                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                     ## this 
                                                                                                                                                                                                                                     ## parameter 
                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                     ## <code>NULL</code>.</p> 
                                                                                                                                                                                                                                     ## <p>For 
                                                                                                                                                                                                                                     ## subsequent 
                                                                                                                                                                                                                                     ## calls 
                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## operation, 
                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                     ## continue 
                                                                                                                                                                                                                                     ## listing 
                                                                                                                                                                                                                                     ## data, 
                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## value 
                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                     ## this 
                                                                                                                                                                                                                                     ## parameter 
                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## value 
                                                                                                                                                                                                                                     ## returned 
                                                                                                                                                                                                                                     ## from 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## previous 
                                                                                                                                                                                                                                     ## response.</p>
  var path_402656803 = newJObject()
  var query_402656804 = newJObject()
  add(path_402656803, "StandardsSubscriptionArn",
      newJString(StandardsSubscriptionArn))
  add(query_402656804, "MaxResults", newJInt(MaxResults))
  add(query_402656804, "NextToken", newJString(NextToken))
  result = call_402656802.call(path_402656803, query_402656804, nil, nil, nil)

var describeStandardsControls* = Call_DescribeStandardsControls_402656788(
    name: "describeStandardsControls", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com",
    route: "/standards/controls/{StandardsSubscriptionArn}",
    validator: validate_DescribeStandardsControls_402656789, base: "/",
    makeUrl: url_DescribeStandardsControls_402656790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableImportFindingsForProduct_402656805 = ref object of OpenApiRestCall_402656044
proc url_DisableImportFindingsForProduct_402656807(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DisableImportFindingsForProduct_402656806(path: JsonNode;
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
  var valid_402656808 = path.getOrDefault("ProductSubscriptionArn")
  valid_402656808 = validateParameter(valid_402656808, JString, required = true,
                                      default = nil)
  if valid_402656808 != nil:
    section.add "ProductSubscriptionArn", valid_402656808
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656809 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Security-Token", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Signature")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Signature", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Algorithm", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Date")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Date", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Credential")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Credential", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656816: Call_DisableImportFindingsForProduct_402656805;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the integration of the specified product with Security Hub. After the integration is disabled, findings from that product are no longer sent to Security Hub.
                                                                                         ## 
  let valid = call_402656816.validator(path, query, header, formData, body, _)
  let scheme = call_402656816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656816.makeUrl(scheme.get, call_402656816.host, call_402656816.base,
                                   call_402656816.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656816, uri, valid, _)

proc call*(call_402656817: Call_DisableImportFindingsForProduct_402656805;
           ProductSubscriptionArn: string): Recallable =
  ## disableImportFindingsForProduct
  ## Disables the integration of the specified product with Security Hub. After the integration is disabled, findings from that product are no longer sent to Security Hub.
  ##   
                                                                                                                                                                           ## ProductSubscriptionArn: string (required)
                                                                                                                                                                           ##                         
                                                                                                                                                                           ## : 
                                                                                                                                                                           ## The 
                                                                                                                                                                           ## ARN 
                                                                                                                                                                           ## of 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## integrated 
                                                                                                                                                                           ## product 
                                                                                                                                                                           ## to 
                                                                                                                                                                           ## disable 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## integration 
                                                                                                                                                                           ## for.
  var path_402656818 = newJObject()
  add(path_402656818, "ProductSubscriptionArn",
      newJString(ProductSubscriptionArn))
  result = call_402656817.call(path_402656818, nil, nil, nil, nil)

var disableImportFindingsForProduct* = Call_DisableImportFindingsForProduct_402656805(
    name: "disableImportFindingsForProduct", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com",
    route: "/productSubscriptions/{ProductSubscriptionArn}",
    validator: validate_DisableImportFindingsForProduct_402656806, base: "/",
    makeUrl: url_DisableImportFindingsForProduct_402656807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_402656819 = ref object of OpenApiRestCall_402656044
proc url_DisassociateFromMasterAccount_402656821(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateFromMasterAccount_402656820(path: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656822 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Security-Token", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Signature")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Signature", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Algorithm", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Date")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Date", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Credential")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Credential", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656829: Call_DisassociateFromMasterAccount_402656819;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the current Security Hub member account from the associated master account.
                                                                                         ## 
  let valid = call_402656829.validator(path, query, header, formData, body, _)
  let scheme = call_402656829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656829.makeUrl(scheme.get, call_402656829.host, call_402656829.base,
                                   call_402656829.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656829, uri, valid, _)

proc call*(call_402656830: Call_DisassociateFromMasterAccount_402656819): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current Security Hub member account from the associated master account.
  result = call_402656830.call(nil, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_402656819(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_402656820, base: "/",
    makeUrl: url_DisassociateFromMasterAccount_402656821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_402656831 = ref object of OpenApiRestCall_402656044
proc url_DisassociateMembers_402656833(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateMembers_402656832(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656834 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Security-Token", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-Signature")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-Signature", valid_402656835
  var valid_402656836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656836
  var valid_402656837 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Algorithm", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Date")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Date", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Credential")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Credential", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656840
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

proc call*(call_402656842: Call_DisassociateMembers_402656831;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified member accounts from the associated master account.
                                                                                         ## 
  let valid = call_402656842.validator(path, query, header, formData, body, _)
  let scheme = call_402656842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656842.makeUrl(scheme.get, call_402656842.host, call_402656842.base,
                                   call_402656842.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656842, uri, valid, _)

proc call*(call_402656843: Call_DisassociateMembers_402656831; body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates the specified member accounts from the associated master account.
  ##   
                                                                                    ## body: JObject (required)
  var body_402656844 = newJObject()
  if body != nil:
    body_402656844 = body
  result = call_402656843.call(nil, nil, nil, nil, body_402656844)

var disassociateMembers* = Call_DisassociateMembers_402656831(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/members/disassociate",
    validator: validate_DisassociateMembers_402656832, base: "/",
    makeUrl: url_DisassociateMembers_402656833,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableImportFindingsForProduct_402656860 = ref object of OpenApiRestCall_402656044
proc url_EnableImportFindingsForProduct_402656862(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableImportFindingsForProduct_402656861(path: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656863 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-Security-Token", valid_402656863
  var valid_402656864 = header.getOrDefault("X-Amz-Signature")
  valid_402656864 = validateParameter(valid_402656864, JString,
                                      required = false, default = nil)
  if valid_402656864 != nil:
    section.add "X-Amz-Signature", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656865
  var valid_402656866 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656866 = validateParameter(valid_402656866, JString,
                                      required = false, default = nil)
  if valid_402656866 != nil:
    section.add "X-Amz-Algorithm", valid_402656866
  var valid_402656867 = header.getOrDefault("X-Amz-Date")
  valid_402656867 = validateParameter(valid_402656867, JString,
                                      required = false, default = nil)
  if valid_402656867 != nil:
    section.add "X-Amz-Date", valid_402656867
  var valid_402656868 = header.getOrDefault("X-Amz-Credential")
  valid_402656868 = validateParameter(valid_402656868, JString,
                                      required = false, default = nil)
  if valid_402656868 != nil:
    section.add "X-Amz-Credential", valid_402656868
  var valid_402656869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656869
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

proc call*(call_402656871: Call_EnableImportFindingsForProduct_402656860;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub.</p> <p>When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.</p>
                                                                                         ## 
  let valid = call_402656871.validator(path, query, header, formData, body, _)
  let scheme = call_402656871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656871.makeUrl(scheme.get, call_402656871.host, call_402656871.base,
                                   call_402656871.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656871, uri, valid, _)

proc call*(call_402656872: Call_EnableImportFindingsForProduct_402656860;
           body: JsonNode): Recallable =
  ## enableImportFindingsForProduct
  ## <p>Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub.</p> <p>When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.</p>
  ##   
                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656873 = newJObject()
  if body != nil:
    body_402656873 = body
  result = call_402656872.call(nil, nil, nil, nil, body_402656873)

var enableImportFindingsForProduct* = Call_EnableImportFindingsForProduct_402656860(
    name: "enableImportFindingsForProduct", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_EnableImportFindingsForProduct_402656861, base: "/",
    makeUrl: url_EnableImportFindingsForProduct_402656862,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnabledProductsForImport_402656845 = ref object of OpenApiRestCall_402656044
proc url_ListEnabledProductsForImport_402656847(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEnabledProductsForImport_402656846(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists all findings-generating solutions (products) that you are subscribed to receive findings from in Security Hub.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : The maximum number of items to return in the response.
  ##   
                                                                                                         ## NextToken: JString
                                                                                                         ##            
                                                                                                         ## : 
                                                                                                         ## <p>The 
                                                                                                         ## token 
                                                                                                         ## that 
                                                                                                         ## is 
                                                                                                         ## required 
                                                                                                         ## for 
                                                                                                         ## pagination. 
                                                                                                         ## On 
                                                                                                         ## your 
                                                                                                         ## first 
                                                                                                         ## call 
                                                                                                         ## to 
                                                                                                         ## the 
                                                                                                         ## <code>ListEnabledProductsForImport</code> 
                                                                                                         ## operation, 
                                                                                                         ## set 
                                                                                                         ## the 
                                                                                                         ## value 
                                                                                                         ## of 
                                                                                                         ## this 
                                                                                                         ## parameter 
                                                                                                         ## to 
                                                                                                         ## <code>NULL</code>.</p> 
                                                                                                         ## <p>For 
                                                                                                         ## subsequent 
                                                                                                         ## calls 
                                                                                                         ## to 
                                                                                                         ## the 
                                                                                                         ## operation, 
                                                                                                         ## to 
                                                                                                         ## continue 
                                                                                                         ## listing 
                                                                                                         ## data, 
                                                                                                         ## set 
                                                                                                         ## the 
                                                                                                         ## value 
                                                                                                         ## of 
                                                                                                         ## this 
                                                                                                         ## parameter 
                                                                                                         ## to 
                                                                                                         ## the 
                                                                                                         ## value 
                                                                                                         ## returned 
                                                                                                         ## from 
                                                                                                         ## the 
                                                                                                         ## previous 
                                                                                                         ## response.</p>
  section = newJObject()
  var valid_402656848 = query.getOrDefault("MaxResults")
  valid_402656848 = validateParameter(valid_402656848, JInt, required = false,
                                      default = nil)
  if valid_402656848 != nil:
    section.add "MaxResults", valid_402656848
  var valid_402656849 = query.getOrDefault("NextToken")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "NextToken", valid_402656849
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656850 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-Security-Token", valid_402656850
  var valid_402656851 = header.getOrDefault("X-Amz-Signature")
  valid_402656851 = validateParameter(valid_402656851, JString,
                                      required = false, default = nil)
  if valid_402656851 != nil:
    section.add "X-Amz-Signature", valid_402656851
  var valid_402656852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Algorithm", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Date")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Date", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Credential")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Credential", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656857: Call_ListEnabledProductsForImport_402656845;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all findings-generating solutions (products) that you are subscribed to receive findings from in Security Hub.
                                                                                         ## 
  let valid = call_402656857.validator(path, query, header, formData, body, _)
  let scheme = call_402656857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656857.makeUrl(scheme.get, call_402656857.host, call_402656857.base,
                                   call_402656857.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656857, uri, valid, _)

proc call*(call_402656858: Call_ListEnabledProductsForImport_402656845;
           MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## listEnabledProductsForImport
  ## Lists all findings-generating solutions (products) that you are subscribed to receive findings from in Security Hub.
  ##   
                                                                                                                         ## MaxResults: int
                                                                                                                         ##             
                                                                                                                         ## : 
                                                                                                                         ## The 
                                                                                                                         ## maximum 
                                                                                                                         ## number 
                                                                                                                         ## of 
                                                                                                                         ## items 
                                                                                                                         ## to 
                                                                                                                         ## return 
                                                                                                                         ## in 
                                                                                                                         ## the 
                                                                                                                         ## response.
  ##   
                                                                                                                                     ## NextToken: string
                                                                                                                                     ##            
                                                                                                                                     ## : 
                                                                                                                                     ## <p>The 
                                                                                                                                     ## token 
                                                                                                                                     ## that 
                                                                                                                                     ## is 
                                                                                                                                     ## required 
                                                                                                                                     ## for 
                                                                                                                                     ## pagination. 
                                                                                                                                     ## On 
                                                                                                                                     ## your 
                                                                                                                                     ## first 
                                                                                                                                     ## call 
                                                                                                                                     ## to 
                                                                                                                                     ## the 
                                                                                                                                     ## <code>ListEnabledProductsForImport</code> 
                                                                                                                                     ## operation, 
                                                                                                                                     ## set 
                                                                                                                                     ## the 
                                                                                                                                     ## value 
                                                                                                                                     ## of 
                                                                                                                                     ## this 
                                                                                                                                     ## parameter 
                                                                                                                                     ## to 
                                                                                                                                     ## <code>NULL</code>.</p> 
                                                                                                                                     ## <p>For 
                                                                                                                                     ## subsequent 
                                                                                                                                     ## calls 
                                                                                                                                     ## to 
                                                                                                                                     ## the 
                                                                                                                                     ## operation, 
                                                                                                                                     ## to 
                                                                                                                                     ## continue 
                                                                                                                                     ## listing 
                                                                                                                                     ## data, 
                                                                                                                                     ## set 
                                                                                                                                     ## the 
                                                                                                                                     ## value 
                                                                                                                                     ## of 
                                                                                                                                     ## this 
                                                                                                                                     ## parameter 
                                                                                                                                     ## to 
                                                                                                                                     ## the 
                                                                                                                                     ## value 
                                                                                                                                     ## returned 
                                                                                                                                     ## from 
                                                                                                                                     ## the 
                                                                                                                                     ## previous 
                                                                                                                                     ## response.</p>
  var query_402656859 = newJObject()
  add(query_402656859, "MaxResults", newJInt(MaxResults))
  add(query_402656859, "NextToken", newJString(NextToken))
  result = call_402656858.call(nil, query_402656859, nil, nil, nil)

var listEnabledProductsForImport* = Call_ListEnabledProductsForImport_402656845(
    name: "listEnabledProductsForImport", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_ListEnabledProductsForImport_402656846, base: "/",
    makeUrl: url_ListEnabledProductsForImport_402656847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnabledStandards_402656874 = ref object of OpenApiRestCall_402656044
proc url_GetEnabledStandards_402656876(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEnabledStandards_402656875(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656877 = query.getOrDefault("MaxResults")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "MaxResults", valid_402656877
  var valid_402656878 = query.getOrDefault("NextToken")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "NextToken", valid_402656878
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656879 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "X-Amz-Security-Token", valid_402656879
  var valid_402656880 = header.getOrDefault("X-Amz-Signature")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "X-Amz-Signature", valid_402656880
  var valid_402656881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656881 = validateParameter(valid_402656881, JString,
                                      required = false, default = nil)
  if valid_402656881 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656881
  var valid_402656882 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656882 = validateParameter(valid_402656882, JString,
                                      required = false, default = nil)
  if valid_402656882 != nil:
    section.add "X-Amz-Algorithm", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Date")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Date", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-Credential")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Credential", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656885
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

proc call*(call_402656887: Call_GetEnabledStandards_402656874;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the standards that are currently enabled.
                                                                                         ## 
  let valid = call_402656887.validator(path, query, header, formData, body, _)
  let scheme = call_402656887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656887.makeUrl(scheme.get, call_402656887.host, call_402656887.base,
                                   call_402656887.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656887, uri, valid, _)

proc call*(call_402656888: Call_GetEnabledStandards_402656874; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getEnabledStandards
  ## Returns a list of the standards that are currently enabled.
  ##   MaxResults: string
                                                                ##             : Pagination limit
  ##   
                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                            ## NextToken: string
                                                                                                                            ##            
                                                                                                                            ## : 
                                                                                                                            ## Pagination 
                                                                                                                            ## token
  var query_402656889 = newJObject()
  var body_402656890 = newJObject()
  add(query_402656889, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656890 = body
  add(query_402656889, "NextToken", newJString(NextToken))
  result = call_402656888.call(nil, query_402656889, nil, nil, body_402656890)

var getEnabledStandards* = Call_GetEnabledStandards_402656874(
    name: "getEnabledStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/get",
    validator: validate_GetEnabledStandards_402656875, base: "/",
    makeUrl: url_GetEnabledStandards_402656876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_402656891 = ref object of OpenApiRestCall_402656044
proc url_GetFindings_402656893(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFindings_402656892(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656894 = query.getOrDefault("MaxResults")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "MaxResults", valid_402656894
  var valid_402656895 = query.getOrDefault("NextToken")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "NextToken", valid_402656895
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656896 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656896 = validateParameter(valid_402656896, JString,
                                      required = false, default = nil)
  if valid_402656896 != nil:
    section.add "X-Amz-Security-Token", valid_402656896
  var valid_402656897 = header.getOrDefault("X-Amz-Signature")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "X-Amz-Signature", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Algorithm", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Date")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Date", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Credential")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Credential", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656902
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

proc call*(call_402656904: Call_GetFindings_402656891; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of findings that match the specified criteria.
                                                                                         ## 
  let valid = call_402656904.validator(path, query, header, formData, body, _)
  let scheme = call_402656904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656904.makeUrl(scheme.get, call_402656904.host, call_402656904.base,
                                   call_402656904.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656904, uri, valid, _)

proc call*(call_402656905: Call_GetFindings_402656891; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFindings
  ## Returns a list of findings that match the specified criteria.
  ##   MaxResults: string
                                                                  ##             : Pagination limit
  ##   
                                                                                                   ## body: JObject (required)
  ##   
                                                                                                                              ## NextToken: string
                                                                                                                              ##            
                                                                                                                              ## : 
                                                                                                                              ## Pagination 
                                                                                                                              ## token
  var query_402656906 = newJObject()
  var body_402656907 = newJObject()
  add(query_402656906, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656907 = body
  add(query_402656906, "NextToken", newJString(NextToken))
  result = call_402656905.call(nil, query_402656906, nil, nil, body_402656907)

var getFindings* = Call_GetFindings_402656891(name: "getFindings",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_GetFindings_402656892, base: "/",
    makeUrl: url_GetFindings_402656893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_402656908 = ref object of OpenApiRestCall_402656044
proc url_UpdateFindings_402656910(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFindings_402656909(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656911 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-Security-Token", valid_402656911
  var valid_402656912 = header.getOrDefault("X-Amz-Signature")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-Signature", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Algorithm", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Date")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Date", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Credential")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Credential", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656917
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

proc call*(call_402656919: Call_UpdateFindings_402656908; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
                                                                                         ## 
  let valid = call_402656919.validator(path, query, header, formData, body, _)
  let scheme = call_402656919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656919.makeUrl(scheme.get, call_402656919.host, call_402656919.base,
                                   call_402656919.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656919, uri, valid, _)

proc call*(call_402656920: Call_UpdateFindings_402656908; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ##   
                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656921 = newJObject()
  if body != nil:
    body_402656921 = body
  result = call_402656920.call(nil, nil, nil, nil, body_402656921)

var updateFindings* = Call_UpdateFindings_402656908(name: "updateFindings",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_UpdateFindings_402656909, base: "/",
    makeUrl: url_UpdateFindings_402656910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsightResults_402656922 = ref object of OpenApiRestCall_402656044
proc url_GetInsightResults_402656924(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetInsightResults_402656923(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656925 = path.getOrDefault("InsightArn")
  valid_402656925 = validateParameter(valid_402656925, JString, required = true,
                                      default = nil)
  if valid_402656925 != nil:
    section.add "InsightArn", valid_402656925
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656926 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-Security-Token", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-Signature")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-Signature", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Algorithm", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Date")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Date", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Credential")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Credential", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656933: Call_GetInsightResults_402656922;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the results of the Security Hub insight specified by the insight ARN.
                                                                                         ## 
  let valid = call_402656933.validator(path, query, header, formData, body, _)
  let scheme = call_402656933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656933.makeUrl(scheme.get, call_402656933.host, call_402656933.base,
                                   call_402656933.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656933, uri, valid, _)

proc call*(call_402656934: Call_GetInsightResults_402656922; InsightArn: string): Recallable =
  ## getInsightResults
  ## Lists the results of the Security Hub insight specified by the insight ARN.
  ##   
                                                                                ## InsightArn: string (required)
                                                                                ##             
                                                                                ## : 
                                                                                ## The 
                                                                                ## ARN 
                                                                                ## of 
                                                                                ## the 
                                                                                ## insight 
                                                                                ## for 
                                                                                ## which 
                                                                                ## to 
                                                                                ## return 
                                                                                ## results.
  var path_402656935 = newJObject()
  add(path_402656935, "InsightArn", newJString(InsightArn))
  result = call_402656934.call(path_402656935, nil, nil, nil, nil)

var getInsightResults* = Call_GetInsightResults_402656922(
    name: "getInsightResults", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/insights/results/{InsightArn}",
    validator: validate_GetInsightResults_402656923, base: "/",
    makeUrl: url_GetInsightResults_402656924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsights_402656936 = ref object of OpenApiRestCall_402656044
proc url_GetInsights_402656938(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInsights_402656937(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656939 = query.getOrDefault("MaxResults")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "MaxResults", valid_402656939
  var valid_402656940 = query.getOrDefault("NextToken")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "NextToken", valid_402656940
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656941 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656941 = validateParameter(valid_402656941, JString,
                                      required = false, default = nil)
  if valid_402656941 != nil:
    section.add "X-Amz-Security-Token", valid_402656941
  var valid_402656942 = header.getOrDefault("X-Amz-Signature")
  valid_402656942 = validateParameter(valid_402656942, JString,
                                      required = false, default = nil)
  if valid_402656942 != nil:
    section.add "X-Amz-Signature", valid_402656942
  var valid_402656943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656943 = validateParameter(valid_402656943, JString,
                                      required = false, default = nil)
  if valid_402656943 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656943
  var valid_402656944 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-Algorithm", valid_402656944
  var valid_402656945 = header.getOrDefault("X-Amz-Date")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Date", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Credential")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Credential", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656947
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

proc call*(call_402656949: Call_GetInsights_402656936; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists and describes insights for the specified insight ARNs.
                                                                                         ## 
  let valid = call_402656949.validator(path, query, header, formData, body, _)
  let scheme = call_402656949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656949.makeUrl(scheme.get, call_402656949.host, call_402656949.base,
                                   call_402656949.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656949, uri, valid, _)

proc call*(call_402656950: Call_GetInsights_402656936; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getInsights
  ## Lists and describes insights for the specified insight ARNs.
  ##   MaxResults: string
                                                                 ##             : Pagination limit
  ##   
                                                                                                  ## body: JObject (required)
  ##   
                                                                                                                             ## NextToken: string
                                                                                                                             ##            
                                                                                                                             ## : 
                                                                                                                             ## Pagination 
                                                                                                                             ## token
  var query_402656951 = newJObject()
  var body_402656952 = newJObject()
  add(query_402656951, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656952 = body
  add(query_402656951, "NextToken", newJString(NextToken))
  result = call_402656950.call(nil, query_402656951, nil, nil, body_402656952)

var getInsights* = Call_GetInsights_402656936(name: "getInsights",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights/get", validator: validate_GetInsights_402656937,
    base: "/", makeUrl: url_GetInsights_402656938,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_402656953 = ref object of OpenApiRestCall_402656044
proc url_GetInvitationsCount_402656955(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInvitationsCount_402656954(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656956 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-Security-Token", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-Signature")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Signature", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Algorithm", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Date")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Date", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-Credential")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Credential", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656963: Call_GetInvitationsCount_402656953;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
                                                                                         ## 
  let valid = call_402656963.validator(path, query, header, formData, body, _)
  let scheme = call_402656963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656963.makeUrl(scheme.get, call_402656963.host, call_402656963.base,
                                   call_402656963.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656963, uri, valid, _)

proc call*(call_402656964: Call_GetInvitationsCount_402656953): Recallable =
  ## getInvitationsCount
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  result = call_402656964.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_402656953(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/invitations/count",
    validator: validate_GetInvitationsCount_402656954, base: "/",
    makeUrl: url_GetInvitationsCount_402656955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_402656965 = ref object of OpenApiRestCall_402656044
proc url_GetMembers_402656967(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMembers_402656966(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656968 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656968 = validateParameter(valid_402656968, JString,
                                      required = false, default = nil)
  if valid_402656968 != nil:
    section.add "X-Amz-Security-Token", valid_402656968
  var valid_402656969 = header.getOrDefault("X-Amz-Signature")
  valid_402656969 = validateParameter(valid_402656969, JString,
                                      required = false, default = nil)
  if valid_402656969 != nil:
    section.add "X-Amz-Signature", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656970
  var valid_402656971 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "X-Amz-Algorithm", valid_402656971
  var valid_402656972 = header.getOrDefault("X-Amz-Date")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-Date", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Credential")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Credential", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656974
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

proc call*(call_402656976: Call_GetMembers_402656965; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the details for the Security Hub member accounts for the specified account IDs.
                                                                                         ## 
  let valid = call_402656976.validator(path, query, header, formData, body, _)
  let scheme = call_402656976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656976.makeUrl(scheme.get, call_402656976.host, call_402656976.base,
                                   call_402656976.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656976, uri, valid, _)

proc call*(call_402656977: Call_GetMembers_402656965; body: JsonNode): Recallable =
  ## getMembers
  ## Returns the details for the Security Hub member accounts for the specified account IDs.
  ##   
                                                                                            ## body: JObject (required)
  var body_402656978 = newJObject()
  if body != nil:
    body_402656978 = body
  result = call_402656977.call(nil, nil, nil, nil, body_402656978)

var getMembers* = Call_GetMembers_402656965(name: "getMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/get", validator: validate_GetMembers_402656966, base: "/",
    makeUrl: url_GetMembers_402656967, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_402656979 = ref object of OpenApiRestCall_402656044
proc url_InviteMembers_402656981(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InviteMembers_402656980(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <code> <a>CreateMembers</a> </code> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656982 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-Security-Token", valid_402656982
  var valid_402656983 = header.getOrDefault("X-Amz-Signature")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-Signature", valid_402656983
  var valid_402656984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656984 = validateParameter(valid_402656984, JString,
                                      required = false, default = nil)
  if valid_402656984 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656984
  var valid_402656985 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-Algorithm", valid_402656985
  var valid_402656986 = header.getOrDefault("X-Amz-Date")
  valid_402656986 = validateParameter(valid_402656986, JString,
                                      required = false, default = nil)
  if valid_402656986 != nil:
    section.add "X-Amz-Date", valid_402656986
  var valid_402656987 = header.getOrDefault("X-Amz-Credential")
  valid_402656987 = validateParameter(valid_402656987, JString,
                                      required = false, default = nil)
  if valid_402656987 != nil:
    section.add "X-Amz-Credential", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656988
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

proc call*(call_402656990: Call_InviteMembers_402656979; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <code> <a>CreateMembers</a> </code> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
                                                                                         ## 
  let valid = call_402656990.validator(path, query, header, formData, body, _)
  let scheme = call_402656990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656990.makeUrl(scheme.get, call_402656990.host, call_402656990.base,
                                   call_402656990.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656990, uri, valid, _)

proc call*(call_402656991: Call_InviteMembers_402656979; body: JsonNode): Recallable =
  ## inviteMembers
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <code> <a>CreateMembers</a> </code> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656992 = newJObject()
  if body != nil:
    body_402656992 = body
  result = call_402656991.call(nil, nil, nil, nil, body_402656992)

var inviteMembers* = Call_InviteMembers_402656979(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/invite", validator: validate_InviteMembers_402656980,
    base: "/", makeUrl: url_InviteMembers_402656981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_402656993 = ref object of OpenApiRestCall_402656044
proc url_ListInvitations_402656995(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_402656994(path: JsonNode; query: JsonNode;
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
  ##   MaxResults: JInt
                                  ##             : The maximum number of items to return in the response. 
  ##   
                                                                                                          ## NextToken: JString
                                                                                                          ##            
                                                                                                          ## : 
                                                                                                          ## <p>The 
                                                                                                          ## token 
                                                                                                          ## that 
                                                                                                          ## is 
                                                                                                          ## required 
                                                                                                          ## for 
                                                                                                          ## pagination. 
                                                                                                          ## On 
                                                                                                          ## your 
                                                                                                          ## first 
                                                                                                          ## call 
                                                                                                          ## to 
                                                                                                          ## the 
                                                                                                          ## <code>ListInvitations</code> 
                                                                                                          ## operation, 
                                                                                                          ## set 
                                                                                                          ## the 
                                                                                                          ## value 
                                                                                                          ## of 
                                                                                                          ## this 
                                                                                                          ## parameter 
                                                                                                          ## to 
                                                                                                          ## <code>NULL</code>.</p> 
                                                                                                          ## <p>For 
                                                                                                          ## subsequent 
                                                                                                          ## calls 
                                                                                                          ## to 
                                                                                                          ## the 
                                                                                                          ## operation, 
                                                                                                          ## to 
                                                                                                          ## continue 
                                                                                                          ## listing 
                                                                                                          ## data, 
                                                                                                          ## set 
                                                                                                          ## the 
                                                                                                          ## value 
                                                                                                          ## of 
                                                                                                          ## this 
                                                                                                          ## parameter 
                                                                                                          ## to 
                                                                                                          ## the 
                                                                                                          ## value 
                                                                                                          ## returned 
                                                                                                          ## from 
                                                                                                          ## the 
                                                                                                          ## previous 
                                                                                                          ## response.</p>
  section = newJObject()
  var valid_402656996 = query.getOrDefault("MaxResults")
  valid_402656996 = validateParameter(valid_402656996, JInt, required = false,
                                      default = nil)
  if valid_402656996 != nil:
    section.add "MaxResults", valid_402656996
  var valid_402656997 = query.getOrDefault("NextToken")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "NextToken", valid_402656997
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656998 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Security-Token", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-Signature")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Signature", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657000
  var valid_402657001 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657001 = validateParameter(valid_402657001, JString,
                                      required = false, default = nil)
  if valid_402657001 != nil:
    section.add "X-Amz-Algorithm", valid_402657001
  var valid_402657002 = header.getOrDefault("X-Amz-Date")
  valid_402657002 = validateParameter(valid_402657002, JString,
                                      required = false, default = nil)
  if valid_402657002 != nil:
    section.add "X-Amz-Date", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-Credential")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Credential", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657005: Call_ListInvitations_402656993; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
                                                                                         ## 
  let valid = call_402657005.validator(path, query, header, formData, body, _)
  let scheme = call_402657005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657005.makeUrl(scheme.get, call_402657005.host, call_402657005.base,
                                   call_402657005.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657005, uri, valid, _)

proc call*(call_402657006: Call_ListInvitations_402656993; MaxResults: int = 0;
           NextToken: string = ""): Recallable =
  ## listInvitations
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ##   
                                                                                              ## MaxResults: int
                                                                                              ##             
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## maximum 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## items 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## in 
                                                                                              ## the 
                                                                                              ## response. 
  ##   
                                                                                                           ## NextToken: string
                                                                                                           ##            
                                                                                                           ## : 
                                                                                                           ## <p>The 
                                                                                                           ## token 
                                                                                                           ## that 
                                                                                                           ## is 
                                                                                                           ## required 
                                                                                                           ## for 
                                                                                                           ## pagination. 
                                                                                                           ## On 
                                                                                                           ## your 
                                                                                                           ## first 
                                                                                                           ## call 
                                                                                                           ## to 
                                                                                                           ## the 
                                                                                                           ## <code>ListInvitations</code> 
                                                                                                           ## operation, 
                                                                                                           ## set 
                                                                                                           ## the 
                                                                                                           ## value 
                                                                                                           ## of 
                                                                                                           ## this 
                                                                                                           ## parameter 
                                                                                                           ## to 
                                                                                                           ## <code>NULL</code>.</p> 
                                                                                                           ## <p>For 
                                                                                                           ## subsequent 
                                                                                                           ## calls 
                                                                                                           ## to 
                                                                                                           ## the 
                                                                                                           ## operation, 
                                                                                                           ## to 
                                                                                                           ## continue 
                                                                                                           ## listing 
                                                                                                           ## data, 
                                                                                                           ## set 
                                                                                                           ## the 
                                                                                                           ## value 
                                                                                                           ## of 
                                                                                                           ## this 
                                                                                                           ## parameter 
                                                                                                           ## to 
                                                                                                           ## the 
                                                                                                           ## value 
                                                                                                           ## returned 
                                                                                                           ## from 
                                                                                                           ## the 
                                                                                                           ## previous 
                                                                                                           ## response.</p>
  var query_402657007 = newJObject()
  add(query_402657007, "MaxResults", newJInt(MaxResults))
  add(query_402657007, "NextToken", newJString(NextToken))
  result = call_402657006.call(nil, query_402657007, nil, nil, nil)

var listInvitations* = Call_ListInvitations_402656993(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_402656994,
    base: "/", makeUrl: url_ListInvitations_402656995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657022 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657024(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_402657023(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657025 = path.getOrDefault("ResourceArn")
  valid_402657025 = validateParameter(valid_402657025, JString, required = true,
                                      default = nil)
  if valid_402657025 != nil:
    section.add "ResourceArn", valid_402657025
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657026 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-Security-Token", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-Signature")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Signature", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Algorithm", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Date")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Date", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-Credential")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-Credential", valid_402657031
  var valid_402657032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657032 = validateParameter(valid_402657032, JString,
                                      required = false, default = nil)
  if valid_402657032 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657032
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

proc call*(call_402657034: Call_TagResource_402657022; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds one or more tags to a resource.
                                                                                         ## 
  let valid = call_402657034.validator(path, query, header, formData, body, _)
  let scheme = call_402657034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657034.makeUrl(scheme.get, call_402657034.host, call_402657034.base,
                                   call_402657034.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657034, uri, valid, _)

proc call*(call_402657035: Call_TagResource_402657022; body: JsonNode;
           ResourceArn: string): Recallable =
  ## tagResource
  ## Adds one or more tags to a resource.
  ##   body: JObject (required)
  ##   ResourceArn: string (required)
                               ##              : The ARN of the resource to apply the tags to.
  var path_402657036 = newJObject()
  var body_402657037 = newJObject()
  if body != nil:
    body_402657037 = body
  add(path_402657036, "ResourceArn", newJString(ResourceArn))
  result = call_402657035.call(path_402657036, nil, nil, nil, body_402657037)

var tagResource* = Call_TagResource_402657022(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}", validator: validate_TagResource_402657023,
    base: "/", makeUrl: url_TagResource_402657024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402657008 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402657010(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListTagsForResource_402657009(path: JsonNode; query: JsonNode;
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
  var valid_402657011 = path.getOrDefault("ResourceArn")
  valid_402657011 = validateParameter(valid_402657011, JString, required = true,
                                      default = nil)
  if valid_402657011 != nil:
    section.add "ResourceArn", valid_402657011
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657012 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Security-Token", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Signature")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Signature", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-Algorithm", valid_402657015
  var valid_402657016 = header.getOrDefault("X-Amz-Date")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-Date", valid_402657016
  var valid_402657017 = header.getOrDefault("X-Amz-Credential")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "X-Amz-Credential", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657019: Call_ListTagsForResource_402657008;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of tags associated with a resource.
                                                                                         ## 
  let valid = call_402657019.validator(path, query, header, formData, body, _)
  let scheme = call_402657019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657019.makeUrl(scheme.get, call_402657019.host, call_402657019.base,
                                   call_402657019.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657019, uri, valid, _)

proc call*(call_402657020: Call_ListTagsForResource_402657008;
           ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with a resource.
  ##   ResourceArn: string (required)
                                                       ##              : The ARN of the resource to retrieve tags for.
  var path_402657021 = newJObject()
  add(path_402657021, "ResourceArn", newJString(ResourceArn))
  result = call_402657020.call(path_402657021, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402657008(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_402657009, base: "/",
    makeUrl: url_ListTagsForResource_402657010,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657038 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657040(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_402657039(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657041 = path.getOrDefault("ResourceArn")
  valid_402657041 = validateParameter(valid_402657041, JString, required = true,
                                      default = nil)
  if valid_402657041 != nil:
    section.add "ResourceArn", valid_402657041
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The tag keys associated with the tags to remove from the resource.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402657042 = query.getOrDefault("tagKeys")
  valid_402657042 = validateParameter(valid_402657042, JArray, required = true,
                                      default = nil)
  if valid_402657042 != nil:
    section.add "tagKeys", valid_402657042
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657043 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Security-Token", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Signature")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Signature", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-Algorithm", valid_402657046
  var valid_402657047 = header.getOrDefault("X-Amz-Date")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-Date", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Credential")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Credential", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657050: Call_UntagResource_402657038; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags from a resource.
                                                                                         ## 
  let valid = call_402657050.validator(path, query, header, formData, body, _)
  let scheme = call_402657050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657050.makeUrl(scheme.get, call_402657050.host, call_402657050.base,
                                   call_402657050.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657050, uri, valid, _)

proc call*(call_402657051: Call_UntagResource_402657038; tagKeys: JsonNode;
           ResourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags from a resource.
  ##   tagKeys: JArray (required)
                                              ##          : The tag keys associated with the tags to remove from the resource.
  ##   
                                                                                                                              ## ResourceArn: string (required)
                                                                                                                              ##              
                                                                                                                              ## : 
                                                                                                                              ## The 
                                                                                                                              ## ARN 
                                                                                                                              ## of 
                                                                                                                              ## the 
                                                                                                                              ## resource 
                                                                                                                              ## to 
                                                                                                                              ## remove 
                                                                                                                              ## the 
                                                                                                                              ## tags 
                                                                                                                              ## from.
  var path_402657052 = newJObject()
  var query_402657053 = newJObject()
  if tagKeys != nil:
    query_402657053.add "tagKeys", tagKeys
  add(path_402657052, "ResourceArn", newJString(ResourceArn))
  result = call_402657051.call(path_402657052, query_402657053, nil, nil, nil)

var untagResource* = Call_UntagResource_402657038(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_402657039,
    base: "/", makeUrl: url_UntagResource_402657040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStandardsControl_402657054 = ref object of OpenApiRestCall_402656044
proc url_UpdateStandardsControl_402657056(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateStandardsControl_402657055(path: JsonNode; query: JsonNode;
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
  var valid_402657057 = path.getOrDefault("StandardsControlArn")
  valid_402657057 = validateParameter(valid_402657057, JString, required = true,
                                      default = nil)
  if valid_402657057 != nil:
    section.add "StandardsControlArn", valid_402657057
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657058 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-Security-Token", valid_402657058
  var valid_402657059 = header.getOrDefault("X-Amz-Signature")
  valid_402657059 = validateParameter(valid_402657059, JString,
                                      required = false, default = nil)
  if valid_402657059 != nil:
    section.add "X-Amz-Signature", valid_402657059
  var valid_402657060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657060
  var valid_402657061 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amz-Algorithm", valid_402657061
  var valid_402657062 = header.getOrDefault("X-Amz-Date")
  valid_402657062 = validateParameter(valid_402657062, JString,
                                      required = false, default = nil)
  if valid_402657062 != nil:
    section.add "X-Amz-Date", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-Credential")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Credential", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657064
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

proc call*(call_402657066: Call_UpdateStandardsControl_402657054;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to control whether an individual security standard control is enabled or disabled.
                                                                                         ## 
  let valid = call_402657066.validator(path, query, header, formData, body, _)
  let scheme = call_402657066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657066.makeUrl(scheme.get, call_402657066.host, call_402657066.base,
                                   call_402657066.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657066, uri, valid, _)

proc call*(call_402657067: Call_UpdateStandardsControl_402657054;
           StandardsControlArn: string; body: JsonNode): Recallable =
  ## updateStandardsControl
  ## Used to control whether an individual security standard control is enabled or disabled.
  ##   
                                                                                            ## StandardsControlArn: string (required)
                                                                                            ##                      
                                                                                            ## : 
                                                                                            ## The 
                                                                                            ## ARN 
                                                                                            ## of 
                                                                                            ## the 
                                                                                            ## security 
                                                                                            ## standard 
                                                                                            ## control 
                                                                                            ## to 
                                                                                            ## enable 
                                                                                            ## or 
                                                                                            ## disable.
  ##   
                                                                                                       ## body: JObject (required)
  var path_402657068 = newJObject()
  var body_402657069 = newJObject()
  add(path_402657068, "StandardsControlArn", newJString(StandardsControlArn))
  if body != nil:
    body_402657069 = body
  result = call_402657067.call(path_402657068, nil, nil, nil, body_402657069)

var updateStandardsControl* = Call_UpdateStandardsControl_402657054(
    name: "updateStandardsControl", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com",
    route: "/standards/control/{StandardsControlArn}",
    validator: validate_UpdateStandardsControl_402657055, base: "/",
    makeUrl: url_UpdateStandardsControl_402657056,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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