
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Elemental MediaPackage
## version: 2017-10-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Elemental MediaPackage
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mediapackage/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "mediapackage.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mediapackage.ap-southeast-1.amazonaws.com", "us-west-2": "mediapackage.us-west-2.amazonaws.com", "eu-west-2": "mediapackage.eu-west-2.amazonaws.com", "ap-northeast-3": "mediapackage.ap-northeast-3.amazonaws.com", "eu-central-1": "mediapackage.eu-central-1.amazonaws.com", "us-east-2": "mediapackage.us-east-2.amazonaws.com", "us-east-1": "mediapackage.us-east-1.amazonaws.com", "cn-northwest-1": "mediapackage.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "mediapackage.ap-south-1.amazonaws.com", "eu-north-1": "mediapackage.eu-north-1.amazonaws.com", "ap-northeast-2": "mediapackage.ap-northeast-2.amazonaws.com", "us-west-1": "mediapackage.us-west-1.amazonaws.com", "us-gov-east-1": "mediapackage.us-gov-east-1.amazonaws.com", "eu-west-3": "mediapackage.eu-west-3.amazonaws.com", "cn-north-1": "mediapackage.cn-north-1.amazonaws.com.cn", "sa-east-1": "mediapackage.sa-east-1.amazonaws.com", "eu-west-1": "mediapackage.eu-west-1.amazonaws.com", "us-gov-west-1": "mediapackage.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mediapackage.ap-southeast-2.amazonaws.com", "ca-central-1": "mediapackage.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "mediapackage.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mediapackage.ap-southeast-1.amazonaws.com",
      "us-west-2": "mediapackage.us-west-2.amazonaws.com",
      "eu-west-2": "mediapackage.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mediapackage.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mediapackage.eu-central-1.amazonaws.com",
      "us-east-2": "mediapackage.us-east-2.amazonaws.com",
      "us-east-1": "mediapackage.us-east-1.amazonaws.com",
      "cn-northwest-1": "mediapackage.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mediapackage.ap-south-1.amazonaws.com",
      "eu-north-1": "mediapackage.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mediapackage.ap-northeast-2.amazonaws.com",
      "us-west-1": "mediapackage.us-west-1.amazonaws.com",
      "us-gov-east-1": "mediapackage.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mediapackage.eu-west-3.amazonaws.com",
      "cn-north-1": "mediapackage.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mediapackage.sa-east-1.amazonaws.com",
      "eu-west-1": "mediapackage.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mediapackage.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mediapackage.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mediapackage.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mediapackage"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateChannel_402656479 = ref object of OpenApiRestCall_402656044
