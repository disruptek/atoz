
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AmazonApiGatewayManagementApi
## version: 2018-11-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## The Amazon API Gateway Management API allows you to directly manage runtime aspects of your deployed APIs. To use it, you must explicitly set the SDK's endpoint to point to the endpoint of your deployed API. The endpoint will be of the form https://{api-id}.execute-api.{region}.amazonaws.com/{stage}, or will be the endpoint corresponding to your API's custom domain and base path, if applicable.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/execute-api/
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

  OpenApiRestCall_600424 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600424](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600424): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "execute-api.ap-northeast-1.amazonaws.com", "ap-southeast-1": "execute-api.ap-southeast-1.amazonaws.com",
                           "us-west-2": "execute-api.us-west-2.amazonaws.com",
                           "eu-west-2": "execute-api.eu-west-2.amazonaws.com", "ap-northeast-3": "execute-api.ap-northeast-3.amazonaws.com", "eu-central-1": "execute-api.eu-central-1.amazonaws.com",
                           "us-east-2": "execute-api.us-east-2.amazonaws.com",
                           "us-east-1": "execute-api.us-east-1.amazonaws.com", "cn-northwest-1": "execute-api.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "execute-api.ap-south-1.amazonaws.com", "eu-north-1": "execute-api.eu-north-1.amazonaws.com", "ap-northeast-2": "execute-api.ap-northeast-2.amazonaws.com",
                           "us-west-1": "execute-api.us-west-1.amazonaws.com", "us-gov-east-1": "execute-api.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "execute-api.eu-west-3.amazonaws.com", "cn-north-1": "execute-api.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "execute-api.sa-east-1.amazonaws.com",
                           "eu-west-1": "execute-api.eu-west-1.amazonaws.com", "us-gov-west-1": "execute-api.us-gov-west-1.amazonaws.com", "ap-southeast-2": "execute-api.ap-southeast-2.amazonaws.com", "ca-central-1": "execute-api.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "execute-api.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "execute-api.ap-southeast-1.amazonaws.com",
      "us-west-2": "execute-api.us-west-2.amazonaws.com",
      "eu-west-2": "execute-api.eu-west-2.amazonaws.com",
      "ap-northeast-3": "execute-api.ap-northeast-3.amazonaws.com",
      "eu-central-1": "execute-api.eu-central-1.amazonaws.com",
      "us-east-2": "execute-api.us-east-2.amazonaws.com",
      "us-east-1": "execute-api.us-east-1.amazonaws.com",
      "cn-northwest-1": "execute-api.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "execute-api.ap-south-1.amazonaws.com",
      "eu-north-1": "execute-api.eu-north-1.amazonaws.com",
      "ap-northeast-2": "execute-api.ap-northeast-2.amazonaws.com",
      "us-west-1": "execute-api.us-west-1.amazonaws.com",
      "us-gov-east-1": "execute-api.us-gov-east-1.amazonaws.com",
      "eu-west-3": "execute-api.eu-west-3.amazonaws.com",
      "cn-north-1": "execute-api.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "execute-api.sa-east-1.amazonaws.com",
      "eu-west-1": "execute-api.eu-west-1.amazonaws.com",
      "us-gov-west-1": "execute-api.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "execute-api.ap-southeast-2.amazonaws.com",
      "ca-central-1": "execute-api.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "apigatewaymanagementapi"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostToConnection_601031 = ref object of OpenApiRestCall_600424
proc url_PostToConnection_601033(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "connectionId" in path, "`connectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/@connections/"),
               (kind: VariableSegment, value: "connectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PostToConnection_601032(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Sends the provided data to the specified connection.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   connectionId: JString (required)
  ##               : The identifier of the connection that a specific client is using.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `connectionId` field"
  var valid_601034 = path.getOrDefault("connectionId")
  valid_601034 = validateParameter(valid_601034, JString, required = true,
                                 default = nil)
  if valid_601034 != nil:
    section.add "connectionId", valid_601034
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
  var valid_601035 = header.getOrDefault("X-Amz-Date")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Date", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Security-Token")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Security-Token", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-Content-Sha256", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-Algorithm")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Algorithm", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-Signature")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Signature", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-SignedHeaders", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Credential")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Credential", valid_601041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601043: Call_PostToConnection_601031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends the provided data to the specified connection.
  ## 
  let valid = call_601043.validator(path, query, header, formData, body)
  let scheme = call_601043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601043.url(scheme.get, call_601043.host, call_601043.base,
                         call_601043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601043, url, valid)

