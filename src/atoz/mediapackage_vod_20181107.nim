
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateAsset_599965 = ref object of OpenApiRestCall_599368
proc url_CreateAsset_599967(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAsset_599966(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599968 = header.getOrDefault("X-Amz-Date")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Date", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Security-Token")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Security-Token", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Content-Sha256", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Algorithm")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Algorithm", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Signature")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Signature", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-SignedHeaders", valid_599973
  var valid_599974 = header.getOrDefault("X-Amz-Credential")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "X-Amz-Credential", valid_599974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599976: Call_CreateAsset_599965; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD Asset resource.
  ## 
  let valid = call_599976.validator(path, query, header, formData, body)
  let scheme = call_599976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599976.url(scheme.get, call_599976.host, call_599976.base,
                         call_599976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599976, url, valid)

proc call*(call_599977: Call_CreateAsset_599965; body: JsonNode): Recallable =
  ## createAsset
  ## Creates a new MediaPackage VOD Asset resource.
  ##   body: JObject (required)
  var body_599978 = newJObject()
  if body != nil:
    body_599978 = body
  result = call_599977.call(nil, nil, nil, nil, body_599978)

var createAsset* = Call_CreateAsset_599965(name: "createAsset",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediapackage-vod.amazonaws.com",
                                        route: "/assets",
                                        validator: validate_CreateAsset_599966,
                                        base: "/", url: url_CreateAsset_599967,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssets_599705 = ref object of OpenApiRestCall_599368
proc url_ListAssets_599707(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssets_599706(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599819 = query.getOrDefault("packagingGroupId")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "packagingGroupId", valid_599819
  var valid_599820 = query.getOrDefault("NextToken")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "NextToken", valid_599820
  var valid_599821 = query.getOrDefault("maxResults")
  valid_599821 = validateParameter(valid_599821, JInt, required = false, default = nil)
  if valid_599821 != nil:
    section.add "maxResults", valid_599821
  var valid_599822 = query.getOrDefault("nextToken")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "nextToken", valid_599822
  var valid_599823 = query.getOrDefault("MaxResults")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "MaxResults", valid_599823
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
  var valid_599824 = header.getOrDefault("X-Amz-Date")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Date", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Security-Token")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Security-Token", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Content-Sha256", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Algorithm")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Algorithm", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-Signature")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-Signature", valid_599828
  var valid_599829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "X-Amz-SignedHeaders", valid_599829
  var valid_599830 = header.getOrDefault("X-Amz-Credential")
  valid_599830 = validateParameter(valid_599830, JString, required = false,
                                 default = nil)
  if valid_599830 != nil:
    section.add "X-Amz-Credential", valid_599830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599853: Call_ListAssets_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD Asset resources.
  ## 
  let valid = call_599853.validator(path, query, header, formData, body)
  let scheme = call_599853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599853.url(scheme.get, call_599853.host, call_599853.base,
                         call_599853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599853, url, valid)

proc call*(call_599924: Call_ListAssets_599705; packagingGroupId: string = "";
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
  var query_599925 = newJObject()
  add(query_599925, "packagingGroupId", newJString(packagingGroupId))
  add(query_599925, "NextToken", newJString(NextToken))
  add(query_599925, "maxResults", newJInt(maxResults))
  add(query_599925, "nextToken", newJString(nextToken))
  add(query_599925, "MaxResults", newJString(MaxResults))
  result = call_599924.call(nil, query_599925, nil, nil, nil)

var listAssets* = Call_ListAssets_599705(name: "listAssets",
                                      meth: HttpMethod.HttpGet,
                                      host: "mediapackage-vod.amazonaws.com",
                                      route: "/assets",
                                      validator: validate_ListAssets_599706,
                                      base: "/", url: url_ListAssets_599707,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingConfiguration_599997 = ref object of OpenApiRestCall_599368
proc url_CreatePackagingConfiguration_599999(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePackagingConfiguration_599998(path: JsonNode; query: JsonNode;
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
  var valid_600000 = header.getOrDefault("X-Amz-Date")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Date", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Security-Token")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Security-Token", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Content-Sha256", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Algorithm")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Algorithm", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Signature")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Signature", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-SignedHeaders", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Credential")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Credential", valid_600006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600008: Call_CreatePackagingConfiguration_599997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_600008.validator(path, query, header, formData, body)
  let scheme = call_600008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600008.url(scheme.get, call_600008.host, call_600008.base,
                         call_600008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600008, url, valid)

proc call*(call_600009: Call_CreatePackagingConfiguration_599997; body: JsonNode): Recallable =
  ## createPackagingConfiguration
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
  ##   body: JObject (required)
  var body_600010 = newJObject()
  if body != nil:
    body_600010 = body
  result = call_600009.call(nil, nil, nil, nil, body_600010)

var createPackagingConfiguration* = Call_CreatePackagingConfiguration_599997(
    name: "createPackagingConfiguration", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_CreatePackagingConfiguration_599998, base: "/",
    url: url_CreatePackagingConfiguration_599999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingConfigurations_599979 = ref object of OpenApiRestCall_599368
proc url_ListPackagingConfigurations_599981(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPackagingConfigurations_599980(path: JsonNode; query: JsonNode;
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
  var valid_599982 = query.getOrDefault("packagingGroupId")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "packagingGroupId", valid_599982
  var valid_599983 = query.getOrDefault("NextToken")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "NextToken", valid_599983
  var valid_599984 = query.getOrDefault("maxResults")
  valid_599984 = validateParameter(valid_599984, JInt, required = false, default = nil)
  if valid_599984 != nil:
    section.add "maxResults", valid_599984
  var valid_599985 = query.getOrDefault("nextToken")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "nextToken", valid_599985
  var valid_599986 = query.getOrDefault("MaxResults")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "MaxResults", valid_599986
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
  var valid_599987 = header.getOrDefault("X-Amz-Date")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Date", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Security-Token")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Security-Token", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Content-Sha256", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Algorithm")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Algorithm", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-Signature")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Signature", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-SignedHeaders", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Credential")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Credential", valid_599993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599994: Call_ListPackagingConfigurations_599979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
  ## 
  let valid = call_599994.validator(path, query, header, formData, body)
  let scheme = call_599994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599994.url(scheme.get, call_599994.host, call_599994.base,
                         call_599994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599994, url, valid)

proc call*(call_599995: Call_ListPackagingConfigurations_599979;
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
  var query_599996 = newJObject()
  add(query_599996, "packagingGroupId", newJString(packagingGroupId))
  add(query_599996, "NextToken", newJString(NextToken))
  add(query_599996, "maxResults", newJInt(maxResults))
  add(query_599996, "nextToken", newJString(nextToken))
  add(query_599996, "MaxResults", newJString(MaxResults))
  result = call_599995.call(nil, query_599996, nil, nil, nil)

var listPackagingConfigurations* = Call_ListPackagingConfigurations_599979(
    name: "listPackagingConfigurations", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_ListPackagingConfigurations_599980, base: "/",
    url: url_ListPackagingConfigurations_599981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingGroup_600028 = ref object of OpenApiRestCall_599368
proc url_CreatePackagingGroup_600030(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePackagingGroup_600029(path: JsonNode; query: JsonNode;
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
  var valid_600031 = header.getOrDefault("X-Amz-Date")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Date", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Security-Token")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Security-Token", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Content-Sha256", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Algorithm")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Algorithm", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Signature")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Signature", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-SignedHeaders", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Credential")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Credential", valid_600037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600039: Call_CreatePackagingGroup_600028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_600039.validator(path, query, header, formData, body)
  let scheme = call_600039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600039.url(scheme.get, call_600039.host, call_600039.base,
                         call_600039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600039, url, valid)

proc call*(call_600040: Call_CreatePackagingGroup_600028; body: JsonNode): Recallable =
  ## createPackagingGroup
  ## Creates a new MediaPackage VOD PackagingGroup resource.
  ##   body: JObject (required)
  var body_600041 = newJObject()
  if body != nil:
    body_600041 = body
  result = call_600040.call(nil, nil, nil, nil, body_600041)

var createPackagingGroup* = Call_CreatePackagingGroup_600028(
    name: "createPackagingGroup", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_CreatePackagingGroup_600029, base: "/",
    url: url_CreatePackagingGroup_600030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingGroups_600011 = ref object of OpenApiRestCall_599368
proc url_ListPackagingGroups_600013(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPackagingGroups_600012(path: JsonNode; query: JsonNode;
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
  var valid_600014 = query.getOrDefault("NextToken")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "NextToken", valid_600014
  var valid_600015 = query.getOrDefault("maxResults")
  valid_600015 = validateParameter(valid_600015, JInt, required = false, default = nil)
  if valid_600015 != nil:
    section.add "maxResults", valid_600015
  var valid_600016 = query.getOrDefault("nextToken")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "nextToken", valid_600016
  var valid_600017 = query.getOrDefault("MaxResults")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "MaxResults", valid_600017
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
  var valid_600018 = header.getOrDefault("X-Amz-Date")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Date", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Security-Token")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Security-Token", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Content-Sha256", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Algorithm")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Algorithm", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Signature")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Signature", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-SignedHeaders", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Credential")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Credential", valid_600024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600025: Call_ListPackagingGroups_600011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
  ## 
  let valid = call_600025.validator(path, query, header, formData, body)
  let scheme = call_600025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600025.url(scheme.get, call_600025.host, call_600025.base,
                         call_600025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600025, url, valid)

proc call*(call_600026: Call_ListPackagingGroups_600011; NextToken: string = "";
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
  var query_600027 = newJObject()
  add(query_600027, "NextToken", newJString(NextToken))
  add(query_600027, "maxResults", newJInt(maxResults))
  add(query_600027, "nextToken", newJString(nextToken))
  add(query_600027, "MaxResults", newJString(MaxResults))
  result = call_600026.call(nil, query_600027, nil, nil, nil)

var listPackagingGroups* = Call_ListPackagingGroups_600011(
    name: "listPackagingGroups", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_ListPackagingGroups_600012, base: "/",
    url: url_ListPackagingGroups_600013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAsset_600042 = ref object of OpenApiRestCall_599368
proc url_DescribeAsset_600044(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeAsset_600043(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600059 = path.getOrDefault("id")
  valid_600059 = validateParameter(valid_600059, JString, required = true,
                                 default = nil)
  if valid_600059 != nil:
    section.add "id", valid_600059
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
  var valid_600060 = header.getOrDefault("X-Amz-Date")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Date", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-Security-Token")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Security-Token", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Content-Sha256", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Algorithm")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Algorithm", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Signature")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Signature", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-SignedHeaders", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Credential")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Credential", valid_600066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600067: Call_DescribeAsset_600042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD Asset resource.
  ## 
  let valid = call_600067.validator(path, query, header, formData, body)
  let scheme = call_600067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600067.url(scheme.get, call_600067.host, call_600067.base,
                         call_600067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600067, url, valid)

proc call*(call_600068: Call_DescribeAsset_600042; id: string): Recallable =
  ## describeAsset
  ## Returns a description of a MediaPackage VOD Asset resource.
  ##   id: string (required)
  ##     : The ID of an MediaPackage VOD Asset resource.
  var path_600069 = newJObject()
  add(path_600069, "id", newJString(id))
  result = call_600068.call(path_600069, nil, nil, nil, nil)

var describeAsset* = Call_DescribeAsset_600042(name: "describeAsset",
    meth: HttpMethod.HttpGet, host: "mediapackage-vod.amazonaws.com",
    route: "/assets/{id}", validator: validate_DescribeAsset_600043, base: "/",
    url: url_DescribeAsset_600044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_600070 = ref object of OpenApiRestCall_599368
proc url_DeleteAsset_600072(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAsset_600071(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600073 = path.getOrDefault("id")
  valid_600073 = validateParameter(valid_600073, JString, required = true,
                                 default = nil)
  if valid_600073 != nil:
    section.add "id", valid_600073
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
  var valid_600074 = header.getOrDefault("X-Amz-Date")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Date", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Security-Token")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Security-Token", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Content-Sha256", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Algorithm")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Algorithm", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Signature")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Signature", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-SignedHeaders", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Credential")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Credential", valid_600080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600081: Call_DeleteAsset_600070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing MediaPackage VOD Asset resource.
  ## 
  let valid = call_600081.validator(path, query, header, formData, body)
  let scheme = call_600081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600081.url(scheme.get, call_600081.host, call_600081.base,
                         call_600081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600081, url, valid)

proc call*(call_600082: Call_DeleteAsset_600070; id: string): Recallable =
  ## deleteAsset
  ## Deletes an existing MediaPackage VOD Asset resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD Asset resource to delete.
  var path_600083 = newJObject()
  add(path_600083, "id", newJString(id))
  result = call_600082.call(path_600083, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_600070(name: "deleteAsset",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediapackage-vod.amazonaws.com",
                                        route: "/assets/{id}",
                                        validator: validate_DeleteAsset_600071,
                                        base: "/", url: url_DeleteAsset_600072,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingConfiguration_600084 = ref object of OpenApiRestCall_599368
proc url_DescribePackagingConfiguration_600086(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribePackagingConfiguration_600085(path: JsonNode;
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
  var valid_600087 = path.getOrDefault("id")
  valid_600087 = validateParameter(valid_600087, JString, required = true,
                                 default = nil)
  if valid_600087 != nil:
    section.add "id", valid_600087
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
  var valid_600088 = header.getOrDefault("X-Amz-Date")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Date", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Security-Token")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Security-Token", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Content-Sha256", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Algorithm")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Algorithm", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Signature")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Signature", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-SignedHeaders", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-Credential")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Credential", valid_600094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600095: Call_DescribePackagingConfiguration_600084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_600095.validator(path, query, header, formData, body)
  let scheme = call_600095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600095.url(scheme.get, call_600095.host, call_600095.base,
                         call_600095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600095, url, valid)

proc call*(call_600096: Call_DescribePackagingConfiguration_600084; id: string): Recallable =
  ## describePackagingConfiguration
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ##   id: string (required)
  ##     : The ID of a MediaPackage VOD PackagingConfiguration resource.
  var path_600097 = newJObject()
  add(path_600097, "id", newJString(id))
  result = call_600096.call(path_600097, nil, nil, nil, nil)

var describePackagingConfiguration* = Call_DescribePackagingConfiguration_600084(
    name: "describePackagingConfiguration", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DescribePackagingConfiguration_600085, base: "/",
    url: url_DescribePackagingConfiguration_600086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingConfiguration_600098 = ref object of OpenApiRestCall_599368
proc url_DeletePackagingConfiguration_600100(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePackagingConfiguration_600099(path: JsonNode; query: JsonNode;
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
  var valid_600101 = path.getOrDefault("id")
  valid_600101 = validateParameter(valid_600101, JString, required = true,
                                 default = nil)
  if valid_600101 != nil:
    section.add "id", valid_600101
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
  var valid_600102 = header.getOrDefault("X-Amz-Date")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Date", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Security-Token")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Security-Token", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Content-Sha256", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Algorithm")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Algorithm", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Signature")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Signature", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-SignedHeaders", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Credential")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Credential", valid_600108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600109: Call_DeletePackagingConfiguration_600098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_600109.validator(path, query, header, formData, body)
  let scheme = call_600109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600109.url(scheme.get, call_600109.host, call_600109.base,
                         call_600109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600109, url, valid)

proc call*(call_600110: Call_DeletePackagingConfiguration_600098; id: string): Recallable =
  ## deletePackagingConfiguration
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD PackagingConfiguration resource to delete.
  var path_600111 = newJObject()
  add(path_600111, "id", newJString(id))
  result = call_600110.call(path_600111, nil, nil, nil, nil)

var deletePackagingConfiguration* = Call_DeletePackagingConfiguration_600098(
    name: "deletePackagingConfiguration", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DeletePackagingConfiguration_600099, base: "/",
    url: url_DeletePackagingConfiguration_600100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingGroup_600112 = ref object of OpenApiRestCall_599368
proc url_DescribePackagingGroup_600114(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribePackagingGroup_600113(path: JsonNode; query: JsonNode;
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
  var valid_600115 = path.getOrDefault("id")
  valid_600115 = validateParameter(valid_600115, JString, required = true,
                                 default = nil)
  if valid_600115 != nil:
    section.add "id", valid_600115
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
  var valid_600116 = header.getOrDefault("X-Amz-Date")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Date", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Security-Token")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Security-Token", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Content-Sha256", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Algorithm")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Algorithm", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Signature")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Signature", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-SignedHeaders", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Credential")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Credential", valid_600122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600123: Call_DescribePackagingGroup_600112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_600123.validator(path, query, header, formData, body)
  let scheme = call_600123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600123.url(scheme.get, call_600123.host, call_600123.base,
                         call_600123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600123, url, valid)

proc call*(call_600124: Call_DescribePackagingGroup_600112; id: string): Recallable =
  ## describePackagingGroup
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ##   id: string (required)
  ##     : The ID of a MediaPackage VOD PackagingGroup resource.
  var path_600125 = newJObject()
  add(path_600125, "id", newJString(id))
  result = call_600124.call(path_600125, nil, nil, nil, nil)

var describePackagingGroup* = Call_DescribePackagingGroup_600112(
    name: "describePackagingGroup", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DescribePackagingGroup_600113, base: "/",
    url: url_DescribePackagingGroup_600114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingGroup_600126 = ref object of OpenApiRestCall_599368
proc url_DeletePackagingGroup_600128(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePackagingGroup_600127(path: JsonNode; query: JsonNode;
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
  var valid_600129 = path.getOrDefault("id")
  valid_600129 = validateParameter(valid_600129, JString, required = true,
                                 default = nil)
  if valid_600129 != nil:
    section.add "id", valid_600129
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
  var valid_600130 = header.getOrDefault("X-Amz-Date")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Date", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Security-Token")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Security-Token", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Content-Sha256", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Algorithm")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Algorithm", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Signature")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Signature", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-SignedHeaders", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-Credential")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Credential", valid_600136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600137: Call_DeletePackagingGroup_600126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_600137.validator(path, query, header, formData, body)
  let scheme = call_600137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600137.url(scheme.get, call_600137.host, call_600137.base,
                         call_600137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600137, url, valid)

proc call*(call_600138: Call_DeletePackagingGroup_600126; id: string): Recallable =
  ## deletePackagingGroup
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD PackagingGroup resource to delete.
  var path_600139 = newJObject()
  add(path_600139, "id", newJString(id))
  result = call_600138.call(path_600139, nil, nil, nil, nil)

var deletePackagingGroup* = Call_DeletePackagingGroup_600126(
    name: "deletePackagingGroup", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DeletePackagingGroup_600127, base: "/",
    url: url_DeletePackagingGroup_600128, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
