
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS SSO OIDC
## version: 2019-06-10
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS Single Sign-On (SSO) OpenID Connect (OIDC) is a web service that enables a client (such as AWS CLI or a native application) to register with AWS SSO. The service also enables the client to fetch the user’s access token upon successful authentication and authorization with AWS SSO. This service conforms with the OAuth 2.0 based implementation of the device authorization grant standard (<a href="https://tools.ietf.org/html/rfc8628">https://tools.ietf.org/html/rfc8628</a>).</p> <p>For general information about AWS SSO, see <a href="https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html">What is AWS Single Sign-On?</a> in the <i>AWS SSO User Guide</i>.</p> <p>This API reference guide describes the AWS SSO OIDC operations that you can call programatically and includes detailed information on data types and errors.</p> <note> <p>AWS provides SDKs that consist of libraries and sample code for various programming languages and platforms such as Java, Ruby, .Net, iOS, and Android. The SDKs provide a convenient way to create programmatic access to AWS SSO and other AWS services. For more information about the AWS SDKs, including how to download and install them, see <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>.</p> </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/oidc/
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

  OpenApiRestCall_21625409 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625409](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625409): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "oidc.ap-northeast-1.amazonaws.com", "ap-southeast-1": "oidc.ap-southeast-1.amazonaws.com",
                           "us-west-2": "oidc.us-west-2.amazonaws.com",
                           "eu-west-2": "oidc.eu-west-2.amazonaws.com", "ap-northeast-3": "oidc.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "oidc.eu-central-1.amazonaws.com",
                           "us-east-2": "oidc.us-east-2.amazonaws.com",
                           "us-east-1": "oidc.us-east-1.amazonaws.com", "cn-northwest-1": "oidc.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "oidc.ap-south-1.amazonaws.com",
                           "eu-north-1": "oidc.eu-north-1.amazonaws.com", "ap-northeast-2": "oidc.ap-northeast-2.amazonaws.com",
                           "us-west-1": "oidc.us-west-1.amazonaws.com",
                           "us-gov-east-1": "oidc.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "oidc.eu-west-3.amazonaws.com",
                           "cn-north-1": "oidc.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "oidc.sa-east-1.amazonaws.com",
                           "eu-west-1": "oidc.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "oidc.us-gov-west-1.amazonaws.com", "ap-southeast-2": "oidc.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "oidc.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "oidc.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "oidc.ap-southeast-1.amazonaws.com",
      "us-west-2": "oidc.us-west-2.amazonaws.com",
      "eu-west-2": "oidc.eu-west-2.amazonaws.com",
      "ap-northeast-3": "oidc.ap-northeast-3.amazonaws.com",
      "eu-central-1": "oidc.eu-central-1.amazonaws.com",
      "us-east-2": "oidc.us-east-2.amazonaws.com",
      "us-east-1": "oidc.us-east-1.amazonaws.com",
      "cn-northwest-1": "oidc.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "oidc.ap-south-1.amazonaws.com",
      "eu-north-1": "oidc.eu-north-1.amazonaws.com",
      "ap-northeast-2": "oidc.ap-northeast-2.amazonaws.com",
      "us-west-1": "oidc.us-west-1.amazonaws.com",
      "us-gov-east-1": "oidc.us-gov-east-1.amazonaws.com",
      "eu-west-3": "oidc.eu-west-3.amazonaws.com",
      "cn-north-1": "oidc.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "oidc.sa-east-1.amazonaws.com",
      "eu-west-1": "oidc.eu-west-1.amazonaws.com",
      "us-gov-west-1": "oidc.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "oidc.ap-southeast-2.amazonaws.com",
      "ca-central-1": "oidc.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sso-oidc"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateToken_21625753 = ref object of OpenApiRestCall_21625409
