
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600413 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600413](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600413): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostToConnection_601025 = ref object of OpenApiRestCall_600413
proc url_PostToConnection_601027(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "connectionId" in path, "`connectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/@connections/"),
               (kind: VariableSegment, value: "connectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PostToConnection_601026(path: JsonNode; query: JsonNode;
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
  var valid_601028 = path.getOrDefault("connectionId")
  valid_601028 = validateParameter(valid_601028, JString, required = true,
                                 default = nil)
  if valid_601028 != nil:
    section.add "connectionId", valid_601028
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
  var valid_601029 = header.getOrDefault("X-Amz-Date")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Date", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Security-Token")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Security-Token", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Content-Sha256", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Algorithm")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Algorithm", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Signature")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Signature", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-SignedHeaders", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-Credential")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Credential", valid_601035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601037: Call_PostToConnection_601025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends the provided data to the specified connection.
  ## 
  let valid = call_601037.validator(path, query, header, formData, body)
  let scheme = call_601037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601037.url(scheme.get, call_601037.host, call_601037.base,
                         call_601037.route, valid.getOrDefault("path"))
  result = hook(call_601037, url, valid)

proc call*(call_601038: Call_PostToConnection_601025; connectionId: string;
          body: JsonNode): Recallable =
  ## postToConnection
  ## Sends the provided data to the specified connection.
  ##   connectionId: string (required)
  ##               : The identifier of the connection that a specific client is using.
  ##   body: JObject (required)
  var path_601039 = newJObject()
  var body_601040 = newJObject()
  add(path_601039, "connectionId", newJString(connectionId))
  if body != nil:
    body_601040 = body
  result = call_601038.call(path_601039, nil, nil, nil, body_601040)

var postToConnection* = Call_PostToConnection_601025(name: "postToConnection",
    meth: HttpMethod.HttpPost, host: "execute-api.amazonaws.com",
    route: "/@connections/{connectionId}", validator: validate_PostToConnection_601026,
    base: "/", url: url_PostToConnection_601027,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_600755 = ref object of OpenApiRestCall_600413
proc url_GetConnection_600757(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "connectionId" in path, "`connectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/@connections/"),
               (kind: VariableSegment, value: "connectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetConnection_600756(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600883 = path.getOrDefault("connectionId")
  valid_600883 = validateParameter(valid_600883, JString, required = true,
                                 default = nil)
  if valid_600883 != nil:
    section.add "connectionId", valid_600883
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
  var valid_600884 = header.getOrDefault("X-Amz-Date")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Date", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Security-Token")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Security-Token", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Content-Sha256", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Algorithm")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Algorithm", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Signature")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Signature", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-SignedHeaders", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Credential")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Credential", valid_600890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_GetConnection_600755; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about the connection with the provided id.
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"))
  result = hook(call_600913, url, valid)

proc call*(call_600984: Call_GetConnection_600755; connectionId: string): Recallable =
  ## getConnection
  ## Get information about the connection with the provided id.
  ##   connectionId: string (required)
  var path_600985 = newJObject()
  add(path_600985, "connectionId", newJString(connectionId))
  result = call_600984.call(path_600985, nil, nil, nil, nil)

var getConnection* = Call_GetConnection_600755(name: "getConnection",
    meth: HttpMethod.HttpGet, host: "execute-api.amazonaws.com",
    route: "/@connections/{connectionId}", validator: validate_GetConnection_600756,
    base: "/", url: url_GetConnection_600757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_601041 = ref object of OpenApiRestCall_600413
proc url_DeleteConnection_601043(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "connectionId" in path, "`connectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/@connections/"),
               (kind: VariableSegment, value: "connectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteConnection_601042(path: JsonNode; query: JsonNode;
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
  var valid_601044 = path.getOrDefault("connectionId")
  valid_601044 = validateParameter(valid_601044, JString, required = true,
                                 default = nil)
  if valid_601044 != nil:
    section.add "connectionId", valid_601044
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
  var valid_601045 = header.getOrDefault("X-Amz-Date")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Date", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Security-Token")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Security-Token", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Content-Sha256", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Algorithm")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Algorithm", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Signature")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Signature", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-SignedHeaders", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Credential")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Credential", valid_601051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601052: Call_DeleteConnection_601041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete the connection with the provided id.
  ## 
  let valid = call_601052.validator(path, query, header, formData, body)
  let scheme = call_601052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601052.url(scheme.get, call_601052.host, call_601052.base,
                         call_601052.route, valid.getOrDefault("path"))
  result = hook(call_601052, url, valid)

proc call*(call_601053: Call_DeleteConnection_601041; connectionId: string): Recallable =
  ## deleteConnection
  ## Delete the connection with the provided id.
  ##   connectionId: string (required)
  var path_601054 = newJObject()
  add(path_601054, "connectionId", newJString(connectionId))
  result = call_601053.call(path_601054, nil, nil, nil, nil)

var deleteConnection* = Call_DeleteConnection_601041(name: "deleteConnection",
    meth: HttpMethod.HttpDelete, host: "execute-api.amazonaws.com",
    route: "/@connections/{connectionId}", validator: validate_DeleteConnection_601042,
    base: "/", url: url_DeleteConnection_601043,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
