
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateAsset_594034 = ref object of OpenApiRestCall_593437
proc url_CreateAsset_594036(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAsset_594035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594037 = header.getOrDefault("X-Amz-Date")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Date", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Security-Token")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Security-Token", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Content-Sha256", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Algorithm")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Algorithm", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Signature")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Signature", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-SignedHeaders", valid_594042
  var valid_594043 = header.getOrDefault("X-Amz-Credential")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "X-Amz-Credential", valid_594043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594045: Call_CreateAsset_594034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD Asset resource.
  ## 
  let valid = call_594045.validator(path, query, header, formData, body)
  let scheme = call_594045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594045.url(scheme.get, call_594045.host, call_594045.base,
                         call_594045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594045, url, valid)

proc call*(call_594046: Call_CreateAsset_594034; body: JsonNode): Recallable =
  ## createAsset
  ## Creates a new MediaPackage VOD Asset resource.
  ##   body: JObject (required)
  var body_594047 = newJObject()
  if body != nil:
    body_594047 = body
  result = call_594046.call(nil, nil, nil, nil, body_594047)

var createAsset* = Call_CreateAsset_594034(name: "createAsset",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediapackage-vod.amazonaws.com",
                                        route: "/assets",
                                        validator: validate_CreateAsset_594035,
                                        base: "/", url: url_CreateAsset_594036,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssets_593774 = ref object of OpenApiRestCall_593437
proc url_ListAssets_593776(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssets_593775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593888 = query.getOrDefault("packagingGroupId")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "packagingGroupId", valid_593888
  var valid_593889 = query.getOrDefault("NextToken")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "NextToken", valid_593889
  var valid_593890 = query.getOrDefault("maxResults")
  valid_593890 = validateParameter(valid_593890, JInt, required = false, default = nil)
  if valid_593890 != nil:
    section.add "maxResults", valid_593890
  var valid_593891 = query.getOrDefault("nextToken")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "nextToken", valid_593891
  var valid_593892 = query.getOrDefault("MaxResults")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "MaxResults", valid_593892
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
  var valid_593893 = header.getOrDefault("X-Amz-Date")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Date", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Security-Token")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Security-Token", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Content-Sha256", valid_593895
  var valid_593896 = header.getOrDefault("X-Amz-Algorithm")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-Algorithm", valid_593896
  var valid_593897 = header.getOrDefault("X-Amz-Signature")
  valid_593897 = validateParameter(valid_593897, JString, required = false,
                                 default = nil)
  if valid_593897 != nil:
    section.add "X-Amz-Signature", valid_593897
  var valid_593898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593898 = validateParameter(valid_593898, JString, required = false,
                                 default = nil)
  if valid_593898 != nil:
    section.add "X-Amz-SignedHeaders", valid_593898
  var valid_593899 = header.getOrDefault("X-Amz-Credential")
  valid_593899 = validateParameter(valid_593899, JString, required = false,
                                 default = nil)
  if valid_593899 != nil:
    section.add "X-Amz-Credential", valid_593899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593922: Call_ListAssets_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD Asset resources.
  ## 
  let valid = call_593922.validator(path, query, header, formData, body)
  let scheme = call_593922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593922.url(scheme.get, call_593922.host, call_593922.base,
                         call_593922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593922, url, valid)

proc call*(call_593993: Call_ListAssets_593774; packagingGroupId: string = "";
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
  var query_593994 = newJObject()
  add(query_593994, "packagingGroupId", newJString(packagingGroupId))
  add(query_593994, "NextToken", newJString(NextToken))
  add(query_593994, "maxResults", newJInt(maxResults))
  add(query_593994, "nextToken", newJString(nextToken))
  add(query_593994, "MaxResults", newJString(MaxResults))
  result = call_593993.call(nil, query_593994, nil, nil, nil)

var listAssets* = Call_ListAssets_593774(name: "listAssets",
                                      meth: HttpMethod.HttpGet,
                                      host: "mediapackage-vod.amazonaws.com",
                                      route: "/assets",
                                      validator: validate_ListAssets_593775,
                                      base: "/", url: url_ListAssets_593776,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingConfiguration_594066 = ref object of OpenApiRestCall_593437
proc url_CreatePackagingConfiguration_594068(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePackagingConfiguration_594067(path: JsonNode; query: JsonNode;
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
  var valid_594069 = header.getOrDefault("X-Amz-Date")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Date", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Security-Token")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Security-Token", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Content-Sha256", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Algorithm")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Algorithm", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Signature")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Signature", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-SignedHeaders", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Credential")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Credential", valid_594075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594077: Call_CreatePackagingConfiguration_594066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_594077.validator(path, query, header, formData, body)
  let scheme = call_594077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594077.url(scheme.get, call_594077.host, call_594077.base,
                         call_594077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594077, url, valid)

proc call*(call_594078: Call_CreatePackagingConfiguration_594066; body: JsonNode): Recallable =
  ## createPackagingConfiguration
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
  ##   body: JObject (required)
  var body_594079 = newJObject()
  if body != nil:
    body_594079 = body
  result = call_594078.call(nil, nil, nil, nil, body_594079)

var createPackagingConfiguration* = Call_CreatePackagingConfiguration_594066(
    name: "createPackagingConfiguration", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_CreatePackagingConfiguration_594067, base: "/",
    url: url_CreatePackagingConfiguration_594068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingConfigurations_594048 = ref object of OpenApiRestCall_593437
proc url_ListPackagingConfigurations_594050(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPackagingConfigurations_594049(path: JsonNode; query: JsonNode;
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
  var valid_594051 = query.getOrDefault("packagingGroupId")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "packagingGroupId", valid_594051
  var valid_594052 = query.getOrDefault("NextToken")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "NextToken", valid_594052
  var valid_594053 = query.getOrDefault("maxResults")
  valid_594053 = validateParameter(valid_594053, JInt, required = false, default = nil)
  if valid_594053 != nil:
    section.add "maxResults", valid_594053
  var valid_594054 = query.getOrDefault("nextToken")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "nextToken", valid_594054
  var valid_594055 = query.getOrDefault("MaxResults")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "MaxResults", valid_594055
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
  var valid_594056 = header.getOrDefault("X-Amz-Date")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Date", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Security-Token")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Security-Token", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Content-Sha256", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Algorithm")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Algorithm", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Signature")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Signature", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-SignedHeaders", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Credential")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Credential", valid_594062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594063: Call_ListPackagingConfigurations_594048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
  ## 
  let valid = call_594063.validator(path, query, header, formData, body)
  let scheme = call_594063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594063.url(scheme.get, call_594063.host, call_594063.base,
                         call_594063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594063, url, valid)

proc call*(call_594064: Call_ListPackagingConfigurations_594048;
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
  var query_594065 = newJObject()
  add(query_594065, "packagingGroupId", newJString(packagingGroupId))
  add(query_594065, "NextToken", newJString(NextToken))
  add(query_594065, "maxResults", newJInt(maxResults))
  add(query_594065, "nextToken", newJString(nextToken))
  add(query_594065, "MaxResults", newJString(MaxResults))
  result = call_594064.call(nil, query_594065, nil, nil, nil)

var listPackagingConfigurations* = Call_ListPackagingConfigurations_594048(
    name: "listPackagingConfigurations", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_ListPackagingConfigurations_594049, base: "/",
    url: url_ListPackagingConfigurations_594050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingGroup_594097 = ref object of OpenApiRestCall_593437
proc url_CreatePackagingGroup_594099(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePackagingGroup_594098(path: JsonNode; query: JsonNode;
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
  var valid_594100 = header.getOrDefault("X-Amz-Date")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Date", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Security-Token")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Security-Token", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Content-Sha256", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-Algorithm")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-Algorithm", valid_594103
  var valid_594104 = header.getOrDefault("X-Amz-Signature")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-Signature", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-SignedHeaders", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Credential")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Credential", valid_594106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594108: Call_CreatePackagingGroup_594097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_594108.validator(path, query, header, formData, body)
  let scheme = call_594108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594108.url(scheme.get, call_594108.host, call_594108.base,
                         call_594108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594108, url, valid)

proc call*(call_594109: Call_CreatePackagingGroup_594097; body: JsonNode): Recallable =
  ## createPackagingGroup
  ## Creates a new MediaPackage VOD PackagingGroup resource.
  ##   body: JObject (required)
  var body_594110 = newJObject()
  if body != nil:
    body_594110 = body
  result = call_594109.call(nil, nil, nil, nil, body_594110)

var createPackagingGroup* = Call_CreatePackagingGroup_594097(
    name: "createPackagingGroup", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_CreatePackagingGroup_594098, base: "/",
    url: url_CreatePackagingGroup_594099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingGroups_594080 = ref object of OpenApiRestCall_593437
proc url_ListPackagingGroups_594082(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPackagingGroups_594081(path: JsonNode; query: JsonNode;
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
  var valid_594083 = query.getOrDefault("NextToken")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "NextToken", valid_594083
  var valid_594084 = query.getOrDefault("maxResults")
  valid_594084 = validateParameter(valid_594084, JInt, required = false, default = nil)
  if valid_594084 != nil:
    section.add "maxResults", valid_594084
  var valid_594085 = query.getOrDefault("nextToken")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "nextToken", valid_594085
  var valid_594086 = query.getOrDefault("MaxResults")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "MaxResults", valid_594086
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
  var valid_594087 = header.getOrDefault("X-Amz-Date")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Date", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Security-Token")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Security-Token", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Content-Sha256", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Algorithm")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Algorithm", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Signature")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Signature", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-SignedHeaders", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Credential")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Credential", valid_594093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594094: Call_ListPackagingGroups_594080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
  ## 
  let valid = call_594094.validator(path, query, header, formData, body)
  let scheme = call_594094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594094.url(scheme.get, call_594094.host, call_594094.base,
                         call_594094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594094, url, valid)

proc call*(call_594095: Call_ListPackagingGroups_594080; NextToken: string = "";
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
  var query_594096 = newJObject()
  add(query_594096, "NextToken", newJString(NextToken))
  add(query_594096, "maxResults", newJInt(maxResults))
  add(query_594096, "nextToken", newJString(nextToken))
  add(query_594096, "MaxResults", newJString(MaxResults))
  result = call_594095.call(nil, query_594096, nil, nil, nil)

var listPackagingGroups* = Call_ListPackagingGroups_594080(
    name: "listPackagingGroups", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_ListPackagingGroups_594081, base: "/",
    url: url_ListPackagingGroups_594082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAsset_594111 = ref object of OpenApiRestCall_593437
proc url_DescribeAsset_594113(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeAsset_594112(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594128 = path.getOrDefault("id")
  valid_594128 = validateParameter(valid_594128, JString, required = true,
                                 default = nil)
  if valid_594128 != nil:
    section.add "id", valid_594128
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
  var valid_594129 = header.getOrDefault("X-Amz-Date")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Date", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Security-Token")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Security-Token", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Content-Sha256", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Algorithm")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Algorithm", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Signature")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Signature", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-SignedHeaders", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Credential")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Credential", valid_594135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594136: Call_DescribeAsset_594111; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD Asset resource.
  ## 
  let valid = call_594136.validator(path, query, header, formData, body)
  let scheme = call_594136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594136.url(scheme.get, call_594136.host, call_594136.base,
                         call_594136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594136, url, valid)

proc call*(call_594137: Call_DescribeAsset_594111; id: string): Recallable =
  ## describeAsset
  ## Returns a description of a MediaPackage VOD Asset resource.
  ##   id: string (required)
  ##     : The ID of an MediaPackage VOD Asset resource.
  var path_594138 = newJObject()
  add(path_594138, "id", newJString(id))
  result = call_594137.call(path_594138, nil, nil, nil, nil)

var describeAsset* = Call_DescribeAsset_594111(name: "describeAsset",
    meth: HttpMethod.HttpGet, host: "mediapackage-vod.amazonaws.com",
    route: "/assets/{id}", validator: validate_DescribeAsset_594112, base: "/",
    url: url_DescribeAsset_594113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_594139 = ref object of OpenApiRestCall_593437
proc url_DeleteAsset_594141(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteAsset_594140(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594142 = path.getOrDefault("id")
  valid_594142 = validateParameter(valid_594142, JString, required = true,
                                 default = nil)
  if valid_594142 != nil:
    section.add "id", valid_594142
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
  var valid_594143 = header.getOrDefault("X-Amz-Date")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Date", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Security-Token")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Security-Token", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Content-Sha256", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Algorithm")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Algorithm", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Signature")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Signature", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-SignedHeaders", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Credential")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Credential", valid_594149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594150: Call_DeleteAsset_594139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing MediaPackage VOD Asset resource.
  ## 
  let valid = call_594150.validator(path, query, header, formData, body)
  let scheme = call_594150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594150.url(scheme.get, call_594150.host, call_594150.base,
                         call_594150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594150, url, valid)

proc call*(call_594151: Call_DeleteAsset_594139; id: string): Recallable =
  ## deleteAsset
  ## Deletes an existing MediaPackage VOD Asset resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD Asset resource to delete.
  var path_594152 = newJObject()
  add(path_594152, "id", newJString(id))
  result = call_594151.call(path_594152, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_594139(name: "deleteAsset",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediapackage-vod.amazonaws.com",
                                        route: "/assets/{id}",
                                        validator: validate_DeleteAsset_594140,
                                        base: "/", url: url_DeleteAsset_594141,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingConfiguration_594153 = ref object of OpenApiRestCall_593437
proc url_DescribePackagingConfiguration_594155(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribePackagingConfiguration_594154(path: JsonNode;
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
  var valid_594156 = path.getOrDefault("id")
  valid_594156 = validateParameter(valid_594156, JString, required = true,
                                 default = nil)
  if valid_594156 != nil:
    section.add "id", valid_594156
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
  var valid_594157 = header.getOrDefault("X-Amz-Date")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Date", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Security-Token")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Security-Token", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Content-Sha256", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Algorithm")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Algorithm", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Signature")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Signature", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-SignedHeaders", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Credential")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Credential", valid_594163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594164: Call_DescribePackagingConfiguration_594153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_594164.validator(path, query, header, formData, body)
  let scheme = call_594164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594164.url(scheme.get, call_594164.host, call_594164.base,
                         call_594164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594164, url, valid)

proc call*(call_594165: Call_DescribePackagingConfiguration_594153; id: string): Recallable =
  ## describePackagingConfiguration
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ##   id: string (required)
  ##     : The ID of a MediaPackage VOD PackagingConfiguration resource.
  var path_594166 = newJObject()
  add(path_594166, "id", newJString(id))
  result = call_594165.call(path_594166, nil, nil, nil, nil)

var describePackagingConfiguration* = Call_DescribePackagingConfiguration_594153(
    name: "describePackagingConfiguration", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DescribePackagingConfiguration_594154, base: "/",
    url: url_DescribePackagingConfiguration_594155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingConfiguration_594167 = ref object of OpenApiRestCall_593437
proc url_DeletePackagingConfiguration_594169(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeletePackagingConfiguration_594168(path: JsonNode; query: JsonNode;
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
  var valid_594170 = path.getOrDefault("id")
  valid_594170 = validateParameter(valid_594170, JString, required = true,
                                 default = nil)
  if valid_594170 != nil:
    section.add "id", valid_594170
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
  var valid_594171 = header.getOrDefault("X-Amz-Date")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Date", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Security-Token")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Security-Token", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Content-Sha256", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Algorithm")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Algorithm", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-Signature")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-Signature", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-SignedHeaders", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Credential")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Credential", valid_594177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594178: Call_DeletePackagingConfiguration_594167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_594178.validator(path, query, header, formData, body)
  let scheme = call_594178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594178.url(scheme.get, call_594178.host, call_594178.base,
                         call_594178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594178, url, valid)

proc call*(call_594179: Call_DeletePackagingConfiguration_594167; id: string): Recallable =
  ## deletePackagingConfiguration
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD PackagingConfiguration resource to delete.
  var path_594180 = newJObject()
  add(path_594180, "id", newJString(id))
  result = call_594179.call(path_594180, nil, nil, nil, nil)

var deletePackagingConfiguration* = Call_DeletePackagingConfiguration_594167(
    name: "deletePackagingConfiguration", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DeletePackagingConfiguration_594168, base: "/",
    url: url_DeletePackagingConfiguration_594169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingGroup_594181 = ref object of OpenApiRestCall_593437
proc url_DescribePackagingGroup_594183(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_DescribePackagingGroup_594182(path: JsonNode; query: JsonNode;
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
  var valid_594184 = path.getOrDefault("id")
  valid_594184 = validateParameter(valid_594184, JString, required = true,
                                 default = nil)
  if valid_594184 != nil:
    section.add "id", valid_594184
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
  var valid_594185 = header.getOrDefault("X-Amz-Date")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Date", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Security-Token")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Security-Token", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-Content-Sha256", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Algorithm")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Algorithm", valid_594188
  var valid_594189 = header.getOrDefault("X-Amz-Signature")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "X-Amz-Signature", valid_594189
  var valid_594190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-SignedHeaders", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Credential")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Credential", valid_594191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594192: Call_DescribePackagingGroup_594181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_594192.validator(path, query, header, formData, body)
  let scheme = call_594192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594192.url(scheme.get, call_594192.host, call_594192.base,
                         call_594192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594192, url, valid)

proc call*(call_594193: Call_DescribePackagingGroup_594181; id: string): Recallable =
  ## describePackagingGroup
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ##   id: string (required)
  ##     : The ID of a MediaPackage VOD PackagingGroup resource.
  var path_594194 = newJObject()
  add(path_594194, "id", newJString(id))
  result = call_594193.call(path_594194, nil, nil, nil, nil)

var describePackagingGroup* = Call_DescribePackagingGroup_594181(
    name: "describePackagingGroup", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DescribePackagingGroup_594182, base: "/",
    url: url_DescribePackagingGroup_594183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingGroup_594195 = ref object of OpenApiRestCall_593437
proc url_DeletePackagingGroup_594197(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_DeletePackagingGroup_594196(path: JsonNode; query: JsonNode;
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
  var valid_594198 = path.getOrDefault("id")
  valid_594198 = validateParameter(valid_594198, JString, required = true,
                                 default = nil)
  if valid_594198 != nil:
    section.add "id", valid_594198
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
  var valid_594199 = header.getOrDefault("X-Amz-Date")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Date", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Security-Token")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Security-Token", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Content-Sha256", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Algorithm")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Algorithm", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Signature")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Signature", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-SignedHeaders", valid_594204
  var valid_594205 = header.getOrDefault("X-Amz-Credential")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Credential", valid_594205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594206: Call_DeletePackagingGroup_594195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_594206.validator(path, query, header, formData, body)
  let scheme = call_594206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594206.url(scheme.get, call_594206.host, call_594206.base,
                         call_594206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594206, url, valid)

proc call*(call_594207: Call_DeletePackagingGroup_594195; id: string): Recallable =
  ## deletePackagingGroup
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD PackagingGroup resource to delete.
  var path_594208 = newJObject()
  add(path_594208, "id", newJString(id))
  result = call_594207.call(path_594208, nil, nil, nil, nil)

var deletePackagingGroup* = Call_DeletePackagingGroup_594195(
    name: "deletePackagingGroup", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DeletePackagingGroup_594196, base: "/",
    url: url_DeletePackagingGroup_594197, schemes: {Scheme.Https, Scheme.Http})
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
