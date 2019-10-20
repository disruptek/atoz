
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
  Call_CreateAsset_592963 = ref object of OpenApiRestCall_592364
proc url_CreateAsset_592965(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAsset_592964(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592966 = header.getOrDefault("X-Amz-Signature")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Signature", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Content-Sha256", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Date")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Date", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-Credential")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-Credential", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-Security-Token")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-Security-Token", valid_592970
  var valid_592971 = header.getOrDefault("X-Amz-Algorithm")
  valid_592971 = validateParameter(valid_592971, JString, required = false,
                                 default = nil)
  if valid_592971 != nil:
    section.add "X-Amz-Algorithm", valid_592971
  var valid_592972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592972 = validateParameter(valid_592972, JString, required = false,
                                 default = nil)
  if valid_592972 != nil:
    section.add "X-Amz-SignedHeaders", valid_592972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592974: Call_CreateAsset_592963; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD Asset resource.
  ## 
  let valid = call_592974.validator(path, query, header, formData, body)
  let scheme = call_592974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592974.url(scheme.get, call_592974.host, call_592974.base,
                         call_592974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592974, url, valid)

proc call*(call_592975: Call_CreateAsset_592963; body: JsonNode): Recallable =
  ## createAsset
  ## Creates a new MediaPackage VOD Asset resource.
  ##   body: JObject (required)
  var body_592976 = newJObject()
  if body != nil:
    body_592976 = body
  result = call_592975.call(nil, nil, nil, nil, body_592976)

var createAsset* = Call_CreateAsset_592963(name: "createAsset",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediapackage-vod.amazonaws.com",
                                        route: "/assets",
                                        validator: validate_CreateAsset_592964,
                                        base: "/", url: url_CreateAsset_592965,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssets_592703 = ref object of OpenApiRestCall_592364
proc url_ListAssets_592705(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssets_592704(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a collection of MediaPackage VOD Asset resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   packagingGroupId: JString
  ##                   : Returns Assets associated with the specified PackagingGroup.
  ##   maxResults: JInt
  ##             : Upper bound on number of records to return.
  section = newJObject()
  var valid_592817 = query.getOrDefault("nextToken")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "nextToken", valid_592817
  var valid_592818 = query.getOrDefault("MaxResults")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "MaxResults", valid_592818
  var valid_592819 = query.getOrDefault("NextToken")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "NextToken", valid_592819
  var valid_592820 = query.getOrDefault("packagingGroupId")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "packagingGroupId", valid_592820
  var valid_592821 = query.getOrDefault("maxResults")
  valid_592821 = validateParameter(valid_592821, JInt, required = false, default = nil)
  if valid_592821 != nil:
    section.add "maxResults", valid_592821
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
  var valid_592822 = header.getOrDefault("X-Amz-Signature")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Signature", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Content-Sha256", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Date")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Date", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-Credential")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-Credential", valid_592825
  var valid_592826 = header.getOrDefault("X-Amz-Security-Token")
  valid_592826 = validateParameter(valid_592826, JString, required = false,
                                 default = nil)
  if valid_592826 != nil:
    section.add "X-Amz-Security-Token", valid_592826
  var valid_592827 = header.getOrDefault("X-Amz-Algorithm")
  valid_592827 = validateParameter(valid_592827, JString, required = false,
                                 default = nil)
  if valid_592827 != nil:
    section.add "X-Amz-Algorithm", valid_592827
  var valid_592828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592828 = validateParameter(valid_592828, JString, required = false,
                                 default = nil)
  if valid_592828 != nil:
    section.add "X-Amz-SignedHeaders", valid_592828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592851: Call_ListAssets_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD Asset resources.
  ## 
  let valid = call_592851.validator(path, query, header, formData, body)
  let scheme = call_592851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592851.url(scheme.get, call_592851.host, call_592851.base,
                         call_592851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592851, url, valid)

proc call*(call_592922: Call_ListAssets_592703; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = "";
          packagingGroupId: string = ""; maxResults: int = 0): Recallable =
  ## listAssets
  ## Returns a collection of MediaPackage VOD Asset resources.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   packagingGroupId: string
  ##                   : Returns Assets associated with the specified PackagingGroup.
  ##   maxResults: int
  ##             : Upper bound on number of records to return.
  var query_592923 = newJObject()
  add(query_592923, "nextToken", newJString(nextToken))
  add(query_592923, "MaxResults", newJString(MaxResults))
  add(query_592923, "NextToken", newJString(NextToken))
  add(query_592923, "packagingGroupId", newJString(packagingGroupId))
  add(query_592923, "maxResults", newJInt(maxResults))
  result = call_592922.call(nil, query_592923, nil, nil, nil)

var listAssets* = Call_ListAssets_592703(name: "listAssets",
                                      meth: HttpMethod.HttpGet,
                                      host: "mediapackage-vod.amazonaws.com",
                                      route: "/assets",
                                      validator: validate_ListAssets_592704,
                                      base: "/", url: url_ListAssets_592705,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingConfiguration_592995 = ref object of OpenApiRestCall_592364
proc url_CreatePackagingConfiguration_592997(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePackagingConfiguration_592996(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592998 = header.getOrDefault("X-Amz-Signature")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Signature", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Content-Sha256", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Date")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Date", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Credential")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Credential", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Security-Token")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Security-Token", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Algorithm")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Algorithm", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-SignedHeaders", valid_593004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593006: Call_CreatePackagingConfiguration_592995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_593006.validator(path, query, header, formData, body)
  let scheme = call_593006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593006.url(scheme.get, call_593006.host, call_593006.base,
                         call_593006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593006, url, valid)

proc call*(call_593007: Call_CreatePackagingConfiguration_592995; body: JsonNode): Recallable =
  ## createPackagingConfiguration
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
  ##   body: JObject (required)
  var body_593008 = newJObject()
  if body != nil:
    body_593008 = body
  result = call_593007.call(nil, nil, nil, nil, body_593008)

var createPackagingConfiguration* = Call_CreatePackagingConfiguration_592995(
    name: "createPackagingConfiguration", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_CreatePackagingConfiguration_592996, base: "/",
    url: url_CreatePackagingConfiguration_592997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingConfigurations_592977 = ref object of OpenApiRestCall_592364
proc url_ListPackagingConfigurations_592979(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPackagingConfigurations_592978(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   packagingGroupId: JString
  ##                   : Returns MediaPackage VOD PackagingConfigurations associated with the specified PackagingGroup.
  ##   maxResults: JInt
  ##             : Upper bound on number of records to return.
  section = newJObject()
  var valid_592980 = query.getOrDefault("nextToken")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "nextToken", valid_592980
  var valid_592981 = query.getOrDefault("MaxResults")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "MaxResults", valid_592981
  var valid_592982 = query.getOrDefault("NextToken")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "NextToken", valid_592982
  var valid_592983 = query.getOrDefault("packagingGroupId")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "packagingGroupId", valid_592983
  var valid_592984 = query.getOrDefault("maxResults")
  valid_592984 = validateParameter(valid_592984, JInt, required = false, default = nil)
  if valid_592984 != nil:
    section.add "maxResults", valid_592984
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
  var valid_592985 = header.getOrDefault("X-Amz-Signature")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Signature", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Content-Sha256", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Date")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Date", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Credential")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Credential", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-Security-Token")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Security-Token", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-Algorithm")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Algorithm", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-SignedHeaders", valid_592991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592992: Call_ListPackagingConfigurations_592977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
  ## 
  let valid = call_592992.validator(path, query, header, formData, body)
  let scheme = call_592992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592992.url(scheme.get, call_592992.host, call_592992.base,
                         call_592992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592992, url, valid)

proc call*(call_592993: Call_ListPackagingConfigurations_592977;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          packagingGroupId: string = ""; maxResults: int = 0): Recallable =
  ## listPackagingConfigurations
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   packagingGroupId: string
  ##                   : Returns MediaPackage VOD PackagingConfigurations associated with the specified PackagingGroup.
  ##   maxResults: int
  ##             : Upper bound on number of records to return.
  var query_592994 = newJObject()
  add(query_592994, "nextToken", newJString(nextToken))
  add(query_592994, "MaxResults", newJString(MaxResults))
  add(query_592994, "NextToken", newJString(NextToken))
  add(query_592994, "packagingGroupId", newJString(packagingGroupId))
  add(query_592994, "maxResults", newJInt(maxResults))
  result = call_592993.call(nil, query_592994, nil, nil, nil)

var listPackagingConfigurations* = Call_ListPackagingConfigurations_592977(
    name: "listPackagingConfigurations", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_ListPackagingConfigurations_592978, base: "/",
    url: url_ListPackagingConfigurations_592979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingGroup_593026 = ref object of OpenApiRestCall_592364
proc url_CreatePackagingGroup_593028(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePackagingGroup_593027(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593029 = header.getOrDefault("X-Amz-Signature")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Signature", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Content-Sha256", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Date")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Date", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Credential")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Credential", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Security-Token")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Security-Token", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Algorithm")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Algorithm", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-SignedHeaders", valid_593035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593037: Call_CreatePackagingGroup_593026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_593037.validator(path, query, header, formData, body)
  let scheme = call_593037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593037.url(scheme.get, call_593037.host, call_593037.base,
                         call_593037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593037, url, valid)

proc call*(call_593038: Call_CreatePackagingGroup_593026; body: JsonNode): Recallable =
  ## createPackagingGroup
  ## Creates a new MediaPackage VOD PackagingGroup resource.
  ##   body: JObject (required)
  var body_593039 = newJObject()
  if body != nil:
    body_593039 = body
  result = call_593038.call(nil, nil, nil, nil, body_593039)

var createPackagingGroup* = Call_CreatePackagingGroup_593026(
    name: "createPackagingGroup", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_CreatePackagingGroup_593027, base: "/",
    url: url_CreatePackagingGroup_593028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingGroups_593009 = ref object of OpenApiRestCall_592364
proc url_ListPackagingGroups_593011(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPackagingGroups_593010(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Upper bound on number of records to return.
  section = newJObject()
  var valid_593012 = query.getOrDefault("nextToken")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "nextToken", valid_593012
  var valid_593013 = query.getOrDefault("MaxResults")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "MaxResults", valid_593013
  var valid_593014 = query.getOrDefault("NextToken")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "NextToken", valid_593014
  var valid_593015 = query.getOrDefault("maxResults")
  valid_593015 = validateParameter(valid_593015, JInt, required = false, default = nil)
  if valid_593015 != nil:
    section.add "maxResults", valid_593015
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
  var valid_593016 = header.getOrDefault("X-Amz-Signature")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Signature", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Content-Sha256", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Date")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Date", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Credential")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Credential", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Security-Token")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Security-Token", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Algorithm")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Algorithm", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-SignedHeaders", valid_593022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593023: Call_ListPackagingGroups_593009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
  ## 
  let valid = call_593023.validator(path, query, header, formData, body)
  let scheme = call_593023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593023.url(scheme.get, call_593023.host, call_593023.base,
                         call_593023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593023, url, valid)

proc call*(call_593024: Call_ListPackagingGroups_593009; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listPackagingGroups
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Upper bound on number of records to return.
  var query_593025 = newJObject()
  add(query_593025, "nextToken", newJString(nextToken))
  add(query_593025, "MaxResults", newJString(MaxResults))
  add(query_593025, "NextToken", newJString(NextToken))
  add(query_593025, "maxResults", newJInt(maxResults))
  result = call_593024.call(nil, query_593025, nil, nil, nil)

var listPackagingGroups* = Call_ListPackagingGroups_593009(
    name: "listPackagingGroups", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_ListPackagingGroups_593010, base: "/",
    url: url_ListPackagingGroups_593011, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAsset_593040 = ref object of OpenApiRestCall_592364
proc url_DescribeAsset_593042(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAsset_593041(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593057 = path.getOrDefault("id")
  valid_593057 = validateParameter(valid_593057, JString, required = true,
                                 default = nil)
  if valid_593057 != nil:
    section.add "id", valid_593057
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
  var valid_593058 = header.getOrDefault("X-Amz-Signature")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Signature", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Content-Sha256", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Date")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Date", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Credential")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Credential", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Security-Token")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Security-Token", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Algorithm")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Algorithm", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-SignedHeaders", valid_593064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593065: Call_DescribeAsset_593040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD Asset resource.
  ## 
  let valid = call_593065.validator(path, query, header, formData, body)
  let scheme = call_593065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593065.url(scheme.get, call_593065.host, call_593065.base,
                         call_593065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593065, url, valid)

proc call*(call_593066: Call_DescribeAsset_593040; id: string): Recallable =
  ## describeAsset
  ## Returns a description of a MediaPackage VOD Asset resource.
  ##   id: string (required)
  ##     : The ID of an MediaPackage VOD Asset resource.
  var path_593067 = newJObject()
  add(path_593067, "id", newJString(id))
  result = call_593066.call(path_593067, nil, nil, nil, nil)

var describeAsset* = Call_DescribeAsset_593040(name: "describeAsset",
    meth: HttpMethod.HttpGet, host: "mediapackage-vod.amazonaws.com",
    route: "/assets/{id}", validator: validate_DescribeAsset_593041, base: "/",
    url: url_DescribeAsset_593042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_593068 = ref object of OpenApiRestCall_592364
proc url_DeleteAsset_593070(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAsset_593069(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593071 = path.getOrDefault("id")
  valid_593071 = validateParameter(valid_593071, JString, required = true,
                                 default = nil)
  if valid_593071 != nil:
    section.add "id", valid_593071
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
  var valid_593072 = header.getOrDefault("X-Amz-Signature")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Signature", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Content-Sha256", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Date")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Date", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Credential")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Credential", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Security-Token")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Security-Token", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Algorithm")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Algorithm", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-SignedHeaders", valid_593078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593079: Call_DeleteAsset_593068; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing MediaPackage VOD Asset resource.
  ## 
  let valid = call_593079.validator(path, query, header, formData, body)
  let scheme = call_593079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593079.url(scheme.get, call_593079.host, call_593079.base,
                         call_593079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593079, url, valid)

proc call*(call_593080: Call_DeleteAsset_593068; id: string): Recallable =
  ## deleteAsset
  ## Deletes an existing MediaPackage VOD Asset resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD Asset resource to delete.
  var path_593081 = newJObject()
  add(path_593081, "id", newJString(id))
  result = call_593080.call(path_593081, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_593068(name: "deleteAsset",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediapackage-vod.amazonaws.com",
                                        route: "/assets/{id}",
                                        validator: validate_DeleteAsset_593069,
                                        base: "/", url: url_DeleteAsset_593070,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingConfiguration_593082 = ref object of OpenApiRestCall_592364
proc url_DescribePackagingConfiguration_593084(protocol: Scheme; host: string;
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

proc validate_DescribePackagingConfiguration_593083(path: JsonNode;
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
  var valid_593085 = path.getOrDefault("id")
  valid_593085 = validateParameter(valid_593085, JString, required = true,
                                 default = nil)
  if valid_593085 != nil:
    section.add "id", valid_593085
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
  var valid_593086 = header.getOrDefault("X-Amz-Signature")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Signature", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Content-Sha256", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Date")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Date", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Credential")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Credential", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Security-Token")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Security-Token", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Algorithm")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Algorithm", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-SignedHeaders", valid_593092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593093: Call_DescribePackagingConfiguration_593082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_593093.validator(path, query, header, formData, body)
  let scheme = call_593093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593093.url(scheme.get, call_593093.host, call_593093.base,
                         call_593093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593093, url, valid)

proc call*(call_593094: Call_DescribePackagingConfiguration_593082; id: string): Recallable =
  ## describePackagingConfiguration
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ##   id: string (required)
  ##     : The ID of a MediaPackage VOD PackagingConfiguration resource.
  var path_593095 = newJObject()
  add(path_593095, "id", newJString(id))
  result = call_593094.call(path_593095, nil, nil, nil, nil)

var describePackagingConfiguration* = Call_DescribePackagingConfiguration_593082(
    name: "describePackagingConfiguration", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DescribePackagingConfiguration_593083, base: "/",
    url: url_DescribePackagingConfiguration_593084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingConfiguration_593096 = ref object of OpenApiRestCall_592364
proc url_DeletePackagingConfiguration_593098(protocol: Scheme; host: string;
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

proc validate_DeletePackagingConfiguration_593097(path: JsonNode; query: JsonNode;
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
  var valid_593099 = path.getOrDefault("id")
  valid_593099 = validateParameter(valid_593099, JString, required = true,
                                 default = nil)
  if valid_593099 != nil:
    section.add "id", valid_593099
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
  var valid_593100 = header.getOrDefault("X-Amz-Signature")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Signature", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Content-Sha256", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Date")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Date", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Credential")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Credential", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Security-Token")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Security-Token", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Algorithm")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Algorithm", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-SignedHeaders", valid_593106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593107: Call_DeletePackagingConfiguration_593096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_593107.validator(path, query, header, formData, body)
  let scheme = call_593107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593107.url(scheme.get, call_593107.host, call_593107.base,
                         call_593107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593107, url, valid)

proc call*(call_593108: Call_DeletePackagingConfiguration_593096; id: string): Recallable =
  ## deletePackagingConfiguration
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD PackagingConfiguration resource to delete.
  var path_593109 = newJObject()
  add(path_593109, "id", newJString(id))
  result = call_593108.call(path_593109, nil, nil, nil, nil)

var deletePackagingConfiguration* = Call_DeletePackagingConfiguration_593096(
    name: "deletePackagingConfiguration", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DeletePackagingConfiguration_593097, base: "/",
    url: url_DeletePackagingConfiguration_593098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingGroup_593110 = ref object of OpenApiRestCall_592364
proc url_DescribePackagingGroup_593112(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePackagingGroup_593111(path: JsonNode; query: JsonNode;
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
  var valid_593113 = path.getOrDefault("id")
  valid_593113 = validateParameter(valid_593113, JString, required = true,
                                 default = nil)
  if valid_593113 != nil:
    section.add "id", valid_593113
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
  var valid_593114 = header.getOrDefault("X-Amz-Signature")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Signature", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Content-Sha256", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Date")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Date", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Credential")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Credential", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Security-Token")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Security-Token", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Algorithm")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Algorithm", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-SignedHeaders", valid_593120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593121: Call_DescribePackagingGroup_593110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_593121.validator(path, query, header, formData, body)
  let scheme = call_593121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593121.url(scheme.get, call_593121.host, call_593121.base,
                         call_593121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593121, url, valid)

proc call*(call_593122: Call_DescribePackagingGroup_593110; id: string): Recallable =
  ## describePackagingGroup
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ##   id: string (required)
  ##     : The ID of a MediaPackage VOD PackagingGroup resource.
  var path_593123 = newJObject()
  add(path_593123, "id", newJString(id))
  result = call_593122.call(path_593123, nil, nil, nil, nil)

var describePackagingGroup* = Call_DescribePackagingGroup_593110(
    name: "describePackagingGroup", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DescribePackagingGroup_593111, base: "/",
    url: url_DescribePackagingGroup_593112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingGroup_593124 = ref object of OpenApiRestCall_592364
proc url_DeletePackagingGroup_593126(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePackagingGroup_593125(path: JsonNode; query: JsonNode;
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
  var valid_593127 = path.getOrDefault("id")
  valid_593127 = validateParameter(valid_593127, JString, required = true,
                                 default = nil)
  if valid_593127 != nil:
    section.add "id", valid_593127
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
  var valid_593128 = header.getOrDefault("X-Amz-Signature")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Signature", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Content-Sha256", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Date")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Date", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Credential")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Credential", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Security-Token")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Security-Token", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Algorithm")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Algorithm", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-SignedHeaders", valid_593134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593135: Call_DeletePackagingGroup_593124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_593135.validator(path, query, header, formData, body)
  let scheme = call_593135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593135.url(scheme.get, call_593135.host, call_593135.base,
                         call_593135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593135, url, valid)

proc call*(call_593136: Call_DeletePackagingGroup_593124; id: string): Recallable =
  ## deletePackagingGroup
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD PackagingGroup resource to delete.
  var path_593137 = newJObject()
  add(path_593137, "id", newJString(id))
  result = call_593136.call(path_593137, nil, nil, nil, nil)

var deletePackagingGroup* = Call_DeletePackagingGroup_593124(
    name: "deletePackagingGroup", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DeletePackagingGroup_593125, base: "/",
    url: url_DeletePackagingGroup_593126, schemes: {Scheme.Https, Scheme.Http})
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
