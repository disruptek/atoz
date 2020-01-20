
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605564 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605564](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605564): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateToken_605902 = ref object of OpenApiRestCall_605564
proc url_CreateToken_605904(protocol: Scheme; host: string; base: string;
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

proc validate_CreateToken_605903(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates and returns an access token for the authorized client. The access token issued will be used to fetch short-term credentials for the assigned roles in the AWS account.
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
  var valid_606016 = header.getOrDefault("X-Amz-Signature")
  valid_606016 = validateParameter(valid_606016, JString, required = false,
                                 default = nil)
  if valid_606016 != nil:
    section.add "X-Amz-Signature", valid_606016
  var valid_606017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606017 = validateParameter(valid_606017, JString, required = false,
                                 default = nil)
  if valid_606017 != nil:
    section.add "X-Amz-Content-Sha256", valid_606017
  var valid_606018 = header.getOrDefault("X-Amz-Date")
  valid_606018 = validateParameter(valid_606018, JString, required = false,
                                 default = nil)
  if valid_606018 != nil:
    section.add "X-Amz-Date", valid_606018
  var valid_606019 = header.getOrDefault("X-Amz-Credential")
  valid_606019 = validateParameter(valid_606019, JString, required = false,
                                 default = nil)
  if valid_606019 != nil:
    section.add "X-Amz-Credential", valid_606019
  var valid_606020 = header.getOrDefault("X-Amz-Security-Token")
  valid_606020 = validateParameter(valid_606020, JString, required = false,
                                 default = nil)
  if valid_606020 != nil:
    section.add "X-Amz-Security-Token", valid_606020
  var valid_606021 = header.getOrDefault("X-Amz-Algorithm")
  valid_606021 = validateParameter(valid_606021, JString, required = false,
                                 default = nil)
  if valid_606021 != nil:
    section.add "X-Amz-Algorithm", valid_606021
  var valid_606022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606022 = validateParameter(valid_606022, JString, required = false,
                                 default = nil)
  if valid_606022 != nil:
    section.add "X-Amz-SignedHeaders", valid_606022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606046: Call_CreateToken_605902; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and returns an access token for the authorized client. The access token issued will be used to fetch short-term credentials for the assigned roles in the AWS account.
  ## 
  let valid = call_606046.validator(path, query, header, formData, body)
  let scheme = call_606046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606046.url(scheme.get, call_606046.host, call_606046.base,
                         call_606046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606046, url, valid)

proc call*(call_606117: Call_CreateToken_605902; body: JsonNode): Recallable =
  ## createToken
  ## Creates and returns an access token for the authorized client. The access token issued will be used to fetch short-term credentials for the assigned roles in the AWS account.
  ##   body: JObject (required)
  var body_606118 = newJObject()
  if body != nil:
    body_606118 = body
  result = call_606117.call(nil, nil, nil, nil, body_606118)

var createToken* = Call_CreateToken_605902(name: "createToken",
                                        meth: HttpMethod.HttpPost,
                                        host: "oidc.amazonaws.com",
                                        route: "/token",
                                        validator: validate_CreateToken_605903,
                                        base: "/", url: url_CreateToken_605904,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterClient_606157 = ref object of OpenApiRestCall_605564
proc url_RegisterClient_606159(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterClient_606158(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Registers a client with AWS SSO. This allows clients to initiate device authorization. The output should be persisted for reuse through many authentication requests.
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
  var valid_606160 = header.getOrDefault("X-Amz-Signature")
  valid_606160 = validateParameter(valid_606160, JString, required = false,
                                 default = nil)
  if valid_606160 != nil:
    section.add "X-Amz-Signature", valid_606160
  var valid_606161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606161 = validateParameter(valid_606161, JString, required = false,
                                 default = nil)
  if valid_606161 != nil:
    section.add "X-Amz-Content-Sha256", valid_606161
  var valid_606162 = header.getOrDefault("X-Amz-Date")
  valid_606162 = validateParameter(valid_606162, JString, required = false,
                                 default = nil)
  if valid_606162 != nil:
    section.add "X-Amz-Date", valid_606162
  var valid_606163 = header.getOrDefault("X-Amz-Credential")
  valid_606163 = validateParameter(valid_606163, JString, required = false,
                                 default = nil)
  if valid_606163 != nil:
    section.add "X-Amz-Credential", valid_606163
  var valid_606164 = header.getOrDefault("X-Amz-Security-Token")
  valid_606164 = validateParameter(valid_606164, JString, required = false,
                                 default = nil)
  if valid_606164 != nil:
    section.add "X-Amz-Security-Token", valid_606164
  var valid_606165 = header.getOrDefault("X-Amz-Algorithm")
  valid_606165 = validateParameter(valid_606165, JString, required = false,
                                 default = nil)
  if valid_606165 != nil:
    section.add "X-Amz-Algorithm", valid_606165
  var valid_606166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606166 = validateParameter(valid_606166, JString, required = false,
                                 default = nil)
  if valid_606166 != nil:
    section.add "X-Amz-SignedHeaders", valid_606166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606168: Call_RegisterClient_606157; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a client with AWS SSO. This allows clients to initiate device authorization. The output should be persisted for reuse through many authentication requests.
  ## 
  let valid = call_606168.validator(path, query, header, formData, body)
  let scheme = call_606168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606168.url(scheme.get, call_606168.host, call_606168.base,
                         call_606168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606168, url, valid)

proc call*(call_606169: Call_RegisterClient_606157; body: JsonNode): Recallable =
  ## registerClient
  ## Registers a client with AWS SSO. This allows clients to initiate device authorization. The output should be persisted for reuse through many authentication requests.
  ##   body: JObject (required)
  var body_606170 = newJObject()
  if body != nil:
    body_606170 = body
  result = call_606169.call(nil, nil, nil, nil, body_606170)

var registerClient* = Call_RegisterClient_606157(name: "registerClient",
    meth: HttpMethod.HttpPost, host: "oidc.amazonaws.com",
    route: "/client/register", validator: validate_RegisterClient_606158, base: "/",
    url: url_RegisterClient_606159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeviceAuthorization_606171 = ref object of OpenApiRestCall_605564
proc url_StartDeviceAuthorization_606173(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDeviceAuthorization_606172(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Initiates device authorization by requesting a pair of verification codes from the authorization service.
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
  var valid_606174 = header.getOrDefault("X-Amz-Signature")
  valid_606174 = validateParameter(valid_606174, JString, required = false,
                                 default = nil)
  if valid_606174 != nil:
    section.add "X-Amz-Signature", valid_606174
  var valid_606175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606175 = validateParameter(valid_606175, JString, required = false,
                                 default = nil)
  if valid_606175 != nil:
    section.add "X-Amz-Content-Sha256", valid_606175
  var valid_606176 = header.getOrDefault("X-Amz-Date")
  valid_606176 = validateParameter(valid_606176, JString, required = false,
                                 default = nil)
  if valid_606176 != nil:
    section.add "X-Amz-Date", valid_606176
  var valid_606177 = header.getOrDefault("X-Amz-Credential")
  valid_606177 = validateParameter(valid_606177, JString, required = false,
                                 default = nil)
  if valid_606177 != nil:
    section.add "X-Amz-Credential", valid_606177
  var valid_606178 = header.getOrDefault("X-Amz-Security-Token")
  valid_606178 = validateParameter(valid_606178, JString, required = false,
                                 default = nil)
  if valid_606178 != nil:
    section.add "X-Amz-Security-Token", valid_606178
  var valid_606179 = header.getOrDefault("X-Amz-Algorithm")
  valid_606179 = validateParameter(valid_606179, JString, required = false,
                                 default = nil)
  if valid_606179 != nil:
    section.add "X-Amz-Algorithm", valid_606179
  var valid_606180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606180 = validateParameter(valid_606180, JString, required = false,
                                 default = nil)
  if valid_606180 != nil:
    section.add "X-Amz-SignedHeaders", valid_606180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606182: Call_StartDeviceAuthorization_606171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates device authorization by requesting a pair of verification codes from the authorization service.
  ## 
  let valid = call_606182.validator(path, query, header, formData, body)
  let scheme = call_606182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606182.url(scheme.get, call_606182.host, call_606182.base,
                         call_606182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606182, url, valid)

proc call*(call_606183: Call_StartDeviceAuthorization_606171; body: JsonNode): Recallable =
  ## startDeviceAuthorization
  ## Initiates device authorization by requesting a pair of verification codes from the authorization service.
  ##   body: JObject (required)
  var body_606184 = newJObject()
  if body != nil:
    body_606184 = body
  result = call_606183.call(nil, nil, nil, nil, body_606184)

var startDeviceAuthorization* = Call_StartDeviceAuthorization_606171(
    name: "startDeviceAuthorization", meth: HttpMethod.HttpPost,
    host: "oidc.amazonaws.com", route: "/device_authorization",
    validator: validate_StartDeviceAuthorization_606172, base: "/",
    url: url_StartDeviceAuthorization_606173, schemes: {Scheme.Https, Scheme.Http})
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
