
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612649): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PutObject_613258 = ref object of OpenApiRestCall_612649
proc url_PutObject_613260(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutObject_613259(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Path: JString (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Path` field"
  var valid_613261 = path.getOrDefault("Path")
  valid_613261 = validateParameter(valid_613261, JString, required = true,
                                 default = nil)
  if valid_613261 != nil:
    section.add "Path", valid_613261
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Cache-Control: JString
  ##                : <p>An optional <code>CacheControl</code> header that allows the caller to control the object's cache behavior. Headers can be passed in as specified in the HTTP at <a 
  ## href="https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9">https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9</a>.</p> <p>Headers with a custom user-defined value are also accepted.</p>
  ##   x-amz-storage-class: JString
  ##                      : Indicates the storage class of a <code>Put</code> request. Defaults to high-performance temporal storage class, and objects are persisted into durable storage shortly after being received.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-upload-availability: JString
  ##                            : <p>Indicates the availability of an object while it is still uploading. If the value is set to <code>streaming</code>, the object is available for downloading after some initial buffering but before the object is uploaded completely. If the value is set to <code>standard</code>, the object is available for downloading only when it is uploaded completely. The default value for this header is <code>standard</code>.</p> <p>To use this header, you must also set the HTTP <code>Transfer-Encoding</code> header to <code>chunked</code>.</p>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   Content-Type: JString
  ##               : The content type of the object.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613262 = header.getOrDefault("Cache-Control")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "Cache-Control", valid_613262
  var valid_613276 = header.getOrDefault("x-amz-storage-class")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = newJString("TEMPORAL"))
  if valid_613276 != nil:
    section.add "x-amz-storage-class", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Signature")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Signature", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Content-Sha256", valid_613278
  var valid_613279 = header.getOrDefault("x-amz-upload-availability")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_613279 != nil:
    section.add "x-amz-upload-availability", valid_613279
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
  var valid_613283 = header.getOrDefault("Content-Type")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "Content-Type", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Algorithm")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Algorithm", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-SignedHeaders", valid_613285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613287: Call_PutObject_613258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ## 
  let valid = call_613287.validator(path, query, header, formData, body)
  let scheme = call_613287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613287.url(scheme.get, call_613287.host, call_613287.base,
                         call_613287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613287, url, valid)

proc call*(call_613288: Call_PutObject_613258; Path: string; body: JsonNode): Recallable =
  ## putObject
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ##   Path: string (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  ##   body: JObject (required)
  var path_613289 = newJObject()
  var body_613290 = newJObject()
  add(path_613289, "Path", newJString(Path))
  if body != nil:
    body_613290 = body
  result = call_613288.call(path_613289, nil, nil, nil, body_613290)

var putObject* = Call_PutObject_613258(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/{Path}",
                                    validator: validate_PutObject_613259,
                                    base: "/", url: url_PutObject_613260,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObject_613305 = ref object of OpenApiRestCall_612649
proc url_DescribeObject_613307(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeObject_613306(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets the headers for an object at the specified path.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Path: JString (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Path` field"
  var valid_613308 = path.getOrDefault("Path")
  valid_613308 = validateParameter(valid_613308, JString, required = true,
                                 default = nil)
  if valid_613308 != nil:
    section.add "Path", valid_613308
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

proc call*(call_613316: Call_DescribeObject_613305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the headers for an object at the specified path.
  ## 
  let valid = call_613316.validator(path, query, header, formData, body)
  let scheme = call_613316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613316.url(scheme.get, call_613316.host, call_613316.base,
                         call_613316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613316, url, valid)

proc call*(call_613317: Call_DescribeObject_613305; Path: string): Recallable =
  ## describeObject
  ## Gets the headers for an object at the specified path.
  ##   Path: string (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var path_613318 = newJObject()
  add(path_613318, "Path", newJString(Path))
  result = call_613317.call(path_613318, nil, nil, nil, nil)

var describeObject* = Call_DescribeObject_613305(name: "describeObject",
    meth: HttpMethod.HttpHead, host: "data.mediastore.amazonaws.com",
    route: "/{Path}", validator: validate_DescribeObject_613306, base: "/",
    url: url_DescribeObject_613307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_612987 = ref object of OpenApiRestCall_612649
proc url_GetObject_612989(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetObject_612988(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Path: JString (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Path` field"
  var valid_613115 = path.getOrDefault("Path")
  valid_613115 = validateParameter(valid_613115, JString, required = true,
                                 default = nil)
  if valid_613115 != nil:
    section.add "Path", valid_613115
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Range: JString
  ##        : The range bytes of an object to retrieve. For more information about the <code>Range</code> header, see <a 
  ## href="http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35">http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35</a>. AWS Elemental MediaStore ignores this header for partially uploaded objects that have streaming upload availability.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613116 = header.getOrDefault("X-Amz-Signature")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Signature", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Content-Sha256", valid_613117
  var valid_613118 = header.getOrDefault("Range")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "Range", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Date")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Date", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Credential")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Credential", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-Security-Token")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-Security-Token", valid_613121
  var valid_613122 = header.getOrDefault("X-Amz-Algorithm")
  valid_613122 = validateParameter(valid_613122, JString, required = false,
                                 default = nil)
  if valid_613122 != nil:
    section.add "X-Amz-Algorithm", valid_613122
  var valid_613123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613123 = validateParameter(valid_613123, JString, required = false,
                                 default = nil)
  if valid_613123 != nil:
    section.add "X-Amz-SignedHeaders", valid_613123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613146: Call_GetObject_612987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ## 
  let valid = call_613146.validator(path, query, header, formData, body)
  let scheme = call_613146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613146.url(scheme.get, call_613146.host, call_613146.base,
                         call_613146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613146, url, valid)

proc call*(call_613217: Call_GetObject_612987; Path: string): Recallable =
  ## getObject
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ##   Path: string (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  var path_613218 = newJObject()
  add(path_613218, "Path", newJString(Path))
  result = call_613217.call(path_613218, nil, nil, nil, nil)

var getObject* = Call_GetObject_612987(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/{Path}",
                                    validator: validate_GetObject_612988,
                                    base: "/", url: url_GetObject_612989,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_613291 = ref object of OpenApiRestCall_612649
proc url_DeleteObject_613293(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteObject_613292(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an object at the specified path.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Path: JString (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Path` field"
  var valid_613294 = path.getOrDefault("Path")
  valid_613294 = validateParameter(valid_613294, JString, required = true,
                                 default = nil)
  if valid_613294 != nil:
    section.add "Path", valid_613294
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
  var valid_613295 = header.getOrDefault("X-Amz-Signature")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Signature", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Content-Sha256", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Date")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Date", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Credential")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Credential", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Security-Token")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Security-Token", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Algorithm")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Algorithm", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-SignedHeaders", valid_613301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613302: Call_DeleteObject_613291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object at the specified path.
  ## 
  let valid = call_613302.validator(path, query, header, formData, body)
  let scheme = call_613302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613302.url(scheme.get, call_613302.host, call_613302.base,
                         call_613302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613302, url, valid)

proc call*(call_613303: Call_DeleteObject_613291; Path: string): Recallable =
  ## deleteObject
  ## Deletes an object at the specified path.
  ##   Path: string (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var path_613304 = newJObject()
  add(path_613304, "Path", newJString(Path))
  result = call_613303.call(path_613304, nil, nil, nil, nil)

var deleteObject* = Call_DeleteObject_613291(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "data.mediastore.amazonaws.com",
    route: "/{Path}", validator: validate_DeleteObject_613292, base: "/",
    url: url_DeleteObject_613293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListItems_613319 = ref object of OpenApiRestCall_612649
proc url_ListItems_613321(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListItems_613320(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : <p>The maximum number of results to return per API request. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. Although 2,000 items match your request, the service returns no more than the first 500 items. (The service also returns a <code>NextToken</code> value that you can use to fetch the next batch of results.) The service might return fewer results than the <code>MaxResults</code> value.</p> <p>If <code>MaxResults</code> is not included in the request, the service defaults to pagination with a maximum of 1,000 results per page.</p>
  ##   NextToken: JString
  ##            : <p>The token that identifies which batch of results that you want to see. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. The service returns the first batch of results (up to 500) and a <code>NextToken</code> value. To see the next batch of results, you can submit the <code>ListItems</code> request a second time and specify the <code>NextToken</code> value.</p> <p>Tokens expire after 15 minutes.</p>
  ##   Path: JString
  ##       : The path in the container from which to retrieve items. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  section = newJObject()
  var valid_613322 = query.getOrDefault("MaxResults")
  valid_613322 = validateParameter(valid_613322, JInt, required = false, default = nil)
  if valid_613322 != nil:
    section.add "MaxResults", valid_613322
  var valid_613323 = query.getOrDefault("NextToken")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "NextToken", valid_613323
  var valid_613324 = query.getOrDefault("Path")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "Path", valid_613324
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
  var valid_613325 = header.getOrDefault("X-Amz-Signature")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Signature", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Content-Sha256", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Date")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Date", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Credential")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Credential", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Security-Token")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Security-Token", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Algorithm")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Algorithm", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-SignedHeaders", valid_613331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613332: Call_ListItems_613319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ## 
  let valid = call_613332.validator(path, query, header, formData, body)
  let scheme = call_613332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613332.url(scheme.get, call_613332.host, call_613332.base,
                         call_613332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613332, url, valid)

proc call*(call_613333: Call_ListItems_613319; MaxResults: int = 0;
          NextToken: string = ""; Path: string = ""): Recallable =
  ## listItems
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ##   MaxResults: int
  ##             : <p>The maximum number of results to return per API request. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. Although 2,000 items match your request, the service returns no more than the first 500 items. (The service also returns a <code>NextToken</code> value that you can use to fetch the next batch of results.) The service might return fewer results than the <code>MaxResults</code> value.</p> <p>If <code>MaxResults</code> is not included in the request, the service defaults to pagination with a maximum of 1,000 results per page.</p>
  ##   NextToken: string
  ##            : <p>The token that identifies which batch of results that you want to see. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. The service returns the first batch of results (up to 500) and a <code>NextToken</code> value. To see the next batch of results, you can submit the <code>ListItems</code> request a second time and specify the <code>NextToken</code> value.</p> <p>Tokens expire after 15 minutes.</p>
  ##   Path: string
  ##       : The path in the container from which to retrieve items. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var query_613334 = newJObject()
  add(query_613334, "MaxResults", newJInt(MaxResults))
  add(query_613334, "NextToken", newJString(NextToken))
  add(query_613334, "Path", newJString(Path))
  result = call_613333.call(nil, query_613334, nil, nil, nil)

var listItems* = Call_ListItems_613319(name: "listItems", meth: HttpMethod.HttpGet,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/", validator: validate_ListItems_613320,
                                    base: "/", url: url_ListItems_613321,
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
