
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602457 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602457](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602457): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PutObject_603065 = ref object of OpenApiRestCall_602457
proc url_PutObject_603067(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_PutObject_603066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603068 = path.getOrDefault("Path")
  valid_603068 = validateParameter(valid_603068, JString, required = true,
                                 default = nil)
  if valid_603068 != nil:
    section.add "Path", valid_603068
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
  var valid_603069 = header.getOrDefault("X-Amz-Date")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Date", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Security-Token")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Security-Token", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Content-Sha256", valid_603071
  var valid_603072 = header.getOrDefault("Cache-Control")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "Cache-Control", valid_603072
  var valid_603073 = header.getOrDefault("Content-Type")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "Content-Type", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Algorithm")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Algorithm", valid_603074
  var valid_603088 = header.getOrDefault("x-amz-storage-class")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = newJString("TEMPORAL"))
  if valid_603088 != nil:
    section.add "x-amz-storage-class", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Signature")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Signature", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-SignedHeaders", valid_603090
  var valid_603091 = header.getOrDefault("x-amz-upload-availability")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_603091 != nil:
    section.add "x-amz-upload-availability", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Credential")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Credential", valid_603092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603094: Call_PutObject_603065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ## 
  let valid = call_603094.validator(path, query, header, formData, body)
  let scheme = call_603094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603094.url(scheme.get, call_603094.host, call_603094.base,
                         call_603094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603094, url, valid)

proc call*(call_603095: Call_PutObject_603065; Path: string; body: JsonNode): Recallable =
  ## putObject
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ##   Path: string (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  ##   body: JObject (required)
  var path_603096 = newJObject()
  var body_603097 = newJObject()
  add(path_603096, "Path", newJString(Path))
  if body != nil:
    body_603097 = body
  result = call_603095.call(path_603096, nil, nil, nil, body_603097)

