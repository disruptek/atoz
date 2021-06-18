
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Elemental MediaLive
## version: 2017-10-14
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## API for AWS Elemental MediaLive
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/medialive/
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "medialive.ap-northeast-1.amazonaws.com", "ap-southeast-1": "medialive.ap-southeast-1.amazonaws.com", "us-west-2": "medialive.us-west-2.amazonaws.com", "eu-west-2": "medialive.eu-west-2.amazonaws.com", "ap-northeast-3": "medialive.ap-northeast-3.amazonaws.com", "eu-central-1": "medialive.eu-central-1.amazonaws.com", "us-east-2": "medialive.us-east-2.amazonaws.com", "us-east-1": "medialive.us-east-1.amazonaws.com", "cn-northwest-1": "medialive.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "medialive.ap-south-1.amazonaws.com", "eu-north-1": "medialive.eu-north-1.amazonaws.com", "ap-northeast-2": "medialive.ap-northeast-2.amazonaws.com", "us-west-1": "medialive.us-west-1.amazonaws.com", "us-gov-east-1": "medialive.us-gov-east-1.amazonaws.com", "eu-west-3": "medialive.eu-west-3.amazonaws.com", "cn-north-1": "medialive.cn-north-1.amazonaws.com.cn", "sa-east-1": "medialive.sa-east-1.amazonaws.com", "eu-west-1": "medialive.eu-west-1.amazonaws.com", "us-gov-west-1": "medialive.us-gov-west-1.amazonaws.com", "ap-southeast-2": "medialive.ap-southeast-2.amazonaws.com", "ca-central-1": "medialive.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "medialive.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "medialive.ap-southeast-1.amazonaws.com",
      "us-west-2": "medialive.us-west-2.amazonaws.com",
      "eu-west-2": "medialive.eu-west-2.amazonaws.com",
      "ap-northeast-3": "medialive.ap-northeast-3.amazonaws.com",
      "eu-central-1": "medialive.eu-central-1.amazonaws.com",
      "us-east-2": "medialive.us-east-2.amazonaws.com",
      "us-east-1": "medialive.us-east-1.amazonaws.com",
      "cn-northwest-1": "medialive.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "medialive.ap-south-1.amazonaws.com",
      "eu-north-1": "medialive.eu-north-1.amazonaws.com",
      "ap-northeast-2": "medialive.ap-northeast-2.amazonaws.com",
      "us-west-1": "medialive.us-west-1.amazonaws.com",
      "us-gov-east-1": "medialive.us-gov-east-1.amazonaws.com",
      "eu-west-3": "medialive.eu-west-3.amazonaws.com",
      "cn-north-1": "medialive.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "medialive.sa-east-1.amazonaws.com",
      "eu-west-1": "medialive.eu-west-1.amazonaws.com",
      "us-gov-west-1": "medialive.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "medialive.ap-southeast-2.amazonaws.com",
      "ca-central-1": "medialive.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "medialive"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_BatchUpdateSchedule_402656492 = ref object of OpenApiRestCall_402656044
