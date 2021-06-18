
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Personalize Runtime
## version: 2018-05-22
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p/>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/personalize-runtime/
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "personalize-runtime.ap-northeast-1.amazonaws.com", "ap-southeast-1": "personalize-runtime.ap-southeast-1.amazonaws.com", "us-west-2": "personalize-runtime.us-west-2.amazonaws.com", "eu-west-2": "personalize-runtime.eu-west-2.amazonaws.com", "ap-northeast-3": "personalize-runtime.ap-northeast-3.amazonaws.com", "eu-central-1": "personalize-runtime.eu-central-1.amazonaws.com", "us-east-2": "personalize-runtime.us-east-2.amazonaws.com", "us-east-1": "personalize-runtime.us-east-1.amazonaws.com", "cn-northwest-1": "personalize-runtime.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "personalize-runtime.ap-south-1.amazonaws.com", "eu-north-1": "personalize-runtime.eu-north-1.amazonaws.com", "ap-northeast-2": "personalize-runtime.ap-northeast-2.amazonaws.com", "us-west-1": "personalize-runtime.us-west-1.amazonaws.com", "us-gov-east-1": "personalize-runtime.us-gov-east-1.amazonaws.com", "eu-west-3": "personalize-runtime.eu-west-3.amazonaws.com", "cn-north-1": "personalize-runtime.cn-north-1.amazonaws.com.cn", "sa-east-1": "personalize-runtime.sa-east-1.amazonaws.com", "eu-west-1": "personalize-runtime.eu-west-1.amazonaws.com", "us-gov-west-1": "personalize-runtime.us-gov-west-1.amazonaws.com", "ap-southeast-2": "personalize-runtime.ap-southeast-2.amazonaws.com", "ca-central-1": "personalize-runtime.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "personalize-runtime.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "personalize-runtime.ap-southeast-1.amazonaws.com",
      "us-west-2": "personalize-runtime.us-west-2.amazonaws.com",
      "eu-west-2": "personalize-runtime.eu-west-2.amazonaws.com",
      "ap-northeast-3": "personalize-runtime.ap-northeast-3.amazonaws.com",
      "eu-central-1": "personalize-runtime.eu-central-1.amazonaws.com",
      "us-east-2": "personalize-runtime.us-east-2.amazonaws.com",
      "us-east-1": "personalize-runtime.us-east-1.amazonaws.com",
      "cn-northwest-1": "personalize-runtime.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "personalize-runtime.ap-south-1.amazonaws.com",
      "eu-north-1": "personalize-runtime.eu-north-1.amazonaws.com",
      "ap-northeast-2": "personalize-runtime.ap-northeast-2.amazonaws.com",
      "us-west-1": "personalize-runtime.us-west-1.amazonaws.com",
      "us-gov-east-1": "personalize-runtime.us-gov-east-1.amazonaws.com",
      "eu-west-3": "personalize-runtime.eu-west-3.amazonaws.com",
      "cn-north-1": "personalize-runtime.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "personalize-runtime.sa-east-1.amazonaws.com",
      "eu-west-1": "personalize-runtime.eu-west-1.amazonaws.com",
      "us-gov-west-1": "personalize-runtime.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "personalize-runtime.ap-southeast-2.amazonaws.com",
      "ca-central-1": "personalize-runtime.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "personalize-runtime"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_GetPersonalizedRanking_402656288 = ref object of OpenApiRestCall_402656038
proc url_GetPersonalizedRanking_402656290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPersonalizedRanking_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user.</p> <note> <p>The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.</p> </note>
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
  var valid_402656372 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656372 = validateParameter(valid_402656372, JString,
                                      required = false, default = nil)
  if valid_402656372 != nil:
    section.add "X-Amz-Security-Token", valid_402656372
  var valid_402656373 = header.getOrDefault("X-Amz-Signature")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "X-Amz-Signature", valid_402656373
  var valid_402656374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656374
  var valid_402656375 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "X-Amz-Algorithm", valid_402656375
  var valid_402656376 = header.getOrDefault("X-Amz-Date")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Date", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-Credential")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Credential", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656378
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

