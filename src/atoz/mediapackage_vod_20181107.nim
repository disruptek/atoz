
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "mediapackage-vod.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mediapackage-vod.ap-southeast-1.amazonaws.com", "us-west-2": "mediapackage-vod.us-west-2.amazonaws.com", "eu-west-2": "mediapackage-vod.eu-west-2.amazonaws.com", "ap-northeast-3": "mediapackage-vod.ap-northeast-3.amazonaws.com", "eu-central-1": "mediapackage-vod.eu-central-1.amazonaws.com", "us-east-2": "mediapackage-vod.us-east-2.amazonaws.com", "us-east-1": "mediapackage-vod.us-east-1.amazonaws.com", "cn-northwest-1": "mediapackage-vod.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "mediapackage-vod.ap-south-1.amazonaws.com", "eu-north-1": "mediapackage-vod.eu-north-1.amazonaws.com", "ap-northeast-2": "mediapackage-vod.ap-northeast-2.amazonaws.com", "us-west-1": "mediapackage-vod.us-west-1.amazonaws.com", "us-gov-east-1": "mediapackage-vod.us-gov-east-1.amazonaws.com", "eu-west-3": "mediapackage-vod.eu-west-3.amazonaws.com", "cn-north-1": "mediapackage-vod.cn-north-1.amazonaws.com.cn", "sa-east-1": "mediapackage-vod.sa-east-1.amazonaws.com", "eu-west-1": "mediapackage-vod.eu-west-1.amazonaws.com", "us-gov-west-1": "mediapackage-vod.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mediapackage-vod.ap-southeast-2.amazonaws.com", "ca-central-1": "mediapackage-vod.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateAsset_601028 = ref object of OpenApiRestCall_600426
proc url_CreateAsset_601030(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAsset_601029(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new MediaPackage VOD Asset resource.
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
  var valid_601031 = header.getOrDefault("X-Amz-Date")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Date", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Security-Token")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Security-Token", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Content-Sha256", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Algorithm")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Algorithm", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-Signature")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Signature", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-SignedHeaders", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-Credential")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-Credential", valid_601037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601039: Call_CreateAsset_601028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD Asset resource.
  ## 
  let valid = call_601039.validator(path, query, header, formData, body)
  let scheme = call_601039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601039.url(scheme.get, call_601039.host, call_601039.base,
                         call_601039.route, valid.getOrDefault("path"))
  result = hook(call_601039, url, valid)

proc call*(call_601040: Call_CreateAsset_601028; body: JsonNode): Recallable =
  ## createAsset
  ## Creates a new MediaPackage VOD Asset resource.
  ##   body: JObject (required)
  var body_601041 = newJObject()
  if body != nil:
    body_601041 = body
  result = call_601040.call(nil, nil, nil, nil, body_601041)

