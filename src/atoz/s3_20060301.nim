
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Storage Service
## version: 2006-03-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p/>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/s3/
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

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "s3-ap-northeast-1.amazonaws.com",
                           "ap-southeast-1": "s3-ap-southeast-1.amazonaws.com",
                           "us-west-2": "s3-us-west-2.amazonaws.com",
                           "eu-west-2": "s3.eu-west-2.amazonaws.com",
                           "ap-northeast-3": "s3.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "s3.eu-central-1.amazonaws.com",
                           "us-east-2": "s3.us-east-2.amazonaws.com",
                           "us-east-1": "s3-us-east-1.amazonaws.com", "cn-northwest-1": "s3.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "s3.ap-south-1.amazonaws.com",
                           "eu-north-1": "s3.eu-north-1.amazonaws.com",
                           "ap-northeast-2": "s3.ap-northeast-2.amazonaws.com",
                           "us-west-1": "s3-us-west-1.amazonaws.com",
                           "us-gov-east-1": "s3.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "s3.eu-west-3.amazonaws.com",
                           "cn-north-1": "s3.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "s3-sa-east-1.amazonaws.com",
                           "eu-west-1": "s3-eu-west-1.amazonaws.com",
                           "us-gov-west-1": "s3-us-gov-west-1.amazonaws.com",
                           "ap-southeast-2": "s3-ap-southeast-2.amazonaws.com",
                           "ca-central-1": "s3.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "s3-ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "s3-ap-southeast-1.amazonaws.com",
      "us-west-2": "s3-us-west-2.amazonaws.com",
      "eu-west-2": "s3.eu-west-2.amazonaws.com",
      "ap-northeast-3": "s3.ap-northeast-3.amazonaws.com",
      "eu-central-1": "s3.eu-central-1.amazonaws.com",
      "us-east-2": "s3.us-east-2.amazonaws.com",
      "us-east-1": "s3-us-east-1.amazonaws.com",
      "cn-northwest-1": "s3.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "s3.ap-south-1.amazonaws.com",
      "eu-north-1": "s3.eu-north-1.amazonaws.com",
      "ap-northeast-2": "s3.ap-northeast-2.amazonaws.com",
      "us-west-1": "s3-us-west-1.amazonaws.com",
      "us-gov-east-1": "s3.us-gov-east-1.amazonaws.com",
      "eu-west-3": "s3.eu-west-3.amazonaws.com",
      "cn-north-1": "s3.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "s3-sa-east-1.amazonaws.com",
      "eu-west-1": "s3-eu-west-1.amazonaws.com",
      "us-gov-west-1": "s3-us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "s3-ap-southeast-2.amazonaws.com",
      "ca-central-1": "s3.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "s3"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CompleteMultipartUpload_601059 = ref object of OpenApiRestCall_600437
proc url_CompleteMultipartUpload_601061(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#uploadId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CompleteMultipartUpload_601060(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601062 = path.getOrDefault("Key")
  valid_601062 = validateParameter(valid_601062, JString, required = true,
                                 default = nil)
  if valid_601062 != nil:
    section.add "Key", valid_601062
  var valid_601063 = path.getOrDefault("Bucket")
  valid_601063 = validateParameter(valid_601063, JString, required = true,
                                 default = nil)
  if valid_601063 != nil:
    section.add "Bucket", valid_601063
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : <p/>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_601064 = query.getOrDefault("uploadId")
  valid_601064 = validateParameter(valid_601064, JString, required = true,
                                 default = nil)
  if valid_601064 != nil:
    section.add "uploadId", valid_601064
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601065 = header.getOrDefault("x-amz-security-token")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "x-amz-security-token", valid_601065
  var valid_601066 = header.getOrDefault("x-amz-request-payer")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = newJString("requester"))
  if valid_601066 != nil:
    section.add "x-amz-request-payer", valid_601066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601068: Call_CompleteMultipartUpload_601059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  let valid = call_601068.validator(path, query, header, formData, body)
  let scheme = call_601068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601068.url(scheme.get, call_601068.host, call_601068.base,
                         call_601068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601068, url, valid)

proc call*(call_601069: Call_CompleteMultipartUpload_601059; uploadId: string;
          Key: string; Bucket: string; body: JsonNode): Recallable =
  ## completeMultipartUpload
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  ##   uploadId: string (required)
  ##           : <p/>
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601070 = newJObject()
  var query_601071 = newJObject()
  var body_601072 = newJObject()
  add(query_601071, "uploadId", newJString(uploadId))
  add(path_601070, "Key", newJString(Key))
  add(path_601070, "Bucket", newJString(Bucket))
  if body != nil:
    body_601072 = body
  result = call_601069.call(path_601070, query_601071, nil, nil, body_601072)

var completeMultipartUpload* = Call_CompleteMultipartUpload_601059(
    name: "completeMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_CompleteMultipartUpload_601060, base: "/",
    url: url_CompleteMultipartUpload_601061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParts_600774 = ref object of OpenApiRestCall_600437
proc url_ListParts_600776(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#uploadId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListParts_600775(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_600902 = path.getOrDefault("Key")
  valid_600902 = validateParameter(valid_600902, JString, required = true,
                                 default = nil)
  if valid_600902 != nil:
    section.add "Key", valid_600902
  var valid_600903 = path.getOrDefault("Bucket")
  valid_600903 = validateParameter(valid_600903, JString, required = true,
                                 default = nil)
  if valid_600903 != nil:
    section.add "Bucket", valid_600903
  result.add "path", section
  ## parameters in `query` object:
  ##   max-parts: JInt
  ##            : Sets the maximum number of parts to return.
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose parts are being listed.
  ##   MaxParts: JString
  ##           : Pagination limit
  ##   part-number-marker: JInt
  ##                     : Specifies the part after which listing should begin. Only parts with higher part numbers will be listed.
  ##   PartNumberMarker: JString
  ##                   : Pagination token
  section = newJObject()
  var valid_600904 = query.getOrDefault("max-parts")
  valid_600904 = validateParameter(valid_600904, JInt, required = false, default = nil)
  if valid_600904 != nil:
    section.add "max-parts", valid_600904
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_600905 = query.getOrDefault("uploadId")
  valid_600905 = validateParameter(valid_600905, JString, required = true,
                                 default = nil)
  if valid_600905 != nil:
    section.add "uploadId", valid_600905
  var valid_600906 = query.getOrDefault("MaxParts")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "MaxParts", valid_600906
  var valid_600907 = query.getOrDefault("part-number-marker")
  valid_600907 = validateParameter(valid_600907, JInt, required = false, default = nil)
  if valid_600907 != nil:
    section.add "part-number-marker", valid_600907
  var valid_600908 = query.getOrDefault("PartNumberMarker")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "PartNumberMarker", valid_600908
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_600909 = header.getOrDefault("x-amz-security-token")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "x-amz-security-token", valid_600909
  var valid_600923 = header.getOrDefault("x-amz-request-payer")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = newJString("requester"))
  if valid_600923 != nil:
    section.add "x-amz-request-payer", valid_600923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600946: Call_ListParts_600774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  let valid = call_600946.validator(path, query, header, formData, body)
  let scheme = call_600946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600946.url(scheme.get, call_600946.host, call_600946.base,
                         call_600946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600946, url, valid)

proc call*(call_601017: Call_ListParts_600774; uploadId: string; Key: string;
          Bucket: string; maxParts: int = 0; MaxParts: string = "";
          partNumberMarker: int = 0; PartNumberMarker: string = ""): Recallable =
  ## listParts
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  ##   maxParts: int
  ##           : Sets the maximum number of parts to return.
  ##   uploadId: string (required)
  ##           : Upload ID identifying the multipart upload whose parts are being listed.
  ##   MaxParts: string
  ##           : Pagination limit
  ##   partNumberMarker: int
  ##                   : Specifies the part after which listing should begin. Only parts with higher part numbers will be listed.
  ##   PartNumberMarker: string
  ##                   : Pagination token
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601018 = newJObject()
  var query_601020 = newJObject()
  add(query_601020, "max-parts", newJInt(maxParts))
  add(query_601020, "uploadId", newJString(uploadId))
  add(query_601020, "MaxParts", newJString(MaxParts))
  add(query_601020, "part-number-marker", newJInt(partNumberMarker))
  add(query_601020, "PartNumberMarker", newJString(PartNumberMarker))
  add(path_601018, "Key", newJString(Key))
  add(path_601018, "Bucket", newJString(Bucket))
  result = call_601017.call(path_601018, query_601020, nil, nil, nil)

var listParts* = Call_ListParts_600774(name: "listParts", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}#uploadId",
                                    validator: validate_ListParts_600775,
                                    base: "/", url: url_ListParts_600776,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortMultipartUpload_601073 = ref object of OpenApiRestCall_600437
proc url_AbortMultipartUpload_601075(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#uploadId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_AbortMultipartUpload_601074(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : Key of the object for which the multipart upload was initiated.
  ##   Bucket: JString (required)
  ##         : Name of the bucket to which the multipart upload was initiated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601076 = path.getOrDefault("Key")
  valid_601076 = validateParameter(valid_601076, JString, required = true,
                                 default = nil)
  if valid_601076 != nil:
    section.add "Key", valid_601076
  var valid_601077 = path.getOrDefault("Bucket")
  valid_601077 = validateParameter(valid_601077, JString, required = true,
                                 default = nil)
  if valid_601077 != nil:
    section.add "Bucket", valid_601077
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID that identifies the multipart upload.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_601078 = query.getOrDefault("uploadId")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = nil)
  if valid_601078 != nil:
    section.add "uploadId", valid_601078
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601079 = header.getOrDefault("x-amz-security-token")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "x-amz-security-token", valid_601079
  var valid_601080 = header.getOrDefault("x-amz-request-payer")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = newJString("requester"))
  if valid_601080 != nil:
    section.add "x-amz-request-payer", valid_601080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601081: Call_AbortMultipartUpload_601073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  let valid = call_601081.validator(path, query, header, formData, body)
  let scheme = call_601081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601081.url(scheme.get, call_601081.host, call_601081.base,
                         call_601081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601081, url, valid)

proc call*(call_601082: Call_AbortMultipartUpload_601073; uploadId: string;
          Key: string; Bucket: string): Recallable =
  ## abortMultipartUpload
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  ##   uploadId: string (required)
  ##           : Upload ID that identifies the multipart upload.
  ##   Key: string (required)
  ##      : Key of the object for which the multipart upload was initiated.
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the multipart upload was initiated.
  var path_601083 = newJObject()
  var query_601084 = newJObject()
  add(query_601084, "uploadId", newJString(uploadId))
  add(path_601083, "Key", newJString(Key))
  add(path_601083, "Bucket", newJString(Bucket))
  result = call_601082.call(path_601083, query_601084, nil, nil, nil)

var abortMultipartUpload* = Call_AbortMultipartUpload_601073(
    name: "abortMultipartUpload", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_AbortMultipartUpload_601074, base: "/",
    url: url_AbortMultipartUpload_601075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyObject_601085 = ref object of OpenApiRestCall_600437
proc url_CopyObject_601087(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#x-amz-copy-source")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CopyObject_601086(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601088 = path.getOrDefault("Key")
  valid_601088 = validateParameter(valid_601088, JString, required = true,
                                 default = nil)
  if valid_601088 != nil:
    section.add "Key", valid_601088
  var valid_601089 = path.getOrDefault("Bucket")
  valid_601089 = validateParameter(valid_601089, JString, required = true,
                                 default = nil)
  if valid_601089 != nil:
    section.add "Bucket", valid_601089
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Content-Disposition: JString
  ##                      : Specifies presentational information for the object.
  ##   x-amz-copy-source-server-side-encryption-customer-algorithm: JString
  ##                                                              : Specifies the algorithm to use when decrypting the source object (e.g., AES256).
  ##   x-amz-grant-full-control: JString
  ##                           : Gives the grantee READ, READ_ACP, and WRITE_ACP permissions on the object.
  ##   x-amz-security-token: JString
  ##   x-amz-copy-source-if-modified-since: JString
  ##                                      : Copies the object if it has been modified since the specified time.
  ##   x-amz-copy-source-server-side-encryption-customer-key-MD5: JString
  ##                                                            : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-tagging-directive: JString
  ##                          : Specifies whether the object tag-set are copied from the source object or replaced with tag-set provided in the request.
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-object-lock-mode: JString
  ##                         : The object lock mode that you want to apply to the copied object.
  ##   Cache-Control: JString
  ##                : Specifies caching behavior along the request/reply chain.
  ##   Content-Language: JString
  ##                   : The language the content is in.
  ##   Content-Type: JString
  ##               : A standard MIME type describing the format of the object data.
  ##   Expires: JString
  ##          : The date and time at which the object is no longer cacheable.
  ##   x-amz-website-redirect-location: JString
  ##                                  : If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata.
  ##   x-amz-copy-source-server-side-encryption-customer-key: JString
  ##                                                        : Specifies the customer-provided encryption key for Amazon S3 to use to decrypt the source object. The encryption key provided in this header must be one that was used when the source object was created.
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the object.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to read the object data and its metadata.
  ##   x-amz-storage-class: JString
  ##                      : The type of storage to use for the object. Defaults to 'STANDARD'.
  ##   x-amz-object-lock-legal-hold: JString
  ##                               : Specifies whether you want to apply a Legal Hold to the copied object.
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  ##   x-amz-tagging: JString
  ##                : The tag-set for the object destination object this value must be used in conjunction with the TaggingDirective. The tag-set must be encoded as URL Query parameters
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the object ACL.
  ##   x-amz-copy-source: JString (required)
  ##                    : The name of the source bucket and key name of the source object, separated by a slash (/). Must be URL-encoded.
  ##   x-amz-server-side-encryption-context: JString
  ##                                       : Specifies the AWS KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs.
  ##   x-amz-server-side-encryption-aws-kms-key-id: JString
  ##                                              : Specifies the AWS KMS key ID to use for object encryption. All GET and PUT requests for an object protected by AWS KMS will fail if not made via SSL or using SigV4. Documentation on configuring any of the officially supported AWS SDKs and CLI can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
  ##   x-amz-object-lock-retain-until-date: JString
  ##                                      : The date and time when you want the copied object's object lock to expire.
  ##   x-amz-metadata-directive: JString
  ##                           : Specifies whether the metadata is copied from the source object or replaced with metadata provided in the request.
  ##   x-amz-copy-source-if-match: JString
  ##                             : Copies the object if its entity tag (ETag) matches the specified tag.
  ##   x-amz-copy-source-if-unmodified-since: JString
  ##                                        : Copies the object if it hasn't been modified since the specified time.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable object.
  ##   Content-Encoding: JString
  ##                   : Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   x-amz-copy-source-if-none-match: JString
  ##                                  : Copies the object if its entity tag (ETag) is different than the specified ETag.
  ##   x-amz-server-side-encryption: JString
  ##                               : The Server-side encryption algorithm used when storing this object in S3 (e.g., AES256, aws:kms).
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header.
  section = newJObject()
  var valid_601090 = header.getOrDefault("Content-Disposition")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "Content-Disposition", valid_601090
  var valid_601091 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_601091
  var valid_601092 = header.getOrDefault("x-amz-grant-full-control")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "x-amz-grant-full-control", valid_601092
  var valid_601093 = header.getOrDefault("x-amz-security-token")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "x-amz-security-token", valid_601093
  var valid_601094 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_601094
  var valid_601095 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_601095
  var valid_601096 = header.getOrDefault("x-amz-tagging-directive")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = newJString("COPY"))
  if valid_601096 != nil:
    section.add "x-amz-tagging-directive", valid_601096
  var valid_601097 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_601097
  var valid_601098 = header.getOrDefault("x-amz-object-lock-mode")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_601098 != nil:
    section.add "x-amz-object-lock-mode", valid_601098
  var valid_601099 = header.getOrDefault("Cache-Control")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "Cache-Control", valid_601099
  var valid_601100 = header.getOrDefault("Content-Language")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "Content-Language", valid_601100
  var valid_601101 = header.getOrDefault("Content-Type")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "Content-Type", valid_601101
  var valid_601102 = header.getOrDefault("Expires")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "Expires", valid_601102
  var valid_601103 = header.getOrDefault("x-amz-website-redirect-location")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "x-amz-website-redirect-location", valid_601103
  var valid_601104 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_601104
  var valid_601105 = header.getOrDefault("x-amz-acl")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = newJString("private"))
  if valid_601105 != nil:
    section.add "x-amz-acl", valid_601105
  var valid_601106 = header.getOrDefault("x-amz-grant-read")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "x-amz-grant-read", valid_601106
  var valid_601107 = header.getOrDefault("x-amz-storage-class")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_601107 != nil:
    section.add "x-amz-storage-class", valid_601107
  var valid_601108 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = newJString("ON"))
  if valid_601108 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_601108
  var valid_601109 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_601109
  var valid_601110 = header.getOrDefault("x-amz-tagging")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "x-amz-tagging", valid_601110
  var valid_601111 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "x-amz-grant-read-acp", valid_601111
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_601112 = header.getOrDefault("x-amz-copy-source")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = nil)
  if valid_601112 != nil:
    section.add "x-amz-copy-source", valid_601112
  var valid_601113 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "x-amz-server-side-encryption-context", valid_601113
  var valid_601114 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_601114
  var valid_601115 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_601115
  var valid_601116 = header.getOrDefault("x-amz-metadata-directive")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = newJString("COPY"))
  if valid_601116 != nil:
    section.add "x-amz-metadata-directive", valid_601116
  var valid_601117 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "x-amz-copy-source-if-match", valid_601117
  var valid_601118 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_601118
  var valid_601119 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "x-amz-grant-write-acp", valid_601119
  var valid_601120 = header.getOrDefault("Content-Encoding")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "Content-Encoding", valid_601120
  var valid_601121 = header.getOrDefault("x-amz-request-payer")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = newJString("requester"))
  if valid_601121 != nil:
    section.add "x-amz-request-payer", valid_601121
  var valid_601122 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_601122
  var valid_601123 = header.getOrDefault("x-amz-server-side-encryption")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = newJString("AES256"))
  if valid_601123 != nil:
    section.add "x-amz-server-side-encryption", valid_601123
  var valid_601124 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_601124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601126: Call_CopyObject_601085; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  let valid = call_601126.validator(path, query, header, formData, body)
  let scheme = call_601126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601126.url(scheme.get, call_601126.host, call_601126.base,
                         call_601126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601126, url, valid)

