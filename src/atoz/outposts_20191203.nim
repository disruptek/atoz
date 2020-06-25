
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Outposts
## version: 2019-12-03
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Outposts is a fully-managed service that extends AWS infrastructure, APIs, and tools to customer premises. By providing local access to AWS-managed infrastructure, AWS Outposts enables customers to build and run applications on premises using the same programming interfaces as in AWS Regions, while using local compute and storage resources for lower latency and local data processing needs.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/outposts/
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

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "outposts.ap-northeast-1.amazonaws.com", "ap-southeast-1": "outposts.ap-southeast-1.amazonaws.com",
                           "us-west-2": "outposts.us-west-2.amazonaws.com",
                           "eu-west-2": "outposts.eu-west-2.amazonaws.com", "ap-northeast-3": "outposts.ap-northeast-3.amazonaws.com", "eu-central-1": "outposts.eu-central-1.amazonaws.com",
                           "us-east-2": "outposts.us-east-2.amazonaws.com",
                           "us-east-1": "outposts.us-east-1.amazonaws.com", "cn-northwest-1": "outposts.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "outposts.ap-south-1.amazonaws.com",
                           "eu-north-1": "outposts.eu-north-1.amazonaws.com", "ap-northeast-2": "outposts.ap-northeast-2.amazonaws.com",
                           "us-west-1": "outposts.us-west-1.amazonaws.com", "us-gov-east-1": "outposts.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "outposts.eu-west-3.amazonaws.com", "cn-north-1": "outposts.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "outposts.sa-east-1.amazonaws.com",
                           "eu-west-1": "outposts.eu-west-1.amazonaws.com", "us-gov-west-1": "outposts.us-gov-west-1.amazonaws.com", "ap-southeast-2": "outposts.ap-southeast-2.amazonaws.com", "ca-central-1": "outposts.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "outposts.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "outposts.ap-southeast-1.amazonaws.com",
      "us-west-2": "outposts.us-west-2.amazonaws.com",
      "eu-west-2": "outposts.eu-west-2.amazonaws.com",
      "ap-northeast-3": "outposts.ap-northeast-3.amazonaws.com",
      "eu-central-1": "outposts.eu-central-1.amazonaws.com",
      "us-east-2": "outposts.us-east-2.amazonaws.com",
      "us-east-1": "outposts.us-east-1.amazonaws.com",
      "cn-northwest-1": "outposts.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "outposts.ap-south-1.amazonaws.com",
      "eu-north-1": "outposts.eu-north-1.amazonaws.com",
      "ap-northeast-2": "outposts.ap-northeast-2.amazonaws.com",
      "us-west-1": "outposts.us-west-1.amazonaws.com",
      "us-gov-east-1": "outposts.us-gov-east-1.amazonaws.com",
      "eu-west-3": "outposts.eu-west-3.amazonaws.com",
      "cn-north-1": "outposts.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "outposts.sa-east-1.amazonaws.com",
      "eu-west-1": "outposts.eu-west-1.amazonaws.com",
      "us-gov-west-1": "outposts.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "outposts.ap-southeast-2.amazonaws.com",
      "ca-central-1": "outposts.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "outposts"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateOutpost_21626010 = ref object of OpenApiRestCall_21625426
