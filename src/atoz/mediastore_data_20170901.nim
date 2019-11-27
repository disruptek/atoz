
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
  Call_PutObject_599967 = ref object of OpenApiRestCall_599359
proc url_PutObject_599969(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutObject_599968(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599970 = path.getOrDefault("Path")
  valid_599970 = validateParameter(valid_599970, JString, required = true,
                                 default = nil)
  if valid_599970 != nil:
    section.add "Path", valid_599970
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
  var valid_599971 = header.getOrDefault("X-Amz-Date")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Date", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Security-Token")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Security-Token", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-Content-Sha256", valid_599973
  var valid_599974 = header.getOrDefault("Cache-Control")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "Cache-Control", valid_599974
  var valid_599975 = header.getOrDefault("Content-Type")
  valid_599975 = validateParameter(valid_599975, JString, required = false,
                                 default = nil)
  if valid_599975 != nil:
    section.add "Content-Type", valid_599975
  var valid_599976 = header.getOrDefault("X-Amz-Algorithm")
  valid_599976 = validateParameter(valid_599976, JString, required = false,
                                 default = nil)
  if valid_599976 != nil:
    section.add "X-Amz-Algorithm", valid_599976
  var valid_599990 = header.getOrDefault("x-amz-storage-class")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = newJString("TEMPORAL"))
  if valid_599990 != nil:
    section.add "x-amz-storage-class", valid_599990
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
  var valid_599993 = header.getOrDefault("x-amz-upload-availability")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_599993 != nil:
    section.add "x-amz-upload-availability", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Credential")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Credential", valid_599994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599996: Call_PutObject_599967; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ## 
  let valid = call_599996.validator(path, query, header, formData, body)
  let scheme = call_599996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599996.url(scheme.get, call_599996.host, call_599996.base,
                         call_599996.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599996, url, valid)

proc call*(call_599997: Call_PutObject_599967; Path: string; body: JsonNode): Recallable =
  ## putObject
  ## Uploads an object to the specified path. Object sizes are limited to 25 MB for standard upload availability and 10 MB for streaming upload availability.
  ##   Path: string (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  ##   body: JObject (required)
  var path_599998 = newJObject()
  var body_599999 = newJObject()
  add(path_599998, "Path", newJString(Path))
  if body != nil:
    body_599999 = body
  result = call_599997.call(path_599998, nil, nil, nil, body_599999)

