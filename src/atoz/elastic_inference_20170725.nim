
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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
  Call_TagResource_606188 = ref object of OpenApiRestCall_605580
proc url_TagResource_606190(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_606189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606191 = path.getOrDefault("resourceArn")
  valid_606191 = validateParameter(valid_606191, JString, required = true,
                                 default = nil)
  if valid_606191 != nil:
    section.add "resourceArn", valid_606191
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
  var valid_606192 = header.getOrDefault("X-Amz-Signature")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Signature", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Content-Sha256", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Date")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Date", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-Credential")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-Credential", valid_606195
  var valid_606196 = header.getOrDefault("X-Amz-Security-Token")
  valid_606196 = validateParameter(valid_606196, JString, required = false,
                                 default = nil)
  if valid_606196 != nil:
    section.add "X-Amz-Security-Token", valid_606196
  var valid_606197 = header.getOrDefault("X-Amz-Algorithm")
  valid_606197 = validateParameter(valid_606197, JString, required = false,
                                 default = nil)
  if valid_606197 != nil:
    section.add "X-Amz-Algorithm", valid_606197
  var valid_606198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606198 = validateParameter(valid_606198, JString, required = false,
                                 default = nil)
  if valid_606198 != nil:
    section.add "X-Amz-SignedHeaders", valid_606198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606200: Call_TagResource_606188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ## 
  let valid = call_606200.validator(path, query, header, formData, body)
  let scheme = call_606200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606200.url(scheme.get, call_606200.host, call_606200.base,
                         call_606200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606200, url, valid)

proc call*(call_606201: Call_TagResource_606188; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to tag.
  ##   body: JObject (required)
  var path_606202 = newJObject()
  var body_606203 = newJObject()
  add(path_606202, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606203 = body
  result = call_606201.call(path_606202, nil, nil, nil, body_606203)

var tagResource* = Call_TagResource_606188(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "api.elastic-inference.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606189,
                                        base: "/", url: url_TagResource_606190,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_605918 = ref object of OpenApiRestCall_605580
proc url_ListTagsForResource_605920(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_605919(path: JsonNode; query: JsonNode;
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
  var valid_606046 = path.getOrDefault("resourceArn")
  valid_606046 = validateParameter(valid_606046, JString, required = true,
                                 default = nil)
  if valid_606046 != nil:
    section.add "resourceArn", valid_606046
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
  var valid_606047 = header.getOrDefault("X-Amz-Signature")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Signature", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Content-Sha256", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Date")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Date", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Credential")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Credential", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Security-Token")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Security-Token", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-Algorithm")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-Algorithm", valid_606052
  var valid_606053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606053 = validateParameter(valid_606053, JString, required = false,
                                 default = nil)
  if valid_606053 != nil:
    section.add "X-Amz-SignedHeaders", valid_606053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606076: Call_ListTagsForResource_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags of an Elastic Inference Accelerator.
  ## 
  let valid = call_606076.validator(path, query, header, formData, body)
  let scheme = call_606076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606076.url(scheme.get, call_606076.host, call_606076.base,
                         call_606076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606076, url, valid)

proc call*(call_606147: Call_ListTagsForResource_605918; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns all tags of an Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to list the tags for.
  var path_606148 = newJObject()
  add(path_606148, "resourceArn", newJString(resourceArn))
  result = call_606147.call(path_606148, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_605918(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "api.elastic-inference.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_605919, base: "/",
    url: url_ListTagsForResource_605920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606204 = ref object of OpenApiRestCall_605580
proc url_UntagResource_606206(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_606205(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606207 = path.getOrDefault("resourceArn")
  valid_606207 = validateParameter(valid_606207, JString, required = true,
                                 default = nil)
  if valid_606207 != nil:
    section.add "resourceArn", valid_606207
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The list of tags to remove from the Elastic Inference Accelerator.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606208 = query.getOrDefault("tagKeys")
  valid_606208 = validateParameter(valid_606208, JArray, required = true, default = nil)
  if valid_606208 != nil:
    section.add "tagKeys", valid_606208
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
  var valid_606209 = header.getOrDefault("X-Amz-Signature")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Signature", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Content-Sha256", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Date")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Date", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Credential")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Credential", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Security-Token")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Security-Token", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-Algorithm")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Algorithm", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-SignedHeaders", valid_606215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606216: Call_UntagResource_606204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ## 
  let valid = call_606216.validator(path, query, header, formData, body)
  let scheme = call_606216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606216.url(scheme.get, call_606216.host, call_606216.base,
                         call_606216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606216, url, valid)

proc call*(call_606217: Call_UntagResource_606204; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to untag.
  ##   tagKeys: JArray (required)
  ##          : The list of tags to remove from the Elastic Inference Accelerator.
  var path_606218 = newJObject()
  var query_606219 = newJObject()
  add(path_606218, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_606219.add "tagKeys", tagKeys
  result = call_606217.call(path_606218, query_606219, nil, nil, nil)

var untagResource* = Call_UntagResource_606204(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "api.elastic-inference.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_606205,
    base: "/", url: url_UntagResource_606206, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
