
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600413 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600413](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600413): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_GetPlaybackConfiguration_600755 = ref object of OpenApiRestCall_600413
proc url_GetPlaybackConfiguration_600757(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Name" in path, "`Name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/playbackConfiguration/"),
               (kind: VariableSegment, value: "Name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetPlaybackConfiguration_600756(path: JsonNode; query: JsonNode;
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
  var valid_600883 = path.getOrDefault("Name")
  valid_600883 = validateParameter(valid_600883, JString, required = true,
                                 default = nil)
  if valid_600883 != nil:
    section.add "Name", valid_600883
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
  var valid_600884 = header.getOrDefault("X-Amz-Date")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Date", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Security-Token")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Security-Token", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Content-Sha256", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Algorithm")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Algorithm", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Signature")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Signature", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-SignedHeaders", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Credential")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Credential", valid_600890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_GetPlaybackConfiguration_600755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the playback configuration for the specified name. 
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"))
  result = hook(call_600913, url, valid)

proc call*(call_600984: Call_GetPlaybackConfiguration_600755; Name: string): Recallable =
  ## getPlaybackConfiguration
  ## Returns the playback configuration for the specified name. 
  ##   Name: string (required)
  ##       : The identifier for the playback configuration.
  var path_600985 = newJObject()
  add(path_600985, "Name", newJString(Name))
  result = call_600984.call(path_600985, nil, nil, nil, nil)

var getPlaybackConfiguration* = Call_GetPlaybackConfiguration_600755(
    name: "getPlaybackConfiguration", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration/{Name}",
    validator: validate_GetPlaybackConfiguration_600756, base: "/",
    url: url_GetPlaybackConfiguration_600757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePlaybackConfiguration_601025 = ref object of OpenApiRestCall_600413
proc url_DeletePlaybackConfiguration_601027(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Name" in path, "`Name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/playbackConfiguration/"),
               (kind: VariableSegment, value: "Name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeletePlaybackConfiguration_601026(path: JsonNode; query: JsonNode;
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
  var valid_601028 = path.getOrDefault("Name")
  valid_601028 = validateParameter(valid_601028, JString, required = true,
                                 default = nil)
  if valid_601028 != nil:
    section.add "Name", valid_601028
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
  var valid_601029 = header.getOrDefault("X-Amz-Date")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Date", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Security-Token")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Security-Token", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Content-Sha256", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Algorithm")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Algorithm", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Signature")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Signature", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-SignedHeaders", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-Credential")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Credential", valid_601035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601036: Call_DeletePlaybackConfiguration_601025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the playback configuration for the specified name. 
  ## 
  let valid = call_601036.validator(path, query, header, formData, body)
  let scheme = call_601036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601036.url(scheme.get, call_601036.host, call_601036.base,
                         call_601036.route, valid.getOrDefault("path"))
  result = hook(call_601036, url, valid)

proc call*(call_601037: Call_DeletePlaybackConfiguration_601025; Name: string): Recallable =
  ## deletePlaybackConfiguration
  ## Deletes the playback configuration for the specified name. 
  ##   Name: string (required)
  ##       : The identifier for the playback configuration.
  var path_601038 = newJObject()
  add(path_601038, "Name", newJString(Name))
  result = call_601037.call(path_601038, nil, nil, nil, nil)

