
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS MediaTailor
## version: 2018-04-23
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Use the AWS Elemental MediaTailor SDK to configure scalable ad insertion for your live and VOD content. With AWS Elemental MediaTailor, you can serve targeted ads to viewers while maintaining broadcast quality in over-the-top (OTT) video applications. For information about using the service, including detailed information about the settings covered in this guide, see the AWS Elemental MediaTailor User Guide.<p>Through the SDK, you manage AWS Elemental MediaTailor configurations the same as you do through the console. For example, you specify ad insertion behavior and mapping information for the origin server and the ad decision server (ADS).</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mediatailor/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "api.mediatailor.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.mediatailor.ap-southeast-1.amazonaws.com", "us-west-2": "api.mediatailor.us-west-2.amazonaws.com", "eu-west-2": "api.mediatailor.eu-west-2.amazonaws.com", "ap-northeast-3": "api.mediatailor.ap-northeast-3.amazonaws.com", "eu-central-1": "api.mediatailor.eu-central-1.amazonaws.com", "us-east-2": "api.mediatailor.us-east-2.amazonaws.com", "us-east-1": "api.mediatailor.us-east-1.amazonaws.com", "cn-northwest-1": "api.mediatailor.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.mediatailor.ap-south-1.amazonaws.com", "eu-north-1": "api.mediatailor.eu-north-1.amazonaws.com", "ap-northeast-2": "api.mediatailor.ap-northeast-2.amazonaws.com", "us-west-1": "api.mediatailor.us-west-1.amazonaws.com", "us-gov-east-1": "api.mediatailor.us-gov-east-1.amazonaws.com", "eu-west-3": "api.mediatailor.eu-west-3.amazonaws.com", "cn-north-1": "api.mediatailor.cn-north-1.amazonaws.com.cn", "sa-east-1": "api.mediatailor.sa-east-1.amazonaws.com", "eu-west-1": "api.mediatailor.eu-west-1.amazonaws.com", "us-gov-west-1": "api.mediatailor.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.mediatailor.ap-southeast-2.amazonaws.com", "ca-central-1": "api.mediatailor.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "api.mediatailor.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.mediatailor.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.mediatailor.us-west-2.amazonaws.com",
      "eu-west-2": "api.mediatailor.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.mediatailor.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.mediatailor.eu-central-1.amazonaws.com",
      "us-east-2": "api.mediatailor.us-east-2.amazonaws.com",
      "us-east-1": "api.mediatailor.us-east-1.amazonaws.com",
      "cn-northwest-1": "api.mediatailor.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.mediatailor.ap-south-1.amazonaws.com",
      "eu-north-1": "api.mediatailor.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.mediatailor.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.mediatailor.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.mediatailor.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.mediatailor.eu-west-3.amazonaws.com",
      "cn-north-1": "api.mediatailor.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.mediatailor.sa-east-1.amazonaws.com",
      "eu-west-1": "api.mediatailor.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.mediatailor.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.mediatailor.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.mediatailor.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mediatailor"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_GetPlaybackConfiguration_402656288 = ref object of OpenApiRestCall_402656038
proc url_GetPlaybackConfiguration_402656290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Name" in path, "`Name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/playbackConfiguration/"),
                 (kind: VariableSegment, value: "Name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPlaybackConfiguration_402656289(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the playback configuration for the specified name. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Name: JString (required)
                                 ##       : The identifier for the playback configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Name` field"
  var valid_402656380 = path.getOrDefault("Name")
  valid_402656380 = validateParameter(valid_402656380, JString, required = true,
                                      default = nil)
  if valid_402656380 != nil:
    section.add "Name", valid_402656380
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
  var valid_402656381 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Security-Token", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Signature")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Signature", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Algorithm", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Date")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Date", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Credential")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Credential", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656401: Call_GetPlaybackConfiguration_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the playback configuration for the specified name. 
                                                                                         ## 
  let valid = call_402656401.validator(path, query, header, formData, body, _)
  let scheme = call_402656401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656401.makeUrl(scheme.get, call_402656401.host, call_402656401.base,
                                   call_402656401.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656401, uri, valid, _)