proc call*(call_402656393: Call_GetPersonalizedRanking_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user.</p> <note> <p>The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.</p> </note>
                                                                                         ## 
  let valid = call_402656393.validator(path, query, header, formData, body, _)
  let scheme = call_402656393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656393.makeUrl(scheme.get, call_402656393.host, call_402656393.base,
                                   call_402656393.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656393, uri, valid, _)

proc call*(call_402656442: Call_GetPersonalizedRanking_402656288; body: JsonNode): Recallable =
  ## getPersonalizedRanking
  ## <p>Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user.</p> <note> <p>The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656443 = newJObject()
  if body != nil:
    body_402656443 = body
  result = call_402656442.call(nil, nil, nil, nil, body_402656443)

var getPersonalizedRanking* = Call_GetPersonalizedRanking_402656288(
    name: "getPersonalizedRanking", meth: HttpMethod.HttpPost,
    host: "personalize-runtime.amazonaws.com", route: "/personalize-ranking",
    validator: validate_GetPersonalizedRanking_402656289, base: "/",
    makeUrl: url_GetPersonalizedRanking_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecommendations_402656470 = ref object of OpenApiRestCall_402656038
proc url_GetRecommendations_402656472(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRecommendations_402656471(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of recommended items. The required input depends on the recipe type used to create the solution backing the campaign, as follows:</p> <ul> <li> <p>RELATED_ITEMS - <code>itemId</code> required, <code>userId</code> not used</p> </li> <li> <p>USER_PERSONALIZATION - <code>itemId</code> optional, <code>userId</code> required</p> </li> </ul> <note> <p>Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API.</p> </note>
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
  var valid_402656473 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656473 = validateParameter(valid_402656473, JString,
                                      required = false, default = nil)
  if valid_402656473 != nil:
    section.add "X-Amz-Security-Token", valid_402656473
  var valid_402656474 = header.getOrDefault("X-Amz-Signature")
  valid_402656474 = validateParameter(valid_402656474, JString,
                                      required = false, default = nil)
  if valid_402656474 != nil:
    section.add "X-Amz-Signature", valid_402656474
  var valid_402656475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656475 = validateParameter(valid_402656475, JString,
                                      required = false, default = nil)
  if valid_402656475 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656475
  var valid_402656476 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656476 = validateParameter(valid_402656476, JString,
                                      required = false, default = nil)
  if valid_402656476 != nil:
    section.add "X-Amz-Algorithm", valid_402656476
  var valid_402656477 = header.getOrDefault("X-Amz-Date")
  valid_402656477 = validateParameter(valid_402656477, JString,
                                      required = false, default = nil)
  if valid_402656477 != nil:
    section.add "X-Amz-Date", valid_402656477
  var valid_402656478 = header.getOrDefault("X-Amz-Credential")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Credential", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656479
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

proc call*(call_402656481: Call_GetRecommendations_402656470;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of recommended items. The required input depends on the recipe type used to create the solution backing the campaign, as follows:</p> <ul> <li> <p>RELATED_ITEMS - <code>itemId</code> required, <code>userId</code> not used</p> </li> <li> <p>USER_PERSONALIZATION - <code>itemId</code> optional, <code>userId</code> required</p> </li> </ul> <note> <p>Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API.</p> </note>
                                                                                         ## 
  let valid = call_402656481.validator(path, query, header, formData, body, _)
  let scheme = call_402656481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656481.makeUrl(scheme.get, call_402656481.host, call_402656481.base,
                                   call_402656481.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656481, uri, valid, _)

proc call*(call_402656482: Call_GetRecommendations_402656470; body: JsonNode): Recallable =
  ## getRecommendations
  ## <p>Returns a list of recommended items. The required input depends on the recipe type used to create the solution backing the campaign, as follows:</p> <ul> <li> <p>RELATED_ITEMS - <code>itemId</code> required, <code>userId</code> not used</p> </li> <li> <p>USER_PERSONALIZATION - <code>itemId</code> optional, <code>userId</code> required</p> </li> </ul> <note> <p>Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656483 = newJObject()
  if body != nil:
    body_402656483 = body
  result = call_402656482.call(nil, nil, nil, nil, body_402656483)

var getRecommendations* = Call_GetRecommendations_402656470(
    name: "getRecommendations", meth: HttpMethod.HttpPost,
    host: "personalize-runtime.amazonaws.com", route: "/recommendations",
    validator: validate_GetRecommendations_402656471, base: "/",
    makeUrl: url_GetRecommendations_402656472,
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