proc call*(call_601044: Call_PostToConnection_601031; connectionId: string;
          body: JsonNode): Recallable =
  ## postToConnection
  ## Sends the provided data to the specified connection.
  ##   connectionId: string (required)
  ##               : The identifier of the connection that a specific client is using.
  ##   body: JObject (required)
  var path_601045 = newJObject()
  var body_601046 = newJObject()
  add(path_601045, "connectionId", newJString(connectionId))
  if body != nil:
    body_601046 = body
  result = call_601044.call(path_601045, nil, nil, nil, body_601046)

var postToConnection* = Call_PostToConnection_601031(name: "postToConnection",
    meth: HttpMethod.HttpPost, host: "execute-api.amazonaws.com",
    route: "/@connections/{connectionId}", validator: validate_PostToConnection_601032,
    base: "/", url: url_PostToConnection_601033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_600761 = ref object of OpenApiRestCall_600424
proc url_GetConnection_600763(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "connectionId" in path, "`connectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/@connections/"),
               (kind: VariableSegment, value: "connectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetConnection_600762(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Get information about the connection with the provided id.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   connectionId: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `connectionId` field"
  var valid_600889 = path.getOrDefault("connectionId")
  valid_600889 = validateParameter(valid_600889, JString, required = true,
                                 default = nil)
  if valid_600889 != nil:
    section.add "connectionId", valid_600889
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
  var valid_600890 = header.getOrDefault("X-Amz-Date")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Date", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Security-Token")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Security-Token", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Content-Sha256", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Algorithm")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Algorithm", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Signature")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Signature", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-SignedHeaders", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-Credential")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-Credential", valid_600896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600919: Call_GetConnection_600761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about the connection with the provided id.
  ## 
  let valid = call_600919.validator(path, query, header, formData, body)
  let scheme = call_600919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600919.url(scheme.get, call_600919.host, call_600919.base,
                         call_600919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600919, url, valid)

proc call*(call_600990: Call_GetConnection_600761; connectionId: string): Recallable =
  ## getConnection
  ## Get information about the connection with the provided id.
  ##   connectionId: string (required)
  var path_600991 = newJObject()
  add(path_600991, "connectionId", newJString(connectionId))
  result = call_600990.call(path_600991, nil, nil, nil, nil)

var getConnection* = Call_GetConnection_600761(name: "getConnection",
    meth: HttpMethod.HttpGet, host: "execute-api.amazonaws.com",
    route: "/@connections/{connectionId}", validator: validate_GetConnection_600762,
    base: "/", url: url_GetConnection_600763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_601047 = ref object of OpenApiRestCall_600424
proc url_DeleteConnection_601049(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "connectionId" in path, "`connectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/@connections/"),
               (kind: VariableSegment, value: "connectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteConnection_601048(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Delete the connection with the provided id.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   connectionId: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `connectionId` field"
  var valid_601050 = path.getOrDefault("connectionId")
  valid_601050 = validateParameter(valid_601050, JString, required = true,
                                 default = nil)
  if valid_601050 != nil:
    section.add "connectionId", valid_601050
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
  var valid_601051 = header.getOrDefault("X-Amz-Date")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Date", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Security-Token")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Security-Token", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Content-Sha256", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Algorithm")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Algorithm", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Signature")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Signature", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-SignedHeaders", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Credential")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Credential", valid_601057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601058: Call_DeleteConnection_601047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete the connection with the provided id.
  ## 
  let valid = call_601058.validator(path, query, header, formData, body)
  let scheme = call_601058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601058.url(scheme.get, call_601058.host, call_601058.base,
                         call_601058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601058, url, valid)

proc call*(call_601059: Call_DeleteConnection_601047; connectionId: string): Recallable =
  ## deleteConnection
  ## Delete the connection with the provided id.
  ##   connectionId: string (required)
  var path_601060 = newJObject()
  add(path_601060, "connectionId", newJString(connectionId))
  result = call_601059.call(path_601060, nil, nil, nil, nil)

var deleteConnection* = Call_DeleteConnection_601047(name: "deleteConnection",
    meth: HttpMethod.HttpDelete, host: "execute-api.amazonaws.com",
    route: "/@connections/{connectionId}", validator: validate_DeleteConnection_601048,
    base: "/", url: url_DeleteConnection_601049,
    schemes: {Scheme.Https, Scheme.Http})
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
