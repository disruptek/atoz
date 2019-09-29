
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
  Call_GetPlaybackConfiguration_593761 = ref object of OpenApiRestCall_593424
proc url_GetPlaybackConfiguration_593763(protocol: Scheme; host: string;
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

proc validate_GetPlaybackConfiguration_593762(path: JsonNode; query: JsonNode;
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
  var valid_593889 = path.getOrDefault("Name")
  valid_593889 = validateParameter(valid_593889, JString, required = true,
                                 default = nil)
  if valid_593889 != nil:
    section.add "Name", valid_593889
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
  var valid_593890 = header.getOrDefault("X-Amz-Date")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Date", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Security-Token")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Security-Token", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Content-Sha256", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Algorithm")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Algorithm", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Signature")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Signature", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-SignedHeaders", valid_593895
  var valid_593896 = header.getOrDefault("X-Amz-Credential")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-Credential", valid_593896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593919: Call_GetPlaybackConfiguration_593761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the playback configuration for the specified name. 
  ## 
  let valid = call_593919.validator(path, query, header, formData, body)
  let scheme = call_593919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593919.url(scheme.get, call_593919.host, call_593919.base,
                         call_593919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593919, url, valid)

proc call*(call_593990: Call_GetPlaybackConfiguration_593761; Name: string): Recallable =
  ## getPlaybackConfiguration
  ## Returns the playback configuration for the specified name. 
  ##   Name: string (required)
  ##       : The identifier for the playback configuration.
  var path_593991 = newJObject()
  add(path_593991, "Name", newJString(Name))
  result = call_593990.call(path_593991, nil, nil, nil, nil)

var getPlaybackConfiguration* = Call_GetPlaybackConfiguration_593761(
    name: "getPlaybackConfiguration", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration/{Name}",
    validator: validate_GetPlaybackConfiguration_593762, base: "/",
    url: url_GetPlaybackConfiguration_593763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePlaybackConfiguration_594031 = ref object of OpenApiRestCall_593424
proc url_DeletePlaybackConfiguration_594033(protocol: Scheme; host: string;
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

proc validate_DeletePlaybackConfiguration_594032(path: JsonNode; query: JsonNode;
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
  var valid_594034 = path.getOrDefault("Name")
  valid_594034 = validateParameter(valid_594034, JString, required = true,
                                 default = nil)
  if valid_594034 != nil:
    section.add "Name", valid_594034
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
  var valid_594035 = header.getOrDefault("X-Amz-Date")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Date", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Security-Token")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Security-Token", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Content-Sha256", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Algorithm")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Algorithm", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Signature")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Signature", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-SignedHeaders", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Credential")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Credential", valid_594041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594042: Call_DeletePlaybackConfiguration_594031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the playback configuration for the specified name. 
  ## 
  let valid = call_594042.validator(path, query, header, formData, body)
  let scheme = call_594042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594042.url(scheme.get, call_594042.host, call_594042.base,
                         call_594042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594042, url, valid)

proc call*(call_594043: Call_DeletePlaybackConfiguration_594031; Name: string): Recallable =
  ## deletePlaybackConfiguration
  ## Deletes the playback configuration for the specified name. 
  ##   Name: string (required)
  ##       : The identifier for the playback configuration.
  var path_594044 = newJObject()
  add(path_594044, "Name", newJString(Name))
  result = call_594043.call(path_594044, nil, nil, nil, nil)

var deletePlaybackConfiguration* = Call_DeletePlaybackConfiguration_594031(
    name: "deletePlaybackConfiguration", meth: HttpMethod.HttpDelete,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration/{Name}",
    validator: validate_DeletePlaybackConfiguration_594032, base: "/",
    url: url_DeletePlaybackConfiguration_594033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPlaybackConfigurations_594045 = ref object of OpenApiRestCall_593424
proc url_ListPlaybackConfigurations_594047(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPlaybackConfigurations_594046(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594048 = query.getOrDefault("NextToken")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "NextToken", valid_594048
  var valid_594049 = query.getOrDefault("MaxResults")
  valid_594049 = validateParameter(valid_594049, JInt, required = false, default = nil)
  if valid_594049 != nil:
    section.add "MaxResults", valid_594049
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
  var valid_594050 = header.getOrDefault("X-Amz-Date")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Date", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Security-Token")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Security-Token", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Content-Sha256", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Algorithm")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Algorithm", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Signature")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Signature", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-SignedHeaders", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Credential")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Credential", valid_594056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594057: Call_ListPlaybackConfigurations_594045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
  ## 
  let valid = call_594057.validator(path, query, header, formData, body)
  let scheme = call_594057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594057.url(scheme.get, call_594057.host, call_594057.base,
                         call_594057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594057, url, valid)

proc call*(call_594058: Call_ListPlaybackConfigurations_594045;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listPlaybackConfigurations
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
  ##   NextToken: string
  ##            : Pagination token returned by the GET list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
  ##   MaxResults: int
  ##             : Maximum number of records to return. 
  var query_594059 = newJObject()
  add(query_594059, "NextToken", newJString(NextToken))
  add(query_594059, "MaxResults", newJInt(MaxResults))
  result = call_594058.call(nil, query_594059, nil, nil, nil)

var listPlaybackConfigurations* = Call_ListPlaybackConfigurations_594045(
    name: "listPlaybackConfigurations", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfigurations",
    validator: validate_ListPlaybackConfigurations_594046, base: "/",
    url: url_ListPlaybackConfigurations_594047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594074 = ref object of OpenApiRestCall_593424
proc url_TagResource_594076(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_594075(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594077 = path.getOrDefault("ResourceArn")
  valid_594077 = validateParameter(valid_594077, JString, required = true,
                                 default = nil)
  if valid_594077 != nil:
    section.add "ResourceArn", valid_594077
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
  var valid_594078 = header.getOrDefault("X-Amz-Date")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Date", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Security-Token")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Security-Token", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Content-Sha256", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Algorithm")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Algorithm", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Signature")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Signature", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-SignedHeaders", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Credential")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Credential", valid_594084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594086: Call_TagResource_594074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to the specified playback configuration resource. You can specify one or more tags to add. 
  ## 
  let valid = call_594086.validator(path, query, header, formData, body)
  let scheme = call_594086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594086.url(scheme.get, call_594086.host, call_594086.base,
                         call_594086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594086, url, valid)

proc call*(call_594087: Call_TagResource_594074; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to the specified playback configuration resource. You can specify one or more tags to add. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  ##   body: JObject (required)
  var path_594088 = newJObject()
  var body_594089 = newJObject()
  add(path_594088, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_594089 = body
  result = call_594087.call(path_594088, nil, nil, nil, body_594089)

var tagResource* = Call_TagResource_594074(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.mediatailor.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_594075,
                                        base: "/", url: url_TagResource_594076,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594060 = ref object of OpenApiRestCall_593424
proc url_ListTagsForResource_594062(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_594061(path: JsonNode; query: JsonNode;
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
  var valid_594063 = path.getOrDefault("ResourceArn")
  valid_594063 = validateParameter(valid_594063, JString, required = true,
                                 default = nil)
  if valid_594063 != nil:
    section.add "ResourceArn", valid_594063
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
  var valid_594064 = header.getOrDefault("X-Amz-Date")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Date", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Security-Token")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Security-Token", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Content-Sha256", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Algorithm")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Algorithm", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Signature")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Signature", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-SignedHeaders", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Credential")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Credential", valid_594070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594071: Call_ListTagsForResource_594060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags assigned to the specified playback configuration resource. 
  ## 
  let valid = call_594071.validator(path, query, header, formData, body)
  let scheme = call_594071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594071.url(scheme.get, call_594071.host, call_594071.base,
                         call_594071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594071, url, valid)

proc call*(call_594072: Call_ListTagsForResource_594060; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified playback configuration resource. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  var path_594073 = newJObject()
  add(path_594073, "ResourceArn", newJString(ResourceArn))
  result = call_594072.call(path_594073, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594060(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_594061, base: "/",
    url: url_ListTagsForResource_594062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPlaybackConfiguration_594090 = ref object of OpenApiRestCall_593424
proc url_PutPlaybackConfiguration_594092(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutPlaybackConfiguration_594091(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594093 = header.getOrDefault("X-Amz-Date")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Date", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Security-Token")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Security-Token", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Content-Sha256", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Algorithm")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Algorithm", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Signature")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Signature", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-SignedHeaders", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Credential")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Credential", valid_594099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594101: Call_PutPlaybackConfiguration_594090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
  ## 
  let valid = call_594101.validator(path, query, header, formData, body)
  let scheme = call_594101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594101.url(scheme.get, call_594101.host, call_594101.base,
                         call_594101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594101, url, valid)

proc call*(call_594102: Call_PutPlaybackConfiguration_594090; body: JsonNode): Recallable =
  ## putPlaybackConfiguration
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
  ##   body: JObject (required)
  var body_594103 = newJObject()
  if body != nil:
    body_594103 = body
  result = call_594102.call(nil, nil, nil, nil, body_594103)

var putPlaybackConfiguration* = Call_PutPlaybackConfiguration_594090(
    name: "putPlaybackConfiguration", meth: HttpMethod.HttpPut,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration",
    validator: validate_PutPlaybackConfiguration_594091, base: "/",
    url: url_PutPlaybackConfiguration_594092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594104 = ref object of OpenApiRestCall_593424
proc url_UntagResource_594106(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_594105(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594107 = path.getOrDefault("ResourceArn")
  valid_594107 = validateParameter(valid_594107, JString, required = true,
                                 default = nil)
  if valid_594107 != nil:
    section.add "ResourceArn", valid_594107
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A comma-separated list of the tag keys to remove from the playback configuration. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594108 = query.getOrDefault("tagKeys")
  valid_594108 = validateParameter(valid_594108, JArray, required = true, default = nil)
  if valid_594108 != nil:
    section.add "tagKeys", valid_594108
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
  var valid_594109 = header.getOrDefault("X-Amz-Date")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Date", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Security-Token")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Security-Token", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Content-Sha256", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Algorithm")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Algorithm", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Signature")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Signature", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-SignedHeaders", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Credential")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Credential", valid_594115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594116: Call_UntagResource_594104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from the specified playback configuration resource. You can specify one or more tags to remove. 
  ## 
  let valid = call_594116.validator(path, query, header, formData, body)
  let scheme = call_594116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594116.url(scheme.get, call_594116.host, call_594116.base,
                         call_594116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594116, url, valid)

proc call*(call_594117: Call_UntagResource_594104; tagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes tags from the specified playback configuration resource. You can specify one or more tags to remove. 
  ##   tagKeys: JArray (required)
  ##          : A comma-separated list of the tag keys to remove from the playback configuration. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  var path_594118 = newJObject()
  var query_594119 = newJObject()
  if tagKeys != nil:
    query_594119.add "tagKeys", tagKeys
  add(path_594118, "ResourceArn", newJString(ResourceArn))
  result = call_594117.call(path_594118, query_594119, nil, nil, nil)

var untagResource* = Call_UntagResource_594104(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "api.mediatailor.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_594105,
    base: "/", url: url_UntagResource_594106, schemes: {Scheme.Https, Scheme.Http})
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
