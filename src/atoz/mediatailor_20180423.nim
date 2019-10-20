
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592355 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592355](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592355): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetPlaybackConfiguration_592694 = ref object of OpenApiRestCall_592355
proc url_GetPlaybackConfiguration_592696(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_GetPlaybackConfiguration_592695(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the playback configuration for the specified name. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Name: JString (required)
  ##       : The identifier for the playback configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Name` field"
  var valid_592822 = path.getOrDefault("Name")
  valid_592822 = validateParameter(valid_592822, JString, required = true,
                                 default = nil)
  if valid_592822 != nil:
    section.add "Name", valid_592822
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
  var valid_592823 = header.getOrDefault("X-Amz-Signature")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Signature", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Content-Sha256", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-Date")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-Date", valid_592825
  var valid_592826 = header.getOrDefault("X-Amz-Credential")
  valid_592826 = validateParameter(valid_592826, JString, required = false,
                                 default = nil)
  if valid_592826 != nil:
    section.add "X-Amz-Credential", valid_592826
  var valid_592827 = header.getOrDefault("X-Amz-Security-Token")
  valid_592827 = validateParameter(valid_592827, JString, required = false,
                                 default = nil)
  if valid_592827 != nil:
    section.add "X-Amz-Security-Token", valid_592827
  var valid_592828 = header.getOrDefault("X-Amz-Algorithm")
  valid_592828 = validateParameter(valid_592828, JString, required = false,
                                 default = nil)
  if valid_592828 != nil:
    section.add "X-Amz-Algorithm", valid_592828
  var valid_592829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592829 = validateParameter(valid_592829, JString, required = false,
                                 default = nil)
  if valid_592829 != nil:
    section.add "X-Amz-SignedHeaders", valid_592829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592852: Call_GetPlaybackConfiguration_592694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the playback configuration for the specified name. 
  ## 
  let valid = call_592852.validator(path, query, header, formData, body)
  let scheme = call_592852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592852.url(scheme.get, call_592852.host, call_592852.base,
                         call_592852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592852, url, valid)

proc call*(call_592923: Call_GetPlaybackConfiguration_592694; Name: string): Recallable =
  ## getPlaybackConfiguration
  ## Returns the playback configuration for the specified name. 
  ##   Name: string (required)
  ##       : The identifier for the playback configuration.
  var path_592924 = newJObject()
  add(path_592924, "Name", newJString(Name))
  result = call_592923.call(path_592924, nil, nil, nil, nil)

var getPlaybackConfiguration* = Call_GetPlaybackConfiguration_592694(
    name: "getPlaybackConfiguration", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration/{Name}",
    validator: validate_GetPlaybackConfiguration_592695, base: "/",
    url: url_GetPlaybackConfiguration_592696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePlaybackConfiguration_592964 = ref object of OpenApiRestCall_592355
proc url_DeletePlaybackConfiguration_592966(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeletePlaybackConfiguration_592965(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the playback configuration for the specified name. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Name: JString (required)
  ##       : The identifier for the playback configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Name` field"
  var valid_592967 = path.getOrDefault("Name")
  valid_592967 = validateParameter(valid_592967, JString, required = true,
                                 default = nil)
  if valid_592967 != nil:
    section.add "Name", valid_592967
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
  var valid_592968 = header.getOrDefault("X-Amz-Signature")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Signature", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-Content-Sha256", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-Date")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-Date", valid_592970
  var valid_592971 = header.getOrDefault("X-Amz-Credential")
  valid_592971 = validateParameter(valid_592971, JString, required = false,
                                 default = nil)
  if valid_592971 != nil:
    section.add "X-Amz-Credential", valid_592971
  var valid_592972 = header.getOrDefault("X-Amz-Security-Token")
  valid_592972 = validateParameter(valid_592972, JString, required = false,
                                 default = nil)
  if valid_592972 != nil:
    section.add "X-Amz-Security-Token", valid_592972
  var valid_592973 = header.getOrDefault("X-Amz-Algorithm")
  valid_592973 = validateParameter(valid_592973, JString, required = false,
                                 default = nil)
  if valid_592973 != nil:
    section.add "X-Amz-Algorithm", valid_592973
  var valid_592974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592974 = validateParameter(valid_592974, JString, required = false,
                                 default = nil)
  if valid_592974 != nil:
    section.add "X-Amz-SignedHeaders", valid_592974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592975: Call_DeletePlaybackConfiguration_592964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the playback configuration for the specified name. 
  ## 
  let valid = call_592975.validator(path, query, header, formData, body)
  let scheme = call_592975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592975.url(scheme.get, call_592975.host, call_592975.base,
                         call_592975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592975, url, valid)

proc call*(call_592976: Call_DeletePlaybackConfiguration_592964; Name: string): Recallable =
  ## deletePlaybackConfiguration
  ## Deletes the playback configuration for the specified name. 
  ##   Name: string (required)
  ##       : The identifier for the playback configuration.
  var path_592977 = newJObject()
  add(path_592977, "Name", newJString(Name))
  result = call_592976.call(path_592977, nil, nil, nil, nil)

var deletePlaybackConfiguration* = Call_DeletePlaybackConfiguration_592964(
    name: "deletePlaybackConfiguration", meth: HttpMethod.HttpDelete,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration/{Name}",
    validator: validate_DeletePlaybackConfiguration_592965, base: "/",
    url: url_DeletePlaybackConfiguration_592966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPlaybackConfigurations_592978 = ref object of OpenApiRestCall_592355
proc url_ListPlaybackConfigurations_592980(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPlaybackConfigurations_592979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : Maximum number of records to return. 
  ##   NextToken: JString
  ##            : Pagination token returned by the GET list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
  section = newJObject()
  var valid_592981 = query.getOrDefault("MaxResults")
  valid_592981 = validateParameter(valid_592981, JInt, required = false, default = nil)
  if valid_592981 != nil:
    section.add "MaxResults", valid_592981
  var valid_592982 = query.getOrDefault("NextToken")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "NextToken", valid_592982
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
  var valid_592983 = header.getOrDefault("X-Amz-Signature")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Signature", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Content-Sha256", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Date")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Date", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Credential")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Credential", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Security-Token")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Security-Token", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Algorithm")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Algorithm", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-SignedHeaders", valid_592989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592990: Call_ListPlaybackConfigurations_592978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
  ## 
  let valid = call_592990.validator(path, query, header, formData, body)
  let scheme = call_592990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592990.url(scheme.get, call_592990.host, call_592990.base,
                         call_592990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592990, url, valid)

proc call*(call_592991: Call_ListPlaybackConfigurations_592978;
          MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## listPlaybackConfigurations
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
  ##   MaxResults: int
  ##             : Maximum number of records to return. 
  ##   NextToken: string
  ##            : Pagination token returned by the GET list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
  var query_592992 = newJObject()
  add(query_592992, "MaxResults", newJInt(MaxResults))
  add(query_592992, "NextToken", newJString(NextToken))
  result = call_592991.call(nil, query_592992, nil, nil, nil)

var listPlaybackConfigurations* = Call_ListPlaybackConfigurations_592978(
    name: "listPlaybackConfigurations", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfigurations",
    validator: validate_ListPlaybackConfigurations_592979, base: "/",
    url: url_ListPlaybackConfigurations_592980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593007 = ref object of OpenApiRestCall_592355
proc url_TagResource_593009(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_593008(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593010 = path.getOrDefault("ResourceArn")
  valid_593010 = validateParameter(valid_593010, JString, required = true,
                                 default = nil)
  if valid_593010 != nil:
    section.add "ResourceArn", valid_593010
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
  var valid_593011 = header.getOrDefault("X-Amz-Signature")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Signature", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Content-Sha256", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Date")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Date", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Credential")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Credential", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Security-Token")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Security-Token", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Algorithm")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Algorithm", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-SignedHeaders", valid_593017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593019: Call_TagResource_593007; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to the specified playback configuration resource. You can specify one or more tags to add. 
  ## 
  let valid = call_593019.validator(path, query, header, formData, body)
  let scheme = call_593019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593019.url(scheme.get, call_593019.host, call_593019.base,
                         call_593019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593019, url, valid)

proc call*(call_593020: Call_TagResource_593007; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to the specified playback configuration resource. You can specify one or more tags to add. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  ##   body: JObject (required)
  var path_593021 = newJObject()
  var body_593022 = newJObject()
  add(path_593021, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_593022 = body
  result = call_593020.call(path_593021, nil, nil, nil, body_593022)

var tagResource* = Call_TagResource_593007(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.mediatailor.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_593008,
                                        base: "/", url: url_TagResource_593009,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_592993 = ref object of OpenApiRestCall_592355
proc url_ListTagsForResource_592995(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_592994(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_592996 = path.getOrDefault("ResourceArn")
  valid_592996 = validateParameter(valid_592996, JString, required = true,
                                 default = nil)
  if valid_592996 != nil:
    section.add "ResourceArn", valid_592996
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
  var valid_592997 = header.getOrDefault("X-Amz-Signature")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Signature", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Content-Sha256", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Date")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Date", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Credential")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Credential", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Security-Token")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Security-Token", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Algorithm")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Algorithm", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-SignedHeaders", valid_593003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593004: Call_ListTagsForResource_592993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags assigned to the specified playback configuration resource. 
  ## 
  let valid = call_593004.validator(path, query, header, formData, body)
  let scheme = call_593004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593004.url(scheme.get, call_593004.host, call_593004.base,
                         call_593004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593004, url, valid)

proc call*(call_593005: Call_ListTagsForResource_592993; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified playback configuration resource. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  var path_593006 = newJObject()
  add(path_593006, "ResourceArn", newJString(ResourceArn))
  result = call_593005.call(path_593006, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_592993(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_592994, base: "/",
    url: url_ListTagsForResource_592995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPlaybackConfiguration_593023 = ref object of OpenApiRestCall_592355
proc url_PutPlaybackConfiguration_593025(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutPlaybackConfiguration_593024(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
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
  var valid_593026 = header.getOrDefault("X-Amz-Signature")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Signature", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Content-Sha256", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Date")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Date", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Credential")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Credential", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Security-Token")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Security-Token", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Algorithm")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Algorithm", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-SignedHeaders", valid_593032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593034: Call_PutPlaybackConfiguration_593023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
  ## 
  let valid = call_593034.validator(path, query, header, formData, body)
  let scheme = call_593034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593034.url(scheme.get, call_593034.host, call_593034.base,
                         call_593034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593034, url, valid)

proc call*(call_593035: Call_PutPlaybackConfiguration_593023; body: JsonNode): Recallable =
  ## putPlaybackConfiguration
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
  ##   body: JObject (required)
  var body_593036 = newJObject()
  if body != nil:
    body_593036 = body
  result = call_593035.call(nil, nil, nil, nil, body_593036)

var putPlaybackConfiguration* = Call_PutPlaybackConfiguration_593023(
    name: "putPlaybackConfiguration", meth: HttpMethod.HttpPut,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration",
    validator: validate_PutPlaybackConfiguration_593024, base: "/",
    url: url_PutPlaybackConfiguration_593025, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593037 = ref object of OpenApiRestCall_592355
proc url_UntagResource_593039(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_593038(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_593040 = path.getOrDefault("ResourceArn")
  valid_593040 = validateParameter(valid_593040, JString, required = true,
                                 default = nil)
  if valid_593040 != nil:
    section.add "ResourceArn", valid_593040
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A comma-separated list of the tag keys to remove from the playback configuration. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_593041 = query.getOrDefault("tagKeys")
  valid_593041 = validateParameter(valid_593041, JArray, required = true, default = nil)
  if valid_593041 != nil:
    section.add "tagKeys", valid_593041
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
  var valid_593042 = header.getOrDefault("X-Amz-Signature")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Signature", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Content-Sha256", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-Date")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Date", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-Credential")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Credential", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Security-Token")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Security-Token", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Algorithm")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Algorithm", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-SignedHeaders", valid_593048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593049: Call_UntagResource_593037; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from the specified playback configuration resource. You can specify one or more tags to remove. 
  ## 
  let valid = call_593049.validator(path, query, header, formData, body)
  let scheme = call_593049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593049.url(scheme.get, call_593049.host, call_593049.base,
                         call_593049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593049, url, valid)

proc call*(call_593050: Call_UntagResource_593037; ResourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from the specified playback configuration resource. You can specify one or more tags to remove. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  ##   tagKeys: JArray (required)
  ##          : A comma-separated list of the tag keys to remove from the playback configuration. 
  var path_593051 = newJObject()
  var query_593052 = newJObject()
  add(path_593051, "ResourceArn", newJString(ResourceArn))
  if tagKeys != nil:
    query_593052.add "tagKeys", tagKeys
  result = call_593050.call(path_593051, query_593052, nil, nil, nil)

var untagResource* = Call_UntagResource_593037(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "api.mediatailor.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_593038,
    base: "/", url: url_UntagResource_593039, schemes: {Scheme.Https, Scheme.Http})
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
