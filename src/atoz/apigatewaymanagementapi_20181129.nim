
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostToConnection_606188 = ref object of OpenApiRestCall_605580
proc url_PostToConnection_606190(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostToConnection_606189(path: JsonNode; query: JsonNode;
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
  var valid_606191 = path.getOrDefault("connectionId")
  valid_606191 = validateParameter(valid_606191, JString, required = true,
                                 default = nil)
  if valid_606191 != nil:
    section.add "connectionId", valid_606191
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
  var valid_606192 = header.getOrDefault("X-Amz-Signature")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Signature", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Content-Sha256", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Date")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Date", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-Credential")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-Credential", valid_606195
  var valid_606196 = header.getOrDefault("X-Amz-Security-Token")
  valid_606196 = validateParameter(valid_606196, JString, required = false,
                                 default = nil)
  if valid_606196 != nil:
    section.add "X-Amz-Security-Token", valid_606196
  var valid_606197 = header.getOrDefault("X-Amz-Algorithm")
  valid_606197 = validateParameter(valid_606197, JString, required = false,
                                 default = nil)
  if valid_606197 != nil:
    section.add "X-Amz-Algorithm", valid_606197
  var valid_606198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606198 = validateParameter(valid_606198, JString, required = false,
                                 default = nil)
  if valid_606198 != nil:
    section.add "X-Amz-SignedHeaders", valid_606198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606200: Call_PostToConnection_606188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends the provided data to the specified connection.
  ## 
  let valid = call_606200.validator(path, query, header, formData, body)
  let scheme = call_606200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606200.url(scheme.get, call_606200.host, call_606200.base,
                         call_606200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606200, url, valid)

proc call*(call_606201: Call_PostToConnection_606188; body: JsonNode;
          connectionId: string): Recallable =
  ## postToConnection
  ## Sends the provided data to the specified connection.
  ##   body: JObject (required)
  ##   connectionId: string (required)
  ##               : The identifier of the connection that a specific client is using.
  var path_606202 = newJObject()
  var body_606203 = newJObject()
  if body != nil:
    body_606203 = body
  add(path_606202, "connectionId", newJString(connectionId))
  result = call_606201.call(path_606202, nil, nil, nil, body_606203)

var postToConnection* = Call_PostToConnection_606188(name: "postToConnection",
    meth: HttpMethod.HttpPost, host: "execute-api.amazonaws.com",
    route: "/@connections/{connectionId}", validator: validate_PostToConnection_606189,
    base: "/", url: url_PostToConnection_606190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_605918 = ref object of OpenApiRestCall_605580
proc url_GetConnection_605920(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConnection_605919(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606046 = path.getOrDefault("connectionId")
  valid_606046 = validateParameter(valid_606046, JString, required = true,
                                 default = nil)
  if valid_606046 != nil:
    section.add "connectionId", valid_606046
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
  var valid_606047 = header.getOrDefault("X-Amz-Signature")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Signature", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Content-Sha256", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Date")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Date", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Credential")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Credential", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Security-Token")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Security-Token", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-Algorithm")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-Algorithm", valid_606052
  var valid_606053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606053 = validateParameter(valid_606053, JString, required = false,
                                 default = nil)
  if valid_606053 != nil:
    section.add "X-Amz-SignedHeaders", valid_606053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606076: Call_GetConnection_605918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about the connection with the provided id.
  ## 
  let valid = call_606076.validator(path, query, header, formData, body)
  let scheme = call_606076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606076.url(scheme.get, call_606076.host, call_606076.base,
                         call_606076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606076, url, valid)

proc call*(call_606147: Call_GetConnection_605918; connectionId: string): Recallable =
  ## getConnection
  ## Get information about the connection with the provided id.
  ##   connectionId: string (required)
  var path_606148 = newJObject()
  add(path_606148, "connectionId", newJString(connectionId))
  result = call_606147.call(path_606148, nil, nil, nil, nil)

var getConnection* = Call_GetConnection_605918(name: "getConnection",
    meth: HttpMethod.HttpGet, host: "execute-api.amazonaws.com",
    route: "/@connections/{connectionId}", validator: validate_GetConnection_605919,
    base: "/", url: url_GetConnection_605920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_606204 = ref object of OpenApiRestCall_605580
proc url_DeleteConnection_606206(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConnection_606205(path: JsonNode; query: JsonNode;
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
  var valid_606207 = path.getOrDefault("connectionId")
  valid_606207 = validateParameter(valid_606207, JString, required = true,
                                 default = nil)
  if valid_606207 != nil:
    section.add "connectionId", valid_606207
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
  var valid_606208 = header.getOrDefault("X-Amz-Signature")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Signature", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Content-Sha256", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Date")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Date", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Credential")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Credential", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Security-Token")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Security-Token", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Algorithm")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Algorithm", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-SignedHeaders", valid_606214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606215: Call_DeleteConnection_606204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete the connection with the provided id.
  ## 
  let valid = call_606215.validator(path, query, header, formData, body)
  let scheme = call_606215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606215.url(scheme.get, call_606215.host, call_606215.base,
                         call_606215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606215, url, valid)

proc call*(call_606216: Call_DeleteConnection_606204; connectionId: string): Recallable =
  ## deleteConnection
  ## Delete the connection with the provided id.
  ##   connectionId: string (required)
  var path_606217 = newJObject()
  add(path_606217, "connectionId", newJString(connectionId))
  result = call_606216.call(path_606217, nil, nil, nil, nil)

var deleteConnection* = Call_DeleteConnection_606204(name: "deleteConnection",
    meth: HttpMethod.HttpDelete, host: "execute-api.amazonaws.com",
    route: "/@connections/{connectionId}", validator: validate_DeleteConnection_606205,
    base: "/", url: url_DeleteConnection_606206,
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