var createAsset* = Call_CreateAsset_601028(name: "createAsset",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediapackage-vod.amazonaws.com",
                                        route: "/assets",
                                        validator: validate_CreateAsset_601029,
                                        base: "/", url: url_CreateAsset_601030,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssets_600768 = ref object of OpenApiRestCall_600426
proc url_ListAssets_600770(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssets_600769(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a collection of MediaPackage VOD Asset resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   packagingGroupId: JString
  ##                   : Returns Assets associated with the specified PackagingGroup.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Upper bound on number of records to return.
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600882 = query.getOrDefault("packagingGroupId")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "packagingGroupId", valid_600882
  var valid_600883 = query.getOrDefault("NextToken")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "NextToken", valid_600883
  var valid_600884 = query.getOrDefault("maxResults")
  valid_600884 = validateParameter(valid_600884, JInt, required = false, default = nil)
  if valid_600884 != nil:
    section.add "maxResults", valid_600884
  var valid_600885 = query.getOrDefault("nextToken")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "nextToken", valid_600885
  var valid_600886 = query.getOrDefault("MaxResults")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "MaxResults", valid_600886
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
  var valid_600887 = header.getOrDefault("X-Amz-Date")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Date", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Security-Token")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Security-Token", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Content-Sha256", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Algorithm")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Algorithm", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Signature")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Signature", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-SignedHeaders", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Credential")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Credential", valid_600893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600916: Call_ListAssets_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD Asset resources.
  ## 
  let valid = call_600916.validator(path, query, header, formData, body)
  let scheme = call_600916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600916.url(scheme.get, call_600916.host, call_600916.base,
                         call_600916.route, valid.getOrDefault("path"))
  result = hook(call_600916, url, valid)

proc call*(call_600987: Call_ListAssets_600768; packagingGroupId: string = "";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listAssets
  ## Returns a collection of MediaPackage VOD Asset resources.
  ##   packagingGroupId: string
  ##                   : Returns Assets associated with the specified PackagingGroup.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Upper bound on number of records to return.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600988 = newJObject()
  add(query_600988, "packagingGroupId", newJString(packagingGroupId))
  add(query_600988, "NextToken", newJString(NextToken))
  add(query_600988, "maxResults", newJInt(maxResults))
  add(query_600988, "nextToken", newJString(nextToken))
  add(query_600988, "MaxResults", newJString(MaxResults))
  result = call_600987.call(nil, query_600988, nil, nil, nil)

var listAssets* = Call_ListAssets_600768(name: "listAssets",
                                      meth: HttpMethod.HttpGet,
                                      host: "mediapackage-vod.amazonaws.com",
                                      route: "/assets",
                                      validator: validate_ListAssets_600769,
                                      base: "/", url: url_ListAssets_600770,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingConfiguration_601060 = ref object of OpenApiRestCall_600426
proc url_CreatePackagingConfiguration_601062(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePackagingConfiguration_601061(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
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
  var valid_601063 = header.getOrDefault("X-Amz-Date")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Date", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Security-Token")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Security-Token", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Content-Sha256", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Algorithm")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Algorithm", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Signature")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Signature", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-SignedHeaders", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Credential")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Credential", valid_601069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601071: Call_CreatePackagingConfiguration_601060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_601071.validator(path, query, header, formData, body)
  let scheme = call_601071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601071.url(scheme.get, call_601071.host, call_601071.base,
                         call_601071.route, valid.getOrDefault("path"))
  result = hook(call_601071, url, valid)

proc call*(call_601072: Call_CreatePackagingConfiguration_601060; body: JsonNode): Recallable =
  ## createPackagingConfiguration
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
  ##   body: JObject (required)
  var body_601073 = newJObject()
  if body != nil:
    body_601073 = body
  result = call_601072.call(nil, nil, nil, nil, body_601073)

var createPackagingConfiguration* = Call_CreatePackagingConfiguration_601060(
    name: "createPackagingConfiguration", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_CreatePackagingConfiguration_601061, base: "/",
    url: url_CreatePackagingConfiguration_601062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingConfigurations_601042 = ref object of OpenApiRestCall_600426
proc url_ListPackagingConfigurations_601044(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPackagingConfigurations_601043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   packagingGroupId: JString
  ##                   : Returns MediaPackage VOD PackagingConfigurations associated with the specified PackagingGroup.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Upper bound on number of records to return.
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601045 = query.getOrDefault("packagingGroupId")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "packagingGroupId", valid_601045
  var valid_601046 = query.getOrDefault("NextToken")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "NextToken", valid_601046
  var valid_601047 = query.getOrDefault("maxResults")
  valid_601047 = validateParameter(valid_601047, JInt, required = false, default = nil)
  if valid_601047 != nil:
    section.add "maxResults", valid_601047
  var valid_601048 = query.getOrDefault("nextToken")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "nextToken", valid_601048
  var valid_601049 = query.getOrDefault("MaxResults")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "MaxResults", valid_601049
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
  var valid_601050 = header.getOrDefault("X-Amz-Date")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Date", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Security-Token")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Security-Token", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Content-Sha256", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Algorithm")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Algorithm", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Signature")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Signature", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-SignedHeaders", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Credential")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Credential", valid_601056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601057: Call_ListPackagingConfigurations_601042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
  ## 
  let valid = call_601057.validator(path, query, header, formData, body)
  let scheme = call_601057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601057.url(scheme.get, call_601057.host, call_601057.base,
                         call_601057.route, valid.getOrDefault("path"))
  result = hook(call_601057, url, valid)

proc call*(call_601058: Call_ListPackagingConfigurations_601042;
          packagingGroupId: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPackagingConfigurations
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
  ##   packagingGroupId: string
  ##                   : Returns MediaPackage VOD PackagingConfigurations associated with the specified PackagingGroup.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Upper bound on number of records to return.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601059 = newJObject()
  add(query_601059, "packagingGroupId", newJString(packagingGroupId))
  add(query_601059, "NextToken", newJString(NextToken))
  add(query_601059, "maxResults", newJInt(maxResults))
  add(query_601059, "nextToken", newJString(nextToken))
  add(query_601059, "MaxResults", newJString(MaxResults))
  result = call_601058.call(nil, query_601059, nil, nil, nil)

var listPackagingConfigurations* = Call_ListPackagingConfigurations_601042(
    name: "listPackagingConfigurations", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_ListPackagingConfigurations_601043, base: "/",
    url: url_ListPackagingConfigurations_601044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingGroup_601091 = ref object of OpenApiRestCall_600426
proc url_CreatePackagingGroup_601093(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePackagingGroup_601092(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new MediaPackage VOD PackagingGroup resource.
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
  var valid_601094 = header.getOrDefault("X-Amz-Date")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Date", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Security-Token")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Security-Token", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Content-Sha256", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Algorithm")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Algorithm", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Signature")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Signature", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-SignedHeaders", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Credential")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Credential", valid_601100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601102: Call_CreatePackagingGroup_601091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_601102.validator(path, query, header, formData, body)
  let scheme = call_601102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601102.url(scheme.get, call_601102.host, call_601102.base,
                         call_601102.route, valid.getOrDefault("path"))
  result = hook(call_601102, url, valid)

proc call*(call_601103: Call_CreatePackagingGroup_601091; body: JsonNode): Recallable =
  ## createPackagingGroup
  ## Creates a new MediaPackage VOD PackagingGroup resource.
  ##   body: JObject (required)
  var body_601104 = newJObject()
  if body != nil:
    body_601104 = body
  result = call_601103.call(nil, nil, nil, nil, body_601104)

var createPackagingGroup* = Call_CreatePackagingGroup_601091(
    name: "createPackagingGroup", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_CreatePackagingGroup_601092, base: "/",
    url: url_CreatePackagingGroup_601093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingGroups_601074 = ref object of OpenApiRestCall_600426
proc url_ListPackagingGroups_601076(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPackagingGroups_601075(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Upper bound on number of records to return.
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601077 = query.getOrDefault("NextToken")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "NextToken", valid_601077
  var valid_601078 = query.getOrDefault("maxResults")
  valid_601078 = validateParameter(valid_601078, JInt, required = false, default = nil)
  if valid_601078 != nil:
    section.add "maxResults", valid_601078
  var valid_601079 = query.getOrDefault("nextToken")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "nextToken", valid_601079
  var valid_601080 = query.getOrDefault("MaxResults")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "MaxResults", valid_601080
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
  var valid_601081 = header.getOrDefault("X-Amz-Date")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Date", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Security-Token")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Security-Token", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Content-Sha256", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Algorithm")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Algorithm", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Signature")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Signature", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-SignedHeaders", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Credential")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Credential", valid_601087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601088: Call_ListPackagingGroups_601074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
  ## 
  let valid = call_601088.validator(path, query, header, formData, body)
  let scheme = call_601088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601088.url(scheme.get, call_601088.host, call_601088.base,
                         call_601088.route, valid.getOrDefault("path"))
  result = hook(call_601088, url, valid)

proc call*(call_601089: Call_ListPackagingGroups_601074; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPackagingGroups
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Upper bound on number of records to return.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601090 = newJObject()
  add(query_601090, "NextToken", newJString(NextToken))
  add(query_601090, "maxResults", newJInt(maxResults))
  add(query_601090, "nextToken", newJString(nextToken))
  add(query_601090, "MaxResults", newJString(MaxResults))
  result = call_601089.call(nil, query_601090, nil, nil, nil)

var listPackagingGroups* = Call_ListPackagingGroups_601074(
    name: "listPackagingGroups", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_ListPackagingGroups_601075, base: "/",
    url: url_ListPackagingGroups_601076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAsset_601105 = ref object of OpenApiRestCall_600426
proc url_DescribeAsset_601107(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/assets/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeAsset_601106(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a description of a MediaPackage VOD Asset resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of an MediaPackage VOD Asset resource.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_601122 = path.getOrDefault("id")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = nil)
  if valid_601122 != nil:
    section.add "id", valid_601122
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
  var valid_601123 = header.getOrDefault("X-Amz-Date")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Date", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Security-Token")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Security-Token", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Content-Sha256", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Algorithm")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Algorithm", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Signature")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Signature", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-SignedHeaders", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Credential")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Credential", valid_601129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601130: Call_DescribeAsset_601105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD Asset resource.
  ## 
  let valid = call_601130.validator(path, query, header, formData, body)
  let scheme = call_601130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601130.url(scheme.get, call_601130.host, call_601130.base,
                         call_601130.route, valid.getOrDefault("path"))
  result = hook(call_601130, url, valid)

proc call*(call_601131: Call_DescribeAsset_601105; id: string): Recallable =
  ## describeAsset
  ## Returns a description of a MediaPackage VOD Asset resource.
  ##   id: string (required)
  ##     : The ID of an MediaPackage VOD Asset resource.
  var path_601132 = newJObject()
  add(path_601132, "id", newJString(id))
  result = call_601131.call(path_601132, nil, nil, nil, nil)

var describeAsset* = Call_DescribeAsset_601105(name: "describeAsset",
    meth: HttpMethod.HttpGet, host: "mediapackage-vod.amazonaws.com",
    route: "/assets/{id}", validator: validate_DescribeAsset_601106, base: "/",
    url: url_DescribeAsset_601107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_601133 = ref object of OpenApiRestCall_600426
proc url_DeleteAsset_601135(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/assets/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteAsset_601134(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing MediaPackage VOD Asset resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the MediaPackage VOD Asset resource to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_601136 = path.getOrDefault("id")
  valid_601136 = validateParameter(valid_601136, JString, required = true,
                                 default = nil)
  if valid_601136 != nil:
    section.add "id", valid_601136
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
  var valid_601137 = header.getOrDefault("X-Amz-Date")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Date", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Security-Token")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Security-Token", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Content-Sha256", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Algorithm")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Algorithm", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Signature", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-SignedHeaders", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Credential")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Credential", valid_601143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601144: Call_DeleteAsset_601133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing MediaPackage VOD Asset resource.
  ## 
  let valid = call_601144.validator(path, query, header, formData, body)
  let scheme = call_601144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601144.url(scheme.get, call_601144.host, call_601144.base,
                         call_601144.route, valid.getOrDefault("path"))
  result = hook(call_601144, url, valid)

proc call*(call_601145: Call_DeleteAsset_601133; id: string): Recallable =
  ## deleteAsset
  ## Deletes an existing MediaPackage VOD Asset resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD Asset resource to delete.
  var path_601146 = newJObject()
  add(path_601146, "id", newJString(id))
  result = call_601145.call(path_601146, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_601133(name: "deleteAsset",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediapackage-vod.amazonaws.com",
                                        route: "/assets/{id}",
                                        validator: validate_DeleteAsset_601134,
                                        base: "/", url: url_DeleteAsset_601135,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingConfiguration_601147 = ref object of OpenApiRestCall_600426
proc url_DescribePackagingConfiguration_601149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/packaging_configurations/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribePackagingConfiguration_601148(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of a MediaPackage VOD PackagingConfiguration resource.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_601150 = path.getOrDefault("id")
  valid_601150 = validateParameter(valid_601150, JString, required = true,
                                 default = nil)
  if valid_601150 != nil:
    section.add "id", valid_601150
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
  var valid_601151 = header.getOrDefault("X-Amz-Date")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Date", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Security-Token")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Security-Token", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Content-Sha256", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Algorithm")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Algorithm", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Signature")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Signature", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-SignedHeaders", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Credential")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Credential", valid_601157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601158: Call_DescribePackagingConfiguration_601147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_601158.validator(path, query, header, formData, body)
  let scheme = call_601158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601158.url(scheme.get, call_601158.host, call_601158.base,
                         call_601158.route, valid.getOrDefault("path"))
  result = hook(call_601158, url, valid)

proc call*(call_601159: Call_DescribePackagingConfiguration_601147; id: string): Recallable =
  ## describePackagingConfiguration
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ##   id: string (required)
  ##     : The ID of a MediaPackage VOD PackagingConfiguration resource.
  var path_601160 = newJObject()
  add(path_601160, "id", newJString(id))
  result = call_601159.call(path_601160, nil, nil, nil, nil)

var describePackagingConfiguration* = Call_DescribePackagingConfiguration_601147(
    name: "describePackagingConfiguration", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DescribePackagingConfiguration_601148, base: "/",
    url: url_DescribePackagingConfiguration_601149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingConfiguration_601161 = ref object of OpenApiRestCall_600426
proc url_DeletePackagingConfiguration_601163(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/packaging_configurations/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeletePackagingConfiguration_601162(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the MediaPackage VOD PackagingConfiguration resource to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_601164 = path.getOrDefault("id")
  valid_601164 = validateParameter(valid_601164, JString, required = true,
                                 default = nil)
  if valid_601164 != nil:
    section.add "id", valid_601164
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
  var valid_601165 = header.getOrDefault("X-Amz-Date")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Date", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Security-Token")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Security-Token", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Content-Sha256", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Algorithm")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Algorithm", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Signature")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Signature", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-SignedHeaders", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Credential")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Credential", valid_601171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601172: Call_DeletePackagingConfiguration_601161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_601172.validator(path, query, header, formData, body)
  let scheme = call_601172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601172.url(scheme.get, call_601172.host, call_601172.base,
                         call_601172.route, valid.getOrDefault("path"))
  result = hook(call_601172, url, valid)

proc call*(call_601173: Call_DeletePackagingConfiguration_601161; id: string): Recallable =
  ## deletePackagingConfiguration
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD PackagingConfiguration resource to delete.
  var path_601174 = newJObject()
  add(path_601174, "id", newJString(id))
  result = call_601173.call(path_601174, nil, nil, nil, nil)

var deletePackagingConfiguration* = Call_DeletePackagingConfiguration_601161(
    name: "deletePackagingConfiguration", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DeletePackagingConfiguration_601162, base: "/",
    url: url_DeletePackagingConfiguration_601163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingGroup_601175 = ref object of OpenApiRestCall_600426
proc url_DescribePackagingGroup_601177(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/packaging_groups/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribePackagingGroup_601176(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of a MediaPackage VOD PackagingGroup resource.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_601178 = path.getOrDefault("id")
  valid_601178 = validateParameter(valid_601178, JString, required = true,
                                 default = nil)
  if valid_601178 != nil:
    section.add "id", valid_601178
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
  var valid_601179 = header.getOrDefault("X-Amz-Date")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Date", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Security-Token")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Security-Token", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Content-Sha256", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Algorithm")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Algorithm", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Signature")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Signature", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-SignedHeaders", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Credential")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Credential", valid_601185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601186: Call_DescribePackagingGroup_601175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_601186.validator(path, query, header, formData, body)
  let scheme = call_601186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601186.url(scheme.get, call_601186.host, call_601186.base,
                         call_601186.route, valid.getOrDefault("path"))
  result = hook(call_601186, url, valid)

proc call*(call_601187: Call_DescribePackagingGroup_601175; id: string): Recallable =
  ## describePackagingGroup
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ##   id: string (required)
  ##     : The ID of a MediaPackage VOD PackagingGroup resource.
  var path_601188 = newJObject()
  add(path_601188, "id", newJString(id))
  result = call_601187.call(path_601188, nil, nil, nil, nil)

var describePackagingGroup* = Call_DescribePackagingGroup_601175(
    name: "describePackagingGroup", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DescribePackagingGroup_601176, base: "/",
    url: url_DescribePackagingGroup_601177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingGroup_601189 = ref object of OpenApiRestCall_600426
proc url_DeletePackagingGroup_601191(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/packaging_groups/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeletePackagingGroup_601190(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the MediaPackage VOD PackagingGroup resource to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_601192 = path.getOrDefault("id")
  valid_601192 = validateParameter(valid_601192, JString, required = true,
                                 default = nil)
  if valid_601192 != nil:
    section.add "id", valid_601192
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
  var valid_601193 = header.getOrDefault("X-Amz-Date")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Date", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Security-Token")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Security-Token", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Content-Sha256", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Algorithm")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Algorithm", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Signature")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Signature", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-SignedHeaders", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Credential")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Credential", valid_601199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601200: Call_DeletePackagingGroup_601189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_601200.validator(path, query, header, formData, body)
  let scheme = call_601200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601200.url(scheme.get, call_601200.host, call_601200.base,
                         call_601200.route, valid.getOrDefault("path"))
  result = hook(call_601200, url, valid)

proc call*(call_601201: Call_DeletePackagingGroup_601189; id: string): Recallable =
  ## deletePackagingGroup
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD PackagingGroup resource to delete.
  var path_601202 = newJObject()
  add(path_601202, "id", newJString(id))
  result = call_601201.call(path_601202, nil, nil, nil, nil)

var deletePackagingGroup* = Call_DeletePackagingGroup_601189(
    name: "deletePackagingGroup", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DeletePackagingGroup_601190, base: "/",
    url: url_DeletePackagingGroup_601191, schemes: {Scheme.Https, Scheme.Http})
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
