
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Elemental MediaPackage VOD
## version: 2018-11-07
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Elemental MediaPackage VOD
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mediapackage-vod/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "mediapackage-vod.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mediapackage-vod.ap-southeast-1.amazonaws.com", "us-west-2": "mediapackage-vod.us-west-2.amazonaws.com", "eu-west-2": "mediapackage-vod.eu-west-2.amazonaws.com", "ap-northeast-3": "mediapackage-vod.ap-northeast-3.amazonaws.com", "eu-central-1": "mediapackage-vod.eu-central-1.amazonaws.com", "us-east-2": "mediapackage-vod.us-east-2.amazonaws.com", "us-east-1": "mediapackage-vod.us-east-1.amazonaws.com", "cn-northwest-1": "mediapackage-vod.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "mediapackage-vod.ap-south-1.amazonaws.com", "eu-north-1": "mediapackage-vod.eu-north-1.amazonaws.com", "ap-northeast-2": "mediapackage-vod.ap-northeast-2.amazonaws.com", "us-west-1": "mediapackage-vod.us-west-1.amazonaws.com", "us-gov-east-1": "mediapackage-vod.us-gov-east-1.amazonaws.com", "eu-west-3": "mediapackage-vod.eu-west-3.amazonaws.com", "cn-north-1": "mediapackage-vod.cn-north-1.amazonaws.com.cn", "sa-east-1": "mediapackage-vod.sa-east-1.amazonaws.com", "eu-west-1": "mediapackage-vod.eu-west-1.amazonaws.com", "us-gov-west-1": "mediapackage-vod.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mediapackage-vod.ap-southeast-2.amazonaws.com", "ca-central-1": "mediapackage-vod.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "mediapackage-vod.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mediapackage-vod.ap-southeast-1.amazonaws.com",
      "us-west-2": "mediapackage-vod.us-west-2.amazonaws.com",
      "eu-west-2": "mediapackage-vod.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mediapackage-vod.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mediapackage-vod.eu-central-1.amazonaws.com",
      "us-east-2": "mediapackage-vod.us-east-2.amazonaws.com",
      "us-east-1": "mediapackage-vod.us-east-1.amazonaws.com",
      "cn-northwest-1": "mediapackage-vod.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mediapackage-vod.ap-south-1.amazonaws.com",
      "eu-north-1": "mediapackage-vod.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mediapackage-vod.ap-northeast-2.amazonaws.com",
      "us-west-1": "mediapackage-vod.us-west-1.amazonaws.com",
      "us-gov-east-1": "mediapackage-vod.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mediapackage-vod.eu-west-3.amazonaws.com",
      "cn-north-1": "mediapackage-vod.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mediapackage-vod.sa-east-1.amazonaws.com",
      "eu-west-1": "mediapackage-vod.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mediapackage-vod.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mediapackage-vod.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mediapackage-vod.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mediapackage-vod"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateAsset_402656474 = ref object of OpenApiRestCall_402656038
proc url_CreateAsset_402656476(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAsset_402656475(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new MediaPackage VOD Asset resource.
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
  var valid_402656477 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656477 = validateParameter(valid_402656477, JString,
                                      required = false, default = nil)
  if valid_402656477 != nil:
    section.add "X-Amz-Security-Token", valid_402656477
  var valid_402656478 = header.getOrDefault("X-Amz-Signature")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Signature", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656479
  var valid_402656480 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Algorithm", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Date")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Date", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Credential")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Credential", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656483
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

