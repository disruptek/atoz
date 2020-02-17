
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elastic  Inference
## version: 2017-07-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Elastic Inference public APIs.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/elastic-inference/
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

  OpenApiRestCall_610649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610649): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.elastic-inference.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.elastic-inference.ap-southeast-1.amazonaws.com", "us-west-2": "api.elastic-inference.us-west-2.amazonaws.com", "eu-west-2": "api.elastic-inference.eu-west-2.amazonaws.com", "ap-northeast-3": "api.elastic-inference.ap-northeast-3.amazonaws.com", "eu-central-1": "api.elastic-inference.eu-central-1.amazonaws.com", "us-east-2": "api.elastic-inference.us-east-2.amazonaws.com", "us-east-1": "api.elastic-inference.us-east-1.amazonaws.com", "cn-northwest-1": "api.elastic-inference.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.elastic-inference.ap-south-1.amazonaws.com", "eu-north-1": "api.elastic-inference.eu-north-1.amazonaws.com", "ap-northeast-2": "api.elastic-inference.ap-northeast-2.amazonaws.com", "us-west-1": "api.elastic-inference.us-west-1.amazonaws.com", "us-gov-east-1": "api.elastic-inference.us-gov-east-1.amazonaws.com", "eu-west-3": "api.elastic-inference.eu-west-3.amazonaws.com", "cn-north-1": "api.elastic-inference.cn-north-1.amazonaws.com.cn", "sa-east-1": "api.elastic-inference.sa-east-1.amazonaws.com", "eu-west-1": "api.elastic-inference.eu-west-1.amazonaws.com", "us-gov-west-1": "api.elastic-inference.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.elastic-inference.ap-southeast-2.amazonaws.com", "ca-central-1": "api.elastic-inference.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "api.elastic-inference.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.elastic-inference.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.elastic-inference.us-west-2.amazonaws.com",
      "eu-west-2": "api.elastic-inference.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.elastic-inference.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.elastic-inference.eu-central-1.amazonaws.com",
      "us-east-2": "api.elastic-inference.us-east-2.amazonaws.com",
      "us-east-1": "api.elastic-inference.us-east-1.amazonaws.com", "cn-northwest-1": "api.elastic-inference.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.elastic-inference.ap-south-1.amazonaws.com",
      "eu-north-1": "api.elastic-inference.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.elastic-inference.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.elastic-inference.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.elastic-inference.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.elastic-inference.eu-west-3.amazonaws.com",
      "cn-north-1": "api.elastic-inference.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.elastic-inference.sa-east-1.amazonaws.com",
      "eu-west-1": "api.elastic-inference.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.elastic-inference.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.elastic-inference.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.elastic-inference.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "elastic-inference"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_TagResource_611257 = ref object of OpenApiRestCall_610649