var putObject* = Call_PutObject_599967(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/{Path}",
                                    validator: validate_PutObject_599968,
                                    base: "/", url: url_PutObject_599969,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObject_600014 = ref object of OpenApiRestCall_599359
proc url_DescribeObject_600016(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeObject_600015(path: JsonNode; query: JsonNode;
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
  var valid_600017 = path.getOrDefault("Path")
  valid_600017 = validateParameter(valid_600017, JString, required = true,
                                 default = nil)
  if valid_600017 != nil:
    section.add "Path", valid_600017
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

proc call*(call_600025: Call_DescribeObject_600014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the headers for an object at the specified path.
  ## 
  let valid = call_600025.validator(path, query, header, formData, body)
  let scheme = call_600025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600025.url(scheme.get, call_600025.host, call_600025.base,
                         call_600025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600025, url, valid)

proc call*(call_600026: Call_DescribeObject_600014; Path: string): Recallable =
  ## describeObject
  ## Gets the headers for an object at the specified path.
  ##   Path: string (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var path_600027 = newJObject()
  add(path_600027, "Path", newJString(Path))
  result = call_600026.call(path_600027, nil, nil, nil, nil)

var describeObject* = Call_DescribeObject_600014(name: "describeObject",
    meth: HttpMethod.HttpHead, host: "data.mediastore.amazonaws.com",
    route: "/{Path}", validator: validate_DescribeObject_600015, base: "/",
    url: url_DescribeObject_600016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_599696 = ref object of OpenApiRestCall_599359
proc url_GetObject_599698(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetObject_599697(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599824 = path.getOrDefault("Path")
  valid_599824 = validateParameter(valid_599824, JString, required = true,
                                 default = nil)
  if valid_599824 != nil:
    section.add "Path", valid_599824
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
  var valid_599832 = header.getOrDefault("Range")
  valid_599832 = validateParameter(valid_599832, JString, required = false,
                                 default = nil)
  if valid_599832 != nil:
    section.add "Range", valid_599832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599855: Call_GetObject_599696; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ## 
  let valid = call_599855.validator(path, query, header, formData, body)
  let scheme = call_599855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599855.url(scheme.get, call_599855.host, call_599855.base,
                         call_599855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599855, url, valid)

proc call*(call_599926: Call_GetObject_599696; Path: string): Recallable =
  ## getObject
  ## Downloads the object at the specified path. If the object’s upload availability is set to <code>streaming</code>, AWS Elemental MediaStore downloads the object even if it’s still uploading the object.
  ##   Path: string (required)
  ##       : <p>The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;</p> <p>For example, to upload the file <code>mlaw.avi</code> to the folder path <code>premium\canada</code> in the container <code>movies</code>, enter the path <code>premium/canada/mlaw.avi</code>.</p> <p>Do not include the container name in this path.</p> <p>If the path includes any folders that don't exist yet, the service creates them. For example, suppose you have an existing <code>premium/usa</code> subfolder. If you specify <code>premium/canada</code>, the service creates a <code>canada</code> subfolder in the <code>premium</code> folder. You then have two subfolders, <code>usa</code> and <code>canada</code>, in the <code>premium</code> folder. </p> <p>There is no correlation between the path to the source and the path (folders) in the container in AWS Elemental MediaStore.</p> <p>For more information about folders and how they exist in a container, see the <a href="http://docs.aws.amazon.com/mediastore/latest/ug/">AWS Elemental MediaStore User Guide</a>.</p> <p>The file name is the name that is assigned to the file that you upload. The file can have the same name inside and outside of AWS Elemental MediaStore, or it can have the same name. The file name can include or omit an extension. </p>
  var path_599927 = newJObject()
  add(path_599927, "Path", newJString(Path))
  result = call_599926.call(path_599927, nil, nil, nil, nil)

var getObject* = Call_GetObject_599696(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/{Path}",
                                    validator: validate_GetObject_599697,
                                    base: "/", url: url_GetObject_599698,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_600000 = ref object of OpenApiRestCall_599359
proc url_DeleteObject_600002(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObject_600001(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600003 = path.getOrDefault("Path")
  valid_600003 = validateParameter(valid_600003, JString, required = true,
                                 default = nil)
  if valid_600003 != nil:
    section.add "Path", valid_600003
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
  var valid_600004 = header.getOrDefault("X-Amz-Date")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Date", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Security-Token")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Security-Token", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Content-Sha256", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Algorithm")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Algorithm", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Signature")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Signature", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-SignedHeaders", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Credential")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Credential", valid_600010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600011: Call_DeleteObject_600000; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object at the specified path.
  ## 
  let valid = call_600011.validator(path, query, header, formData, body)
  let scheme = call_600011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600011.url(scheme.get, call_600011.host, call_600011.base,
                         call_600011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600011, url, valid)

proc call*(call_600012: Call_DeleteObject_600000; Path: string): Recallable =
  ## deleteObject
  ## Deletes an object at the specified path.
  ##   Path: string (required)
  ##       : The path (including the file name) where the object is stored in the container. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  var path_600013 = newJObject()
  add(path_600013, "Path", newJString(Path))
  result = call_600012.call(path_600013, nil, nil, nil, nil)

var deleteObject* = Call_DeleteObject_600000(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "data.mediastore.amazonaws.com",
    route: "/{Path}", validator: validate_DeleteObject_600001, base: "/",
    url: url_DeleteObject_600002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListItems_600028 = ref object of OpenApiRestCall_599359
proc url_ListItems_600030(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListItems_600029(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600031 = query.getOrDefault("NextToken")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "NextToken", valid_600031
  var valid_600032 = query.getOrDefault("Path")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "Path", valid_600032
  var valid_600033 = query.getOrDefault("MaxResults")
  valid_600033 = validateParameter(valid_600033, JInt, required = false, default = nil)
  if valid_600033 != nil:
    section.add "MaxResults", valid_600033
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
  var valid_600034 = header.getOrDefault("X-Amz-Date")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Date", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Security-Token")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Security-Token", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Content-Sha256", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Algorithm")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Algorithm", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Signature")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Signature", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-SignedHeaders", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Credential")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Credential", valid_600040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600041: Call_ListItems_600028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ## 
  let valid = call_600041.validator(path, query, header, formData, body)
  let scheme = call_600041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600041.url(scheme.get, call_600041.host, call_600041.base,
                         call_600041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600041, url, valid)

proc call*(call_600042: Call_ListItems_600028; NextToken: string = "";
          Path: string = ""; MaxResults: int = 0): Recallable =
  ## listItems
  ## Provides a list of metadata entries about folders and objects in the specified folder.
  ##   NextToken: string
  ##            : <p>The token that identifies which batch of results that you want to see. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. The service returns the first batch of results (up to 500) and a <code>NextToken</code> value. To see the next batch of results, you can submit the <code>ListItems</code> request a second time and specify the <code>NextToken</code> value.</p> <p>Tokens expire after 15 minutes.</p>
  ##   Path: string
  ##       : The path in the container from which to retrieve items. Format: &lt;folder name&gt;/&lt;folder name&gt;/&lt;file name&gt;
  ##   MaxResults: int
  ##             : <p>The maximum number of results to return per API request. For example, you submit a <code>ListItems</code> request with <code>MaxResults</code> set at 500. Although 2,000 items match your request, the service returns no more than the first 500 items. (The service also returns a <code>NextToken</code> value that you can use to fetch the next batch of results.) The service might return fewer results than the <code>MaxResults</code> value.</p> <p>If <code>MaxResults</code> is not included in the request, the service defaults to pagination with a maximum of 1,000 results per page.</p>
  var query_600043 = newJObject()
  add(query_600043, "NextToken", newJString(NextToken))
  add(query_600043, "Path", newJString(Path))
  add(query_600043, "MaxResults", newJInt(MaxResults))
  result = call_600042.call(nil, query_600043, nil, nil, nil)

var listItems* = Call_ListItems_600028(name: "listItems", meth: HttpMethod.HttpGet,
                                    host: "data.mediastore.amazonaws.com",
                                    route: "/", validator: validate_ListItems_600029,
                                    base: "/", url: url_ListItems_600030,
                                    schemes: {Scheme.Https, Scheme.Http})
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
