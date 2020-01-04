
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

  OpenApiRestCall_601364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601364): Option[Scheme] {.used.} =
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
  Call_CreateToken_601702 = ref object of OpenApiRestCall_601364
proc url_CreateToken_601704(protocol: Scheme; host: string; base: string;
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

proc validate_CreateToken_601703(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601816 = header.getOrDefault("X-Amz-Signature")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "X-Amz-Signature", valid_601816
  var valid_601817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "X-Amz-Content-Sha256", valid_601817
  var valid_601818 = header.getOrDefault("X-Amz-Date")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "X-Amz-Date", valid_601818
  var valid_601819 = header.getOrDefault("X-Amz-Credential")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "X-Amz-Credential", valid_601819
  var valid_601820 = header.getOrDefault("X-Amz-Security-Token")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "X-Amz-Security-Token", valid_601820
  var valid_601821 = header.getOrDefault("X-Amz-Algorithm")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Algorithm", valid_601821
  var valid_601822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-SignedHeaders", valid_601822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601846: Call_CreateToken_601702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates and returns an access token for the authorized client. The access token issued will be used to fetch short-term credentials for the assigned roles in the AWS account.
  ## 
  let valid = call_601846.validator(path, query, header, formData, body)
  let scheme = call_601846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601846.url(scheme.get, call_601846.host, call_601846.base,
                         call_601846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601846, url, valid)

proc call*(call_601917: Call_CreateToken_601702; body: JsonNode): Recallable =
  ## createToken
  ## Creates and returns an access token for the authorized client. The access token issued will be used to fetch short-term credentials for the assigned roles in the AWS account.
  ##   body: JObject (required)
  var body_601918 = newJObject()
  if body != nil:
    body_601918 = body
  result = call_601917.call(nil, nil, nil, nil, body_601918)

var createToken* = Call_CreateToken_601702(name: "createToken",
                                        meth: HttpMethod.HttpPost,
                                        host: "oidc.amazonaws.com",
                                        route: "/token",
                                        validator: validate_CreateToken_601703,
                                        base: "/", url: url_CreateToken_601704,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterClient_601957 = ref object of OpenApiRestCall_601364
proc url_RegisterClient_601959(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterClient_601958(path: JsonNode; query: JsonNode;
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
  var valid_601960 = header.getOrDefault("X-Amz-Signature")
  valid_601960 = validateParameter(valid_601960, JString, required = false,
                                 default = nil)
  if valid_601960 != nil:
    section.add "X-Amz-Signature", valid_601960
  var valid_601961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601961 = validateParameter(valid_601961, JString, required = false,
                                 default = nil)
  if valid_601961 != nil:
    section.add "X-Amz-Content-Sha256", valid_601961
  var valid_601962 = header.getOrDefault("X-Amz-Date")
  valid_601962 = validateParameter(valid_601962, JString, required = false,
                                 default = nil)
  if valid_601962 != nil:
    section.add "X-Amz-Date", valid_601962
  var valid_601963 = header.getOrDefault("X-Amz-Credential")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "X-Amz-Credential", valid_601963
  var valid_601964 = header.getOrDefault("X-Amz-Security-Token")
  valid_601964 = validateParameter(valid_601964, JString, required = false,
                                 default = nil)
  if valid_601964 != nil:
    section.add "X-Amz-Security-Token", valid_601964
  var valid_601965 = header.getOrDefault("X-Amz-Algorithm")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "X-Amz-Algorithm", valid_601965
  var valid_601966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-SignedHeaders", valid_601966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601968: Call_RegisterClient_601957; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a client with AWS SSO. This allows clients to initiate device authorization. The output should be persisted for reuse through many authentication requests.
  ## 
  let valid = call_601968.validator(path, query, header, formData, body)
  let scheme = call_601968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601968.url(scheme.get, call_601968.host, call_601968.base,
                         call_601968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601968, url, valid)

proc call*(call_601969: Call_RegisterClient_601957; body: JsonNode): Recallable =
  ## registerClient
  ## Registers a client with AWS SSO. This allows clients to initiate device authorization. The output should be persisted for reuse through many authentication requests.
  ##   body: JObject (required)
  var body_601970 = newJObject()
  if body != nil:
    body_601970 = body
  result = call_601969.call(nil, nil, nil, nil, body_601970)

var registerClient* = Call_RegisterClient_601957(name: "registerClient",
    meth: HttpMethod.HttpPost, host: "oidc.amazonaws.com",
    route: "/client/register", validator: validate_RegisterClient_601958, base: "/",
    url: url_RegisterClient_601959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeviceAuthorization_601971 = ref object of OpenApiRestCall_601364
proc url_StartDeviceAuthorization_601973(protocol: Scheme; host: string;
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

proc validate_StartDeviceAuthorization_601972(path: JsonNode; query: JsonNode;
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
  var valid_601974 = header.getOrDefault("X-Amz-Signature")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "X-Amz-Signature", valid_601974
  var valid_601975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-Content-Sha256", valid_601975
  var valid_601976 = header.getOrDefault("X-Amz-Date")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "X-Amz-Date", valid_601976
  var valid_601977 = header.getOrDefault("X-Amz-Credential")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "X-Amz-Credential", valid_601977
  var valid_601978 = header.getOrDefault("X-Amz-Security-Token")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "X-Amz-Security-Token", valid_601978
  var valid_601979 = header.getOrDefault("X-Amz-Algorithm")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "X-Amz-Algorithm", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-SignedHeaders", valid_601980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601982: Call_StartDeviceAuthorization_601971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates device authorization by requesting a pair of verification codes from the authorization service.
  ## 
  let valid = call_601982.validator(path, query, header, formData, body)
  let scheme = call_601982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601982.url(scheme.get, call_601982.host, call_601982.base,
                         call_601982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601982, url, valid)

proc call*(call_601983: Call_StartDeviceAuthorization_601971; body: JsonNode): Recallable =
  ## startDeviceAuthorization
  ## Initiates device authorization by requesting a pair of verification codes from the authorization service.
  ##   body: JObject (required)
  var body_601984 = newJObject()
  if body != nil:
    body_601984 = body
  result = call_601983.call(nil, nil, nil, nil, body_601984)

var startDeviceAuthorization* = Call_StartDeviceAuthorization_601971(
    name: "startDeviceAuthorization", meth: HttpMethod.HttpPost,
    host: "oidc.amazonaws.com", route: "/device_authorization",
    validator: validate_StartDeviceAuthorization_601972, base: "/",
    url: url_StartDeviceAuthorization_601973, schemes: {Scheme.Https, Scheme.Http})
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
