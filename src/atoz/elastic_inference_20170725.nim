
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

  OpenApiRestCall_599359 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599359](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599359): Option[Scheme] {.used.} =
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
  Call_TagResource_599966 = ref object of OpenApiRestCall_599359
proc url_TagResource_599968(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_599967(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599969 = path.getOrDefault("resourceArn")
  valid_599969 = validateParameter(valid_599969, JString, required = true,
                                 default = nil)
  if valid_599969 != nil:
    section.add "resourceArn", valid_599969
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
  var valid_599970 = header.getOrDefault("X-Amz-Date")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Date", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Security-Token")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Security-Token", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Content-Sha256", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-Algorithm")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-Algorithm", valid_599973
  var valid_599974 = header.getOrDefault("X-Amz-Signature")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "X-Amz-Signature", valid_599974
  var valid_599975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599975 = validateParameter(valid_599975, JString, required = false,
                                 default = nil)
  if valid_599975 != nil:
    section.add "X-Amz-SignedHeaders", valid_599975
  var valid_599976 = header.getOrDefault("X-Amz-Credential")
  valid_599976 = validateParameter(valid_599976, JString, required = false,
                                 default = nil)
  if valid_599976 != nil:
    section.add "X-Amz-Credential", valid_599976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599978: Call_TagResource_599966; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ## 
  let valid = call_599978.validator(path, query, header, formData, body)
  let scheme = call_599978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599978.url(scheme.get, call_599978.host, call_599978.base,
                         call_599978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599978, url, valid)

proc call*(call_599979: Call_TagResource_599966; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to tag.
  var path_599980 = newJObject()
  var body_599981 = newJObject()
  if body != nil:
    body_599981 = body
  add(path_599980, "resourceArn", newJString(resourceArn))
  result = call_599979.call(path_599980, nil, nil, nil, body_599981)

var tagResource* = Call_TagResource_599966(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "api.elastic-inference.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_599967,
                                        base: "/", url: url_TagResource_599968,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_599696 = ref object of OpenApiRestCall_599359
proc url_ListTagsForResource_599698(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_599697(path: JsonNode; query: JsonNode;
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
  var valid_599824 = path.getOrDefault("resourceArn")
  valid_599824 = validateParameter(valid_599824, JString, required = true,
                                 default = nil)
  if valid_599824 != nil:
    section.add "resourceArn", valid_599824
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
  var valid_599825 = header.getOrDefault("X-Amz-Date")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Date", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Security-Token")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Security-Token", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Content-Sha256", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-Algorithm")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-Algorithm", valid_599828
  var valid_599829 = header.getOrDefault("X-Amz-Signature")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "X-Amz-Signature", valid_599829
  var valid_599830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599830 = validateParameter(valid_599830, JString, required = false,
                                 default = nil)
  if valid_599830 != nil:
    section.add "X-Amz-SignedHeaders", valid_599830
  var valid_599831 = header.getOrDefault("X-Amz-Credential")
  valid_599831 = validateParameter(valid_599831, JString, required = false,
                                 default = nil)
  if valid_599831 != nil:
    section.add "X-Amz-Credential", valid_599831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599854: Call_ListTagsForResource_599696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags of an Elastic Inference Accelerator.
  ## 
  let valid = call_599854.validator(path, query, header, formData, body)
  let scheme = call_599854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599854.url(scheme.get, call_599854.host, call_599854.base,
                         call_599854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599854, url, valid)

proc call*(call_599925: Call_ListTagsForResource_599696; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns all tags of an Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to list the tags for.
  var path_599926 = newJObject()
  add(path_599926, "resourceArn", newJString(resourceArn))
  result = call_599925.call(path_599926, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_599696(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "api.elastic-inference.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_599697, base: "/",
    url: url_ListTagsForResource_599698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_599982 = ref object of OpenApiRestCall_599359
proc url_UntagResource_599984(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_599983(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599985 = path.getOrDefault("resourceArn")
  valid_599985 = validateParameter(valid_599985, JString, required = true,
                                 default = nil)
  if valid_599985 != nil:
    section.add "resourceArn", valid_599985
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The list of tags to remove from the Elastic Inference Accelerator.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_599986 = query.getOrDefault("tagKeys")
  valid_599986 = validateParameter(valid_599986, JArray, required = true, default = nil)
  if valid_599986 != nil:
    section.add "tagKeys", valid_599986
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

proc call*(call_599994: Call_UntagResource_599982; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ## 
  let valid = call_599994.validator(path, query, header, formData, body)
  let scheme = call_599994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599994.url(scheme.get, call_599994.host, call_599994.base,
                         call_599994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599994, url, valid)

proc call*(call_599995: Call_UntagResource_599982; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ##   tagKeys: JArray (required)
  ##          : The list of tags to remove from the Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to untag.
  var path_599996 = newJObject()
  var query_599997 = newJObject()
  if tagKeys != nil:
    query_599997.add "tagKeys", tagKeys
  add(path_599996, "resourceArn", newJString(resourceArn))
  result = call_599995.call(path_599996, query_599997, nil, nil, nil)

var untagResource* = Call_UntagResource_599982(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "api.elastic-inference.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_599983,
    base: "/", url: url_UntagResource_599984, schemes: {Scheme.Https, Scheme.Http})
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
