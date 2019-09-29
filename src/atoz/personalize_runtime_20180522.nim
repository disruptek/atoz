
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593424 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593424](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593424): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetPersonalizedRanking_593761 = ref object of OpenApiRestCall_593424
proc url_GetPersonalizedRanking_593763(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPersonalizedRanking_593762(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593875 = header.getOrDefault("X-Amz-Date")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "X-Amz-Date", valid_593875
  var valid_593876 = header.getOrDefault("X-Amz-Security-Token")
  valid_593876 = validateParameter(valid_593876, JString, required = false,
                                 default = nil)
  if valid_593876 != nil:
    section.add "X-Amz-Security-Token", valid_593876
  var valid_593877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593877 = validateParameter(valid_593877, JString, required = false,
                                 default = nil)
  if valid_593877 != nil:
    section.add "X-Amz-Content-Sha256", valid_593877
  var valid_593878 = header.getOrDefault("X-Amz-Algorithm")
  valid_593878 = validateParameter(valid_593878, JString, required = false,
                                 default = nil)
  if valid_593878 != nil:
    section.add "X-Amz-Algorithm", valid_593878
  var valid_593879 = header.getOrDefault("X-Amz-Signature")
  valid_593879 = validateParameter(valid_593879, JString, required = false,
                                 default = nil)
  if valid_593879 != nil:
    section.add "X-Amz-Signature", valid_593879
  var valid_593880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593880 = validateParameter(valid_593880, JString, required = false,
                                 default = nil)
  if valid_593880 != nil:
    section.add "X-Amz-SignedHeaders", valid_593880
  var valid_593881 = header.getOrDefault("X-Amz-Credential")
  valid_593881 = validateParameter(valid_593881, JString, required = false,
                                 default = nil)
  if valid_593881 != nil:
    section.add "X-Amz-Credential", valid_593881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593905: Call_GetPersonalizedRanking_593761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user.</p> <note> <p>The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.</p> </note>
  ## 
  let valid = call_593905.validator(path, query, header, formData, body)
  let scheme = call_593905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593905.url(scheme.get, call_593905.host, call_593905.base,
                         call_593905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593905, url, valid)

proc call*(call_593976: Call_GetPersonalizedRanking_593761; body: JsonNode): Recallable =
  ## getPersonalizedRanking
  ## <p>Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user.</p> <note> <p>The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.</p> </note>
  ##   body: JObject (required)
  var body_593977 = newJObject()
  if body != nil:
    body_593977 = body
  result = call_593976.call(nil, nil, nil, nil, body_593977)

var getPersonalizedRanking* = Call_GetPersonalizedRanking_593761(
    name: "getPersonalizedRanking", meth: HttpMethod.HttpPost,
    host: "personalize-runtime.amazonaws.com", route: "/personalize-ranking",
    validator: validate_GetPersonalizedRanking_593762, base: "/",
    url: url_GetPersonalizedRanking_593763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecommendations_594016 = ref object of OpenApiRestCall_593424
proc url_GetRecommendations_594018(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRecommendations_594017(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594019 = header.getOrDefault("X-Amz-Date")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Date", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Security-Token")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Security-Token", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Content-Sha256", valid_594021
  var valid_594022 = header.getOrDefault("X-Amz-Algorithm")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-Algorithm", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-Signature")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-Signature", valid_594023
  var valid_594024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "X-Amz-SignedHeaders", valid_594024
  var valid_594025 = header.getOrDefault("X-Amz-Credential")
  valid_594025 = validateParameter(valid_594025, JString, required = false,
                                 default = nil)
  if valid_594025 != nil:
    section.add "X-Amz-Credential", valid_594025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594027: Call_GetRecommendations_594016; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of recommended items. The required input depends on the recipe type used to create the solution backing the campaign, as follows:</p> <ul> <li> <p>RELATED_ITEMS - <code>itemId</code> required, <code>userId</code> not used</p> </li> <li> <p>USER_PERSONALIZATION - <code>itemId</code> optional, <code>userId</code> required</p> </li> </ul> <note> <p>Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API.</p> </note>
  ## 
  let valid = call_594027.validator(path, query, header, formData, body)
  let scheme = call_594027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594027.url(scheme.get, call_594027.host, call_594027.base,
                         call_594027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594027, url, valid)

proc call*(call_594028: Call_GetRecommendations_594016; body: JsonNode): Recallable =
  ## getRecommendations
  ## <p>Returns a list of recommended items. The required input depends on the recipe type used to create the solution backing the campaign, as follows:</p> <ul> <li> <p>RELATED_ITEMS - <code>itemId</code> required, <code>userId</code> not used</p> </li> <li> <p>USER_PERSONALIZATION - <code>itemId</code> optional, <code>userId</code> required</p> </li> </ul> <note> <p>Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API.</p> </note>
  ##   body: JObject (required)
  var body_594029 = newJObject()
  if body != nil:
    body_594029 = body
  result = call_594028.call(nil, nil, nil, nil, body_594029)

var getRecommendations* = Call_GetRecommendations_594016(
    name: "getRecommendations", meth: HttpMethod.HttpPost,
    host: "personalize-runtime.amazonaws.com", route: "/recommendations",
    validator: validate_GetRecommendations_594017, base: "/",
    url: url_GetRecommendations_594018, schemes: {Scheme.Https, Scheme.Http})
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
