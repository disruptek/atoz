
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.mediatailor.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.mediatailor.ap-southeast-1.amazonaws.com", "us-west-2": "api.mediatailor.us-west-2.amazonaws.com", "eu-west-2": "api.mediatailor.eu-west-2.amazonaws.com", "ap-northeast-3": "api.mediatailor.ap-northeast-3.amazonaws.com", "eu-central-1": "api.mediatailor.eu-central-1.amazonaws.com", "us-east-2": "api.mediatailor.us-east-2.amazonaws.com", "us-east-1": "api.mediatailor.us-east-1.amazonaws.com", "cn-northwest-1": "api.mediatailor.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.mediatailor.ap-south-1.amazonaws.com", "eu-north-1": "api.mediatailor.eu-north-1.amazonaws.com", "ap-northeast-2": "api.mediatailor.ap-northeast-2.amazonaws.com", "us-west-1": "api.mediatailor.us-west-1.amazonaws.com", "us-gov-east-1": "api.mediatailor.us-gov-east-1.amazonaws.com", "eu-west-3": "api.mediatailor.eu-west-3.amazonaws.com", "cn-north-1": "api.mediatailor.cn-north-1.amazonaws.com.cn", "sa-east-1": "api.mediatailor.sa-east-1.amazonaws.com", "eu-west-1": "api.mediatailor.eu-west-1.amazonaws.com", "us-gov-west-1": "api.mediatailor.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.mediatailor.ap-southeast-2.amazonaws.com", "ca-central-1": "api.mediatailor.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_GetPlaybackConfiguration_21625770 = ref object of OpenApiRestCall_21625426
proc url_GetPlaybackConfiguration_21625772(protocol: Scheme; host: string;
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

proc validate_GetPlaybackConfiguration_21625771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the playback configuration for the specified name. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Name: JString (required)
  ##       : The identifier for the playback configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Name` field"
  var valid_21625886 = path.getOrDefault("Name")
  valid_21625886 = validateParameter(valid_21625886, JString, required = true,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "Name", valid_21625886
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
  var valid_21625887 = header.getOrDefault("X-Amz-Date")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Date", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Security-Token", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Algorithm", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-Signature")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-Signature", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625892
  var valid_21625893 = header.getOrDefault("X-Amz-Credential")
  valid_21625893 = validateParameter(valid_21625893, JString, required = false,
                                   default = nil)
  if valid_21625893 != nil:
    section.add "X-Amz-Credential", valid_21625893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625918: Call_GetPlaybackConfiguration_21625770;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the playback configuration for the specified name. 
  ## 
  let valid = call_21625918.validator(path, query, header, formData, body, _)
  let scheme = call_21625918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625918.makeUrl(scheme.get, call_21625918.host, call_21625918.base,
                               call_21625918.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625918, uri, valid, _)

proc call*(call_21625981: Call_GetPlaybackConfiguration_21625770; Name: string): Recallable =
  ## getPlaybackConfiguration
  ## Returns the playback configuration for the specified name. 
  ##   Name: string (required)
  ##       : The identifier for the playback configuration.
  var path_21625983 = newJObject()
  add(path_21625983, "Name", newJString(Name))
  result = call_21625981.call(path_21625983, nil, nil, nil, nil)

var getPlaybackConfiguration* = Call_GetPlaybackConfiguration_21625770(
    name: "getPlaybackConfiguration", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration/{Name}",
    validator: validate_GetPlaybackConfiguration_21625771, base: "/",
    makeUrl: url_GetPlaybackConfiguration_21625772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePlaybackConfiguration_21626021 = ref object of OpenApiRestCall_21625426
proc url_DeletePlaybackConfiguration_21626023(protocol: Scheme; host: string;
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

proc validate_DeletePlaybackConfiguration_21626022(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the playback configuration for the specified name. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Name: JString (required)
  ##       : The identifier for the playback configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Name` field"
  var valid_21626024 = path.getOrDefault("Name")
  valid_21626024 = validateParameter(valid_21626024, JString, required = true,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "Name", valid_21626024
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
  var valid_21626025 = header.getOrDefault("X-Amz-Date")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Date", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Security-Token", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Algorithm", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-Signature")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-Signature", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626030
  var valid_21626031 = header.getOrDefault("X-Amz-Credential")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-Credential", valid_21626031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626032: Call_DeletePlaybackConfiguration_21626021;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the playback configuration for the specified name. 
  ## 
  let valid = call_21626032.validator(path, query, header, formData, body, _)
  let scheme = call_21626032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626032.makeUrl(scheme.get, call_21626032.host, call_21626032.base,
                               call_21626032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626032, uri, valid, _)

proc call*(call_21626033: Call_DeletePlaybackConfiguration_21626021; Name: string): Recallable =
  ## deletePlaybackConfiguration
  ## Deletes the playback configuration for the specified name. 
  ##   Name: string (required)
  ##       : The identifier for the playback configuration.
  var path_21626034 = newJObject()
  add(path_21626034, "Name", newJString(Name))
  result = call_21626033.call(path_21626034, nil, nil, nil, nil)

var deletePlaybackConfiguration* = Call_DeletePlaybackConfiguration_21626021(
    name: "deletePlaybackConfiguration", meth: HttpMethod.HttpDelete,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration/{Name}",
    validator: validate_DeletePlaybackConfiguration_21626022, base: "/",
    makeUrl: url_DeletePlaybackConfiguration_21626023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPlaybackConfigurations_21626035 = ref object of OpenApiRestCall_21625426
proc url_ListPlaybackConfigurations_21626037(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPlaybackConfigurations_21626036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token returned by the GET list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
  ##   MaxResults: JInt
  ##             : Maximum number of records to return. 
  section = newJObject()
  var valid_21626038 = query.getOrDefault("NextToken")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "NextToken", valid_21626038
  var valid_21626039 = query.getOrDefault("MaxResults")
  valid_21626039 = validateParameter(valid_21626039, JInt, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "MaxResults", valid_21626039
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
  var valid_21626040 = header.getOrDefault("X-Amz-Date")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Date", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Security-Token", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Algorithm", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Signature")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Signature", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Credential")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Credential", valid_21626046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626047: Call_ListPlaybackConfigurations_21626035;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
  ## 
  let valid = call_21626047.validator(path, query, header, formData, body, _)
  let scheme = call_21626047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626047.makeUrl(scheme.get, call_21626047.host, call_21626047.base,
                               call_21626047.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626047, uri, valid, _)

proc call*(call_21626048: Call_ListPlaybackConfigurations_21626035;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listPlaybackConfigurations
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
  ##   NextToken: string
  ##            : Pagination token returned by the GET list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
  ##   MaxResults: int
  ##             : Maximum number of records to return. 
  var query_21626049 = newJObject()
  add(query_21626049, "NextToken", newJString(NextToken))
  add(query_21626049, "MaxResults", newJInt(MaxResults))
  result = call_21626048.call(nil, query_21626049, nil, nil, nil)

var listPlaybackConfigurations* = Call_ListPlaybackConfigurations_21626035(
    name: "listPlaybackConfigurations", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfigurations",
    validator: validate_ListPlaybackConfigurations_21626036, base: "/",
    makeUrl: url_ListPlaybackConfigurations_21626037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626065 = ref object of OpenApiRestCall_21625426
proc url_TagResource_21626067(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626066(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626068 = path.getOrDefault("ResourceArn")
  valid_21626068 = validateParameter(valid_21626068, JString, required = true,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "ResourceArn", valid_21626068
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626077: Call_TagResource_21626065; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds tags to the specified playback configuration resource. You can specify one or more tags to add. 
  ## 
  let valid = call_21626077.validator(path, query, header, formData, body, _)
  let scheme = call_21626077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626077.makeUrl(scheme.get, call_21626077.host, call_21626077.base,
                               call_21626077.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626077, uri, valid, _)

proc call*(call_21626078: Call_TagResource_21626065; ResourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to the specified playback configuration resource. You can specify one or more tags to add. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  ##   body: JObject (required)
  var path_21626079 = newJObject()
  var body_21626080 = newJObject()
  add(path_21626079, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_21626080 = body
  result = call_21626078.call(path_21626079, nil, nil, nil, body_21626080)

var tagResource* = Call_TagResource_21626065(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "api.mediatailor.amazonaws.com",
    route: "/tags/{ResourceArn}", validator: validate_TagResource_21626066,
    base: "/", makeUrl: url_TagResource_21626067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626051 = ref object of OpenApiRestCall_21625426
proc url_ListTagsForResource_21626053(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21626052(path: JsonNode; query: JsonNode;
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
  var valid_21626054 = path.getOrDefault("ResourceArn")
  valid_21626054 = validateParameter(valid_21626054, JString, required = true,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "ResourceArn", valid_21626054
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

proc call*(call_21626062: Call_ListTagsForResource_21626051; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the tags assigned to the specified playback configuration resource. 
  ## 
  let valid = call_21626062.validator(path, query, header, formData, body, _)
  let scheme = call_21626062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626062.makeUrl(scheme.get, call_21626062.host, call_21626062.base,
                               call_21626062.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626062, uri, valid, _)

proc call*(call_21626063: Call_ListTagsForResource_21626051; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified playback configuration resource. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  var path_21626064 = newJObject()
  add(path_21626064, "ResourceArn", newJString(ResourceArn))
  result = call_21626063.call(path_21626064, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626051(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_21626052, base: "/",
    makeUrl: url_ListTagsForResource_21626053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPlaybackConfiguration_21626081 = ref object of OpenApiRestCall_21625426
proc url_PutPlaybackConfiguration_21626083(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutPlaybackConfiguration_21626082(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
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
  var valid_21626084 = header.getOrDefault("X-Amz-Date")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Date", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Security-Token", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Algorithm", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Signature")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Signature", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Credential")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Credential", valid_21626090
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

proc call*(call_21626092: Call_PutPlaybackConfiguration_21626081;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
  ## 
  let valid = call_21626092.validator(path, query, header, formData, body, _)
  let scheme = call_21626092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626092.makeUrl(scheme.get, call_21626092.host, call_21626092.base,
                               call_21626092.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626092, uri, valid, _)

proc call*(call_21626093: Call_PutPlaybackConfiguration_21626081; body: JsonNode): Recallable =
  ## putPlaybackConfiguration
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
  ##   body: JObject (required)
  var body_21626094 = newJObject()
  if body != nil:
    body_21626094 = body
  result = call_21626093.call(nil, nil, nil, nil, body_21626094)

var putPlaybackConfiguration* = Call_PutPlaybackConfiguration_21626081(
    name: "putPlaybackConfiguration", meth: HttpMethod.HttpPut,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration",
    validator: validate_PutPlaybackConfiguration_21626082, base: "/",
    makeUrl: url_PutPlaybackConfiguration_21626083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626095 = ref object of OpenApiRestCall_21625426
proc url_UntagResource_21626097(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626096(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626098 = path.getOrDefault("ResourceArn")
  valid_21626098 = validateParameter(valid_21626098, JString, required = true,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "ResourceArn", valid_21626098
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A comma-separated list of the tag keys to remove from the playback configuration. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626099 = query.getOrDefault("tagKeys")
  valid_21626099 = validateParameter(valid_21626099, JArray, required = true,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "tagKeys", valid_21626099
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
  var valid_21626100 = header.getOrDefault("X-Amz-Date")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Date", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Security-Token", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Algorithm", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Signature")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Signature", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Credential")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Credential", valid_21626106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626107: Call_UntagResource_21626095; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags from the specified playback configuration resource. You can specify one or more tags to remove. 
  ## 
  let valid = call_21626107.validator(path, query, header, formData, body, _)
  let scheme = call_21626107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626107.makeUrl(scheme.get, call_21626107.host, call_21626107.base,
                               call_21626107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626107, uri, valid, _)

proc call*(call_21626108: Call_UntagResource_21626095; tagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes tags from the specified playback configuration resource. You can specify one or more tags to remove. 
  ##   tagKeys: JArray (required)
  ##          : A comma-separated list of the tag keys to remove from the playback configuration. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  var path_21626109 = newJObject()
  var query_21626110 = newJObject()
  if tagKeys != nil:
    query_21626110.add "tagKeys", tagKeys
  add(path_21626109, "ResourceArn", newJString(ResourceArn))
  result = call_21626108.call(path_21626109, query_21626110, nil, nil, nil)

var untagResource* = Call_UntagResource_21626095(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "api.mediatailor.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_21626096,
    base: "/", makeUrl: url_UntagResource_21626097,
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