var putObject* = Call_PutObject_603065(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/{Path}",
                                    validator: validate_PutObject_603066,
                                    base: "/", url: url_PutObject_603067,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObject_603112 = ref object of OpenApiRestCall_602457
proc url_DescribeObject_603114(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeObject_603113(path: JsonNode; query: JsonNode;
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
  var valid_603115 = path.getOrDefault("Path")
  valid_603115 = validateParameter(valid_603115, JString, required = true,
                                 default = nil)
  if valid_603115 != nil:
    section.add "Path", valid_603115
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
  var valid_603116 = header.getOrDefault("X-Amz-Date")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Date", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Security-Token")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Security-Token", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Content-Sha256", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Algorithm")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Algorithm", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Signature")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Signature", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-SignedHeaders", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Credential")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Credential", valid_603122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603123: Call_DescribeObject_603112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the headers for an object at the specified path.
  ## 
  let valid = call_603123.validator(path, query, header, formData, body)
  let scheme = call_603123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603123.url(scheme.get, call_603123.host, call_603123.base,
                         call_603123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603123, url, valid)

proc call*(call_603124: Call_DescribeObject_603112; Path: string): Recallable =
  ## describeObject
  ## Gets the headers for an object at the specified path.
  ##   Path: string (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var path_603125 = newJObject()
  add(path_603125, "Path", newJString(Path))
  result = call_603124.call(path_603125, nil, nil, nil, nil)

var describeObject* = Call_DescribeObject_603112(name: "describeObject",
    meth: HttpMethod.HttpHead, host: "data.mediastore.amazonaws.com",
    route: "/{Path}", validator: validate_DescribeObject_603113, base: "/",
    url: url_DescribeObject_603114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_602794 = ref object of OpenApiRestCall_602457
proc url_GetObject_602796(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetObject_602795(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602922 = path.getOrDefault("Path")
  valid_602922 = validateParameter(valid_602922, JString, required = true,
                                 default = nil)
  if valid_602922 != nil:
    section.add "Path", valid_602922
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
  var valid_602923 = header.getOrDefault("X-Amz-Date")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Date", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Security-Token")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Security-Token", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Content-Sha256", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Algorithm")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Algorithm", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-Signature")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-Signature", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-SignedHeaders", valid_602928
  var valid_602929 = header.getOrDefault("X-Amz-Credential")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-Credential", valid_602929
  var valid_602930 = header.getOrDefault("Range")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "Range", valid_602930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602953: Call_GetObject_602794; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ## 
  let valid = call_602953.validator(path, query, header, formData, body)
  let scheme = call_602953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602953.url(scheme.get, call_602953.host, call_602953.base,
                         call_602953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602953, url, valid)

proc call*(call_603024: Call_GetObject_602794; Path: string): Recallable =
  ## getObject
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ##   Path: string (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  var path_603025 = newJObject()
  add(path_603025, "Path", newJString(Path))
  result = call_603024.call(path_603025, nil, nil, nil, nil)

var getObject* = Call_GetObject_602794(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/{Path}",
                                    validator: validate_GetObject_602795,
                                    base: "/", url: url_GetObject_602796,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_603098 = ref object of OpenApiRestCall_602457
proc url_DeleteObject_603100(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteObject_603099(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603101 = path.getOrDefault("Path")
  valid_603101 = validateParameter(valid_603101, JString, required = true,
                                 default = nil)
  if valid_603101 != nil:
    section.add "Path", valid_603101
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
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Content-Sha256", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Algorithm")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Algorithm", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Signature")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Signature", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-SignedHeaders", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Credential")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Credential", valid_603108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603109: Call_DeleteObject_603098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object at the specified path.
  ## 
  let valid = call_603109.validator(path, query, header, formData, body)
  let scheme = call_603109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603109.url(scheme.get, call_603109.host, call_603109.base,
                         call_603109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603109, url, valid)

proc call*(call_603110: Call_DeleteObject_603098; Path: string): Recallable =
  ## deleteObject
  ## Deletes an object at the specified path.
  ##   Path: string (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var path_603111 = newJObject()
  add(path_603111, "Path", newJString(Path))
  result = call_603110.call(path_603111, nil, nil, nil, nil)

var deleteObject* = Call_DeleteObject_603098(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "data.mediastore.amazonaws.com",
    route: "/{Path}", validator: validate_DeleteObject_603099, base: "/",
    url: url_DeleteObject_603100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListItems_603126 = ref object of OpenApiRestCall_602457
proc url_ListItems_603128(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListItems_603127(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603129 = query.getOrDefault("NextToken")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "NextToken", valid_603129
  var valid_603130 = query.getOrDefault("Path")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "Path", valid_603130
  var valid_603131 = query.getOrDefault("MaxResults")
  valid_603131 = validateParameter(valid_603131, JInt, required = false, default = nil)
  if valid_603131 != nil:
    section.add "MaxResults", valid_603131
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
  var valid_603132 = header.getOrDefault("X-Amz-Date")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Date", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Security-Token")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Security-Token", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Content-Sha256", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Algorithm")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Algorithm", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Signature")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Signature", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-SignedHeaders", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Credential")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Credential", valid_603138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603139: Call_ListItems_603126; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ## 
  let valid = call_603139.validator(path, query, header, formData, body)
  let scheme = call_603139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603139.url(scheme.get, call_603139.host, call_603139.base,
                         call_603139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603139, url, valid)

proc call*(call_603140: Call_ListItems_603126; NextToken: string = "";
          Path: string = ""; MaxResults: int = 0): Recallable =
  ## listItems
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ##   NextToken: string
  ##            : <p>The token that identifies which batch of results that you want to see. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. The service returns the first batch of results (up to 500) and a <code>NextToken</code> value. To see the next batch of results, you can submit the <code>ListItems</code> request a second time and specify the <code>NextToken</code> value.</p> <p>Tokens expire after 15 minutes.</p>
  ##   Path: string
  ##       : The path in the container from which to retrieve items. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  ##   MaxResults: int
  ##             : <p>The maximum number of results to return per API request. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. Although 2,000 items match your request, the service returns no more than the first 500 items. (The service also returns a <code>NextToken</code> value that you can use to fetch the next batch of results.) The service might return fewer results than the <code>MaxResults</code> value.</p> <p>If <code>MaxResults</code> is not included in the request, the service defaults to pagination with a maximum of 1,000 results per page.</p>
  var query_603141 = newJObject()
  add(query_603141, "NextToken", newJString(NextToken))
  add(query_603141, "Path", newJString(Path))
  add(query_603141, "MaxResults", newJInt(MaxResults))
  result = call_603140.call(nil, query_603141, nil, nil, nil)

var listItems* = Call_ListItems_603126(name: "listItems", meth: HttpMethod.HttpGet,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/", validator: validate_ListItems_603127,
                                    base: "/", url: url_ListItems_603128,
                                    schemes: {Scheme.Https, Scheme.Http})
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