proc call*(call_601127: Call_CopyObject_601085; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## copyObject
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601128 = newJObject()
  var body_601129 = newJObject()
  add(path_601128, "Key", newJString(Key))
  add(path_601128, "Bucket", newJString(Bucket))
  if body != nil:
    body_601129 = body
  result = call_601127.call(path_601128, nil, nil, nil, body_601129)

var copyObject* = Call_CopyObject_601085(name: "copyObject",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#x-amz-copy-source",
                                      validator: validate_CopyObject_601086,
                                      base: "/", url: url_CopyObject_601087,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBucket_601147 = ref object of OpenApiRestCall_600437
proc url_CreateBucket_601149(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateBucket_601148(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601150 = path.getOrDefault("Bucket")
  valid_601150 = validateParameter(valid_601150, JString, required = true,
                                 default = nil)
  if valid_601150 != nil:
    section.add "Bucket", valid_601150
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the bucket.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to list the objects in the bucket.
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the bucket ACL.
  ##   x-amz-bucket-object-lock-enabled: JBool
  ##                                   : Specifies whether you want Amazon S3 object lock to be enabled for the new bucket.
  ##   x-amz-grant-write: JString
  ##                    : Allows grantee to create, overwrite, and delete any object in the bucket.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable bucket.
  ##   x-amz-grant-full-control: JString
  ##                           : Allows grantee the read, write, read ACP, and write ACP permissions on the bucket.
  section = newJObject()
  var valid_601151 = header.getOrDefault("x-amz-security-token")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "x-amz-security-token", valid_601151
  var valid_601152 = header.getOrDefault("x-amz-acl")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = newJString("private"))
  if valid_601152 != nil:
    section.add "x-amz-acl", valid_601152
  var valid_601153 = header.getOrDefault("x-amz-grant-read")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "x-amz-grant-read", valid_601153
  var valid_601154 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "x-amz-grant-read-acp", valid_601154
  var valid_601155 = header.getOrDefault("x-amz-bucket-object-lock-enabled")
  valid_601155 = validateParameter(valid_601155, JBool, required = false, default = nil)
  if valid_601155 != nil:
    section.add "x-amz-bucket-object-lock-enabled", valid_601155
  var valid_601156 = header.getOrDefault("x-amz-grant-write")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "x-amz-grant-write", valid_601156
  var valid_601157 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "x-amz-grant-write-acp", valid_601157
  var valid_601158 = header.getOrDefault("x-amz-grant-full-control")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "x-amz-grant-full-control", valid_601158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601160: Call_CreateBucket_601147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  let valid = call_601160.validator(path, query, header, formData, body)
  let scheme = call_601160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601160.url(scheme.get, call_601160.host, call_601160.base,
                         call_601160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601160, url, valid)

proc call*(call_601161: Call_CreateBucket_601147; Bucket: string; body: JsonNode): Recallable =
  ## createBucket
  ## Creates a new bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601162 = newJObject()
  var body_601163 = newJObject()
  add(path_601162, "Bucket", newJString(Bucket))
  if body != nil:
    body_601163 = body
  result = call_601161.call(path_601162, nil, nil, nil, body_601163)

var createBucket* = Call_CreateBucket_601147(name: "createBucket",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_CreateBucket_601148, base: "/", url: url_CreateBucket_601149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadBucket_601172 = ref object of OpenApiRestCall_600437
proc url_HeadBucket_601174(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_HeadBucket_601173(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601175 = path.getOrDefault("Bucket")
  valid_601175 = validateParameter(valid_601175, JString, required = true,
                                 default = nil)
  if valid_601175 != nil:
    section.add "Bucket", valid_601175
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601176 = header.getOrDefault("x-amz-security-token")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "x-amz-security-token", valid_601176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601177: Call_HeadBucket_601172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  let valid = call_601177.validator(path, query, header, formData, body)
  let scheme = call_601177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601177.url(scheme.get, call_601177.host, call_601177.base,
                         call_601177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601177, url, valid)

proc call*(call_601178: Call_HeadBucket_601172; Bucket: string): Recallable =
  ## headBucket
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601179 = newJObject()
  add(path_601179, "Bucket", newJString(Bucket))
  result = call_601178.call(path_601179, nil, nil, nil, nil)

var headBucket* = Call_HeadBucket_601172(name: "headBucket",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}",
                                      validator: validate_HeadBucket_601173,
                                      base: "/", url: url_HeadBucket_601174,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjects_601130 = ref object of OpenApiRestCall_600437
proc url_ListObjects_601132(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListObjects_601131(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601133 = path.getOrDefault("Bucket")
  valid_601133 = validateParameter(valid_601133, JString, required = true,
                                 default = nil)
  if valid_601133 != nil:
    section.add "Bucket", valid_601133
  result.add "path", section
  ## parameters in `query` object:
  ##   max-keys: JInt
  ##           : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   encoding-type: JString
  ##                : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   marker: JString
  ##         : Specifies the key to start with when listing objects in a bucket.
  ##   Marker: JString
  ##         : Pagination token
  ##   delimiter: JString
  ##            : A delimiter is a character you use to group keys.
  ##   prefix: JString
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   MaxKeys: JString
  ##          : Pagination limit
  section = newJObject()
  var valid_601134 = query.getOrDefault("max-keys")
  valid_601134 = validateParameter(valid_601134, JInt, required = false, default = nil)
  if valid_601134 != nil:
    section.add "max-keys", valid_601134
  var valid_601135 = query.getOrDefault("encoding-type")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = newJString("url"))
  if valid_601135 != nil:
    section.add "encoding-type", valid_601135
  var valid_601136 = query.getOrDefault("marker")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "marker", valid_601136
  var valid_601137 = query.getOrDefault("Marker")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "Marker", valid_601137
  var valid_601138 = query.getOrDefault("delimiter")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "delimiter", valid_601138
  var valid_601139 = query.getOrDefault("prefix")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "prefix", valid_601139
  var valid_601140 = query.getOrDefault("MaxKeys")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "MaxKeys", valid_601140
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601141 = header.getOrDefault("x-amz-security-token")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "x-amz-security-token", valid_601141
  var valid_601142 = header.getOrDefault("x-amz-request-payer")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = newJString("requester"))
  if valid_601142 != nil:
    section.add "x-amz-request-payer", valid_601142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601143: Call_ListObjects_601130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
  let valid = call_601143.validator(path, query, header, formData, body)
  let scheme = call_601143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601143.url(scheme.get, call_601143.host, call_601143.base,
                         call_601143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601143, url, valid)

proc call*(call_601144: Call_ListObjects_601130; Bucket: string; maxKeys: int = 0;
          encodingType: string = "url"; marker: string = ""; Marker: string = "";
          delimiter: string = ""; prefix: string = ""; MaxKeys: string = ""): Recallable =
  ## listObjects
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
  ##   maxKeys: int
  ##          : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   encodingType: string
  ##               : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   marker: string
  ##         : Specifies the key to start with when listing objects in a bucket.
  ##   Marker: string
  ##         : Pagination token
  ##   delimiter: string
  ##            : A delimiter is a character you use to group keys.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   prefix: string
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   MaxKeys: string
  ##          : Pagination limit
  var path_601145 = newJObject()
  var query_601146 = newJObject()
  add(query_601146, "max-keys", newJInt(maxKeys))
  add(query_601146, "encoding-type", newJString(encodingType))
  add(query_601146, "marker", newJString(marker))
  add(query_601146, "Marker", newJString(Marker))
  add(query_601146, "delimiter", newJString(delimiter))
  add(path_601145, "Bucket", newJString(Bucket))
  add(query_601146, "prefix", newJString(prefix))
  add(query_601146, "MaxKeys", newJString(MaxKeys))
  result = call_601144.call(path_601145, query_601146, nil, nil, nil)

var listObjects* = Call_ListObjects_601130(name: "listObjects",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com",
                                        route: "/{Bucket}",
                                        validator: validate_ListObjects_601131,
                                        base: "/", url: url_ListObjects_601132,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucket_601164 = ref object of OpenApiRestCall_600437
proc url_DeleteBucket_601166(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBucket_601165(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601167 = path.getOrDefault("Bucket")
  valid_601167 = validateParameter(valid_601167, JString, required = true,
                                 default = nil)
  if valid_601167 != nil:
    section.add "Bucket", valid_601167
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601168 = header.getOrDefault("x-amz-security-token")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "x-amz-security-token", valid_601168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_DeleteBucket_601164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_DeleteBucket_601164; Bucket: string): Recallable =
  ## deleteBucket
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601171 = newJObject()
  add(path_601171, "Bucket", newJString(Bucket))
  result = call_601170.call(path_601171, nil, nil, nil, nil)

var deleteBucket* = Call_DeleteBucket_601164(name: "deleteBucket",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_DeleteBucket_601165, base: "/", url: url_DeleteBucket_601166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultipartUpload_601180 = ref object of OpenApiRestCall_600437
proc url_CreateMultipartUpload_601182(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#uploads")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateMultipartUpload_601181(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601183 = path.getOrDefault("Key")
  valid_601183 = validateParameter(valid_601183, JString, required = true,
                                 default = nil)
  if valid_601183 != nil:
    section.add "Key", valid_601183
  var valid_601184 = path.getOrDefault("Bucket")
  valid_601184 = validateParameter(valid_601184, JString, required = true,
                                 default = nil)
  if valid_601184 != nil:
    section.add "Bucket", valid_601184
  result.add "path", section
  ## parameters in `query` object:
  ##   uploads: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_601185 = query.getOrDefault("uploads")
  valid_601185 = validateParameter(valid_601185, JBool, required = true, default = nil)
  if valid_601185 != nil:
    section.add "uploads", valid_601185
  result.add "query", section
  ## parameters in `header` object:
  ##   Content-Disposition: JString
  ##                      : Specifies presentational information for the object.
  ##   x-amz-grant-full-control: JString
  ##                           : Gives the grantee READ, READ_ACP, and WRITE_ACP permissions on the object.
  ##   x-amz-security-token: JString
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-object-lock-mode: JString
  ##                         : Specifies the object lock mode that you want to apply to the uploaded object.
  ##   Cache-Control: JString
  ##                : Specifies caching behavior along the request/reply chain.
  ##   Content-Language: JString
  ##                   : The language the content is in.
  ##   Content-Type: JString
  ##               : A standard MIME type describing the format of the object data.
  ##   Expires: JString
  ##          : The date and time at which the object is no longer cacheable.
  ##   x-amz-website-redirect-location: JString
  ##                                  : If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata.
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the object.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to read the object data and its metadata.
  ##   x-amz-storage-class: JString
  ##                      : The type of storage to use for the object. Defaults to 'STANDARD'.
  ##   x-amz-object-lock-legal-hold: JString
  ##                               : Specifies whether you want to apply a Legal Hold to the uploaded object.
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  ##   x-amz-tagging: JString
  ##                : The tag-set for the object. The tag-set must be encoded as URL Query parameters
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the object ACL.
  ##   x-amz-server-side-encryption-context: JString
  ##                                       : Specifies the AWS KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs.
  ##   x-amz-server-side-encryption-aws-kms-key-id: JString
  ##                                              : Specifies the AWS KMS key ID to use for object encryption. All GET and PUT requests for an object protected by AWS KMS will fail if not made via SSL or using SigV4. Documentation on configuring any of the officially supported AWS SDKs and CLI can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
  ##   x-amz-object-lock-retain-until-date: JString
  ##                                      : Specifies the date and time when you want the object lock to expire.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable object.
  ##   Content-Encoding: JString
  ##                   : Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   x-amz-server-side-encryption: JString
  ##                               : The Server-side encryption algorithm used when storing this object in S3 (e.g., AES256, aws:kms).
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header.
  section = newJObject()
  var valid_601186 = header.getOrDefault("Content-Disposition")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "Content-Disposition", valid_601186
  var valid_601187 = header.getOrDefault("x-amz-grant-full-control")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "x-amz-grant-full-control", valid_601187
  var valid_601188 = header.getOrDefault("x-amz-security-token")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "x-amz-security-token", valid_601188
  var valid_601189 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_601189
  var valid_601190 = header.getOrDefault("x-amz-object-lock-mode")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_601190 != nil:
    section.add "x-amz-object-lock-mode", valid_601190
  var valid_601191 = header.getOrDefault("Cache-Control")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "Cache-Control", valid_601191
  var valid_601192 = header.getOrDefault("Content-Language")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "Content-Language", valid_601192
  var valid_601193 = header.getOrDefault("Content-Type")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "Content-Type", valid_601193
  var valid_601194 = header.getOrDefault("Expires")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "Expires", valid_601194
  var valid_601195 = header.getOrDefault("x-amz-website-redirect-location")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "x-amz-website-redirect-location", valid_601195
  var valid_601196 = header.getOrDefault("x-amz-acl")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = newJString("private"))
  if valid_601196 != nil:
    section.add "x-amz-acl", valid_601196
  var valid_601197 = header.getOrDefault("x-amz-grant-read")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "x-amz-grant-read", valid_601197
  var valid_601198 = header.getOrDefault("x-amz-storage-class")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_601198 != nil:
    section.add "x-amz-storage-class", valid_601198
  var valid_601199 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = newJString("ON"))
  if valid_601199 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_601199
  var valid_601200 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_601200
  var valid_601201 = header.getOrDefault("x-amz-tagging")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "x-amz-tagging", valid_601201
  var valid_601202 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "x-amz-grant-read-acp", valid_601202
  var valid_601203 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "x-amz-server-side-encryption-context", valid_601203
  var valid_601204 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_601204
  var valid_601205 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_601205
  var valid_601206 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "x-amz-grant-write-acp", valid_601206
  var valid_601207 = header.getOrDefault("Content-Encoding")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "Content-Encoding", valid_601207
  var valid_601208 = header.getOrDefault("x-amz-request-payer")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = newJString("requester"))
  if valid_601208 != nil:
    section.add "x-amz-request-payer", valid_601208
  var valid_601209 = header.getOrDefault("x-amz-server-side-encryption")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = newJString("AES256"))
  if valid_601209 != nil:
    section.add "x-amz-server-side-encryption", valid_601209
  var valid_601210 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_601210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601212: Call_CreateMultipartUpload_601180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  let valid = call_601212.validator(path, query, header, formData, body)
  let scheme = call_601212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601212.url(scheme.get, call_601212.host, call_601212.base,
                         call_601212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601212, url, valid)

proc call*(call_601213: Call_CreateMultipartUpload_601180; Key: string;
          uploads: bool; Bucket: string; body: JsonNode): Recallable =
  ## createMultipartUpload
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  ##   Key: string (required)
  ##      : <p/>
  ##   uploads: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601214 = newJObject()
  var query_601215 = newJObject()
  var body_601216 = newJObject()
  add(path_601214, "Key", newJString(Key))
  add(query_601215, "uploads", newJBool(uploads))
  add(path_601214, "Bucket", newJString(Bucket))
  if body != nil:
    body_601216 = body
  result = call_601213.call(path_601214, query_601215, nil, nil, body_601216)

var createMultipartUpload* = Call_CreateMultipartUpload_601180(
    name: "createMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploads",
    validator: validate_CreateMultipartUpload_601181, base: "/",
    url: url_CreateMultipartUpload_601182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAnalyticsConfiguration_601228 = ref object of OpenApiRestCall_600437
proc url_PutBucketAnalyticsConfiguration_601230(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#analytics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketAnalyticsConfiguration_601229(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket to which an analytics configuration is stored.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601231 = path.getOrDefault("Bucket")
  valid_601231 = validateParameter(valid_601231, JString, required = true,
                                 default = nil)
  if valid_601231 != nil:
    section.add "Bucket", valid_601231
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601232 = query.getOrDefault("id")
  valid_601232 = validateParameter(valid_601232, JString, required = true,
                                 default = nil)
  if valid_601232 != nil:
    section.add "id", valid_601232
  var valid_601233 = query.getOrDefault("analytics")
  valid_601233 = validateParameter(valid_601233, JBool, required = true, default = nil)
  if valid_601233 != nil:
    section.add "analytics", valid_601233
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601234 = header.getOrDefault("x-amz-security-token")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "x-amz-security-token", valid_601234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601236: Call_PutBucketAnalyticsConfiguration_601228;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_601236.validator(path, query, header, formData, body)
  let scheme = call_601236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601236.url(scheme.get, call_601236.host, call_601236.base,
                         call_601236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601236, url, valid)

proc call*(call_601237: Call_PutBucketAnalyticsConfiguration_601228; id: string;
          analytics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAnalyticsConfiguration
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket to which an analytics configuration is stored.
  ##   body: JObject (required)
  var path_601238 = newJObject()
  var query_601239 = newJObject()
  var body_601240 = newJObject()
  add(query_601239, "id", newJString(id))
  add(query_601239, "analytics", newJBool(analytics))
  add(path_601238, "Bucket", newJString(Bucket))
  if body != nil:
    body_601240 = body
  result = call_601237.call(path_601238, query_601239, nil, nil, body_601240)

var putBucketAnalyticsConfiguration* = Call_PutBucketAnalyticsConfiguration_601228(
    name: "putBucketAnalyticsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_PutBucketAnalyticsConfiguration_601229, base: "/",
    url: url_PutBucketAnalyticsConfiguration_601230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAnalyticsConfiguration_601217 = ref object of OpenApiRestCall_600437
proc url_GetBucketAnalyticsConfiguration_601219(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#analytics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketAnalyticsConfiguration_601218(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket from which an analytics configuration is retrieved.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601220 = path.getOrDefault("Bucket")
  valid_601220 = validateParameter(valid_601220, JString, required = true,
                                 default = nil)
  if valid_601220 != nil:
    section.add "Bucket", valid_601220
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601221 = query.getOrDefault("id")
  valid_601221 = validateParameter(valid_601221, JString, required = true,
                                 default = nil)
  if valid_601221 != nil:
    section.add "id", valid_601221
  var valid_601222 = query.getOrDefault("analytics")
  valid_601222 = validateParameter(valid_601222, JBool, required = true, default = nil)
  if valid_601222 != nil:
    section.add "analytics", valid_601222
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601223 = header.getOrDefault("x-amz-security-token")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "x-amz-security-token", valid_601223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601224: Call_GetBucketAnalyticsConfiguration_601217;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_601224.validator(path, query, header, formData, body)
  let scheme = call_601224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601224.url(scheme.get, call_601224.host, call_601224.base,
                         call_601224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601224, url, valid)

proc call*(call_601225: Call_GetBucketAnalyticsConfiguration_601217; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## getBucketAnalyticsConfiguration
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is retrieved.
  var path_601226 = newJObject()
  var query_601227 = newJObject()
  add(query_601227, "id", newJString(id))
  add(query_601227, "analytics", newJBool(analytics))
  add(path_601226, "Bucket", newJString(Bucket))
  result = call_601225.call(path_601226, query_601227, nil, nil, nil)

var getBucketAnalyticsConfiguration* = Call_GetBucketAnalyticsConfiguration_601217(
    name: "getBucketAnalyticsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_GetBucketAnalyticsConfiguration_601218, base: "/",
    url: url_GetBucketAnalyticsConfiguration_601219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketAnalyticsConfiguration_601241 = ref object of OpenApiRestCall_600437
proc url_DeleteBucketAnalyticsConfiguration_601243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#analytics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBucketAnalyticsConfiguration_601242(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket from which an analytics configuration is deleted.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601244 = path.getOrDefault("Bucket")
  valid_601244 = validateParameter(valid_601244, JString, required = true,
                                 default = nil)
  if valid_601244 != nil:
    section.add "Bucket", valid_601244
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601245 = query.getOrDefault("id")
  valid_601245 = validateParameter(valid_601245, JString, required = true,
                                 default = nil)
  if valid_601245 != nil:
    section.add "id", valid_601245
  var valid_601246 = query.getOrDefault("analytics")
  valid_601246 = validateParameter(valid_601246, JBool, required = true, default = nil)
  if valid_601246 != nil:
    section.add "analytics", valid_601246
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601247 = header.getOrDefault("x-amz-security-token")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "x-amz-security-token", valid_601247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601248: Call_DeleteBucketAnalyticsConfiguration_601241;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ## 
  let valid = call_601248.validator(path, query, header, formData, body)
  let scheme = call_601248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601248.url(scheme.get, call_601248.host, call_601248.base,
                         call_601248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601248, url, valid)

proc call*(call_601249: Call_DeleteBucketAnalyticsConfiguration_601241; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## deleteBucketAnalyticsConfiguration
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is deleted.
  var path_601250 = newJObject()
  var query_601251 = newJObject()
  add(query_601251, "id", newJString(id))
  add(query_601251, "analytics", newJBool(analytics))
  add(path_601250, "Bucket", newJString(Bucket))
  result = call_601249.call(path_601250, query_601251, nil, nil, nil)

var deleteBucketAnalyticsConfiguration* = Call_DeleteBucketAnalyticsConfiguration_601241(
    name: "deleteBucketAnalyticsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_DeleteBucketAnalyticsConfiguration_601242, base: "/",
    url: url_DeleteBucketAnalyticsConfiguration_601243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketCors_601262 = ref object of OpenApiRestCall_600437
proc url_PutBucketCors_601264(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#cors")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketCors_601263(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the CORS configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601265 = path.getOrDefault("Bucket")
  valid_601265 = validateParameter(valid_601265, JString, required = true,
                                 default = nil)
  if valid_601265 != nil:
    section.add "Bucket", valid_601265
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_601266 = query.getOrDefault("cors")
  valid_601266 = validateParameter(valid_601266, JBool, required = true, default = nil)
  if valid_601266 != nil:
    section.add "cors", valid_601266
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601267 = header.getOrDefault("x-amz-security-token")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "x-amz-security-token", valid_601267
  var valid_601268 = header.getOrDefault("Content-MD5")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "Content-MD5", valid_601268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601270: Call_PutBucketCors_601262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the CORS configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  let valid = call_601270.validator(path, query, header, formData, body)
  let scheme = call_601270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601270.url(scheme.get, call_601270.host, call_601270.base,
                         call_601270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601270, url, valid)

proc call*(call_601271: Call_PutBucketCors_601262; cors: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketCors
  ## Sets the CORS configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601272 = newJObject()
  var query_601273 = newJObject()
  var body_601274 = newJObject()
  add(query_601273, "cors", newJBool(cors))
  add(path_601272, "Bucket", newJString(Bucket))
  if body != nil:
    body_601274 = body
  result = call_601271.call(path_601272, query_601273, nil, nil, body_601274)

var putBucketCors* = Call_PutBucketCors_601262(name: "putBucketCors",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_PutBucketCors_601263, base: "/", url: url_PutBucketCors_601264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketCors_601252 = ref object of OpenApiRestCall_600437
proc url_GetBucketCors_601254(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#cors")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketCors_601253(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the CORS configuration for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601255 = path.getOrDefault("Bucket")
  valid_601255 = validateParameter(valid_601255, JString, required = true,
                                 default = nil)
  if valid_601255 != nil:
    section.add "Bucket", valid_601255
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_601256 = query.getOrDefault("cors")
  valid_601256 = validateParameter(valid_601256, JBool, required = true, default = nil)
  if valid_601256 != nil:
    section.add "cors", valid_601256
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601257 = header.getOrDefault("x-amz-security-token")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "x-amz-security-token", valid_601257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601258: Call_GetBucketCors_601252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the CORS configuration for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  let valid = call_601258.validator(path, query, header, formData, body)
  let scheme = call_601258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601258.url(scheme.get, call_601258.host, call_601258.base,
                         call_601258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601258, url, valid)

proc call*(call_601259: Call_GetBucketCors_601252; cors: bool; Bucket: string): Recallable =
  ## getBucketCors
  ## Returns the CORS configuration for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601260 = newJObject()
  var query_601261 = newJObject()
  add(query_601261, "cors", newJBool(cors))
  add(path_601260, "Bucket", newJString(Bucket))
  result = call_601259.call(path_601260, query_601261, nil, nil, nil)

var getBucketCors* = Call_GetBucketCors_601252(name: "getBucketCors",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_GetBucketCors_601253, base: "/", url: url_GetBucketCors_601254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketCors_601275 = ref object of OpenApiRestCall_600437
proc url_DeleteBucketCors_601277(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#cors")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBucketCors_601276(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes the CORS configuration information set for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601278 = path.getOrDefault("Bucket")
  valid_601278 = validateParameter(valid_601278, JString, required = true,
                                 default = nil)
  if valid_601278 != nil:
    section.add "Bucket", valid_601278
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_601279 = query.getOrDefault("cors")
  valid_601279 = validateParameter(valid_601279, JBool, required = true, default = nil)
  if valid_601279 != nil:
    section.add "cors", valid_601279
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601280 = header.getOrDefault("x-amz-security-token")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "x-amz-security-token", valid_601280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601281: Call_DeleteBucketCors_601275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the CORS configuration information set for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  let valid = call_601281.validator(path, query, header, formData, body)
  let scheme = call_601281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601281.url(scheme.get, call_601281.host, call_601281.base,
                         call_601281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601281, url, valid)

proc call*(call_601282: Call_DeleteBucketCors_601275; cors: bool; Bucket: string): Recallable =
  ## deleteBucketCors
  ## Deletes the CORS configuration information set for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601283 = newJObject()
  var query_601284 = newJObject()
  add(query_601284, "cors", newJBool(cors))
  add(path_601283, "Bucket", newJString(Bucket))
  result = call_601282.call(path_601283, query_601284, nil, nil, nil)

var deleteBucketCors* = Call_DeleteBucketCors_601275(name: "deleteBucketCors",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_DeleteBucketCors_601276, base: "/",
    url: url_DeleteBucketCors_601277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketEncryption_601295 = ref object of OpenApiRestCall_600437
proc url_PutBucketEncryption_601297(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#encryption")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketEncryption_601296(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : Specifies default encryption for a bucket using server-side encryption with Amazon S3-managed keys (SSE-S3) or AWS KMS-managed keys (SSE-KMS). For information about the Amazon S3 default encryption feature, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 Default Bucket Encryption</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601298 = path.getOrDefault("Bucket")
  valid_601298 = validateParameter(valid_601298, JString, required = true,
                                 default = nil)
  if valid_601298 != nil:
    section.add "Bucket", valid_601298
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_601299 = query.getOrDefault("encryption")
  valid_601299 = validateParameter(valid_601299, JBool, required = true, default = nil)
  if valid_601299 != nil:
    section.add "encryption", valid_601299
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the server-side encryption configuration. This parameter is auto-populated when using the command from the CLI.
  section = newJObject()
  var valid_601300 = header.getOrDefault("x-amz-security-token")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "x-amz-security-token", valid_601300
  var valid_601301 = header.getOrDefault("Content-MD5")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "Content-MD5", valid_601301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601303: Call_PutBucketEncryption_601295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ## 
  let valid = call_601303.validator(path, query, header, formData, body)
  let scheme = call_601303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601303.url(scheme.get, call_601303.host, call_601303.base,
                         call_601303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601303, url, valid)

proc call*(call_601304: Call_PutBucketEncryption_601295; encryption: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketEncryption
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : Specifies default encryption for a bucket using server-side encryption with Amazon S3-managed keys (SSE-S3) or AWS KMS-managed keys (SSE-KMS). For information about the Amazon S3 default encryption feature, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 Default Bucket Encryption</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   body: JObject (required)
  var path_601305 = newJObject()
  var query_601306 = newJObject()
  var body_601307 = newJObject()
  add(query_601306, "encryption", newJBool(encryption))
  add(path_601305, "Bucket", newJString(Bucket))
  if body != nil:
    body_601307 = body
  result = call_601304.call(path_601305, query_601306, nil, nil, body_601307)

var putBucketEncryption* = Call_PutBucketEncryption_601295(
    name: "putBucketEncryption", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_PutBucketEncryption_601296,
    base: "/", url: url_PutBucketEncryption_601297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketEncryption_601285 = ref object of OpenApiRestCall_600437
proc url_GetBucketEncryption_601287(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#encryption")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketEncryption_601286(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns the server-side encryption configuration of a bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket from which the server-side encryption configuration is retrieved.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601288 = path.getOrDefault("Bucket")
  valid_601288 = validateParameter(valid_601288, JString, required = true,
                                 default = nil)
  if valid_601288 != nil:
    section.add "Bucket", valid_601288
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_601289 = query.getOrDefault("encryption")
  valid_601289 = validateParameter(valid_601289, JBool, required = true, default = nil)
  if valid_601289 != nil:
    section.add "encryption", valid_601289
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601290 = header.getOrDefault("x-amz-security-token")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "x-amz-security-token", valid_601290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601291: Call_GetBucketEncryption_601285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the server-side encryption configuration of a bucket.
  ## 
  let valid = call_601291.validator(path, query, header, formData, body)
  let scheme = call_601291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601291.url(scheme.get, call_601291.host, call_601291.base,
                         call_601291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601291, url, valid)

proc call*(call_601292: Call_GetBucketEncryption_601285; encryption: bool;
          Bucket: string): Recallable =
  ## getBucketEncryption
  ## Returns the server-side encryption configuration of a bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which the server-side encryption configuration is retrieved.
  var path_601293 = newJObject()
  var query_601294 = newJObject()
  add(query_601294, "encryption", newJBool(encryption))
  add(path_601293, "Bucket", newJString(Bucket))
  result = call_601292.call(path_601293, query_601294, nil, nil, nil)

var getBucketEncryption* = Call_GetBucketEncryption_601285(
    name: "getBucketEncryption", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_GetBucketEncryption_601286,
    base: "/", url: url_GetBucketEncryption_601287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketEncryption_601308 = ref object of OpenApiRestCall_600437
proc url_DeleteBucketEncryption_601310(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#encryption")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBucketEncryption_601309(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the server-side encryption configuration from the bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket containing the server-side encryption configuration to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601311 = path.getOrDefault("Bucket")
  valid_601311 = validateParameter(valid_601311, JString, required = true,
                                 default = nil)
  if valid_601311 != nil:
    section.add "Bucket", valid_601311
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_601312 = query.getOrDefault("encryption")
  valid_601312 = validateParameter(valid_601312, JBool, required = true, default = nil)
  if valid_601312 != nil:
    section.add "encryption", valid_601312
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601313 = header.getOrDefault("x-amz-security-token")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "x-amz-security-token", valid_601313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601314: Call_DeleteBucketEncryption_601308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the server-side encryption configuration from the bucket.
  ## 
  let valid = call_601314.validator(path, query, header, formData, body)
  let scheme = call_601314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601314.url(scheme.get, call_601314.host, call_601314.base,
                         call_601314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601314, url, valid)

proc call*(call_601315: Call_DeleteBucketEncryption_601308; encryption: bool;
          Bucket: string): Recallable =
  ## deleteBucketEncryption
  ## Deletes the server-side encryption configuration from the bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the server-side encryption configuration to delete.
  var path_601316 = newJObject()
  var query_601317 = newJObject()
  add(query_601317, "encryption", newJBool(encryption))
  add(path_601316, "Bucket", newJString(Bucket))
  result = call_601315.call(path_601316, query_601317, nil, nil, nil)

var deleteBucketEncryption* = Call_DeleteBucketEncryption_601308(
    name: "deleteBucketEncryption", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#encryption",
    validator: validate_DeleteBucketEncryption_601309, base: "/",
    url: url_DeleteBucketEncryption_601310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketInventoryConfiguration_601329 = ref object of OpenApiRestCall_600437
proc url_PutBucketInventoryConfiguration_601331(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#inventory&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketInventoryConfiguration_601330(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket where the inventory configuration will be stored.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601332 = path.getOrDefault("Bucket")
  valid_601332 = validateParameter(valid_601332, JString, required = true,
                                 default = nil)
  if valid_601332 != nil:
    section.add "Bucket", valid_601332
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_601333 = query.getOrDefault("inventory")
  valid_601333 = validateParameter(valid_601333, JBool, required = true, default = nil)
  if valid_601333 != nil:
    section.add "inventory", valid_601333
  var valid_601334 = query.getOrDefault("id")
  valid_601334 = validateParameter(valid_601334, JString, required = true,
                                 default = nil)
  if valid_601334 != nil:
    section.add "id", valid_601334
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601335 = header.getOrDefault("x-amz-security-token")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "x-amz-security-token", valid_601335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601337: Call_PutBucketInventoryConfiguration_601329;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_601337.validator(path, query, header, formData, body)
  let scheme = call_601337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601337.url(scheme.get, call_601337.host, call_601337.base,
                         call_601337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601337, url, valid)

proc call*(call_601338: Call_PutBucketInventoryConfiguration_601329;
          inventory: bool; id: string; Bucket: string; body: JsonNode): Recallable =
  ## putBucketInventoryConfiguration
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket where the inventory configuration will be stored.
  ##   body: JObject (required)
  var path_601339 = newJObject()
  var query_601340 = newJObject()
  var body_601341 = newJObject()
  add(query_601340, "inventory", newJBool(inventory))
  add(query_601340, "id", newJString(id))
  add(path_601339, "Bucket", newJString(Bucket))
  if body != nil:
    body_601341 = body
  result = call_601338.call(path_601339, query_601340, nil, nil, body_601341)

var putBucketInventoryConfiguration* = Call_PutBucketInventoryConfiguration_601329(
    name: "putBucketInventoryConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_PutBucketInventoryConfiguration_601330, base: "/",
    url: url_PutBucketInventoryConfiguration_601331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketInventoryConfiguration_601318 = ref object of OpenApiRestCall_600437
proc url_GetBucketInventoryConfiguration_601320(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#inventory&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketInventoryConfiguration_601319(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket containing the inventory configuration to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601321 = path.getOrDefault("Bucket")
  valid_601321 = validateParameter(valid_601321, JString, required = true,
                                 default = nil)
  if valid_601321 != nil:
    section.add "Bucket", valid_601321
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_601322 = query.getOrDefault("inventory")
  valid_601322 = validateParameter(valid_601322, JBool, required = true, default = nil)
  if valid_601322 != nil:
    section.add "inventory", valid_601322
  var valid_601323 = query.getOrDefault("id")
  valid_601323 = validateParameter(valid_601323, JString, required = true,
                                 default = nil)
  if valid_601323 != nil:
    section.add "id", valid_601323
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601324 = header.getOrDefault("x-amz-security-token")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "x-amz-security-token", valid_601324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601325: Call_GetBucketInventoryConfiguration_601318;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_601325.validator(path, query, header, formData, body)
  let scheme = call_601325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601325.url(scheme.get, call_601325.host, call_601325.base,
                         call_601325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601325, url, valid)

proc call*(call_601326: Call_GetBucketInventoryConfiguration_601318;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## getBucketInventoryConfiguration
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to retrieve.
  var path_601327 = newJObject()
  var query_601328 = newJObject()
  add(query_601328, "inventory", newJBool(inventory))
  add(query_601328, "id", newJString(id))
  add(path_601327, "Bucket", newJString(Bucket))
  result = call_601326.call(path_601327, query_601328, nil, nil, nil)

var getBucketInventoryConfiguration* = Call_GetBucketInventoryConfiguration_601318(
    name: "getBucketInventoryConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_GetBucketInventoryConfiguration_601319, base: "/",
    url: url_GetBucketInventoryConfiguration_601320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketInventoryConfiguration_601342 = ref object of OpenApiRestCall_600437
proc url_DeleteBucketInventoryConfiguration_601344(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#inventory&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBucketInventoryConfiguration_601343(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket containing the inventory configuration to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601345 = path.getOrDefault("Bucket")
  valid_601345 = validateParameter(valid_601345, JString, required = true,
                                 default = nil)
  if valid_601345 != nil:
    section.add "Bucket", valid_601345
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_601346 = query.getOrDefault("inventory")
  valid_601346 = validateParameter(valid_601346, JBool, required = true, default = nil)
  if valid_601346 != nil:
    section.add "inventory", valid_601346
  var valid_601347 = query.getOrDefault("id")
  valid_601347 = validateParameter(valid_601347, JString, required = true,
                                 default = nil)
  if valid_601347 != nil:
    section.add "id", valid_601347
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601348 = header.getOrDefault("x-amz-security-token")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "x-amz-security-token", valid_601348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_DeleteBucketInventoryConfiguration_601342;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_DeleteBucketInventoryConfiguration_601342;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## deleteBucketInventoryConfiguration
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to delete.
  var path_601351 = newJObject()
  var query_601352 = newJObject()
  add(query_601352, "inventory", newJBool(inventory))
  add(query_601352, "id", newJString(id))
  add(path_601351, "Bucket", newJString(Bucket))
  result = call_601350.call(path_601351, query_601352, nil, nil, nil)

var deleteBucketInventoryConfiguration* = Call_DeleteBucketInventoryConfiguration_601342(
    name: "deleteBucketInventoryConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_DeleteBucketInventoryConfiguration_601343, base: "/",
    url: url_DeleteBucketInventoryConfiguration_601344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycleConfiguration_601363 = ref object of OpenApiRestCall_600437
proc url_PutBucketLifecycleConfiguration_601365(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#lifecycle")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketLifecycleConfiguration_601364(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601366 = path.getOrDefault("Bucket")
  valid_601366 = validateParameter(valid_601366, JString, required = true,
                                 default = nil)
  if valid_601366 != nil:
    section.add "Bucket", valid_601366
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_601367 = query.getOrDefault("lifecycle")
  valid_601367 = validateParameter(valid_601367, JBool, required = true, default = nil)
  if valid_601367 != nil:
    section.add "lifecycle", valid_601367
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601368 = header.getOrDefault("x-amz-security-token")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "x-amz-security-token", valid_601368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601370: Call_PutBucketLifecycleConfiguration_601363;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ## 
  let valid = call_601370.validator(path, query, header, formData, body)
  let scheme = call_601370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601370.url(scheme.get, call_601370.host, call_601370.base,
                         call_601370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601370, url, valid)

proc call*(call_601371: Call_PutBucketLifecycleConfiguration_601363;
          Bucket: string; lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycleConfiguration
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_601372 = newJObject()
  var query_601373 = newJObject()
  var body_601374 = newJObject()
  add(path_601372, "Bucket", newJString(Bucket))
  add(query_601373, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_601374 = body
  result = call_601371.call(path_601372, query_601373, nil, nil, body_601374)

var putBucketLifecycleConfiguration* = Call_PutBucketLifecycleConfiguration_601363(
    name: "putBucketLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_PutBucketLifecycleConfiguration_601364, base: "/",
    url: url_PutBucketLifecycleConfiguration_601365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycleConfiguration_601353 = ref object of OpenApiRestCall_600437
proc url_GetBucketLifecycleConfiguration_601355(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#lifecycle")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketLifecycleConfiguration_601354(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the lifecycle configuration information set on the bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601356 = path.getOrDefault("Bucket")
  valid_601356 = validateParameter(valid_601356, JString, required = true,
                                 default = nil)
  if valid_601356 != nil:
    section.add "Bucket", valid_601356
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_601357 = query.getOrDefault("lifecycle")
  valid_601357 = validateParameter(valid_601357, JBool, required = true, default = nil)
  if valid_601357 != nil:
    section.add "lifecycle", valid_601357
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601358 = header.getOrDefault("x-amz-security-token")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "x-amz-security-token", valid_601358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601359: Call_GetBucketLifecycleConfiguration_601353;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the lifecycle configuration information set on the bucket.
  ## 
  let valid = call_601359.validator(path, query, header, formData, body)
  let scheme = call_601359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601359.url(scheme.get, call_601359.host, call_601359.base,
                         call_601359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601359, url, valid)

proc call*(call_601360: Call_GetBucketLifecycleConfiguration_601353;
          Bucket: string; lifecycle: bool): Recallable =
  ## getBucketLifecycleConfiguration
  ## Returns the lifecycle configuration information set on the bucket.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_601361 = newJObject()
  var query_601362 = newJObject()
  add(path_601361, "Bucket", newJString(Bucket))
  add(query_601362, "lifecycle", newJBool(lifecycle))
  result = call_601360.call(path_601361, query_601362, nil, nil, nil)

var getBucketLifecycleConfiguration* = Call_GetBucketLifecycleConfiguration_601353(
    name: "getBucketLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_GetBucketLifecycleConfiguration_601354, base: "/",
    url: url_GetBucketLifecycleConfiguration_601355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketLifecycle_601375 = ref object of OpenApiRestCall_600437
proc url_DeleteBucketLifecycle_601377(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#lifecycle")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBucketLifecycle_601376(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the lifecycle configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601378 = path.getOrDefault("Bucket")
  valid_601378 = validateParameter(valid_601378, JString, required = true,
                                 default = nil)
  if valid_601378 != nil:
    section.add "Bucket", valid_601378
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_601379 = query.getOrDefault("lifecycle")
  valid_601379 = validateParameter(valid_601379, JBool, required = true, default = nil)
  if valid_601379 != nil:
    section.add "lifecycle", valid_601379
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601380 = header.getOrDefault("x-amz-security-token")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "x-amz-security-token", valid_601380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601381: Call_DeleteBucketLifecycle_601375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the lifecycle configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  let valid = call_601381.validator(path, query, header, formData, body)
  let scheme = call_601381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601381.url(scheme.get, call_601381.host, call_601381.base,
                         call_601381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601381, url, valid)

proc call*(call_601382: Call_DeleteBucketLifecycle_601375; Bucket: string;
          lifecycle: bool): Recallable =
  ## deleteBucketLifecycle
  ## Deletes the lifecycle configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_601383 = newJObject()
  var query_601384 = newJObject()
  add(path_601383, "Bucket", newJString(Bucket))
  add(query_601384, "lifecycle", newJBool(lifecycle))
  result = call_601382.call(path_601383, query_601384, nil, nil, nil)

var deleteBucketLifecycle* = Call_DeleteBucketLifecycle_601375(
    name: "deleteBucketLifecycle", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_DeleteBucketLifecycle_601376, base: "/",
    url: url_DeleteBucketLifecycle_601377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketMetricsConfiguration_601396 = ref object of OpenApiRestCall_600437
proc url_PutBucketMetricsConfiguration_601398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#metrics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketMetricsConfiguration_601397(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket for which the metrics configuration is set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601399 = path.getOrDefault("Bucket")
  valid_601399 = validateParameter(valid_601399, JString, required = true,
                                 default = nil)
  if valid_601399 != nil:
    section.add "Bucket", valid_601399
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601400 = query.getOrDefault("id")
  valid_601400 = validateParameter(valid_601400, JString, required = true,
                                 default = nil)
  if valid_601400 != nil:
    section.add "id", valid_601400
  var valid_601401 = query.getOrDefault("metrics")
  valid_601401 = validateParameter(valid_601401, JBool, required = true, default = nil)
  if valid_601401 != nil:
    section.add "metrics", valid_601401
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601402 = header.getOrDefault("x-amz-security-token")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "x-amz-security-token", valid_601402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601404: Call_PutBucketMetricsConfiguration_601396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ## 
  let valid = call_601404.validator(path, query, header, formData, body)
  let scheme = call_601404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601404.url(scheme.get, call_601404.host, call_601404.base,
                         call_601404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601404, url, valid)

proc call*(call_601405: Call_PutBucketMetricsConfiguration_601396; id: string;
          metrics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketMetricsConfiguration
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket for which the metrics configuration is set.
  ##   body: JObject (required)
  var path_601406 = newJObject()
  var query_601407 = newJObject()
  var body_601408 = newJObject()
  add(query_601407, "id", newJString(id))
  add(query_601407, "metrics", newJBool(metrics))
  add(path_601406, "Bucket", newJString(Bucket))
  if body != nil:
    body_601408 = body
  result = call_601405.call(path_601406, query_601407, nil, nil, body_601408)

var putBucketMetricsConfiguration* = Call_PutBucketMetricsConfiguration_601396(
    name: "putBucketMetricsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_PutBucketMetricsConfiguration_601397, base: "/",
    url: url_PutBucketMetricsConfiguration_601398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketMetricsConfiguration_601385 = ref object of OpenApiRestCall_600437
proc url_GetBucketMetricsConfiguration_601387(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#metrics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketMetricsConfiguration_601386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket containing the metrics configuration to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601388 = path.getOrDefault("Bucket")
  valid_601388 = validateParameter(valid_601388, JString, required = true,
                                 default = nil)
  if valid_601388 != nil:
    section.add "Bucket", valid_601388
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601389 = query.getOrDefault("id")
  valid_601389 = validateParameter(valid_601389, JString, required = true,
                                 default = nil)
  if valid_601389 != nil:
    section.add "id", valid_601389
  var valid_601390 = query.getOrDefault("metrics")
  valid_601390 = validateParameter(valid_601390, JBool, required = true, default = nil)
  if valid_601390 != nil:
    section.add "metrics", valid_601390
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601391 = header.getOrDefault("x-amz-security-token")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "x-amz-security-token", valid_601391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601392: Call_GetBucketMetricsConfiguration_601385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_601392.validator(path, query, header, formData, body)
  let scheme = call_601392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601392.url(scheme.get, call_601392.host, call_601392.base,
                         call_601392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601392, url, valid)

proc call*(call_601393: Call_GetBucketMetricsConfiguration_601385; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## getBucketMetricsConfiguration
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to retrieve.
  var path_601394 = newJObject()
  var query_601395 = newJObject()
  add(query_601395, "id", newJString(id))
  add(query_601395, "metrics", newJBool(metrics))
  add(path_601394, "Bucket", newJString(Bucket))
  result = call_601393.call(path_601394, query_601395, nil, nil, nil)

var getBucketMetricsConfiguration* = Call_GetBucketMetricsConfiguration_601385(
    name: "getBucketMetricsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_GetBucketMetricsConfiguration_601386, base: "/",
    url: url_GetBucketMetricsConfiguration_601387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketMetricsConfiguration_601409 = ref object of OpenApiRestCall_600437
proc url_DeleteBucketMetricsConfiguration_601411(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#metrics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBucketMetricsConfiguration_601410(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket containing the metrics configuration to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601412 = path.getOrDefault("Bucket")
  valid_601412 = validateParameter(valid_601412, JString, required = true,
                                 default = nil)
  if valid_601412 != nil:
    section.add "Bucket", valid_601412
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601413 = query.getOrDefault("id")
  valid_601413 = validateParameter(valid_601413, JString, required = true,
                                 default = nil)
  if valid_601413 != nil:
    section.add "id", valid_601413
  var valid_601414 = query.getOrDefault("metrics")
  valid_601414 = validateParameter(valid_601414, JBool, required = true, default = nil)
  if valid_601414 != nil:
    section.add "metrics", valid_601414
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601415 = header.getOrDefault("x-amz-security-token")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "x-amz-security-token", valid_601415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601416: Call_DeleteBucketMetricsConfiguration_601409;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_601416.validator(path, query, header, formData, body)
  let scheme = call_601416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601416.url(scheme.get, call_601416.host, call_601416.base,
                         call_601416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601416, url, valid)

proc call*(call_601417: Call_DeleteBucketMetricsConfiguration_601409; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## deleteBucketMetricsConfiguration
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to delete.
  var path_601418 = newJObject()
  var query_601419 = newJObject()
  add(query_601419, "id", newJString(id))
  add(query_601419, "metrics", newJBool(metrics))
  add(path_601418, "Bucket", newJString(Bucket))
  result = call_601417.call(path_601418, query_601419, nil, nil, nil)

var deleteBucketMetricsConfiguration* = Call_DeleteBucketMetricsConfiguration_601409(
    name: "deleteBucketMetricsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_DeleteBucketMetricsConfiguration_601410, base: "/",
    url: url_DeleteBucketMetricsConfiguration_601411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketPolicy_601430 = ref object of OpenApiRestCall_600437
proc url_PutBucketPolicy_601432(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketPolicy_601431(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601433 = path.getOrDefault("Bucket")
  valid_601433 = validateParameter(valid_601433, JString, required = true,
                                 default = nil)
  if valid_601433 != nil:
    section.add "Bucket", valid_601433
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_601434 = query.getOrDefault("policy")
  valid_601434 = validateParameter(valid_601434, JBool, required = true, default = nil)
  if valid_601434 != nil:
    section.add "policy", valid_601434
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-confirm-remove-self-bucket-access: JBool
  ##                                          : Set this parameter to true to confirm that you want to remove your permissions to change this bucket policy in the future.
  section = newJObject()
  var valid_601435 = header.getOrDefault("x-amz-security-token")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "x-amz-security-token", valid_601435
  var valid_601436 = header.getOrDefault("Content-MD5")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "Content-MD5", valid_601436
  var valid_601437 = header.getOrDefault("x-amz-confirm-remove-self-bucket-access")
  valid_601437 = validateParameter(valid_601437, JBool, required = false, default = nil)
  if valid_601437 != nil:
    section.add "x-amz-confirm-remove-self-bucket-access", valid_601437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601439: Call_PutBucketPolicy_601430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  let valid = call_601439.validator(path, query, header, formData, body)
  let scheme = call_601439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601439.url(scheme.get, call_601439.host, call_601439.base,
                         call_601439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601439, url, valid)

proc call*(call_601440: Call_PutBucketPolicy_601430; policy: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketPolicy
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601441 = newJObject()
  var query_601442 = newJObject()
  var body_601443 = newJObject()
  add(query_601442, "policy", newJBool(policy))
  add(path_601441, "Bucket", newJString(Bucket))
  if body != nil:
    body_601443 = body
  result = call_601440.call(path_601441, query_601442, nil, nil, body_601443)

var putBucketPolicy* = Call_PutBucketPolicy_601430(name: "putBucketPolicy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_PutBucketPolicy_601431, base: "/", url: url_PutBucketPolicy_601432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicy_601420 = ref object of OpenApiRestCall_600437
proc url_GetBucketPolicy_601422(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketPolicy_601421(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns the policy of a specified bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601423 = path.getOrDefault("Bucket")
  valid_601423 = validateParameter(valid_601423, JString, required = true,
                                 default = nil)
  if valid_601423 != nil:
    section.add "Bucket", valid_601423
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_601424 = query.getOrDefault("policy")
  valid_601424 = validateParameter(valid_601424, JBool, required = true, default = nil)
  if valid_601424 != nil:
    section.add "policy", valid_601424
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601425 = header.getOrDefault("x-amz-security-token")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "x-amz-security-token", valid_601425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601426: Call_GetBucketPolicy_601420; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the policy of a specified bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  let valid = call_601426.validator(path, query, header, formData, body)
  let scheme = call_601426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601426.url(scheme.get, call_601426.host, call_601426.base,
                         call_601426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601426, url, valid)

proc call*(call_601427: Call_GetBucketPolicy_601420; policy: bool; Bucket: string): Recallable =
  ## getBucketPolicy
  ## Returns the policy of a specified bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601428 = newJObject()
  var query_601429 = newJObject()
  add(query_601429, "policy", newJBool(policy))
  add(path_601428, "Bucket", newJString(Bucket))
  result = call_601427.call(path_601428, query_601429, nil, nil, nil)

var getBucketPolicy* = Call_GetBucketPolicy_601420(name: "getBucketPolicy",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_GetBucketPolicy_601421, base: "/", url: url_GetBucketPolicy_601422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketPolicy_601444 = ref object of OpenApiRestCall_600437
proc url_DeleteBucketPolicy_601446(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBucketPolicy_601445(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes the policy from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601447 = path.getOrDefault("Bucket")
  valid_601447 = validateParameter(valid_601447, JString, required = true,
                                 default = nil)
  if valid_601447 != nil:
    section.add "Bucket", valid_601447
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_601448 = query.getOrDefault("policy")
  valid_601448 = validateParameter(valid_601448, JBool, required = true, default = nil)
  if valid_601448 != nil:
    section.add "policy", valid_601448
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601449 = header.getOrDefault("x-amz-security-token")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "x-amz-security-token", valid_601449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601450: Call_DeleteBucketPolicy_601444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  let valid = call_601450.validator(path, query, header, formData, body)
  let scheme = call_601450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601450.url(scheme.get, call_601450.host, call_601450.base,
                         call_601450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601450, url, valid)

proc call*(call_601451: Call_DeleteBucketPolicy_601444; policy: bool; Bucket: string): Recallable =
  ## deleteBucketPolicy
  ## Deletes the policy from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601452 = newJObject()
  var query_601453 = newJObject()
  add(query_601453, "policy", newJBool(policy))
  add(path_601452, "Bucket", newJString(Bucket))
  result = call_601451.call(path_601452, query_601453, nil, nil, nil)

var deleteBucketPolicy* = Call_DeleteBucketPolicy_601444(
    name: "deleteBucketPolicy", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_DeleteBucketPolicy_601445, base: "/",
    url: url_DeleteBucketPolicy_601446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketReplication_601464 = ref object of OpenApiRestCall_600437
proc url_PutBucketReplication_601466(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#replication")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketReplication_601465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601467 = path.getOrDefault("Bucket")
  valid_601467 = validateParameter(valid_601467, JString, required = true,
                                 default = nil)
  if valid_601467 != nil:
    section.add "Bucket", valid_601467
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_601468 = query.getOrDefault("replication")
  valid_601468 = validateParameter(valid_601468, JBool, required = true, default = nil)
  if valid_601468 != nil:
    section.add "replication", valid_601468
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit.
  ##   x-amz-bucket-object-lock-token: JString
  ##                                 : A token that allows Amazon S3 object lock to be enabled for an existing bucket.
  section = newJObject()
  var valid_601469 = header.getOrDefault("x-amz-security-token")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "x-amz-security-token", valid_601469
  var valid_601470 = header.getOrDefault("Content-MD5")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "Content-MD5", valid_601470
  var valid_601471 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_601471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601473: Call_PutBucketReplication_601464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_601473.validator(path, query, header, formData, body)
  let scheme = call_601473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601473.url(scheme.get, call_601473.host, call_601473.base,
                         call_601473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601473, url, valid)

proc call*(call_601474: Call_PutBucketReplication_601464; replication: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketReplication
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601475 = newJObject()
  var query_601476 = newJObject()
  var body_601477 = newJObject()
  add(query_601476, "replication", newJBool(replication))
  add(path_601475, "Bucket", newJString(Bucket))
  if body != nil:
    body_601477 = body
  result = call_601474.call(path_601475, query_601476, nil, nil, body_601477)

var putBucketReplication* = Call_PutBucketReplication_601464(
    name: "putBucketReplication", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_PutBucketReplication_601465, base: "/",
    url: url_PutBucketReplication_601466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketReplication_601454 = ref object of OpenApiRestCall_600437
proc url_GetBucketReplication_601456(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#replication")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketReplication_601455(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601457 = path.getOrDefault("Bucket")
  valid_601457 = validateParameter(valid_601457, JString, required = true,
                                 default = nil)
  if valid_601457 != nil:
    section.add "Bucket", valid_601457
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_601458 = query.getOrDefault("replication")
  valid_601458 = validateParameter(valid_601458, JBool, required = true, default = nil)
  if valid_601458 != nil:
    section.add "replication", valid_601458
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601459 = header.getOrDefault("x-amz-security-token")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "x-amz-security-token", valid_601459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601460: Call_GetBucketReplication_601454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ## 
  let valid = call_601460.validator(path, query, header, formData, body)
  let scheme = call_601460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601460.url(scheme.get, call_601460.host, call_601460.base,
                         call_601460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601460, url, valid)

proc call*(call_601461: Call_GetBucketReplication_601454; replication: bool;
          Bucket: string): Recallable =
  ## getBucketReplication
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601462 = newJObject()
  var query_601463 = newJObject()
  add(query_601463, "replication", newJBool(replication))
  add(path_601462, "Bucket", newJString(Bucket))
  result = call_601461.call(path_601462, query_601463, nil, nil, nil)

var getBucketReplication* = Call_GetBucketReplication_601454(
    name: "getBucketReplication", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_GetBucketReplication_601455, base: "/",
    url: url_GetBucketReplication_601456, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketReplication_601478 = ref object of OpenApiRestCall_600437
proc url_DeleteBucketReplication_601480(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#replication")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBucketReplication_601479(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p> The bucket name. </p> <note> <p>It can take a while to propagate the deletion of a replication configuration to all Amazon S3 systems.</p> </note>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601481 = path.getOrDefault("Bucket")
  valid_601481 = validateParameter(valid_601481, JString, required = true,
                                 default = nil)
  if valid_601481 != nil:
    section.add "Bucket", valid_601481
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_601482 = query.getOrDefault("replication")
  valid_601482 = validateParameter(valid_601482, JBool, required = true, default = nil)
  if valid_601482 != nil:
    section.add "replication", valid_601482
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601483 = header.getOrDefault("x-amz-security-token")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "x-amz-security-token", valid_601483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601484: Call_DeleteBucketReplication_601478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_601484.validator(path, query, header, formData, body)
  let scheme = call_601484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601484.url(scheme.get, call_601484.host, call_601484.base,
                         call_601484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601484, url, valid)

proc call*(call_601485: Call_DeleteBucketReplication_601478; replication: bool;
          Bucket: string): Recallable =
  ## deleteBucketReplication
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p> The bucket name. </p> <note> <p>It can take a while to propagate the deletion of a replication configuration to all Amazon S3 systems.</p> </note>
  var path_601486 = newJObject()
  var query_601487 = newJObject()
  add(query_601487, "replication", newJBool(replication))
  add(path_601486, "Bucket", newJString(Bucket))
  result = call_601485.call(path_601486, query_601487, nil, nil, nil)

var deleteBucketReplication* = Call_DeleteBucketReplication_601478(
    name: "deleteBucketReplication", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_DeleteBucketReplication_601479, base: "/",
    url: url_DeleteBucketReplication_601480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketTagging_601498 = ref object of OpenApiRestCall_600437
proc url_PutBucketTagging_601500(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#tagging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketTagging_601499(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Sets the tags for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601501 = path.getOrDefault("Bucket")
  valid_601501 = validateParameter(valid_601501, JString, required = true,
                                 default = nil)
  if valid_601501 != nil:
    section.add "Bucket", valid_601501
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601502 = query.getOrDefault("tagging")
  valid_601502 = validateParameter(valid_601502, JBool, required = true, default = nil)
  if valid_601502 != nil:
    section.add "tagging", valid_601502
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601503 = header.getOrDefault("x-amz-security-token")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "x-amz-security-token", valid_601503
  var valid_601504 = header.getOrDefault("Content-MD5")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "Content-MD5", valid_601504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601506: Call_PutBucketTagging_601498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the tags for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  let valid = call_601506.validator(path, query, header, formData, body)
  let scheme = call_601506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601506.url(scheme.get, call_601506.host, call_601506.base,
                         call_601506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601506, url, valid)

proc call*(call_601507: Call_PutBucketTagging_601498; tagging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketTagging
  ## Sets the tags for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601508 = newJObject()
  var query_601509 = newJObject()
  var body_601510 = newJObject()
  add(query_601509, "tagging", newJBool(tagging))
  add(path_601508, "Bucket", newJString(Bucket))
  if body != nil:
    body_601510 = body
  result = call_601507.call(path_601508, query_601509, nil, nil, body_601510)

var putBucketTagging* = Call_PutBucketTagging_601498(name: "putBucketTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_PutBucketTagging_601499, base: "/",
    url: url_PutBucketTagging_601500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketTagging_601488 = ref object of OpenApiRestCall_600437
proc url_GetBucketTagging_601490(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#tagging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketTagging_601489(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the tag set associated with the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601491 = path.getOrDefault("Bucket")
  valid_601491 = validateParameter(valid_601491, JString, required = true,
                                 default = nil)
  if valid_601491 != nil:
    section.add "Bucket", valid_601491
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601492 = query.getOrDefault("tagging")
  valid_601492 = validateParameter(valid_601492, JBool, required = true, default = nil)
  if valid_601492 != nil:
    section.add "tagging", valid_601492
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601493 = header.getOrDefault("x-amz-security-token")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "x-amz-security-token", valid_601493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601494: Call_GetBucketTagging_601488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag set associated with the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  let valid = call_601494.validator(path, query, header, formData, body)
  let scheme = call_601494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601494.url(scheme.get, call_601494.host, call_601494.base,
                         call_601494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601494, url, valid)

proc call*(call_601495: Call_GetBucketTagging_601488; tagging: bool; Bucket: string): Recallable =
  ## getBucketTagging
  ## Returns the tag set associated with the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601496 = newJObject()
  var query_601497 = newJObject()
  add(query_601497, "tagging", newJBool(tagging))
  add(path_601496, "Bucket", newJString(Bucket))
  result = call_601495.call(path_601496, query_601497, nil, nil, nil)

var getBucketTagging* = Call_GetBucketTagging_601488(name: "getBucketTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_GetBucketTagging_601489, base: "/",
    url: url_GetBucketTagging_601490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketTagging_601511 = ref object of OpenApiRestCall_600437
proc url_DeleteBucketTagging_601513(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#tagging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBucketTagging_601512(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes the tags from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601514 = path.getOrDefault("Bucket")
  valid_601514 = validateParameter(valid_601514, JString, required = true,
                                 default = nil)
  if valid_601514 != nil:
    section.add "Bucket", valid_601514
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601515 = query.getOrDefault("tagging")
  valid_601515 = validateParameter(valid_601515, JBool, required = true, default = nil)
  if valid_601515 != nil:
    section.add "tagging", valid_601515
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601516 = header.getOrDefault("x-amz-security-token")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "x-amz-security-token", valid_601516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601517: Call_DeleteBucketTagging_601511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the tags from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  let valid = call_601517.validator(path, query, header, formData, body)
  let scheme = call_601517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601517.url(scheme.get, call_601517.host, call_601517.base,
                         call_601517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601517, url, valid)

proc call*(call_601518: Call_DeleteBucketTagging_601511; tagging: bool;
          Bucket: string): Recallable =
  ## deleteBucketTagging
  ## Deletes the tags from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601519 = newJObject()
  var query_601520 = newJObject()
  add(query_601520, "tagging", newJBool(tagging))
  add(path_601519, "Bucket", newJString(Bucket))
  result = call_601518.call(path_601519, query_601520, nil, nil, nil)

var deleteBucketTagging* = Call_DeleteBucketTagging_601511(
    name: "deleteBucketTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_DeleteBucketTagging_601512, base: "/",
    url: url_DeleteBucketTagging_601513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketWebsite_601531 = ref object of OpenApiRestCall_600437
proc url_PutBucketWebsite_601533(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#website")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketWebsite_601532(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Set the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601534 = path.getOrDefault("Bucket")
  valid_601534 = validateParameter(valid_601534, JString, required = true,
                                 default = nil)
  if valid_601534 != nil:
    section.add "Bucket", valid_601534
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_601535 = query.getOrDefault("website")
  valid_601535 = validateParameter(valid_601535, JBool, required = true, default = nil)
  if valid_601535 != nil:
    section.add "website", valid_601535
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601536 = header.getOrDefault("x-amz-security-token")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "x-amz-security-token", valid_601536
  var valid_601537 = header.getOrDefault("Content-MD5")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "Content-MD5", valid_601537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601539: Call_PutBucketWebsite_601531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  let valid = call_601539.validator(path, query, header, formData, body)
  let scheme = call_601539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601539.url(scheme.get, call_601539.host, call_601539.base,
                         call_601539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601539, url, valid)

proc call*(call_601540: Call_PutBucketWebsite_601531; website: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketWebsite
  ## Set the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601541 = newJObject()
  var query_601542 = newJObject()
  var body_601543 = newJObject()
  add(query_601542, "website", newJBool(website))
  add(path_601541, "Bucket", newJString(Bucket))
  if body != nil:
    body_601543 = body
  result = call_601540.call(path_601541, query_601542, nil, nil, body_601543)

var putBucketWebsite* = Call_PutBucketWebsite_601531(name: "putBucketWebsite",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_PutBucketWebsite_601532, base: "/",
    url: url_PutBucketWebsite_601533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketWebsite_601521 = ref object of OpenApiRestCall_600437
proc url_GetBucketWebsite_601523(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#website")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketWebsite_601522(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601524 = path.getOrDefault("Bucket")
  valid_601524 = validateParameter(valid_601524, JString, required = true,
                                 default = nil)
  if valid_601524 != nil:
    section.add "Bucket", valid_601524
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_601525 = query.getOrDefault("website")
  valid_601525 = validateParameter(valid_601525, JBool, required = true, default = nil)
  if valid_601525 != nil:
    section.add "website", valid_601525
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601526 = header.getOrDefault("x-amz-security-token")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "x-amz-security-token", valid_601526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601527: Call_GetBucketWebsite_601521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  let valid = call_601527.validator(path, query, header, formData, body)
  let scheme = call_601527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601527.url(scheme.get, call_601527.host, call_601527.base,
                         call_601527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601527, url, valid)

proc call*(call_601528: Call_GetBucketWebsite_601521; website: bool; Bucket: string): Recallable =
  ## getBucketWebsite
  ## Returns the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601529 = newJObject()
  var query_601530 = newJObject()
  add(query_601530, "website", newJBool(website))
  add(path_601529, "Bucket", newJString(Bucket))
  result = call_601528.call(path_601529, query_601530, nil, nil, nil)

var getBucketWebsite* = Call_GetBucketWebsite_601521(name: "getBucketWebsite",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_GetBucketWebsite_601522, base: "/",
    url: url_GetBucketWebsite_601523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketWebsite_601544 = ref object of OpenApiRestCall_600437
proc url_DeleteBucketWebsite_601546(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#website")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBucketWebsite_601545(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## This operation removes the website configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601547 = path.getOrDefault("Bucket")
  valid_601547 = validateParameter(valid_601547, JString, required = true,
                                 default = nil)
  if valid_601547 != nil:
    section.add "Bucket", valid_601547
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_601548 = query.getOrDefault("website")
  valid_601548 = validateParameter(valid_601548, JBool, required = true, default = nil)
  if valid_601548 != nil:
    section.add "website", valid_601548
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601549 = header.getOrDefault("x-amz-security-token")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "x-amz-security-token", valid_601549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601550: Call_DeleteBucketWebsite_601544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes the website configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  let valid = call_601550.validator(path, query, header, formData, body)
  let scheme = call_601550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601550.url(scheme.get, call_601550.host, call_601550.base,
                         call_601550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601550, url, valid)

proc call*(call_601551: Call_DeleteBucketWebsite_601544; website: bool;
          Bucket: string): Recallable =
  ## deleteBucketWebsite
  ## This operation removes the website configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601552 = newJObject()
  var query_601553 = newJObject()
  add(query_601553, "website", newJBool(website))
  add(path_601552, "Bucket", newJString(Bucket))
  result = call_601551.call(path_601552, query_601553, nil, nil, nil)

var deleteBucketWebsite* = Call_DeleteBucketWebsite_601544(
    name: "deleteBucketWebsite", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_DeleteBucketWebsite_601545, base: "/",
    url: url_DeleteBucketWebsite_601546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObject_601581 = ref object of OpenApiRestCall_600437
proc url_PutObject_601583(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutObject_601582(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds an object to a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : Object key for which the PUT operation was initiated.
  ##   Bucket: JString (required)
  ##         : Name of the bucket to which the PUT operation was initiated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601584 = path.getOrDefault("Key")
  valid_601584 = validateParameter(valid_601584, JString, required = true,
                                 default = nil)
  if valid_601584 != nil:
    section.add "Key", valid_601584
  var valid_601585 = path.getOrDefault("Bucket")
  valid_601585 = validateParameter(valid_601585, JString, required = true,
                                 default = nil)
  if valid_601585 != nil:
    section.add "Bucket", valid_601585
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Content-Disposition: JString
  ##                      : Specifies presentational information for the object.
  ##   x-amz-grant-full-control: JString
  ##                           : Gives the grantee READ, READ_ACP, and WRITE_ACP permissions on the object.
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the part data. This parameter is auto-populated when using the command from the CLI. This parameted is required if object lock parameters are specified.
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-object-lock-mode: JString
  ##                         : The object lock mode that you want to apply to this object.
  ##   Cache-Control: JString
  ##                : Specifies caching behavior along the request/reply chain.
  ##   Content-Language: JString
  ##                   : The language the content is in.
  ##   Content-Type: JString
  ##               : A standard MIME type describing the format of the object data.
  ##   Expires: JString
  ##          : The date and time at which the object is no longer cacheable.
  ##   x-amz-website-redirect-location: JString
  ##                                  : If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata.
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the object.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to read the object data and its metadata.
  ##   x-amz-storage-class: JString
  ##                      : The type of storage to use for the object. Defaults to 'STANDARD'.
  ##   x-amz-object-lock-legal-hold: JString
  ##                               : The Legal Hold status that you want to apply to the specified object.
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  ##   x-amz-tagging: JString
  ##                : The tag-set for the object. The tag-set must be encoded as URL Query parameters. (For example, "Key1=Value1")
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the object ACL.
  ##   Content-Length: JInt
  ##                 : Size of the body in bytes. This parameter is useful when the size of the body cannot be determined automatically.
  ##   x-amz-server-side-encryption-context: JString
  ##                                       : Specifies the AWS KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs.
  ##   x-amz-server-side-encryption-aws-kms-key-id: JString
  ##                                              : Specifies the AWS KMS key ID to use for object encryption. All GET and PUT requests for an object protected by AWS KMS will fail if not made via SSL or using SigV4. Documentation on configuring any of the officially supported AWS SDKs and CLI can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
  ##   x-amz-object-lock-retain-until-date: JString
  ##                                      : The date and time when you want this object's object lock to expire.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable object.
  ##   Content-Encoding: JString
  ##                   : Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   x-amz-server-side-encryption: JString
  ##                               : The Server-side encryption algorithm used when storing this object in S3 (e.g., AES256, aws:kms).
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header.
  section = newJObject()
  var valid_601586 = header.getOrDefault("Content-Disposition")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "Content-Disposition", valid_601586
  var valid_601587 = header.getOrDefault("x-amz-grant-full-control")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "x-amz-grant-full-control", valid_601587
  var valid_601588 = header.getOrDefault("x-amz-security-token")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "x-amz-security-token", valid_601588
  var valid_601589 = header.getOrDefault("Content-MD5")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "Content-MD5", valid_601589
  var valid_601590 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_601590
  var valid_601591 = header.getOrDefault("x-amz-object-lock-mode")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_601591 != nil:
    section.add "x-amz-object-lock-mode", valid_601591
  var valid_601592 = header.getOrDefault("Cache-Control")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "Cache-Control", valid_601592
  var valid_601593 = header.getOrDefault("Content-Language")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "Content-Language", valid_601593
  var valid_601594 = header.getOrDefault("Content-Type")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "Content-Type", valid_601594
  var valid_601595 = header.getOrDefault("Expires")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "Expires", valid_601595
  var valid_601596 = header.getOrDefault("x-amz-website-redirect-location")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "x-amz-website-redirect-location", valid_601596
  var valid_601597 = header.getOrDefault("x-amz-acl")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = newJString("private"))
  if valid_601597 != nil:
    section.add "x-amz-acl", valid_601597
  var valid_601598 = header.getOrDefault("x-amz-grant-read")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "x-amz-grant-read", valid_601598
  var valid_601599 = header.getOrDefault("x-amz-storage-class")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_601599 != nil:
    section.add "x-amz-storage-class", valid_601599
  var valid_601600 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = newJString("ON"))
  if valid_601600 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_601600
  var valid_601601 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_601601
  var valid_601602 = header.getOrDefault("x-amz-tagging")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "x-amz-tagging", valid_601602
  var valid_601603 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "x-amz-grant-read-acp", valid_601603
  var valid_601604 = header.getOrDefault("Content-Length")
  valid_601604 = validateParameter(valid_601604, JInt, required = false, default = nil)
  if valid_601604 != nil:
    section.add "Content-Length", valid_601604
  var valid_601605 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "x-amz-server-side-encryption-context", valid_601605
  var valid_601606 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_601606
  var valid_601607 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_601607
  var valid_601608 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "x-amz-grant-write-acp", valid_601608
  var valid_601609 = header.getOrDefault("Content-Encoding")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "Content-Encoding", valid_601609
  var valid_601610 = header.getOrDefault("x-amz-request-payer")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = newJString("requester"))
  if valid_601610 != nil:
    section.add "x-amz-request-payer", valid_601610
  var valid_601611 = header.getOrDefault("x-amz-server-side-encryption")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = newJString("AES256"))
  if valid_601611 != nil:
    section.add "x-amz-server-side-encryption", valid_601611
  var valid_601612 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_601612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601614: Call_PutObject_601581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an object to a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  let valid = call_601614.validator(path, query, header, formData, body)
  let scheme = call_601614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601614.url(scheme.get, call_601614.host, call_601614.base,
                         call_601614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601614, url, valid)

proc call*(call_601615: Call_PutObject_601581; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## putObject
  ## Adds an object to a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  ##   Key: string (required)
  ##      : Object key for which the PUT operation was initiated.
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the PUT operation was initiated.
  ##   body: JObject (required)
  var path_601616 = newJObject()
  var body_601617 = newJObject()
  add(path_601616, "Key", newJString(Key))
  add(path_601616, "Bucket", newJString(Bucket))
  if body != nil:
    body_601617 = body
  result = call_601615.call(path_601616, nil, nil, nil, body_601617)

var putObject* = Call_PutObject_601581(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_PutObject_601582,
                                    base: "/", url: url_PutObject_601583,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadObject_601632 = ref object of OpenApiRestCall_600437
proc url_HeadObject_601634(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_HeadObject_601633(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601635 = path.getOrDefault("Key")
  valid_601635 = validateParameter(valid_601635, JString, required = true,
                                 default = nil)
  if valid_601635 != nil:
    section.add "Key", valid_601635
  var valid_601636 = path.getOrDefault("Bucket")
  valid_601636 = validateParameter(valid_601636, JString, required = true,
                                 default = nil)
  if valid_601636 != nil:
    section.add "Bucket", valid_601636
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   partNumber: JInt
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
  section = newJObject()
  var valid_601637 = query.getOrDefault("versionId")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "versionId", valid_601637
  var valid_601638 = query.getOrDefault("partNumber")
  valid_601638 = validateParameter(valid_601638, JInt, required = false, default = nil)
  if valid_601638 != nil:
    section.add "partNumber", valid_601638
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   If-Match: JString
  ##           : Return the object only if its entity tag (ETag) is the same as the one specified, otherwise return a 412 (precondition failed).
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   If-Unmodified-Since: JString
  ##                      : Return the object only if it has not been modified since the specified time, otherwise return a 412 (precondition failed).
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  ##   If-Modified-Since: JString
  ##                    : Return the object only if it has been modified since the specified time, otherwise return a 304 (not modified).
  ##   If-None-Match: JString
  ##                : Return the object only if its entity tag (ETag) is different from the one specified, otherwise return a 304 (not modified).
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   Range: JString
  ##        : Downloads the specified range bytes of an object. For more information about the HTTP Range header, go to http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header.
  section = newJObject()
  var valid_601639 = header.getOrDefault("x-amz-security-token")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "x-amz-security-token", valid_601639
  var valid_601640 = header.getOrDefault("If-Match")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "If-Match", valid_601640
  var valid_601641 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_601641
  var valid_601642 = header.getOrDefault("If-Unmodified-Since")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "If-Unmodified-Since", valid_601642
  var valid_601643 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_601643
  var valid_601644 = header.getOrDefault("If-Modified-Since")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "If-Modified-Since", valid_601644
  var valid_601645 = header.getOrDefault("If-None-Match")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "If-None-Match", valid_601645
  var valid_601646 = header.getOrDefault("x-amz-request-payer")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = newJString("requester"))
  if valid_601646 != nil:
    section.add "x-amz-request-payer", valid_601646
  var valid_601647 = header.getOrDefault("Range")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "Range", valid_601647
  var valid_601648 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_601648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601649: Call_HeadObject_601632; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  let valid = call_601649.validator(path, query, header, formData, body)
  let scheme = call_601649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601649.url(scheme.get, call_601649.host, call_601649.base,
                         call_601649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601649, url, valid)

proc call*(call_601650: Call_HeadObject_601632; Key: string; Bucket: string;
          versionId: string = ""; partNumber: int = 0): Recallable =
  ## headObject
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  ##   versionId: string
  ##            : VersionId used to reference a specific version of the object.
  ##   partNumber: int
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601651 = newJObject()
  var query_601652 = newJObject()
  add(query_601652, "versionId", newJString(versionId))
  add(query_601652, "partNumber", newJInt(partNumber))
  add(path_601651, "Key", newJString(Key))
  add(path_601651, "Bucket", newJString(Bucket))
  result = call_601650.call(path_601651, query_601652, nil, nil, nil)

var headObject* = Call_HeadObject_601632(name: "headObject",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}/{Key}",
                                      validator: validate_HeadObject_601633,
                                      base: "/", url: url_HeadObject_601634,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_601554 = ref object of OpenApiRestCall_600437
proc url_GetObject_601556(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetObject_601555(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves objects from Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601557 = path.getOrDefault("Key")
  valid_601557 = validateParameter(valid_601557, JString, required = true,
                                 default = nil)
  if valid_601557 != nil:
    section.add "Key", valid_601557
  var valid_601558 = path.getOrDefault("Bucket")
  valid_601558 = validateParameter(valid_601558, JString, required = true,
                                 default = nil)
  if valid_601558 != nil:
    section.add "Bucket", valid_601558
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   partNumber: JInt
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' GET request for the part specified. Useful for downloading just a part of an object.
  ##   response-expires: JString
  ##                   : Sets the Expires header of the response.
  ##   response-content-language: JString
  ##                            : Sets the Content-Language header of the response.
  ##   response-content-encoding: JString
  ##                            : Sets the Content-Encoding header of the response.
  ##   response-cache-control: JString
  ##                         : Sets the Cache-Control header of the response.
  ##   response-content-disposition: JString
  ##                               : Sets the Content-Disposition header of the response
  ##   response-content-type: JString
  ##                        : Sets the Content-Type header of the response.
  section = newJObject()
  var valid_601559 = query.getOrDefault("versionId")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "versionId", valid_601559
  var valid_601560 = query.getOrDefault("partNumber")
  valid_601560 = validateParameter(valid_601560, JInt, required = false, default = nil)
  if valid_601560 != nil:
    section.add "partNumber", valid_601560
  var valid_601561 = query.getOrDefault("response-expires")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "response-expires", valid_601561
  var valid_601562 = query.getOrDefault("response-content-language")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "response-content-language", valid_601562
  var valid_601563 = query.getOrDefault("response-content-encoding")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "response-content-encoding", valid_601563
  var valid_601564 = query.getOrDefault("response-cache-control")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "response-cache-control", valid_601564
  var valid_601565 = query.getOrDefault("response-content-disposition")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "response-content-disposition", valid_601565
  var valid_601566 = query.getOrDefault("response-content-type")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "response-content-type", valid_601566
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   If-Match: JString
  ##           : Return the object only if its entity tag (ETag) is the same as the one specified, otherwise return a 412 (precondition failed).
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   If-Unmodified-Since: JString
  ##                      : Return the object only if it has not been modified since the specified time, otherwise return a 412 (precondition failed).
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  ##   If-Modified-Since: JString
  ##                    : Return the object only if it has been modified since the specified time, otherwise return a 304 (not modified).
  ##   If-None-Match: JString
  ##                : Return the object only if its entity tag (ETag) is different from the one specified, otherwise return a 304 (not modified).
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   Range: JString
  ##        : Downloads the specified range bytes of an object. For more information about the HTTP Range header, go to http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header.
  section = newJObject()
  var valid_601567 = header.getOrDefault("x-amz-security-token")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "x-amz-security-token", valid_601567
  var valid_601568 = header.getOrDefault("If-Match")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "If-Match", valid_601568
  var valid_601569 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_601569
  var valid_601570 = header.getOrDefault("If-Unmodified-Since")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "If-Unmodified-Since", valid_601570
  var valid_601571 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_601571
  var valid_601572 = header.getOrDefault("If-Modified-Since")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "If-Modified-Since", valid_601572
  var valid_601573 = header.getOrDefault("If-None-Match")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "If-None-Match", valid_601573
  var valid_601574 = header.getOrDefault("x-amz-request-payer")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = newJString("requester"))
  if valid_601574 != nil:
    section.add "x-amz-request-payer", valid_601574
  var valid_601575 = header.getOrDefault("Range")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "Range", valid_601575
  var valid_601576 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_601576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601577: Call_GetObject_601554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves objects from Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  let valid = call_601577.validator(path, query, header, formData, body)
  let scheme = call_601577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601577.url(scheme.get, call_601577.host, call_601577.base,
                         call_601577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601577, url, valid)

proc call*(call_601578: Call_GetObject_601554; Key: string; Bucket: string;
          versionId: string = ""; partNumber: int = 0; responseExpires: string = "";
          responseContentLanguage: string = "";
          responseContentEncoding: string = ""; responseCacheControl: string = "";
          responseContentDisposition: string = ""; responseContentType: string = ""): Recallable =
  ## getObject
  ## Retrieves objects from Amazon S3.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  ##   versionId: string
  ##            : VersionId used to reference a specific version of the object.
  ##   partNumber: int
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' GET request for the part specified. Useful for downloading just a part of an object.
  ##   responseExpires: string
  ##                  : Sets the Expires header of the response.
  ##   responseContentLanguage: string
  ##                          : Sets the Content-Language header of the response.
  ##   Key: string (required)
  ##      : <p/>
  ##   responseContentEncoding: string
  ##                          : Sets the Content-Encoding header of the response.
  ##   responseCacheControl: string
  ##                       : Sets the Cache-Control header of the response.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   responseContentDisposition: string
  ##                             : Sets the Content-Disposition header of the response
  ##   responseContentType: string
  ##                      : Sets the Content-Type header of the response.
  var path_601579 = newJObject()
  var query_601580 = newJObject()
  add(query_601580, "versionId", newJString(versionId))
  add(query_601580, "partNumber", newJInt(partNumber))
  add(query_601580, "response-expires", newJString(responseExpires))
  add(query_601580, "response-content-language",
      newJString(responseContentLanguage))
  add(path_601579, "Key", newJString(Key))
  add(query_601580, "response-content-encoding",
      newJString(responseContentEncoding))
  add(query_601580, "response-cache-control", newJString(responseCacheControl))
  add(path_601579, "Bucket", newJString(Bucket))
  add(query_601580, "response-content-disposition",
      newJString(responseContentDisposition))
  add(query_601580, "response-content-type", newJString(responseContentType))
  result = call_601578.call(path_601579, query_601580, nil, nil, nil)

var getObject* = Call_GetObject_601554(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_GetObject_601555,
                                    base: "/", url: url_GetObject_601556,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_601618 = ref object of OpenApiRestCall_600437
proc url_DeleteObject_601620(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteObject_601619(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601621 = path.getOrDefault("Key")
  valid_601621 = validateParameter(valid_601621, JString, required = true,
                                 default = nil)
  if valid_601621 != nil:
    section.add "Key", valid_601621
  var valid_601622 = path.getOrDefault("Bucket")
  valid_601622 = validateParameter(valid_601622, JString, required = true,
                                 default = nil)
  if valid_601622 != nil:
    section.add "Bucket", valid_601622
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  var valid_601623 = query.getOrDefault("versionId")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "versionId", valid_601623
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  ##   x-amz-bypass-governance-retention: JBool
  ##                                    : Indicates whether Amazon S3 object lock should bypass governance-mode restrictions to process this operation.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601624 = header.getOrDefault("x-amz-security-token")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "x-amz-security-token", valid_601624
  var valid_601625 = header.getOrDefault("x-amz-mfa")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "x-amz-mfa", valid_601625
  var valid_601626 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_601626 = validateParameter(valid_601626, JBool, required = false, default = nil)
  if valid_601626 != nil:
    section.add "x-amz-bypass-governance-retention", valid_601626
  var valid_601627 = header.getOrDefault("x-amz-request-payer")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = newJString("requester"))
  if valid_601627 != nil:
    section.add "x-amz-request-payer", valid_601627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601628: Call_DeleteObject_601618; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  let valid = call_601628.validator(path, query, header, formData, body)
  let scheme = call_601628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601628.url(scheme.get, call_601628.host, call_601628.base,
                         call_601628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601628, url, valid)

proc call*(call_601629: Call_DeleteObject_601618; Key: string; Bucket: string;
          versionId: string = ""): Recallable =
  ## deleteObject
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  ##   versionId: string
  ##            : VersionId used to reference a specific version of the object.
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601630 = newJObject()
  var query_601631 = newJObject()
  add(query_601631, "versionId", newJString(versionId))
  add(path_601630, "Key", newJString(Key))
  add(path_601630, "Bucket", newJString(Bucket))
  result = call_601629.call(path_601630, query_601631, nil, nil, nil)

var deleteObject* = Call_DeleteObject_601618(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}/{Key}",
    validator: validate_DeleteObject_601619, base: "/", url: url_DeleteObject_601620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectTagging_601665 = ref object of OpenApiRestCall_600437
proc url_PutObjectTagging_601667(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#tagging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutObjectTagging_601666(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601668 = path.getOrDefault("Key")
  valid_601668 = validateParameter(valid_601668, JString, required = true,
                                 default = nil)
  if valid_601668 != nil:
    section.add "Key", valid_601668
  var valid_601669 = path.getOrDefault("Bucket")
  valid_601669 = validateParameter(valid_601669, JString, required = true,
                                 default = nil)
  if valid_601669 != nil:
    section.add "Bucket", valid_601669
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_601670 = query.getOrDefault("versionId")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "versionId", valid_601670
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601671 = query.getOrDefault("tagging")
  valid_601671 = validateParameter(valid_601671, JBool, required = true, default = nil)
  if valid_601671 != nil:
    section.add "tagging", valid_601671
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601672 = header.getOrDefault("x-amz-security-token")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "x-amz-security-token", valid_601672
  var valid_601673 = header.getOrDefault("Content-MD5")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "Content-MD5", valid_601673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601675: Call_PutObjectTagging_601665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ## 
  let valid = call_601675.validator(path, query, header, formData, body)
  let scheme = call_601675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601675.url(scheme.get, call_601675.host, call_601675.base,
                         call_601675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601675, url, valid)

proc call*(call_601676: Call_PutObjectTagging_601665; tagging: bool; Key: string;
          Bucket: string; body: JsonNode; versionId: string = ""): Recallable =
  ## putObjectTagging
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ##   versionId: string
  ##            : <p/>
  ##   tagging: bool (required)
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601677 = newJObject()
  var query_601678 = newJObject()
  var body_601679 = newJObject()
  add(query_601678, "versionId", newJString(versionId))
  add(query_601678, "tagging", newJBool(tagging))
  add(path_601677, "Key", newJString(Key))
  add(path_601677, "Bucket", newJString(Bucket))
  if body != nil:
    body_601679 = body
  result = call_601676.call(path_601677, query_601678, nil, nil, body_601679)

var putObjectTagging* = Call_PutObjectTagging_601665(name: "putObjectTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_PutObjectTagging_601666,
    base: "/", url: url_PutObjectTagging_601667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTagging_601653 = ref object of OpenApiRestCall_600437
proc url_GetObjectTagging_601655(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#tagging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetObjectTagging_601654(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the tag-set of an object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601656 = path.getOrDefault("Key")
  valid_601656 = validateParameter(valid_601656, JString, required = true,
                                 default = nil)
  if valid_601656 != nil:
    section.add "Key", valid_601656
  var valid_601657 = path.getOrDefault("Bucket")
  valid_601657 = validateParameter(valid_601657, JString, required = true,
                                 default = nil)
  if valid_601657 != nil:
    section.add "Bucket", valid_601657
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_601658 = query.getOrDefault("versionId")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "versionId", valid_601658
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601659 = query.getOrDefault("tagging")
  valid_601659 = validateParameter(valid_601659, JBool, required = true, default = nil)
  if valid_601659 != nil:
    section.add "tagging", valid_601659
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601660 = header.getOrDefault("x-amz-security-token")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "x-amz-security-token", valid_601660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601661: Call_GetObjectTagging_601653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag-set of an object.
  ## 
  let valid = call_601661.validator(path, query, header, formData, body)
  let scheme = call_601661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601661.url(scheme.get, call_601661.host, call_601661.base,
                         call_601661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601661, url, valid)

proc call*(call_601662: Call_GetObjectTagging_601653; tagging: bool; Key: string;
          Bucket: string; versionId: string = ""): Recallable =
  ## getObjectTagging
  ## Returns the tag-set of an object.
  ##   versionId: string
  ##            : <p/>
  ##   tagging: bool (required)
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601663 = newJObject()
  var query_601664 = newJObject()
  add(query_601664, "versionId", newJString(versionId))
  add(query_601664, "tagging", newJBool(tagging))
  add(path_601663, "Key", newJString(Key))
  add(path_601663, "Bucket", newJString(Bucket))
  result = call_601662.call(path_601663, query_601664, nil, nil, nil)

var getObjectTagging* = Call_GetObjectTagging_601653(name: "getObjectTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_GetObjectTagging_601654,
    base: "/", url: url_GetObjectTagging_601655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjectTagging_601680 = ref object of OpenApiRestCall_600437
proc url_DeleteObjectTagging_601682(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#tagging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteObjectTagging_601681(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes the tag-set from an existing object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601683 = path.getOrDefault("Key")
  valid_601683 = validateParameter(valid_601683, JString, required = true,
                                 default = nil)
  if valid_601683 != nil:
    section.add "Key", valid_601683
  var valid_601684 = path.getOrDefault("Bucket")
  valid_601684 = validateParameter(valid_601684, JString, required = true,
                                 default = nil)
  if valid_601684 != nil:
    section.add "Bucket", valid_601684
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The versionId of the object that the tag-set will be removed from.
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_601685 = query.getOrDefault("versionId")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "versionId", valid_601685
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601686 = query.getOrDefault("tagging")
  valid_601686 = validateParameter(valid_601686, JBool, required = true, default = nil)
  if valid_601686 != nil:
    section.add "tagging", valid_601686
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601687 = header.getOrDefault("x-amz-security-token")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "x-amz-security-token", valid_601687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601688: Call_DeleteObjectTagging_601680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the tag-set from an existing object.
  ## 
  let valid = call_601688.validator(path, query, header, formData, body)
  let scheme = call_601688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601688.url(scheme.get, call_601688.host, call_601688.base,
                         call_601688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601688, url, valid)

proc call*(call_601689: Call_DeleteObjectTagging_601680; tagging: bool; Key: string;
          Bucket: string; versionId: string = ""): Recallable =
  ## deleteObjectTagging
  ## Removes the tag-set from an existing object.
  ##   versionId: string
  ##            : The versionId of the object that the tag-set will be removed from.
  ##   tagging: bool (required)
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601690 = newJObject()
  var query_601691 = newJObject()
  add(query_601691, "versionId", newJString(versionId))
  add(query_601691, "tagging", newJBool(tagging))
  add(path_601690, "Key", newJString(Key))
  add(path_601690, "Bucket", newJString(Bucket))
  result = call_601689.call(path_601690, query_601691, nil, nil, nil)

var deleteObjectTagging* = Call_DeleteObjectTagging_601680(
    name: "deleteObjectTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#tagging",
    validator: validate_DeleteObjectTagging_601681, base: "/",
    url: url_DeleteObjectTagging_601682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjects_601692 = ref object of OpenApiRestCall_600437
proc url_DeleteObjects_601694(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#delete")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteObjects_601693(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601695 = path.getOrDefault("Bucket")
  valid_601695 = validateParameter(valid_601695, JString, required = true,
                                 default = nil)
  if valid_601695 != nil:
    section.add "Bucket", valid_601695
  result.add "path", section
  ## parameters in `query` object:
  ##   delete: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `delete` field"
  var valid_601696 = query.getOrDefault("delete")
  valid_601696 = validateParameter(valid_601696, JBool, required = true, default = nil)
  if valid_601696 != nil:
    section.add "delete", valid_601696
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  ##   x-amz-bypass-governance-retention: JBool
  ##                                    : Specifies whether you want to delete this object even if it has a Governance-type object lock in place. You must have sufficient permissions to perform this operation.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601697 = header.getOrDefault("x-amz-security-token")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "x-amz-security-token", valid_601697
  var valid_601698 = header.getOrDefault("x-amz-mfa")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "x-amz-mfa", valid_601698
  var valid_601699 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_601699 = validateParameter(valid_601699, JBool, required = false, default = nil)
  if valid_601699 != nil:
    section.add "x-amz-bypass-governance-retention", valid_601699
  var valid_601700 = header.getOrDefault("x-amz-request-payer")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = newJString("requester"))
  if valid_601700 != nil:
    section.add "x-amz-request-payer", valid_601700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601702: Call_DeleteObjects_601692; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  let valid = call_601702.validator(path, query, header, formData, body)
  let scheme = call_601702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601702.url(scheme.get, call_601702.host, call_601702.base,
                         call_601702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601702, url, valid)

proc call*(call_601703: Call_DeleteObjects_601692; Bucket: string; body: JsonNode;
          delete: bool): Recallable =
  ## deleteObjects
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   delete: bool (required)
  var path_601704 = newJObject()
  var query_601705 = newJObject()
  var body_601706 = newJObject()
  add(path_601704, "Bucket", newJString(Bucket))
  if body != nil:
    body_601706 = body
  add(query_601705, "delete", newJBool(delete))
  result = call_601703.call(path_601704, query_601705, nil, nil, body_601706)

var deleteObjects* = Call_DeleteObjects_601692(name: "deleteObjects",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com", route: "/{Bucket}#delete",
    validator: validate_DeleteObjects_601693, base: "/", url: url_DeleteObjects_601694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_601717 = ref object of OpenApiRestCall_600437
proc url_PutPublicAccessBlock_601719(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#publicAccessBlock")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutPublicAccessBlock_601718(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601720 = path.getOrDefault("Bucket")
  valid_601720 = validateParameter(valid_601720, JString, required = true,
                                 default = nil)
  if valid_601720 != nil:
    section.add "Bucket", valid_601720
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_601721 = query.getOrDefault("publicAccessBlock")
  valid_601721 = validateParameter(valid_601721, JBool, required = true, default = nil)
  if valid_601721 != nil:
    section.add "publicAccessBlock", valid_601721
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash of the <code>PutPublicAccessBlock</code> request body. 
  section = newJObject()
  var valid_601722 = header.getOrDefault("x-amz-security-token")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "x-amz-security-token", valid_601722
  var valid_601723 = header.getOrDefault("Content-MD5")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "Content-MD5", valid_601723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601725: Call_PutPublicAccessBlock_601717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_601725.validator(path, query, header, formData, body)
  let scheme = call_601725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601725.url(scheme.get, call_601725.host, call_601725.base,
                         call_601725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601725, url, valid)

proc call*(call_601726: Call_PutPublicAccessBlock_601717; publicAccessBlock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to set.
  ##   body: JObject (required)
  var path_601727 = newJObject()
  var query_601728 = newJObject()
  var body_601729 = newJObject()
  add(query_601728, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_601727, "Bucket", newJString(Bucket))
  if body != nil:
    body_601729 = body
  result = call_601726.call(path_601727, query_601728, nil, nil, body_601729)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_601717(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_PutPublicAccessBlock_601718, base: "/",
    url: url_PutPublicAccessBlock_601719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_601707 = ref object of OpenApiRestCall_600437
proc url_GetPublicAccessBlock_601709(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#publicAccessBlock")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetPublicAccessBlock_601708(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to retrieve. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601710 = path.getOrDefault("Bucket")
  valid_601710 = validateParameter(valid_601710, JString, required = true,
                                 default = nil)
  if valid_601710 != nil:
    section.add "Bucket", valid_601710
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_601711 = query.getOrDefault("publicAccessBlock")
  valid_601711 = validateParameter(valid_601711, JBool, required = true, default = nil)
  if valid_601711 != nil:
    section.add "publicAccessBlock", valid_601711
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601712 = header.getOrDefault("x-amz-security-token")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "x-amz-security-token", valid_601712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601713: Call_GetPublicAccessBlock_601707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_601713.validator(path, query, header, formData, body)
  let scheme = call_601713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601713.url(scheme.get, call_601713.host, call_601713.base,
                         call_601713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601713, url, valid)

proc call*(call_601714: Call_GetPublicAccessBlock_601707; publicAccessBlock: bool;
          Bucket: string): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to retrieve. 
  var path_601715 = newJObject()
  var query_601716 = newJObject()
  add(query_601716, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_601715, "Bucket", newJString(Bucket))
  result = call_601714.call(path_601715, query_601716, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_601707(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_GetPublicAccessBlock_601708, base: "/",
    url: url_GetPublicAccessBlock_601709, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_601730 = ref object of OpenApiRestCall_600437
proc url_DeletePublicAccessBlock_601732(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#publicAccessBlock")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeletePublicAccessBlock_601731(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to delete. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601733 = path.getOrDefault("Bucket")
  valid_601733 = validateParameter(valid_601733, JString, required = true,
                                 default = nil)
  if valid_601733 != nil:
    section.add "Bucket", valid_601733
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_601734 = query.getOrDefault("publicAccessBlock")
  valid_601734 = validateParameter(valid_601734, JBool, required = true, default = nil)
  if valid_601734 != nil:
    section.add "publicAccessBlock", valid_601734
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601735 = header.getOrDefault("x-amz-security-token")
  valid_601735 = validateParameter(valid_601735, JString, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "x-amz-security-token", valid_601735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601736: Call_DeletePublicAccessBlock_601730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ## 
  let valid = call_601736.validator(path, query, header, formData, body)
  let scheme = call_601736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601736.url(scheme.get, call_601736.host, call_601736.base,
                         call_601736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601736, url, valid)

proc call*(call_601737: Call_DeletePublicAccessBlock_601730;
          publicAccessBlock: bool; Bucket: string): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to delete. 
  var path_601738 = newJObject()
  var query_601739 = newJObject()
  add(query_601739, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_601738, "Bucket", newJString(Bucket))
  result = call_601737.call(path_601738, query_601739, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_601730(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_DeletePublicAccessBlock_601731, base: "/",
    url: url_DeletePublicAccessBlock_601732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAccelerateConfiguration_601750 = ref object of OpenApiRestCall_600437
proc url_PutBucketAccelerateConfiguration_601752(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#accelerate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketAccelerateConfiguration_601751(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the accelerate configuration of an existing bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : Name of the bucket for which the accelerate configuration is set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601753 = path.getOrDefault("Bucket")
  valid_601753 = validateParameter(valid_601753, JString, required = true,
                                 default = nil)
  if valid_601753 != nil:
    section.add "Bucket", valid_601753
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_601754 = query.getOrDefault("accelerate")
  valid_601754 = validateParameter(valid_601754, JBool, required = true, default = nil)
  if valid_601754 != nil:
    section.add "accelerate", valid_601754
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601755 = header.getOrDefault("x-amz-security-token")
  valid_601755 = validateParameter(valid_601755, JString, required = false,
                                 default = nil)
  if valid_601755 != nil:
    section.add "x-amz-security-token", valid_601755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601757: Call_PutBucketAccelerateConfiguration_601750;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the accelerate configuration of an existing bucket.
  ## 
  let valid = call_601757.validator(path, query, header, formData, body)
  let scheme = call_601757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601757.url(scheme.get, call_601757.host, call_601757.base,
                         call_601757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601757, url, valid)

proc call*(call_601758: Call_PutBucketAccelerateConfiguration_601750;
          accelerate: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAccelerateConfiguration
  ## Sets the accelerate configuration of an existing bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is set.
  ##   body: JObject (required)
  var path_601759 = newJObject()
  var query_601760 = newJObject()
  var body_601761 = newJObject()
  add(query_601760, "accelerate", newJBool(accelerate))
  add(path_601759, "Bucket", newJString(Bucket))
  if body != nil:
    body_601761 = body
  result = call_601758.call(path_601759, query_601760, nil, nil, body_601761)

var putBucketAccelerateConfiguration* = Call_PutBucketAccelerateConfiguration_601750(
    name: "putBucketAccelerateConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_PutBucketAccelerateConfiguration_601751, base: "/",
    url: url_PutBucketAccelerateConfiguration_601752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAccelerateConfiguration_601740 = ref object of OpenApiRestCall_600437
proc url_GetBucketAccelerateConfiguration_601742(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#accelerate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketAccelerateConfiguration_601741(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the accelerate configuration of a bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : Name of the bucket for which the accelerate configuration is retrieved.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601743 = path.getOrDefault("Bucket")
  valid_601743 = validateParameter(valid_601743, JString, required = true,
                                 default = nil)
  if valid_601743 != nil:
    section.add "Bucket", valid_601743
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_601744 = query.getOrDefault("accelerate")
  valid_601744 = validateParameter(valid_601744, JBool, required = true, default = nil)
  if valid_601744 != nil:
    section.add "accelerate", valid_601744
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601745 = header.getOrDefault("x-amz-security-token")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "x-amz-security-token", valid_601745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601746: Call_GetBucketAccelerateConfiguration_601740;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the accelerate configuration of a bucket.
  ## 
  let valid = call_601746.validator(path, query, header, formData, body)
  let scheme = call_601746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601746.url(scheme.get, call_601746.host, call_601746.base,
                         call_601746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601746, url, valid)

proc call*(call_601747: Call_GetBucketAccelerateConfiguration_601740;
          accelerate: bool; Bucket: string): Recallable =
  ## getBucketAccelerateConfiguration
  ## Returns the accelerate configuration of a bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is retrieved.
  var path_601748 = newJObject()
  var query_601749 = newJObject()
  add(query_601749, "accelerate", newJBool(accelerate))
  add(path_601748, "Bucket", newJString(Bucket))
  result = call_601747.call(path_601748, query_601749, nil, nil, nil)

var getBucketAccelerateConfiguration* = Call_GetBucketAccelerateConfiguration_601740(
    name: "getBucketAccelerateConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_GetBucketAccelerateConfiguration_601741, base: "/",
    url: url_GetBucketAccelerateConfiguration_601742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAcl_601772 = ref object of OpenApiRestCall_600437
proc url_PutBucketAcl_601774(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#acl")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketAcl_601773(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601775 = path.getOrDefault("Bucket")
  valid_601775 = validateParameter(valid_601775, JString, required = true,
                                 default = nil)
  if valid_601775 != nil:
    section.add "Bucket", valid_601775
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_601776 = query.getOrDefault("acl")
  valid_601776 = validateParameter(valid_601776, JBool, required = true, default = nil)
  if valid_601776 != nil:
    section.add "acl", valid_601776
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the bucket.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to list the objects in the bucket.
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the bucket ACL.
  ##   x-amz-grant-write: JString
  ##                    : Allows grantee to create, overwrite, and delete any object in the bucket.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable bucket.
  ##   x-amz-grant-full-control: JString
  ##                           : Allows grantee the read, write, read ACP, and write ACP permissions on the bucket.
  section = newJObject()
  var valid_601777 = header.getOrDefault("x-amz-security-token")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "x-amz-security-token", valid_601777
  var valid_601778 = header.getOrDefault("Content-MD5")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "Content-MD5", valid_601778
  var valid_601779 = header.getOrDefault("x-amz-acl")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = newJString("private"))
  if valid_601779 != nil:
    section.add "x-amz-acl", valid_601779
  var valid_601780 = header.getOrDefault("x-amz-grant-read")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "x-amz-grant-read", valid_601780
  var valid_601781 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "x-amz-grant-read-acp", valid_601781
  var valid_601782 = header.getOrDefault("x-amz-grant-write")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "x-amz-grant-write", valid_601782
  var valid_601783 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "x-amz-grant-write-acp", valid_601783
  var valid_601784 = header.getOrDefault("x-amz-grant-full-control")
  valid_601784 = validateParameter(valid_601784, JString, required = false,
                                 default = nil)
  if valid_601784 != nil:
    section.add "x-amz-grant-full-control", valid_601784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601786: Call_PutBucketAcl_601772; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  let valid = call_601786.validator(path, query, header, formData, body)
  let scheme = call_601786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601786.url(scheme.get, call_601786.host, call_601786.base,
                         call_601786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601786, url, valid)

proc call*(call_601787: Call_PutBucketAcl_601772; acl: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketAcl
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601788 = newJObject()
  var query_601789 = newJObject()
  var body_601790 = newJObject()
  add(query_601789, "acl", newJBool(acl))
  add(path_601788, "Bucket", newJString(Bucket))
  if body != nil:
    body_601790 = body
  result = call_601787.call(path_601788, query_601789, nil, nil, body_601790)

var putBucketAcl* = Call_PutBucketAcl_601772(name: "putBucketAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_PutBucketAcl_601773, base: "/", url: url_PutBucketAcl_601774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAcl_601762 = ref object of OpenApiRestCall_600437
proc url_GetBucketAcl_601764(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#acl")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketAcl_601763(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the access control policy for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601765 = path.getOrDefault("Bucket")
  valid_601765 = validateParameter(valid_601765, JString, required = true,
                                 default = nil)
  if valid_601765 != nil:
    section.add "Bucket", valid_601765
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_601766 = query.getOrDefault("acl")
  valid_601766 = validateParameter(valid_601766, JBool, required = true, default = nil)
  if valid_601766 != nil:
    section.add "acl", valid_601766
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601767 = header.getOrDefault("x-amz-security-token")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "x-amz-security-token", valid_601767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601768: Call_GetBucketAcl_601762; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the access control policy for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  let valid = call_601768.validator(path, query, header, formData, body)
  let scheme = call_601768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601768.url(scheme.get, call_601768.host, call_601768.base,
                         call_601768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601768, url, valid)

proc call*(call_601769: Call_GetBucketAcl_601762; acl: bool; Bucket: string): Recallable =
  ## getBucketAcl
  ## Gets the access control policy for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601770 = newJObject()
  var query_601771 = newJObject()
  add(query_601771, "acl", newJBool(acl))
  add(path_601770, "Bucket", newJString(Bucket))
  result = call_601769.call(path_601770, query_601771, nil, nil, nil)

var getBucketAcl* = Call_GetBucketAcl_601762(name: "getBucketAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_GetBucketAcl_601763, base: "/", url: url_GetBucketAcl_601764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycle_601801 = ref object of OpenApiRestCall_600437
proc url_PutBucketLifecycle_601803(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#lifecycle&deprecated!")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketLifecycle_601802(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601804 = path.getOrDefault("Bucket")
  valid_601804 = validateParameter(valid_601804, JString, required = true,
                                 default = nil)
  if valid_601804 != nil:
    section.add "Bucket", valid_601804
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_601805 = query.getOrDefault("lifecycle")
  valid_601805 = validateParameter(valid_601805, JBool, required = true, default = nil)
  if valid_601805 != nil:
    section.add "lifecycle", valid_601805
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601806 = header.getOrDefault("x-amz-security-token")
  valid_601806 = validateParameter(valid_601806, JString, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "x-amz-security-token", valid_601806
  var valid_601807 = header.getOrDefault("Content-MD5")
  valid_601807 = validateParameter(valid_601807, JString, required = false,
                                 default = nil)
  if valid_601807 != nil:
    section.add "Content-MD5", valid_601807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601809: Call_PutBucketLifecycle_601801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  let valid = call_601809.validator(path, query, header, formData, body)
  let scheme = call_601809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601809.url(scheme.get, call_601809.host, call_601809.base,
                         call_601809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601809, url, valid)

proc call*(call_601810: Call_PutBucketLifecycle_601801; Bucket: string;
          lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycle
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_601811 = newJObject()
  var query_601812 = newJObject()
  var body_601813 = newJObject()
  add(path_601811, "Bucket", newJString(Bucket))
  add(query_601812, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_601813 = body
  result = call_601810.call(path_601811, query_601812, nil, nil, body_601813)

var putBucketLifecycle* = Call_PutBucketLifecycle_601801(
    name: "putBucketLifecycle", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_PutBucketLifecycle_601802, base: "/",
    url: url_PutBucketLifecycle_601803, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycle_601791 = ref object of OpenApiRestCall_600437
proc url_GetBucketLifecycle_601793(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#lifecycle&deprecated!")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketLifecycle_601792(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601794 = path.getOrDefault("Bucket")
  valid_601794 = validateParameter(valid_601794, JString, required = true,
                                 default = nil)
  if valid_601794 != nil:
    section.add "Bucket", valid_601794
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_601795 = query.getOrDefault("lifecycle")
  valid_601795 = validateParameter(valid_601795, JBool, required = true, default = nil)
  if valid_601795 != nil:
    section.add "lifecycle", valid_601795
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601796 = header.getOrDefault("x-amz-security-token")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "x-amz-security-token", valid_601796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601797: Call_GetBucketLifecycle_601791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  let valid = call_601797.validator(path, query, header, formData, body)
  let scheme = call_601797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601797.url(scheme.get, call_601797.host, call_601797.base,
                         call_601797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601797, url, valid)

proc call*(call_601798: Call_GetBucketLifecycle_601791; Bucket: string;
          lifecycle: bool): Recallable =
  ## getBucketLifecycle
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_601799 = newJObject()
  var query_601800 = newJObject()
  add(path_601799, "Bucket", newJString(Bucket))
  add(query_601800, "lifecycle", newJBool(lifecycle))
  result = call_601798.call(path_601799, query_601800, nil, nil, nil)

var getBucketLifecycle* = Call_GetBucketLifecycle_601791(
    name: "getBucketLifecycle", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_GetBucketLifecycle_601792, base: "/",
    url: url_GetBucketLifecycle_601793, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLocation_601814 = ref object of OpenApiRestCall_600437
proc url_GetBucketLocation_601816(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#location")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketLocation_601815(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns the region the bucket resides in.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601817 = path.getOrDefault("Bucket")
  valid_601817 = validateParameter(valid_601817, JString, required = true,
                                 default = nil)
  if valid_601817 != nil:
    section.add "Bucket", valid_601817
  result.add "path", section
  ## parameters in `query` object:
  ##   location: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `location` field"
  var valid_601818 = query.getOrDefault("location")
  valid_601818 = validateParameter(valid_601818, JBool, required = true, default = nil)
  if valid_601818 != nil:
    section.add "location", valid_601818
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601819 = header.getOrDefault("x-amz-security-token")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "x-amz-security-token", valid_601819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601820: Call_GetBucketLocation_601814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the region the bucket resides in.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  let valid = call_601820.validator(path, query, header, formData, body)
  let scheme = call_601820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601820.url(scheme.get, call_601820.host, call_601820.base,
                         call_601820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601820, url, valid)

proc call*(call_601821: Call_GetBucketLocation_601814; location: bool; Bucket: string): Recallable =
  ## getBucketLocation
  ## Returns the region the bucket resides in.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  ##   location: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601822 = newJObject()
  var query_601823 = newJObject()
  add(query_601823, "location", newJBool(location))
  add(path_601822, "Bucket", newJString(Bucket))
  result = call_601821.call(path_601822, query_601823, nil, nil, nil)

var getBucketLocation* = Call_GetBucketLocation_601814(name: "getBucketLocation",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#location",
    validator: validate_GetBucketLocation_601815, base: "/",
    url: url_GetBucketLocation_601816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLogging_601834 = ref object of OpenApiRestCall_600437
proc url_PutBucketLogging_601836(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#logging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketLogging_601835(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601837 = path.getOrDefault("Bucket")
  valid_601837 = validateParameter(valid_601837, JString, required = true,
                                 default = nil)
  if valid_601837 != nil:
    section.add "Bucket", valid_601837
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_601838 = query.getOrDefault("logging")
  valid_601838 = validateParameter(valid_601838, JBool, required = true, default = nil)
  if valid_601838 != nil:
    section.add "logging", valid_601838
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601839 = header.getOrDefault("x-amz-security-token")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "x-amz-security-token", valid_601839
  var valid_601840 = header.getOrDefault("Content-MD5")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "Content-MD5", valid_601840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601842: Call_PutBucketLogging_601834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  let valid = call_601842.validator(path, query, header, formData, body)
  let scheme = call_601842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601842.url(scheme.get, call_601842.host, call_601842.base,
                         call_601842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601842, url, valid)

proc call*(call_601843: Call_PutBucketLogging_601834; logging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketLogging
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601844 = newJObject()
  var query_601845 = newJObject()
  var body_601846 = newJObject()
  add(query_601845, "logging", newJBool(logging))
  add(path_601844, "Bucket", newJString(Bucket))
  if body != nil:
    body_601846 = body
  result = call_601843.call(path_601844, query_601845, nil, nil, body_601846)

var putBucketLogging* = Call_PutBucketLogging_601834(name: "putBucketLogging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_PutBucketLogging_601835, base: "/",
    url: url_PutBucketLogging_601836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLogging_601824 = ref object of OpenApiRestCall_600437
proc url_GetBucketLogging_601826(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#logging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketLogging_601825(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601827 = path.getOrDefault("Bucket")
  valid_601827 = validateParameter(valid_601827, JString, required = true,
                                 default = nil)
  if valid_601827 != nil:
    section.add "Bucket", valid_601827
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_601828 = query.getOrDefault("logging")
  valid_601828 = validateParameter(valid_601828, JBool, required = true, default = nil)
  if valid_601828 != nil:
    section.add "logging", valid_601828
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601829 = header.getOrDefault("x-amz-security-token")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "x-amz-security-token", valid_601829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601830: Call_GetBucketLogging_601824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  let valid = call_601830.validator(path, query, header, formData, body)
  let scheme = call_601830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601830.url(scheme.get, call_601830.host, call_601830.base,
                         call_601830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601830, url, valid)

proc call*(call_601831: Call_GetBucketLogging_601824; logging: bool; Bucket: string): Recallable =
  ## getBucketLogging
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601832 = newJObject()
  var query_601833 = newJObject()
  add(query_601833, "logging", newJBool(logging))
  add(path_601832, "Bucket", newJString(Bucket))
  result = call_601831.call(path_601832, query_601833, nil, nil, nil)

var getBucketLogging* = Call_GetBucketLogging_601824(name: "getBucketLogging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_GetBucketLogging_601825, base: "/",
    url: url_GetBucketLogging_601826, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotificationConfiguration_601857 = ref object of OpenApiRestCall_600437
proc url_PutBucketNotificationConfiguration_601859(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#notification")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketNotificationConfiguration_601858(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables notifications of specified events for a bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601860 = path.getOrDefault("Bucket")
  valid_601860 = validateParameter(valid_601860, JString, required = true,
                                 default = nil)
  if valid_601860 != nil:
    section.add "Bucket", valid_601860
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_601861 = query.getOrDefault("notification")
  valid_601861 = validateParameter(valid_601861, JBool, required = true, default = nil)
  if valid_601861 != nil:
    section.add "notification", valid_601861
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601862 = header.getOrDefault("x-amz-security-token")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "x-amz-security-token", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601864: Call_PutBucketNotificationConfiguration_601857;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enables notifications of specified events for a bucket.
  ## 
  let valid = call_601864.validator(path, query, header, formData, body)
  let scheme = call_601864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601864.url(scheme.get, call_601864.host, call_601864.base,
                         call_601864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601864, url, valid)

proc call*(call_601865: Call_PutBucketNotificationConfiguration_601857;
          notification: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotificationConfiguration
  ## Enables notifications of specified events for a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601866 = newJObject()
  var query_601867 = newJObject()
  var body_601868 = newJObject()
  add(query_601867, "notification", newJBool(notification))
  add(path_601866, "Bucket", newJString(Bucket))
  if body != nil:
    body_601868 = body
  result = call_601865.call(path_601866, query_601867, nil, nil, body_601868)

var putBucketNotificationConfiguration* = Call_PutBucketNotificationConfiguration_601857(
    name: "putBucketNotificationConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_PutBucketNotificationConfiguration_601858, base: "/",
    url: url_PutBucketNotificationConfiguration_601859,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotificationConfiguration_601847 = ref object of OpenApiRestCall_600437
proc url_GetBucketNotificationConfiguration_601849(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#notification")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketNotificationConfiguration_601848(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the notification configuration of a bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : Name of the bucket to get the notification configuration for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601850 = path.getOrDefault("Bucket")
  valid_601850 = validateParameter(valid_601850, JString, required = true,
                                 default = nil)
  if valid_601850 != nil:
    section.add "Bucket", valid_601850
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_601851 = query.getOrDefault("notification")
  valid_601851 = validateParameter(valid_601851, JBool, required = true, default = nil)
  if valid_601851 != nil:
    section.add "notification", valid_601851
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601852 = header.getOrDefault("x-amz-security-token")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "x-amz-security-token", valid_601852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601853: Call_GetBucketNotificationConfiguration_601847;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the notification configuration of a bucket.
  ## 
  let valid = call_601853.validator(path, query, header, formData, body)
  let scheme = call_601853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601853.url(scheme.get, call_601853.host, call_601853.base,
                         call_601853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601853, url, valid)

proc call*(call_601854: Call_GetBucketNotificationConfiguration_601847;
          notification: bool; Bucket: string): Recallable =
  ## getBucketNotificationConfiguration
  ## Returns the notification configuration of a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_601855 = newJObject()
  var query_601856 = newJObject()
  add(query_601856, "notification", newJBool(notification))
  add(path_601855, "Bucket", newJString(Bucket))
  result = call_601854.call(path_601855, query_601856, nil, nil, nil)

var getBucketNotificationConfiguration* = Call_GetBucketNotificationConfiguration_601847(
    name: "getBucketNotificationConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_GetBucketNotificationConfiguration_601848, base: "/",
    url: url_GetBucketNotificationConfiguration_601849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotification_601879 = ref object of OpenApiRestCall_600437
proc url_PutBucketNotification_601881(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#notification&deprecated!")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketNotification_601880(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601882 = path.getOrDefault("Bucket")
  valid_601882 = validateParameter(valid_601882, JString, required = true,
                                 default = nil)
  if valid_601882 != nil:
    section.add "Bucket", valid_601882
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_601883 = query.getOrDefault("notification")
  valid_601883 = validateParameter(valid_601883, JBool, required = true, default = nil)
  if valid_601883 != nil:
    section.add "notification", valid_601883
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601884 = header.getOrDefault("x-amz-security-token")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "x-amz-security-token", valid_601884
  var valid_601885 = header.getOrDefault("Content-MD5")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "Content-MD5", valid_601885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601887: Call_PutBucketNotification_601879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  let valid = call_601887.validator(path, query, header, formData, body)
  let scheme = call_601887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601887.url(scheme.get, call_601887.host, call_601887.base,
                         call_601887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601887, url, valid)

proc call*(call_601888: Call_PutBucketNotification_601879; notification: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotification
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601889 = newJObject()
  var query_601890 = newJObject()
  var body_601891 = newJObject()
  add(query_601890, "notification", newJBool(notification))
  add(path_601889, "Bucket", newJString(Bucket))
  if body != nil:
    body_601891 = body
  result = call_601888.call(path_601889, query_601890, nil, nil, body_601891)

var putBucketNotification* = Call_PutBucketNotification_601879(
    name: "putBucketNotification", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_PutBucketNotification_601880, base: "/",
    url: url_PutBucketNotification_601881, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotification_601869 = ref object of OpenApiRestCall_600437
proc url_GetBucketNotification_601871(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#notification&deprecated!")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketNotification_601870(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : Name of the bucket to get the notification configuration for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601872 = path.getOrDefault("Bucket")
  valid_601872 = validateParameter(valid_601872, JString, required = true,
                                 default = nil)
  if valid_601872 != nil:
    section.add "Bucket", valid_601872
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_601873 = query.getOrDefault("notification")
  valid_601873 = validateParameter(valid_601873, JBool, required = true, default = nil)
  if valid_601873 != nil:
    section.add "notification", valid_601873
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601874 = header.getOrDefault("x-amz-security-token")
  valid_601874 = validateParameter(valid_601874, JString, required = false,
                                 default = nil)
  if valid_601874 != nil:
    section.add "x-amz-security-token", valid_601874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601875: Call_GetBucketNotification_601869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  let valid = call_601875.validator(path, query, header, formData, body)
  let scheme = call_601875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601875.url(scheme.get, call_601875.host, call_601875.base,
                         call_601875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601875, url, valid)

proc call*(call_601876: Call_GetBucketNotification_601869; notification: bool;
          Bucket: string): Recallable =
  ## getBucketNotification
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_601877 = newJObject()
  var query_601878 = newJObject()
  add(query_601878, "notification", newJBool(notification))
  add(path_601877, "Bucket", newJString(Bucket))
  result = call_601876.call(path_601877, query_601878, nil, nil, nil)

var getBucketNotification* = Call_GetBucketNotification_601869(
    name: "getBucketNotification", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_GetBucketNotification_601870, base: "/",
    url: url_GetBucketNotification_601871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicyStatus_601892 = ref object of OpenApiRestCall_600437
proc url_GetBucketPolicyStatus_601894(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#policyStatus")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketPolicyStatus_601893(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the Amazon S3 bucket whose policy status you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601895 = path.getOrDefault("Bucket")
  valid_601895 = validateParameter(valid_601895, JString, required = true,
                                 default = nil)
  if valid_601895 != nil:
    section.add "Bucket", valid_601895
  result.add "path", section
  ## parameters in `query` object:
  ##   policyStatus: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `policyStatus` field"
  var valid_601896 = query.getOrDefault("policyStatus")
  valid_601896 = validateParameter(valid_601896, JBool, required = true, default = nil)
  if valid_601896 != nil:
    section.add "policyStatus", valid_601896
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601897 = header.getOrDefault("x-amz-security-token")
  valid_601897 = validateParameter(valid_601897, JString, required = false,
                                 default = nil)
  if valid_601897 != nil:
    section.add "x-amz-security-token", valid_601897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601898: Call_GetBucketPolicyStatus_601892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ## 
  let valid = call_601898.validator(path, query, header, formData, body)
  let scheme = call_601898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601898.url(scheme.get, call_601898.host, call_601898.base,
                         call_601898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601898, url, valid)

proc call*(call_601899: Call_GetBucketPolicyStatus_601892; policyStatus: bool;
          Bucket: string): Recallable =
  ## getBucketPolicyStatus
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ##   policyStatus: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose policy status you want to retrieve.
  var path_601900 = newJObject()
  var query_601901 = newJObject()
  add(query_601901, "policyStatus", newJBool(policyStatus))
  add(path_601900, "Bucket", newJString(Bucket))
  result = call_601899.call(path_601900, query_601901, nil, nil, nil)

var getBucketPolicyStatus* = Call_GetBucketPolicyStatus_601892(
    name: "getBucketPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#policyStatus",
    validator: validate_GetBucketPolicyStatus_601893, base: "/",
    url: url_GetBucketPolicyStatus_601894, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketRequestPayment_601912 = ref object of OpenApiRestCall_600437
proc url_PutBucketRequestPayment_601914(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#requestPayment")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketRequestPayment_601913(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601915 = path.getOrDefault("Bucket")
  valid_601915 = validateParameter(valid_601915, JString, required = true,
                                 default = nil)
  if valid_601915 != nil:
    section.add "Bucket", valid_601915
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_601916 = query.getOrDefault("requestPayment")
  valid_601916 = validateParameter(valid_601916, JBool, required = true, default = nil)
  if valid_601916 != nil:
    section.add "requestPayment", valid_601916
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601917 = header.getOrDefault("x-amz-security-token")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "x-amz-security-token", valid_601917
  var valid_601918 = header.getOrDefault("Content-MD5")
  valid_601918 = validateParameter(valid_601918, JString, required = false,
                                 default = nil)
  if valid_601918 != nil:
    section.add "Content-MD5", valid_601918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601920: Call_PutBucketRequestPayment_601912; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  let valid = call_601920.validator(path, query, header, formData, body)
  let scheme = call_601920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601920.url(scheme.get, call_601920.host, call_601920.base,
                         call_601920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601920, url, valid)

proc call*(call_601921: Call_PutBucketRequestPayment_601912; requestPayment: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketRequestPayment
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601922 = newJObject()
  var query_601923 = newJObject()
  var body_601924 = newJObject()
  add(query_601923, "requestPayment", newJBool(requestPayment))
  add(path_601922, "Bucket", newJString(Bucket))
  if body != nil:
    body_601924 = body
  result = call_601921.call(path_601922, query_601923, nil, nil, body_601924)

var putBucketRequestPayment* = Call_PutBucketRequestPayment_601912(
    name: "putBucketRequestPayment", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_PutBucketRequestPayment_601913, base: "/",
    url: url_PutBucketRequestPayment_601914, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketRequestPayment_601902 = ref object of OpenApiRestCall_600437
proc url_GetBucketRequestPayment_601904(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#requestPayment")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketRequestPayment_601903(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the request payment configuration of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601905 = path.getOrDefault("Bucket")
  valid_601905 = validateParameter(valid_601905, JString, required = true,
                                 default = nil)
  if valid_601905 != nil:
    section.add "Bucket", valid_601905
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_601906 = query.getOrDefault("requestPayment")
  valid_601906 = validateParameter(valid_601906, JBool, required = true, default = nil)
  if valid_601906 != nil:
    section.add "requestPayment", valid_601906
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601907 = header.getOrDefault("x-amz-security-token")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "x-amz-security-token", valid_601907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601908: Call_GetBucketRequestPayment_601902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the request payment configuration of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  let valid = call_601908.validator(path, query, header, formData, body)
  let scheme = call_601908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601908.url(scheme.get, call_601908.host, call_601908.base,
                         call_601908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601908, url, valid)

proc call*(call_601909: Call_GetBucketRequestPayment_601902; requestPayment: bool;
          Bucket: string): Recallable =
  ## getBucketRequestPayment
  ## Returns the request payment configuration of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601910 = newJObject()
  var query_601911 = newJObject()
  add(query_601911, "requestPayment", newJBool(requestPayment))
  add(path_601910, "Bucket", newJString(Bucket))
  result = call_601909.call(path_601910, query_601911, nil, nil, nil)

var getBucketRequestPayment* = Call_GetBucketRequestPayment_601902(
    name: "getBucketRequestPayment", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_GetBucketRequestPayment_601903, base: "/",
    url: url_GetBucketRequestPayment_601904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketVersioning_601935 = ref object of OpenApiRestCall_600437
proc url_PutBucketVersioning_601937(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#versioning")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBucketVersioning_601936(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601938 = path.getOrDefault("Bucket")
  valid_601938 = validateParameter(valid_601938, JString, required = true,
                                 default = nil)
  if valid_601938 != nil:
    section.add "Bucket", valid_601938
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_601939 = query.getOrDefault("versioning")
  valid_601939 = validateParameter(valid_601939, JBool, required = true, default = nil)
  if valid_601939 != nil:
    section.add "versioning", valid_601939
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  section = newJObject()
  var valid_601940 = header.getOrDefault("x-amz-security-token")
  valid_601940 = validateParameter(valid_601940, JString, required = false,
                                 default = nil)
  if valid_601940 != nil:
    section.add "x-amz-security-token", valid_601940
  var valid_601941 = header.getOrDefault("Content-MD5")
  valid_601941 = validateParameter(valid_601941, JString, required = false,
                                 default = nil)
  if valid_601941 != nil:
    section.add "Content-MD5", valid_601941
  var valid_601942 = header.getOrDefault("x-amz-mfa")
  valid_601942 = validateParameter(valid_601942, JString, required = false,
                                 default = nil)
  if valid_601942 != nil:
    section.add "x-amz-mfa", valid_601942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601944: Call_PutBucketVersioning_601935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  let valid = call_601944.validator(path, query, header, formData, body)
  let scheme = call_601944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601944.url(scheme.get, call_601944.host, call_601944.base,
                         call_601944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601944, url, valid)

proc call*(call_601945: Call_PutBucketVersioning_601935; Bucket: string;
          body: JsonNode; versioning: bool): Recallable =
  ## putBucketVersioning
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   versioning: bool (required)
  var path_601946 = newJObject()
  var query_601947 = newJObject()
  var body_601948 = newJObject()
  add(path_601946, "Bucket", newJString(Bucket))
  if body != nil:
    body_601948 = body
  add(query_601947, "versioning", newJBool(versioning))
  result = call_601945.call(path_601946, query_601947, nil, nil, body_601948)

var putBucketVersioning* = Call_PutBucketVersioning_601935(
    name: "putBucketVersioning", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_PutBucketVersioning_601936,
    base: "/", url: url_PutBucketVersioning_601937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketVersioning_601925 = ref object of OpenApiRestCall_600437
proc url_GetBucketVersioning_601927(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#versioning")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBucketVersioning_601926(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns the versioning state of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_601928 = path.getOrDefault("Bucket")
  valid_601928 = validateParameter(valid_601928, JString, required = true,
                                 default = nil)
  if valid_601928 != nil:
    section.add "Bucket", valid_601928
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_601929 = query.getOrDefault("versioning")
  valid_601929 = validateParameter(valid_601929, JBool, required = true, default = nil)
  if valid_601929 != nil:
    section.add "versioning", valid_601929
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601930 = header.getOrDefault("x-amz-security-token")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "x-amz-security-token", valid_601930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601931: Call_GetBucketVersioning_601925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the versioning state of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  let valid = call_601931.validator(path, query, header, formData, body)
  let scheme = call_601931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601931.url(scheme.get, call_601931.host, call_601931.base,
                         call_601931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601931, url, valid)

proc call*(call_601932: Call_GetBucketVersioning_601925; Bucket: string;
          versioning: bool): Recallable =
  ## getBucketVersioning
  ## Returns the versioning state of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versioning: bool (required)
  var path_601933 = newJObject()
  var query_601934 = newJObject()
  add(path_601933, "Bucket", newJString(Bucket))
  add(query_601934, "versioning", newJBool(versioning))
  result = call_601932.call(path_601933, query_601934, nil, nil, nil)

var getBucketVersioning* = Call_GetBucketVersioning_601925(
    name: "getBucketVersioning", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_GetBucketVersioning_601926,
    base: "/", url: url_GetBucketVersioning_601927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectAcl_601962 = ref object of OpenApiRestCall_600437
proc url_PutObjectAcl_601964(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#acl")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutObjectAcl_601963(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601965 = path.getOrDefault("Key")
  valid_601965 = validateParameter(valid_601965, JString, required = true,
                                 default = nil)
  if valid_601965 != nil:
    section.add "Key", valid_601965
  var valid_601966 = path.getOrDefault("Bucket")
  valid_601966 = validateParameter(valid_601966, JString, required = true,
                                 default = nil)
  if valid_601966 != nil:
    section.add "Bucket", valid_601966
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_601967 = query.getOrDefault("versionId")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "versionId", valid_601967
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_601968 = query.getOrDefault("acl")
  valid_601968 = validateParameter(valid_601968, JBool, required = true, default = nil)
  if valid_601968 != nil:
    section.add "acl", valid_601968
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the object.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to list the objects in the bucket.
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the bucket ACL.
  ##   x-amz-grant-write: JString
  ##                    : Allows grantee to create, overwrite, and delete any object in the bucket.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable bucket.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   x-amz-grant-full-control: JString
  ##                           : Allows grantee the read, write, read ACP, and write ACP permissions on the bucket.
  section = newJObject()
  var valid_601969 = header.getOrDefault("x-amz-security-token")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "x-amz-security-token", valid_601969
  var valid_601970 = header.getOrDefault("Content-MD5")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "Content-MD5", valid_601970
  var valid_601971 = header.getOrDefault("x-amz-acl")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = newJString("private"))
  if valid_601971 != nil:
    section.add "x-amz-acl", valid_601971
  var valid_601972 = header.getOrDefault("x-amz-grant-read")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "x-amz-grant-read", valid_601972
  var valid_601973 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "x-amz-grant-read-acp", valid_601973
  var valid_601974 = header.getOrDefault("x-amz-grant-write")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "x-amz-grant-write", valid_601974
  var valid_601975 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "x-amz-grant-write-acp", valid_601975
  var valid_601976 = header.getOrDefault("x-amz-request-payer")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = newJString("requester"))
  if valid_601976 != nil:
    section.add "x-amz-request-payer", valid_601976
  var valid_601977 = header.getOrDefault("x-amz-grant-full-control")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "x-amz-grant-full-control", valid_601977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601979: Call_PutObjectAcl_601962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  let valid = call_601979.validator(path, query, header, formData, body)
  let scheme = call_601979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601979.url(scheme.get, call_601979.host, call_601979.base,
                         call_601979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601979, url, valid)

proc call*(call_601980: Call_PutObjectAcl_601962; Key: string; acl: bool;
          Bucket: string; body: JsonNode; versionId: string = ""): Recallable =
  ## putObjectAcl
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  ##   versionId: string
  ##            : VersionId used to reference a specific version of the object.
  ##   Key: string (required)
  ##      : <p/>
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601981 = newJObject()
  var query_601982 = newJObject()
  var body_601983 = newJObject()
  add(query_601982, "versionId", newJString(versionId))
  add(path_601981, "Key", newJString(Key))
  add(query_601982, "acl", newJBool(acl))
  add(path_601981, "Bucket", newJString(Bucket))
  if body != nil:
    body_601983 = body
  result = call_601980.call(path_601981, query_601982, nil, nil, body_601983)

var putObjectAcl* = Call_PutObjectAcl_601962(name: "putObjectAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_PutObjectAcl_601963,
    base: "/", url: url_PutObjectAcl_601964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAcl_601949 = ref object of OpenApiRestCall_600437
proc url_GetObjectAcl_601951(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#acl")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetObjectAcl_601950(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the access control list (ACL) of an object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601952 = path.getOrDefault("Key")
  valid_601952 = validateParameter(valid_601952, JString, required = true,
                                 default = nil)
  if valid_601952 != nil:
    section.add "Key", valid_601952
  var valid_601953 = path.getOrDefault("Bucket")
  valid_601953 = validateParameter(valid_601953, JString, required = true,
                                 default = nil)
  if valid_601953 != nil:
    section.add "Bucket", valid_601953
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_601954 = query.getOrDefault("versionId")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "versionId", valid_601954
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_601955 = query.getOrDefault("acl")
  valid_601955 = validateParameter(valid_601955, JBool, required = true, default = nil)
  if valid_601955 != nil:
    section.add "acl", valid_601955
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601956 = header.getOrDefault("x-amz-security-token")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "x-amz-security-token", valid_601956
  var valid_601957 = header.getOrDefault("x-amz-request-payer")
  valid_601957 = validateParameter(valid_601957, JString, required = false,
                                 default = newJString("requester"))
  if valid_601957 != nil:
    section.add "x-amz-request-payer", valid_601957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601958: Call_GetObjectAcl_601949; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access control list (ACL) of an object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  let valid = call_601958.validator(path, query, header, formData, body)
  let scheme = call_601958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601958.url(scheme.get, call_601958.host, call_601958.base,
                         call_601958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601958, url, valid)

proc call*(call_601959: Call_GetObjectAcl_601949; Key: string; acl: bool;
          Bucket: string; versionId: string = ""): Recallable =
  ## getObjectAcl
  ## Returns the access control list (ACL) of an object.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  ##   versionId: string
  ##            : VersionId used to reference a specific version of the object.
  ##   Key: string (required)
  ##      : <p/>
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601960 = newJObject()
  var query_601961 = newJObject()
  add(query_601961, "versionId", newJString(versionId))
  add(path_601960, "Key", newJString(Key))
  add(query_601961, "acl", newJBool(acl))
  add(path_601960, "Bucket", newJString(Bucket))
  result = call_601959.call(path_601960, query_601961, nil, nil, nil)

var getObjectAcl* = Call_GetObjectAcl_601949(name: "getObjectAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_GetObjectAcl_601950,
    base: "/", url: url_GetObjectAcl_601951, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLegalHold_601997 = ref object of OpenApiRestCall_600437
proc url_PutObjectLegalHold_601999(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#legal-hold")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutObjectLegalHold_601998(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Applies a Legal Hold configuration to the specified object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : The key name for the object that you want to place a Legal Hold on.
  ##   Bucket: JString (required)
  ##         : The bucket containing the object that you want to place a Legal Hold on.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_602000 = path.getOrDefault("Key")
  valid_602000 = validateParameter(valid_602000, JString, required = true,
                                 default = nil)
  if valid_602000 != nil:
    section.add "Key", valid_602000
  var valid_602001 = path.getOrDefault("Bucket")
  valid_602001 = validateParameter(valid_602001, JString, required = true,
                                 default = nil)
  if valid_602001 != nil:
    section.add "Bucket", valid_602001
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object that you want to place a Legal Hold on.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_602002 = query.getOrDefault("versionId")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "versionId", valid_602002
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_602003 = query.getOrDefault("legal-hold")
  valid_602003 = validateParameter(valid_602003, JBool, required = true, default = nil)
  if valid_602003 != nil:
    section.add "legal-hold", valid_602003
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602004 = header.getOrDefault("x-amz-security-token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "x-amz-security-token", valid_602004
  var valid_602005 = header.getOrDefault("Content-MD5")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "Content-MD5", valid_602005
  var valid_602006 = header.getOrDefault("x-amz-request-payer")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = newJString("requester"))
  if valid_602006 != nil:
    section.add "x-amz-request-payer", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_PutObjectLegalHold_601997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a Legal Hold configuration to the specified object.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602008, url, valid)

proc call*(call_602009: Call_PutObjectLegalHold_601997; Key: string; legalHold: bool;
          Bucket: string; body: JsonNode; versionId: string = ""): Recallable =
  ## putObjectLegalHold
  ## Applies a Legal Hold configuration to the specified object.
  ##   versionId: string
  ##            : The version ID of the object that you want to place a Legal Hold on.
  ##   Key: string (required)
  ##      : The key name for the object that you want to place a Legal Hold on.
  ##   legalHold: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket containing the object that you want to place a Legal Hold on.
  ##   body: JObject (required)
  var path_602010 = newJObject()
  var query_602011 = newJObject()
  var body_602012 = newJObject()
  add(query_602011, "versionId", newJString(versionId))
  add(path_602010, "Key", newJString(Key))
  add(query_602011, "legal-hold", newJBool(legalHold))
  add(path_602010, "Bucket", newJString(Bucket))
  if body != nil:
    body_602012 = body
  result = call_602009.call(path_602010, query_602011, nil, nil, body_602012)

var putObjectLegalHold* = Call_PutObjectLegalHold_601997(
    name: "putObjectLegalHold", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_PutObjectLegalHold_601998,
    base: "/", url: url_PutObjectLegalHold_601999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLegalHold_601984 = ref object of OpenApiRestCall_600437
proc url_GetObjectLegalHold_601986(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#legal-hold")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetObjectLegalHold_601985(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets an object's current Legal Hold status.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : The key name for the object whose Legal Hold status you want to retrieve.
  ##   Bucket: JString (required)
  ##         : The bucket containing the object whose Legal Hold status you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_601987 = path.getOrDefault("Key")
  valid_601987 = validateParameter(valid_601987, JString, required = true,
                                 default = nil)
  if valid_601987 != nil:
    section.add "Key", valid_601987
  var valid_601988 = path.getOrDefault("Bucket")
  valid_601988 = validateParameter(valid_601988, JString, required = true,
                                 default = nil)
  if valid_601988 != nil:
    section.add "Bucket", valid_601988
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object whose Legal Hold status you want to retrieve.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_601989 = query.getOrDefault("versionId")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "versionId", valid_601989
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_601990 = query.getOrDefault("legal-hold")
  valid_601990 = validateParameter(valid_601990, JBool, required = true, default = nil)
  if valid_601990 != nil:
    section.add "legal-hold", valid_601990
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601991 = header.getOrDefault("x-amz-security-token")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "x-amz-security-token", valid_601991
  var valid_601992 = header.getOrDefault("x-amz-request-payer")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = newJString("requester"))
  if valid_601992 != nil:
    section.add "x-amz-request-payer", valid_601992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601993: Call_GetObjectLegalHold_601984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an object's current Legal Hold status.
  ## 
  let valid = call_601993.validator(path, query, header, formData, body)
  let scheme = call_601993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601993.url(scheme.get, call_601993.host, call_601993.base,
                         call_601993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601993, url, valid)

proc call*(call_601994: Call_GetObjectLegalHold_601984; Key: string; legalHold: bool;
          Bucket: string; versionId: string = ""): Recallable =
  ## getObjectLegalHold
  ## Gets an object's current Legal Hold status.
  ##   versionId: string
  ##            : The version ID of the object whose Legal Hold status you want to retrieve.
  ##   Key: string (required)
  ##      : The key name for the object whose Legal Hold status you want to retrieve.
  ##   legalHold: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket containing the object whose Legal Hold status you want to retrieve.
  var path_601995 = newJObject()
  var query_601996 = newJObject()
  add(query_601996, "versionId", newJString(versionId))
  add(path_601995, "Key", newJString(Key))
  add(query_601996, "legal-hold", newJBool(legalHold))
  add(path_601995, "Bucket", newJString(Bucket))
  result = call_601994.call(path_601995, query_601996, nil, nil, nil)

var getObjectLegalHold* = Call_GetObjectLegalHold_601984(
    name: "getObjectLegalHold", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_GetObjectLegalHold_601985,
    base: "/", url: url_GetObjectLegalHold_601986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLockConfiguration_602023 = ref object of OpenApiRestCall_600437
proc url_PutObjectLockConfiguration_602025(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#object-lock")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutObjectLockConfiguration_602024(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The bucket whose object lock configuration you want to create or replace.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_602026 = path.getOrDefault("Bucket")
  valid_602026 = validateParameter(valid_602026, JString, required = true,
                                 default = nil)
  if valid_602026 != nil:
    section.add "Bucket", valid_602026
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_602027 = query.getOrDefault("object-lock")
  valid_602027 = validateParameter(valid_602027, JBool, required = true, default = nil)
  if valid_602027 != nil:
    section.add "object-lock", valid_602027
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  ##   x-amz-bucket-object-lock-token: JString
  ##                                 : A token to allow Amazon S3 object lock to be enabled for an existing bucket.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602028 = header.getOrDefault("x-amz-security-token")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "x-amz-security-token", valid_602028
  var valid_602029 = header.getOrDefault("Content-MD5")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "Content-MD5", valid_602029
  var valid_602030 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_602030
  var valid_602031 = header.getOrDefault("x-amz-request-payer")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = newJString("requester"))
  if valid_602031 != nil:
    section.add "x-amz-request-payer", valid_602031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602033: Call_PutObjectLockConfiguration_602023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_602033.validator(path, query, header, formData, body)
  let scheme = call_602033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602033.url(scheme.get, call_602033.host, call_602033.base,
                         call_602033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602033, url, valid)

proc call*(call_602034: Call_PutObjectLockConfiguration_602023; objectLock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putObjectLockConfiguration
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to create or replace.
  ##   body: JObject (required)
  var path_602035 = newJObject()
  var query_602036 = newJObject()
  var body_602037 = newJObject()
  add(query_602036, "object-lock", newJBool(objectLock))
  add(path_602035, "Bucket", newJString(Bucket))
  if body != nil:
    body_602037 = body
  result = call_602034.call(path_602035, query_602036, nil, nil, body_602037)

var putObjectLockConfiguration* = Call_PutObjectLockConfiguration_602023(
    name: "putObjectLockConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_PutObjectLockConfiguration_602024, base: "/",
    url: url_PutObjectLockConfiguration_602025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLockConfiguration_602013 = ref object of OpenApiRestCall_600437
proc url_GetObjectLockConfiguration_602015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#object-lock")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetObjectLockConfiguration_602014(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The bucket whose object lock configuration you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_602016 = path.getOrDefault("Bucket")
  valid_602016 = validateParameter(valid_602016, JString, required = true,
                                 default = nil)
  if valid_602016 != nil:
    section.add "Bucket", valid_602016
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_602017 = query.getOrDefault("object-lock")
  valid_602017 = validateParameter(valid_602017, JBool, required = true, default = nil)
  if valid_602017 != nil:
    section.add "object-lock", valid_602017
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602018 = header.getOrDefault("x-amz-security-token")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "x-amz-security-token", valid_602018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602019: Call_GetObjectLockConfiguration_602013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_602019.validator(path, query, header, formData, body)
  let scheme = call_602019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602019.url(scheme.get, call_602019.host, call_602019.base,
                         call_602019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602019, url, valid)

proc call*(call_602020: Call_GetObjectLockConfiguration_602013; objectLock: bool;
          Bucket: string): Recallable =
  ## getObjectLockConfiguration
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to retrieve.
  var path_602021 = newJObject()
  var query_602022 = newJObject()
  add(query_602022, "object-lock", newJBool(objectLock))
  add(path_602021, "Bucket", newJString(Bucket))
  result = call_602020.call(path_602021, query_602022, nil, nil, nil)

var getObjectLockConfiguration* = Call_GetObjectLockConfiguration_602013(
    name: "getObjectLockConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_GetObjectLockConfiguration_602014, base: "/",
    url: url_GetObjectLockConfiguration_602015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectRetention_602051 = ref object of OpenApiRestCall_600437
proc url_PutObjectRetention_602053(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#retention")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutObjectRetention_602052(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Places an Object Retention configuration on an object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : The key name for the object that you want to apply this Object Retention configuration to.
  ##   Bucket: JString (required)
  ##         : The bucket that contains the object you want to apply this Object Retention configuration to.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_602054 = path.getOrDefault("Key")
  valid_602054 = validateParameter(valid_602054, JString, required = true,
                                 default = nil)
  if valid_602054 != nil:
    section.add "Key", valid_602054
  var valid_602055 = path.getOrDefault("Bucket")
  valid_602055 = validateParameter(valid_602055, JString, required = true,
                                 default = nil)
  if valid_602055 != nil:
    section.add "Bucket", valid_602055
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object that you want to apply this Object Retention configuration to.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_602056 = query.getOrDefault("versionId")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "versionId", valid_602056
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_602057 = query.getOrDefault("retention")
  valid_602057 = validateParameter(valid_602057, JBool, required = true, default = nil)
  if valid_602057 != nil:
    section.add "retention", valid_602057
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  ##   x-amz-bypass-governance-retention: JBool
  ##                                    : Indicates whether this operation should bypass Governance-mode restrictions.j
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602058 = header.getOrDefault("x-amz-security-token")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "x-amz-security-token", valid_602058
  var valid_602059 = header.getOrDefault("Content-MD5")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "Content-MD5", valid_602059
  var valid_602060 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_602060 = validateParameter(valid_602060, JBool, required = false, default = nil)
  if valid_602060 != nil:
    section.add "x-amz-bypass-governance-retention", valid_602060
  var valid_602061 = header.getOrDefault("x-amz-request-payer")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = newJString("requester"))
  if valid_602061 != nil:
    section.add "x-amz-request-payer", valid_602061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602063: Call_PutObjectRetention_602051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an Object Retention configuration on an object.
  ## 
  let valid = call_602063.validator(path, query, header, formData, body)
  let scheme = call_602063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602063.url(scheme.get, call_602063.host, call_602063.base,
                         call_602063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602063, url, valid)

proc call*(call_602064: Call_PutObjectRetention_602051; retention: bool; Key: string;
          Bucket: string; body: JsonNode; versionId: string = ""): Recallable =
  ## putObjectRetention
  ## Places an Object Retention configuration on an object.
  ##   versionId: string
  ##            : The version ID for the object that you want to apply this Object Retention configuration to.
  ##   retention: bool (required)
  ##   Key: string (required)
  ##      : The key name for the object that you want to apply this Object Retention configuration to.
  ##   Bucket: string (required)
  ##         : The bucket that contains the object you want to apply this Object Retention configuration to.
  ##   body: JObject (required)
  var path_602065 = newJObject()
  var query_602066 = newJObject()
  var body_602067 = newJObject()
  add(query_602066, "versionId", newJString(versionId))
  add(query_602066, "retention", newJBool(retention))
  add(path_602065, "Key", newJString(Key))
  add(path_602065, "Bucket", newJString(Bucket))
  if body != nil:
    body_602067 = body
  result = call_602064.call(path_602065, query_602066, nil, nil, body_602067)

var putObjectRetention* = Call_PutObjectRetention_602051(
    name: "putObjectRetention", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_PutObjectRetention_602052,
    base: "/", url: url_PutObjectRetention_602053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectRetention_602038 = ref object of OpenApiRestCall_600437
proc url_GetObjectRetention_602040(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#retention")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetObjectRetention_602039(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves an object's retention settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : The key name for the object whose retention settings you want to retrieve.
  ##   Bucket: JString (required)
  ##         : The bucket containing the object whose retention settings you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_602041 = path.getOrDefault("Key")
  valid_602041 = validateParameter(valid_602041, JString, required = true,
                                 default = nil)
  if valid_602041 != nil:
    section.add "Key", valid_602041
  var valid_602042 = path.getOrDefault("Bucket")
  valid_602042 = validateParameter(valid_602042, JString, required = true,
                                 default = nil)
  if valid_602042 != nil:
    section.add "Bucket", valid_602042
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object whose retention settings you want to retrieve.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_602043 = query.getOrDefault("versionId")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "versionId", valid_602043
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_602044 = query.getOrDefault("retention")
  valid_602044 = validateParameter(valid_602044, JBool, required = true, default = nil)
  if valid_602044 != nil:
    section.add "retention", valid_602044
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602045 = header.getOrDefault("x-amz-security-token")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "x-amz-security-token", valid_602045
  var valid_602046 = header.getOrDefault("x-amz-request-payer")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = newJString("requester"))
  if valid_602046 != nil:
    section.add "x-amz-request-payer", valid_602046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602047: Call_GetObjectRetention_602038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an object's retention settings.
  ## 
  let valid = call_602047.validator(path, query, header, formData, body)
  let scheme = call_602047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602047.url(scheme.get, call_602047.host, call_602047.base,
                         call_602047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602047, url, valid)

proc call*(call_602048: Call_GetObjectRetention_602038; retention: bool; Key: string;
          Bucket: string; versionId: string = ""): Recallable =
  ## getObjectRetention
  ## Retrieves an object's retention settings.
  ##   versionId: string
  ##            : The version ID for the object whose retention settings you want to retrieve.
  ##   retention: bool (required)
  ##   Key: string (required)
  ##      : The key name for the object whose retention settings you want to retrieve.
  ##   Bucket: string (required)
  ##         : The bucket containing the object whose retention settings you want to retrieve.
  var path_602049 = newJObject()
  var query_602050 = newJObject()
  add(query_602050, "versionId", newJString(versionId))
  add(query_602050, "retention", newJBool(retention))
  add(path_602049, "Key", newJString(Key))
  add(path_602049, "Bucket", newJString(Bucket))
  result = call_602048.call(path_602049, query_602050, nil, nil, nil)

var getObjectRetention* = Call_GetObjectRetention_602038(
    name: "getObjectRetention", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_GetObjectRetention_602039,
    base: "/", url: url_GetObjectRetention_602040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTorrent_602068 = ref object of OpenApiRestCall_600437
proc url_GetObjectTorrent_602070(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#torrent")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetObjectTorrent_602069(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Return torrent files from a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_602071 = path.getOrDefault("Key")
  valid_602071 = validateParameter(valid_602071, JString, required = true,
                                 default = nil)
  if valid_602071 != nil:
    section.add "Key", valid_602071
  var valid_602072 = path.getOrDefault("Bucket")
  valid_602072 = validateParameter(valid_602072, JString, required = true,
                                 default = nil)
  if valid_602072 != nil:
    section.add "Bucket", valid_602072
  result.add "path", section
  ## parameters in `query` object:
  ##   torrent: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `torrent` field"
  var valid_602073 = query.getOrDefault("torrent")
  valid_602073 = validateParameter(valid_602073, JBool, required = true, default = nil)
  if valid_602073 != nil:
    section.add "torrent", valid_602073
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602074 = header.getOrDefault("x-amz-security-token")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "x-amz-security-token", valid_602074
  var valid_602075 = header.getOrDefault("x-amz-request-payer")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = newJString("requester"))
  if valid_602075 != nil:
    section.add "x-amz-request-payer", valid_602075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602076: Call_GetObjectTorrent_602068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return torrent files from a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  let valid = call_602076.validator(path, query, header, formData, body)
  let scheme = call_602076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602076.url(scheme.get, call_602076.host, call_602076.base,
                         call_602076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602076, url, valid)

proc call*(call_602077: Call_GetObjectTorrent_602068; torrent: bool; Key: string;
          Bucket: string): Recallable =
  ## getObjectTorrent
  ## Return torrent files from a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  ##   torrent: bool (required)
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_602078 = newJObject()
  var query_602079 = newJObject()
  add(query_602079, "torrent", newJBool(torrent))
  add(path_602078, "Key", newJString(Key))
  add(path_602078, "Bucket", newJString(Bucket))
  result = call_602077.call(path_602078, query_602079, nil, nil, nil)

var getObjectTorrent* = Call_GetObjectTorrent_602068(name: "getObjectTorrent",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#torrent", validator: validate_GetObjectTorrent_602069,
    base: "/", url: url_GetObjectTorrent_602070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketAnalyticsConfigurations_602080 = ref object of OpenApiRestCall_600437
proc url_ListBucketAnalyticsConfigurations_602082(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#analytics")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListBucketAnalyticsConfigurations_602081(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the analytics configurations for the bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket from which analytics configurations are retrieved.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_602083 = path.getOrDefault("Bucket")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = nil)
  if valid_602083 != nil:
    section.add "Bucket", valid_602083
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   continuation-token: JString
  ##                     : The ContinuationToken that represents a placeholder from where this request should begin.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_602084 = query.getOrDefault("analytics")
  valid_602084 = validateParameter(valid_602084, JBool, required = true, default = nil)
  if valid_602084 != nil:
    section.add "analytics", valid_602084
  var valid_602085 = query.getOrDefault("continuation-token")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "continuation-token", valid_602085
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602086 = header.getOrDefault("x-amz-security-token")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "x-amz-security-token", valid_602086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602087: Call_ListBucketAnalyticsConfigurations_602080;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the analytics configurations for the bucket.
  ## 
  let valid = call_602087.validator(path, query, header, formData, body)
  let scheme = call_602087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602087.url(scheme.get, call_602087.host, call_602087.base,
                         call_602087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602087, url, valid)

proc call*(call_602088: Call_ListBucketAnalyticsConfigurations_602080;
          analytics: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketAnalyticsConfigurations
  ## Lists the analytics configurations for the bucket.
  ##   analytics: bool (required)
  ##   continuationToken: string
  ##                    : The ContinuationToken that represents a placeholder from where this request should begin.
  ##   Bucket: string (required)
  ##         : The name of the bucket from which analytics configurations are retrieved.
  var path_602089 = newJObject()
  var query_602090 = newJObject()
  add(query_602090, "analytics", newJBool(analytics))
  add(query_602090, "continuation-token", newJString(continuationToken))
  add(path_602089, "Bucket", newJString(Bucket))
  result = call_602088.call(path_602089, query_602090, nil, nil, nil)

var listBucketAnalyticsConfigurations* = Call_ListBucketAnalyticsConfigurations_602080(
    name: "listBucketAnalyticsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics",
    validator: validate_ListBucketAnalyticsConfigurations_602081, base: "/",
    url: url_ListBucketAnalyticsConfigurations_602082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketInventoryConfigurations_602091 = ref object of OpenApiRestCall_600437
proc url_ListBucketInventoryConfigurations_602093(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#inventory")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListBucketInventoryConfigurations_602092(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of inventory configurations for the bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket containing the inventory configurations to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_602094 = path.getOrDefault("Bucket")
  valid_602094 = validateParameter(valid_602094, JString, required = true,
                                 default = nil)
  if valid_602094 != nil:
    section.add "Bucket", valid_602094
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_602095 = query.getOrDefault("inventory")
  valid_602095 = validateParameter(valid_602095, JBool, required = true, default = nil)
  if valid_602095 != nil:
    section.add "inventory", valid_602095
  var valid_602096 = query.getOrDefault("continuation-token")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "continuation-token", valid_602096
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602097 = header.getOrDefault("x-amz-security-token")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "x-amz-security-token", valid_602097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_ListBucketInventoryConfigurations_602091;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of inventory configurations for the bucket.
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602098, url, valid)

proc call*(call_602099: Call_ListBucketInventoryConfigurations_602091;
          inventory: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketInventoryConfigurations
  ## Returns a list of inventory configurations for the bucket.
  ##   inventory: bool (required)
  ##   continuationToken: string
  ##                    : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configurations to retrieve.
  var path_602100 = newJObject()
  var query_602101 = newJObject()
  add(query_602101, "inventory", newJBool(inventory))
  add(query_602101, "continuation-token", newJString(continuationToken))
  add(path_602100, "Bucket", newJString(Bucket))
  result = call_602099.call(path_602100, query_602101, nil, nil, nil)

var listBucketInventoryConfigurations* = Call_ListBucketInventoryConfigurations_602091(
    name: "listBucketInventoryConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory",
    validator: validate_ListBucketInventoryConfigurations_602092, base: "/",
    url: url_ListBucketInventoryConfigurations_602093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketMetricsConfigurations_602102 = ref object of OpenApiRestCall_600437
proc url_ListBucketMetricsConfigurations_602104(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#metrics")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListBucketMetricsConfigurations_602103(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the metrics configurations for the bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The name of the bucket containing the metrics configurations to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_602105 = path.getOrDefault("Bucket")
  valid_602105 = validateParameter(valid_602105, JString, required = true,
                                 default = nil)
  if valid_602105 != nil:
    section.add "Bucket", valid_602105
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_602106 = query.getOrDefault("metrics")
  valid_602106 = validateParameter(valid_602106, JBool, required = true, default = nil)
  if valid_602106 != nil:
    section.add "metrics", valid_602106
  var valid_602107 = query.getOrDefault("continuation-token")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "continuation-token", valid_602107
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602108 = header.getOrDefault("x-amz-security-token")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "x-amz-security-token", valid_602108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602109: Call_ListBucketMetricsConfigurations_602102;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the metrics configurations for the bucket.
  ## 
  let valid = call_602109.validator(path, query, header, formData, body)
  let scheme = call_602109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602109.url(scheme.get, call_602109.host, call_602109.base,
                         call_602109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602109, url, valid)

proc call*(call_602110: Call_ListBucketMetricsConfigurations_602102; metrics: bool;
          Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketMetricsConfigurations
  ## Lists the metrics configurations for the bucket.
  ##   metrics: bool (required)
  ##   continuationToken: string
  ##                    : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configurations to retrieve.
  var path_602111 = newJObject()
  var query_602112 = newJObject()
  add(query_602112, "metrics", newJBool(metrics))
  add(query_602112, "continuation-token", newJString(continuationToken))
  add(path_602111, "Bucket", newJString(Bucket))
  result = call_602110.call(path_602111, query_602112, nil, nil, nil)

var listBucketMetricsConfigurations* = Call_ListBucketMetricsConfigurations_602102(
    name: "listBucketMetricsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics",
    validator: validate_ListBucketMetricsConfigurations_602103, base: "/",
    url: url_ListBucketMetricsConfigurations_602104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuckets_602113 = ref object of OpenApiRestCall_600437
proc url_ListBuckets_602115(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuckets_602114(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602116 = header.getOrDefault("x-amz-security-token")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "x-amz-security-token", valid_602116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602117: Call_ListBuckets_602113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  let valid = call_602117.validator(path, query, header, formData, body)
  let scheme = call_602117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602117.url(scheme.get, call_602117.host, call_602117.base,
                         call_602117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602117, url, valid)

proc call*(call_602118: Call_ListBuckets_602113): Recallable =
  ## listBuckets
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  result = call_602118.call(nil, nil, nil, nil, nil)

var listBuckets* = Call_ListBuckets_602113(name: "listBuckets",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com", route: "/",
                                        validator: validate_ListBuckets_602114,
                                        base: "/", url: url_ListBuckets_602115,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultipartUploads_602119 = ref object of OpenApiRestCall_600437
proc url_ListMultipartUploads_602121(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#uploads")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListMultipartUploads_602120(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists in-progress multipart uploads.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_602122 = path.getOrDefault("Bucket")
  valid_602122 = validateParameter(valid_602122, JString, required = true,
                                 default = nil)
  if valid_602122 != nil:
    section.add "Bucket", valid_602122
  result.add "path", section
  ## parameters in `query` object:
  ##   max-uploads: JInt
  ##              : Sets the maximum number of multipart uploads, from 1 to 1,000, to return in the response body. 1,000 is the maximum number of uploads that can be returned in a response.
  ##   key-marker: JString
  ##             : Together with upload-id-marker, this parameter specifies the multipart upload after which listing should begin.
  ##   encoding-type: JString
  ##                : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   uploads: JBool (required)
  ##   MaxUploads: JString
  ##             : Pagination limit
  ##   delimiter: JString
  ##            : Character you use to group keys.
  ##   prefix: JString
  ##         : Lists in-progress uploads only for those keys that begin with the specified prefix.
  ##   upload-id-marker: JString
  ##                   : Together with key-marker, specifies the multipart upload after which listing should begin. If key-marker is not specified, the upload-id-marker parameter is ignored.
  ##   KeyMarker: JString
  ##            : Pagination token
  ##   UploadIdMarker: JString
  ##                 : Pagination token
  section = newJObject()
  var valid_602123 = query.getOrDefault("max-uploads")
  valid_602123 = validateParameter(valid_602123, JInt, required = false, default = nil)
  if valid_602123 != nil:
    section.add "max-uploads", valid_602123
  var valid_602124 = query.getOrDefault("key-marker")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "key-marker", valid_602124
  var valid_602125 = query.getOrDefault("encoding-type")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = newJString("url"))
  if valid_602125 != nil:
    section.add "encoding-type", valid_602125
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_602126 = query.getOrDefault("uploads")
  valid_602126 = validateParameter(valid_602126, JBool, required = true, default = nil)
  if valid_602126 != nil:
    section.add "uploads", valid_602126
  var valid_602127 = query.getOrDefault("MaxUploads")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "MaxUploads", valid_602127
  var valid_602128 = query.getOrDefault("delimiter")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "delimiter", valid_602128
  var valid_602129 = query.getOrDefault("prefix")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "prefix", valid_602129
  var valid_602130 = query.getOrDefault("upload-id-marker")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "upload-id-marker", valid_602130
  var valid_602131 = query.getOrDefault("KeyMarker")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "KeyMarker", valid_602131
  var valid_602132 = query.getOrDefault("UploadIdMarker")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "UploadIdMarker", valid_602132
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602133 = header.getOrDefault("x-amz-security-token")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "x-amz-security-token", valid_602133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602134: Call_ListMultipartUploads_602119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists in-progress multipart uploads.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
  let valid = call_602134.validator(path, query, header, formData, body)
  let scheme = call_602134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602134.url(scheme.get, call_602134.host, call_602134.base,
                         call_602134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602134, url, valid)

proc call*(call_602135: Call_ListMultipartUploads_602119; uploads: bool;
          Bucket: string; maxUploads: int = 0; keyMarker: string = "";
          encodingType: string = "url"; MaxUploads: string = ""; delimiter: string = "";
          prefix: string = ""; uploadIdMarker: string = ""; KeyMarker: string = "";
          UploadIdMarker: string = ""): Recallable =
  ## listMultipartUploads
  ## This operation lists in-progress multipart uploads.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
  ##   maxUploads: int
  ##             : Sets the maximum number of multipart uploads, from 1 to 1,000, to return in the response body. 1,000 is the maximum number of uploads that can be returned in a response.
  ##   keyMarker: string
  ##            : Together with upload-id-marker, this parameter specifies the multipart upload after which listing should begin.
  ##   encodingType: string
  ##               : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   uploads: bool (required)
  ##   MaxUploads: string
  ##             : Pagination limit
  ##   delimiter: string
  ##            : Character you use to group keys.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   prefix: string
  ##         : Lists in-progress uploads only for those keys that begin with the specified prefix.
  ##   uploadIdMarker: string
  ##                 : Together with key-marker, specifies the multipart upload after which listing should begin. If key-marker is not specified, the upload-id-marker parameter is ignored.
  ##   KeyMarker: string
  ##            : Pagination token
  ##   UploadIdMarker: string
  ##                 : Pagination token
  var path_602136 = newJObject()
  var query_602137 = newJObject()
  add(query_602137, "max-uploads", newJInt(maxUploads))
  add(query_602137, "key-marker", newJString(keyMarker))
  add(query_602137, "encoding-type", newJString(encodingType))
  add(query_602137, "uploads", newJBool(uploads))
  add(query_602137, "MaxUploads", newJString(MaxUploads))
  add(query_602137, "delimiter", newJString(delimiter))
  add(path_602136, "Bucket", newJString(Bucket))
  add(query_602137, "prefix", newJString(prefix))
  add(query_602137, "upload-id-marker", newJString(uploadIdMarker))
  add(query_602137, "KeyMarker", newJString(KeyMarker))
  add(query_602137, "UploadIdMarker", newJString(UploadIdMarker))
  result = call_602135.call(path_602136, query_602137, nil, nil, nil)

var listMultipartUploads* = Call_ListMultipartUploads_602119(
    name: "listMultipartUploads", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#uploads",
    validator: validate_ListMultipartUploads_602120, base: "/",
    url: url_ListMultipartUploads_602121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectVersions_602138 = ref object of OpenApiRestCall_600437
proc url_ListObjectVersions_602140(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListObjectVersions_602139(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns metadata about all of the versions of objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_602141 = path.getOrDefault("Bucket")
  valid_602141 = validateParameter(valid_602141, JString, required = true,
                                 default = nil)
  if valid_602141 != nil:
    section.add "Bucket", valid_602141
  result.add "path", section
  ## parameters in `query` object:
  ##   key-marker: JString
  ##             : Specifies the key to start with when listing objects in a bucket.
  ##   max-keys: JInt
  ##           : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   VersionIdMarker: JString
  ##                  : Pagination token
  ##   versions: JBool (required)
  ##   encoding-type: JString
  ##                : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   version-id-marker: JString
  ##                    : Specifies the object version you want to start listing from.
  ##   delimiter: JString
  ##            : A delimiter is a character you use to group keys.
  ##   prefix: JString
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   MaxKeys: JString
  ##          : Pagination limit
  ##   KeyMarker: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602142 = query.getOrDefault("key-marker")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "key-marker", valid_602142
  var valid_602143 = query.getOrDefault("max-keys")
  valid_602143 = validateParameter(valid_602143, JInt, required = false, default = nil)
  if valid_602143 != nil:
    section.add "max-keys", valid_602143
  var valid_602144 = query.getOrDefault("VersionIdMarker")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "VersionIdMarker", valid_602144
  assert query != nil,
        "query argument is necessary due to required `versions` field"
  var valid_602145 = query.getOrDefault("versions")
  valid_602145 = validateParameter(valid_602145, JBool, required = true, default = nil)
  if valid_602145 != nil:
    section.add "versions", valid_602145
  var valid_602146 = query.getOrDefault("encoding-type")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = newJString("url"))
  if valid_602146 != nil:
    section.add "encoding-type", valid_602146
  var valid_602147 = query.getOrDefault("version-id-marker")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "version-id-marker", valid_602147
  var valid_602148 = query.getOrDefault("delimiter")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "delimiter", valid_602148
  var valid_602149 = query.getOrDefault("prefix")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "prefix", valid_602149
  var valid_602150 = query.getOrDefault("MaxKeys")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "MaxKeys", valid_602150
  var valid_602151 = query.getOrDefault("KeyMarker")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "KeyMarker", valid_602151
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602152 = header.getOrDefault("x-amz-security-token")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "x-amz-security-token", valid_602152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602153: Call_ListObjectVersions_602138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about all of the versions of objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
  let valid = call_602153.validator(path, query, header, formData, body)
  let scheme = call_602153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602153.url(scheme.get, call_602153.host, call_602153.base,
                         call_602153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602153, url, valid)

proc call*(call_602154: Call_ListObjectVersions_602138; versions: bool;
          Bucket: string; keyMarker: string = ""; maxKeys: int = 0;
          VersionIdMarker: string = ""; encodingType: string = "url";
          versionIdMarker: string = ""; delimiter: string = ""; prefix: string = "";
          MaxKeys: string = ""; KeyMarker: string = ""): Recallable =
  ## listObjectVersions
  ## Returns metadata about all of the versions of objects in a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
  ##   keyMarker: string
  ##            : Specifies the key to start with when listing objects in a bucket.
  ##   maxKeys: int
  ##          : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   VersionIdMarker: string
  ##                  : Pagination token
  ##   versions: bool (required)
  ##   encodingType: string
  ##               : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   versionIdMarker: string
  ##                  : Specifies the object version you want to start listing from.
  ##   delimiter: string
  ##            : A delimiter is a character you use to group keys.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   prefix: string
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   MaxKeys: string
  ##          : Pagination limit
  ##   KeyMarker: string
  ##            : Pagination token
  var path_602155 = newJObject()
  var query_602156 = newJObject()
  add(query_602156, "key-marker", newJString(keyMarker))
  add(query_602156, "max-keys", newJInt(maxKeys))
  add(query_602156, "VersionIdMarker", newJString(VersionIdMarker))
  add(query_602156, "versions", newJBool(versions))
  add(query_602156, "encoding-type", newJString(encodingType))
  add(query_602156, "version-id-marker", newJString(versionIdMarker))
  add(query_602156, "delimiter", newJString(delimiter))
  add(path_602155, "Bucket", newJString(Bucket))
  add(query_602156, "prefix", newJString(prefix))
  add(query_602156, "MaxKeys", newJString(MaxKeys))
  add(query_602156, "KeyMarker", newJString(KeyMarker))
  result = call_602154.call(path_602155, query_602156, nil, nil, nil)

var listObjectVersions* = Call_ListObjectVersions_602138(
    name: "listObjectVersions", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versions", validator: validate_ListObjectVersions_602139,
    base: "/", url: url_ListObjectVersions_602140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectsV2_602157 = ref object of OpenApiRestCall_600437
proc url_ListObjectsV2_602159(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#list-type=2")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListObjectsV2_602158(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. Note: ListObjectsV2 is the revised List Objects API and we recommend you use this revised API for new application development.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : Name of the bucket to list.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_602160 = path.getOrDefault("Bucket")
  valid_602160 = validateParameter(valid_602160, JString, required = true,
                                 default = nil)
  if valid_602160 != nil:
    section.add "Bucket", valid_602160
  result.add "path", section
  ## parameters in `query` object:
  ##   list-type: JString (required)
  ##   max-keys: JInt
  ##           : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   encoding-type: JString
  ##                : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   continuation-token: JString
  ##                     : ContinuationToken indicates Amazon S3 that the list is being continued on this bucket with a token. ContinuationToken is obfuscated and is not a real key
  ##   fetch-owner: JBool
  ##              : The owner field is not present in listV2 by default, if you want to return owner field with each key in the result then set the fetch owner field to true
  ##   delimiter: JString
  ##            : A delimiter is a character you use to group keys.
  ##   start-after: JString
  ##              : StartAfter is where you want Amazon S3 to start listing from. Amazon S3 starts listing after this specified key. StartAfter can be any key in the bucket
  ##   ContinuationToken: JString
  ##                    : Pagination token
  ##   prefix: JString
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   MaxKeys: JString
  ##          : Pagination limit
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `list-type` field"
  var valid_602161 = query.getOrDefault("list-type")
  valid_602161 = validateParameter(valid_602161, JString, required = true,
                                 default = newJString("2"))
  if valid_602161 != nil:
    section.add "list-type", valid_602161
  var valid_602162 = query.getOrDefault("max-keys")
  valid_602162 = validateParameter(valid_602162, JInt, required = false, default = nil)
  if valid_602162 != nil:
    section.add "max-keys", valid_602162
  var valid_602163 = query.getOrDefault("encoding-type")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = newJString("url"))
  if valid_602163 != nil:
    section.add "encoding-type", valid_602163
  var valid_602164 = query.getOrDefault("continuation-token")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "continuation-token", valid_602164
  var valid_602165 = query.getOrDefault("fetch-owner")
  valid_602165 = validateParameter(valid_602165, JBool, required = false, default = nil)
  if valid_602165 != nil:
    section.add "fetch-owner", valid_602165
  var valid_602166 = query.getOrDefault("delimiter")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "delimiter", valid_602166
  var valid_602167 = query.getOrDefault("start-after")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "start-after", valid_602167
  var valid_602168 = query.getOrDefault("ContinuationToken")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "ContinuationToken", valid_602168
  var valid_602169 = query.getOrDefault("prefix")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "prefix", valid_602169
  var valid_602170 = query.getOrDefault("MaxKeys")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "MaxKeys", valid_602170
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602171 = header.getOrDefault("x-amz-security-token")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "x-amz-security-token", valid_602171
  var valid_602172 = header.getOrDefault("x-amz-request-payer")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = newJString("requester"))
  if valid_602172 != nil:
    section.add "x-amz-request-payer", valid_602172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602173: Call_ListObjectsV2_602157; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. Note: ListObjectsV2 is the revised List Objects API and we recommend you use this revised API for new application development.
  ## 
  let valid = call_602173.validator(path, query, header, formData, body)
  let scheme = call_602173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602173.url(scheme.get, call_602173.host, call_602173.base,
                         call_602173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602173, url, valid)

proc call*(call_602174: Call_ListObjectsV2_602157; Bucket: string;
          listType: string = "2"; maxKeys: int = 0; encodingType: string = "url";
          continuationToken: string = ""; fetchOwner: bool = false;
          delimiter: string = ""; startAfter: string = "";
          ContinuationToken: string = ""; prefix: string = ""; MaxKeys: string = ""): Recallable =
  ## listObjectsV2
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. Note: ListObjectsV2 is the revised List Objects API and we recommend you use this revised API for new application development.
  ##   listType: string (required)
  ##   maxKeys: int
  ##          : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   encodingType: string
  ##               : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   continuationToken: string
  ##                    : ContinuationToken indicates Amazon S3 that the list is being continued on this bucket with a token. ContinuationToken is obfuscated and is not a real key
  ##   fetchOwner: bool
  ##             : The owner field is not present in listV2 by default, if you want to return owner field with each key in the result then set the fetch owner field to true
  ##   delimiter: string
  ##            : A delimiter is a character you use to group keys.
  ##   Bucket: string (required)
  ##         : Name of the bucket to list.
  ##   startAfter: string
  ##             : StartAfter is where you want Amazon S3 to start listing from. Amazon S3 starts listing after this specified key. StartAfter can be any key in the bucket
  ##   ContinuationToken: string
  ##                    : Pagination token
  ##   prefix: string
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   MaxKeys: string
  ##          : Pagination limit
  var path_602175 = newJObject()
  var query_602176 = newJObject()
  add(query_602176, "list-type", newJString(listType))
  add(query_602176, "max-keys", newJInt(maxKeys))
  add(query_602176, "encoding-type", newJString(encodingType))
  add(query_602176, "continuation-token", newJString(continuationToken))
  add(query_602176, "fetch-owner", newJBool(fetchOwner))
  add(query_602176, "delimiter", newJString(delimiter))
  add(path_602175, "Bucket", newJString(Bucket))
  add(query_602176, "start-after", newJString(startAfter))
  add(query_602176, "ContinuationToken", newJString(ContinuationToken))
  add(query_602176, "prefix", newJString(prefix))
  add(query_602176, "MaxKeys", newJString(MaxKeys))
  result = call_602174.call(path_602175, query_602176, nil, nil, nil)

var listObjectsV2* = Call_ListObjectsV2_602157(name: "listObjectsV2",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#list-type=2", validator: validate_ListObjectsV2_602158,
    base: "/", url: url_ListObjectsV2_602159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreObject_602177 = ref object of OpenApiRestCall_600437
proc url_RestoreObject_602179(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#restore")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_RestoreObject_602178(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Restores an archived copy of an object back into Amazon S3
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_602180 = path.getOrDefault("Key")
  valid_602180 = validateParameter(valid_602180, JString, required = true,
                                 default = nil)
  if valid_602180 != nil:
    section.add "Key", valid_602180
  var valid_602181 = path.getOrDefault("Bucket")
  valid_602181 = validateParameter(valid_602181, JString, required = true,
                                 default = nil)
  if valid_602181 != nil:
    section.add "Bucket", valid_602181
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   restore: JBool (required)
  section = newJObject()
  var valid_602182 = query.getOrDefault("versionId")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "versionId", valid_602182
  assert query != nil, "query argument is necessary due to required `restore` field"
  var valid_602183 = query.getOrDefault("restore")
  valid_602183 = validateParameter(valid_602183, JBool, required = true, default = nil)
  if valid_602183 != nil:
    section.add "restore", valid_602183
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602184 = header.getOrDefault("x-amz-security-token")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "x-amz-security-token", valid_602184
  var valid_602185 = header.getOrDefault("x-amz-request-payer")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = newJString("requester"))
  if valid_602185 != nil:
    section.add "x-amz-request-payer", valid_602185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602187: Call_RestoreObject_602177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restores an archived copy of an object back into Amazon S3
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  let valid = call_602187.validator(path, query, header, formData, body)
  let scheme = call_602187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602187.url(scheme.get, call_602187.host, call_602187.base,
                         call_602187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602187, url, valid)

proc call*(call_602188: Call_RestoreObject_602177; Key: string; restore: bool;
          Bucket: string; body: JsonNode; versionId: string = ""): Recallable =
  ## restoreObject
  ## Restores an archived copy of an object back into Amazon S3
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  ##   versionId: string
  ##            : <p/>
  ##   Key: string (required)
  ##      : <p/>
  ##   restore: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_602189 = newJObject()
  var query_602190 = newJObject()
  var body_602191 = newJObject()
  add(query_602190, "versionId", newJString(versionId))
  add(path_602189, "Key", newJString(Key))
  add(query_602190, "restore", newJBool(restore))
  add(path_602189, "Bucket", newJString(Bucket))
  if body != nil:
    body_602191 = body
  result = call_602188.call(path_602189, query_602190, nil, nil, body_602191)

var restoreObject* = Call_RestoreObject_602177(name: "restoreObject",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#restore", validator: validate_RestoreObject_602178,
    base: "/", url: url_RestoreObject_602179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SelectObjectContent_602192 = ref object of OpenApiRestCall_600437
proc url_SelectObjectContent_602194(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#select&select-type=2")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_SelectObjectContent_602193(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : The object key.
  ##   Bucket: JString (required)
  ##         : The S3 bucket.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_602195 = path.getOrDefault("Key")
  valid_602195 = validateParameter(valid_602195, JString, required = true,
                                 default = nil)
  if valid_602195 != nil:
    section.add "Key", valid_602195
  var valid_602196 = path.getOrDefault("Bucket")
  valid_602196 = validateParameter(valid_602196, JString, required = true,
                                 default = nil)
  if valid_602196 != nil:
    section.add "Bucket", valid_602196
  result.add "path", section
  ## parameters in `query` object:
  ##   select: JBool (required)
  ##   select-type: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `select` field"
  var valid_602197 = query.getOrDefault("select")
  valid_602197 = validateParameter(valid_602197, JBool, required = true, default = nil)
  if valid_602197 != nil:
    section.add "select", valid_602197
  var valid_602198 = query.getOrDefault("select-type")
  valid_602198 = validateParameter(valid_602198, JString, required = true,
                                 default = newJString("2"))
  if valid_602198 != nil:
    section.add "select-type", valid_602198
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : The SSE Customer Key MD5. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html"> Server-Side Encryption (Using Customer-Provided Encryption Keys</a>. 
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : The SSE Algorithm used to encrypt the object. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html"> Server-Side Encryption (Using Customer-Provided Encryption Keys</a>. 
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : The SSE Customer Key. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html"> Server-Side Encryption (Using Customer-Provided Encryption Keys</a>. 
  section = newJObject()
  var valid_602199 = header.getOrDefault("x-amz-security-token")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "x-amz-security-token", valid_602199
  var valid_602200 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_602200
  var valid_602201 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_602201
  var valid_602202 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_602202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602204: Call_SelectObjectContent_602192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ## 
  let valid = call_602204.validator(path, query, header, formData, body)
  let scheme = call_602204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602204.url(scheme.get, call_602204.host, call_602204.base,
                         call_602204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602204, url, valid)

proc call*(call_602205: Call_SelectObjectContent_602192; select: bool; Key: string;
          Bucket: string; body: JsonNode; selectType: string = "2"): Recallable =
  ## selectObjectContent
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ##   select: bool (required)
  ##   Key: string (required)
  ##      : The object key.
  ##   Bucket: string (required)
  ##         : The S3 bucket.
  ##   body: JObject (required)
  ##   selectType: string (required)
  var path_602206 = newJObject()
  var query_602207 = newJObject()
  var body_602208 = newJObject()
  add(query_602207, "select", newJBool(select))
  add(path_602206, "Key", newJString(Key))
  add(path_602206, "Bucket", newJString(Bucket))
  if body != nil:
    body_602208 = body
  add(query_602207, "select-type", newJString(selectType))
  result = call_602205.call(path_602206, query_602207, nil, nil, body_602208)

var selectObjectContent* = Call_SelectObjectContent_602192(
    name: "selectObjectContent", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#select&select-type=2",
    validator: validate_SelectObjectContent_602193, base: "/",
    url: url_SelectObjectContent_602194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPart_602209 = ref object of OpenApiRestCall_600437
proc url_UploadPart_602211(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"),
               (kind: ConstantSegment, value: "#partNumber&uploadId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UploadPart_602210(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : Object key for which the multipart upload was initiated.
  ##   Bucket: JString (required)
  ##         : Name of the bucket to which the multipart upload was initiated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_602212 = path.getOrDefault("Key")
  valid_602212 = validateParameter(valid_602212, JString, required = true,
                                 default = nil)
  if valid_602212 != nil:
    section.add "Key", valid_602212
  var valid_602213 = path.getOrDefault("Bucket")
  valid_602213 = validateParameter(valid_602213, JString, required = true,
                                 default = nil)
  if valid_602213 != nil:
    section.add "Bucket", valid_602213
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being uploaded.
  ##   partNumber: JInt (required)
  ##             : Part number of part being uploaded. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_602214 = query.getOrDefault("uploadId")
  valid_602214 = validateParameter(valid_602214, JString, required = true,
                                 default = nil)
  if valid_602214 != nil:
    section.add "uploadId", valid_602214
  var valid_602215 = query.getOrDefault("partNumber")
  valid_602215 = validateParameter(valid_602215, JInt, required = true, default = nil)
  if valid_602215 != nil:
    section.add "partNumber", valid_602215
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the part data. This parameter is auto-populated when using the command from the CLI. This parameted is required if object lock parameters are specified.
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  ##   Content-Length: JInt
  ##                 : Size of the body in bytes. This parameter is useful when the size of the body cannot be determined automatically.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header. This must be the same encryption key specified in the initiate multipart upload request.
  section = newJObject()
  var valid_602216 = header.getOrDefault("x-amz-security-token")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "x-amz-security-token", valid_602216
  var valid_602217 = header.getOrDefault("Content-MD5")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "Content-MD5", valid_602217
  var valid_602218 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_602218
  var valid_602219 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_602219
  var valid_602220 = header.getOrDefault("Content-Length")
  valid_602220 = validateParameter(valid_602220, JInt, required = false, default = nil)
  if valid_602220 != nil:
    section.add "Content-Length", valid_602220
  var valid_602221 = header.getOrDefault("x-amz-request-payer")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = newJString("requester"))
  if valid_602221 != nil:
    section.add "x-amz-request-payer", valid_602221
  var valid_602222 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_602222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602224: Call_UploadPart_602209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  let valid = call_602224.validator(path, query, header, formData, body)
  let scheme = call_602224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602224.url(scheme.get, call_602224.host, call_602224.base,
                         call_602224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602224, url, valid)

proc call*(call_602225: Call_UploadPart_602209; uploadId: string; partNumber: int;
          Key: string; Bucket: string; body: JsonNode): Recallable =
  ## uploadPart
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  ##   uploadId: string (required)
  ##           : Upload ID identifying the multipart upload whose part is being uploaded.
  ##   partNumber: int (required)
  ##             : Part number of part being uploaded. This is a positive integer between 1 and 10,000.
  ##   Key: string (required)
  ##      : Object key for which the multipart upload was initiated.
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the multipart upload was initiated.
  ##   body: JObject (required)
  var path_602226 = newJObject()
  var query_602227 = newJObject()
  var body_602228 = newJObject()
  add(query_602227, "uploadId", newJString(uploadId))
  add(query_602227, "partNumber", newJInt(partNumber))
  add(path_602226, "Key", newJString(Key))
  add(path_602226, "Bucket", newJString(Bucket))
  if body != nil:
    body_602228 = body
  result = call_602225.call(path_602226, query_602227, nil, nil, body_602228)

var uploadPart* = Call_UploadPart_602209(name: "uploadPart",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#partNumber&uploadId",
                                      validator: validate_UploadPart_602210,
                                      base: "/", url: url_UploadPart_602211,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPartCopy_602229 = ref object of OpenApiRestCall_600437
proc url_UploadPartCopy_602231(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  assert "Key" in path, "`Key` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Key"), (kind: ConstantSegment,
        value: "#x-amz-copy-source&partNumber&uploadId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UploadPartCopy_602230(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Uploads a part by copying data from an existing object as data source.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Key: JString (required)
  ##      : <p/>
  ##   Bucket: JString (required)
  ##         : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Key` field"
  var valid_602232 = path.getOrDefault("Key")
  valid_602232 = validateParameter(valid_602232, JString, required = true,
                                 default = nil)
  if valid_602232 != nil:
    section.add "Key", valid_602232
  var valid_602233 = path.getOrDefault("Bucket")
  valid_602233 = validateParameter(valid_602233, JString, required = true,
                                 default = nil)
  if valid_602233 != nil:
    section.add "Bucket", valid_602233
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being copied.
  ##   partNumber: JInt (required)
  ##             : Part number of part being copied. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_602234 = query.getOrDefault("uploadId")
  valid_602234 = validateParameter(valid_602234, JString, required = true,
                                 default = nil)
  if valid_602234 != nil:
    section.add "uploadId", valid_602234
  var valid_602235 = query.getOrDefault("partNumber")
  valid_602235 = validateParameter(valid_602235, JInt, required = true, default = nil)
  if valid_602235 != nil:
    section.add "partNumber", valid_602235
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-copy-source-server-side-encryption-customer-algorithm: JString
  ##                                                              : Specifies the algorithm to use when decrypting the source object (e.g., AES256).
  ##   x-amz-security-token: JString
  ##   x-amz-copy-source-if-modified-since: JString
  ##                                      : Copies the object if it has been modified since the specified time.
  ##   x-amz-copy-source-server-side-encryption-customer-key-MD5: JString
  ##                                                            : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-copy-source-range: JString
  ##                          : The range of bytes to copy from the source object. The range value must use the form bytes=first-last, where the first and last are the zero-based byte offsets to copy. For example, bytes=0-9 indicates that you want to copy the first ten bytes of the source. You can copy a range only if the source object is greater than 5 MB.
  ##   x-amz-copy-source-server-side-encryption-customer-key: JString
  ##                                                        : Specifies the customer-provided encryption key for Amazon S3 to use to decrypt the source object. The encryption key provided in this header must be one that was used when the source object was created.
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  ##   x-amz-copy-source: JString (required)
  ##                    : The name of the source bucket and key name of the source object, separated by a slash (/). Must be URL-encoded.
  ##   x-amz-copy-source-if-match: JString
  ##                             : Copies the object if its entity tag (ETag) matches the specified tag.
  ##   x-amz-copy-source-if-unmodified-since: JString
  ##                                        : Copies the object if it hasn't been modified since the specified time.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   x-amz-copy-source-if-none-match: JString
  ##                                  : Copies the object if its entity tag (ETag) is different than the specified ETag.
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header. This must be the same encryption key specified in the initiate multipart upload request.
  section = newJObject()
  var valid_602236 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_602236
  var valid_602237 = header.getOrDefault("x-amz-security-token")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "x-amz-security-token", valid_602237
  var valid_602238 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_602238
  var valid_602239 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_602239
  var valid_602240 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_602240
  var valid_602241 = header.getOrDefault("x-amz-copy-source-range")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "x-amz-copy-source-range", valid_602241
  var valid_602242 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_602242
  var valid_602243 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_602243
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_602244 = header.getOrDefault("x-amz-copy-source")
  valid_602244 = validateParameter(valid_602244, JString, required = true,
                                 default = nil)
  if valid_602244 != nil:
    section.add "x-amz-copy-source", valid_602244
  var valid_602245 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "x-amz-copy-source-if-match", valid_602245
  var valid_602246 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_602246
  var valid_602247 = header.getOrDefault("x-amz-request-payer")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = newJString("requester"))
  if valid_602247 != nil:
    section.add "x-amz-request-payer", valid_602247
  var valid_602248 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_602248
  var valid_602249 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_602249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602250: Call_UploadPartCopy_602229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads a part by copying data from an existing object as data source.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  let valid = call_602250.validator(path, query, header, formData, body)
  let scheme = call_602250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602250.url(scheme.get, call_602250.host, call_602250.base,
                         call_602250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602250, url, valid)

proc call*(call_602251: Call_UploadPartCopy_602229; uploadId: string;
          partNumber: int; Key: string; Bucket: string): Recallable =
  ## uploadPartCopy
  ## Uploads a part by copying data from an existing object as data source.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  ##   uploadId: string (required)
  ##           : Upload ID identifying the multipart upload whose part is being copied.
  ##   partNumber: int (required)
  ##             : Part number of part being copied. This is a positive integer between 1 and 10,000.
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_602252 = newJObject()
  var query_602253 = newJObject()
  add(query_602253, "uploadId", newJString(uploadId))
  add(query_602253, "partNumber", newJInt(partNumber))
  add(path_602252, "Key", newJString(Key))
  add(path_602252, "Bucket", newJString(Bucket))
  result = call_602251.call(path_602252, query_602253, nil, nil, nil)

var uploadPartCopy* = Call_UploadPartCopy_602229(name: "uploadPartCopy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#x-amz-copy-source&partNumber&uploadId",
    validator: validate_UploadPartCopy_602230, base: "/", url: url_UploadPartCopy_602231,
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