proc url_BatchUpdateSchedule_402656494(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
                 (kind: VariableSegment, value: "channelId"),
                 (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchUpdateSchedule_402656493(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update a channel schedule
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
                                 ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `channelId` field"
  var valid_402656495 = path.getOrDefault("channelId")
  valid_402656495 = validateParameter(valid_402656495, JString, required = true,
                                      default = nil)
  if valid_402656495 != nil:
    section.add "channelId", valid_402656495
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
  var valid_402656496 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Security-Token", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Signature")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Signature", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Algorithm", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Date")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Date", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Credential")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Credential", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656502
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

proc call*(call_402656504: Call_BatchUpdateSchedule_402656492;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a channel schedule
                                                                                         ## 
  let valid = call_402656504.validator(path, query, header, formData, body, _)
  let scheme = call_402656504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656504.makeUrl(scheme.get, call_402656504.host, call_402656504.base,
                                   call_402656504.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656504, uri, valid, _)

proc call*(call_402656505: Call_BatchUpdateSchedule_402656492;
           channelId: string; body: JsonNode): Recallable =
  ## batchUpdateSchedule
  ## Update a channel schedule
  ##   channelId: string (required)
                              ##            : Placeholder documentation for __string
  ##   
                                                                                    ## body: JObject (required)
  var path_402656506 = newJObject()
  var body_402656507 = newJObject()
  add(path_402656506, "channelId", newJString(channelId))
  if body != nil:
    body_402656507 = body
  result = call_402656505.call(path_402656506, nil, nil, nil, body_402656507)

var batchUpdateSchedule* = Call_BatchUpdateSchedule_402656492(
    name: "batchUpdateSchedule", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_BatchUpdateSchedule_402656493, base: "/",
    makeUrl: url_BatchUpdateSchedule_402656494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchedule_402656294 = ref object of OpenApiRestCall_402656044
proc url_DescribeSchedule_402656296(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
                 (kind: VariableSegment, value: "channelId"),
                 (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeSchedule_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get a channel schedule
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
                                 ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `channelId` field"
  var valid_402656389 = path.getOrDefault("channelId")
  valid_402656389 = validateParameter(valid_402656389, JString, required = true,
                                      default = nil)
  if valid_402656389 != nil:
    section.add "channelId", valid_402656389
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Placeholder documentation for MaxResults
  ##   
                                                                                           ## nextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Placeholder 
                                                                                           ## documentation 
                                                                                           ## for 
                                                                                           ## __string
  ##   
                                                                                                      ## MaxResults: JString
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## Pagination 
                                                                                                      ## limit
  ##   
                                                                                                              ## NextToken: JString
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## Pagination 
                                                                                                              ## token
  section = newJObject()
  var valid_402656390 = query.getOrDefault("maxResults")
  valid_402656390 = validateParameter(valid_402656390, JInt, required = false,
                                      default = nil)
  if valid_402656390 != nil:
    section.add "maxResults", valid_402656390
  var valid_402656391 = query.getOrDefault("nextToken")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "nextToken", valid_402656391
  var valid_402656392 = query.getOrDefault("MaxResults")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "MaxResults", valid_402656392
  var valid_402656393 = query.getOrDefault("NextToken")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "NextToken", valid_402656393
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
  var valid_402656394 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Security-Token", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Signature")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Signature", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-Algorithm", valid_402656397
  var valid_402656398 = header.getOrDefault("X-Amz-Date")
  valid_402656398 = validateParameter(valid_402656398, JString,
                                      required = false, default = nil)
  if valid_402656398 != nil:
    section.add "X-Amz-Date", valid_402656398
  var valid_402656399 = header.getOrDefault("X-Amz-Credential")
  valid_402656399 = validateParameter(valid_402656399, JString,
                                      required = false, default = nil)
  if valid_402656399 != nil:
    section.add "X-Amz-Credential", valid_402656399
  var valid_402656400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656400 = validateParameter(valid_402656400, JString,
                                      required = false, default = nil)
  if valid_402656400 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656414: Call_DescribeSchedule_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get a channel schedule
                                                                                         ## 
  let valid = call_402656414.validator(path, query, header, formData, body, _)
  let scheme = call_402656414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656414.makeUrl(scheme.get, call_402656414.host, call_402656414.base,
                                   call_402656414.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656414, uri, valid, _)

proc call*(call_402656463: Call_DescribeSchedule_402656294; channelId: string;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## describeSchedule
  ## Get a channel schedule
  ##   channelId: string (required)
                           ##            : Placeholder documentation for __string
  ##   
                                                                                 ## maxResults: int
                                                                                 ##             
                                                                                 ## : 
                                                                                 ## Placeholder 
                                                                                 ## documentation 
                                                                                 ## for 
                                                                                 ## MaxResults
  ##   
                                                                                              ## nextToken: string
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## Placeholder 
                                                                                              ## documentation 
                                                                                              ## for 
                                                                                              ## __string
  ##   
                                                                                                         ## MaxResults: string
                                                                                                         ##             
                                                                                                         ## : 
                                                                                                         ## Pagination 
                                                                                                         ## limit
  ##   
                                                                                                                 ## NextToken: string
                                                                                                                 ##            
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## token
  var path_402656464 = newJObject()
  var query_402656466 = newJObject()
  add(path_402656464, "channelId", newJString(channelId))
  add(query_402656466, "maxResults", newJInt(maxResults))
  add(query_402656466, "nextToken", newJString(nextToken))
  add(query_402656466, "MaxResults", newJString(MaxResults))
  add(query_402656466, "NextToken", newJString(NextToken))
  result = call_402656463.call(path_402656464, query_402656466, nil, nil, nil)

var describeSchedule* = Call_DescribeSchedule_402656294(
    name: "describeSchedule", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DescribeSchedule_402656295, base: "/",
    makeUrl: url_DescribeSchedule_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchedule_402656508 = ref object of OpenApiRestCall_402656044
proc url_DeleteSchedule_402656510(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
                 (kind: VariableSegment, value: "channelId"),
                 (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSchedule_402656509(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete all schedule actions on a channel.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
                                 ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `channelId` field"
  var valid_402656511 = path.getOrDefault("channelId")
  valid_402656511 = validateParameter(valid_402656511, JString, required = true,
                                      default = nil)
  if valid_402656511 != nil:
    section.add "channelId", valid_402656511
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
  var valid_402656512 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Security-Token", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Signature")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Signature", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Algorithm", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Date")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Date", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Credential")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Credential", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656519: Call_DeleteSchedule_402656508; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete all schedule actions on a channel.
                                                                                         ## 
  let valid = call_402656519.validator(path, query, header, formData, body, _)
  let scheme = call_402656519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656519.makeUrl(scheme.get, call_402656519.host, call_402656519.base,
                                   call_402656519.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656519, uri, valid, _)

proc call*(call_402656520: Call_DeleteSchedule_402656508; channelId: string): Recallable =
  ## deleteSchedule
  ## Delete all schedule actions on a channel.
  ##   channelId: string (required)
                                              ##            : Placeholder documentation for __string
  var path_402656521 = newJObject()
  add(path_402656521, "channelId", newJString(channelId))
  result = call_402656520.call(path_402656521, nil, nil, nil, nil)

var deleteSchedule* = Call_DeleteSchedule_402656508(name: "deleteSchedule",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DeleteSchedule_402656509, base: "/",
    makeUrl: url_DeleteSchedule_402656510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_402656539 = ref object of OpenApiRestCall_402656044
proc url_CreateChannel_402656541(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateChannel_402656540(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new channel
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
  var valid_402656542 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Security-Token", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Signature")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Signature", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Algorithm", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Date")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Date", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Credential")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Credential", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656548
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

proc call*(call_402656550: Call_CreateChannel_402656539; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new channel
                                                                                         ## 
  let valid = call_402656550.validator(path, query, header, formData, body, _)
  let scheme = call_402656550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656550.makeUrl(scheme.get, call_402656550.host, call_402656550.base,
                                   call_402656550.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656550, uri, valid, _)

proc call*(call_402656551: Call_CreateChannel_402656539; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new channel
  ##   body: JObject (required)
  var body_402656552 = newJObject()
  if body != nil:
    body_402656552 = body
  result = call_402656551.call(nil, nil, nil, nil, body_402656552)

var createChannel* = Call_CreateChannel_402656539(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_CreateChannel_402656540,
    base: "/", makeUrl: url_CreateChannel_402656541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_402656522 = ref object of OpenApiRestCall_402656044
proc url_ListChannels_402656524(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChannels_402656523(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Produces list of channels that have been created
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Placeholder documentation for MaxResults
  ##   
                                                                                           ## nextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Placeholder 
                                                                                           ## documentation 
                                                                                           ## for 
                                                                                           ## __string
  ##   
                                                                                                      ## MaxResults: JString
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## Pagination 
                                                                                                      ## limit
  ##   
                                                                                                              ## NextToken: JString
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## Pagination 
                                                                                                              ## token
  section = newJObject()
  var valid_402656525 = query.getOrDefault("maxResults")
  valid_402656525 = validateParameter(valid_402656525, JInt, required = false,
                                      default = nil)
  if valid_402656525 != nil:
    section.add "maxResults", valid_402656525
  var valid_402656526 = query.getOrDefault("nextToken")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "nextToken", valid_402656526
  var valid_402656527 = query.getOrDefault("MaxResults")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "MaxResults", valid_402656527
  var valid_402656528 = query.getOrDefault("NextToken")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "NextToken", valid_402656528
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
  var valid_402656529 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Security-Token", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Signature")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Signature", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Algorithm", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Date")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Date", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Credential")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Credential", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656536: Call_ListChannels_402656522; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces list of channels that have been created
                                                                                         ## 
  let valid = call_402656536.validator(path, query, header, formData, body, _)
  let scheme = call_402656536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656536.makeUrl(scheme.get, call_402656536.host, call_402656536.base,
                                   call_402656536.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656536, uri, valid, _)

proc call*(call_402656537: Call_ListChannels_402656522; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listChannels
  ## Produces list of channels that have been created
  ##   maxResults: int
                                                     ##             : Placeholder documentation for MaxResults
  ##   
                                                                                                              ## nextToken: string
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## Placeholder 
                                                                                                              ## documentation 
                                                                                                              ## for 
                                                                                                              ## __string
  ##   
                                                                                                                         ## MaxResults: string
                                                                                                                         ##             
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## limit
  ##   
                                                                                                                                 ## NextToken: string
                                                                                                                                 ##            
                                                                                                                                 ## : 
                                                                                                                                 ## Pagination 
                                                                                                                                 ## token
  var query_402656538 = newJObject()
  add(query_402656538, "maxResults", newJInt(maxResults))
  add(query_402656538, "nextToken", newJString(nextToken))
  add(query_402656538, "MaxResults", newJString(MaxResults))
  add(query_402656538, "NextToken", newJString(NextToken))
  result = call_402656537.call(nil, query_402656538, nil, nil, nil)

var listChannels* = Call_ListChannels_402656522(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_ListChannels_402656523,
    base: "/", makeUrl: url_ListChannels_402656524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_402656570 = ref object of OpenApiRestCall_402656044
proc url_CreateInput_402656572(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInput_402656571(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create an input
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
  var valid_402656573 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Security-Token", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Signature")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Signature", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Algorithm", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Date")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Date", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Credential")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Credential", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656579
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

proc call*(call_402656581: Call_CreateInput_402656570; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create an input
                                                                                         ## 
  let valid = call_402656581.validator(path, query, header, formData, body, _)
  let scheme = call_402656581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656581.makeUrl(scheme.get, call_402656581.host, call_402656581.base,
                                   call_402656581.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656581, uri, valid, _)

proc call*(call_402656582: Call_CreateInput_402656570; body: JsonNode): Recallable =
  ## createInput
  ## Create an input
  ##   body: JObject (required)
  var body_402656583 = newJObject()
  if body != nil:
    body_402656583 = body
  result = call_402656582.call(nil, nil, nil, nil, body_402656583)

var createInput* = Call_CreateInput_402656570(name: "createInput",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/inputs", validator: validate_CreateInput_402656571, base: "/",
    makeUrl: url_CreateInput_402656572, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_402656553 = ref object of OpenApiRestCall_402656044
proc url_ListInputs_402656555(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputs_402656554(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Produces list of inputs that have been created
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Placeholder documentation for MaxResults
  ##   
                                                                                           ## nextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Placeholder 
                                                                                           ## documentation 
                                                                                           ## for 
                                                                                           ## __string
  ##   
                                                                                                      ## MaxResults: JString
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## Pagination 
                                                                                                      ## limit
  ##   
                                                                                                              ## NextToken: JString
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## Pagination 
                                                                                                              ## token
  section = newJObject()
  var valid_402656556 = query.getOrDefault("maxResults")
  valid_402656556 = validateParameter(valid_402656556, JInt, required = false,
                                      default = nil)
  if valid_402656556 != nil:
    section.add "maxResults", valid_402656556
  var valid_402656557 = query.getOrDefault("nextToken")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "nextToken", valid_402656557
  var valid_402656558 = query.getOrDefault("MaxResults")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "MaxResults", valid_402656558
  var valid_402656559 = query.getOrDefault("NextToken")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "NextToken", valid_402656559
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
  var valid_402656560 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Security-Token", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Signature")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Signature", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Algorithm", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Date")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Date", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Credential")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Credential", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656567: Call_ListInputs_402656553; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces list of inputs that have been created
                                                                                         ## 
  let valid = call_402656567.validator(path, query, header, formData, body, _)
  let scheme = call_402656567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656567.makeUrl(scheme.get, call_402656567.host, call_402656567.base,
                                   call_402656567.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656567, uri, valid, _)

proc call*(call_402656568: Call_ListInputs_402656553; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listInputs
  ## Produces list of inputs that have been created
  ##   maxResults: int
                                                   ##             : Placeholder documentation for MaxResults
  ##   
                                                                                                            ## nextToken: string
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## Placeholder 
                                                                                                            ## documentation 
                                                                                                            ## for 
                                                                                                            ## __string
  ##   
                                                                                                                       ## MaxResults: string
                                                                                                                       ##             
                                                                                                                       ## : 
                                                                                                                       ## Pagination 
                                                                                                                       ## limit
  ##   
                                                                                                                               ## NextToken: string
                                                                                                                               ##            
                                                                                                                               ## : 
                                                                                                                               ## Pagination 
                                                                                                                               ## token
  var query_402656569 = newJObject()
  add(query_402656569, "maxResults", newJInt(maxResults))
  add(query_402656569, "nextToken", newJString(nextToken))
  add(query_402656569, "MaxResults", newJString(MaxResults))
  add(query_402656569, "NextToken", newJString(NextToken))
  result = call_402656568.call(nil, query_402656569, nil, nil, nil)

var listInputs* = Call_ListInputs_402656553(name: "listInputs",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/inputs", validator: validate_ListInputs_402656554, base: "/",
    makeUrl: url_ListInputs_402656555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInputSecurityGroup_402656601 = ref object of OpenApiRestCall_402656044
proc url_CreateInputSecurityGroup_402656603(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInputSecurityGroup_402656602(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a Input Security Group
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
  var valid_402656604 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Security-Token", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Signature")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Signature", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Algorithm", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Date")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Date", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Credential")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Credential", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656610
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

proc call*(call_402656612: Call_CreateInputSecurityGroup_402656601;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Input Security Group
                                                                                         ## 
  let valid = call_402656612.validator(path, query, header, formData, body, _)
  let scheme = call_402656612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656612.makeUrl(scheme.get, call_402656612.host, call_402656612.base,
                                   call_402656612.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656612, uri, valid, _)

proc call*(call_402656613: Call_CreateInputSecurityGroup_402656601;
           body: JsonNode): Recallable =
  ## createInputSecurityGroup
  ## Creates a Input Security Group
  ##   body: JObject (required)
  var body_402656614 = newJObject()
  if body != nil:
    body_402656614 = body
  result = call_402656613.call(nil, nil, nil, nil, body_402656614)

var createInputSecurityGroup* = Call_CreateInputSecurityGroup_402656601(
    name: "createInputSecurityGroup", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_CreateInputSecurityGroup_402656602, base: "/",
    makeUrl: url_CreateInputSecurityGroup_402656603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputSecurityGroups_402656584 = ref object of OpenApiRestCall_402656044
proc url_ListInputSecurityGroups_402656586(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputSecurityGroups_402656585(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Produces a list of Input Security Groups for an account
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Placeholder documentation for MaxResults
  ##   
                                                                                           ## nextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Placeholder 
                                                                                           ## documentation 
                                                                                           ## for 
                                                                                           ## __string
  ##   
                                                                                                      ## MaxResults: JString
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## Pagination 
                                                                                                      ## limit
  ##   
                                                                                                              ## NextToken: JString
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## Pagination 
                                                                                                              ## token
  section = newJObject()
  var valid_402656587 = query.getOrDefault("maxResults")
  valid_402656587 = validateParameter(valid_402656587, JInt, required = false,
                                      default = nil)
  if valid_402656587 != nil:
    section.add "maxResults", valid_402656587
  var valid_402656588 = query.getOrDefault("nextToken")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "nextToken", valid_402656588
  var valid_402656589 = query.getOrDefault("MaxResults")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "MaxResults", valid_402656589
  var valid_402656590 = query.getOrDefault("NextToken")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "NextToken", valid_402656590
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
  var valid_402656591 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Security-Token", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Signature")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Signature", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Algorithm", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Date")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Date", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Credential")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Credential", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656598: Call_ListInputSecurityGroups_402656584;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces a list of Input Security Groups for an account
                                                                                         ## 
  let valid = call_402656598.validator(path, query, header, formData, body, _)
  let scheme = call_402656598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656598.makeUrl(scheme.get, call_402656598.host, call_402656598.base,
                                   call_402656598.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656598, uri, valid, _)

proc call*(call_402656599: Call_ListInputSecurityGroups_402656584;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listInputSecurityGroups
  ## Produces a list of Input Security Groups for an account
  ##   maxResults: int
                                                            ##             : Placeholder documentation for MaxResults
  ##   
                                                                                                                     ## nextToken: string
                                                                                                                     ##            
                                                                                                                     ## : 
                                                                                                                     ## Placeholder 
                                                                                                                     ## documentation 
                                                                                                                     ## for 
                                                                                                                     ## __string
  ##   
                                                                                                                                ## MaxResults: string
                                                                                                                                ##             
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## limit
  ##   
                                                                                                                                        ## NextToken: string
                                                                                                                                        ##            
                                                                                                                                        ## : 
                                                                                                                                        ## Pagination 
                                                                                                                                        ## token
  var query_402656600 = newJObject()
  add(query_402656600, "maxResults", newJInt(maxResults))
  add(query_402656600, "nextToken", newJString(nextToken))
  add(query_402656600, "MaxResults", newJString(MaxResults))
  add(query_402656600, "NextToken", newJString(NextToken))
  result = call_402656599.call(nil, query_402656600, nil, nil, nil)

var listInputSecurityGroups* = Call_ListInputSecurityGroups_402656584(
    name: "listInputSecurityGroups", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_ListInputSecurityGroups_402656585, base: "/",
    makeUrl: url_ListInputSecurityGroups_402656586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplex_402656632 = ref object of OpenApiRestCall_402656044
proc url_CreateMultiplex_402656634(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMultiplex_402656633(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new multiplex.
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
  var valid_402656635 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Security-Token", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Signature")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Signature", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Algorithm", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Date")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Date", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Credential")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Credential", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656641
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

proc call*(call_402656643: Call_CreateMultiplex_402656632; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new multiplex.
                                                                                         ## 
  let valid = call_402656643.validator(path, query, header, formData, body, _)
  let scheme = call_402656643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656643.makeUrl(scheme.get, call_402656643.host, call_402656643.base,
                                   call_402656643.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656643, uri, valid, _)

proc call*(call_402656644: Call_CreateMultiplex_402656632; body: JsonNode): Recallable =
  ## createMultiplex
  ## Create a new multiplex.
  ##   body: JObject (required)
  var body_402656645 = newJObject()
  if body != nil:
    body_402656645 = body
  result = call_402656644.call(nil, nil, nil, nil, body_402656645)

var createMultiplex* = Call_CreateMultiplex_402656632(name: "createMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_CreateMultiplex_402656633,
    base: "/", makeUrl: url_CreateMultiplex_402656634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexes_402656615 = ref object of OpenApiRestCall_402656044
proc url_ListMultiplexes_402656617(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMultiplexes_402656616(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve a list of the existing multiplexes.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Placeholder documentation for MaxResults
  ##   
                                                                                           ## nextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Placeholder 
                                                                                           ## documentation 
                                                                                           ## for 
                                                                                           ## __string
  ##   
                                                                                                      ## MaxResults: JString
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## Pagination 
                                                                                                      ## limit
  ##   
                                                                                                              ## NextToken: JString
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## Pagination 
                                                                                                              ## token
  section = newJObject()
  var valid_402656618 = query.getOrDefault("maxResults")
  valid_402656618 = validateParameter(valid_402656618, JInt, required = false,
                                      default = nil)
  if valid_402656618 != nil:
    section.add "maxResults", valid_402656618
  var valid_402656619 = query.getOrDefault("nextToken")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "nextToken", valid_402656619
  var valid_402656620 = query.getOrDefault("MaxResults")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "MaxResults", valid_402656620
  var valid_402656621 = query.getOrDefault("NextToken")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "NextToken", valid_402656621
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
  var valid_402656622 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Security-Token", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Signature")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Signature", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Algorithm", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Date")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Date", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Credential")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Credential", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656629: Call_ListMultiplexes_402656615; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a list of the existing multiplexes.
                                                                                         ## 
  let valid = call_402656629.validator(path, query, header, formData, body, _)
  let scheme = call_402656629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656629.makeUrl(scheme.get, call_402656629.host, call_402656629.base,
                                   call_402656629.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656629, uri, valid, _)

proc call*(call_402656630: Call_ListMultiplexes_402656615; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listMultiplexes
  ## Retrieve a list of the existing multiplexes.
  ##   maxResults: int
                                                 ##             : Placeholder documentation for MaxResults
  ##   
                                                                                                          ## nextToken: string
                                                                                                          ##            
                                                                                                          ## : 
                                                                                                          ## Placeholder 
                                                                                                          ## documentation 
                                                                                                          ## for 
                                                                                                          ## __string
  ##   
                                                                                                                     ## MaxResults: string
                                                                                                                     ##             
                                                                                                                     ## : 
                                                                                                                     ## Pagination 
                                                                                                                     ## limit
  ##   
                                                                                                                             ## NextToken: string
                                                                                                                             ##            
                                                                                                                             ## : 
                                                                                                                             ## Pagination 
                                                                                                                             ## token
  var query_402656631 = newJObject()
  add(query_402656631, "maxResults", newJInt(maxResults))
  add(query_402656631, "nextToken", newJString(nextToken))
  add(query_402656631, "MaxResults", newJString(MaxResults))
  add(query_402656631, "NextToken", newJString(NextToken))
  result = call_402656630.call(nil, query_402656631, nil, nil, nil)

var listMultiplexes* = Call_ListMultiplexes_402656615(name: "listMultiplexes",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_ListMultiplexes_402656616,
    base: "/", makeUrl: url_ListMultiplexes_402656617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplexProgram_402656665 = ref object of OpenApiRestCall_402656044
proc url_CreateMultiplexProgram_402656667(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
                 (kind: VariableSegment, value: "multiplexId"),
                 (kind: ConstantSegment, value: "/programs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateMultiplexProgram_402656666(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new program in the multiplex.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
                                 ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `multiplexId` field"
  var valid_402656668 = path.getOrDefault("multiplexId")
  valid_402656668 = validateParameter(valid_402656668, JString, required = true,
                                      default = nil)
  if valid_402656668 != nil:
    section.add "multiplexId", valid_402656668
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
  var valid_402656669 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Security-Token", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Signature")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Signature", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Algorithm", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Date")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Date", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Credential")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Credential", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656675
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

proc call*(call_402656677: Call_CreateMultiplexProgram_402656665;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new program in the multiplex.
                                                                                         ## 
  let valid = call_402656677.validator(path, query, header, formData, body, _)
  let scheme = call_402656677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656677.makeUrl(scheme.get, call_402656677.host, call_402656677.base,
                                   call_402656677.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656677, uri, valid, _)

proc call*(call_402656678: Call_CreateMultiplexProgram_402656665;
           multiplexId: string; body: JsonNode): Recallable =
  ## createMultiplexProgram
  ## Create a new program in the multiplex.
  ##   multiplexId: string (required)
                                           ##              : Placeholder documentation for __string
  ##   
                                                                                                   ## body: JObject (required)
  var path_402656679 = newJObject()
  var body_402656680 = newJObject()
  add(path_402656679, "multiplexId", newJString(multiplexId))
  if body != nil:
    body_402656680 = body
  result = call_402656678.call(path_402656679, nil, nil, nil, body_402656680)

var createMultiplexProgram* = Call_CreateMultiplexProgram_402656665(
    name: "createMultiplexProgram", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_CreateMultiplexProgram_402656666, base: "/",
    makeUrl: url_CreateMultiplexProgram_402656667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexPrograms_402656646 = ref object of OpenApiRestCall_402656044
proc url_ListMultiplexPrograms_402656648(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
                 (kind: VariableSegment, value: "multiplexId"),
                 (kind: ConstantSegment, value: "/programs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListMultiplexPrograms_402656647(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the programs that currently exist for a specific multiplex.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
                                 ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `multiplexId` field"
  var valid_402656649 = path.getOrDefault("multiplexId")
  valid_402656649 = validateParameter(valid_402656649, JString, required = true,
                                      default = nil)
  if valid_402656649 != nil:
    section.add "multiplexId", valid_402656649
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Placeholder documentation for MaxResults
  ##   
                                                                                           ## nextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Placeholder 
                                                                                           ## documentation 
                                                                                           ## for 
                                                                                           ## __string
  ##   
                                                                                                      ## MaxResults: JString
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## Pagination 
                                                                                                      ## limit
  ##   
                                                                                                              ## NextToken: JString
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## Pagination 
                                                                                                              ## token
  section = newJObject()
  var valid_402656650 = query.getOrDefault("maxResults")
  valid_402656650 = validateParameter(valid_402656650, JInt, required = false,
                                      default = nil)
  if valid_402656650 != nil:
    section.add "maxResults", valid_402656650
  var valid_402656651 = query.getOrDefault("nextToken")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "nextToken", valid_402656651
  var valid_402656652 = query.getOrDefault("MaxResults")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "MaxResults", valid_402656652
  var valid_402656653 = query.getOrDefault("NextToken")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "NextToken", valid_402656653
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
  var valid_402656654 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Security-Token", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Signature")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Signature", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Algorithm", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Date")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Date", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Credential")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Credential", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656661: Call_ListMultiplexPrograms_402656646;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the programs that currently exist for a specific multiplex.
                                                                                         ## 
  let valid = call_402656661.validator(path, query, header, formData, body, _)
  let scheme = call_402656661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656661.makeUrl(scheme.get, call_402656661.host, call_402656661.base,
                                   call_402656661.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656661, uri, valid, _)

proc call*(call_402656662: Call_ListMultiplexPrograms_402656646;
           multiplexId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMultiplexPrograms
  ## List the programs that currently exist for a specific multiplex.
  ##   maxResults: int
                                                                     ##             : Placeholder documentation for MaxResults
  ##   
                                                                                                                              ## multiplexId: string (required)
                                                                                                                              ##              
                                                                                                                              ## : 
                                                                                                                              ## Placeholder 
                                                                                                                              ## documentation 
                                                                                                                              ## for 
                                                                                                                              ## __string
  ##   
                                                                                                                                         ## nextToken: string
                                                                                                                                         ##            
                                                                                                                                         ## : 
                                                                                                                                         ## Placeholder 
                                                                                                                                         ## documentation 
                                                                                                                                         ## for 
                                                                                                                                         ## __string
  ##   
                                                                                                                                                    ## MaxResults: string
                                                                                                                                                    ##             
                                                                                                                                                    ## : 
                                                                                                                                                    ## Pagination 
                                                                                                                                                    ## limit
  ##   
                                                                                                                                                            ## NextToken: string
                                                                                                                                                            ##            
                                                                                                                                                            ## : 
                                                                                                                                                            ## Pagination 
                                                                                                                                                            ## token
  var path_402656663 = newJObject()
  var query_402656664 = newJObject()
  add(query_402656664, "maxResults", newJInt(maxResults))
  add(path_402656663, "multiplexId", newJString(multiplexId))
  add(query_402656664, "nextToken", newJString(nextToken))
  add(query_402656664, "MaxResults", newJString(MaxResults))
  add(query_402656664, "NextToken", newJString(NextToken))
  result = call_402656662.call(path_402656663, query_402656664, nil, nil, nil)

var listMultiplexPrograms* = Call_ListMultiplexPrograms_402656646(
    name: "listMultiplexPrograms", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_ListMultiplexPrograms_402656647, base: "/",
    makeUrl: url_ListMultiplexPrograms_402656648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_402656695 = ref object of OpenApiRestCall_402656044
proc url_CreateTags_402656697(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
                 (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTags_402656696(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create tags for a resource
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
                                 ##               : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656698 = path.getOrDefault("resource-arn")
  valid_402656698 = validateParameter(valid_402656698, JString, required = true,
                                      default = nil)
  if valid_402656698 != nil:
    section.add "resource-arn", valid_402656698
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
  var valid_402656699 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Security-Token", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Signature")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Signature", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Algorithm", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Date")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Date", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Credential")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Credential", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656705
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

proc call*(call_402656707: Call_CreateTags_402656695; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create tags for a resource
                                                                                         ## 
  let valid = call_402656707.validator(path, query, header, formData, body, _)
  let scheme = call_402656707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656707.makeUrl(scheme.get, call_402656707.host, call_402656707.base,
                                   call_402656707.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656707, uri, valid, _)

proc call*(call_402656708: Call_CreateTags_402656695; body: JsonNode;
           resourceArn: string): Recallable =
  ## createTags
  ## Create tags for a resource
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              : Placeholder documentation for __string
  var path_402656709 = newJObject()
  var body_402656710 = newJObject()
  if body != nil:
    body_402656710 = body
  add(path_402656709, "resource-arn", newJString(resourceArn))
  result = call_402656708.call(path_402656709, nil, nil, nil, body_402656710)

var createTags* = Call_CreateTags_402656695(name: "createTags",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/tags/{resource-arn}", validator: validate_CreateTags_402656696,
    base: "/", makeUrl: url_CreateTags_402656697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656681 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656683(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
                 (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656682(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Produces list of tags that have been created for a resource
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
                                 ##               : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656684 = path.getOrDefault("resource-arn")
  valid_402656684 = validateParameter(valid_402656684, JString, required = true,
                                      default = nil)
  if valid_402656684 != nil:
    section.add "resource-arn", valid_402656684
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
  var valid_402656685 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Security-Token", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Signature")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Signature", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Algorithm", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Date")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Date", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Credential")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Credential", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656692: Call_ListTagsForResource_402656681;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces list of tags that have been created for a resource
                                                                                         ## 
  let valid = call_402656692.validator(path, query, header, formData, body, _)
  let scheme = call_402656692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656692.makeUrl(scheme.get, call_402656692.host, call_402656692.base,
                                   call_402656692.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656692, uri, valid, _)

proc call*(call_402656693: Call_ListTagsForResource_402656681;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Produces list of tags that have been created for a resource
  ##   resourceArn: string (required)
                                                                ##              : Placeholder documentation for __string
  var path_402656694 = newJObject()
  add(path_402656694, "resource-arn", newJString(resourceArn))
  result = call_402656693.call(path_402656694, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656681(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}",
    validator: validate_ListTagsForResource_402656682, base: "/",
    makeUrl: url_ListTagsForResource_402656683,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_402656725 = ref object of OpenApiRestCall_402656044
proc url_UpdateChannel_402656727(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
                 (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateChannel_402656726(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a channel.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
                                 ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `channelId` field"
  var valid_402656728 = path.getOrDefault("channelId")
  valid_402656728 = validateParameter(valid_402656728, JString, required = true,
                                      default = nil)
  if valid_402656728 != nil:
    section.add "channelId", valid_402656728
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
  var valid_402656729 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Security-Token", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Signature")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Signature", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Algorithm", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Date")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Date", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Credential")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Credential", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656735
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

proc call*(call_402656737: Call_UpdateChannel_402656725; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a channel.
                                                                                         ## 
  let valid = call_402656737.validator(path, query, header, formData, body, _)
  let scheme = call_402656737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656737.makeUrl(scheme.get, call_402656737.host, call_402656737.base,
                                   call_402656737.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656737, uri, valid, _)

proc call*(call_402656738: Call_UpdateChannel_402656725; channelId: string;
           body: JsonNode): Recallable =
  ## updateChannel
  ## Updates a channel.
  ##   channelId: string (required)
                       ##            : Placeholder documentation for __string
  ##   
                                                                             ## body: JObject (required)
  var path_402656739 = newJObject()
  var body_402656740 = newJObject()
  add(path_402656739, "channelId", newJString(channelId))
  if body != nil:
    body_402656740 = body
  result = call_402656738.call(path_402656739, nil, nil, nil, body_402656740)

var updateChannel* = Call_UpdateChannel_402656725(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_UpdateChannel_402656726,
    base: "/", makeUrl: url_UpdateChannel_402656727,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_402656711 = ref object of OpenApiRestCall_402656044
proc url_DescribeChannel_402656713(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
                 (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeChannel_402656712(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details about a channel
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
                                 ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `channelId` field"
  var valid_402656714 = path.getOrDefault("channelId")
  valid_402656714 = validateParameter(valid_402656714, JString, required = true,
                                      default = nil)
  if valid_402656714 != nil:
    section.add "channelId", valid_402656714
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
  var valid_402656715 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Security-Token", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Signature")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Signature", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Algorithm", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Date")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Date", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Credential")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Credential", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656722: Call_DescribeChannel_402656711; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about a channel
                                                                                         ## 
  let valid = call_402656722.validator(path, query, header, formData, body, _)
  let scheme = call_402656722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656722.makeUrl(scheme.get, call_402656722.host, call_402656722.base,
                                   call_402656722.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656722, uri, valid, _)

proc call*(call_402656723: Call_DescribeChannel_402656711; channelId: string): Recallable =
  ## describeChannel
  ## Gets details about a channel
  ##   channelId: string (required)
                                 ##            : Placeholder documentation for __string
  var path_402656724 = newJObject()
  add(path_402656724, "channelId", newJString(channelId))
  result = call_402656723.call(path_402656724, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_402656711(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DescribeChannel_402656712,
    base: "/", makeUrl: url_DescribeChannel_402656713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_402656741 = ref object of OpenApiRestCall_402656044
proc url_DeleteChannel_402656743(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
                 (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteChannel_402656742(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts deletion of channel. The associated outputs are also deleted.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
                                 ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `channelId` field"
  var valid_402656744 = path.getOrDefault("channelId")
  valid_402656744 = validateParameter(valid_402656744, JString, required = true,
                                      default = nil)
  if valid_402656744 != nil:
    section.add "channelId", valid_402656744
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
  var valid_402656745 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Security-Token", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Signature")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Signature", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Algorithm", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Date")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Date", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Credential")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Credential", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656752: Call_DeleteChannel_402656741; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts deletion of channel. The associated outputs are also deleted.
                                                                                         ## 
  let valid = call_402656752.validator(path, query, header, formData, body, _)
  let scheme = call_402656752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656752.makeUrl(scheme.get, call_402656752.host, call_402656752.base,
                                   call_402656752.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656752, uri, valid, _)

proc call*(call_402656753: Call_DeleteChannel_402656741; channelId: string): Recallable =
  ## deleteChannel
  ## Starts deletion of channel. The associated outputs are also deleted.
  ##   
                                                                         ## channelId: string (required)
                                                                         ##            
                                                                         ## : 
                                                                         ## Placeholder 
                                                                         ## documentation 
                                                                         ## for 
                                                                         ## __string
  var path_402656754 = newJObject()
  add(path_402656754, "channelId", newJString(channelId))
  result = call_402656753.call(path_402656754, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_402656741(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DeleteChannel_402656742,
    base: "/", makeUrl: url_DeleteChannel_402656743,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_402656769 = ref object of OpenApiRestCall_402656044
proc url_UpdateInput_402656771(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
                 (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInput_402656770(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an input.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
                                 ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `inputId` field"
  var valid_402656772 = path.getOrDefault("inputId")
  valid_402656772 = validateParameter(valid_402656772, JString, required = true,
                                      default = nil)
  if valid_402656772 != nil:
    section.add "inputId", valid_402656772
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
  var valid_402656773 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Security-Token", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Signature")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Signature", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Algorithm", valid_402656776
  var valid_402656777 = header.getOrDefault("X-Amz-Date")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Date", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Credential")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Credential", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656779
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

proc call*(call_402656781: Call_UpdateInput_402656769; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an input.
                                                                                         ## 
  let valid = call_402656781.validator(path, query, header, formData, body, _)
  let scheme = call_402656781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656781.makeUrl(scheme.get, call_402656781.host, call_402656781.base,
                                   call_402656781.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656781, uri, valid, _)

proc call*(call_402656782: Call_UpdateInput_402656769; inputId: string;
           body: JsonNode): Recallable =
  ## updateInput
  ## Updates an input.
  ##   inputId: string (required)
                      ##          : Placeholder documentation for __string
  ##   body: 
                                                                          ## JObject (required)
  var path_402656783 = newJObject()
  var body_402656784 = newJObject()
  add(path_402656783, "inputId", newJString(inputId))
  if body != nil:
    body_402656784 = body
  result = call_402656782.call(path_402656783, nil, nil, nil, body_402656784)

var updateInput* = Call_UpdateInput_402656769(name: "updateInput",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_UpdateInput_402656770,
    base: "/", makeUrl: url_UpdateInput_402656771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_402656755 = ref object of OpenApiRestCall_402656044
proc url_DescribeInput_402656757(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
                 (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeInput_402656756(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Produces details about an input
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
                                 ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `inputId` field"
  var valid_402656758 = path.getOrDefault("inputId")
  valid_402656758 = validateParameter(valid_402656758, JString, required = true,
                                      default = nil)
  if valid_402656758 != nil:
    section.add "inputId", valid_402656758
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
  var valid_402656759 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Security-Token", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-Signature")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-Signature", valid_402656760
  var valid_402656761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Algorithm", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Date")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Date", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Credential")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Credential", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656766: Call_DescribeInput_402656755; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces details about an input
                                                                                         ## 
  let valid = call_402656766.validator(path, query, header, formData, body, _)
  let scheme = call_402656766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656766.makeUrl(scheme.get, call_402656766.host, call_402656766.base,
                                   call_402656766.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656766, uri, valid, _)

proc call*(call_402656767: Call_DescribeInput_402656755; inputId: string): Recallable =
  ## describeInput
  ## Produces details about an input
  ##   inputId: string (required)
                                    ##          : Placeholder documentation for __string
  var path_402656768 = newJObject()
  add(path_402656768, "inputId", newJString(inputId))
  result = call_402656767.call(path_402656768, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_402656755(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_DescribeInput_402656756,
    base: "/", makeUrl: url_DescribeInput_402656757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_402656785 = ref object of OpenApiRestCall_402656044
proc url_DeleteInput_402656787(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
                 (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInput_402656786(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the input end point
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
                                 ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `inputId` field"
  var valid_402656788 = path.getOrDefault("inputId")
  valid_402656788 = validateParameter(valid_402656788, JString, required = true,
                                      default = nil)
  if valid_402656788 != nil:
    section.add "inputId", valid_402656788
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
  var valid_402656789 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Security-Token", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-Signature")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Signature", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Algorithm", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Date")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Date", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Credential")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Credential", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656796: Call_DeleteInput_402656785; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the input end point
                                                                                         ## 
  let valid = call_402656796.validator(path, query, header, formData, body, _)
  let scheme = call_402656796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656796.makeUrl(scheme.get, call_402656796.host, call_402656796.base,
                                   call_402656796.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656796, uri, valid, _)

proc call*(call_402656797: Call_DeleteInput_402656785; inputId: string): Recallable =
  ## deleteInput
  ## Deletes the input end point
  ##   inputId: string (required)
                                ##          : Placeholder documentation for __string
  var path_402656798 = newJObject()
  add(path_402656798, "inputId", newJString(inputId))
  result = call_402656797.call(path_402656798, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_402656785(name: "deleteInput",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_DeleteInput_402656786,
    base: "/", makeUrl: url_DeleteInput_402656787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInputSecurityGroup_402656813 = ref object of OpenApiRestCall_402656044
proc url_UpdateInputSecurityGroup_402656815(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
         "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
                 (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInputSecurityGroup_402656814(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Update an Input Security Group's Whilelists.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
                                 ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_402656816 = path.getOrDefault("inputSecurityGroupId")
  valid_402656816 = validateParameter(valid_402656816, JString, required = true,
                                      default = nil)
  if valid_402656816 != nil:
    section.add "inputSecurityGroupId", valid_402656816
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
  var valid_402656817 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-Security-Token", valid_402656817
  var valid_402656818 = header.getOrDefault("X-Amz-Signature")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Signature", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Algorithm", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Date")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Date", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Credential")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Credential", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656823
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

proc call*(call_402656825: Call_UpdateInputSecurityGroup_402656813;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update an Input Security Group's Whilelists.
                                                                                         ## 
  let valid = call_402656825.validator(path, query, header, formData, body, _)
  let scheme = call_402656825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656825.makeUrl(scheme.get, call_402656825.host, call_402656825.base,
                                   call_402656825.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656825, uri, valid, _)

proc call*(call_402656826: Call_UpdateInputSecurityGroup_402656813;
           inputSecurityGroupId: string; body: JsonNode): Recallable =
  ## updateInputSecurityGroup
  ## Update an Input Security Group's Whilelists.
  ##   inputSecurityGroupId: string (required)
                                                 ##                       : Placeholder documentation for __string
  ##   
                                                                                                                  ## body: JObject (required)
  var path_402656827 = newJObject()
  var body_402656828 = newJObject()
  add(path_402656827, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  if body != nil:
    body_402656828 = body
  result = call_402656826.call(path_402656827, nil, nil, nil, body_402656828)

var updateInputSecurityGroup* = Call_UpdateInputSecurityGroup_402656813(
    name: "updateInputSecurityGroup", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_UpdateInputSecurityGroup_402656814, base: "/",
    makeUrl: url_UpdateInputSecurityGroup_402656815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInputSecurityGroup_402656799 = ref object of OpenApiRestCall_402656044
proc url_DescribeInputSecurityGroup_402656801(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
         "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
                 (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeInputSecurityGroup_402656800(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Produces a summary of an Input Security Group
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
                                 ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_402656802 = path.getOrDefault("inputSecurityGroupId")
  valid_402656802 = validateParameter(valid_402656802, JString, required = true,
                                      default = nil)
  if valid_402656802 != nil:
    section.add "inputSecurityGroupId", valid_402656802
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
  var valid_402656803 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Security-Token", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-Signature")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Signature", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Algorithm", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Date")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Date", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Credential")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Credential", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656810: Call_DescribeInputSecurityGroup_402656799;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces a summary of an Input Security Group
                                                                                         ## 
  let valid = call_402656810.validator(path, query, header, formData, body, _)
  let scheme = call_402656810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656810.makeUrl(scheme.get, call_402656810.host, call_402656810.base,
                                   call_402656810.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656810, uri, valid, _)

proc call*(call_402656811: Call_DescribeInputSecurityGroup_402656799;
           inputSecurityGroupId: string): Recallable =
  ## describeInputSecurityGroup
  ## Produces a summary of an Input Security Group
  ##   inputSecurityGroupId: string (required)
                                                  ##                       : Placeholder documentation for __string
  var path_402656812 = newJObject()
  add(path_402656812, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_402656811.call(path_402656812, nil, nil, nil, nil)

var describeInputSecurityGroup* = Call_DescribeInputSecurityGroup_402656799(
    name: "describeInputSecurityGroup", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DescribeInputSecurityGroup_402656800, base: "/",
    makeUrl: url_DescribeInputSecurityGroup_402656801,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInputSecurityGroup_402656829 = ref object of OpenApiRestCall_402656044
proc url_DeleteInputSecurityGroup_402656831(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
         "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
                 (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInputSecurityGroup_402656830(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes an Input Security Group
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
                                 ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_402656832 = path.getOrDefault("inputSecurityGroupId")
  valid_402656832 = validateParameter(valid_402656832, JString, required = true,
                                      default = nil)
  if valid_402656832 != nil:
    section.add "inputSecurityGroupId", valid_402656832
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
  var valid_402656833 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Security-Token", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-Signature")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Signature", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656835
  var valid_402656836 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "X-Amz-Algorithm", valid_402656836
  var valid_402656837 = header.getOrDefault("X-Amz-Date")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Date", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Credential")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Credential", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656840: Call_DeleteInputSecurityGroup_402656829;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Input Security Group
                                                                                         ## 
  let valid = call_402656840.validator(path, query, header, formData, body, _)
  let scheme = call_402656840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656840.makeUrl(scheme.get, call_402656840.host, call_402656840.base,
                                   call_402656840.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656840, uri, valid, _)

proc call*(call_402656841: Call_DeleteInputSecurityGroup_402656829;
           inputSecurityGroupId: string): Recallable =
  ## deleteInputSecurityGroup
  ## Deletes an Input Security Group
  ##   inputSecurityGroupId: string (required)
                                    ##                       : Placeholder documentation for __string
  var path_402656842 = newJObject()
  add(path_402656842, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_402656841.call(path_402656842, nil, nil, nil, nil)

var deleteInputSecurityGroup* = Call_DeleteInputSecurityGroup_402656829(
    name: "deleteInputSecurityGroup", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DeleteInputSecurityGroup_402656830, base: "/",
    makeUrl: url_DeleteInputSecurityGroup_402656831,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplex_402656857 = ref object of OpenApiRestCall_402656044
proc url_UpdateMultiplex_402656859(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
                 (kind: VariableSegment, value: "multiplexId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMultiplex_402656858(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a multiplex.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
                                 ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `multiplexId` field"
  var valid_402656860 = path.getOrDefault("multiplexId")
  valid_402656860 = validateParameter(valid_402656860, JString, required = true,
                                      default = nil)
  if valid_402656860 != nil:
    section.add "multiplexId", valid_402656860
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
  var valid_402656861 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Security-Token", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Signature")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Signature", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656863
  var valid_402656864 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656864 = validateParameter(valid_402656864, JString,
                                      required = false, default = nil)
  if valid_402656864 != nil:
    section.add "X-Amz-Algorithm", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-Date")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-Date", valid_402656865
  var valid_402656866 = header.getOrDefault("X-Amz-Credential")
  valid_402656866 = validateParameter(valid_402656866, JString,
                                      required = false, default = nil)
  if valid_402656866 != nil:
    section.add "X-Amz-Credential", valid_402656866
  var valid_402656867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656867 = validateParameter(valid_402656867, JString,
                                      required = false, default = nil)
  if valid_402656867 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656867
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

proc call*(call_402656869: Call_UpdateMultiplex_402656857; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a multiplex.
                                                                                         ## 
  let valid = call_402656869.validator(path, query, header, formData, body, _)
  let scheme = call_402656869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656869.makeUrl(scheme.get, call_402656869.host, call_402656869.base,
                                   call_402656869.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656869, uri, valid, _)

proc call*(call_402656870: Call_UpdateMultiplex_402656857; multiplexId: string;
           body: JsonNode): Recallable =
  ## updateMultiplex
  ## Updates a multiplex.
  ##   multiplexId: string (required)
                         ##              : Placeholder documentation for __string
  ##   
                                                                                 ## body: JObject (required)
  var path_402656871 = newJObject()
  var body_402656872 = newJObject()
  add(path_402656871, "multiplexId", newJString(multiplexId))
  if body != nil:
    body_402656872 = body
  result = call_402656870.call(path_402656871, nil, nil, nil, body_402656872)

var updateMultiplex* = Call_UpdateMultiplex_402656857(name: "updateMultiplex",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}",
    validator: validate_UpdateMultiplex_402656858, base: "/",
    makeUrl: url_UpdateMultiplex_402656859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplex_402656843 = ref object of OpenApiRestCall_402656044
proc url_DescribeMultiplex_402656845(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
                 (kind: VariableSegment, value: "multiplexId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeMultiplex_402656844(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details about a multiplex.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
                                 ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `multiplexId` field"
  var valid_402656846 = path.getOrDefault("multiplexId")
  valid_402656846 = validateParameter(valid_402656846, JString, required = true,
                                      default = nil)
  if valid_402656846 != nil:
    section.add "multiplexId", valid_402656846
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
  var valid_402656847 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Security-Token", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-Signature")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Signature", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-Algorithm", valid_402656850
  var valid_402656851 = header.getOrDefault("X-Amz-Date")
  valid_402656851 = validateParameter(valid_402656851, JString,
                                      required = false, default = nil)
  if valid_402656851 != nil:
    section.add "X-Amz-Date", valid_402656851
  var valid_402656852 = header.getOrDefault("X-Amz-Credential")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-Credential", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656854: Call_DescribeMultiplex_402656843;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about a multiplex.
                                                                                         ## 
  let valid = call_402656854.validator(path, query, header, formData, body, _)
  let scheme = call_402656854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656854.makeUrl(scheme.get, call_402656854.host, call_402656854.base,
                                   call_402656854.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656854, uri, valid, _)

proc call*(call_402656855: Call_DescribeMultiplex_402656843; multiplexId: string): Recallable =
  ## describeMultiplex
  ## Gets details about a multiplex.
  ##   multiplexId: string (required)
                                    ##              : Placeholder documentation for __string
  var path_402656856 = newJObject()
  add(path_402656856, "multiplexId", newJString(multiplexId))
  result = call_402656855.call(path_402656856, nil, nil, nil, nil)

var describeMultiplex* = Call_DescribeMultiplex_402656843(
    name: "describeMultiplex", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/multiplexes/{multiplexId}",
    validator: validate_DescribeMultiplex_402656844, base: "/",
    makeUrl: url_DescribeMultiplex_402656845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplex_402656873 = ref object of OpenApiRestCall_402656044
proc url_DeleteMultiplex_402656875(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
                 (kind: VariableSegment, value: "multiplexId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMultiplex_402656874(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a multiplex. The multiplex must be idle.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
                                 ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `multiplexId` field"
  var valid_402656876 = path.getOrDefault("multiplexId")
  valid_402656876 = validateParameter(valid_402656876, JString, required = true,
                                      default = nil)
  if valid_402656876 != nil:
    section.add "multiplexId", valid_402656876
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
  var valid_402656877 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-Security-Token", valid_402656877
  var valid_402656878 = header.getOrDefault("X-Amz-Signature")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-Signature", valid_402656878
  var valid_402656879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656879
  var valid_402656880 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "X-Amz-Algorithm", valid_402656880
  var valid_402656881 = header.getOrDefault("X-Amz-Date")
  valid_402656881 = validateParameter(valid_402656881, JString,
                                      required = false, default = nil)
  if valid_402656881 != nil:
    section.add "X-Amz-Date", valid_402656881
  var valid_402656882 = header.getOrDefault("X-Amz-Credential")
  valid_402656882 = validateParameter(valid_402656882, JString,
                                      required = false, default = nil)
  if valid_402656882 != nil:
    section.add "X-Amz-Credential", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656884: Call_DeleteMultiplex_402656873; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a multiplex. The multiplex must be idle.
                                                                                         ## 
  let valid = call_402656884.validator(path, query, header, formData, body, _)
  let scheme = call_402656884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656884.makeUrl(scheme.get, call_402656884.host, call_402656884.base,
                                   call_402656884.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656884, uri, valid, _)

proc call*(call_402656885: Call_DeleteMultiplex_402656873; multiplexId: string): Recallable =
  ## deleteMultiplex
  ## Delete a multiplex. The multiplex must be idle.
  ##   multiplexId: string (required)
                                                    ##              : Placeholder documentation for __string
  var path_402656886 = newJObject()
  add(path_402656886, "multiplexId", newJString(multiplexId))
  result = call_402656885.call(path_402656886, nil, nil, nil, nil)

var deleteMultiplex* = Call_DeleteMultiplex_402656873(name: "deleteMultiplex",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}",
    validator: validate_DeleteMultiplex_402656874, base: "/",
    makeUrl: url_DeleteMultiplex_402656875, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplexProgram_402656902 = ref object of OpenApiRestCall_402656044
proc url_UpdateMultiplexProgram_402656904(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  assert "programName" in path, "`programName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
                 (kind: VariableSegment, value: "multiplexId"),
                 (kind: ConstantSegment, value: "/programs/"),
                 (kind: VariableSegment, value: "programName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMultiplexProgram_402656903(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update a program in a multiplex.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
                                 ##              : Placeholder documentation for __string
  ##   
                                                                                         ## programName: JString (required)
                                                                                         ##              
                                                                                         ## : 
                                                                                         ## Placeholder 
                                                                                         ## documentation 
                                                                                         ## for 
                                                                                         ## __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `multiplexId` field"
  var valid_402656905 = path.getOrDefault("multiplexId")
  valid_402656905 = validateParameter(valid_402656905, JString, required = true,
                                      default = nil)
  if valid_402656905 != nil:
    section.add "multiplexId", valid_402656905
  var valid_402656906 = path.getOrDefault("programName")
  valid_402656906 = validateParameter(valid_402656906, JString, required = true,
                                      default = nil)
  if valid_402656906 != nil:
    section.add "programName", valid_402656906
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
  var valid_402656907 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-Security-Token", valid_402656907
  var valid_402656908 = header.getOrDefault("X-Amz-Signature")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-Signature", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-Algorithm", valid_402656910
  var valid_402656911 = header.getOrDefault("X-Amz-Date")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-Date", valid_402656911
  var valid_402656912 = header.getOrDefault("X-Amz-Credential")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-Credential", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656913
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

proc call*(call_402656915: Call_UpdateMultiplexProgram_402656902;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a program in a multiplex.
                                                                                         ## 
  let valid = call_402656915.validator(path, query, header, formData, body, _)
  let scheme = call_402656915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656915.makeUrl(scheme.get, call_402656915.host, call_402656915.base,
                                   call_402656915.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656915, uri, valid, _)

proc call*(call_402656916: Call_UpdateMultiplexProgram_402656902;
           multiplexId: string; body: JsonNode; programName: string): Recallable =
  ## updateMultiplexProgram
  ## Update a program in a multiplex.
  ##   multiplexId: string (required)
                                     ##              : Placeholder documentation for __string
  ##   
                                                                                             ## body: JObject (required)
  ##   
                                                                                                                        ## programName: string (required)
                                                                                                                        ##              
                                                                                                                        ## : 
                                                                                                                        ## Placeholder 
                                                                                                                        ## documentation 
                                                                                                                        ## for 
                                                                                                                        ## __string
  var path_402656917 = newJObject()
  var body_402656918 = newJObject()
  add(path_402656917, "multiplexId", newJString(multiplexId))
  if body != nil:
    body_402656918 = body
  add(path_402656917, "programName", newJString(programName))
  result = call_402656916.call(path_402656917, nil, nil, nil, body_402656918)

var updateMultiplexProgram* = Call_UpdateMultiplexProgram_402656902(
    name: "updateMultiplexProgram", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_UpdateMultiplexProgram_402656903, base: "/",
    makeUrl: url_UpdateMultiplexProgram_402656904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplexProgram_402656887 = ref object of OpenApiRestCall_402656044
proc url_DescribeMultiplexProgram_402656889(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  assert "programName" in path, "`programName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
                 (kind: VariableSegment, value: "multiplexId"),
                 (kind: ConstantSegment, value: "/programs/"),
                 (kind: VariableSegment, value: "programName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeMultiplexProgram_402656888(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the details for a program in a multiplex.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
                                 ##              : Placeholder documentation for __string
  ##   
                                                                                         ## programName: JString (required)
                                                                                         ##              
                                                                                         ## : 
                                                                                         ## Placeholder 
                                                                                         ## documentation 
                                                                                         ## for 
                                                                                         ## __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `multiplexId` field"
  var valid_402656890 = path.getOrDefault("multiplexId")
  valid_402656890 = validateParameter(valid_402656890, JString, required = true,
                                      default = nil)
  if valid_402656890 != nil:
    section.add "multiplexId", valid_402656890
  var valid_402656891 = path.getOrDefault("programName")
  valid_402656891 = validateParameter(valid_402656891, JString, required = true,
                                      default = nil)
  if valid_402656891 != nil:
    section.add "programName", valid_402656891
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
  var valid_402656892 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Security-Token", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-Signature")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-Signature", valid_402656893
  var valid_402656894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656894
  var valid_402656895 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-Algorithm", valid_402656895
  var valid_402656896 = header.getOrDefault("X-Amz-Date")
  valid_402656896 = validateParameter(valid_402656896, JString,
                                      required = false, default = nil)
  if valid_402656896 != nil:
    section.add "X-Amz-Date", valid_402656896
  var valid_402656897 = header.getOrDefault("X-Amz-Credential")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "X-Amz-Credential", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656899: Call_DescribeMultiplexProgram_402656887;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the details for a program in a multiplex.
                                                                                         ## 
  let valid = call_402656899.validator(path, query, header, formData, body, _)
  let scheme = call_402656899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656899.makeUrl(scheme.get, call_402656899.host, call_402656899.base,
                                   call_402656899.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656899, uri, valid, _)

proc call*(call_402656900: Call_DescribeMultiplexProgram_402656887;
           multiplexId: string; programName: string): Recallable =
  ## describeMultiplexProgram
  ## Get the details for a program in a multiplex.
  ##   multiplexId: string (required)
                                                  ##              : Placeholder documentation for __string
  ##   
                                                                                                          ## programName: string (required)
                                                                                                          ##              
                                                                                                          ## : 
                                                                                                          ## Placeholder 
                                                                                                          ## documentation 
                                                                                                          ## for 
                                                                                                          ## __string
  var path_402656901 = newJObject()
  add(path_402656901, "multiplexId", newJString(multiplexId))
  add(path_402656901, "programName", newJString(programName))
  result = call_402656900.call(path_402656901, nil, nil, nil, nil)

var describeMultiplexProgram* = Call_DescribeMultiplexProgram_402656887(
    name: "describeMultiplexProgram", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DescribeMultiplexProgram_402656888, base: "/",
    makeUrl: url_DescribeMultiplexProgram_402656889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplexProgram_402656919 = ref object of OpenApiRestCall_402656044
proc url_DeleteMultiplexProgram_402656921(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  assert "programName" in path, "`programName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
                 (kind: VariableSegment, value: "multiplexId"),
                 (kind: ConstantSegment, value: "/programs/"),
                 (kind: VariableSegment, value: "programName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMultiplexProgram_402656920(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a program from a multiplex.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
                                 ##              : Placeholder documentation for __string
  ##   
                                                                                         ## programName: JString (required)
                                                                                         ##              
                                                                                         ## : 
                                                                                         ## Placeholder 
                                                                                         ## documentation 
                                                                                         ## for 
                                                                                         ## __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `multiplexId` field"
  var valid_402656922 = path.getOrDefault("multiplexId")
  valid_402656922 = validateParameter(valid_402656922, JString, required = true,
                                      default = nil)
  if valid_402656922 != nil:
    section.add "multiplexId", valid_402656922
  var valid_402656923 = path.getOrDefault("programName")
  valid_402656923 = validateParameter(valid_402656923, JString, required = true,
                                      default = nil)
  if valid_402656923 != nil:
    section.add "programName", valid_402656923
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
  var valid_402656924 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "X-Amz-Security-Token", valid_402656924
  var valid_402656925 = header.getOrDefault("X-Amz-Signature")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "X-Amz-Signature", valid_402656925
  var valid_402656926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-Algorithm", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Date")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Date", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Credential")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Credential", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656931: Call_DeleteMultiplexProgram_402656919;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a program from a multiplex.
                                                                                         ## 
  let valid = call_402656931.validator(path, query, header, formData, body, _)
  let scheme = call_402656931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656931.makeUrl(scheme.get, call_402656931.host, call_402656931.base,
                                   call_402656931.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656931, uri, valid, _)

proc call*(call_402656932: Call_DeleteMultiplexProgram_402656919;
           multiplexId: string; programName: string): Recallable =
  ## deleteMultiplexProgram
  ## Delete a program from a multiplex.
  ##   multiplexId: string (required)
                                       ##              : Placeholder documentation for __string
  ##   
                                                                                               ## programName: string (required)
                                                                                               ##              
                                                                                               ## : 
                                                                                               ## Placeholder 
                                                                                               ## documentation 
                                                                                               ## for 
                                                                                               ## __string
  var path_402656933 = newJObject()
  add(path_402656933, "multiplexId", newJString(multiplexId))
  add(path_402656933, "programName", newJString(programName))
  result = call_402656932.call(path_402656933, nil, nil, nil, nil)

var deleteMultiplexProgram* = Call_DeleteMultiplexProgram_402656919(
    name: "deleteMultiplexProgram", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DeleteMultiplexProgram_402656920, base: "/",
    makeUrl: url_DeleteMultiplexProgram_402656921,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReservation_402656948 = ref object of OpenApiRestCall_402656044
proc url_UpdateReservation_402656950(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
                 (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateReservation_402656949(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update reservation.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   reservationId: JString (required)
                                 ##                : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `reservationId` field"
  var valid_402656951 = path.getOrDefault("reservationId")
  valid_402656951 = validateParameter(valid_402656951, JString, required = true,
                                      default = nil)
  if valid_402656951 != nil:
    section.add "reservationId", valid_402656951
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
  var valid_402656952 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-Security-Token", valid_402656952
  var valid_402656953 = header.getOrDefault("X-Amz-Signature")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-Signature", valid_402656953
  var valid_402656954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Algorithm", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-Date")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-Date", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-Credential")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Credential", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656958
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

proc call*(call_402656960: Call_UpdateReservation_402656948;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update reservation.
                                                                                         ## 
  let valid = call_402656960.validator(path, query, header, formData, body, _)
  let scheme = call_402656960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656960.makeUrl(scheme.get, call_402656960.host, call_402656960.base,
                                   call_402656960.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656960, uri, valid, _)

proc call*(call_402656961: Call_UpdateReservation_402656948; body: JsonNode;
           reservationId: string): Recallable =
  ## updateReservation
  ## Update reservation.
  ##   body: JObject (required)
  ##   reservationId: string (required)
                               ##                : Placeholder documentation for __string
  var path_402656962 = newJObject()
  var body_402656963 = newJObject()
  if body != nil:
    body_402656963 = body
  add(path_402656962, "reservationId", newJString(reservationId))
  result = call_402656961.call(path_402656962, nil, nil, nil, body_402656963)

var updateReservation* = Call_UpdateReservation_402656948(
    name: "updateReservation", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_UpdateReservation_402656949, base: "/",
    makeUrl: url_UpdateReservation_402656950,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservation_402656934 = ref object of OpenApiRestCall_402656044
proc url_DescribeReservation_402656936(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
                 (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeReservation_402656935(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get details for a reservation.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   reservationId: JString (required)
                                 ##                : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `reservationId` field"
  var valid_402656937 = path.getOrDefault("reservationId")
  valid_402656937 = validateParameter(valid_402656937, JString, required = true,
                                      default = nil)
  if valid_402656937 != nil:
    section.add "reservationId", valid_402656937
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
  var valid_402656938 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Security-Token", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Signature")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Signature", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656940
  var valid_402656941 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656941 = validateParameter(valid_402656941, JString,
                                      required = false, default = nil)
  if valid_402656941 != nil:
    section.add "X-Amz-Algorithm", valid_402656941
  var valid_402656942 = header.getOrDefault("X-Amz-Date")
  valid_402656942 = validateParameter(valid_402656942, JString,
                                      required = false, default = nil)
  if valid_402656942 != nil:
    section.add "X-Amz-Date", valid_402656942
  var valid_402656943 = header.getOrDefault("X-Amz-Credential")
  valid_402656943 = validateParameter(valid_402656943, JString,
                                      required = false, default = nil)
  if valid_402656943 != nil:
    section.add "X-Amz-Credential", valid_402656943
  var valid_402656944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656945: Call_DescribeReservation_402656934;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get details for a reservation.
                                                                                         ## 
  let valid = call_402656945.validator(path, query, header, formData, body, _)
  let scheme = call_402656945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656945.makeUrl(scheme.get, call_402656945.host, call_402656945.base,
                                   call_402656945.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656945, uri, valid, _)

proc call*(call_402656946: Call_DescribeReservation_402656934;
           reservationId: string): Recallable =
  ## describeReservation
  ## Get details for a reservation.
  ##   reservationId: string (required)
                                   ##                : Placeholder documentation for __string
  var path_402656947 = newJObject()
  add(path_402656947, "reservationId", newJString(reservationId))
  result = call_402656946.call(path_402656947, nil, nil, nil, nil)

var describeReservation* = Call_DescribeReservation_402656934(
    name: "describeReservation", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_DescribeReservation_402656935, base: "/",
    makeUrl: url_DescribeReservation_402656936,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReservation_402656964 = ref object of OpenApiRestCall_402656044
proc url_DeleteReservation_402656966(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
                 (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteReservation_402656965(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete an expired reservation.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   reservationId: JString (required)
                                 ##                : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `reservationId` field"
  var valid_402656967 = path.getOrDefault("reservationId")
  valid_402656967 = validateParameter(valid_402656967, JString, required = true,
                                      default = nil)
  if valid_402656967 != nil:
    section.add "reservationId", valid_402656967
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
  var valid_402656968 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656968 = validateParameter(valid_402656968, JString,
                                      required = false, default = nil)
  if valid_402656968 != nil:
    section.add "X-Amz-Security-Token", valid_402656968
  var valid_402656969 = header.getOrDefault("X-Amz-Signature")
  valid_402656969 = validateParameter(valid_402656969, JString,
                                      required = false, default = nil)
  if valid_402656969 != nil:
    section.add "X-Amz-Signature", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656970
  var valid_402656971 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "X-Amz-Algorithm", valid_402656971
  var valid_402656972 = header.getOrDefault("X-Amz-Date")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-Date", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Credential")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Credential", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656975: Call_DeleteReservation_402656964;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an expired reservation.
                                                                                         ## 
  let valid = call_402656975.validator(path, query, header, formData, body, _)
  let scheme = call_402656975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656975.makeUrl(scheme.get, call_402656975.host, call_402656975.base,
                                   call_402656975.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656975, uri, valid, _)

proc call*(call_402656976: Call_DeleteReservation_402656964;
           reservationId: string): Recallable =
  ## deleteReservation
  ## Delete an expired reservation.
  ##   reservationId: string (required)
                                   ##                : Placeholder documentation for __string
  var path_402656977 = newJObject()
  add(path_402656977, "reservationId", newJString(reservationId))
  result = call_402656976.call(path_402656977, nil, nil, nil, nil)

var deleteReservation* = Call_DeleteReservation_402656964(
    name: "deleteReservation", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_DeleteReservation_402656965, base: "/",
    makeUrl: url_DeleteReservation_402656966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_402656978 = ref object of OpenApiRestCall_402656044
proc url_DeleteTags_402656980(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
                 (kind: VariableSegment, value: "resource-arn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTags_402656979(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes tags for a resource
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
                                 ##               : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656981 = path.getOrDefault("resource-arn")
  valid_402656981 = validateParameter(valid_402656981, JString, required = true,
                                      default = nil)
  if valid_402656981 != nil:
    section.add "resource-arn", valid_402656981
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : Placeholder documentation for __listOf__string
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656982 = query.getOrDefault("tagKeys")
  valid_402656982 = validateParameter(valid_402656982, JArray, required = true,
                                      default = nil)
  if valid_402656982 != nil:
    section.add "tagKeys", valid_402656982
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
  var valid_402656983 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-Security-Token", valid_402656983
  var valid_402656984 = header.getOrDefault("X-Amz-Signature")
  valid_402656984 = validateParameter(valid_402656984, JString,
                                      required = false, default = nil)
  if valid_402656984 != nil:
    section.add "X-Amz-Signature", valid_402656984
  var valid_402656985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656985
  var valid_402656986 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656986 = validateParameter(valid_402656986, JString,
                                      required = false, default = nil)
  if valid_402656986 != nil:
    section.add "X-Amz-Algorithm", valid_402656986
  var valid_402656987 = header.getOrDefault("X-Amz-Date")
  valid_402656987 = validateParameter(valid_402656987, JString,
                                      required = false, default = nil)
  if valid_402656987 != nil:
    section.add "X-Amz-Date", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-Credential")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Credential", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656990: Call_DeleteTags_402656978; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags for a resource
                                                                                         ## 
  let valid = call_402656990.validator(path, query, header, formData, body, _)
  let scheme = call_402656990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656990.makeUrl(scheme.get, call_402656990.host, call_402656990.base,
                                   call_402656990.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656990, uri, valid, _)

proc call*(call_402656991: Call_DeleteTags_402656978; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## deleteTags
  ## Removes tags for a resource
  ##   tagKeys: JArray (required)
                                ##          : Placeholder documentation for __listOf__string
  ##   
                                                                                            ## resourceArn: string (required)
                                                                                            ##              
                                                                                            ## : 
                                                                                            ## Placeholder 
                                                                                            ## documentation 
                                                                                            ## for 
                                                                                            ## __string
  var path_402656992 = newJObject()
  var query_402656993 = newJObject()
  if tagKeys != nil:
    query_402656993.add "tagKeys", tagKeys
  add(path_402656992, "resource-arn", newJString(resourceArn))
  result = call_402656991.call(path_402656992, query_402656993, nil, nil, nil)

var deleteTags* = Call_DeleteTags_402656978(name: "deleteTags",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/tags/{resource-arn}#tagKeys", validator: validate_DeleteTags_402656979,
    base: "/", makeUrl: url_DeleteTags_402656980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOffering_402656994 = ref object of OpenApiRestCall_402656044
proc url_DescribeOffering_402656996(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "offeringId" in path, "`offeringId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/offerings/"),
                 (kind: VariableSegment, value: "offeringId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeOffering_402656995(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get details for an offering.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   offeringId: JString (required)
                                 ##             : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `offeringId` field"
  var valid_402656997 = path.getOrDefault("offeringId")
  valid_402656997 = validateParameter(valid_402656997, JString, required = true,
                                      default = nil)
  if valid_402656997 != nil:
    section.add "offeringId", valid_402656997
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
  var valid_402656998 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Security-Token", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-Signature")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Signature", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657000
  var valid_402657001 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657001 = validateParameter(valid_402657001, JString,
                                      required = false, default = nil)
  if valid_402657001 != nil:
    section.add "X-Amz-Algorithm", valid_402657001
  var valid_402657002 = header.getOrDefault("X-Amz-Date")
  valid_402657002 = validateParameter(valid_402657002, JString,
                                      required = false, default = nil)
  if valid_402657002 != nil:
    section.add "X-Amz-Date", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-Credential")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Credential", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657005: Call_DescribeOffering_402656994;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get details for an offering.
                                                                                         ## 
  let valid = call_402657005.validator(path, query, header, formData, body, _)
  let scheme = call_402657005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657005.makeUrl(scheme.get, call_402657005.host, call_402657005.base,
                                   call_402657005.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657005, uri, valid, _)

proc call*(call_402657006: Call_DescribeOffering_402656994; offeringId: string): Recallable =
  ## describeOffering
  ## Get details for an offering.
  ##   offeringId: string (required)
                                 ##             : Placeholder documentation for __string
  var path_402657007 = newJObject()
  add(path_402657007, "offeringId", newJString(offeringId))
  result = call_402657006.call(path_402657007, nil, nil, nil, nil)

var describeOffering* = Call_DescribeOffering_402656994(
    name: "describeOffering", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/offerings/{offeringId}",
    validator: validate_DescribeOffering_402656995, base: "/",
    makeUrl: url_DescribeOffering_402656996,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_402657008 = ref object of OpenApiRestCall_402656044
proc url_ListOfferings_402657010(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferings_402657009(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List offerings available for purchase.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   channelConfiguration: JString
                                  ##                       : Placeholder documentation for __string
  ##   
                                                                                                   ## channelClass: JString
                                                                                                   ##               
                                                                                                   ## : 
                                                                                                   ## Placeholder 
                                                                                                   ## documentation 
                                                                                                   ## for 
                                                                                                   ## __string
  ##   
                                                                                                              ## maxResults: JInt
                                                                                                              ##             
                                                                                                              ## : 
                                                                                                              ## Placeholder 
                                                                                                              ## documentation 
                                                                                                              ## for 
                                                                                                              ## MaxResults
  ##   
                                                                                                                           ## videoQuality: JString
                                                                                                                           ##               
                                                                                                                           ## : 
                                                                                                                           ## Placeholder 
                                                                                                                           ## documentation 
                                                                                                                           ## for 
                                                                                                                           ## __string
  ##   
                                                                                                                                      ## nextToken: JString
                                                                                                                                      ##            
                                                                                                                                      ## : 
                                                                                                                                      ## Placeholder 
                                                                                                                                      ## documentation 
                                                                                                                                      ## for 
                                                                                                                                      ## __string
  ##   
                                                                                                                                                 ## resolution: JString
                                                                                                                                                 ##             
                                                                                                                                                 ## : 
                                                                                                                                                 ## Placeholder 
                                                                                                                                                 ## documentation 
                                                                                                                                                 ## for 
                                                                                                                                                 ## __string
  ##   
                                                                                                                                                            ## MaxResults: JString
                                                                                                                                                            ##             
                                                                                                                                                            ## : 
                                                                                                                                                            ## Pagination 
                                                                                                                                                            ## limit
  ##   
                                                                                                                                                                    ## resourceType: JString
                                                                                                                                                                    ##               
                                                                                                                                                                    ## : 
                                                                                                                                                                    ## Placeholder 
                                                                                                                                                                    ## documentation 
                                                                                                                                                                    ## for 
                                                                                                                                                                    ## __string
  ##   
                                                                                                                                                                               ## NextToken: JString
                                                                                                                                                                               ##            
                                                                                                                                                                               ## : 
                                                                                                                                                                               ## Pagination 
                                                                                                                                                                               ## token
  ##   
                                                                                                                                                                                       ## codec: JString
                                                                                                                                                                                       ##        
                                                                                                                                                                                       ## : 
                                                                                                                                                                                       ## Placeholder 
                                                                                                                                                                                       ## documentation 
                                                                                                                                                                                       ## for 
                                                                                                                                                                                       ## __string
  ##   
                                                                                                                                                                                                  ## specialFeature: JString
                                                                                                                                                                                                  ##                 
                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                  ## Placeholder 
                                                                                                                                                                                                  ## documentation 
                                                                                                                                                                                                  ## for 
                                                                                                                                                                                                  ## __string
  ##   
                                                                                                                                                                                                             ## maximumBitrate: JString
                                                                                                                                                                                                             ##                 
                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                             ## Placeholder 
                                                                                                                                                                                                             ## documentation 
                                                                                                                                                                                                             ## for 
                                                                                                                                                                                                             ## __string
  ##   
                                                                                                                                                                                                                        ## maximumFramerate: JString
                                                                                                                                                                                                                        ##                   
                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                        ## Placeholder 
                                                                                                                                                                                                                        ## documentation 
                                                                                                                                                                                                                        ## for 
                                                                                                                                                                                                                        ## __string
  ##   
                                                                                                                                                                                                                                   ## duration: JString
                                                                                                                                                                                                                                   ##           
                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                   ## Placeholder 
                                                                                                                                                                                                                                   ## documentation 
                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                   ## __string
  section = newJObject()
  var valid_402657011 = query.getOrDefault("channelConfiguration")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "channelConfiguration", valid_402657011
  var valid_402657012 = query.getOrDefault("channelClass")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "channelClass", valid_402657012
  var valid_402657013 = query.getOrDefault("maxResults")
  valid_402657013 = validateParameter(valid_402657013, JInt, required = false,
                                      default = nil)
  if valid_402657013 != nil:
    section.add "maxResults", valid_402657013
  var valid_402657014 = query.getOrDefault("videoQuality")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "videoQuality", valid_402657014
  var valid_402657015 = query.getOrDefault("nextToken")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "nextToken", valid_402657015
  var valid_402657016 = query.getOrDefault("resolution")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "resolution", valid_402657016
  var valid_402657017 = query.getOrDefault("MaxResults")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "MaxResults", valid_402657017
  var valid_402657018 = query.getOrDefault("resourceType")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "resourceType", valid_402657018
  var valid_402657019 = query.getOrDefault("NextToken")
  valid_402657019 = validateParameter(valid_402657019, JString,
                                      required = false, default = nil)
  if valid_402657019 != nil:
    section.add "NextToken", valid_402657019
  var valid_402657020 = query.getOrDefault("codec")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "codec", valid_402657020
  var valid_402657021 = query.getOrDefault("specialFeature")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "specialFeature", valid_402657021
  var valid_402657022 = query.getOrDefault("maximumBitrate")
  valid_402657022 = validateParameter(valid_402657022, JString,
                                      required = false, default = nil)
  if valid_402657022 != nil:
    section.add "maximumBitrate", valid_402657022
  var valid_402657023 = query.getOrDefault("maximumFramerate")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "maximumFramerate", valid_402657023
  var valid_402657024 = query.getOrDefault("duration")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "duration", valid_402657024
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
  var valid_402657025 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-Security-Token", valid_402657025
  var valid_402657026 = header.getOrDefault("X-Amz-Signature")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-Signature", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Algorithm", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-Date")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Date", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Credential")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Credential", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657032: Call_ListOfferings_402657008; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List offerings available for purchase.
                                                                                         ## 
  let valid = call_402657032.validator(path, query, header, formData, body, _)
  let scheme = call_402657032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657032.makeUrl(scheme.get, call_402657032.host, call_402657032.base,
                                   call_402657032.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657032, uri, valid, _)

proc call*(call_402657033: Call_ListOfferings_402657008;
           channelConfiguration: string = ""; channelClass: string = "";
           maxResults: int = 0; videoQuality: string = "";
           nextToken: string = ""; resolution: string = "";
           MaxResults: string = ""; resourceType: string = "";
           NextToken: string = ""; codec: string = "";
           specialFeature: string = ""; maximumBitrate: string = "";
           maximumFramerate: string = ""; duration: string = ""): Recallable =
  ## listOfferings
  ## List offerings available for purchase.
  ##   channelConfiguration: string
                                           ##                       : Placeholder documentation for __string
  ##   
                                                                                                            ## channelClass: string
                                                                                                            ##               
                                                                                                            ## : 
                                                                                                            ## Placeholder 
                                                                                                            ## documentation 
                                                                                                            ## for 
                                                                                                            ## __string
  ##   
                                                                                                                       ## maxResults: int
                                                                                                                       ##             
                                                                                                                       ## : 
                                                                                                                       ## Placeholder 
                                                                                                                       ## documentation 
                                                                                                                       ## for 
                                                                                                                       ## MaxResults
  ##   
                                                                                                                                    ## videoQuality: string
                                                                                                                                    ##               
                                                                                                                                    ## : 
                                                                                                                                    ## Placeholder 
                                                                                                                                    ## documentation 
                                                                                                                                    ## for 
                                                                                                                                    ## __string
  ##   
                                                                                                                                               ## nextToken: string
                                                                                                                                               ##            
                                                                                                                                               ## : 
                                                                                                                                               ## Placeholder 
                                                                                                                                               ## documentation 
                                                                                                                                               ## for 
                                                                                                                                               ## __string
  ##   
                                                                                                                                                          ## resolution: string
                                                                                                                                                          ##             
                                                                                                                                                          ## : 
                                                                                                                                                          ## Placeholder 
                                                                                                                                                          ## documentation 
                                                                                                                                                          ## for 
                                                                                                                                                          ## __string
  ##   
                                                                                                                                                                     ## MaxResults: string
                                                                                                                                                                     ##             
                                                                                                                                                                     ## : 
                                                                                                                                                                     ## Pagination 
                                                                                                                                                                     ## limit
  ##   
                                                                                                                                                                             ## resourceType: string
                                                                                                                                                                             ##               
                                                                                                                                                                             ## : 
                                                                                                                                                                             ## Placeholder 
                                                                                                                                                                             ## documentation 
                                                                                                                                                                             ## for 
                                                                                                                                                                             ## __string
  ##   
                                                                                                                                                                                        ## NextToken: string
                                                                                                                                                                                        ##            
                                                                                                                                                                                        ## : 
                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                        ## token
  ##   
                                                                                                                                                                                                ## codec: string
                                                                                                                                                                                                ##        
                                                                                                                                                                                                ## : 
                                                                                                                                                                                                ## Placeholder 
                                                                                                                                                                                                ## documentation 
                                                                                                                                                                                                ## for 
                                                                                                                                                                                                ## __string
  ##   
                                                                                                                                                                                                           ## specialFeature: string
                                                                                                                                                                                                           ##                 
                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                           ## Placeholder 
                                                                                                                                                                                                           ## documentation 
                                                                                                                                                                                                           ## for 
                                                                                                                                                                                                           ## __string
  ##   
                                                                                                                                                                                                                      ## maximumBitrate: string
                                                                                                                                                                                                                      ##                 
                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                      ## Placeholder 
                                                                                                                                                                                                                      ## documentation 
                                                                                                                                                                                                                      ## for 
                                                                                                                                                                                                                      ## __string
  ##   
                                                                                                                                                                                                                                 ## maximumFramerate: string
                                                                                                                                                                                                                                 ##                   
                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                 ## Placeholder 
                                                                                                                                                                                                                                 ## documentation 
                                                                                                                                                                                                                                 ## for 
                                                                                                                                                                                                                                 ## __string
  ##   
                                                                                                                                                                                                                                            ## duration: string
                                                                                                                                                                                                                                            ##           
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## Placeholder 
                                                                                                                                                                                                                                            ## documentation 
                                                                                                                                                                                                                                            ## for 
                                                                                                                                                                                                                                            ## __string
  var query_402657034 = newJObject()
  add(query_402657034, "channelConfiguration", newJString(channelConfiguration))
  add(query_402657034, "channelClass", newJString(channelClass))
  add(query_402657034, "maxResults", newJInt(maxResults))
  add(query_402657034, "videoQuality", newJString(videoQuality))
  add(query_402657034, "nextToken", newJString(nextToken))
  add(query_402657034, "resolution", newJString(resolution))
  add(query_402657034, "MaxResults", newJString(MaxResults))
  add(query_402657034, "resourceType", newJString(resourceType))
  add(query_402657034, "NextToken", newJString(NextToken))
  add(query_402657034, "codec", newJString(codec))
  add(query_402657034, "specialFeature", newJString(specialFeature))
  add(query_402657034, "maximumBitrate", newJString(maximumBitrate))
  add(query_402657034, "maximumFramerate", newJString(maximumFramerate))
  add(query_402657034, "duration", newJString(duration))
  result = call_402657033.call(nil, query_402657034, nil, nil, nil)

var listOfferings* = Call_ListOfferings_402657008(name: "listOfferings",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings", validator: validate_ListOfferings_402657009,
    base: "/", makeUrl: url_ListOfferings_402657010,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReservations_402657035 = ref object of OpenApiRestCall_402656044
proc url_ListReservations_402657037(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListReservations_402657036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List purchased reservations.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   channelClass: JString
                                  ##               : Placeholder documentation for __string
  ##   
                                                                                           ## maxResults: JInt
                                                                                           ##             
                                                                                           ## : 
                                                                                           ## Placeholder 
                                                                                           ## documentation 
                                                                                           ## for 
                                                                                           ## MaxResults
  ##   
                                                                                                        ## videoQuality: JString
                                                                                                        ##               
                                                                                                        ## : 
                                                                                                        ## Placeholder 
                                                                                                        ## documentation 
                                                                                                        ## for 
                                                                                                        ## __string
  ##   
                                                                                                                   ## nextToken: JString
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## Placeholder 
                                                                                                                   ## documentation 
                                                                                                                   ## for 
                                                                                                                   ## __string
  ##   
                                                                                                                              ## resolution: JString
                                                                                                                              ##             
                                                                                                                              ## : 
                                                                                                                              ## Placeholder 
                                                                                                                              ## documentation 
                                                                                                                              ## for 
                                                                                                                              ## __string
  ##   
                                                                                                                                         ## MaxResults: JString
                                                                                                                                         ##             
                                                                                                                                         ## : 
                                                                                                                                         ## Pagination 
                                                                                                                                         ## limit
  ##   
                                                                                                                                                 ## resourceType: JString
                                                                                                                                                 ##               
                                                                                                                                                 ## : 
                                                                                                                                                 ## Placeholder 
                                                                                                                                                 ## documentation 
                                                                                                                                                 ## for 
                                                                                                                                                 ## __string
  ##   
                                                                                                                                                            ## NextToken: JString
                                                                                                                                                            ##            
                                                                                                                                                            ## : 
                                                                                                                                                            ## Pagination 
                                                                                                                                                            ## token
  ##   
                                                                                                                                                                    ## codec: JString
                                                                                                                                                                    ##        
                                                                                                                                                                    ## : 
                                                                                                                                                                    ## Placeholder 
                                                                                                                                                                    ## documentation 
                                                                                                                                                                    ## for 
                                                                                                                                                                    ## __string
  ##   
                                                                                                                                                                               ## specialFeature: JString
                                                                                                                                                                               ##                 
                                                                                                                                                                               ## : 
                                                                                                                                                                               ## Placeholder 
                                                                                                                                                                               ## documentation 
                                                                                                                                                                               ## for 
                                                                                                                                                                               ## __string
  ##   
                                                                                                                                                                                          ## maximumBitrate: JString
                                                                                                                                                                                          ##                 
                                                                                                                                                                                          ## : 
                                                                                                                                                                                          ## Placeholder 
                                                                                                                                                                                          ## documentation 
                                                                                                                                                                                          ## for 
                                                                                                                                                                                          ## __string
  ##   
                                                                                                                                                                                                     ## maximumFramerate: JString
                                                                                                                                                                                                     ##                   
                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                     ## Placeholder 
                                                                                                                                                                                                     ## documentation 
                                                                                                                                                                                                     ## for 
                                                                                                                                                                                                     ## __string
  section = newJObject()
  var valid_402657038 = query.getOrDefault("channelClass")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "channelClass", valid_402657038
  var valid_402657039 = query.getOrDefault("maxResults")
  valid_402657039 = validateParameter(valid_402657039, JInt, required = false,
                                      default = nil)
  if valid_402657039 != nil:
    section.add "maxResults", valid_402657039
  var valid_402657040 = query.getOrDefault("videoQuality")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "videoQuality", valid_402657040
  var valid_402657041 = query.getOrDefault("nextToken")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "nextToken", valid_402657041
  var valid_402657042 = query.getOrDefault("resolution")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "resolution", valid_402657042
  var valid_402657043 = query.getOrDefault("MaxResults")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "MaxResults", valid_402657043
  var valid_402657044 = query.getOrDefault("resourceType")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "resourceType", valid_402657044
  var valid_402657045 = query.getOrDefault("NextToken")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "NextToken", valid_402657045
  var valid_402657046 = query.getOrDefault("codec")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "codec", valid_402657046
  var valid_402657047 = query.getOrDefault("specialFeature")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "specialFeature", valid_402657047
  var valid_402657048 = query.getOrDefault("maximumBitrate")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "maximumBitrate", valid_402657048
  var valid_402657049 = query.getOrDefault("maximumFramerate")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "maximumFramerate", valid_402657049
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
  var valid_402657050 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Security-Token", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-Signature")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-Signature", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Algorithm", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-Date")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-Date", valid_402657054
  var valid_402657055 = header.getOrDefault("X-Amz-Credential")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Credential", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657057: Call_ListReservations_402657035;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List purchased reservations.
                                                                                         ## 
  let valid = call_402657057.validator(path, query, header, formData, body, _)
  let scheme = call_402657057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657057.makeUrl(scheme.get, call_402657057.host, call_402657057.base,
                                   call_402657057.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657057, uri, valid, _)

proc call*(call_402657058: Call_ListReservations_402657035;
           channelClass: string = ""; maxResults: int = 0;
           videoQuality: string = ""; nextToken: string = "";
           resolution: string = ""; MaxResults: string = "";
           resourceType: string = ""; NextToken: string = "";
           codec: string = ""; specialFeature: string = "";
           maximumBitrate: string = ""; maximumFramerate: string = ""): Recallable =
  ## listReservations
  ## List purchased reservations.
  ##   channelClass: string
                                 ##               : Placeholder documentation for __string
  ##   
                                                                                          ## maxResults: int
                                                                                          ##             
                                                                                          ## : 
                                                                                          ## Placeholder 
                                                                                          ## documentation 
                                                                                          ## for 
                                                                                          ## MaxResults
  ##   
                                                                                                       ## videoQuality: string
                                                                                                       ##               
                                                                                                       ## : 
                                                                                                       ## Placeholder 
                                                                                                       ## documentation 
                                                                                                       ## for 
                                                                                                       ## __string
  ##   
                                                                                                                  ## nextToken: string
                                                                                                                  ##            
                                                                                                                  ## : 
                                                                                                                  ## Placeholder 
                                                                                                                  ## documentation 
                                                                                                                  ## for 
                                                                                                                  ## __string
  ##   
                                                                                                                             ## resolution: string
                                                                                                                             ##             
                                                                                                                             ## : 
                                                                                                                             ## Placeholder 
                                                                                                                             ## documentation 
                                                                                                                             ## for 
                                                                                                                             ## __string
  ##   
                                                                                                                                        ## MaxResults: string
                                                                                                                                        ##             
                                                                                                                                        ## : 
                                                                                                                                        ## Pagination 
                                                                                                                                        ## limit
  ##   
                                                                                                                                                ## resourceType: string
                                                                                                                                                ##               
                                                                                                                                                ## : 
                                                                                                                                                ## Placeholder 
                                                                                                                                                ## documentation 
                                                                                                                                                ## for 
                                                                                                                                                ## __string
  ##   
                                                                                                                                                           ## NextToken: string
                                                                                                                                                           ##            
                                                                                                                                                           ## : 
                                                                                                                                                           ## Pagination 
                                                                                                                                                           ## token
  ##   
                                                                                                                                                                   ## codec: string
                                                                                                                                                                   ##        
                                                                                                                                                                   ## : 
                                                                                                                                                                   ## Placeholder 
                                                                                                                                                                   ## documentation 
                                                                                                                                                                   ## for 
                                                                                                                                                                   ## __string
  ##   
                                                                                                                                                                              ## specialFeature: string
                                                                                                                                                                              ##                 
                                                                                                                                                                              ## : 
                                                                                                                                                                              ## Placeholder 
                                                                                                                                                                              ## documentation 
                                                                                                                                                                              ## for 
                                                                                                                                                                              ## __string
  ##   
                                                                                                                                                                                         ## maximumBitrate: string
                                                                                                                                                                                         ##                 
                                                                                                                                                                                         ## : 
                                                                                                                                                                                         ## Placeholder 
                                                                                                                                                                                         ## documentation 
                                                                                                                                                                                         ## for 
                                                                                                                                                                                         ## __string
  ##   
                                                                                                                                                                                                    ## maximumFramerate: string
                                                                                                                                                                                                    ##                   
                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                    ## Placeholder 
                                                                                                                                                                                                    ## documentation 
                                                                                                                                                                                                    ## for 
                                                                                                                                                                                                    ## __string
  var query_402657059 = newJObject()
  add(query_402657059, "channelClass", newJString(channelClass))
  add(query_402657059, "maxResults", newJInt(maxResults))
  add(query_402657059, "videoQuality", newJString(videoQuality))
  add(query_402657059, "nextToken", newJString(nextToken))
  add(query_402657059, "resolution", newJString(resolution))
  add(query_402657059, "MaxResults", newJString(MaxResults))
  add(query_402657059, "resourceType", newJString(resourceType))
  add(query_402657059, "NextToken", newJString(NextToken))
  add(query_402657059, "codec", newJString(codec))
  add(query_402657059, "specialFeature", newJString(specialFeature))
  add(query_402657059, "maximumBitrate", newJString(maximumBitrate))
  add(query_402657059, "maximumFramerate", newJString(maximumFramerate))
  result = call_402657058.call(nil, query_402657059, nil, nil, nil)

var listReservations* = Call_ListReservations_402657035(
    name: "listReservations", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/reservations",
    validator: validate_ListReservations_402657036, base: "/",
    makeUrl: url_ListReservations_402657037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_402657060 = ref object of OpenApiRestCall_402656044
proc url_PurchaseOffering_402657062(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "offeringId" in path, "`offeringId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/offerings/"),
                 (kind: VariableSegment, value: "offeringId"),
                 (kind: ConstantSegment, value: "/purchase")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PurchaseOffering_402657061(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Purchase an offering and create a reservation.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   offeringId: JString (required)
                                 ##             : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `offeringId` field"
  var valid_402657063 = path.getOrDefault("offeringId")
  valid_402657063 = validateParameter(valid_402657063, JString, required = true,
                                      default = nil)
  if valid_402657063 != nil:
    section.add "offeringId", valid_402657063
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
  var valid_402657064 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Security-Token", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Signature")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Signature", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657066
  var valid_402657067 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657067 = validateParameter(valid_402657067, JString,
                                      required = false, default = nil)
  if valid_402657067 != nil:
    section.add "X-Amz-Algorithm", valid_402657067
  var valid_402657068 = header.getOrDefault("X-Amz-Date")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "X-Amz-Date", valid_402657068
  var valid_402657069 = header.getOrDefault("X-Amz-Credential")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "X-Amz-Credential", valid_402657069
  var valid_402657070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657070
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

proc call*(call_402657072: Call_PurchaseOffering_402657060;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Purchase an offering and create a reservation.
                                                                                         ## 
  let valid = call_402657072.validator(path, query, header, formData, body, _)
  let scheme = call_402657072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657072.makeUrl(scheme.get, call_402657072.host, call_402657072.base,
                                   call_402657072.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657072, uri, valid, _)

proc call*(call_402657073: Call_PurchaseOffering_402657060; body: JsonNode;
           offeringId: string): Recallable =
  ## purchaseOffering
  ## Purchase an offering and create a reservation.
  ##   body: JObject (required)
  ##   offeringId: string (required)
                               ##             : Placeholder documentation for __string
  var path_402657074 = newJObject()
  var body_402657075 = newJObject()
  if body != nil:
    body_402657075 = body
  add(path_402657074, "offeringId", newJString(offeringId))
  result = call_402657073.call(path_402657074, nil, nil, nil, body_402657075)

var purchaseOffering* = Call_PurchaseOffering_402657060(
    name: "purchaseOffering", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}/purchase",
    validator: validate_PurchaseOffering_402657061, base: "/",
    makeUrl: url_PurchaseOffering_402657062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChannel_402657076 = ref object of OpenApiRestCall_402656044
proc url_StartChannel_402657078(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
                 (kind: VariableSegment, value: "channelId"),
                 (kind: ConstantSegment, value: "/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartChannel_402657077(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts an existing channel
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
                                 ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `channelId` field"
  var valid_402657079 = path.getOrDefault("channelId")
  valid_402657079 = validateParameter(valid_402657079, JString, required = true,
                                      default = nil)
  if valid_402657079 != nil:
    section.add "channelId", valid_402657079
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
  var valid_402657080 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Security-Token", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-Signature")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-Signature", valid_402657081
  var valid_402657082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657082 = validateParameter(valid_402657082, JString,
                                      required = false, default = nil)
  if valid_402657082 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657082
  var valid_402657083 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "X-Amz-Algorithm", valid_402657083
  var valid_402657084 = header.getOrDefault("X-Amz-Date")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "X-Amz-Date", valid_402657084
  var valid_402657085 = header.getOrDefault("X-Amz-Credential")
  valid_402657085 = validateParameter(valid_402657085, JString,
                                      required = false, default = nil)
  if valid_402657085 != nil:
    section.add "X-Amz-Credential", valid_402657085
  var valid_402657086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657086 = validateParameter(valid_402657086, JString,
                                      required = false, default = nil)
  if valid_402657086 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657087: Call_StartChannel_402657076; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts an existing channel
                                                                                         ## 
  let valid = call_402657087.validator(path, query, header, formData, body, _)
  let scheme = call_402657087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657087.makeUrl(scheme.get, call_402657087.host, call_402657087.base,
                                   call_402657087.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657087, uri, valid, _)

proc call*(call_402657088: Call_StartChannel_402657076; channelId: string): Recallable =
  ## startChannel
  ## Starts an existing channel
  ##   channelId: string (required)
                               ##            : Placeholder documentation for __string
  var path_402657089 = newJObject()
  add(path_402657089, "channelId", newJString(channelId))
  result = call_402657088.call(path_402657089, nil, nil, nil, nil)

var startChannel* = Call_StartChannel_402657076(name: "startChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/start", validator: validate_StartChannel_402657077,
    base: "/", makeUrl: url_StartChannel_402657078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMultiplex_402657090 = ref object of OpenApiRestCall_402656044
proc url_StartMultiplex_402657092(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
                 (kind: VariableSegment, value: "multiplexId"),
                 (kind: ConstantSegment, value: "/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartMultiplex_402657091(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
                                 ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `multiplexId` field"
  var valid_402657093 = path.getOrDefault("multiplexId")
  valid_402657093 = validateParameter(valid_402657093, JString, required = true,
                                      default = nil)
  if valid_402657093 != nil:
    section.add "multiplexId", valid_402657093
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
  var valid_402657094 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Security-Token", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Signature")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Signature", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Algorithm", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Date")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Date", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-Credential")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-Credential", valid_402657099
  var valid_402657100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657100 = validateParameter(valid_402657100, JString,
                                      required = false, default = nil)
  if valid_402657100 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657101: Call_StartMultiplex_402657090; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
                                                                                         ## 
  let valid = call_402657101.validator(path, query, header, formData, body, _)
  let scheme = call_402657101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657101.makeUrl(scheme.get, call_402657101.host, call_402657101.base,
                                   call_402657101.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657101, uri, valid, _)

proc call*(call_402657102: Call_StartMultiplex_402657090; multiplexId: string): Recallable =
  ## startMultiplex
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ##   
                                                                                                                           ## multiplexId: string (required)
                                                                                                                           ##              
                                                                                                                           ## : 
                                                                                                                           ## Placeholder 
                                                                                                                           ## documentation 
                                                                                                                           ## for 
                                                                                                                           ## __string
  var path_402657103 = newJObject()
  add(path_402657103, "multiplexId", newJString(multiplexId))
  result = call_402657102.call(path_402657103, nil, nil, nil, nil)

var startMultiplex* = Call_StartMultiplex_402657090(name: "startMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/start",
    validator: validate_StartMultiplex_402657091, base: "/",
    makeUrl: url_StartMultiplex_402657092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopChannel_402657104 = ref object of OpenApiRestCall_402656044
proc url_StopChannel_402657106(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
                 (kind: VariableSegment, value: "channelId"),
                 (kind: ConstantSegment, value: "/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopChannel_402657105(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops a running channel
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
                                 ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `channelId` field"
  var valid_402657107 = path.getOrDefault("channelId")
  valid_402657107 = validateParameter(valid_402657107, JString, required = true,
                                      default = nil)
  if valid_402657107 != nil:
    section.add "channelId", valid_402657107
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
  var valid_402657108 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657108 = validateParameter(valid_402657108, JString,
                                      required = false, default = nil)
  if valid_402657108 != nil:
    section.add "X-Amz-Security-Token", valid_402657108
  var valid_402657109 = header.getOrDefault("X-Amz-Signature")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "X-Amz-Signature", valid_402657109
  var valid_402657110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657110
  var valid_402657111 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "X-Amz-Algorithm", valid_402657111
  var valid_402657112 = header.getOrDefault("X-Amz-Date")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Date", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Credential")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Credential", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657115: Call_StopChannel_402657104; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a running channel
                                                                                         ## 
  let valid = call_402657115.validator(path, query, header, formData, body, _)
  let scheme = call_402657115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657115.makeUrl(scheme.get, call_402657115.host, call_402657115.base,
                                   call_402657115.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657115, uri, valid, _)

proc call*(call_402657116: Call_StopChannel_402657104; channelId: string): Recallable =
  ## stopChannel
  ## Stops a running channel
  ##   channelId: string (required)
                            ##            : Placeholder documentation for __string
  var path_402657117 = newJObject()
  add(path_402657117, "channelId", newJString(channelId))
  result = call_402657116.call(path_402657117, nil, nil, nil, nil)

var stopChannel* = Call_StopChannel_402657104(name: "stopChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/stop", validator: validate_StopChannel_402657105,
    base: "/", makeUrl: url_StopChannel_402657106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMultiplex_402657118 = ref object of OpenApiRestCall_402656044
proc url_StopMultiplex_402657120(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
                 (kind: VariableSegment, value: "multiplexId"),
                 (kind: ConstantSegment, value: "/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopMultiplex_402657119(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
                                 ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `multiplexId` field"
  var valid_402657121 = path.getOrDefault("multiplexId")
  valid_402657121 = validateParameter(valid_402657121, JString, required = true,
                                      default = nil)
  if valid_402657121 != nil:
    section.add "multiplexId", valid_402657121
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
  var valid_402657122 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657122 = validateParameter(valid_402657122, JString,
                                      required = false, default = nil)
  if valid_402657122 != nil:
    section.add "X-Amz-Security-Token", valid_402657122
  var valid_402657123 = header.getOrDefault("X-Amz-Signature")
  valid_402657123 = validateParameter(valid_402657123, JString,
                                      required = false, default = nil)
  if valid_402657123 != nil:
    section.add "X-Amz-Signature", valid_402657123
  var valid_402657124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657124 = validateParameter(valid_402657124, JString,
                                      required = false, default = nil)
  if valid_402657124 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657124
  var valid_402657125 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657125 = validateParameter(valid_402657125, JString,
                                      required = false, default = nil)
  if valid_402657125 != nil:
    section.add "X-Amz-Algorithm", valid_402657125
  var valid_402657126 = header.getOrDefault("X-Amz-Date")
  valid_402657126 = validateParameter(valid_402657126, JString,
                                      required = false, default = nil)
  if valid_402657126 != nil:
    section.add "X-Amz-Date", valid_402657126
  var valid_402657127 = header.getOrDefault("X-Amz-Credential")
  valid_402657127 = validateParameter(valid_402657127, JString,
                                      required = false, default = nil)
  if valid_402657127 != nil:
    section.add "X-Amz-Credential", valid_402657127
  var valid_402657128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657129: Call_StopMultiplex_402657118; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
                                                                                         ## 
  let valid = call_402657129.validator(path, query, header, formData, body, _)
  let scheme = call_402657129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657129.makeUrl(scheme.get, call_402657129.host, call_402657129.base,
                                   call_402657129.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657129, uri, valid, _)

proc call*(call_402657130: Call_StopMultiplex_402657118; multiplexId: string): Recallable =
  ## stopMultiplex
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ##   
                                                                                          ## multiplexId: string (required)
                                                                                          ##              
                                                                                          ## : 
                                                                                          ## Placeholder 
                                                                                          ## documentation 
                                                                                          ## for 
                                                                                          ## __string
  var path_402657131 = newJObject()
  add(path_402657131, "multiplexId", newJString(multiplexId))
  result = call_402657130.call(path_402657131, nil, nil, nil, nil)

var stopMultiplex* = Call_StopMultiplex_402657118(name: "stopMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/stop",
    validator: validate_StopMultiplex_402657119, base: "/",
    makeUrl: url_StopMultiplex_402657120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannelClass_402657132 = ref object of OpenApiRestCall_402656044
proc url_UpdateChannelClass_402657134(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
                 (kind: VariableSegment, value: "channelId"),
                 (kind: ConstantSegment, value: "/channelClass")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateChannelClass_402657133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Changes the class of the channel.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
                                 ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `channelId` field"
  var valid_402657135 = path.getOrDefault("channelId")
  valid_402657135 = validateParameter(valid_402657135, JString, required = true,
                                      default = nil)
  if valid_402657135 != nil:
    section.add "channelId", valid_402657135
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
  var valid_402657136 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657136 = validateParameter(valid_402657136, JString,
                                      required = false, default = nil)
  if valid_402657136 != nil:
    section.add "X-Amz-Security-Token", valid_402657136
  var valid_402657137 = header.getOrDefault("X-Amz-Signature")
  valid_402657137 = validateParameter(valid_402657137, JString,
                                      required = false, default = nil)
  if valid_402657137 != nil:
    section.add "X-Amz-Signature", valid_402657137
  var valid_402657138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657138 = validateParameter(valid_402657138, JString,
                                      required = false, default = nil)
  if valid_402657138 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657138
  var valid_402657139 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657139 = validateParameter(valid_402657139, JString,
                                      required = false, default = nil)
  if valid_402657139 != nil:
    section.add "X-Amz-Algorithm", valid_402657139
  var valid_402657140 = header.getOrDefault("X-Amz-Date")
  valid_402657140 = validateParameter(valid_402657140, JString,
                                      required = false, default = nil)
  if valid_402657140 != nil:
    section.add "X-Amz-Date", valid_402657140
  var valid_402657141 = header.getOrDefault("X-Amz-Credential")
  valid_402657141 = validateParameter(valid_402657141, JString,
                                      required = false, default = nil)
  if valid_402657141 != nil:
    section.add "X-Amz-Credential", valid_402657141
  var valid_402657142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657142 = validateParameter(valid_402657142, JString,
                                      required = false, default = nil)
  if valid_402657142 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657142
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

proc call*(call_402657144: Call_UpdateChannelClass_402657132;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the class of the channel.
                                                                                         ## 
  let valid = call_402657144.validator(path, query, header, formData, body, _)
  let scheme = call_402657144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657144.makeUrl(scheme.get, call_402657144.host, call_402657144.base,
                                   call_402657144.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657144, uri, valid, _)

proc call*(call_402657145: Call_UpdateChannelClass_402657132; channelId: string;
           body: JsonNode): Recallable =
  ## updateChannelClass
  ## Changes the class of the channel.
  ##   channelId: string (required)
                                      ##            : Placeholder documentation for __string
  ##   
                                                                                            ## body: JObject (required)
  var path_402657146 = newJObject()
  var body_402657147 = newJObject()
  add(path_402657146, "channelId", newJString(channelId))
  if body != nil:
    body_402657147 = body
  result = call_402657145.call(path_402657146, nil, nil, nil, body_402657147)

var updateChannelClass* = Call_UpdateChannelClass_402657132(
    name: "updateChannelClass", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/channelClass",
    validator: validate_UpdateChannelClass_402657133, base: "/",
    makeUrl: url_UpdateChannelClass_402657134,
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