proc url_TagResource_611259(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_611258(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the Elastic Inference Accelerator to tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611260 = path.getOrDefault("resourceArn")
  valid_611260 = validateParameter(valid_611260, JString, required = true,
                                 default = nil)
  if valid_611260 != nil:
    section.add "resourceArn", valid_611260
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
  var valid_611261 = header.getOrDefault("X-Amz-Signature")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Signature", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-Content-Sha256", valid_611262
  var valid_611263 = header.getOrDefault("X-Amz-Date")
  valid_611263 = validateParameter(valid_611263, JString, required = false,
                                 default = nil)
  if valid_611263 != nil:
    section.add "X-Amz-Date", valid_611263
  var valid_611264 = header.getOrDefault("X-Amz-Credential")
  valid_611264 = validateParameter(valid_611264, JString, required = false,
                                 default = nil)
  if valid_611264 != nil:
    section.add "X-Amz-Credential", valid_611264
  var valid_611265 = header.getOrDefault("X-Amz-Security-Token")
  valid_611265 = validateParameter(valid_611265, JString, required = false,
                                 default = nil)
  if valid_611265 != nil:
    section.add "X-Amz-Security-Token", valid_611265
  var valid_611266 = header.getOrDefault("X-Amz-Algorithm")
  valid_611266 = validateParameter(valid_611266, JString, required = false,
                                 default = nil)
  if valid_611266 != nil:
    section.add "X-Amz-Algorithm", valid_611266
  var valid_611267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611267 = validateParameter(valid_611267, JString, required = false,
                                 default = nil)
  if valid_611267 != nil:
    section.add "X-Amz-SignedHeaders", valid_611267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611269: Call_TagResource_611257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ## 
  let valid = call_611269.validator(path, query, header, formData, body)
  let scheme = call_611269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611269.url(scheme.get, call_611269.host, call_611269.base,
                         call_611269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611269, url, valid)

proc call*(call_611270: Call_TagResource_611257; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to tag.
  ##   body: JObject (required)
  var path_611271 = newJObject()
  var body_611272 = newJObject()
  add(path_611271, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_611272 = body
  result = call_611270.call(path_611271, nil, nil, nil, body_611272)

var tagResource* = Call_TagResource_611257(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "api.elastic-inference.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_611258,
                                        base: "/", url: url_TagResource_611259,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_610987 = ref object of OpenApiRestCall_610649
proc url_ListTagsForResource_610989(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_610988(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns all tags of an Elastic Inference Accelerator.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the Elastic Inference Accelerator to list the tags for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611115 = path.getOrDefault("resourceArn")
  valid_611115 = validateParameter(valid_611115, JString, required = true,
                                 default = nil)
  if valid_611115 != nil:
    section.add "resourceArn", valid_611115
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
  var valid_611116 = header.getOrDefault("X-Amz-Signature")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Signature", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Content-Sha256", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-Date")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-Date", valid_611118
  var valid_611119 = header.getOrDefault("X-Amz-Credential")
  valid_611119 = validateParameter(valid_611119, JString, required = false,
                                 default = nil)
  if valid_611119 != nil:
    section.add "X-Amz-Credential", valid_611119
  var valid_611120 = header.getOrDefault("X-Amz-Security-Token")
  valid_611120 = validateParameter(valid_611120, JString, required = false,
                                 default = nil)
  if valid_611120 != nil:
    section.add "X-Amz-Security-Token", valid_611120
  var valid_611121 = header.getOrDefault("X-Amz-Algorithm")
  valid_611121 = validateParameter(valid_611121, JString, required = false,
                                 default = nil)
  if valid_611121 != nil:
    section.add "X-Amz-Algorithm", valid_611121
  var valid_611122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611122 = validateParameter(valid_611122, JString, required = false,
                                 default = nil)
  if valid_611122 != nil:
    section.add "X-Amz-SignedHeaders", valid_611122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611145: Call_ListTagsForResource_610987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags of an Elastic Inference Accelerator.
  ## 
  let valid = call_611145.validator(path, query, header, formData, body)
  let scheme = call_611145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611145.url(scheme.get, call_611145.host, call_611145.base,
                         call_611145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611145, url, valid)

proc call*(call_611216: Call_ListTagsForResource_610987; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns all tags of an Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to list the tags for.
  var path_611217 = newJObject()
  add(path_611217, "resourceArn", newJString(resourceArn))
  result = call_611216.call(path_611217, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_610987(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "api.elastic-inference.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_610988, base: "/",
    url: url_ListTagsForResource_610989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611273 = ref object of OpenApiRestCall_610649
proc url_UntagResource_611275(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_611274(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the Elastic Inference Accelerator to untag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611276 = path.getOrDefault("resourceArn")
  valid_611276 = validateParameter(valid_611276, JString, required = true,
                                 default = nil)
  if valid_611276 != nil:
    section.add "resourceArn", valid_611276
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The list of tags to remove from the Elastic Inference Accelerator.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611277 = query.getOrDefault("tagKeys")
  valid_611277 = validateParameter(valid_611277, JArray, required = true, default = nil)
  if valid_611277 != nil:
    section.add "tagKeys", valid_611277
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
  var valid_611278 = header.getOrDefault("X-Amz-Signature")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Signature", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Content-Sha256", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-Date")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Date", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-Credential")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-Credential", valid_611281
  var valid_611282 = header.getOrDefault("X-Amz-Security-Token")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-Security-Token", valid_611282
  var valid_611283 = header.getOrDefault("X-Amz-Algorithm")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-Algorithm", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-SignedHeaders", valid_611284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611285: Call_UntagResource_611273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ## 
  let valid = call_611285.validator(path, query, header, formData, body)
  let scheme = call_611285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611285.url(scheme.get, call_611285.host, call_611285.base,
                         call_611285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611285, url, valid)

proc call*(call_611286: Call_UntagResource_611273; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to untag.
  ##   tagKeys: JArray (required)
  ##          : The list of tags to remove from the Elastic Inference Accelerator.
  var path_611287 = newJObject()
  var query_611288 = newJObject()
  add(path_611287, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_611288.add "tagKeys", tagKeys
  result = call_611286.call(path_611287, query_611288, nil, nil, nil)

var untagResource* = Call_UntagResource_611273(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "api.elastic-inference.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_611274,
    base: "/", url: url_UntagResource_611275, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