proc url_CreateChannel_402656481(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateChannel_402656480(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new Channel.
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
  var valid_402656482 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Security-Token", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Signature")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Signature", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Algorithm", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Date")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Date", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Credential")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Credential", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656488
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

proc call*(call_402656490: Call_CreateChannel_402656479; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Channel.
                                                                                         ## 
  let valid = call_402656490.validator(path, query, header, formData, body, _)
  let scheme = call_402656490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656490.makeUrl(scheme.get, call_402656490.host, call_402656490.base,
                                   call_402656490.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656490, uri, valid, _)

proc call*(call_402656491: Call_CreateChannel_402656479; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new Channel.
  ##   body: JObject (required)
  var body_402656492 = newJObject()
  if body != nil:
    body_402656492 = body
  result = call_402656491.call(nil, nil, nil, nil, body_402656492)

var createChannel* = Call_CreateChannel_402656479(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_402656480, base: "/",
    makeUrl: url_CreateChannel_402656481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListChannels_402656296(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChannels_402656295(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a collection of Channels.
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
  var valid_402656378 = query.getOrDefault("maxResults")
  valid_402656378 = validateParameter(valid_402656378, JInt, required = false,
                                      default = nil)
  if valid_402656378 != nil:
    section.add "maxResults", valid_402656378
  var valid_402656379 = query.getOrDefault("nextToken")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "nextToken", valid_402656379
  var valid_402656380 = query.getOrDefault("MaxResults")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "MaxResults", valid_402656380
  var valid_402656381 = query.getOrDefault("NextToken")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "NextToken", valid_402656381
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
  var valid_402656382 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Security-Token", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Signature")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Signature", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Algorithm", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Date")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Date", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Credential")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Credential", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656402: Call_ListChannels_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a collection of Channels.
                                                                                         ## 
  let valid = call_402656402.validator(path, query, header, formData, body, _)
  let scheme = call_402656402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656402.makeUrl(scheme.get, call_402656402.host, call_402656402.base,
                                   call_402656402.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656402, uri, valid, _)

proc call*(call_402656451: Call_ListChannels_402656294; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listChannels
  ## Returns a collection of Channels.
  ##   maxResults: int
                                      ##             : Upper bound on number of records to return.
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
  var query_402656452 = newJObject()
  add(query_402656452, "maxResults", newJInt(maxResults))
  add(query_402656452, "nextToken", newJString(nextToken))
  add(query_402656452, "MaxResults", newJString(MaxResults))
  add(query_402656452, "NextToken", newJString(NextToken))
  result = call_402656451.call(nil, query_402656452, nil, nil, nil)

var listChannels* = Call_ListChannels_402656294(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_402656295, base: "/",
    makeUrl: url_ListChannels_402656296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHarvestJob_402656512 = ref object of OpenApiRestCall_402656044
proc url_CreateHarvestJob_402656514(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHarvestJob_402656513(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new HarvestJob record.
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
  var valid_402656515 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Security-Token", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Signature")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Signature", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Algorithm", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Date")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Date", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Credential")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Credential", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656521
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

proc call*(call_402656523: Call_CreateHarvestJob_402656512;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new HarvestJob record.
                                                                                         ## 
  let valid = call_402656523.validator(path, query, header, formData, body, _)
  let scheme = call_402656523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656523.makeUrl(scheme.get, call_402656523.host, call_402656523.base,
                                   call_402656523.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656523, uri, valid, _)

proc call*(call_402656524: Call_CreateHarvestJob_402656512; body: JsonNode): Recallable =
  ## createHarvestJob
  ## Creates a new HarvestJob record.
  ##   body: JObject (required)
  var body_402656525 = newJObject()
  if body != nil:
    body_402656525 = body
  result = call_402656524.call(nil, nil, nil, nil, body_402656525)

var createHarvestJob* = Call_CreateHarvestJob_402656512(
    name: "createHarvestJob", meth: HttpMethod.HttpPost,
    host: "mediapackage.amazonaws.com", route: "/harvest_jobs",
    validator: validate_CreateHarvestJob_402656513, base: "/",
    makeUrl: url_CreateHarvestJob_402656514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHarvestJobs_402656493 = ref object of OpenApiRestCall_402656044
proc url_ListHarvestJobs_402656495(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHarvestJobs_402656494(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a collection of HarvestJob records.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The upper bound on the number of records to return.
  ##   
                                                                                                      ## includeChannelId: JString
                                                                                                      ##                   
                                                                                                      ## : 
                                                                                                      ## When 
                                                                                                      ## specified, 
                                                                                                      ## the 
                                                                                                      ## request 
                                                                                                      ## will 
                                                                                                      ## return 
                                                                                                      ## only 
                                                                                                      ## HarvestJobs 
                                                                                                      ## associated 
                                                                                                      ## with 
                                                                                                      ## the 
                                                                                                      ## given 
                                                                                                      ## Channel 
                                                                                                      ## ID.
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
                                                                                                                       ## includeStatus: JString
                                                                                                                       ##                
                                                                                                                       ## : 
                                                                                                                       ## When 
                                                                                                                       ## specified, 
                                                                                                                       ## the 
                                                                                                                       ## request 
                                                                                                                       ## will 
                                                                                                                       ## return 
                                                                                                                       ## only 
                                                                                                                       ## HarvestJobs 
                                                                                                                       ## in 
                                                                                                                       ## the 
                                                                                                                       ## given 
                                                                                                                       ## status.
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
  var valid_402656496 = query.getOrDefault("maxResults")
  valid_402656496 = validateParameter(valid_402656496, JInt, required = false,
                                      default = nil)
  if valid_402656496 != nil:
    section.add "maxResults", valid_402656496
  var valid_402656497 = query.getOrDefault("includeChannelId")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "includeChannelId", valid_402656497
  var valid_402656498 = query.getOrDefault("nextToken")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "nextToken", valid_402656498
  var valid_402656499 = query.getOrDefault("includeStatus")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "includeStatus", valid_402656499
  var valid_402656500 = query.getOrDefault("MaxResults")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "MaxResults", valid_402656500
  var valid_402656501 = query.getOrDefault("NextToken")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "NextToken", valid_402656501
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
  var valid_402656502 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Security-Token", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Signature")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Signature", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Algorithm", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Date")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Date", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Credential")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Credential", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656509: Call_ListHarvestJobs_402656493; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a collection of HarvestJob records.
                                                                                         ## 
  let valid = call_402656509.validator(path, query, header, formData, body, _)
  let scheme = call_402656509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656509.makeUrl(scheme.get, call_402656509.host, call_402656509.base,
                                   call_402656509.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656509, uri, valid, _)

proc call*(call_402656510: Call_ListHarvestJobs_402656493; maxResults: int = 0;
           includeChannelId: string = ""; nextToken: string = "";
           includeStatus: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listHarvestJobs
  ## Returns a collection of HarvestJob records.
  ##   maxResults: int
                                                ##             : The upper bound on the number of records to return.
  ##   
                                                                                                                    ## includeChannelId: string
                                                                                                                    ##                   
                                                                                                                    ## : 
                                                                                                                    ## When 
                                                                                                                    ## specified, 
                                                                                                                    ## the 
                                                                                                                    ## request 
                                                                                                                    ## will 
                                                                                                                    ## return 
                                                                                                                    ## only 
                                                                                                                    ## HarvestJobs 
                                                                                                                    ## associated 
                                                                                                                    ## with 
                                                                                                                    ## the 
                                                                                                                    ## given 
                                                                                                                    ## Channel 
                                                                                                                    ## ID.
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
                                                                                                                                     ## includeStatus: string
                                                                                                                                     ##                
                                                                                                                                     ## : 
                                                                                                                                     ## When 
                                                                                                                                     ## specified, 
                                                                                                                                     ## the 
                                                                                                                                     ## request 
                                                                                                                                     ## will 
                                                                                                                                     ## return 
                                                                                                                                     ## only 
                                                                                                                                     ## HarvestJobs 
                                                                                                                                     ## in 
                                                                                                                                     ## the 
                                                                                                                                     ## given 
                                                                                                                                     ## status.
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
  var query_402656511 = newJObject()
  add(query_402656511, "maxResults", newJInt(maxResults))
  add(query_402656511, "includeChannelId", newJString(includeChannelId))
  add(query_402656511, "nextToken", newJString(nextToken))
  add(query_402656511, "includeStatus", newJString(includeStatus))
  add(query_402656511, "MaxResults", newJString(MaxResults))
  add(query_402656511, "NextToken", newJString(NextToken))
  result = call_402656510.call(nil, query_402656511, nil, nil, nil)

var listHarvestJobs* = Call_ListHarvestJobs_402656493(name: "listHarvestJobs",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/harvest_jobs", validator: validate_ListHarvestJobs_402656494,
    base: "/", makeUrl: url_ListHarvestJobs_402656495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOriginEndpoint_402656544 = ref object of OpenApiRestCall_402656044
proc url_CreateOriginEndpoint_402656546(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOriginEndpoint_402656545(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new OriginEndpoint record.
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
  var valid_402656547 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Security-Token", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Signature")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Signature", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Algorithm", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Date")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Date", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Credential")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Credential", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656553
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

proc call*(call_402656555: Call_CreateOriginEndpoint_402656544;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new OriginEndpoint record.
                                                                                         ## 
  let valid = call_402656555.validator(path, query, header, formData, body, _)
  let scheme = call_402656555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656555.makeUrl(scheme.get, call_402656555.host, call_402656555.base,
                                   call_402656555.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656555, uri, valid, _)

proc call*(call_402656556: Call_CreateOriginEndpoint_402656544; body: JsonNode): Recallable =
  ## createOriginEndpoint
  ## Creates a new OriginEndpoint record.
  ##   body: JObject (required)
  var body_402656557 = newJObject()
  if body != nil:
    body_402656557 = body
  result = call_402656556.call(nil, nil, nil, nil, body_402656557)

var createOriginEndpoint* = Call_CreateOriginEndpoint_402656544(
    name: "createOriginEndpoint", meth: HttpMethod.HttpPost,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_CreateOriginEndpoint_402656545, base: "/",
    makeUrl: url_CreateOriginEndpoint_402656546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOriginEndpoints_402656526 = ref object of OpenApiRestCall_402656044
proc url_ListOriginEndpoints_402656528(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOriginEndpoints_402656527(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a collection of OriginEndpoint records.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The upper bound on the number of records to return.
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
  ##   
                                                                                                                                 ## channelId: JString
                                                                                                                                 ##            
                                                                                                                                 ## : 
                                                                                                                                 ## When 
                                                                                                                                 ## specified, 
                                                                                                                                 ## the 
                                                                                                                                 ## request 
                                                                                                                                 ## will 
                                                                                                                                 ## return 
                                                                                                                                 ## only 
                                                                                                                                 ## OriginEndpoints 
                                                                                                                                 ## associated 
                                                                                                                                 ## with 
                                                                                                                                 ## the 
                                                                                                                                 ## given 
                                                                                                                                 ## Channel 
                                                                                                                                 ## ID.
  section = newJObject()
  var valid_402656529 = query.getOrDefault("maxResults")
  valid_402656529 = validateParameter(valid_402656529, JInt, required = false,
                                      default = nil)
  if valid_402656529 != nil:
    section.add "maxResults", valid_402656529
  var valid_402656530 = query.getOrDefault("nextToken")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "nextToken", valid_402656530
  var valid_402656531 = query.getOrDefault("MaxResults")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "MaxResults", valid_402656531
  var valid_402656532 = query.getOrDefault("NextToken")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "NextToken", valid_402656532
  var valid_402656533 = query.getOrDefault("channelId")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "channelId", valid_402656533
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
  var valid_402656534 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Security-Token", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Signature")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Signature", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Algorithm", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Date")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Date", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Credential")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Credential", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656541: Call_ListOriginEndpoints_402656526;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a collection of OriginEndpoint records.
                                                                                         ## 
  let valid = call_402656541.validator(path, query, header, formData, body, _)
  let scheme = call_402656541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656541.makeUrl(scheme.get, call_402656541.host, call_402656541.base,
                                   call_402656541.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656541, uri, valid, _)

proc call*(call_402656542: Call_ListOriginEndpoints_402656526;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""; channelId: string = ""): Recallable =
  ## listOriginEndpoints
  ## Returns a collection of OriginEndpoint records.
  ##   maxResults: int
                                                    ##             : The upper bound on the number of records to return.
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
  ##   
                                                                                                                                                   ## channelId: string
                                                                                                                                                   ##            
                                                                                                                                                   ## : 
                                                                                                                                                   ## When 
                                                                                                                                                   ## specified, 
                                                                                                                                                   ## the 
                                                                                                                                                   ## request 
                                                                                                                                                   ## will 
                                                                                                                                                   ## return 
                                                                                                                                                   ## only 
                                                                                                                                                   ## OriginEndpoints 
                                                                                                                                                   ## associated 
                                                                                                                                                   ## with 
                                                                                                                                                   ## the 
                                                                                                                                                   ## given 
                                                                                                                                                   ## Channel 
                                                                                                                                                   ## ID.
  var query_402656543 = newJObject()
  add(query_402656543, "maxResults", newJInt(maxResults))
  add(query_402656543, "nextToken", newJString(nextToken))
  add(query_402656543, "MaxResults", newJString(MaxResults))
  add(query_402656543, "NextToken", newJString(NextToken))
  add(query_402656543, "channelId", newJString(channelId))
  result = call_402656542.call(nil, query_402656543, nil, nil, nil)

var listOriginEndpoints* = Call_ListOriginEndpoints_402656526(
    name: "listOriginEndpoints", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_ListOriginEndpoints_402656527, base: "/",
    makeUrl: url_ListOriginEndpoints_402656528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_402656583 = ref object of OpenApiRestCall_402656044
proc url_UpdateChannel_402656585(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateChannel_402656584(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing Channel.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the Channel to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656586 = path.getOrDefault("id")
  valid_402656586 = validateParameter(valid_402656586, JString, required = true,
                                      default = nil)
  if valid_402656586 != nil:
    section.add "id", valid_402656586
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
  var valid_402656587 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Security-Token", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Signature")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Signature", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Algorithm", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Date")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Date", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Credential")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Credential", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656593
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

proc call*(call_402656595: Call_UpdateChannel_402656583; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing Channel.
                                                                                         ## 
  let valid = call_402656595.validator(path, query, header, formData, body, _)
  let scheme = call_402656595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656595.makeUrl(scheme.get, call_402656595.host, call_402656595.base,
                                   call_402656595.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656595, uri, valid, _)

proc call*(call_402656596: Call_UpdateChannel_402656583; id: string;
           body: JsonNode): Recallable =
  ## updateChannel
  ## Updates an existing Channel.
  ##   id: string (required)
                                 ##     : The ID of the Channel to update.
  ##   body: 
                                                                          ## JObject (required)
  var path_402656597 = newJObject()
  var body_402656598 = newJObject()
  add(path_402656597, "id", newJString(id))
  if body != nil:
    body_402656598 = body
  result = call_402656596.call(path_402656597, nil, nil, nil, body_402656598)

var updateChannel* = Call_UpdateChannel_402656583(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_UpdateChannel_402656584,
    base: "/", makeUrl: url_UpdateChannel_402656585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_402656558 = ref object of OpenApiRestCall_402656044
proc url_DescribeChannel_402656560(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeChannel_402656559(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details about a Channel.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of a Channel.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656572 = path.getOrDefault("id")
  valid_402656572 = validateParameter(valid_402656572, JString, required = true,
                                      default = nil)
  if valid_402656572 != nil:
    section.add "id", valid_402656572
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
  if body != nil:
    result.add "body", body

proc call*(call_402656580: Call_DescribeChannel_402656558; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about a Channel.
                                                                                         ## 
  let valid = call_402656580.validator(path, query, header, formData, body, _)
  let scheme = call_402656580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656580.makeUrl(scheme.get, call_402656580.host, call_402656580.base,
                                   call_402656580.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656580, uri, valid, _)

proc call*(call_402656581: Call_DescribeChannel_402656558; id: string): Recallable =
  ## describeChannel
  ## Gets details about a Channel.
  ##   id: string (required)
                                  ##     : The ID of a Channel.
  var path_402656582 = newJObject()
  add(path_402656582, "id", newJString(id))
  result = call_402656581.call(path_402656582, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_402656558(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DescribeChannel_402656559,
    base: "/", makeUrl: url_DescribeChannel_402656560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_402656599 = ref object of OpenApiRestCall_402656044
proc url_DeleteChannel_402656601(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteChannel_402656600(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing Channel.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the Channel to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656602 = path.getOrDefault("id")
  valid_402656602 = validateParameter(valid_402656602, JString, required = true,
                                      default = nil)
  if valid_402656602 != nil:
    section.add "id", valid_402656602
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
  var valid_402656603 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Security-Token", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Signature")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Signature", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Algorithm", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Date")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Date", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Credential")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Credential", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656610: Call_DeleteChannel_402656599; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing Channel.
                                                                                         ## 
  let valid = call_402656610.validator(path, query, header, formData, body, _)
  let scheme = call_402656610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656610.makeUrl(scheme.get, call_402656610.host, call_402656610.base,
                                   call_402656610.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656610, uri, valid, _)

proc call*(call_402656611: Call_DeleteChannel_402656599; id: string): Recallable =
  ## deleteChannel
  ## Deletes an existing Channel.
  ##   id: string (required)
                                 ##     : The ID of the Channel to delete.
  var path_402656612 = newJObject()
  add(path_402656612, "id", newJString(id))
  result = call_402656611.call(path_402656612, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_402656599(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DeleteChannel_402656600,
    base: "/", makeUrl: url_DeleteChannel_402656601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOriginEndpoint_402656627 = ref object of OpenApiRestCall_402656044
proc url_UpdateOriginEndpoint_402656629(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/origin_endpoints/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateOriginEndpoint_402656628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing OriginEndpoint.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the OriginEndpoint to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656630 = path.getOrDefault("id")
  valid_402656630 = validateParameter(valid_402656630, JString, required = true,
                                      default = nil)
  if valid_402656630 != nil:
    section.add "id", valid_402656630
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
  var valid_402656631 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Security-Token", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Signature")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Signature", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Algorithm", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Date")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Date", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Credential")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Credential", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656637
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

proc call*(call_402656639: Call_UpdateOriginEndpoint_402656627;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing OriginEndpoint.
                                                                                         ## 
  let valid = call_402656639.validator(path, query, header, formData, body, _)
  let scheme = call_402656639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656639.makeUrl(scheme.get, call_402656639.host, call_402656639.base,
                                   call_402656639.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656639, uri, valid, _)

proc call*(call_402656640: Call_UpdateOriginEndpoint_402656627; id: string;
           body: JsonNode): Recallable =
  ## updateOriginEndpoint
  ## Updates an existing OriginEndpoint.
  ##   id: string (required)
                                        ##     : The ID of the OriginEndpoint to update.
  ##   
                                                                                        ## body: JObject (required)
  var path_402656641 = newJObject()
  var body_402656642 = newJObject()
  add(path_402656641, "id", newJString(id))
  if body != nil:
    body_402656642 = body
  result = call_402656640.call(path_402656641, nil, nil, nil, body_402656642)

var updateOriginEndpoint* = Call_UpdateOriginEndpoint_402656627(
    name: "updateOriginEndpoint", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_UpdateOriginEndpoint_402656628, base: "/",
    makeUrl: url_UpdateOriginEndpoint_402656629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOriginEndpoint_402656613 = ref object of OpenApiRestCall_402656044
proc url_DescribeOriginEndpoint_402656615(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/origin_endpoints/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeOriginEndpoint_402656614(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details about an existing OriginEndpoint.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the OriginEndpoint.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656616 = path.getOrDefault("id")
  valid_402656616 = validateParameter(valid_402656616, JString, required = true,
                                      default = nil)
  if valid_402656616 != nil:
    section.add "id", valid_402656616
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
  var valid_402656617 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Security-Token", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Signature")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Signature", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Algorithm", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Date")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Date", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Credential")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Credential", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656624: Call_DescribeOriginEndpoint_402656613;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about an existing OriginEndpoint.
                                                                                         ## 
  let valid = call_402656624.validator(path, query, header, formData, body, _)
  let scheme = call_402656624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656624.makeUrl(scheme.get, call_402656624.host, call_402656624.base,
                                   call_402656624.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656624, uri, valid, _)

proc call*(call_402656625: Call_DescribeOriginEndpoint_402656613; id: string): Recallable =
  ## describeOriginEndpoint
  ## Gets details about an existing OriginEndpoint.
  ##   id: string (required)
                                                   ##     : The ID of the OriginEndpoint.
  var path_402656626 = newJObject()
  add(path_402656626, "id", newJString(id))
  result = call_402656625.call(path_402656626, nil, nil, nil, nil)

var describeOriginEndpoint* = Call_DescribeOriginEndpoint_402656613(
    name: "describeOriginEndpoint", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DescribeOriginEndpoint_402656614, base: "/",
    makeUrl: url_DescribeOriginEndpoint_402656615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOriginEndpoint_402656643 = ref object of OpenApiRestCall_402656044
proc url_DeleteOriginEndpoint_402656645(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/origin_endpoints/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteOriginEndpoint_402656644(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing OriginEndpoint.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the OriginEndpoint to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656646 = path.getOrDefault("id")
  valid_402656646 = validateParameter(valid_402656646, JString, required = true,
                                      default = nil)
  if valid_402656646 != nil:
    section.add "id", valid_402656646
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
  var valid_402656647 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Security-Token", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Signature")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Signature", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Algorithm", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Date")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Date", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Credential")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Credential", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656654: Call_DeleteOriginEndpoint_402656643;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing OriginEndpoint.
                                                                                         ## 
  let valid = call_402656654.validator(path, query, header, formData, body, _)
  let scheme = call_402656654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656654.makeUrl(scheme.get, call_402656654.host, call_402656654.base,
                                   call_402656654.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656654, uri, valid, _)

proc call*(call_402656655: Call_DeleteOriginEndpoint_402656643; id: string): Recallable =
  ## deleteOriginEndpoint
  ## Deletes an existing OriginEndpoint.
  ##   id: string (required)
                                        ##     : The ID of the OriginEndpoint to delete.
  var path_402656656 = newJObject()
  add(path_402656656, "id", newJString(id))
  result = call_402656655.call(path_402656656, nil, nil, nil, nil)

var deleteOriginEndpoint* = Call_DeleteOriginEndpoint_402656643(
    name: "deleteOriginEndpoint", meth: HttpMethod.HttpDelete,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DeleteOriginEndpoint_402656644, base: "/",
    makeUrl: url_DeleteOriginEndpoint_402656645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHarvestJob_402656657 = ref object of OpenApiRestCall_402656044
proc url_DescribeHarvestJob_402656659(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/harvest_jobs/"),
                 (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeHarvestJob_402656658(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details about an existing HarvestJob.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the HarvestJob.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656660 = path.getOrDefault("id")
  valid_402656660 = validateParameter(valid_402656660, JString, required = true,
                                      default = nil)
  if valid_402656660 != nil:
    section.add "id", valid_402656660
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
  var valid_402656661 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Security-Token", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Signature")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Signature", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Algorithm", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Date")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Date", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Credential")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Credential", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656668: Call_DescribeHarvestJob_402656657;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about an existing HarvestJob.
                                                                                         ## 
  let valid = call_402656668.validator(path, query, header, formData, body, _)
  let scheme = call_402656668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656668.makeUrl(scheme.get, call_402656668.host, call_402656668.base,
                                   call_402656668.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656668, uri, valid, _)

proc call*(call_402656669: Call_DescribeHarvestJob_402656657; id: string): Recallable =
  ## describeHarvestJob
  ## Gets details about an existing HarvestJob.
  ##   id: string (required)
                                               ##     : The ID of the HarvestJob.
  var path_402656670 = newJObject()
  add(path_402656670, "id", newJString(id))
  result = call_402656669.call(path_402656670, nil, nil, nil, nil)

var describeHarvestJob* = Call_DescribeHarvestJob_402656657(
    name: "describeHarvestJob", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/harvest_jobs/{id}",
    validator: validate_DescribeHarvestJob_402656658, base: "/",
    makeUrl: url_DescribeHarvestJob_402656659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656685 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656687(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656686(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656688 = path.getOrDefault("resource-arn")
  valid_402656688 = validateParameter(valid_402656688, JString, required = true,
                                      default = nil)
  if valid_402656688 != nil:
    section.add "resource-arn", valid_402656688
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
  var valid_402656689 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Security-Token", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Signature")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Signature", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Algorithm", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Date")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Date", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Credential")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Credential", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656695
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

proc call*(call_402656697: Call_TagResource_402656685; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656697.validator(path, query, header, formData, body, _)
  let scheme = call_402656697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656697.makeUrl(scheme.get, call_402656697.host, call_402656697.base,
                                   call_402656697.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656697, uri, valid, _)

proc call*(call_402656698: Call_TagResource_402656685; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  var path_402656699 = newJObject()
  var body_402656700 = newJObject()
  if body != nil:
    body_402656700 = body
  add(path_402656699, "resource-arn", newJString(resourceArn))
  result = call_402656698.call(path_402656699, nil, nil, nil, body_402656700)

var tagResource* = Call_TagResource_402656685(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/tags/{resource-arn}", validator: validate_TagResource_402656686,
    base: "/", makeUrl: url_TagResource_402656687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656671 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656673(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656674 = path.getOrDefault("resource-arn")
  valid_402656674 = validateParameter(valid_402656674, JString, required = true,
                                      default = nil)
  if valid_402656674 != nil:
    section.add "resource-arn", valid_402656674
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
  var valid_402656675 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Security-Token", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Signature")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Signature", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Algorithm", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Date")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Date", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Credential")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Credential", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656682: Call_ListTagsForResource_402656671;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656682.validator(path, query, header, formData, body, _)
  let scheme = call_402656682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656682.makeUrl(scheme.get, call_402656682.host, call_402656682.base,
                                   call_402656682.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656682, uri, valid, _)

proc call*(call_402656683: Call_ListTagsForResource_402656671;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ##   resourceArn: string (required)
  var path_402656684 = newJObject()
  add(path_402656684, "resource-arn", newJString(resourceArn))
  result = call_402656683.call(path_402656684, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656671(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_402656672, base: "/",
    makeUrl: url_ListTagsForResource_402656673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateChannelCredentials_402656701 = ref object of OpenApiRestCall_402656044
proc url_RotateChannelCredentials_402656703(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
                 (kind: VariableSegment, value: "id"),
                 (kind: ConstantSegment, value: "/credentials")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RotateChannelCredentials_402656702(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the channel to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656704 = path.getOrDefault("id")
  valid_402656704 = validateParameter(valid_402656704, JString, required = true,
                                      default = nil)
  if valid_402656704 != nil:
    section.add "id", valid_402656704
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
  var valid_402656705 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Security-Token", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Signature")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Signature", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Algorithm", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Date")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Date", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Credential")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Credential", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656712: Call_RotateChannelCredentials_402656701;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
                                                                                         ## 
  let valid = call_402656712.validator(path, query, header, formData, body, _)
  let scheme = call_402656712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656712.makeUrl(scheme.get, call_402656712.host, call_402656712.base,
                                   call_402656712.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656712, uri, valid, _)

proc call*(call_402656713: Call_RotateChannelCredentials_402656701; id: string): Recallable =
  ## rotateChannelCredentials
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ##   
                                                                                                                                                             ## id: string (required)
                                                                                                                                                             ##     
                                                                                                                                                             ## : 
                                                                                                                                                             ## The 
                                                                                                                                                             ## ID 
                                                                                                                                                             ## of 
                                                                                                                                                             ## the 
                                                                                                                                                             ## channel 
                                                                                                                                                             ## to 
                                                                                                                                                             ## update.
  var path_402656714 = newJObject()
  add(path_402656714, "id", newJString(id))
  result = call_402656713.call(path_402656714, nil, nil, nil, nil)

var rotateChannelCredentials* = Call_RotateChannelCredentials_402656701(
    name: "rotateChannelCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/channels/{id}/credentials",
    validator: validate_RotateChannelCredentials_402656702, base: "/",
    makeUrl: url_RotateChannelCredentials_402656703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateIngestEndpointCredentials_402656715 = ref object of OpenApiRestCall_402656044
proc url_RotateIngestEndpointCredentials_402656717(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  assert "ingest_endpoint_id" in path,
         "`ingest_endpoint_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
                 (kind: VariableSegment, value: "id"),
                 (kind: ConstantSegment, value: "/ingest_endpoints/"),
                 (kind: VariableSegment, value: "ingest_endpoint_id"),
                 (kind: ConstantSegment, value: "/credentials")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RotateIngestEndpointCredentials_402656716(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the channel the IngestEndpoint is on.
  ##   
                                                                                         ## ingest_endpoint_id: JString (required)
                                                                                         ##                     
                                                                                         ## : 
                                                                                         ## The 
                                                                                         ## id 
                                                                                         ## of 
                                                                                         ## the 
                                                                                         ## IngestEndpoint 
                                                                                         ## whose 
                                                                                         ## credentials 
                                                                                         ## should 
                                                                                         ## be 
                                                                                         ## rotated
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656718 = path.getOrDefault("id")
  valid_402656718 = validateParameter(valid_402656718, JString, required = true,
                                      default = nil)
  if valid_402656718 != nil:
    section.add "id", valid_402656718
  var valid_402656719 = path.getOrDefault("ingest_endpoint_id")
  valid_402656719 = validateParameter(valid_402656719, JString, required = true,
                                      default = nil)
  if valid_402656719 != nil:
    section.add "ingest_endpoint_id", valid_402656719
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
  var valid_402656720 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Security-Token", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Signature")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Signature", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Algorithm", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Date")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Date", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Credential")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Credential", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656727: Call_RotateIngestEndpointCredentials_402656715;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
                                                                                         ## 
  let valid = call_402656727.validator(path, query, header, formData, body, _)
  let scheme = call_402656727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656727.makeUrl(scheme.get, call_402656727.host, call_402656727.base,
                                   call_402656727.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656727, uri, valid, _)

proc call*(call_402656728: Call_RotateIngestEndpointCredentials_402656715;
           id: string; ingestEndpointId: string): Recallable =
  ## rotateIngestEndpointCredentials
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ##   
                                                                                                ## id: string (required)
                                                                                                ##     
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## ID 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## channel 
                                                                                                ## the 
                                                                                                ## IngestEndpoint 
                                                                                                ## is 
                                                                                                ## on.
  ##   
                                                                                                      ## ingestEndpointId: string (required)
                                                                                                      ##                   
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## id 
                                                                                                      ## of 
                                                                                                      ## the 
                                                                                                      ## IngestEndpoint 
                                                                                                      ## whose 
                                                                                                      ## credentials 
                                                                                                      ## should 
                                                                                                      ## be 
                                                                                                      ## rotated
  var path_402656729 = newJObject()
  add(path_402656729, "id", newJString(id))
  add(path_402656729, "ingest_endpoint_id", newJString(ingestEndpointId))
  result = call_402656728.call(path_402656729, nil, nil, nil, nil)

var rotateIngestEndpointCredentials* = Call_RotateIngestEndpointCredentials_402656715(
    name: "rotateIngestEndpointCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com",
    route: "/channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials",
    validator: validate_RotateIngestEndpointCredentials_402656716, base: "/",
    makeUrl: url_RotateIngestEndpointCredentials_402656717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656730 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656732(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resource-arn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656731(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656733 = path.getOrDefault("resource-arn")
  valid_402656733 = validateParameter(valid_402656733, JString, required = true,
                                      default = nil)
  if valid_402656733 != nil:
    section.add "resource-arn", valid_402656733
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The key(s) of tag to be deleted
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656734 = query.getOrDefault("tagKeys")
  valid_402656734 = validateParameter(valid_402656734, JArray, required = true,
                                      default = nil)
  if valid_402656734 != nil:
    section.add "tagKeys", valid_402656734
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
  var valid_402656735 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Security-Token", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Signature")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Signature", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Algorithm", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Date")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Date", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Credential")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Credential", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656742: Call_UntagResource_402656730; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656742.validator(path, query, header, formData, body, _)
  let scheme = call_402656742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656742.makeUrl(scheme.get, call_402656742.host, call_402656742.base,
                                   call_402656742.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656742, uri, valid, _)

proc call*(call_402656743: Call_UntagResource_402656730; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ##   tagKeys: JArray (required)
                  ##          : The key(s) of tag to be deleted
  ##   resourceArn: string (required)
  var path_402656744 = newJObject()
  var query_402656745 = newJObject()
  if tagKeys != nil:
    query_402656745.add "tagKeys", tagKeys
  add(path_402656744, "resource-arn", newJString(resourceArn))
  result = call_402656743.call(path_402656744, query_402656745, nil, nil, nil)

var untagResource* = Call_UntagResource_402656730(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_402656731,
    base: "/", makeUrl: url_UntagResource_402656732,
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