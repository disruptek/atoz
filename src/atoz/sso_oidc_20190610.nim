
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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

  OpenApiRestCall_402656029 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656029](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656029): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "oidc.ap-northeast-1.amazonaws.com", "ap-southeast-1": "oidc.ap-southeast-1.amazonaws.com",
                               "us-west-2": "oidc.us-west-2.amazonaws.com",
                               "eu-west-2": "oidc.eu-west-2.amazonaws.com", "ap-northeast-3": "oidc.ap-northeast-3.amazonaws.com", "eu-central-1": "oidc.eu-central-1.amazonaws.com",
                               "us-east-2": "oidc.us-east-2.amazonaws.com",
                               "us-east-1": "oidc.us-east-1.amazonaws.com", "cn-northwest-1": "oidc.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "oidc.ap-south-1.amazonaws.com",
                               "eu-north-1": "oidc.eu-north-1.amazonaws.com", "ap-northeast-2": "oidc.ap-northeast-2.amazonaws.com",
                               "us-west-1": "oidc.us-west-1.amazonaws.com", "us-gov-east-1": "oidc.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "oidc.eu-west-3.amazonaws.com", "cn-north-1": "oidc.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "oidc.sa-east-1.amazonaws.com",
                               "eu-west-1": "oidc.eu-west-1.amazonaws.com", "us-gov-west-1": "oidc.us-gov-west-1.amazonaws.com", "ap-southeast-2": "oidc.ap-southeast-2.amazonaws.com", "ca-central-1": "oidc.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateToken_402656279 = ref object of OpenApiRestCall_402656029