proc call*(call_402656485: Call_CreateAsset_402656474; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new MediaPackage VOD Asset resource.
                                                                                         ## 
  let valid = call_402656485.validator(path, query, header, formData, body, _)
  let scheme = call_402656485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656485.makeUrl(scheme.get, call_402656485.host, call_402656485.base,
                                   call_402656485.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656485, uri, valid, _)

proc call*(call_402656486: Call_CreateAsset_402656474; body: JsonNode): Recallable =
  ## createAsset
  ## Creates a new MediaPackage VOD Asset resource.
  ##   body: JObject (required)
  var body_402656487 = newJObject()
  if body != nil:
    body_402656487 = body
  result = call_402656486.call(nil, nil, nil, nil, body_402656487)

var createAsset* = Call_CreateAsset_402656474(name: "createAsset",
    meth: HttpMethod.HttpPost, host: "mediapackage-vod.amazonaws.com",
    route: "/assets", validator: validate_CreateAsset_402656475, base: "/",
    makeUrl: url_CreateAsset_402656476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssets_402656288 = ref object of OpenApiRestCall_402656038
proc url_ListAssets_402656290(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssets_402656289(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a collection of MediaPackage VOD Asset resources.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Upper bound on number of records to return.
  ##   
                                                                                              ## packagingGroupId: JString
                                                                                              ##                   
                                                                                              ## : 
                                                                                              ## Returns 
                                                                                              ## Assets 
                                                                                              ## associated 
                                                                                              ## with 
                                                                                              ## the 
                                                                                              ## specified 
                                                                                              ## PackagingGroup.
  ##   
                                                                                                                ## nextToken: JString
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## A 
                                                                                                                ## token 
                                                                                                                ## used 
                                                                                                                ## to 
                                                                                                                ## resume 
                                                                                                                ## pagination 
                                                                                                                ## from 
                                                                                                                ## the 
                                                                                                                ## end 
                                                                                                                ## of 
                                                                                                                ## a 
                                                                                                                ## previous 
                                                                                                                ## request.
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
  var valid_402656372 = query.getOrDefault("maxResults")
  valid_402656372 = validateParameter(valid_402656372, JInt, required = false,
                                      default = nil)
  if valid_402656372 != nil:
    section.add "maxResults", valid_402656372
  var valid_402656373 = query.getOrDefault("packagingGroupId")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "packagingGroupId", valid_402656373
  var valid_402656374 = query.getOrDefault("nextToken")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "nextToken", valid_402656374
  var valid_402656375 = query.getOrDefault("MaxResults")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "MaxResults", valid_402656375
  var valid_402656376 = query.getOrDefault("NextToken")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "NextToken", valid_402656376
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
  var valid_402656377 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Security-Token", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-Signature")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Signature", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Algorithm", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Date")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Date", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Credential")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Credential", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656397: Call_ListAssets_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a collection of MediaPackage VOD Asset resources.
                                                                                         ## 
  let valid = call_402656397.validator(path, query, header, formData, body, _)
  let scheme = call_402656397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656397.makeUrl(scheme.get, call_402656397.host, call_402656397.base,
                                   call_402656397.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656397, uri, valid, _)

proc call*(call_402656446: Call_ListAssets_402656288; maxResults: int = 0;
           packagingGroupId: string = ""; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAssets
  ## Returns a collection of MediaPackage VOD Asset resources.
  ##   maxResults: int
                                                              ##             : Upper bound on number of records to return.
  ##   
                                                                                                                          ## packagingGroupId: string
                                                                                                                          ##                   
                                                                                                                          ## : 
                                                                                                                          ## Returns 
                                                                                                                          ## Assets 
                                                                                                                          ## associated 
                                                                                                                          ## with 
                                                                                                                          ## the 
                                                                                                                          ## specified 
                                                                                                                          ## PackagingGroup.
  ##   
                                                                                                                                            ## nextToken: string
                                                                                                                                            ##            
                                                                                                                                            ## : 
                                                                                                                                            ## A 
                                                                                                                                            ## token 
                                                                                                                                            ## used 
                                                                                                                                            ## to 
                                                                                                                                            ## resume 
                                                                                                                                            ## pagination 
                                                                                                                                            ## from 
                                                                                                                                            ## the 
                                                                                                                                            ## end 
                                                                                                                                            ## of 
                                                                                                                                            ## a 
                                                                                                                                            ## previous 
                                                                                                                                            ## request.
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
  var query_402656447 = newJObject()
  add(query_402656447, "maxResults", newJInt(maxResults))
  add(query_402656447, "packagingGroupId", newJString(packagingGroupId))
  add(query_402656447, "nextToken", newJString(nextToken))
  add(query_402656447, "MaxResults", newJString(MaxResults))
  add(query_402656447, "NextToken", newJString(NextToken))
  result = call_402656446.call(nil, query_402656447, nil, nil, nil)

var listAssets* = Call_ListAssets_402656288(name: "listAssets",
    meth: HttpMethod.HttpGet, host: "mediapackage-vod.amazonaws.com",
    route: "/assets", validator: validate_ListAssets_402656289, base: "/",
    makeUrl: url_ListAssets_402656290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingConfiguration_402656506 = ref object of OpenApiRestCall_402656038
proc url_CreatePackagingConfiguration_402656508(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePackagingConfiguration_402656507(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
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
  var valid_402656509 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Security-Token", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Signature")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Signature", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Algorithm", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Date")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Date", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Credential")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Credential", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656515
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

proc call*(call_402656517: Call_CreatePackagingConfiguration_402656506;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
                                                                                         ## 
  let valid = call_402656517.validator(path, query, header, formData, body, _)
  let scheme = call_402656517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656517.makeUrl(scheme.get, call_402656517.host, call_402656517.base,
                                   call_402656517.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656517, uri, valid, _)

proc call*(call_402656518: Call_CreatePackagingConfiguration_402656506;
           body: JsonNode): Recallable =
  ## createPackagingConfiguration
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
  ##   body: JObject (required)
  var body_402656519 = newJObject()
  if body != nil:
    body_402656519 = body
  result = call_402656518.call(nil, nil, nil, nil, body_402656519)

var createPackagingConfiguration* = Call_CreatePackagingConfiguration_402656506(
    name: "createPackagingConfiguration", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_CreatePackagingConfiguration_402656507, base: "/",
    makeUrl: url_CreatePackagingConfiguration_402656508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingConfigurations_402656488 = ref object of OpenApiRestCall_402656038
proc url_ListPackagingConfigurations_402656490(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPackagingConfigurations_402656489(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Upper bound on number of records to return.
  ##   
                                                                                              ## packagingGroupId: JString
                                                                                              ##                   
                                                                                              ## : 
                                                                                              ## Returns 
                                                                                              ## MediaPackage 
                                                                                              ## VOD 
                                                                                              ## PackagingConfigurations 
                                                                                              ## associated 
                                                                                              ## with 
                                                                                              ## the 
                                                                                              ## specified 
                                                                                              ## PackagingGroup.
  ##   
                                                                                                                ## nextToken: JString
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## A 
                                                                                                                ## token 
                                                                                                                ## used 
                                                                                                                ## to 
                                                                                                                ## resume 
                                                                                                                ## pagination 
                                                                                                                ## from 
                                                                                                                ## the 
                                                                                                                ## end 
                                                                                                                ## of 
                                                                                                                ## a 
                                                                                                                ## previous 
                                                                                                                ## request.
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
  var valid_402656491 = query.getOrDefault("maxResults")
  valid_402656491 = validateParameter(valid_402656491, JInt, required = false,
                                      default = nil)
  if valid_402656491 != nil:
    section.add "maxResults", valid_402656491
  var valid_402656492 = query.getOrDefault("packagingGroupId")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "packagingGroupId", valid_402656492
  var valid_402656493 = query.getOrDefault("nextToken")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "nextToken", valid_402656493
  var valid_402656494 = query.getOrDefault("MaxResults")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "MaxResults", valid_402656494
  var valid_402656495 = query.getOrDefault("NextToken")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "NextToken", valid_402656495
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
  if body != nil:
    result.add "body", body

proc call*(call_402656503: Call_ListPackagingConfigurations_402656488;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
                                                                                         ## 
  let valid = call_402656503.validator(path, query, header, formData, body, _)
  let scheme = call_402656503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656503.makeUrl(scheme.get, call_402656503.host, call_402656503.base,
                                   call_402656503.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656503, uri, valid, _)

proc call*(call_402656504: Call_ListPackagingConfigurations_402656488;
           maxResults: int = 0; packagingGroupId: string = "";
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listPackagingConfigurations
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
  ##   
                                                                               ## maxResults: int
                                                                               ##             
                                                                               ## : 
                                                                               ## Upper 
                                                                               ## bound 
                                                                               ## on 
                                                                               ## number 
                                                                               ## of 
                                                                               ## records 
                                                                               ## to 
                                                                               ## return.
  ##   
                                                                                         ## packagingGroupId: string
                                                                                         ##                   
                                                                                         ## : 
                                                                                         ## Returns 
                                                                                         ## MediaPackage 
                                                                                         ## VOD 
                                                                                         ## PackagingConfigurations 
                                                                                         ## associated 
                                                                                         ## with 
                                                                                         ## the 
                                                                                         ## specified 
                                                                                         ## PackagingGroup.
  ##   
                                                                                                           ## nextToken: string
                                                                                                           ##            
                                                                                                           ## : 
                                                                                                           ## A 
                                                                                                           ## token 
                                                                                                           ## used 
                                                                                                           ## to 
                                                                                                           ## resume 
                                                                                                           ## pagination 
                                                                                                           ## from 
                                                                                                           ## the 
                                                                                                           ## end 
                                                                                                           ## of 
                                                                                                           ## a 
                                                                                                           ## previous 
                                                                                                           ## request.
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
  var query_402656505 = newJObject()
  add(query_402656505, "maxResults", newJInt(maxResults))
  add(query_402656505, "packagingGroupId", newJString(packagingGroupId))
  add(query_402656505, "nextToken", newJString(nextToken))
  add(query_402656505, "MaxResults", newJString(MaxResults))
  add(query_402656505, "NextToken", newJString(NextToken))
  result = call_402656504.call(nil, query_402656505, nil, nil, nil)

var listPackagingConfigurations* = Call_ListPackagingConfigurations_402656488(
    name: "listPackagingConfigurations", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_ListPackagingConfigurations_402656489, base: "/",
    makeUrl: url_ListPackagingConfigurations_402656490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingGroup_402656537 = ref object of OpenApiRestCall_402656038
proc url_CreatePackagingGroup_402656539(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePackagingGroup_402656538(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new MediaPackage VOD PackagingGroup resource.
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
  var valid_402656540 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Security-Token", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Signature")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Signature", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Algorithm", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Date")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Date", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Credential")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Credential", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656546
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

proc call*(call_402656548: Call_CreatePackagingGroup_402656537;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new MediaPackage VOD PackagingGroup resource.
                                                                                         ## 
  let valid = call_402656548.validator(path, query, header, formData, body, _)
  let scheme = call_402656548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656548.makeUrl(scheme.get, call_402656548.host, call_402656548.base,
                                   call_402656548.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656548, uri, valid, _)

proc call*(call_402656549: Call_CreatePackagingGroup_402656537; body: JsonNode): Recallable =
  ## createPackagingGroup
  ## Creates a new MediaPackage VOD PackagingGroup resource.
  ##   body: JObject (required)
  var body_402656550 = newJObject()
  if body != nil:
    body_402656550 = body
  result = call_402656549.call(nil, nil, nil, nil, body_402656550)

var createPackagingGroup* = Call_CreatePackagingGroup_402656537(
    name: "createPackagingGroup", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_CreatePackagingGroup_402656538, base: "/",
    makeUrl: url_CreatePackagingGroup_402656539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingGroups_402656520 = ref object of OpenApiRestCall_402656038
proc url_ListPackagingGroups_402656522(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPackagingGroups_402656521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Upper bound on number of records to return.
  ##   
                                                                                              ## nextToken: JString
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## A 
                                                                                              ## token 
                                                                                              ## used 
                                                                                              ## to 
                                                                                              ## resume 
                                                                                              ## pagination 
                                                                                              ## from 
                                                                                              ## the 
                                                                                              ## end 
                                                                                              ## of 
                                                                                              ## a 
                                                                                              ## previous 
                                                                                              ## request.
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
  var valid_402656523 = query.getOrDefault("maxResults")
  valid_402656523 = validateParameter(valid_402656523, JInt, required = false,
                                      default = nil)
  if valid_402656523 != nil:
    section.add "maxResults", valid_402656523
  var valid_402656524 = query.getOrDefault("nextToken")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "nextToken", valid_402656524
  var valid_402656525 = query.getOrDefault("MaxResults")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "MaxResults", valid_402656525
  var valid_402656526 = query.getOrDefault("NextToken")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "NextToken", valid_402656526
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
  var valid_402656527 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Security-Token", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Signature")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Signature", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Algorithm", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Date")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Date", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Credential")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Credential", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656534: Call_ListPackagingGroups_402656520;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
                                                                                         ## 
  let valid = call_402656534.validator(path, query, header, formData, body, _)
  let scheme = call_402656534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656534.makeUrl(scheme.get, call_402656534.host, call_402656534.base,
                                   call_402656534.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656534, uri, valid, _)

proc call*(call_402656535: Call_ListPackagingGroups_402656520;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listPackagingGroups
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
  ##   
                                                                       ## maxResults: int
                                                                       ##             
                                                                       ## : 
                                                                       ## Upper 
                                                                       ## bound 
                                                                       ## on 
                                                                       ## number of 
                                                                       ## records 
                                                                       ## to 
                                                                       ## return.
  ##   
                                                                                 ## nextToken: string
                                                                                 ##            
                                                                                 ## : 
                                                                                 ## A 
                                                                                 ## token 
                                                                                 ## used 
                                                                                 ## to 
                                                                                 ## resume 
                                                                                 ## pagination 
                                                                                 ## from 
                                                                                 ## the 
                                                                                 ## end 
                                                                                 ## of 
                                                                                 ## a 
                                                                                 ## previous 
                                                                                 ## request.
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
  var query_402656536 = newJObject()
  add(query_402656536, "maxResults", newJInt(maxResults))
  add(query_402656536, "nextToken", newJString(nextToken))
  add(query_402656536, "MaxResults", newJString(MaxResults))
  add(query_402656536, "NextToken", newJString(NextToken))
  result = call_402656535.call(nil, query_402656536, nil, nil, nil)

var listPackagingGroups* = Call_ListPackagingGroups_402656520(
    name: "listPackagingGroups", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_ListPackagingGroups_402656521, base: "/",
    makeUrl: url_ListPackagingGroups_402656522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAsset_402656551 = ref object of OpenApiRestCall_402656038
proc url_DescribeAsset_402656553(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/assets/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeAsset_402656552(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a description of a MediaPackage VOD Asset resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of an MediaPackage VOD Asset resource.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656565 = path.getOrDefault("id")
  valid_402656565 = validateParameter(valid_402656565, JString, required = true,
                                      default = nil)
  if valid_402656565 != nil:
    section.add "id", valid_402656565
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
  var valid_402656566 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Security-Token", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Signature")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Signature", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Algorithm", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Date")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Date", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Credential")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Credential", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656573: Call_DescribeAsset_402656551; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a description of a MediaPackage VOD Asset resource.
                                                                                         ## 
  let valid = call_402656573.validator(path, query, header, formData, body, _)
  let scheme = call_402656573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656573.makeUrl(scheme.get, call_402656573.host, call_402656573.base,
                                   call_402656573.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656573, uri, valid, _)

proc call*(call_402656574: Call_DescribeAsset_402656551; id: string): Recallable =
  ## describeAsset
  ## Returns a description of a MediaPackage VOD Asset resource.
  ##   id: string (required)
                                                                ##     : The ID of an MediaPackage VOD Asset resource.
  var path_402656575 = newJObject()
  add(path_402656575, "id", newJString(id))
  result = call_402656574.call(path_402656575, nil, nil, nil, nil)

var describeAsset* = Call_DescribeAsset_402656551(name: "describeAsset",
    meth: HttpMethod.HttpGet, host: "mediapackage-vod.amazonaws.com",
    route: "/assets/{id}", validator: validate_DescribeAsset_402656552,
    base: "/", makeUrl: url_DescribeAsset_402656553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_402656576 = ref object of OpenApiRestCall_402656038
proc url_DeleteAsset_402656578(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/assets/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAsset_402656577(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing MediaPackage VOD Asset resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the MediaPackage VOD Asset resource to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656579 = path.getOrDefault("id")
  valid_402656579 = validateParameter(valid_402656579, JString, required = true,
                                      default = nil)
  if valid_402656579 != nil:
    section.add "id", valid_402656579
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
  var valid_402656580 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Security-Token", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Signature")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Signature", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Algorithm", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Date")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Date", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Credential")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Credential", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656587: Call_DeleteAsset_402656576; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing MediaPackage VOD Asset resource.
                                                                                         ## 
  let valid = call_402656587.validator(path, query, header, formData, body, _)
  let scheme = call_402656587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656587.makeUrl(scheme.get, call_402656587.host, call_402656587.base,
                                   call_402656587.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656587, uri, valid, _)

proc call*(call_402656588: Call_DeleteAsset_402656576; id: string): Recallable =
  ## deleteAsset
  ## Deletes an existing MediaPackage VOD Asset resource.
  ##   id: string (required)
                                                         ##     : The ID of the MediaPackage VOD Asset resource to delete.
  var path_402656589 = newJObject()
  add(path_402656589, "id", newJString(id))
  result = call_402656588.call(path_402656589, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_402656576(name: "deleteAsset",
    meth: HttpMethod.HttpDelete, host: "mediapackage-vod.amazonaws.com",
    route: "/assets/{id}", validator: validate_DeleteAsset_402656577, base: "/",
    makeUrl: url_DeleteAsset_402656578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingConfiguration_402656590 = ref object of OpenApiRestCall_402656038
proc url_DescribePackagingConfiguration_402656592(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/packaging_configurations/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribePackagingConfiguration_402656591(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of a MediaPackage VOD PackagingConfiguration resource.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656593 = path.getOrDefault("id")
  valid_402656593 = validateParameter(valid_402656593, JString, required = true,
                                      default = nil)
  if valid_402656593 != nil:
    section.add "id", valid_402656593
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
  var valid_402656594 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Security-Token", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Signature")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Signature", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Algorithm", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Date")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Date", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Credential")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Credential", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656601: Call_DescribePackagingConfiguration_402656590;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
                                                                                         ## 
  let valid = call_402656601.validator(path, query, header, formData, body, _)
  let scheme = call_402656601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656601.makeUrl(scheme.get, call_402656601.host, call_402656601.base,
                                   call_402656601.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656601, uri, valid, _)

proc call*(call_402656602: Call_DescribePackagingConfiguration_402656590;
           id: string): Recallable =
  ## describePackagingConfiguration
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ##   
                                                                                 ## id: string (required)
                                                                                 ##     
                                                                                 ## : 
                                                                                 ## The 
                                                                                 ## ID 
                                                                                 ## of 
                                                                                 ## a 
                                                                                 ## MediaPackage 
                                                                                 ## VOD 
                                                                                 ## PackagingConfiguration 
                                                                                 ## resource.
  var path_402656603 = newJObject()
  add(path_402656603, "id", newJString(id))
  result = call_402656602.call(path_402656603, nil, nil, nil, nil)

var describePackagingConfiguration* = Call_DescribePackagingConfiguration_402656590(
    name: "describePackagingConfiguration", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DescribePackagingConfiguration_402656591, base: "/",
    makeUrl: url_DescribePackagingConfiguration_402656592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingConfiguration_402656604 = ref object of OpenApiRestCall_402656038
proc url_DeletePackagingConfiguration_402656606(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/packaging_configurations/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePackagingConfiguration_402656605(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the MediaPackage VOD PackagingConfiguration resource to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656607 = path.getOrDefault("id")
  valid_402656607 = validateParameter(valid_402656607, JString, required = true,
                                      default = nil)
  if valid_402656607 != nil:
    section.add "id", valid_402656607
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
  var valid_402656608 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Security-Token", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Signature")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Signature", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Algorithm", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Date")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Date", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Credential")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Credential", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656615: Call_DeletePackagingConfiguration_402656604;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
                                                                                         ## 
  let valid = call_402656615.validator(path, query, header, formData, body, _)
  let scheme = call_402656615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656615.makeUrl(scheme.get, call_402656615.host, call_402656615.base,
                                   call_402656615.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656615, uri, valid, _)

proc call*(call_402656616: Call_DeletePackagingConfiguration_402656604;
           id: string): Recallable =
  ## deletePackagingConfiguration
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ##   id: string (required)
                                                                ##     : The ID of the MediaPackage VOD PackagingConfiguration resource to delete.
  var path_402656617 = newJObject()
  add(path_402656617, "id", newJString(id))
  result = call_402656616.call(path_402656617, nil, nil, nil, nil)

var deletePackagingConfiguration* = Call_DeletePackagingConfiguration_402656604(
    name: "deletePackagingConfiguration", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DeletePackagingConfiguration_402656605, base: "/",
    makeUrl: url_DeletePackagingConfiguration_402656606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingGroup_402656618 = ref object of OpenApiRestCall_402656038
proc url_DescribePackagingGroup_402656620(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/packaging_groups/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribePackagingGroup_402656619(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of a MediaPackage VOD PackagingGroup resource.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656621 = path.getOrDefault("id")
  valid_402656621 = validateParameter(valid_402656621, JString, required = true,
                                      default = nil)
  if valid_402656621 != nil:
    section.add "id", valid_402656621
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

proc call*(call_402656629: Call_DescribePackagingGroup_402656618;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
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

proc call*(call_402656630: Call_DescribePackagingGroup_402656618; id: string): Recallable =
  ## describePackagingGroup
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ##   id: string 
                                                                         ## (required)
                                                                         ##     
                                                                         ## : 
                                                                         ## The ID of a 
                                                                         ## MediaPackage 
                                                                         ## VOD 
                                                                         ## PackagingGroup 
                                                                         ## resource.
  var path_402656631 = newJObject()
  add(path_402656631, "id", newJString(id))
  result = call_402656630.call(path_402656631, nil, nil, nil, nil)

var describePackagingGroup* = Call_DescribePackagingGroup_402656618(
    name: "describePackagingGroup", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DescribePackagingGroup_402656619, base: "/",
    makeUrl: url_DescribePackagingGroup_402656620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingGroup_402656632 = ref object of OpenApiRestCall_402656038
proc url_DeletePackagingGroup_402656634(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/packaging_groups/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePackagingGroup_402656633(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a MediaPackage VOD PackagingGroup resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the MediaPackage VOD PackagingGroup resource to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656635 = path.getOrDefault("id")
  valid_402656635 = validateParameter(valid_402656635, JString, required = true,
                                      default = nil)
  if valid_402656635 != nil:
    section.add "id", valid_402656635
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
  var valid_402656636 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Security-Token", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Signature")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Signature", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Algorithm", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Date")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Date", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Credential")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Credential", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656643: Call_DeletePackagingGroup_402656632;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a MediaPackage VOD PackagingGroup resource.
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

proc call*(call_402656644: Call_DeletePackagingGroup_402656632; id: string): Recallable =
  ## deletePackagingGroup
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ##   id: string (required)
                                                        ##     : The ID of the MediaPackage VOD PackagingGroup resource to delete.
  var path_402656645 = newJObject()
  add(path_402656645, "id", newJString(id))
  result = call_402656644.call(path_402656645, nil, nil, nil, nil)

var deletePackagingGroup* = Call_DeletePackagingGroup_402656632(
    name: "deletePackagingGroup", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DeletePackagingGroup_402656633, base: "/",
    makeUrl: url_DeletePackagingGroup_402656634,
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