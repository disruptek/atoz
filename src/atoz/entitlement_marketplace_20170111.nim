
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Marketplace Entitlement Service
## version: 2017-01-11
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Marketplace Entitlement Service</fullname> <p>This reference provides descriptions of the AWS Marketplace Entitlement Service API.</p> <p>AWS Marketplace Entitlement Service is used to determine the entitlement of a customer to a given product. An entitlement represents capacity in a product owned by the customer. For example, a customer might own some number of users or seats in an SaaS application or some amount of data capacity in a multi-tenant database.</p> <p> <b>Getting Entitlement Records</b> </p> <ul> <li> <p> <i>GetEntitlements</i>- Gets the entitlements for a Marketplace product.</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/marketplace/
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

  OpenApiRestCall_610649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610649): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "entitlement.marketplace.ap-northeast-1.amazonaws.com", "ap-southeast-1": "entitlement.marketplace.ap-southeast-1.amazonaws.com", "us-west-2": "entitlement.marketplace.us-west-2.amazonaws.com", "eu-west-2": "entitlement.marketplace.eu-west-2.amazonaws.com", "ap-northeast-3": "entitlement.marketplace.ap-northeast-3.amazonaws.com", "eu-central-1": "entitlement.marketplace.eu-central-1.amazonaws.com", "us-east-2": "entitlement.marketplace.us-east-2.amazonaws.com", "us-east-1": "entitlement.marketplace.us-east-1.amazonaws.com", "cn-northwest-1": "entitlement.marketplace.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "entitlement.marketplace.ap-south-1.amazonaws.com", "eu-north-1": "entitlement.marketplace.eu-north-1.amazonaws.com", "ap-northeast-2": "entitlement.marketplace.ap-northeast-2.amazonaws.com", "us-west-1": "entitlement.marketplace.us-west-1.amazonaws.com", "us-gov-east-1": "entitlement.marketplace.us-gov-east-1.amazonaws.com", "eu-west-3": "entitlement.marketplace.eu-west-3.amazonaws.com", "cn-north-1": "entitlement.marketplace.cn-north-1.amazonaws.com.cn", "sa-east-1": "entitlement.marketplace.sa-east-1.amazonaws.com", "eu-west-1": "entitlement.marketplace.eu-west-1.amazonaws.com", "us-gov-west-1": "entitlement.marketplace.us-gov-west-1.amazonaws.com", "ap-southeast-2": "entitlement.marketplace.ap-southeast-2.amazonaws.com", "ca-central-1": "entitlement.marketplace.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "entitlement.marketplace.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "entitlement.marketplace.ap-southeast-1.amazonaws.com",
      "us-west-2": "entitlement.marketplace.us-west-2.amazonaws.com",
      "eu-west-2": "entitlement.marketplace.eu-west-2.amazonaws.com",
      "ap-northeast-3": "entitlement.marketplace.ap-northeast-3.amazonaws.com",
      "eu-central-1": "entitlement.marketplace.eu-central-1.amazonaws.com",
      "us-east-2": "entitlement.marketplace.us-east-2.amazonaws.com",
      "us-east-1": "entitlement.marketplace.us-east-1.amazonaws.com", "cn-northwest-1": "entitlement.marketplace.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "entitlement.marketplace.ap-south-1.amazonaws.com",
      "eu-north-1": "entitlement.marketplace.eu-north-1.amazonaws.com",
      "ap-northeast-2": "entitlement.marketplace.ap-northeast-2.amazonaws.com",
      "us-west-1": "entitlement.marketplace.us-west-1.amazonaws.com",
      "us-gov-east-1": "entitlement.marketplace.us-gov-east-1.amazonaws.com",
      "eu-west-3": "entitlement.marketplace.eu-west-3.amazonaws.com",
      "cn-north-1": "entitlement.marketplace.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "entitlement.marketplace.sa-east-1.amazonaws.com",
      "eu-west-1": "entitlement.marketplace.eu-west-1.amazonaws.com",
      "us-gov-west-1": "entitlement.marketplace.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "entitlement.marketplace.ap-southeast-2.amazonaws.com",
      "ca-central-1": "entitlement.marketplace.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "entitlement.marketplace"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetEntitlements_610987 = ref object of OpenApiRestCall_610649
proc url_GetEntitlements_610989(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEntitlements_610988(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## GetEntitlements retrieves entitlement values for a given product. The results can be filtered based on customer identifier or product dimensions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611114 = header.getOrDefault("X-Amz-Target")
  valid_611114 = validateParameter(valid_611114, JString, required = true, default = newJString(
      "AWSMPEntitlementService.GetEntitlements"))
  if valid_611114 != nil:
    section.add "X-Amz-Target", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Signature")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Signature", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Content-Sha256", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Date")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Date", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-Credential")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-Credential", valid_611118
  var valid_611119 = header.getOrDefault("X-Amz-Security-Token")
  valid_611119 = validateParameter(valid_611119, JString, required = false,
                                 default = nil)
  if valid_611119 != nil:
    section.add "X-Amz-Security-Token", valid_611119
  var valid_611120 = header.getOrDefault("X-Amz-Algorithm")
  valid_611120 = validateParameter(valid_611120, JString, required = false,
                                 default = nil)
  if valid_611120 != nil:
    section.add "X-Amz-Algorithm", valid_611120
  var valid_611121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611121 = validateParameter(valid_611121, JString, required = false,
                                 default = nil)
  if valid_611121 != nil:
    section.add "X-Amz-SignedHeaders", valid_611121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611145: Call_GetEntitlements_610987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## GetEntitlements retrieves entitlement values for a given product. The results can be filtered based on customer identifier or product dimensions.
  ## 
  let valid = call_611145.validator(path, query, header, formData, body)
  let scheme = call_611145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611145.url(scheme.get, call_611145.host, call_611145.base,
                         call_611145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611145, url, valid)

proc call*(call_611216: Call_GetEntitlements_610987; body: JsonNode): Recallable =
  ## getEntitlements
  ## GetEntitlements retrieves entitlement values for a given product. The results can be filtered based on customer identifier or product dimensions.
  ##   body: JObject (required)
  var body_611217 = newJObject()
  if body != nil:
    body_611217 = body
  result = call_611216.call(nil, nil, nil, nil, body_611217)

var getEntitlements* = Call_GetEntitlements_610987(name: "getEntitlements",
    meth: HttpMethod.HttpPost, host: "entitlement.marketplace.amazonaws.com",
    route: "/#X-Amz-Target=AWSMPEntitlementService.GetEntitlements",
    validator: validate_GetEntitlements_610988, base: "/", url: url_GetEntitlements_610989,
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