proc call*(call_402656450: Call_GetPlaybackConfiguration_402656288; Name: string): Recallable =
  ## getPlaybackConfiguration
  ## Returns the playback configuration for the specified name. 
  ##   Name: string (required)
                                                                ##       : The identifier for the playback configuration.
  var path_402656451 = newJObject()
  add(path_402656451, "Name", newJString(Name))
  result = call_402656450.call(path_402656451, nil, nil, nil, nil)

var getPlaybackConfiguration* = Call_GetPlaybackConfiguration_402656288(
    name: "getPlaybackConfiguration", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com",
    route: "/playbackConfiguration/{Name}",
    validator: validate_GetPlaybackConfiguration_402656289, base: "/",
    makeUrl: url_GetPlaybackConfiguration_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePlaybackConfiguration_402656481 = ref object of OpenApiRestCall_402656038
proc url_DeletePlaybackConfiguration_402656483(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Name" in path, "`Name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/playbackConfiguration/"),
                 (kind: VariableSegment, value: "Name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePlaybackConfiguration_402656482(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the playback configuration for the specified name. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Name: JString (required)
                                 ##       : The identifier for the playback configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Name` field"
  var valid_402656484 = path.getOrDefault("Name")
  valid_402656484 = validateParameter(valid_402656484, JString, required = true,
                                      default = nil)
  if valid_402656484 != nil:
    section.add "Name", valid_402656484
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
  var valid_402656485 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Security-Token", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Signature")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Signature", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Algorithm", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Date")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Date", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Credential")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Credential", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656492: Call_DeletePlaybackConfiguration_402656481;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the playback configuration for the specified name. 
                                                                                         ## 
  let valid = call_402656492.validator(path, query, header, formData, body, _)
  let scheme = call_402656492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656492.makeUrl(scheme.get, call_402656492.host, call_402656492.base,
                                   call_402656492.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656492, uri, valid, _)

proc call*(call_402656493: Call_DeletePlaybackConfiguration_402656481;
           Name: string): Recallable =
  ## deletePlaybackConfiguration
  ## Deletes the playback configuration for the specified name. 
  ##   Name: string (required)
                                                                ##       : The identifier for the playback configuration.
  var path_402656494 = newJObject()
  add(path_402656494, "Name", newJString(Name))
  result = call_402656493.call(path_402656494, nil, nil, nil, nil)

var deletePlaybackConfiguration* = Call_DeletePlaybackConfiguration_402656481(
    name: "deletePlaybackConfiguration", meth: HttpMethod.HttpDelete,
    host: "api.mediatailor.amazonaws.com",
    route: "/playbackConfiguration/{Name}",
    validator: validate_DeletePlaybackConfiguration_402656482, base: "/",
    makeUrl: url_DeletePlaybackConfiguration_402656483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPlaybackConfigurations_402656495 = ref object of OpenApiRestCall_402656038
proc url_ListPlaybackConfigurations_402656497(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPlaybackConfigurations_402656496(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : Maximum number of records to return. 
  ##   
                                                                                        ## NextToken: JString
                                                                                        ##            
                                                                                        ## : 
                                                                                        ## Pagination 
                                                                                        ## token 
                                                                                        ## returned 
                                                                                        ## by 
                                                                                        ## the 
                                                                                        ## GET 
                                                                                        ## list 
                                                                                        ## request 
                                                                                        ## when 
                                                                                        ## results 
                                                                                        ## exceed 
                                                                                        ## the 
                                                                                        ## maximum 
                                                                                        ## allowed. 
                                                                                        ## Use 
                                                                                        ## the 
                                                                                        ## token 
                                                                                        ## to 
                                                                                        ## fetch 
                                                                                        ## the 
                                                                                        ## next 
                                                                                        ## page 
                                                                                        ## of 
                                                                                        ## results.
  section = newJObject()
  var valid_402656498 = query.getOrDefault("MaxResults")
  valid_402656498 = validateParameter(valid_402656498, JInt, required = false,
                                      default = nil)
  if valid_402656498 != nil:
    section.add "MaxResults", valid_402656498
  var valid_402656499 = query.getOrDefault("NextToken")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "NextToken", valid_402656499
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
  var valid_402656500 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Security-Token", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Signature")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Signature", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Algorithm", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Date")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Date", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Credential")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Credential", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656507: Call_ListPlaybackConfigurations_402656495;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
                                                                                         ## 
  let valid = call_402656507.validator(path, query, header, formData, body, _)
  let scheme = call_402656507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656507.makeUrl(scheme.get, call_402656507.host, call_402656507.base,
                                   call_402656507.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656507, uri, valid, _)

proc call*(call_402656508: Call_ListPlaybackConfigurations_402656495;
           MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## listPlaybackConfigurations
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                       ## MaxResults: int
                                                                                                                                                                                                                                                                                                                                                                                       ##             
                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                       ## Maximum 
                                                                                                                                                                                                                                                                                                                                                                                       ## number 
                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                       ## records 
                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                       ## return. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                  ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                  ## token 
                                                                                                                                                                                                                                                                                                                                                                                                  ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                  ## by 
                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                  ## GET 
                                                                                                                                                                                                                                                                                                                                                                                                  ## list 
                                                                                                                                                                                                                                                                                                                                                                                                  ## request 
                                                                                                                                                                                                                                                                                                                                                                                                  ## when 
                                                                                                                                                                                                                                                                                                                                                                                                  ## results 
                                                                                                                                                                                                                                                                                                                                                                                                  ## exceed 
                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                  ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                  ## allowed. 
                                                                                                                                                                                                                                                                                                                                                                                                  ## Use 
                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                  ## token 
                                                                                                                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                                                                                                                  ## fetch 
                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                  ## next 
                                                                                                                                                                                                                                                                                                                                                                                                  ## page 
                                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                                  ## results.
  var query_402656509 = newJObject()
  add(query_402656509, "MaxResults", newJInt(MaxResults))
  add(query_402656509, "NextToken", newJString(NextToken))
  result = call_402656508.call(nil, query_402656509, nil, nil, nil)

var listPlaybackConfigurations* = Call_ListPlaybackConfigurations_402656495(
    name: "listPlaybackConfigurations", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfigurations",
    validator: validate_ListPlaybackConfigurations_402656496, base: "/",
    makeUrl: url_ListPlaybackConfigurations_402656497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656524 = ref object of OpenApiRestCall_402656038
proc url_TagResource_402656526(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656525(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds tags to the specified playback configuration resource. You can specify one or more tags to add. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ResourceArn` field"
  var valid_402656527 = path.getOrDefault("ResourceArn")
  valid_402656527 = validateParameter(valid_402656527, JString, required = true,
                                      default = nil)
  if valid_402656527 != nil:
    section.add "ResourceArn", valid_402656527
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
  var valid_402656528 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Security-Token", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Signature")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Signature", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Algorithm", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Date")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Date", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Credential")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Credential", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656534
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

proc call*(call_402656536: Call_TagResource_402656524; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds tags to the specified playback configuration resource. You can specify one or more tags to add. 
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

proc call*(call_402656537: Call_TagResource_402656524; body: JsonNode;
           ResourceArn: string): Recallable =
  ## tagResource
  ## Adds tags to the specified playback configuration resource. You can specify one or more tags to add. 
  ##   
                                                                                                          ## body: JObject (required)
  ##   
                                                                                                                                     ## ResourceArn: string (required)
                                                                                                                                     ##              
                                                                                                                                     ## : 
                                                                                                                                     ## The 
                                                                                                                                     ## Amazon 
                                                                                                                                     ## Resource 
                                                                                                                                     ## Name 
                                                                                                                                     ## (ARN) 
                                                                                                                                     ## for 
                                                                                                                                     ## the 
                                                                                                                                     ## playback 
                                                                                                                                     ## configuration. 
                                                                                                                                     ## You 
                                                                                                                                     ## can 
                                                                                                                                     ## get 
                                                                                                                                     ## this 
                                                                                                                                     ## from 
                                                                                                                                     ## the 
                                                                                                                                     ## response 
                                                                                                                                     ## to 
                                                                                                                                     ## any 
                                                                                                                                     ## playback 
                                                                                                                                     ## configuration 
                                                                                                                                     ## request. 
  var path_402656538 = newJObject()
  var body_402656539 = newJObject()
  if body != nil:
    body_402656539 = body
  add(path_402656538, "ResourceArn", newJString(ResourceArn))
  result = call_402656537.call(path_402656538, nil, nil, nil, body_402656539)

var tagResource* = Call_TagResource_402656524(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "api.mediatailor.amazonaws.com",
    route: "/tags/{ResourceArn}", validator: validate_TagResource_402656525,
    base: "/", makeUrl: url_TagResource_402656526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656510 = ref object of OpenApiRestCall_402656038
proc url_ListTagsForResource_402656512(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656511(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the tags assigned to the specified playback configuration resource. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ResourceArn` field"
  var valid_402656513 = path.getOrDefault("ResourceArn")
  valid_402656513 = validateParameter(valid_402656513, JString, required = true,
                                      default = nil)
  if valid_402656513 != nil:
    section.add "ResourceArn", valid_402656513
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
  var valid_402656514 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Security-Token", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Signature")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Signature", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Algorithm", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Date")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Date", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Credential")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Credential", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656521: Call_ListTagsForResource_402656510;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the tags assigned to the specified playback configuration resource. 
                                                                                         ## 
  let valid = call_402656521.validator(path, query, header, formData, body, _)
  let scheme = call_402656521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656521.makeUrl(scheme.get, call_402656521.host, call_402656521.base,
                                   call_402656521.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656521, uri, valid, _)

proc call*(call_402656522: Call_ListTagsForResource_402656510;
           ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified playback configuration resource. 
  ##   
                                                                                           ## ResourceArn: string (required)
                                                                                           ##              
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## Amazon 
                                                                                           ## Resource 
                                                                                           ## Name 
                                                                                           ## (ARN) 
                                                                                           ## for 
                                                                                           ## the 
                                                                                           ## playback 
                                                                                           ## configuration. 
                                                                                           ## You 
                                                                                           ## can 
                                                                                           ## get 
                                                                                           ## this 
                                                                                           ## from 
                                                                                           ## the 
                                                                                           ## response 
                                                                                           ## to 
                                                                                           ## any 
                                                                                           ## playback 
                                                                                           ## configuration 
                                                                                           ## request. 
  var path_402656523 = newJObject()
  add(path_402656523, "ResourceArn", newJString(ResourceArn))
  result = call_402656522.call(path_402656523, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656510(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_402656511, base: "/",
    makeUrl: url_ListTagsForResource_402656512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPlaybackConfiguration_402656540 = ref object of OpenApiRestCall_402656038
proc url_PutPlaybackConfiguration_402656542(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutPlaybackConfiguration_402656541(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
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
  var valid_402656543 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Security-Token", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Signature")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Signature", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Algorithm", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Date")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Date", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Credential")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Credential", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656549
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

proc call*(call_402656551: Call_PutPlaybackConfiguration_402656540;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
                                                                                         ## 
  let valid = call_402656551.validator(path, query, header, formData, body, _)
  let scheme = call_402656551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656551.makeUrl(scheme.get, call_402656551.host, call_402656551.base,
                                   call_402656551.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656551, uri, valid, _)

proc call*(call_402656552: Call_PutPlaybackConfiguration_402656540;
           body: JsonNode): Recallable =
  ## putPlaybackConfiguration
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
  ##   body: JObject (required)
  var body_402656553 = newJObject()
  if body != nil:
    body_402656553 = body
  result = call_402656552.call(nil, nil, nil, nil, body_402656553)

var putPlaybackConfiguration* = Call_PutPlaybackConfiguration_402656540(
    name: "putPlaybackConfiguration", meth: HttpMethod.HttpPut,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration",
    validator: validate_PutPlaybackConfiguration_402656541, base: "/",
    makeUrl: url_PutPlaybackConfiguration_402656542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656554 = ref object of OpenApiRestCall_402656038
proc url_UntagResource_402656556(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "ResourceArn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656555(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes tags from the specified playback configuration resource. You can specify one or more tags to remove. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ResourceArn` field"
  var valid_402656557 = path.getOrDefault("ResourceArn")
  valid_402656557 = validateParameter(valid_402656557, JString, required = true,
                                      default = nil)
  if valid_402656557 != nil:
    section.add "ResourceArn", valid_402656557
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : A comma-separated list of the tag keys to remove from the playback configuration. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656558 = query.getOrDefault("tagKeys")
  valid_402656558 = validateParameter(valid_402656558, JArray, required = true,
                                      default = nil)
  if valid_402656558 != nil:
    section.add "tagKeys", valid_402656558
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
  var valid_402656559 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Security-Token", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Signature")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Signature", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Algorithm", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Date")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Date", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Credential")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Credential", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656566: Call_UntagResource_402656554; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags from the specified playback configuration resource. You can specify one or more tags to remove. 
                                                                                         ## 
  let valid = call_402656566.validator(path, query, header, formData, body, _)
  let scheme = call_402656566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656566.makeUrl(scheme.get, call_402656566.host, call_402656566.base,
                                   call_402656566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656566, uri, valid, _)

proc call*(call_402656567: Call_UntagResource_402656554; tagKeys: JsonNode;
           ResourceArn: string): Recallable =
  ## untagResource
  ## Removes tags from the specified playback configuration resource. You can specify one or more tags to remove. 
  ##   
                                                                                                                  ## tagKeys: JArray (required)
                                                                                                                  ##          
                                                                                                                  ## : 
                                                                                                                  ## A 
                                                                                                                  ## comma-separated 
                                                                                                                  ## list 
                                                                                                                  ## of 
                                                                                                                  ## the 
                                                                                                                  ## tag 
                                                                                                                  ## keys 
                                                                                                                  ## to 
                                                                                                                  ## remove 
                                                                                                                  ## from 
                                                                                                                  ## the 
                                                                                                                  ## playback 
                                                                                                                  ## configuration. 
  ##   
                                                                                                                                    ## ResourceArn: string (required)
                                                                                                                                    ##              
                                                                                                                                    ## : 
                                                                                                                                    ## The 
                                                                                                                                    ## Amazon 
                                                                                                                                    ## Resource 
                                                                                                                                    ## Name 
                                                                                                                                    ## (ARN) 
                                                                                                                                    ## for 
                                                                                                                                    ## the 
                                                                                                                                    ## playback 
                                                                                                                                    ## configuration. 
                                                                                                                                    ## You 
                                                                                                                                    ## can 
                                                                                                                                    ## get 
                                                                                                                                    ## this 
                                                                                                                                    ## from 
                                                                                                                                    ## the 
                                                                                                                                    ## response 
                                                                                                                                    ## to 
                                                                                                                                    ## any 
                                                                                                                                    ## playback 
                                                                                                                                    ## configuration 
                                                                                                                                    ## request. 
  var path_402656568 = newJObject()
  var query_402656569 = newJObject()
  if tagKeys != nil:
    query_402656569.add "tagKeys", tagKeys
  add(path_402656568, "ResourceArn", newJString(ResourceArn))
  result = call_402656567.call(path_402656568, query_402656569, nil, nil, nil)

var untagResource* = Call_UntagResource_402656554(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "api.mediatailor.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_402656555,
    base: "/", makeUrl: url_UntagResource_402656556,
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