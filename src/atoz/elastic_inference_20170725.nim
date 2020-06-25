
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_TagResource_21626021 = ref object of OpenApiRestCall_21625426
proc url_TagResource_21626023(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626022(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626024 = path.getOrDefault("resourceArn")
  valid_21626024 = validateParameter(valid_21626024, JString, required = true,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "resourceArn", valid_21626024
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626033: Call_TagResource_21626021; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ## 
  let valid = call_21626033.validator(path, query, header, formData, body, _)
  let scheme = call_21626033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626033.makeUrl(scheme.get, call_21626033.host, call_21626033.base,
                               call_21626033.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626033, uri, valid, _)

proc call*(call_21626034: Call_TagResource_21626021; body: JsonNode;
          resourceArn: string): Recallable =
  ## tagResource
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to tag.
  var path_21626035 = newJObject()
  var body_21626036 = newJObject()
  if body != nil:
    body_21626036 = body
  add(path_21626035, "resourceArn", newJString(resourceArn))
  result = call_21626034.call(path_21626035, nil, nil, nil, body_21626036)

var tagResource* = Call_TagResource_21626021(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "api.elastic-inference.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_21626022,
    base: "/", makeUrl: url_TagResource_21626023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21625770 = ref object of OpenApiRestCall_21625426
proc url_ListTagsForResource_21625772(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21625771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625886 = path.getOrDefault("resourceArn")
  valid_21625886 = validateParameter(valid_21625886, JString, required = true,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "resourceArn", valid_21625886
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

proc call*(call_21625918: Call_ListTagsForResource_21625770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all tags of an Elastic Inference Accelerator.
  ## 
  let valid = call_21625918.validator(path, query, header, formData, body, _)
  let scheme = call_21625918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625918.makeUrl(scheme.get, call_21625918.host, call_21625918.base,
                               call_21625918.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625918, uri, valid, _)

proc call*(call_21625981: Call_ListTagsForResource_21625770; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns all tags of an Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to list the tags for.
  var path_21625983 = newJObject()
  add(path_21625983, "resourceArn", newJString(resourceArn))
  result = call_21625981.call(path_21625983, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21625770(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "api.elastic-inference.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_21625771, base: "/",
    makeUrl: url_ListTagsForResource_21625772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626037 = ref object of OpenApiRestCall_21625426
proc url_UntagResource_21626039(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626038(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626040 = path.getOrDefault("resourceArn")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "resourceArn", valid_21626040
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The list of tags to remove from the Elastic Inference Accelerator.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626041 = query.getOrDefault("tagKeys")
  valid_21626041 = validateParameter(valid_21626041, JArray, required = true,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "tagKeys", valid_21626041
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
  var valid_21626042 = header.getOrDefault("X-Amz-Date")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Date", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Security-Token", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Algorithm", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Signature")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Signature", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Credential")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Credential", valid_21626048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626049: Call_UntagResource_21626037; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ## 
  let valid = call_21626049.validator(path, query, header, formData, body, _)
  let scheme = call_21626049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626049.makeUrl(scheme.get, call_21626049.host, call_21626049.base,
                               call_21626049.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626049, uri, valid, _)

proc call*(call_21626050: Call_UntagResource_21626037; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ##   tagKeys: JArray (required)
  ##          : The list of tags to remove from the Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to untag.
  var path_21626051 = newJObject()
  var query_21626052 = newJObject()
  if tagKeys != nil:
    query_21626052.add "tagKeys", tagKeys
  add(path_21626051, "resourceArn", newJString(resourceArn))
  result = call_21626050.call(path_21626051, query_21626052, nil, nil, nil)

var untagResource* = Call_UntagResource_21626037(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "api.elastic-inference.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_21626038,
    base: "/", makeUrl: url_UntagResource_21626039,
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