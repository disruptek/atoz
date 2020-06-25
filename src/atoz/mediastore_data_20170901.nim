
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Elemental MediaStore Data Plane
## version: 2017-09-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## An AWS Elemental MediaStore asset is an object, similar to an object in the Amazon S3 service. Objects are the fundamental entities that are stored in AWS Elemental MediaStore.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mediastore/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "data.mediastore.ap-northeast-1.amazonaws.com", "ap-southeast-1": "data.mediastore.ap-southeast-1.amazonaws.com", "us-west-2": "data.mediastore.us-west-2.amazonaws.com", "eu-west-2": "data.mediastore.eu-west-2.amazonaws.com", "ap-northeast-3": "data.mediastore.ap-northeast-3.amazonaws.com", "eu-central-1": "data.mediastore.eu-central-1.amazonaws.com", "us-east-2": "data.mediastore.us-east-2.amazonaws.com", "us-east-1": "data.mediastore.us-east-1.amazonaws.com", "cn-northwest-1": "data.mediastore.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "data.mediastore.ap-south-1.amazonaws.com", "eu-north-1": "data.mediastore.eu-north-1.amazonaws.com", "ap-northeast-2": "data.mediastore.ap-northeast-2.amazonaws.com", "us-west-1": "data.mediastore.us-west-1.amazonaws.com", "us-gov-east-1": "data.mediastore.us-gov-east-1.amazonaws.com", "eu-west-3": "data.mediastore.eu-west-3.amazonaws.com", "cn-north-1": "data.mediastore.cn-north-1.amazonaws.com.cn", "sa-east-1": "data.mediastore.sa-east-1.amazonaws.com", "eu-west-1": "data.mediastore.eu-west-1.amazonaws.com", "us-gov-west-1": "data.mediastore.us-gov-west-1.amazonaws.com", "ap-southeast-2": "data.mediastore.ap-southeast-2.amazonaws.com", "ca-central-1": "data.mediastore.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "data.mediastore.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "data.mediastore.ap-southeast-1.amazonaws.com",
      "us-west-2": "data.mediastore.us-west-2.amazonaws.com",
      "eu-west-2": "data.mediastore.eu-west-2.amazonaws.com",
      "ap-northeast-3": "data.mediastore.ap-northeast-3.amazonaws.com",
      "eu-central-1": "data.mediastore.eu-central-1.amazonaws.com",
      "us-east-2": "data.mediastore.us-east-2.amazonaws.com",
      "us-east-1": "data.mediastore.us-east-1.amazonaws.com",
      "cn-northwest-1": "data.mediastore.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "data.mediastore.ap-south-1.amazonaws.com",
      "eu-north-1": "data.mediastore.eu-north-1.amazonaws.com",
      "ap-northeast-2": "data.mediastore.ap-northeast-2.amazonaws.com",
      "us-west-1": "data.mediastore.us-west-1.amazonaws.com",
      "us-gov-east-1": "data.mediastore.us-gov-east-1.amazonaws.com",
      "eu-west-3": "data.mediastore.eu-west-3.amazonaws.com",
      "cn-north-1": "data.mediastore.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "data.mediastore.sa-east-1.amazonaws.com",
      "eu-west-1": "data.mediastore.eu-west-1.amazonaws.com",
      "us-gov-west-1": "data.mediastore.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "data.mediastore.ap-southeast-2.amazonaws.com",
      "ca-central-1": "data.mediastore.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mediastore-data"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PutObject_21626022 = ref object of OpenApiRestCall_21625426
proc url_PutObject_21626024(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Path" in path, "`Path` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Path")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutObject_21626023(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Path: JString (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Path` field"
  var valid_21626025 = path.getOrDefault("Path")
  valid_21626025 = validateParameter(valid_21626025, JString, required = true,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "Path", valid_21626025
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Cache-Control: JString
  ##                : <p>An optional <code>CacheControl</code> header that allows the caller to control the object's cache behavior. Headers can be passed in as specified in the HTTP at <a 
  ## href="https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9">https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9</a>.</p> <p>Headers with a custom user-defined value are also accepted.</p>
  ##   Content-Type: JString
  ##               : The content type of the object.
  ##   X-Amz-Algorithm: JString
  ##   x-amz-storage-class: JString
  ##                      : Indicates the storage class of a <code>Put</code> request. Defaults to high-performance temporal storage class, and objects are persisted into durable storage shortly after being received.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-upload-availability: JString
  ##                            : <p>Indicates the availability of an object while it is still uploading. If the value is set to <code>streaming</code>, the object is available for downloading after some initial buffering but before the object is uploaded completely. If the value is set to <code>standard</code>, the object is available for downloading only when it is uploaded completely. The default value for this header is <code>standard</code>.</p> <p>To use this header, you must also set the HTTP <code>Transfer-Encoding</code> header to <code>chunked</code>.</p>
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626026 = header.getOrDefault("X-Amz-Date")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Date", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Security-Token", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626028
  var valid_21626029 = header.getOrDefault("Cache-Control")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "Cache-Control", valid_21626029
  var valid_21626030 = header.getOrDefault("Content-Type")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "Content-Type", valid_21626030
  var valid_21626031 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-Algorithm", valid_21626031
  var valid_21626046 = header.getOrDefault("x-amz-storage-class")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = newJString("TEMPORAL"))
  if valid_21626046 != nil:
    section.add "x-amz-storage-class", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Signature")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Signature", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626048
  var valid_21626049 = header.getOrDefault("x-amz-upload-availability")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = newJString("STANDARD"))
  if valid_21626049 != nil:
    section.add "x-amz-upload-availability", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Credential")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Credential", valid_21626050
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

