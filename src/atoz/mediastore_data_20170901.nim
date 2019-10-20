
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

  OpenApiRestCall_592355 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592355](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592355): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PutObject_592965 = ref object of OpenApiRestCall_592355
proc url_PutObject_592967(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutObject_592966(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592968 = path.getOrDefault("Path")
  valid_592968 = validateParameter(valid_592968, JString, required = true,
                                 default = nil)
  if valid_592968 != nil:
    section.add "Path", valid_592968
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
  var valid_592969 = header.getOrDefault("Cache-Control")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "Cache-Control", valid_592969
  var valid_592983 = header.getOrDefault("x-amz-storage-class")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = newJString("TEMPORAL"))
  if valid_592983 != nil:
    section.add "x-amz-storage-class", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Signature")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Signature", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Content-Sha256", valid_592985
  var valid_592986 = header.getOrDefault("x-amz-upload-availability")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_592986 != nil:
    section.add "x-amz-upload-availability", valid_592986
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
  var valid_592990 = header.getOrDefault("Content-Type")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "Content-Type", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Algorithm")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Algorithm", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-SignedHeaders", valid_592992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592994: Call_PutObject_592965; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ## 
  let valid = call_592994.validator(path, query, header, formData, body)
  let scheme = call_592994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592994.url(scheme.get, call_592994.host, call_592994.base,
                         call_592994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592994, url, valid)

proc call*(call_592995: Call_PutObject_592965; Path: string; body: JsonNode): Recallable =
  ## putObject
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ##   Path: string (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  ##   body: JObject (required)
  var path_592996 = newJObject()
  var body_592997 = newJObject()
  add(path_592996, "Path", newJString(Path))
  if body != nil:
    body_592997 = body
  result = call_592995.call(path_592996, nil, nil, nil, body_592997)

var putObject* = Call_PutObject_592965(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/{Path}",
                                    validator: validate_PutObject_592966,
                                    base: "/", url: url_PutObject_592967,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObject_593012 = ref object of OpenApiRestCall_592355
proc url_DescribeObject_593014(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeObject_593013(path: JsonNode; query: JsonNode;
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
  var valid_593015 = path.getOrDefault("Path")
  valid_593015 = validateParameter(valid_593015, JString, required = true,
                                 default = nil)
  if valid_593015 != nil:
    section.add "Path", valid_593015
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

proc call*(call_593023: Call_DescribeObject_593012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the headers for an object at the specified path.
  ## 
  let valid = call_593023.validator(path, query, header, formData, body)
  let scheme = call_593023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593023.url(scheme.get, call_593023.host, call_593023.base,
                         call_593023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593023, url, valid)

proc call*(call_593024: Call_DescribeObject_593012; Path: string): Recallable =
  ## describeObject
  ## Gets the headers for an object at the specified path.
  ##   Path: string (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var path_593025 = newJObject()
  add(path_593025, "Path", newJString(Path))
  result = call_593024.call(path_593025, nil, nil, nil, nil)

var describeObject* = Call_DescribeObject_593012(name: "describeObject",
    meth: HttpMethod.HttpHead, host: "data.mediastore.amazonaws.com",
    route: "/{Path}", validator: validate_DescribeObject_593013, base: "/",
    url: url_DescribeObject_593014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_592694 = ref object of OpenApiRestCall_592355
proc url_GetObject_592696(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetObject_592695(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592822 = path.getOrDefault("Path")
  valid_592822 = validateParameter(valid_592822, JString, required = true,
                                 default = nil)
  if valid_592822 != nil:
    section.add "Path", valid_592822
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
  var valid_592823 = header.getOrDefault("X-Amz-Signature")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Signature", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Content-Sha256", valid_592824
  var valid_592825 = header.getOrDefault("Range")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "Range", valid_592825
  var valid_592826 = header.getOrDefault("X-Amz-Date")
  valid_592826 = validateParameter(valid_592826, JString, required = false,
                                 default = nil)
  if valid_592826 != nil:
    section.add "X-Amz-Date", valid_592826
  var valid_592827 = header.getOrDefault("X-Amz-Credential")
  valid_592827 = validateParameter(valid_592827, JString, required = false,
                                 default = nil)
  if valid_592827 != nil:
    section.add "X-Amz-Credential", valid_592827
  var valid_592828 = header.getOrDefault("X-Amz-Security-Token")
  valid_592828 = validateParameter(valid_592828, JString, required = false,
                                 default = nil)
  if valid_592828 != nil:
    section.add "X-Amz-Security-Token", valid_592828
  var valid_592829 = header.getOrDefault("X-Amz-Algorithm")
  valid_592829 = validateParameter(valid_592829, JString, required = false,
                                 default = nil)
  if valid_592829 != nil:
    section.add "X-Amz-Algorithm", valid_592829
  var valid_592830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592830 = validateParameter(valid_592830, JString, required = false,
                                 default = nil)
  if valid_592830 != nil:
    section.add "X-Amz-SignedHeaders", valid_592830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592853: Call_GetObject_592694; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ## 
  let valid = call_592853.validator(path, query, header, formData, body)
  let scheme = call_592853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592853.url(scheme.get, call_592853.host, call_592853.base,
                         call_592853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592853, url, valid)

proc call*(call_592924: Call_GetObject_592694; Path: string): Recallable =
  ## getObject
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ##   Path: string (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  var path_592925 = newJObject()
  add(path_592925, "Path", newJString(Path))
  result = call_592924.call(path_592925, nil, nil, nil, nil)

var getObject* = Call_GetObject_592694(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/{Path}",
                                    validator: validate_GetObject_592695,
                                    base: "/", url: url_GetObject_592696,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_592998 = ref object of OpenApiRestCall_592355
proc url_DeleteObject_593000(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObject_592999(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593001 = path.getOrDefault("Path")
  valid_593001 = validateParameter(valid_593001, JString, required = true,
                                 default = nil)
  if valid_593001 != nil:
    section.add "Path", valid_593001
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
  var valid_593002 = header.getOrDefault("X-Amz-Signature")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Signature", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Content-Sha256", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Date")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Date", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Credential")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Credential", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Security-Token")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Security-Token", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Algorithm")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Algorithm", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-SignedHeaders", valid_593008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593009: Call_DeleteObject_592998; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object at the specified path.
  ## 
  let valid = call_593009.validator(path, query, header, formData, body)
  let scheme = call_593009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593009.url(scheme.get, call_593009.host, call_593009.base,
                         call_593009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593009, url, valid)

proc call*(call_593010: Call_DeleteObject_592998; Path: string): Recallable =
  ## deleteObject
  ## Deletes an object at the specified path.
  ##   Path: string (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var path_593011 = newJObject()
  add(path_593011, "Path", newJString(Path))
  result = call_593010.call(path_593011, nil, nil, nil, nil)

var deleteObject* = Call_DeleteObject_592998(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "data.mediastore.amazonaws.com",
    route: "/{Path}", validator: validate_DeleteObject_592999, base: "/",
    url: url_DeleteObject_593000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListItems_593026 = ref object of OpenApiRestCall_592355
proc url_ListItems_593028(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListItems_593027(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593029 = query.getOrDefault("MaxResults")
  valid_593029 = validateParameter(valid_593029, JInt, required = false, default = nil)
  if valid_593029 != nil:
    section.add "MaxResults", valid_593029
  var valid_593030 = query.getOrDefault("NextToken")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "NextToken", valid_593030
  var valid_593031 = query.getOrDefault("Path")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "Path", valid_593031
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
  var valid_593032 = header.getOrDefault("X-Amz-Signature")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Signature", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Content-Sha256", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Date")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Date", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Credential")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Credential", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Security-Token")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Security-Token", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Algorithm")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Algorithm", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-SignedHeaders", valid_593038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593039: Call_ListItems_593026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ## 
  let valid = call_593039.validator(path, query, header, formData, body)
  let scheme = call_593039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593039.url(scheme.get, call_593039.host, call_593039.base,
                         call_593039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593039, url, valid)

proc call*(call_593040: Call_ListItems_593026; MaxResults: int = 0;
          NextToken: string = ""; Path: string = ""): Recallable =
  ## listItems
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ##   MaxResults: int
  ##             : <p>The maximum number of results to return per API request. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. Although 2,000 items match your request, the service returns no more than the first 500 items. (The service also returns a <code>NextToken</code> value that you can use to fetch the next batch of results.) The service might return fewer results than the <code>MaxResults</code> value.</p> <p>If <code>MaxResults</code> is not included in the request, the service defaults to pagination with a maximum of 1,000 results per page.</p>
  ##   NextToken: string
  ##            : <p>The token that identifies which batch of results that you want to see. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. The service returns the first batch of results (up to 500) and a <code>NextToken</code> value. To see the next batch of results, you can submit the <code>ListItems</code> request a second time and specify the <code>NextToken</code> value.</p> <p>Tokens expire after 15 minutes.</p>
  ##   Path: string
  ##       : The path in the container from which to retrieve items. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var query_593041 = newJObject()
  add(query_593041, "MaxResults", newJInt(MaxResults))
  add(query_593041, "NextToken", newJString(NextToken))
  add(query_593041, "Path", newJString(Path))
  result = call_593040.call(nil, query_593041, nil, nil, nil)

var listItems* = Call_ListItems_593026(name: "listItems", meth: HttpMethod.HttpGet,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/", validator: validate_ListItems_593027,
                                    base: "/", url: url_ListItems_593028,
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