var deletePlaybackConfiguration* = Call_DeletePlaybackConfiguration_601025(
    name: "deletePlaybackConfiguration", meth: HttpMethod.HttpDelete,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration/{Name}",
    validator: validate_DeletePlaybackConfiguration_601026, base: "/",
    url: url_DeletePlaybackConfiguration_601027,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPlaybackConfigurations_601039 = ref object of OpenApiRestCall_600413
proc url_ListPlaybackConfigurations_601041(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPlaybackConfigurations_601040(path: JsonNode; query: JsonNode;
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
  var valid_601042 = query.getOrDefault("NextToken")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "NextToken", valid_601042
  var valid_601043 = query.getOrDefault("MaxResults")
  valid_601043 = validateParameter(valid_601043, JInt, required = false, default = nil)
  if valid_601043 != nil:
    section.add "MaxResults", valid_601043
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
  var valid_601044 = header.getOrDefault("X-Amz-Date")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Date", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Security-Token")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Security-Token", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Content-Sha256", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Algorithm")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Algorithm", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Signature")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Signature", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-SignedHeaders", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Credential")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Credential", valid_601050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601051: Call_ListPlaybackConfigurations_601039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
  ## 
  let valid = call_601051.validator(path, query, header, formData, body)
  let scheme = call_601051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601051.url(scheme.get, call_601051.host, call_601051.base,
                         call_601051.route, valid.getOrDefault("path"))
  result = hook(call_601051, url, valid)

proc call*(call_601052: Call_ListPlaybackConfigurations_601039;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listPlaybackConfigurations
  ## Returns a list of the playback configurations defined in AWS Elemental MediaTailor. You can specify a maximum number of configurations to return at a time. The default maximum is 50. Results are returned in pagefuls. If MediaTailor has more configurations than the specified maximum, it provides parameters in the response that you can use to retrieve the next pageful. 
  ##   NextToken: string
  ##            : Pagination token returned by the GET list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
  ##   MaxResults: int
  ##             : Maximum number of records to return. 
  var query_601053 = newJObject()
  add(query_601053, "NextToken", newJString(NextToken))
  add(query_601053, "MaxResults", newJInt(MaxResults))
  result = call_601052.call(nil, query_601053, nil, nil, nil)

var listPlaybackConfigurations* = Call_ListPlaybackConfigurations_601039(
    name: "listPlaybackConfigurations", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfigurations",
    validator: validate_ListPlaybackConfigurations_601040, base: "/",
    url: url_ListPlaybackConfigurations_601041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601068 = ref object of OpenApiRestCall_600413
proc url_TagResource_601070(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_601069(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601071 = path.getOrDefault("ResourceArn")
  valid_601071 = validateParameter(valid_601071, JString, required = true,
                                 default = nil)
  if valid_601071 != nil:
    section.add "ResourceArn", valid_601071
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
  var valid_601072 = header.getOrDefault("X-Amz-Date")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Date", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Security-Token")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Security-Token", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Content-Sha256", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Algorithm")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Algorithm", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Signature")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Signature", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-SignedHeaders", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Credential")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Credential", valid_601078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601080: Call_TagResource_601068; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to the specified playback configuration resource. You can specify one or more tags to add. 
  ## 
  let valid = call_601080.validator(path, query, header, formData, body)
  let scheme = call_601080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601080.url(scheme.get, call_601080.host, call_601080.base,
                         call_601080.route, valid.getOrDefault("path"))
  result = hook(call_601080, url, valid)

proc call*(call_601081: Call_TagResource_601068; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to the specified playback configuration resource. You can specify one or more tags to add. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  ##   body: JObject (required)
  var path_601082 = newJObject()
  var body_601083 = newJObject()
  add(path_601082, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_601083 = body
  result = call_601081.call(path_601082, nil, nil, nil, body_601083)

var tagResource* = Call_TagResource_601068(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.mediatailor.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_601069,
                                        base: "/", url: url_TagResource_601070,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601054 = ref object of OpenApiRestCall_600413
proc url_ListTagsForResource_601056(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_601055(path: JsonNode; query: JsonNode;
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
  var valid_601057 = path.getOrDefault("ResourceArn")
  valid_601057 = validateParameter(valid_601057, JString, required = true,
                                 default = nil)
  if valid_601057 != nil:
    section.add "ResourceArn", valid_601057
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
  var valid_601058 = header.getOrDefault("X-Amz-Date")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Date", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Security-Token")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Security-Token", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Content-Sha256", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Algorithm")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Algorithm", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Signature")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Signature", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-SignedHeaders", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Credential")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Credential", valid_601064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601065: Call_ListTagsForResource_601054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags assigned to the specified playback configuration resource. 
  ## 
  let valid = call_601065.validator(path, query, header, formData, body)
  let scheme = call_601065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601065.url(scheme.get, call_601065.host, call_601065.base,
                         call_601065.route, valid.getOrDefault("path"))
  result = hook(call_601065, url, valid)

proc call*(call_601066: Call_ListTagsForResource_601054; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified playback configuration resource. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  var path_601067 = newJObject()
  add(path_601067, "ResourceArn", newJString(ResourceArn))
  result = call_601066.call(path_601067, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_601054(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "api.mediatailor.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_601055, base: "/",
    url: url_ListTagsForResource_601056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPlaybackConfiguration_601084 = ref object of OpenApiRestCall_600413
proc url_PutPlaybackConfiguration_601086(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutPlaybackConfiguration_601085(path: JsonNode; query: JsonNode;
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
  var valid_601087 = header.getOrDefault("X-Amz-Date")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Date", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Security-Token")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Security-Token", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Content-Sha256", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Algorithm")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Algorithm", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Signature")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Signature", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-SignedHeaders", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Credential")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Credential", valid_601093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601095: Call_PutPlaybackConfiguration_601084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
  ## 
  let valid = call_601095.validator(path, query, header, formData, body)
  let scheme = call_601095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601095.url(scheme.get, call_601095.host, call_601095.base,
                         call_601095.route, valid.getOrDefault("path"))
  result = hook(call_601095, url, valid)

proc call*(call_601096: Call_PutPlaybackConfiguration_601084; body: JsonNode): Recallable =
  ## putPlaybackConfiguration
  ## Adds a new playback configuration to AWS Elemental MediaTailor. 
  ##   body: JObject (required)
  var body_601097 = newJObject()
  if body != nil:
    body_601097 = body
  result = call_601096.call(nil, nil, nil, nil, body_601097)

var putPlaybackConfiguration* = Call_PutPlaybackConfiguration_601084(
    name: "putPlaybackConfiguration", meth: HttpMethod.HttpPut,
    host: "api.mediatailor.amazonaws.com", route: "/playbackConfiguration",
    validator: validate_PutPlaybackConfiguration_601085, base: "/",
    url: url_PutPlaybackConfiguration_601086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601098 = ref object of OpenApiRestCall_600413
proc url_UntagResource_601100(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "ResourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_601099(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601101 = path.getOrDefault("ResourceArn")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = nil)
  if valid_601101 != nil:
    section.add "ResourceArn", valid_601101
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A comma-separated list of the tag keys to remove from the playback configuration. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_601102 = query.getOrDefault("tagKeys")
  valid_601102 = validateParameter(valid_601102, JArray, required = true, default = nil)
  if valid_601102 != nil:
    section.add "tagKeys", valid_601102
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
  var valid_601103 = header.getOrDefault("X-Amz-Date")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Date", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Security-Token")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Security-Token", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Content-Sha256", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Algorithm")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Algorithm", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Signature")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Signature", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-SignedHeaders", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Credential")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Credential", valid_601109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601110: Call_UntagResource_601098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from the specified playback configuration resource. You can specify one or more tags to remove. 
  ## 
  let valid = call_601110.validator(path, query, header, formData, body)
  let scheme = call_601110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601110.url(scheme.get, call_601110.host, call_601110.base,
                         call_601110.route, valid.getOrDefault("path"))
  result = hook(call_601110, url, valid)

proc call*(call_601111: Call_UntagResource_601098; tagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes tags from the specified playback configuration resource. You can specify one or more tags to remove. 
  ##   tagKeys: JArray (required)
  ##          : A comma-separated list of the tag keys to remove from the playback configuration. 
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the playback configuration. You can get this from the response to any playback configuration request. 
  var path_601112 = newJObject()
  var query_601113 = newJObject()
  if tagKeys != nil:
    query_601113.add "tagKeys", tagKeys
  add(path_601112, "ResourceArn", newJString(ResourceArn))
  result = call_601111.call(path_601112, query_601113, nil, nil, nil)

var untagResource* = Call_UntagResource_601098(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "api.mediatailor.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_601099,
    base: "/", url: url_UntagResource_601100, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