proc url_CreateToken_402656281(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateToken_402656280(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656363 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656363 = validateParameter(valid_402656363, JString,
                                      required = false, default = nil)
  if valid_402656363 != nil:
    section.add "X-Amz-Security-Token", valid_402656363
  var valid_402656364 = header.getOrDefault("X-Amz-Signature")
  valid_402656364 = validateParameter(valid_402656364, JString,
                                      required = false, default = nil)
  if valid_402656364 != nil:
    section.add "X-Amz-Signature", valid_402656364
  var valid_402656365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656365 = validateParameter(valid_402656365, JString,
                                      required = false, default = nil)
  if valid_402656365 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656365
  var valid_402656366 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656366 = validateParameter(valid_402656366, JString,
                                      required = false, default = nil)
  if valid_402656366 != nil:
    section.add "X-Amz-Algorithm", valid_402656366
  var valid_402656367 = header.getOrDefault("X-Amz-Date")
  valid_402656367 = validateParameter(valid_402656367, JString,
                                      required = false, default = nil)
  if valid_402656367 != nil:
    section.add "X-Amz-Date", valid_402656367
  var valid_402656368 = header.getOrDefault("X-Amz-Credential")
  valid_402656368 = validateParameter(valid_402656368, JString,
                                      required = false, default = nil)
  if valid_402656368 != nil:
    section.add "X-Amz-Credential", valid_402656368
  var valid_402656369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656369 = validateParameter(valid_402656369, JString,
                                      required = false, default = nil)
  if valid_402656369 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656369
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

proc call*(call_402656384: Call_CreateToken_402656279; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates and returns an access token for the authorized client. The access token issued will be used to fetch short-term credentials for the assigned roles in the AWS account.
                                                                                         ## 
  let valid = call_402656384.validator(path, query, header, formData, body, _)
  let scheme = call_402656384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656384.makeUrl(scheme.get, call_402656384.host, call_402656384.base,
                                   call_402656384.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656384, uri, valid, _)

proc call*(call_402656433: Call_CreateToken_402656279; body: JsonNode): Recallable =
  ## createToken
  ## Creates and returns an access token for the authorized client. The access token issued will be used to fetch short-term credentials for the assigned roles in the AWS account.
  ##   
                                                                                                                                                                                   ## body: JObject (required)
  var body_402656434 = newJObject()
  if body != nil:
    body_402656434 = body
  result = call_402656433.call(nil, nil, nil, nil, body_402656434)

var createToken* = Call_CreateToken_402656279(name: "createToken",
    meth: HttpMethod.HttpPost, host: "oidc.amazonaws.com", route: "/token",
    validator: validate_CreateToken_402656280, base: "/",
    makeUrl: url_CreateToken_402656281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterClient_402656461 = ref object of OpenApiRestCall_402656029
proc url_RegisterClient_402656463(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterClient_402656462(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656464 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656464 = validateParameter(valid_402656464, JString,
                                      required = false, default = nil)
  if valid_402656464 != nil:
    section.add "X-Amz-Security-Token", valid_402656464
  var valid_402656465 = header.getOrDefault("X-Amz-Signature")
  valid_402656465 = validateParameter(valid_402656465, JString,
                                      required = false, default = nil)
  if valid_402656465 != nil:
    section.add "X-Amz-Signature", valid_402656465
  var valid_402656466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656466 = validateParameter(valid_402656466, JString,
                                      required = false, default = nil)
  if valid_402656466 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656466
  var valid_402656467 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656467 = validateParameter(valid_402656467, JString,
                                      required = false, default = nil)
  if valid_402656467 != nil:
    section.add "X-Amz-Algorithm", valid_402656467
  var valid_402656468 = header.getOrDefault("X-Amz-Date")
  valid_402656468 = validateParameter(valid_402656468, JString,
                                      required = false, default = nil)
  if valid_402656468 != nil:
    section.add "X-Amz-Date", valid_402656468
  var valid_402656469 = header.getOrDefault("X-Amz-Credential")
  valid_402656469 = validateParameter(valid_402656469, JString,
                                      required = false, default = nil)
  if valid_402656469 != nil:
    section.add "X-Amz-Credential", valid_402656469
  var valid_402656470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656470 = validateParameter(valid_402656470, JString,
                                      required = false, default = nil)
  if valid_402656470 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656470
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

proc call*(call_402656472: Call_RegisterClient_402656461; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers a client with AWS SSO. This allows clients to initiate device authorization. The output should be persisted for reuse through many authentication requests.
                                                                                         ## 
  let valid = call_402656472.validator(path, query, header, formData, body, _)
  let scheme = call_402656472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656472.makeUrl(scheme.get, call_402656472.host, call_402656472.base,
                                   call_402656472.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656472, uri, valid, _)

proc call*(call_402656473: Call_RegisterClient_402656461; body: JsonNode): Recallable =
  ## registerClient
  ## Registers a client with AWS SSO. This allows clients to initiate device authorization. The output should be persisted for reuse through many authentication requests.
  ##   
                                                                                                                                                                          ## body: JObject (required)
  var body_402656474 = newJObject()
  if body != nil:
    body_402656474 = body
  result = call_402656473.call(nil, nil, nil, nil, body_402656474)

var registerClient* = Call_RegisterClient_402656461(name: "registerClient",
    meth: HttpMethod.HttpPost, host: "oidc.amazonaws.com",
    route: "/client/register", validator: validate_RegisterClient_402656462,
    base: "/", makeUrl: url_RegisterClient_402656463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeviceAuthorization_402656475 = ref object of OpenApiRestCall_402656029
proc url_StartDeviceAuthorization_402656477(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDeviceAuthorization_402656476(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Initiates device authorization by requesting a pair of verification codes from the authorization service.
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
  var valid_402656478 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Security-Token", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-Signature")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Signature", valid_402656479
  var valid_402656480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Algorithm", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Date")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Date", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Credential")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Credential", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656484
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

proc call*(call_402656486: Call_StartDeviceAuthorization_402656475;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Initiates device authorization by requesting a pair of verification codes from the authorization service.
                                                                                         ## 
  let valid = call_402656486.validator(path, query, header, formData, body, _)
  let scheme = call_402656486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656486.makeUrl(scheme.get, call_402656486.host, call_402656486.base,
                                   call_402656486.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656486, uri, valid, _)

proc call*(call_402656487: Call_StartDeviceAuthorization_402656475;
           body: JsonNode): Recallable =
  ## startDeviceAuthorization
  ## Initiates device authorization by requesting a pair of verification codes from the authorization service.
  ##   
                                                                                                              ## body: JObject (required)
  var body_402656488 = newJObject()
  if body != nil:
    body_402656488 = body
  result = call_402656487.call(nil, nil, nil, nil, body_402656488)

var startDeviceAuthorization* = Call_StartDeviceAuthorization_402656475(
    name: "startDeviceAuthorization", meth: HttpMethod.HttpPost,
    host: "oidc.amazonaws.com", route: "/device_authorization",
    validator: validate_StartDeviceAuthorization_402656476, base: "/",
    makeUrl: url_StartDeviceAuthorization_402656477,
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