proc url_CreateOutpost_21626012(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOutpost_21626011(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates an Outpost.
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
  var valid_21626013 = header.getOrDefault("X-Amz-Date")
  valid_21626013 = validateParameter(valid_21626013, JString, required = false,
                                   default = nil)
  if valid_21626013 != nil:
    section.add "X-Amz-Date", valid_21626013
  var valid_21626014 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626014 = validateParameter(valid_21626014, JString, required = false,
                                   default = nil)
  if valid_21626014 != nil:
    section.add "X-Amz-Security-Token", valid_21626014
  var valid_21626015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626015 = validateParameter(valid_21626015, JString, required = false,
                                   default = nil)
  if valid_21626015 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626015
  var valid_21626016 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626016 = validateParameter(valid_21626016, JString, required = false,
                                   default = nil)
  if valid_21626016 != nil:
    section.add "X-Amz-Algorithm", valid_21626016
  var valid_21626017 = header.getOrDefault("X-Amz-Signature")
  valid_21626017 = validateParameter(valid_21626017, JString, required = false,
                                   default = nil)
  if valid_21626017 != nil:
    section.add "X-Amz-Signature", valid_21626017
  var valid_21626018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626018 = validateParameter(valid_21626018, JString, required = false,
                                   default = nil)
  if valid_21626018 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626018
  var valid_21626019 = header.getOrDefault("X-Amz-Credential")
  valid_21626019 = validateParameter(valid_21626019, JString, required = false,
                                   default = nil)
  if valid_21626019 != nil:
    section.add "X-Amz-Credential", valid_21626019
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

proc call*(call_21626021: Call_CreateOutpost_21626010; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Outpost.
  ## 
  let valid = call_21626021.validator(path, query, header, formData, body, _)
  let scheme = call_21626021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626021.makeUrl(scheme.get, call_21626021.host, call_21626021.base,
                               call_21626021.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626021, uri, valid, _)

proc call*(call_21626022: Call_CreateOutpost_21626010; body: JsonNode): Recallable =
  ## createOutpost
  ## Creates an Outpost.
  ##   body: JObject (required)
  var body_21626023 = newJObject()
  if body != nil:
    body_21626023 = body
  result = call_21626022.call(nil, nil, nil, nil, body_21626023)

var createOutpost* = Call_CreateOutpost_21626010(name: "createOutpost",
    meth: HttpMethod.HttpPost, host: "outposts.amazonaws.com", route: "/outposts",
    validator: validate_CreateOutpost_21626011, base: "/",
    makeUrl: url_CreateOutpost_21626012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutposts_21625770 = ref object of OpenApiRestCall_21625426
proc url_ListOutposts_21625772(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOutposts_21625771(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## List the Outposts for your AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The pagination token.
  ##   MaxResults: JInt
  ##             : The maximum page size.
  section = newJObject()
  var valid_21625873 = query.getOrDefault("NextToken")
  valid_21625873 = validateParameter(valid_21625873, JString, required = false,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "NextToken", valid_21625873
  var valid_21625874 = query.getOrDefault("MaxResults")
  valid_21625874 = validateParameter(valid_21625874, JInt, required = false,
                                   default = nil)
  if valid_21625874 != nil:
    section.add "MaxResults", valid_21625874
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
  var valid_21625875 = header.getOrDefault("X-Amz-Date")
  valid_21625875 = validateParameter(valid_21625875, JString, required = false,
                                   default = nil)
  if valid_21625875 != nil:
    section.add "X-Amz-Date", valid_21625875
  var valid_21625876 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625876 = validateParameter(valid_21625876, JString, required = false,
                                   default = nil)
  if valid_21625876 != nil:
    section.add "X-Amz-Security-Token", valid_21625876
  var valid_21625877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625877 = validateParameter(valid_21625877, JString, required = false,
                                   default = nil)
  if valid_21625877 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625877
  var valid_21625878 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625878 = validateParameter(valid_21625878, JString, required = false,
                                   default = nil)
  if valid_21625878 != nil:
    section.add "X-Amz-Algorithm", valid_21625878
  var valid_21625879 = header.getOrDefault("X-Amz-Signature")
  valid_21625879 = validateParameter(valid_21625879, JString, required = false,
                                   default = nil)
  if valid_21625879 != nil:
    section.add "X-Amz-Signature", valid_21625879
  var valid_21625880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625880 = validateParameter(valid_21625880, JString, required = false,
                                   default = nil)
  if valid_21625880 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625880
  var valid_21625881 = header.getOrDefault("X-Amz-Credential")
  valid_21625881 = validateParameter(valid_21625881, JString, required = false,
                                   default = nil)
  if valid_21625881 != nil:
    section.add "X-Amz-Credential", valid_21625881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625906: Call_ListOutposts_21625770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the Outposts for your AWS account.
  ## 
  let valid = call_21625906.validator(path, query, header, formData, body, _)
  let scheme = call_21625906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625906.makeUrl(scheme.get, call_21625906.host, call_21625906.base,
                               call_21625906.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625906, uri, valid, _)

proc call*(call_21625969: Call_ListOutposts_21625770; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## listOutposts
  ## List the Outposts for your AWS account.
  ##   NextToken: string
  ##            : The pagination token.
  ##   MaxResults: int
  ##             : The maximum page size.
  var query_21625971 = newJObject()
  add(query_21625971, "NextToken", newJString(NextToken))
  add(query_21625971, "MaxResults", newJInt(MaxResults))
  result = call_21625969.call(nil, query_21625971, nil, nil, nil)

var listOutposts* = Call_ListOutposts_21625770(name: "listOutposts",
    meth: HttpMethod.HttpGet, host: "outposts.amazonaws.com", route: "/outposts",
    validator: validate_ListOutposts_21625771, base: "/", makeUrl: url_ListOutposts_21625772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpost_21626024 = ref object of OpenApiRestCall_21625426
proc url_GetOutpost_21626026(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OutpostId" in path, "`OutpostId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/outposts/"),
               (kind: VariableSegment, value: "OutpostId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetOutpost_21626025(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about the specified Outpost.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OutpostId: JString (required)
  ##            : The ID of the Outpost.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `OutpostId` field"
  var valid_21626040 = path.getOrDefault("OutpostId")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "OutpostId", valid_21626040
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
  var valid_21626041 = header.getOrDefault("X-Amz-Date")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Date", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Security-Token", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Algorithm", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Signature")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Signature", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Credential")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Credential", valid_21626047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626048: Call_GetOutpost_21626024; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the specified Outpost.
  ## 
  let valid = call_21626048.validator(path, query, header, formData, body, _)
  let scheme = call_21626048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626048.makeUrl(scheme.get, call_21626048.host, call_21626048.base,
                               call_21626048.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626048, uri, valid, _)

proc call*(call_21626049: Call_GetOutpost_21626024; OutpostId: string): Recallable =
  ## getOutpost
  ## Gets information about the specified Outpost.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  var path_21626050 = newJObject()
  add(path_21626050, "OutpostId", newJString(OutpostId))
  result = call_21626049.call(path_21626050, nil, nil, nil, nil)

var getOutpost* = Call_GetOutpost_21626024(name: "getOutpost",
                                        meth: HttpMethod.HttpGet,
                                        host: "outposts.amazonaws.com",
                                        route: "/outposts/{OutpostId}",
                                        validator: validate_GetOutpost_21626025,
                                        base: "/", makeUrl: url_GetOutpost_21626026,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOutpost_21626051 = ref object of OpenApiRestCall_21625426
proc url_DeleteOutpost_21626053(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OutpostId" in path, "`OutpostId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/outposts/"),
               (kind: VariableSegment, value: "OutpostId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteOutpost_21626052(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the Outpost.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OutpostId: JString (required)
  ##            : The ID of the Outpost.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `OutpostId` field"
  var valid_21626054 = path.getOrDefault("OutpostId")
  valid_21626054 = validateParameter(valid_21626054, JString, required = true,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "OutpostId", valid_21626054
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
  var valid_21626055 = header.getOrDefault("X-Amz-Date")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Date", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Security-Token", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Algorithm", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Signature")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Signature", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Credential")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Credential", valid_21626061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626062: Call_DeleteOutpost_21626051; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the Outpost.
  ## 
  let valid = call_21626062.validator(path, query, header, formData, body, _)
  let scheme = call_21626062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626062.makeUrl(scheme.get, call_21626062.host, call_21626062.base,
                               call_21626062.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626062, uri, valid, _)

proc call*(call_21626063: Call_DeleteOutpost_21626051; OutpostId: string): Recallable =
  ## deleteOutpost
  ## Deletes the Outpost.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  var path_21626064 = newJObject()
  add(path_21626064, "OutpostId", newJString(OutpostId))
  result = call_21626063.call(path_21626064, nil, nil, nil, nil)

var deleteOutpost* = Call_DeleteOutpost_21626051(name: "deleteOutpost",
    meth: HttpMethod.HttpDelete, host: "outposts.amazonaws.com",
    route: "/outposts/{OutpostId}", validator: validate_DeleteOutpost_21626052,
    base: "/", makeUrl: url_DeleteOutpost_21626053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSite_21626065 = ref object of OpenApiRestCall_21625426
proc url_DeleteSite_21626067(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SiteId" in path, "`SiteId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/sites/"),
               (kind: VariableSegment, value: "SiteId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSite_21626066(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the site.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SiteId: JString (required)
  ##         : The ID of the site.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SiteId` field"
  var valid_21626068 = path.getOrDefault("SiteId")
  valid_21626068 = validateParameter(valid_21626068, JString, required = true,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "SiteId", valid_21626068
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
  var valid_21626069 = header.getOrDefault("X-Amz-Date")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Date", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Security-Token", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Algorithm", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Signature")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Signature", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Credential")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Credential", valid_21626075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626076: Call_DeleteSite_21626065; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the site.
  ## 
  let valid = call_21626076.validator(path, query, header, formData, body, _)
  let scheme = call_21626076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626076.makeUrl(scheme.get, call_21626076.host, call_21626076.base,
                               call_21626076.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626076, uri, valid, _)

proc call*(call_21626077: Call_DeleteSite_21626065; SiteId: string): Recallable =
  ## deleteSite
  ## Deletes the site.
  ##   SiteId: string (required)
  ##         : The ID of the site.
  var path_21626078 = newJObject()
  add(path_21626078, "SiteId", newJString(SiteId))
  result = call_21626077.call(path_21626078, nil, nil, nil, nil)

var deleteSite* = Call_DeleteSite_21626065(name: "deleteSite",
                                        meth: HttpMethod.HttpDelete,
                                        host: "outposts.amazonaws.com",
                                        route: "/sites/{SiteId}",
                                        validator: validate_DeleteSite_21626066,
                                        base: "/", makeUrl: url_DeleteSite_21626067,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpostInstanceTypes_21626079 = ref object of OpenApiRestCall_21625426
proc url_GetOutpostInstanceTypes_21626081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OutpostId" in path, "`OutpostId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/outposts/"),
               (kind: VariableSegment, value: "OutpostId"),
               (kind: ConstantSegment, value: "/instanceTypes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetOutpostInstanceTypes_21626080(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the instance types for the specified Outpost.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OutpostId: JString (required)
  ##            : The ID of the Outpost.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `OutpostId` field"
  var valid_21626082 = path.getOrDefault("OutpostId")
  valid_21626082 = validateParameter(valid_21626082, JString, required = true,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "OutpostId", valid_21626082
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The pagination token.
  ##   MaxResults: JInt
  ##             : The maximum page size.
  section = newJObject()
  var valid_21626083 = query.getOrDefault("NextToken")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "NextToken", valid_21626083
  var valid_21626084 = query.getOrDefault("MaxResults")
  valid_21626084 = validateParameter(valid_21626084, JInt, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "MaxResults", valid_21626084
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
  var valid_21626085 = header.getOrDefault("X-Amz-Date")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Date", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Security-Token", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Algorithm", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Signature")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Signature", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Credential")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Credential", valid_21626091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626092: Call_GetOutpostInstanceTypes_21626079;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the instance types for the specified Outpost.
  ## 
  let valid = call_21626092.validator(path, query, header, formData, body, _)
  let scheme = call_21626092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626092.makeUrl(scheme.get, call_21626092.host, call_21626092.base,
                               call_21626092.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626092, uri, valid, _)

proc call*(call_21626093: Call_GetOutpostInstanceTypes_21626079; OutpostId: string;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## getOutpostInstanceTypes
  ## Lists the instance types for the specified Outpost.
  ##   NextToken: string
  ##            : The pagination token.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  ##   MaxResults: int
  ##             : The maximum page size.
  var path_21626094 = newJObject()
  var query_21626095 = newJObject()
  add(query_21626095, "NextToken", newJString(NextToken))
  add(path_21626094, "OutpostId", newJString(OutpostId))
  add(query_21626095, "MaxResults", newJInt(MaxResults))
  result = call_21626093.call(path_21626094, query_21626095, nil, nil, nil)

var getOutpostInstanceTypes* = Call_GetOutpostInstanceTypes_21626079(
    name: "getOutpostInstanceTypes", meth: HttpMethod.HttpGet,
    host: "outposts.amazonaws.com", route: "/outposts/{OutpostId}/instanceTypes",
    validator: validate_GetOutpostInstanceTypes_21626080, base: "/",
    makeUrl: url_GetOutpostInstanceTypes_21626081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSites_21626096 = ref object of OpenApiRestCall_21625426
proc url_ListSites_21626098(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSites_21626097(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the sites for the specified AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The pagination token.
  ##   MaxResults: JInt
  ##             : The maximum page size.
  section = newJObject()
  var valid_21626099 = query.getOrDefault("NextToken")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "NextToken", valid_21626099
  var valid_21626100 = query.getOrDefault("MaxResults")
  valid_21626100 = validateParameter(valid_21626100, JInt, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "MaxResults", valid_21626100
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
  var valid_21626101 = header.getOrDefault("X-Amz-Date")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Date", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Security-Token", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Algorithm", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Signature")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Signature", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Credential")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Credential", valid_21626107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626108: Call_ListSites_21626096; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the sites for the specified AWS account.
  ## 
  let valid = call_21626108.validator(path, query, header, formData, body, _)
  let scheme = call_21626108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626108.makeUrl(scheme.get, call_21626108.host, call_21626108.base,
                               call_21626108.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626108, uri, valid, _)

proc call*(call_21626109: Call_ListSites_21626096; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## listSites
  ## Lists the sites for the specified AWS account.
  ##   NextToken: string
  ##            : The pagination token.
  ##   MaxResults: int
  ##             : The maximum page size.
  var query_21626110 = newJObject()
  add(query_21626110, "NextToken", newJString(NextToken))
  add(query_21626110, "MaxResults", newJInt(MaxResults))
  result = call_21626109.call(nil, query_21626110, nil, nil, nil)

var listSites* = Call_ListSites_21626096(name: "listSites", meth: HttpMethod.HttpGet,
                                      host: "outposts.amazonaws.com",
                                      route: "/sites",
                                      validator: validate_ListSites_21626097,
                                      base: "/", makeUrl: url_ListSites_21626098,
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