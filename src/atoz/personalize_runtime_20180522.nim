
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "personalize-runtime.ap-northeast-1.amazonaws.com", "ap-southeast-1": "personalize-runtime.ap-southeast-1.amazonaws.com", "us-west-2": "personalize-runtime.us-west-2.amazonaws.com", "eu-west-2": "personalize-runtime.eu-west-2.amazonaws.com", "ap-northeast-3": "personalize-runtime.ap-northeast-3.amazonaws.com", "eu-central-1": "personalize-runtime.eu-central-1.amazonaws.com", "us-east-2": "personalize-runtime.us-east-2.amazonaws.com", "us-east-1": "personalize-runtime.us-east-1.amazonaws.com", "cn-northwest-1": "personalize-runtime.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "personalize-runtime.ap-south-1.amazonaws.com", "eu-north-1": "personalize-runtime.eu-north-1.amazonaws.com", "ap-northeast-2": "personalize-runtime.ap-northeast-2.amazonaws.com", "us-west-1": "personalize-runtime.us-west-1.amazonaws.com", "us-gov-east-1": "personalize-runtime.us-gov-east-1.amazonaws.com", "eu-west-3": "personalize-runtime.eu-west-3.amazonaws.com", "cn-north-1": "personalize-runtime.cn-north-1.amazonaws.com.cn", "sa-east-1": "personalize-runtime.sa-east-1.amazonaws.com", "eu-west-1": "personalize-runtime.eu-west-1.amazonaws.com", "us-gov-west-1": "personalize-runtime.us-gov-west-1.amazonaws.com", "ap-southeast-2": "personalize-runtime.ap-southeast-2.amazonaws.com", "ca-central-1": "personalize-runtime.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetPersonalizedRanking_605918 = ref object of OpenApiRestCall_605580
proc url_GetPersonalizedRanking_605920(protocol: Scheme; host: string; base: string;
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

proc validate_GetPersonalizedRanking_605919(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user.</p> <note> <p>The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.</p> </note>
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
  var valid_606032 = header.getOrDefault("X-Amz-Signature")
  valid_606032 = validateParameter(valid_606032, JString, required = false,
                                 default = nil)
  if valid_606032 != nil:
    section.add "X-Amz-Signature", valid_606032
  var valid_606033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606033 = validateParameter(valid_606033, JString, required = false,
                                 default = nil)
  if valid_606033 != nil:
    section.add "X-Amz-Content-Sha256", valid_606033
  var valid_606034 = header.getOrDefault("X-Amz-Date")
  valid_606034 = validateParameter(valid_606034, JString, required = false,
                                 default = nil)
  if valid_606034 != nil:
    section.add "X-Amz-Date", valid_606034
  var valid_606035 = header.getOrDefault("X-Amz-Credential")
  valid_606035 = validateParameter(valid_606035, JString, required = false,
                                 default = nil)
  if valid_606035 != nil:
    section.add "X-Amz-Credential", valid_606035
  var valid_606036 = header.getOrDefault("X-Amz-Security-Token")
  valid_606036 = validateParameter(valid_606036, JString, required = false,
                                 default = nil)
  if valid_606036 != nil:
    section.add "X-Amz-Security-Token", valid_606036
  var valid_606037 = header.getOrDefault("X-Amz-Algorithm")
  valid_606037 = validateParameter(valid_606037, JString, required = false,
                                 default = nil)
  if valid_606037 != nil:
    section.add "X-Amz-Algorithm", valid_606037
  var valid_606038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606038 = validateParameter(valid_606038, JString, required = false,
                                 default = nil)
  if valid_606038 != nil:
    section.add "X-Amz-SignedHeaders", valid_606038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606062: Call_GetPersonalizedRanking_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user.</p> <note> <p>The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.</p> </note>
  ## 
  let valid = call_606062.validator(path, query, header, formData, body)
  let scheme = call_606062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606062.url(scheme.get, call_606062.host, call_606062.base,
                         call_606062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606062, url, valid)

proc call*(call_606133: Call_GetPersonalizedRanking_605918; body: JsonNode): Recallable =
  ## getPersonalizedRanking
  ## <p>Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user.</p> <note> <p>The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.</p> </note>
  ##   body: JObject (required)
  var body_606134 = newJObject()
  if body != nil:
    body_606134 = body
  result = call_606133.call(nil, nil, nil, nil, body_606134)

var getPersonalizedRanking* = Call_GetPersonalizedRanking_605918(
    name: "getPersonalizedRanking", meth: HttpMethod.HttpPost,
    host: "personalize-runtime.amazonaws.com", route: "/personalize-ranking",
    validator: validate_GetPersonalizedRanking_605919, base: "/",
    url: url_GetPersonalizedRanking_605920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecommendations_606173 = ref object of OpenApiRestCall_605580
proc url_GetRecommendations_606175(protocol: Scheme; host: string; base: string;
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

proc validate_GetRecommendations_606174(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Returns a list of recommended items. The required input depends on the recipe type used to create the solution backing the campaign, as follows:</p> <ul> <li> <p>RELATED_ITEMS - <code>itemId</code> required, <code>userId</code> not used</p> </li> <li> <p>USER_PERSONALIZATION - <code>itemId</code> optional, <code>userId</code> required</p> </li> </ul> <note> <p>Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API.</p> </note>
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
  var valid_606176 = header.getOrDefault("X-Amz-Signature")
  valid_606176 = validateParameter(valid_606176, JString, required = false,
                                 default = nil)
  if valid_606176 != nil:
    section.add "X-Amz-Signature", valid_606176
  var valid_606177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606177 = validateParameter(valid_606177, JString, required = false,
                                 default = nil)
  if valid_606177 != nil:
    section.add "X-Amz-Content-Sha256", valid_606177
  var valid_606178 = header.getOrDefault("X-Amz-Date")
  valid_606178 = validateParameter(valid_606178, JString, required = false,
                                 default = nil)
  if valid_606178 != nil:
    section.add "X-Amz-Date", valid_606178
  var valid_606179 = header.getOrDefault("X-Amz-Credential")
  valid_606179 = validateParameter(valid_606179, JString, required = false,
                                 default = nil)
  if valid_606179 != nil:
    section.add "X-Amz-Credential", valid_606179
  var valid_606180 = header.getOrDefault("X-Amz-Security-Token")
  valid_606180 = validateParameter(valid_606180, JString, required = false,
                                 default = nil)
  if valid_606180 != nil:
    section.add "X-Amz-Security-Token", valid_606180
  var valid_606181 = header.getOrDefault("X-Amz-Algorithm")
  valid_606181 = validateParameter(valid_606181, JString, required = false,
                                 default = nil)
  if valid_606181 != nil:
    section.add "X-Amz-Algorithm", valid_606181
  var valid_606182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606182 = validateParameter(valid_606182, JString, required = false,
                                 default = nil)
  if valid_606182 != nil:
    section.add "X-Amz-SignedHeaders", valid_606182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606184: Call_GetRecommendations_606173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of recommended items. The required input depends on the recipe type used to create the solution backing the campaign, as follows:</p> <ul> <li> <p>RELATED_ITEMS - <code>itemId</code> required, <code>userId</code> not used</p> </li> <li> <p>USER_PERSONALIZATION - <code>itemId</code> optional, <code>userId</code> required</p> </li> </ul> <note> <p>Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API.</p> </note>
  ## 
  let valid = call_606184.validator(path, query, header, formData, body)
  let scheme = call_606184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606184.url(scheme.get, call_606184.host, call_606184.base,
                         call_606184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606184, url, valid)

proc call*(call_606185: Call_GetRecommendations_606173; body: JsonNode): Recallable =
  ## getRecommendations
  ## <p>Returns a list of recommended items. The required input depends on the recipe type used to create the solution backing the campaign, as follows:</p> <ul> <li> <p>RELATED_ITEMS - <code>itemId</code> required, <code>userId</code> not used</p> </li> <li> <p>USER_PERSONALIZATION - <code>itemId</code> optional, <code>userId</code> required</p> </li> </ul> <note> <p>Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API.</p> </note>
  ##   body: JObject (required)
  var body_606186 = newJObject()
  if body != nil:
    body_606186 = body
  result = call_606185.call(nil, nil, nil, nil, body_606186)

var getRecommendations* = Call_GetRecommendations_606173(
    name: "getRecommendations", meth: HttpMethod.HttpPost,
    host: "personalize-runtime.amazonaws.com", route: "/recommendations",
    validator: validate_GetRecommendations_606174, base: "/",
    url: url_GetRecommendations_606175, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
