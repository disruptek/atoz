
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_CreateAsset_613256 = ref object of OpenApiRestCall_612658
proc url_CreateAsset_613258(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAsset_613257(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613259 = header.getOrDefault("X-Amz-Signature")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Signature", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Content-Sha256", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Date")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Date", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Credential")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Credential", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Security-Token")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Security-Token", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-Algorithm")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-Algorithm", valid_613264
  var valid_613265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613265 = validateParameter(valid_613265, JString, required = false,
                                 default = nil)
  if valid_613265 != nil:
    section.add "X-Amz-SignedHeaders", valid_613265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613267: Call_CreateAsset_613256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD Asset resource.
  ## 
  let valid = call_613267.validator(path, query, header, formData, body)
  let scheme = call_613267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613267.url(scheme.get, call_613267.host, call_613267.base,
                         call_613267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613267, url, valid)

proc call*(call_613268: Call_CreateAsset_613256; body: JsonNode): Recallable =
  ## createAsset
  ## Creates a new MediaPackage VOD Asset resource.
  ##   body: JObject (required)
  var body_613269 = newJObject()
  if body != nil:
    body_613269 = body
  result = call_613268.call(nil, nil, nil, nil, body_613269)

var createAsset* = Call_CreateAsset_613256(name: "createAsset",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediapackage-vod.amazonaws.com",
                                        route: "/assets",
                                        validator: validate_CreateAsset_613257,
                                        base: "/", url: url_CreateAsset_613258,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssets_612996 = ref object of OpenApiRestCall_612658
proc url_ListAssets_612998(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssets_612997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613110 = query.getOrDefault("nextToken")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "nextToken", valid_613110
  var valid_613111 = query.getOrDefault("MaxResults")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "MaxResults", valid_613111
  var valid_613112 = query.getOrDefault("NextToken")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "NextToken", valid_613112
  var valid_613113 = query.getOrDefault("packagingGroupId")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "packagingGroupId", valid_613113
  var valid_613114 = query.getOrDefault("maxResults")
  valid_613114 = validateParameter(valid_613114, JInt, required = false, default = nil)
  if valid_613114 != nil:
    section.add "maxResults", valid_613114
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
  var valid_613115 = header.getOrDefault("X-Amz-Signature")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Signature", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Content-Sha256", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Date")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Date", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-Credential")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-Credential", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Security-Token")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Security-Token", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Algorithm")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Algorithm", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-SignedHeaders", valid_613121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613144: Call_ListAssets_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD Asset resources.
  ## 
  let valid = call_613144.validator(path, query, header, formData, body)
  let scheme = call_613144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613144.url(scheme.get, call_613144.host, call_613144.base,
                         call_613144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613144, url, valid)

proc call*(call_613215: Call_ListAssets_612996; nextToken: string = "";
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
  var query_613216 = newJObject()
  add(query_613216, "nextToken", newJString(nextToken))
  add(query_613216, "MaxResults", newJString(MaxResults))
  add(query_613216, "NextToken", newJString(NextToken))
  add(query_613216, "packagingGroupId", newJString(packagingGroupId))
  add(query_613216, "maxResults", newJInt(maxResults))
  result = call_613215.call(nil, query_613216, nil, nil, nil)

var listAssets* = Call_ListAssets_612996(name: "listAssets",
                                      meth: HttpMethod.HttpGet,
                                      host: "mediapackage-vod.amazonaws.com",
                                      route: "/assets",
                                      validator: validate_ListAssets_612997,
                                      base: "/", url: url_ListAssets_612998,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingConfiguration_613288 = ref object of OpenApiRestCall_612658
proc url_CreatePackagingConfiguration_613290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePackagingConfiguration_613289(path: JsonNode; query: JsonNode;
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
  var valid_613291 = header.getOrDefault("X-Amz-Signature")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Signature", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Content-Sha256", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Date")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Date", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Credential")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Credential", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Security-Token")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Security-Token", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Algorithm")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Algorithm", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-SignedHeaders", valid_613297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613299: Call_CreatePackagingConfiguration_613288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_613299.validator(path, query, header, formData, body)
  let scheme = call_613299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613299.url(scheme.get, call_613299.host, call_613299.base,
                         call_613299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613299, url, valid)

proc call*(call_613300: Call_CreatePackagingConfiguration_613288; body: JsonNode): Recallable =
  ## createPackagingConfiguration
  ## Creates a new MediaPackage VOD PackagingConfiguration resource.
  ##   body: JObject (required)
  var body_613301 = newJObject()
  if body != nil:
    body_613301 = body
  result = call_613300.call(nil, nil, nil, nil, body_613301)

var createPackagingConfiguration* = Call_CreatePackagingConfiguration_613288(
    name: "createPackagingConfiguration", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_CreatePackagingConfiguration_613289, base: "/",
    url: url_CreatePackagingConfiguration_613290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingConfigurations_613270 = ref object of OpenApiRestCall_612658
proc url_ListPackagingConfigurations_613272(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPackagingConfigurations_613271(path: JsonNode; query: JsonNode;
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
  var valid_613273 = query.getOrDefault("nextToken")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "nextToken", valid_613273
  var valid_613274 = query.getOrDefault("MaxResults")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "MaxResults", valid_613274
  var valid_613275 = query.getOrDefault("NextToken")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "NextToken", valid_613275
  var valid_613276 = query.getOrDefault("packagingGroupId")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "packagingGroupId", valid_613276
  var valid_613277 = query.getOrDefault("maxResults")
  valid_613277 = validateParameter(valid_613277, JInt, required = false, default = nil)
  if valid_613277 != nil:
    section.add "maxResults", valid_613277
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
  var valid_613278 = header.getOrDefault("X-Amz-Signature")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Signature", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Content-Sha256", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Date")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Date", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-Credential")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-Credential", valid_613281
  var valid_613282 = header.getOrDefault("X-Amz-Security-Token")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Security-Token", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Algorithm")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Algorithm", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-SignedHeaders", valid_613284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613285: Call_ListPackagingConfigurations_613270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingConfiguration resources.
  ## 
  let valid = call_613285.validator(path, query, header, formData, body)
  let scheme = call_613285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613285.url(scheme.get, call_613285.host, call_613285.base,
                         call_613285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613285, url, valid)

proc call*(call_613286: Call_ListPackagingConfigurations_613270;
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
  var query_613287 = newJObject()
  add(query_613287, "nextToken", newJString(nextToken))
  add(query_613287, "MaxResults", newJString(MaxResults))
  add(query_613287, "NextToken", newJString(NextToken))
  add(query_613287, "packagingGroupId", newJString(packagingGroupId))
  add(query_613287, "maxResults", newJInt(maxResults))
  result = call_613286.call(nil, query_613287, nil, nil, nil)

var listPackagingConfigurations* = Call_ListPackagingConfigurations_613270(
    name: "listPackagingConfigurations", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_configurations",
    validator: validate_ListPackagingConfigurations_613271, base: "/",
    url: url_ListPackagingConfigurations_613272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePackagingGroup_613319 = ref object of OpenApiRestCall_612658
proc url_CreatePackagingGroup_613321(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePackagingGroup_613320(path: JsonNode; query: JsonNode;
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
  var valid_613322 = header.getOrDefault("X-Amz-Signature")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Signature", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Content-Sha256", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Date")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Date", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Credential")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Credential", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Security-Token")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Security-Token", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Algorithm")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Algorithm", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-SignedHeaders", valid_613328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613330: Call_CreatePackagingGroup_613319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_613330.validator(path, query, header, formData, body)
  let scheme = call_613330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613330.url(scheme.get, call_613330.host, call_613330.base,
                         call_613330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613330, url, valid)

proc call*(call_613331: Call_CreatePackagingGroup_613319; body: JsonNode): Recallable =
  ## createPackagingGroup
  ## Creates a new MediaPackage VOD PackagingGroup resource.
  ##   body: JObject (required)
  var body_613332 = newJObject()
  if body != nil:
    body_613332 = body
  result = call_613331.call(nil, nil, nil, nil, body_613332)

var createPackagingGroup* = Call_CreatePackagingGroup_613319(
    name: "createPackagingGroup", meth: HttpMethod.HttpPost,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_CreatePackagingGroup_613320, base: "/",
    url: url_CreatePackagingGroup_613321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPackagingGroups_613302 = ref object of OpenApiRestCall_612658
proc url_ListPackagingGroups_613304(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPackagingGroups_613303(path: JsonNode; query: JsonNode;
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
  var valid_613305 = query.getOrDefault("nextToken")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "nextToken", valid_613305
  var valid_613306 = query.getOrDefault("MaxResults")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "MaxResults", valid_613306
  var valid_613307 = query.getOrDefault("NextToken")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "NextToken", valid_613307
  var valid_613308 = query.getOrDefault("maxResults")
  valid_613308 = validateParameter(valid_613308, JInt, required = false, default = nil)
  if valid_613308 != nil:
    section.add "maxResults", valid_613308
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
  var valid_613309 = header.getOrDefault("X-Amz-Signature")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Signature", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Content-Sha256", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Date")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Date", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Credential")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Credential", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Security-Token")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Security-Token", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Algorithm")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Algorithm", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-SignedHeaders", valid_613315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613316: Call_ListPackagingGroups_613302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of MediaPackage VOD PackagingGroup resources.
  ## 
  let valid = call_613316.validator(path, query, header, formData, body)
  let scheme = call_613316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613316.url(scheme.get, call_613316.host, call_613316.base,
                         call_613316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613316, url, valid)

proc call*(call_613317: Call_ListPackagingGroups_613302; nextToken: string = "";
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
  var query_613318 = newJObject()
  add(query_613318, "nextToken", newJString(nextToken))
  add(query_613318, "MaxResults", newJString(MaxResults))
  add(query_613318, "NextToken", newJString(NextToken))
  add(query_613318, "maxResults", newJInt(maxResults))
  result = call_613317.call(nil, query_613318, nil, nil, nil)

var listPackagingGroups* = Call_ListPackagingGroups_613302(
    name: "listPackagingGroups", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups",
    validator: validate_ListPackagingGroups_613303, base: "/",
    url: url_ListPackagingGroups_613304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAsset_613333 = ref object of OpenApiRestCall_612658
proc url_DescribeAsset_613335(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAsset_613334(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613350 = path.getOrDefault("id")
  valid_613350 = validateParameter(valid_613350, JString, required = true,
                                 default = nil)
  if valid_613350 != nil:
    section.add "id", valid_613350
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
  var valid_613351 = header.getOrDefault("X-Amz-Signature")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Signature", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Content-Sha256", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Date")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Date", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Credential")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Credential", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Security-Token")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Security-Token", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Algorithm")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Algorithm", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-SignedHeaders", valid_613357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613358: Call_DescribeAsset_613333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD Asset resource.
  ## 
  let valid = call_613358.validator(path, query, header, formData, body)
  let scheme = call_613358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613358.url(scheme.get, call_613358.host, call_613358.base,
                         call_613358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613358, url, valid)

proc call*(call_613359: Call_DescribeAsset_613333; id: string): Recallable =
  ## describeAsset
  ## Returns a description of a MediaPackage VOD Asset resource.
  ##   id: string (required)
  ##     : The ID of an MediaPackage VOD Asset resource.
  var path_613360 = newJObject()
  add(path_613360, "id", newJString(id))
  result = call_613359.call(path_613360, nil, nil, nil, nil)

var describeAsset* = Call_DescribeAsset_613333(name: "describeAsset",
    meth: HttpMethod.HttpGet, host: "mediapackage-vod.amazonaws.com",
    route: "/assets/{id}", validator: validate_DescribeAsset_613334, base: "/",
    url: url_DescribeAsset_613335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_613361 = ref object of OpenApiRestCall_612658
proc url_DeleteAsset_613363(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAsset_613362(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613364 = path.getOrDefault("id")
  valid_613364 = validateParameter(valid_613364, JString, required = true,
                                 default = nil)
  if valid_613364 != nil:
    section.add "id", valid_613364
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
  var valid_613365 = header.getOrDefault("X-Amz-Signature")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Signature", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Content-Sha256", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Date")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Date", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Credential")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Credential", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Security-Token")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Security-Token", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Algorithm")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Algorithm", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-SignedHeaders", valid_613371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613372: Call_DeleteAsset_613361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing MediaPackage VOD Asset resource.
  ## 
  let valid = call_613372.validator(path, query, header, formData, body)
  let scheme = call_613372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613372.url(scheme.get, call_613372.host, call_613372.base,
                         call_613372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613372, url, valid)

proc call*(call_613373: Call_DeleteAsset_613361; id: string): Recallable =
  ## deleteAsset
  ## Deletes an existing MediaPackage VOD Asset resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD Asset resource to delete.
  var path_613374 = newJObject()
  add(path_613374, "id", newJString(id))
  result = call_613373.call(path_613374, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_613361(name: "deleteAsset",
                                        meth: HttpMethod.HttpDelete,
                                        host: "mediapackage-vod.amazonaws.com",
                                        route: "/assets/{id}",
                                        validator: validate_DeleteAsset_613362,
                                        base: "/", url: url_DeleteAsset_613363,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingConfiguration_613375 = ref object of OpenApiRestCall_612658
proc url_DescribePackagingConfiguration_613377(protocol: Scheme; host: string;
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

proc validate_DescribePackagingConfiguration_613376(path: JsonNode;
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
  var valid_613378 = path.getOrDefault("id")
  valid_613378 = validateParameter(valid_613378, JString, required = true,
                                 default = nil)
  if valid_613378 != nil:
    section.add "id", valid_613378
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
  var valid_613379 = header.getOrDefault("X-Amz-Signature")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Signature", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Content-Sha256", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Date")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Date", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Credential")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Credential", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Security-Token")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Security-Token", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Algorithm")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Algorithm", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-SignedHeaders", valid_613385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613386: Call_DescribePackagingConfiguration_613375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_613386.validator(path, query, header, formData, body)
  let scheme = call_613386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613386.url(scheme.get, call_613386.host, call_613386.base,
                         call_613386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613386, url, valid)

proc call*(call_613387: Call_DescribePackagingConfiguration_613375; id: string): Recallable =
  ## describePackagingConfiguration
  ## Returns a description of a MediaPackage VOD PackagingConfiguration resource.
  ##   id: string (required)
  ##     : The ID of a MediaPackage VOD PackagingConfiguration resource.
  var path_613388 = newJObject()
  add(path_613388, "id", newJString(id))
  result = call_613387.call(path_613388, nil, nil, nil, nil)

var describePackagingConfiguration* = Call_DescribePackagingConfiguration_613375(
    name: "describePackagingConfiguration", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DescribePackagingConfiguration_613376, base: "/",
    url: url_DescribePackagingConfiguration_613377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingConfiguration_613389 = ref object of OpenApiRestCall_612658
proc url_DeletePackagingConfiguration_613391(protocol: Scheme; host: string;
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

proc validate_DeletePackagingConfiguration_613390(path: JsonNode; query: JsonNode;
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
  var valid_613392 = path.getOrDefault("id")
  valid_613392 = validateParameter(valid_613392, JString, required = true,
                                 default = nil)
  if valid_613392 != nil:
    section.add "id", valid_613392
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
  var valid_613393 = header.getOrDefault("X-Amz-Signature")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Signature", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Content-Sha256", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Date")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Date", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Credential")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Credential", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Security-Token")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Security-Token", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-Algorithm")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Algorithm", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-SignedHeaders", valid_613399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613400: Call_DeletePackagingConfiguration_613389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ## 
  let valid = call_613400.validator(path, query, header, formData, body)
  let scheme = call_613400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613400.url(scheme.get, call_613400.host, call_613400.base,
                         call_613400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613400, url, valid)

proc call*(call_613401: Call_DeletePackagingConfiguration_613389; id: string): Recallable =
  ## deletePackagingConfiguration
  ## Deletes a MediaPackage VOD PackagingConfiguration resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD PackagingConfiguration resource to delete.
  var path_613402 = newJObject()
  add(path_613402, "id", newJString(id))
  result = call_613401.call(path_613402, nil, nil, nil, nil)

var deletePackagingConfiguration* = Call_DeletePackagingConfiguration_613389(
    name: "deletePackagingConfiguration", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com",
    route: "/packaging_configurations/{id}",
    validator: validate_DeletePackagingConfiguration_613390, base: "/",
    url: url_DeletePackagingConfiguration_613391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePackagingGroup_613403 = ref object of OpenApiRestCall_612658
proc url_DescribePackagingGroup_613405(protocol: Scheme; host: string; base: string;
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

proc validate_DescribePackagingGroup_613404(path: JsonNode; query: JsonNode;
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
  var valid_613406 = path.getOrDefault("id")
  valid_613406 = validateParameter(valid_613406, JString, required = true,
                                 default = nil)
  if valid_613406 != nil:
    section.add "id", valid_613406
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
  var valid_613407 = header.getOrDefault("X-Amz-Signature")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Signature", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Content-Sha256", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Date")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Date", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Credential")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Credential", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Security-Token")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Security-Token", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Algorithm")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Algorithm", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-SignedHeaders", valid_613413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613414: Call_DescribePackagingGroup_613403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_613414.validator(path, query, header, formData, body)
  let scheme = call_613414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613414.url(scheme.get, call_613414.host, call_613414.base,
                         call_613414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613414, url, valid)

proc call*(call_613415: Call_DescribePackagingGroup_613403; id: string): Recallable =
  ## describePackagingGroup
  ## Returns a description of a MediaPackage VOD PackagingGroup resource.
  ##   id: string (required)
  ##     : The ID of a MediaPackage VOD PackagingGroup resource.
  var path_613416 = newJObject()
  add(path_613416, "id", newJString(id))
  result = call_613415.call(path_613416, nil, nil, nil, nil)

var describePackagingGroup* = Call_DescribePackagingGroup_613403(
    name: "describePackagingGroup", meth: HttpMethod.HttpGet,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DescribePackagingGroup_613404, base: "/",
    url: url_DescribePackagingGroup_613405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePackagingGroup_613417 = ref object of OpenApiRestCall_612658
proc url_DeletePackagingGroup_613419(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePackagingGroup_613418(path: JsonNode; query: JsonNode;
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
  var valid_613420 = path.getOrDefault("id")
  valid_613420 = validateParameter(valid_613420, JString, required = true,
                                 default = nil)
  if valid_613420 != nil:
    section.add "id", valid_613420
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
  var valid_613421 = header.getOrDefault("X-Amz-Signature")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Signature", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Content-Sha256", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Date")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Date", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Credential")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Credential", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Security-Token")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Security-Token", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Algorithm")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Algorithm", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-SignedHeaders", valid_613427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613428: Call_DeletePackagingGroup_613417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ## 
  let valid = call_613428.validator(path, query, header, formData, body)
  let scheme = call_613428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613428.url(scheme.get, call_613428.host, call_613428.base,
                         call_613428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613428, url, valid)

proc call*(call_613429: Call_DeletePackagingGroup_613417; id: string): Recallable =
  ## deletePackagingGroup
  ## Deletes a MediaPackage VOD PackagingGroup resource.
  ##   id: string (required)
  ##     : The ID of the MediaPackage VOD PackagingGroup resource to delete.
  var path_613430 = newJObject()
  add(path_613430, "id", newJString(id))
  result = call_613429.call(path_613430, nil, nil, nil, nil)

var deletePackagingGroup* = Call_DeletePackagingGroup_613417(
    name: "deletePackagingGroup", meth: HttpMethod.HttpDelete,
    host: "mediapackage-vod.amazonaws.com", route: "/packaging_groups/{id}",
    validator: validate_DeletePackagingGroup_613418, base: "/",
    url: url_DeletePackagingGroup_613419, schemes: {Scheme.Https, Scheme.Http})
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