proc url_CreateToken_21625755(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateToken_21625754(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates and returns an access token for the authorized client. The access token issued will be used to fetch short-term credentials for the assigned roles in the AWS account.
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
  var valid_21625856 = header.getOrDefault("X-Amz-Date")
  valid_21625856 = validateParameter(valid_21625856, JString, required = false,
                                   default = nil)
  if valid_21625856 != nil:
    section.add "X-Amz-Date", valid_21625856
  var valid_21625857 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625857 = validateParameter(valid_21625857, JString, required = false,
                                   default = nil)
  if valid_21625857 != nil:
    section.add "X-Amz-Security-Token", valid_21625857
  var valid_21625858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625858 = validateParameter(valid_21625858, JString, required = false,
                                   default = nil)
  if valid_21625858 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625858
  var valid_21625859 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625859 = validateParameter(valid_21625859, JString, required = false,
                                   default = nil)
  if valid_21625859 != nil:
    section.add "X-Amz-Algorithm", valid_21625859
  var valid_21625860 = header.getOrDefault("X-Amz-Signature")
  valid_21625860 = validateParameter(valid_21625860, JString, required = false,
                                   default = nil)
  if valid_21625860 != nil:
    section.add "X-Amz-Signature", valid_21625860
  var valid_21625861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625861 = validateParameter(valid_21625861, JString, required = false,
                                   default = nil)
  if valid_21625861 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625861
  var valid_21625862 = header.getOrDefault("X-Amz-Credential")
  valid_21625862 = validateParameter(valid_21625862, JString, required = false,
                                   default = nil)
  if valid_21625862 != nil:
    section.add "X-Amz-Credential", valid_21625862
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

proc call*(call_21625888: Call_CreateToken_21625753; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates and returns an access token for the authorized client. The access token issued will be used to fetch short-term credentials for the assigned roles in the AWS account.
  ## 
  let valid = call_21625888.validator(path, query, header, formData, body, _)
  let scheme = call_21625888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625888.makeUrl(scheme.get, call_21625888.host, call_21625888.base,
                               call_21625888.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625888, uri, valid, _)

proc call*(call_21625951: Call_CreateToken_21625753; body: JsonNode): Recallable =
  ## createToken
  ## Creates and returns an access token for the authorized client. The access token issued will be used to fetch short-term credentials for the assigned roles in the AWS account.
  ##   body: JObject (required)
  var body_21625952 = newJObject()
  if body != nil:
    body_21625952 = body
  result = call_21625951.call(nil, nil, nil, nil, body_21625952)

var createToken* = Call_CreateToken_21625753(name: "createToken",
    meth: HttpMethod.HttpPost, host: "oidc.amazonaws.com", route: "/token",
    validator: validate_CreateToken_21625754, base: "/", makeUrl: url_CreateToken_21625755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterClient_21625988 = ref object of OpenApiRestCall_21625409
proc url_RegisterClient_21625990(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterClient_21625989(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Registers a client with AWS SSO. This allows clients to initiate device authorization. The output should be persisted for reuse through many authentication requests.
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
  var valid_21625991 = header.getOrDefault("X-Amz-Date")
  valid_21625991 = validateParameter(valid_21625991, JString, required = false,
                                   default = nil)
  if valid_21625991 != nil:
    section.add "X-Amz-Date", valid_21625991
  var valid_21625992 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625992 = validateParameter(valid_21625992, JString, required = false,
                                   default = nil)
  if valid_21625992 != nil:
    section.add "X-Amz-Security-Token", valid_21625992
  var valid_21625993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625993 = validateParameter(valid_21625993, JString, required = false,
                                   default = nil)
  if valid_21625993 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625993
  var valid_21625994 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625994 = validateParameter(valid_21625994, JString, required = false,
                                   default = nil)
  if valid_21625994 != nil:
    section.add "X-Amz-Algorithm", valid_21625994
  var valid_21625995 = header.getOrDefault("X-Amz-Signature")
  valid_21625995 = validateParameter(valid_21625995, JString, required = false,
                                   default = nil)
  if valid_21625995 != nil:
    section.add "X-Amz-Signature", valid_21625995
  var valid_21625996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625996 = validateParameter(valid_21625996, JString, required = false,
                                   default = nil)
  if valid_21625996 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625996
  var valid_21625997 = header.getOrDefault("X-Amz-Credential")
  valid_21625997 = validateParameter(valid_21625997, JString, required = false,
                                   default = nil)
  if valid_21625997 != nil:
    section.add "X-Amz-Credential", valid_21625997
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

proc call*(call_21625999: Call_RegisterClient_21625988; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers a client with AWS SSO. This allows clients to initiate device authorization. The output should be persisted for reuse through many authentication requests.
  ## 
  let valid = call_21625999.validator(path, query, header, formData, body, _)
  let scheme = call_21625999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625999.makeUrl(scheme.get, call_21625999.host, call_21625999.base,
                               call_21625999.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625999, uri, valid, _)

proc call*(call_21626000: Call_RegisterClient_21625988; body: JsonNode): Recallable =
  ## registerClient
  ## Registers a client with AWS SSO. This allows clients to initiate device authorization. The output should be persisted for reuse through many authentication requests.
  ##   body: JObject (required)
  var body_21626001 = newJObject()
  if body != nil:
    body_21626001 = body
  result = call_21626000.call(nil, nil, nil, nil, body_21626001)

var registerClient* = Call_RegisterClient_21625988(name: "registerClient",
    meth: HttpMethod.HttpPost, host: "oidc.amazonaws.com",
    route: "/client/register", validator: validate_RegisterClient_21625989,
    base: "/", makeUrl: url_RegisterClient_21625990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeviceAuthorization_21626002 = ref object of OpenApiRestCall_21625409
proc url_StartDeviceAuthorization_21626004(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDeviceAuthorization_21626003(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Initiates device authorization by requesting a pair of verification codes from the authorization service.
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
  var valid_21626005 = header.getOrDefault("X-Amz-Date")
  valid_21626005 = validateParameter(valid_21626005, JString, required = false,
                                   default = nil)
  if valid_21626005 != nil:
    section.add "X-Amz-Date", valid_21626005
  var valid_21626006 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626006 = validateParameter(valid_21626006, JString, required = false,
                                   default = nil)
  if valid_21626006 != nil:
    section.add "X-Amz-Security-Token", valid_21626006
  var valid_21626007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626007 = validateParameter(valid_21626007, JString, required = false,
                                   default = nil)
  if valid_21626007 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626007
  var valid_21626008 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626008 = validateParameter(valid_21626008, JString, required = false,
                                   default = nil)
  if valid_21626008 != nil:
    section.add "X-Amz-Algorithm", valid_21626008
  var valid_21626009 = header.getOrDefault("X-Amz-Signature")
  valid_21626009 = validateParameter(valid_21626009, JString, required = false,
                                   default = nil)
  if valid_21626009 != nil:
    section.add "X-Amz-Signature", valid_21626009
  var valid_21626010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626010 = validateParameter(valid_21626010, JString, required = false,
                                   default = nil)
  if valid_21626010 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626010
  var valid_21626011 = header.getOrDefault("X-Amz-Credential")
  valid_21626011 = validateParameter(valid_21626011, JString, required = false,
                                   default = nil)
  if valid_21626011 != nil:
    section.add "X-Amz-Credential", valid_21626011
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

proc call*(call_21626013: Call_StartDeviceAuthorization_21626002;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Initiates device authorization by requesting a pair of verification codes from the authorization service.
  ## 
  let valid = call_21626013.validator(path, query, header, formData, body, _)
  let scheme = call_21626013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626013.makeUrl(scheme.get, call_21626013.host, call_21626013.base,
                               call_21626013.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626013, uri, valid, _)

proc call*(call_21626014: Call_StartDeviceAuthorization_21626002; body: JsonNode): Recallable =
  ## startDeviceAuthorization
  ## Initiates device authorization by requesting a pair of verification codes from the authorization service.
  ##   body: JObject (required)
  var body_21626015 = newJObject()
  if body != nil:
    body_21626015 = body
  result = call_21626014.call(nil, nil, nil, nil, body_21626015)

var startDeviceAuthorization* = Call_StartDeviceAuthorization_21626002(
    name: "startDeviceAuthorization", meth: HttpMethod.HttpPost,
    host: "oidc.amazonaws.com", route: "/device_authorization",
    validator: validate_StartDeviceAuthorization_21626003, base: "/",
    makeUrl: url_StartDeviceAuthorization_21626004,
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