proc call*(call_21626052: Call_PutObject_21626022; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ## 
  let valid = call_21626052.validator(path, query, header, formData, body, _)
  let scheme = call_21626052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626052.makeUrl(scheme.get, call_21626052.host, call_21626052.base,
                               call_21626052.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626052, uri, valid, _)

proc call*(call_21626053: Call_PutObject_21626022; Path: string; body: JsonNode): Recallable =
  ## putObject
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ##   Path: string (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  ##   body: JObject (required)
  var path_21626054 = newJObject()
  var body_21626055 = newJObject()
  add(path_21626054, "Path", newJString(Path))
  if body != nil:
    body_21626055 = body
  result = call_21626053.call(path_21626054, nil, nil, nil, body_21626055)

var putObject* = Call_PutObject_21626022(name: "putObject", meth: HttpMethod.HttpPut,
                                      host: "data.mediastore.amazonaws.com",
                                      route: "/{Path}",
                                      validator: validate_PutObject_21626023,
                                      base: "/", makeUrl: url_PutObject_21626024,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObject_21626070 = ref object of OpenApiRestCall_21625426
proc url_DescribeObject_21626072(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Path" in path, "`Path` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Path")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeObject_21626071(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the headers for an object at the specified path.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Path: JString (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Path` field"
  var valid_21626073 = path.getOrDefault("Path")
  valid_21626073 = validateParameter(valid_21626073, JString, required = true,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "Path", valid_21626073
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
  var valid_21626074 = header.getOrDefault("X-Amz-Date")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Date", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Security-Token", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Algorithm", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Signature")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Signature", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Credential")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Credential", valid_21626080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626081: Call_DescribeObject_21626070; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the headers for an object at the specified path.
  ## 
  let valid = call_21626081.validator(path, query, header, formData, body, _)
  let scheme = call_21626081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626081.makeUrl(scheme.get, call_21626081.host, call_21626081.base,
                               call_21626081.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626081, uri, valid, _)

proc call*(call_21626082: Call_DescribeObject_21626070; Path: string): Recallable =
  ## describeObject
  ## Gets the headers for an object at the specified path.
  ##   Path: string (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var path_21626083 = newJObject()
  add(path_21626083, "Path", newJString(Path))
  result = call_21626082.call(path_21626083, nil, nil, nil, nil)

var describeObject* = Call_DescribeObject_21626070(name: "describeObject",
    meth: HttpMethod.HttpHead, host: "data.mediastore.amazonaws.com",
    route: "/{Path}", validator: validate_DescribeObject_21626071, base: "/",
    makeUrl: url_DescribeObject_21626072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_21625770 = ref object of OpenApiRestCall_21625426
proc url_GetObject_21625772(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Path" in path, "`Path` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Path")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetObject_21625771(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Path: JString (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Path` field"
  var valid_21625886 = path.getOrDefault("Path")
  valid_21625886 = validateParameter(valid_21625886, JString, required = true,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "Path", valid_21625886
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
  ##   Range: JString
  ##        : The range bytes of an object to retrieve. For more information about the <code>Range</code> header, see <a 
  ## href="http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35">http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35</a>. AWS Elemental MediaStore ignores this header for partially uploaded objects that have streaming upload availability.
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
  var valid_21625894 = header.getOrDefault("Range")
  valid_21625894 = validateParameter(valid_21625894, JString, required = false,
                                   default = nil)
  if valid_21625894 != nil:
    section.add "Range", valid_21625894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625919: Call_GetObject_21625770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ## 
  let valid = call_21625919.validator(path, query, header, formData, body, _)
  let scheme = call_21625919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625919.makeUrl(scheme.get, call_21625919.host, call_21625919.base,
                               call_21625919.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625919, uri, valid, _)

proc call*(call_21625982: Call_GetObject_21625770; Path: string): Recallable =
  ## getObject
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ##   Path: string (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  var path_21625984 = newJObject()
  add(path_21625984, "Path", newJString(Path))
  result = call_21625982.call(path_21625984, nil, nil, nil, nil)

var getObject* = Call_GetObject_21625770(name: "getObject", meth: HttpMethod.HttpGet,
                                      host: "data.mediastore.amazonaws.com",
                                      route: "/{Path}",
                                      validator: validate_GetObject_21625771,
                                      base: "/", makeUrl: url_GetObject_21625772,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_21626056 = ref object of OpenApiRestCall_21625426
proc url_DeleteObject_21626058(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Path" in path, "`Path` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Path")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteObject_21626057(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes an object at the specified path.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Path: JString (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Path` field"
  var valid_21626059 = path.getOrDefault("Path")
  valid_21626059 = validateParameter(valid_21626059, JString, required = true,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "Path", valid_21626059
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
  var valid_21626060 = header.getOrDefault("X-Amz-Date")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Date", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Security-Token", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Algorithm", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Signature")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Signature", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Credential")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Credential", valid_21626066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626067: Call_DeleteObject_21626056; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an object at the specified path.
  ## 
  let valid = call_21626067.validator(path, query, header, formData, body, _)
  let scheme = call_21626067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626067.makeUrl(scheme.get, call_21626067.host, call_21626067.base,
                               call_21626067.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626067, uri, valid, _)

proc call*(call_21626068: Call_DeleteObject_21626056; Path: string): Recallable =
  ## deleteObject
  ## Deletes an object at the specified path.
  ##   Path: string (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var path_21626069 = newJObject()
  add(path_21626069, "Path", newJString(Path))
  result = call_21626068.call(path_21626069, nil, nil, nil, nil)

var deleteObject* = Call_DeleteObject_21626056(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "data.mediastore.amazonaws.com",
    route: "/{Path}", validator: validate_DeleteObject_21626057, base: "/",
    makeUrl: url_DeleteObject_21626058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListItems_21626084 = ref object of OpenApiRestCall_21625426
proc url_ListItems_21626086(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListItems_21626085(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : <p>The token that identifies which batch of results that you want to see. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. The service returns the first batch of results (up to 500) and a <code>NextToken</code> value. To see the next batch of results, you can submit the <code>ListItems</code> request a second time and specify the <code>NextToken</code> value.</p> <p>Tokens expire after 15 minutes.</p>
  ##   Path: JString
  ##       : The path in the container from which to retrieve items. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  ##   MaxResults: JInt
  ##             : <p>The maximum number of results to return per API request. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. Although 2,000 items match your request, the service returns no more than the first 500 items. (The service also returns a <code>NextToken</code> value that you can use to fetch the next batch of results.) The service might return fewer results than the <code>MaxResults</code> value.</p> <p>If <code>MaxResults</code> is not included in the request, the service defaults to pagination with a maximum of 1,000 results per page.</p>
  section = newJObject()
  var valid_21626087 = query.getOrDefault("NextToken")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "NextToken", valid_21626087
  var valid_21626088 = query.getOrDefault("Path")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "Path", valid_21626088
  var valid_21626089 = query.getOrDefault("MaxResults")
  valid_21626089 = validateParameter(valid_21626089, JInt, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "MaxResults", valid_21626089
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
  var valid_21626090 = header.getOrDefault("X-Amz-Date")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Date", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Security-Token", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Algorithm", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Signature")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Signature", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Credential")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Credential", valid_21626096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626097: Call_ListItems_21626084; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ## 
  let valid = call_21626097.validator(path, query, header, formData, body, _)
  let scheme = call_21626097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626097.makeUrl(scheme.get, call_21626097.host, call_21626097.base,
                               call_21626097.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626097, uri, valid, _)

proc call*(call_21626098: Call_ListItems_21626084; NextToken: string = "";
          Path: string = ""; MaxResults: int = 0): Recallable =
  ## listItems
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ##   NextToken: string
  ##            : <p>The token that identifies which batch of results that you want to see. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. The service returns the first batch of results (up to 500) and a <code>NextToken</code> value. To see the next batch of results, you can submit the <code>ListItems</code> request a second time and specify the <code>NextToken</code> value.</p> <p>Tokens expire after 15 minutes.</p>
  ##   Path: string
  ##       : The path in the container from which to retrieve items. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  ##   MaxResults: int
  ##             : <p>The maximum number of results to return per API request. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. Although 2,000 items match your request, the service returns no more than the first 500 items. (The service also returns a <code>NextToken</code> value that you can use to fetch the next batch of results.) The service might return fewer results than the <code>MaxResults</code> value.</p> <p>If <code>MaxResults</code> is not included in the request, the service defaults to pagination with a maximum of 1,000 results per page.</p>
  var query_21626099 = newJObject()
  add(query_21626099, "NextToken", newJString(NextToken))
  add(query_21626099, "Path", newJString(Path))
  add(query_21626099, "MaxResults", newJInt(MaxResults))
  result = call_21626098.call(nil, query_21626099, nil, nil, nil)

var listItems* = Call_ListItems_21626084(name: "listItems", meth: HttpMethod.HttpGet,
                                      host: "data.mediastore.amazonaws.com",
                                      route: "/", validator: validate_ListItems_21626085,
                                      base: "/", makeUrl: url_ListItems_21626086,
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