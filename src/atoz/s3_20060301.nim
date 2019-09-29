
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  Call_CompleteMultipartUpload_594059 = ref object of OpenApiRestCall_593437
proc url_CompleteMultipartUpload_594061(protocol: Scheme; host: string; base: string;
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

proc validate_CompleteMultipartUpload_594060(path: JsonNode; query: JsonNode;
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
  var valid_594062 = path.getOrDefault("Key")
  valid_594062 = validateParameter(valid_594062, JString, required = true,
                                 default = nil)
  if valid_594062 != nil:
    section.add "Key", valid_594062
  var valid_594063 = path.getOrDefault("Bucket")
  valid_594063 = validateParameter(valid_594063, JString, required = true,
                                 default = nil)
  if valid_594063 != nil:
    section.add "Bucket", valid_594063
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : <p/>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_594064 = query.getOrDefault("uploadId")
  valid_594064 = validateParameter(valid_594064, JString, required = true,
                                 default = nil)
  if valid_594064 != nil:
    section.add "uploadId", valid_594064
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_594065 = header.getOrDefault("x-amz-security-token")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "x-amz-security-token", valid_594065
  var valid_594066 = header.getOrDefault("x-amz-request-payer")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = newJString("requester"))
  if valid_594066 != nil:
    section.add "x-amz-request-payer", valid_594066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594068: Call_CompleteMultipartUpload_594059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  let valid = call_594068.validator(path, query, header, formData, body)
  let scheme = call_594068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594068.url(scheme.get, call_594068.host, call_594068.base,
                         call_594068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594068, url, valid)

proc call*(call_594069: Call_CompleteMultipartUpload_594059; uploadId: string;
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
  var path_594070 = newJObject()
  var query_594071 = newJObject()
  var body_594072 = newJObject()
  add(query_594071, "uploadId", newJString(uploadId))
  add(path_594070, "Key", newJString(Key))
  add(path_594070, "Bucket", newJString(Bucket))
  if body != nil:
    body_594072 = body
  result = call_594069.call(path_594070, query_594071, nil, nil, body_594072)

var completeMultipartUpload* = Call_CompleteMultipartUpload_594059(
    name: "completeMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_CompleteMultipartUpload_594060, base: "/",
    url: url_CompleteMultipartUpload_594061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParts_593774 = ref object of OpenApiRestCall_593437
proc url_ListParts_593776(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListParts_593775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593902 = path.getOrDefault("Key")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = nil)
  if valid_593902 != nil:
    section.add "Key", valid_593902
  var valid_593903 = path.getOrDefault("Bucket")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = nil)
  if valid_593903 != nil:
    section.add "Bucket", valid_593903
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
  var valid_593904 = query.getOrDefault("max-parts")
  valid_593904 = validateParameter(valid_593904, JInt, required = false, default = nil)
  if valid_593904 != nil:
    section.add "max-parts", valid_593904
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_593905 = query.getOrDefault("uploadId")
  valid_593905 = validateParameter(valid_593905, JString, required = true,
                                 default = nil)
  if valid_593905 != nil:
    section.add "uploadId", valid_593905
  var valid_593906 = query.getOrDefault("MaxParts")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "MaxParts", valid_593906
  var valid_593907 = query.getOrDefault("part-number-marker")
  valid_593907 = validateParameter(valid_593907, JInt, required = false, default = nil)
  if valid_593907 != nil:
    section.add "part-number-marker", valid_593907
  var valid_593908 = query.getOrDefault("PartNumberMarker")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "PartNumberMarker", valid_593908
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_593909 = header.getOrDefault("x-amz-security-token")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "x-amz-security-token", valid_593909
  var valid_593923 = header.getOrDefault("x-amz-request-payer")
  valid_593923 = validateParameter(valid_593923, JString, required = false,
                                 default = newJString("requester"))
  if valid_593923 != nil:
    section.add "x-amz-request-payer", valid_593923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593946: Call_ListParts_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  let valid = call_593946.validator(path, query, header, formData, body)
  let scheme = call_593946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593946.url(scheme.get, call_593946.host, call_593946.base,
                         call_593946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593946, url, valid)

proc call*(call_594017: Call_ListParts_593774; uploadId: string; Key: string;
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
  var path_594018 = newJObject()
  var query_594020 = newJObject()
  add(query_594020, "max-parts", newJInt(maxParts))
  add(query_594020, "uploadId", newJString(uploadId))
  add(query_594020, "MaxParts", newJString(MaxParts))
  add(query_594020, "part-number-marker", newJInt(partNumberMarker))
  add(query_594020, "PartNumberMarker", newJString(PartNumberMarker))
  add(path_594018, "Key", newJString(Key))
  add(path_594018, "Bucket", newJString(Bucket))
  result = call_594017.call(path_594018, query_594020, nil, nil, nil)

var listParts* = Call_ListParts_593774(name: "listParts", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}#uploadId",
                                    validator: validate_ListParts_593775,
                                    base: "/", url: url_ListParts_593776,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortMultipartUpload_594073 = ref object of OpenApiRestCall_593437
proc url_AbortMultipartUpload_594075(protocol: Scheme; host: string; base: string;
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

proc validate_AbortMultipartUpload_594074(path: JsonNode; query: JsonNode;
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
  var valid_594076 = path.getOrDefault("Key")
  valid_594076 = validateParameter(valid_594076, JString, required = true,
                                 default = nil)
  if valid_594076 != nil:
    section.add "Key", valid_594076
  var valid_594077 = path.getOrDefault("Bucket")
  valid_594077 = validateParameter(valid_594077, JString, required = true,
                                 default = nil)
  if valid_594077 != nil:
    section.add "Bucket", valid_594077
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID that identifies the multipart upload.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_594078 = query.getOrDefault("uploadId")
  valid_594078 = validateParameter(valid_594078, JString, required = true,
                                 default = nil)
  if valid_594078 != nil:
    section.add "uploadId", valid_594078
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_594079 = header.getOrDefault("x-amz-security-token")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "x-amz-security-token", valid_594079
  var valid_594080 = header.getOrDefault("x-amz-request-payer")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = newJString("requester"))
  if valid_594080 != nil:
    section.add "x-amz-request-payer", valid_594080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594081: Call_AbortMultipartUpload_594073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  let valid = call_594081.validator(path, query, header, formData, body)
  let scheme = call_594081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594081.url(scheme.get, call_594081.host, call_594081.base,
                         call_594081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594081, url, valid)

proc call*(call_594082: Call_AbortMultipartUpload_594073; uploadId: string;
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
  var path_594083 = newJObject()
  var query_594084 = newJObject()
  add(query_594084, "uploadId", newJString(uploadId))
  add(path_594083, "Key", newJString(Key))
  add(path_594083, "Bucket", newJString(Bucket))
  result = call_594082.call(path_594083, query_594084, nil, nil, nil)

var abortMultipartUpload* = Call_AbortMultipartUpload_594073(
    name: "abortMultipartUpload", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_AbortMultipartUpload_594074, base: "/",
    url: url_AbortMultipartUpload_594075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyObject_594085 = ref object of OpenApiRestCall_593437
proc url_CopyObject_594087(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CopyObject_594086(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594088 = path.getOrDefault("Key")
  valid_594088 = validateParameter(valid_594088, JString, required = true,
                                 default = nil)
  if valid_594088 != nil:
    section.add "Key", valid_594088
  var valid_594089 = path.getOrDefault("Bucket")
  valid_594089 = validateParameter(valid_594089, JString, required = true,
                                 default = nil)
  if valid_594089 != nil:
    section.add "Bucket", valid_594089
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
  var valid_594090 = header.getOrDefault("Content-Disposition")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "Content-Disposition", valid_594090
  var valid_594091 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_594091
  var valid_594092 = header.getOrDefault("x-amz-grant-full-control")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "x-amz-grant-full-control", valid_594092
  var valid_594093 = header.getOrDefault("x-amz-security-token")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "x-amz-security-token", valid_594093
  var valid_594094 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_594094
  var valid_594095 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_594095
  var valid_594096 = header.getOrDefault("x-amz-tagging-directive")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = newJString("COPY"))
  if valid_594096 != nil:
    section.add "x-amz-tagging-directive", valid_594096
  var valid_594097 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_594097
  var valid_594098 = header.getOrDefault("x-amz-object-lock-mode")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_594098 != nil:
    section.add "x-amz-object-lock-mode", valid_594098
  var valid_594099 = header.getOrDefault("Cache-Control")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "Cache-Control", valid_594099
  var valid_594100 = header.getOrDefault("Content-Language")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "Content-Language", valid_594100
  var valid_594101 = header.getOrDefault("Content-Type")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "Content-Type", valid_594101
  var valid_594102 = header.getOrDefault("Expires")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "Expires", valid_594102
  var valid_594103 = header.getOrDefault("x-amz-website-redirect-location")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "x-amz-website-redirect-location", valid_594103
  var valid_594104 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_594104
  var valid_594105 = header.getOrDefault("x-amz-acl")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = newJString("private"))
  if valid_594105 != nil:
    section.add "x-amz-acl", valid_594105
  var valid_594106 = header.getOrDefault("x-amz-grant-read")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "x-amz-grant-read", valid_594106
  var valid_594107 = header.getOrDefault("x-amz-storage-class")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_594107 != nil:
    section.add "x-amz-storage-class", valid_594107
  var valid_594108 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = newJString("ON"))
  if valid_594108 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_594108
  var valid_594109 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_594109
  var valid_594110 = header.getOrDefault("x-amz-tagging")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "x-amz-tagging", valid_594110
  var valid_594111 = header.getOrDefault("x-amz-grant-read-acp")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "x-amz-grant-read-acp", valid_594111
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_594112 = header.getOrDefault("x-amz-copy-source")
  valid_594112 = validateParameter(valid_594112, JString, required = true,
                                 default = nil)
  if valid_594112 != nil:
    section.add "x-amz-copy-source", valid_594112
  var valid_594113 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "x-amz-server-side-encryption-context", valid_594113
  var valid_594114 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_594114
  var valid_594115 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_594115
  var valid_594116 = header.getOrDefault("x-amz-metadata-directive")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = newJString("COPY"))
  if valid_594116 != nil:
    section.add "x-amz-metadata-directive", valid_594116
  var valid_594117 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "x-amz-copy-source-if-match", valid_594117
  var valid_594118 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_594118
  var valid_594119 = header.getOrDefault("x-amz-grant-write-acp")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "x-amz-grant-write-acp", valid_594119
  var valid_594120 = header.getOrDefault("Content-Encoding")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "Content-Encoding", valid_594120
  var valid_594121 = header.getOrDefault("x-amz-request-payer")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = newJString("requester"))
  if valid_594121 != nil:
    section.add "x-amz-request-payer", valid_594121
  var valid_594122 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_594122
  var valid_594123 = header.getOrDefault("x-amz-server-side-encryption")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = newJString("AES256"))
  if valid_594123 != nil:
    section.add "x-amz-server-side-encryption", valid_594123
  var valid_594124 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_594124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594126: Call_CopyObject_594085; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  let valid = call_594126.validator(path, query, header, formData, body)
  let scheme = call_594126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594126.url(scheme.get, call_594126.host, call_594126.base,
                         call_594126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594126, url, valid)

proc call*(call_594127: Call_CopyObject_594085; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## copyObject
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594128 = newJObject()
  var body_594129 = newJObject()
  add(path_594128, "Key", newJString(Key))
  add(path_594128, "Bucket", newJString(Bucket))
  if body != nil:
    body_594129 = body
  result = call_594127.call(path_594128, nil, nil, nil, body_594129)

var copyObject* = Call_CopyObject_594085(name: "copyObject",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#x-amz-copy-source",
                                      validator: validate_CopyObject_594086,
                                      base: "/", url: url_CopyObject_594087,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBucket_594147 = ref object of OpenApiRestCall_593437
proc url_CreateBucket_594149(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBucket_594148(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594150 = path.getOrDefault("Bucket")
  valid_594150 = validateParameter(valid_594150, JString, required = true,
                                 default = nil)
  if valid_594150 != nil:
    section.add "Bucket", valid_594150
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
  var valid_594151 = header.getOrDefault("x-amz-security-token")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "x-amz-security-token", valid_594151
  var valid_594152 = header.getOrDefault("x-amz-acl")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = newJString("private"))
  if valid_594152 != nil:
    section.add "x-amz-acl", valid_594152
  var valid_594153 = header.getOrDefault("x-amz-grant-read")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "x-amz-grant-read", valid_594153
  var valid_594154 = header.getOrDefault("x-amz-grant-read-acp")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "x-amz-grant-read-acp", valid_594154
  var valid_594155 = header.getOrDefault("x-amz-bucket-object-lock-enabled")
  valid_594155 = validateParameter(valid_594155, JBool, required = false, default = nil)
  if valid_594155 != nil:
    section.add "x-amz-bucket-object-lock-enabled", valid_594155
  var valid_594156 = header.getOrDefault("x-amz-grant-write")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "x-amz-grant-write", valid_594156
  var valid_594157 = header.getOrDefault("x-amz-grant-write-acp")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "x-amz-grant-write-acp", valid_594157
  var valid_594158 = header.getOrDefault("x-amz-grant-full-control")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "x-amz-grant-full-control", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_CreateBucket_594147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_CreateBucket_594147; Bucket: string; body: JsonNode): Recallable =
  ## createBucket
  ## Creates a new bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594162 = newJObject()
  var body_594163 = newJObject()
  add(path_594162, "Bucket", newJString(Bucket))
  if body != nil:
    body_594163 = body
  result = call_594161.call(path_594162, nil, nil, nil, body_594163)

var createBucket* = Call_CreateBucket_594147(name: "createBucket",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_CreateBucket_594148, base: "/", url: url_CreateBucket_594149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadBucket_594172 = ref object of OpenApiRestCall_593437
proc url_HeadBucket_594174(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_HeadBucket_594173(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594175 = path.getOrDefault("Bucket")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = nil)
  if valid_594175 != nil:
    section.add "Bucket", valid_594175
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594176 = header.getOrDefault("x-amz-security-token")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "x-amz-security-token", valid_594176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594177: Call_HeadBucket_594172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  let valid = call_594177.validator(path, query, header, formData, body)
  let scheme = call_594177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594177.url(scheme.get, call_594177.host, call_594177.base,
                         call_594177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594177, url, valid)

proc call*(call_594178: Call_HeadBucket_594172; Bucket: string): Recallable =
  ## headBucket
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594179 = newJObject()
  add(path_594179, "Bucket", newJString(Bucket))
  result = call_594178.call(path_594179, nil, nil, nil, nil)

var headBucket* = Call_HeadBucket_594172(name: "headBucket",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}",
                                      validator: validate_HeadBucket_594173,
                                      base: "/", url: url_HeadBucket_594174,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjects_594130 = ref object of OpenApiRestCall_593437
proc url_ListObjects_594132(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjects_594131(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594133 = path.getOrDefault("Bucket")
  valid_594133 = validateParameter(valid_594133, JString, required = true,
                                 default = nil)
  if valid_594133 != nil:
    section.add "Bucket", valid_594133
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
  var valid_594134 = query.getOrDefault("max-keys")
  valid_594134 = validateParameter(valid_594134, JInt, required = false, default = nil)
  if valid_594134 != nil:
    section.add "max-keys", valid_594134
  var valid_594135 = query.getOrDefault("encoding-type")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = newJString("url"))
  if valid_594135 != nil:
    section.add "encoding-type", valid_594135
  var valid_594136 = query.getOrDefault("marker")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "marker", valid_594136
  var valid_594137 = query.getOrDefault("Marker")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "Marker", valid_594137
  var valid_594138 = query.getOrDefault("delimiter")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "delimiter", valid_594138
  var valid_594139 = query.getOrDefault("prefix")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "prefix", valid_594139
  var valid_594140 = query.getOrDefault("MaxKeys")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "MaxKeys", valid_594140
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_594141 = header.getOrDefault("x-amz-security-token")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "x-amz-security-token", valid_594141
  var valid_594142 = header.getOrDefault("x-amz-request-payer")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = newJString("requester"))
  if valid_594142 != nil:
    section.add "x-amz-request-payer", valid_594142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594143: Call_ListObjects_594130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
  let valid = call_594143.validator(path, query, header, formData, body)
  let scheme = call_594143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594143.url(scheme.get, call_594143.host, call_594143.base,
                         call_594143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594143, url, valid)

proc call*(call_594144: Call_ListObjects_594130; Bucket: string; maxKeys: int = 0;
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
  var path_594145 = newJObject()
  var query_594146 = newJObject()
  add(query_594146, "max-keys", newJInt(maxKeys))
  add(query_594146, "encoding-type", newJString(encodingType))
  add(query_594146, "marker", newJString(marker))
  add(query_594146, "Marker", newJString(Marker))
  add(query_594146, "delimiter", newJString(delimiter))
  add(path_594145, "Bucket", newJString(Bucket))
  add(query_594146, "prefix", newJString(prefix))
  add(query_594146, "MaxKeys", newJString(MaxKeys))
  result = call_594144.call(path_594145, query_594146, nil, nil, nil)

var listObjects* = Call_ListObjects_594130(name: "listObjects",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com",
                                        route: "/{Bucket}",
                                        validator: validate_ListObjects_594131,
                                        base: "/", url: url_ListObjects_594132,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucket_594164 = ref object of OpenApiRestCall_593437
proc url_DeleteBucket_594166(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucket_594165(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594167 = path.getOrDefault("Bucket")
  valid_594167 = validateParameter(valid_594167, JString, required = true,
                                 default = nil)
  if valid_594167 != nil:
    section.add "Bucket", valid_594167
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594168 = header.getOrDefault("x-amz-security-token")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "x-amz-security-token", valid_594168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594169: Call_DeleteBucket_594164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  let valid = call_594169.validator(path, query, header, formData, body)
  let scheme = call_594169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594169.url(scheme.get, call_594169.host, call_594169.base,
                         call_594169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594169, url, valid)

proc call*(call_594170: Call_DeleteBucket_594164; Bucket: string): Recallable =
  ## deleteBucket
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594171 = newJObject()
  add(path_594171, "Bucket", newJString(Bucket))
  result = call_594170.call(path_594171, nil, nil, nil, nil)

var deleteBucket* = Call_DeleteBucket_594164(name: "deleteBucket",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_DeleteBucket_594165, base: "/", url: url_DeleteBucket_594166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultipartUpload_594180 = ref object of OpenApiRestCall_593437
proc url_CreateMultipartUpload_594182(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMultipartUpload_594181(path: JsonNode; query: JsonNode;
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
  var valid_594183 = path.getOrDefault("Key")
  valid_594183 = validateParameter(valid_594183, JString, required = true,
                                 default = nil)
  if valid_594183 != nil:
    section.add "Key", valid_594183
  var valid_594184 = path.getOrDefault("Bucket")
  valid_594184 = validateParameter(valid_594184, JString, required = true,
                                 default = nil)
  if valid_594184 != nil:
    section.add "Bucket", valid_594184
  result.add "path", section
  ## parameters in `query` object:
  ##   uploads: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_594185 = query.getOrDefault("uploads")
  valid_594185 = validateParameter(valid_594185, JBool, required = true, default = nil)
  if valid_594185 != nil:
    section.add "uploads", valid_594185
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
  var valid_594186 = header.getOrDefault("Content-Disposition")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "Content-Disposition", valid_594186
  var valid_594187 = header.getOrDefault("x-amz-grant-full-control")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "x-amz-grant-full-control", valid_594187
  var valid_594188 = header.getOrDefault("x-amz-security-token")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "x-amz-security-token", valid_594188
  var valid_594189 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_594189
  var valid_594190 = header.getOrDefault("x-amz-object-lock-mode")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_594190 != nil:
    section.add "x-amz-object-lock-mode", valid_594190
  var valid_594191 = header.getOrDefault("Cache-Control")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "Cache-Control", valid_594191
  var valid_594192 = header.getOrDefault("Content-Language")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "Content-Language", valid_594192
  var valid_594193 = header.getOrDefault("Content-Type")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "Content-Type", valid_594193
  var valid_594194 = header.getOrDefault("Expires")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "Expires", valid_594194
  var valid_594195 = header.getOrDefault("x-amz-website-redirect-location")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "x-amz-website-redirect-location", valid_594195
  var valid_594196 = header.getOrDefault("x-amz-acl")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = newJString("private"))
  if valid_594196 != nil:
    section.add "x-amz-acl", valid_594196
  var valid_594197 = header.getOrDefault("x-amz-grant-read")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "x-amz-grant-read", valid_594197
  var valid_594198 = header.getOrDefault("x-amz-storage-class")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_594198 != nil:
    section.add "x-amz-storage-class", valid_594198
  var valid_594199 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = newJString("ON"))
  if valid_594199 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_594199
  var valid_594200 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_594200
  var valid_594201 = header.getOrDefault("x-amz-tagging")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "x-amz-tagging", valid_594201
  var valid_594202 = header.getOrDefault("x-amz-grant-read-acp")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "x-amz-grant-read-acp", valid_594202
  var valid_594203 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "x-amz-server-side-encryption-context", valid_594203
  var valid_594204 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_594204
  var valid_594205 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_594205
  var valid_594206 = header.getOrDefault("x-amz-grant-write-acp")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "x-amz-grant-write-acp", valid_594206
  var valid_594207 = header.getOrDefault("Content-Encoding")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "Content-Encoding", valid_594207
  var valid_594208 = header.getOrDefault("x-amz-request-payer")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = newJString("requester"))
  if valid_594208 != nil:
    section.add "x-amz-request-payer", valid_594208
  var valid_594209 = header.getOrDefault("x-amz-server-side-encryption")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = newJString("AES256"))
  if valid_594209 != nil:
    section.add "x-amz-server-side-encryption", valid_594209
  var valid_594210 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_594210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594212: Call_CreateMultipartUpload_594180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  let valid = call_594212.validator(path, query, header, formData, body)
  let scheme = call_594212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594212.url(scheme.get, call_594212.host, call_594212.base,
                         call_594212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594212, url, valid)

proc call*(call_594213: Call_CreateMultipartUpload_594180; Key: string;
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
  var path_594214 = newJObject()
  var query_594215 = newJObject()
  var body_594216 = newJObject()
  add(path_594214, "Key", newJString(Key))
  add(query_594215, "uploads", newJBool(uploads))
  add(path_594214, "Bucket", newJString(Bucket))
  if body != nil:
    body_594216 = body
  result = call_594213.call(path_594214, query_594215, nil, nil, body_594216)

var createMultipartUpload* = Call_CreateMultipartUpload_594180(
    name: "createMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploads",
    validator: validate_CreateMultipartUpload_594181, base: "/",
    url: url_CreateMultipartUpload_594182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAnalyticsConfiguration_594228 = ref object of OpenApiRestCall_593437
proc url_PutBucketAnalyticsConfiguration_594230(protocol: Scheme; host: string;
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

proc validate_PutBucketAnalyticsConfiguration_594229(path: JsonNode;
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
  var valid_594231 = path.getOrDefault("Bucket")
  valid_594231 = validateParameter(valid_594231, JString, required = true,
                                 default = nil)
  if valid_594231 != nil:
    section.add "Bucket", valid_594231
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_594232 = query.getOrDefault("id")
  valid_594232 = validateParameter(valid_594232, JString, required = true,
                                 default = nil)
  if valid_594232 != nil:
    section.add "id", valid_594232
  var valid_594233 = query.getOrDefault("analytics")
  valid_594233 = validateParameter(valid_594233, JBool, required = true, default = nil)
  if valid_594233 != nil:
    section.add "analytics", valid_594233
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594234 = header.getOrDefault("x-amz-security-token")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "x-amz-security-token", valid_594234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594236: Call_PutBucketAnalyticsConfiguration_594228;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_594236.validator(path, query, header, formData, body)
  let scheme = call_594236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594236.url(scheme.get, call_594236.host, call_594236.base,
                         call_594236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594236, url, valid)

proc call*(call_594237: Call_PutBucketAnalyticsConfiguration_594228; id: string;
          analytics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAnalyticsConfiguration
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket to which an analytics configuration is stored.
  ##   body: JObject (required)
  var path_594238 = newJObject()
  var query_594239 = newJObject()
  var body_594240 = newJObject()
  add(query_594239, "id", newJString(id))
  add(query_594239, "analytics", newJBool(analytics))
  add(path_594238, "Bucket", newJString(Bucket))
  if body != nil:
    body_594240 = body
  result = call_594237.call(path_594238, query_594239, nil, nil, body_594240)

var putBucketAnalyticsConfiguration* = Call_PutBucketAnalyticsConfiguration_594228(
    name: "putBucketAnalyticsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_PutBucketAnalyticsConfiguration_594229, base: "/",
    url: url_PutBucketAnalyticsConfiguration_594230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAnalyticsConfiguration_594217 = ref object of OpenApiRestCall_593437
proc url_GetBucketAnalyticsConfiguration_594219(protocol: Scheme; host: string;
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

proc validate_GetBucketAnalyticsConfiguration_594218(path: JsonNode;
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
  var valid_594220 = path.getOrDefault("Bucket")
  valid_594220 = validateParameter(valid_594220, JString, required = true,
                                 default = nil)
  if valid_594220 != nil:
    section.add "Bucket", valid_594220
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_594221 = query.getOrDefault("id")
  valid_594221 = validateParameter(valid_594221, JString, required = true,
                                 default = nil)
  if valid_594221 != nil:
    section.add "id", valid_594221
  var valid_594222 = query.getOrDefault("analytics")
  valid_594222 = validateParameter(valid_594222, JBool, required = true, default = nil)
  if valid_594222 != nil:
    section.add "analytics", valid_594222
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594223 = header.getOrDefault("x-amz-security-token")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "x-amz-security-token", valid_594223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594224: Call_GetBucketAnalyticsConfiguration_594217;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_594224.validator(path, query, header, formData, body)
  let scheme = call_594224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594224.url(scheme.get, call_594224.host, call_594224.base,
                         call_594224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594224, url, valid)

proc call*(call_594225: Call_GetBucketAnalyticsConfiguration_594217; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## getBucketAnalyticsConfiguration
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is retrieved.
  var path_594226 = newJObject()
  var query_594227 = newJObject()
  add(query_594227, "id", newJString(id))
  add(query_594227, "analytics", newJBool(analytics))
  add(path_594226, "Bucket", newJString(Bucket))
  result = call_594225.call(path_594226, query_594227, nil, nil, nil)

var getBucketAnalyticsConfiguration* = Call_GetBucketAnalyticsConfiguration_594217(
    name: "getBucketAnalyticsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_GetBucketAnalyticsConfiguration_594218, base: "/",
    url: url_GetBucketAnalyticsConfiguration_594219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketAnalyticsConfiguration_594241 = ref object of OpenApiRestCall_593437
proc url_DeleteBucketAnalyticsConfiguration_594243(protocol: Scheme; host: string;
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

proc validate_DeleteBucketAnalyticsConfiguration_594242(path: JsonNode;
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
  var valid_594244 = path.getOrDefault("Bucket")
  valid_594244 = validateParameter(valid_594244, JString, required = true,
                                 default = nil)
  if valid_594244 != nil:
    section.add "Bucket", valid_594244
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_594245 = query.getOrDefault("id")
  valid_594245 = validateParameter(valid_594245, JString, required = true,
                                 default = nil)
  if valid_594245 != nil:
    section.add "id", valid_594245
  var valid_594246 = query.getOrDefault("analytics")
  valid_594246 = validateParameter(valid_594246, JBool, required = true, default = nil)
  if valid_594246 != nil:
    section.add "analytics", valid_594246
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594247 = header.getOrDefault("x-amz-security-token")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "x-amz-security-token", valid_594247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594248: Call_DeleteBucketAnalyticsConfiguration_594241;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ## 
  let valid = call_594248.validator(path, query, header, formData, body)
  let scheme = call_594248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594248.url(scheme.get, call_594248.host, call_594248.base,
                         call_594248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594248, url, valid)

proc call*(call_594249: Call_DeleteBucketAnalyticsConfiguration_594241; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## deleteBucketAnalyticsConfiguration
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is deleted.
  var path_594250 = newJObject()
  var query_594251 = newJObject()
  add(query_594251, "id", newJString(id))
  add(query_594251, "analytics", newJBool(analytics))
  add(path_594250, "Bucket", newJString(Bucket))
  result = call_594249.call(path_594250, query_594251, nil, nil, nil)

var deleteBucketAnalyticsConfiguration* = Call_DeleteBucketAnalyticsConfiguration_594241(
    name: "deleteBucketAnalyticsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_DeleteBucketAnalyticsConfiguration_594242, base: "/",
    url: url_DeleteBucketAnalyticsConfiguration_594243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketCors_594262 = ref object of OpenApiRestCall_593437
proc url_PutBucketCors_594264(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketCors_594263(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594265 = path.getOrDefault("Bucket")
  valid_594265 = validateParameter(valid_594265, JString, required = true,
                                 default = nil)
  if valid_594265 != nil:
    section.add "Bucket", valid_594265
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_594266 = query.getOrDefault("cors")
  valid_594266 = validateParameter(valid_594266, JBool, required = true, default = nil)
  if valid_594266 != nil:
    section.add "cors", valid_594266
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_594267 = header.getOrDefault("x-amz-security-token")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "x-amz-security-token", valid_594267
  var valid_594268 = header.getOrDefault("Content-MD5")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "Content-MD5", valid_594268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594270: Call_PutBucketCors_594262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the CORS configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  let valid = call_594270.validator(path, query, header, formData, body)
  let scheme = call_594270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594270.url(scheme.get, call_594270.host, call_594270.base,
                         call_594270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594270, url, valid)

proc call*(call_594271: Call_PutBucketCors_594262; cors: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketCors
  ## Sets the CORS configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594272 = newJObject()
  var query_594273 = newJObject()
  var body_594274 = newJObject()
  add(query_594273, "cors", newJBool(cors))
  add(path_594272, "Bucket", newJString(Bucket))
  if body != nil:
    body_594274 = body
  result = call_594271.call(path_594272, query_594273, nil, nil, body_594274)

var putBucketCors* = Call_PutBucketCors_594262(name: "putBucketCors",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_PutBucketCors_594263, base: "/", url: url_PutBucketCors_594264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketCors_594252 = ref object of OpenApiRestCall_593437
proc url_GetBucketCors_594254(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketCors_594253(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594255 = path.getOrDefault("Bucket")
  valid_594255 = validateParameter(valid_594255, JString, required = true,
                                 default = nil)
  if valid_594255 != nil:
    section.add "Bucket", valid_594255
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_594256 = query.getOrDefault("cors")
  valid_594256 = validateParameter(valid_594256, JBool, required = true, default = nil)
  if valid_594256 != nil:
    section.add "cors", valid_594256
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594257 = header.getOrDefault("x-amz-security-token")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "x-amz-security-token", valid_594257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594258: Call_GetBucketCors_594252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the CORS configuration for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  let valid = call_594258.validator(path, query, header, formData, body)
  let scheme = call_594258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594258.url(scheme.get, call_594258.host, call_594258.base,
                         call_594258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594258, url, valid)

proc call*(call_594259: Call_GetBucketCors_594252; cors: bool; Bucket: string): Recallable =
  ## getBucketCors
  ## Returns the CORS configuration for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594260 = newJObject()
  var query_594261 = newJObject()
  add(query_594261, "cors", newJBool(cors))
  add(path_594260, "Bucket", newJString(Bucket))
  result = call_594259.call(path_594260, query_594261, nil, nil, nil)

var getBucketCors* = Call_GetBucketCors_594252(name: "getBucketCors",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_GetBucketCors_594253, base: "/", url: url_GetBucketCors_594254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketCors_594275 = ref object of OpenApiRestCall_593437
proc url_DeleteBucketCors_594277(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketCors_594276(path: JsonNode; query: JsonNode;
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
  var valid_594278 = path.getOrDefault("Bucket")
  valid_594278 = validateParameter(valid_594278, JString, required = true,
                                 default = nil)
  if valid_594278 != nil:
    section.add "Bucket", valid_594278
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_594279 = query.getOrDefault("cors")
  valid_594279 = validateParameter(valid_594279, JBool, required = true, default = nil)
  if valid_594279 != nil:
    section.add "cors", valid_594279
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594280 = header.getOrDefault("x-amz-security-token")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "x-amz-security-token", valid_594280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594281: Call_DeleteBucketCors_594275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the CORS configuration information set for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  let valid = call_594281.validator(path, query, header, formData, body)
  let scheme = call_594281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594281.url(scheme.get, call_594281.host, call_594281.base,
                         call_594281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594281, url, valid)

proc call*(call_594282: Call_DeleteBucketCors_594275; cors: bool; Bucket: string): Recallable =
  ## deleteBucketCors
  ## Deletes the CORS configuration information set for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594283 = newJObject()
  var query_594284 = newJObject()
  add(query_594284, "cors", newJBool(cors))
  add(path_594283, "Bucket", newJString(Bucket))
  result = call_594282.call(path_594283, query_594284, nil, nil, nil)

var deleteBucketCors* = Call_DeleteBucketCors_594275(name: "deleteBucketCors",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_DeleteBucketCors_594276, base: "/",
    url: url_DeleteBucketCors_594277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketEncryption_594295 = ref object of OpenApiRestCall_593437
proc url_PutBucketEncryption_594297(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketEncryption_594296(path: JsonNode; query: JsonNode;
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
  var valid_594298 = path.getOrDefault("Bucket")
  valid_594298 = validateParameter(valid_594298, JString, required = true,
                                 default = nil)
  if valid_594298 != nil:
    section.add "Bucket", valid_594298
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_594299 = query.getOrDefault("encryption")
  valid_594299 = validateParameter(valid_594299, JBool, required = true, default = nil)
  if valid_594299 != nil:
    section.add "encryption", valid_594299
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the server-side encryption configuration. This parameter is auto-populated when using the command from the CLI.
  section = newJObject()
  var valid_594300 = header.getOrDefault("x-amz-security-token")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "x-amz-security-token", valid_594300
  var valid_594301 = header.getOrDefault("Content-MD5")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "Content-MD5", valid_594301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594303: Call_PutBucketEncryption_594295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ## 
  let valid = call_594303.validator(path, query, header, formData, body)
  let scheme = call_594303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594303.url(scheme.get, call_594303.host, call_594303.base,
                         call_594303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594303, url, valid)

proc call*(call_594304: Call_PutBucketEncryption_594295; encryption: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketEncryption
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : Specifies default encryption for a bucket using server-side encryption with Amazon S3-managed keys (SSE-S3) or AWS KMS-managed keys (SSE-KMS). For information about the Amazon S3 default encryption feature, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 Default Bucket Encryption</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   body: JObject (required)
  var path_594305 = newJObject()
  var query_594306 = newJObject()
  var body_594307 = newJObject()
  add(query_594306, "encryption", newJBool(encryption))
  add(path_594305, "Bucket", newJString(Bucket))
  if body != nil:
    body_594307 = body
  result = call_594304.call(path_594305, query_594306, nil, nil, body_594307)

var putBucketEncryption* = Call_PutBucketEncryption_594295(
    name: "putBucketEncryption", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_PutBucketEncryption_594296,
    base: "/", url: url_PutBucketEncryption_594297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketEncryption_594285 = ref object of OpenApiRestCall_593437
proc url_GetBucketEncryption_594287(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketEncryption_594286(path: JsonNode; query: JsonNode;
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
  var valid_594288 = path.getOrDefault("Bucket")
  valid_594288 = validateParameter(valid_594288, JString, required = true,
                                 default = nil)
  if valid_594288 != nil:
    section.add "Bucket", valid_594288
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_594289 = query.getOrDefault("encryption")
  valid_594289 = validateParameter(valid_594289, JBool, required = true, default = nil)
  if valid_594289 != nil:
    section.add "encryption", valid_594289
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594290 = header.getOrDefault("x-amz-security-token")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "x-amz-security-token", valid_594290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594291: Call_GetBucketEncryption_594285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the server-side encryption configuration of a bucket.
  ## 
  let valid = call_594291.validator(path, query, header, formData, body)
  let scheme = call_594291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594291.url(scheme.get, call_594291.host, call_594291.base,
                         call_594291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594291, url, valid)

proc call*(call_594292: Call_GetBucketEncryption_594285; encryption: bool;
          Bucket: string): Recallable =
  ## getBucketEncryption
  ## Returns the server-side encryption configuration of a bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which the server-side encryption configuration is retrieved.
  var path_594293 = newJObject()
  var query_594294 = newJObject()
  add(query_594294, "encryption", newJBool(encryption))
  add(path_594293, "Bucket", newJString(Bucket))
  result = call_594292.call(path_594293, query_594294, nil, nil, nil)

var getBucketEncryption* = Call_GetBucketEncryption_594285(
    name: "getBucketEncryption", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_GetBucketEncryption_594286,
    base: "/", url: url_GetBucketEncryption_594287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketEncryption_594308 = ref object of OpenApiRestCall_593437
proc url_DeleteBucketEncryption_594310(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketEncryption_594309(path: JsonNode; query: JsonNode;
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
  var valid_594311 = path.getOrDefault("Bucket")
  valid_594311 = validateParameter(valid_594311, JString, required = true,
                                 default = nil)
  if valid_594311 != nil:
    section.add "Bucket", valid_594311
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_594312 = query.getOrDefault("encryption")
  valid_594312 = validateParameter(valid_594312, JBool, required = true, default = nil)
  if valid_594312 != nil:
    section.add "encryption", valid_594312
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594313 = header.getOrDefault("x-amz-security-token")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "x-amz-security-token", valid_594313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594314: Call_DeleteBucketEncryption_594308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the server-side encryption configuration from the bucket.
  ## 
  let valid = call_594314.validator(path, query, header, formData, body)
  let scheme = call_594314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594314.url(scheme.get, call_594314.host, call_594314.base,
                         call_594314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594314, url, valid)

proc call*(call_594315: Call_DeleteBucketEncryption_594308; encryption: bool;
          Bucket: string): Recallable =
  ## deleteBucketEncryption
  ## Deletes the server-side encryption configuration from the bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the server-side encryption configuration to delete.
  var path_594316 = newJObject()
  var query_594317 = newJObject()
  add(query_594317, "encryption", newJBool(encryption))
  add(path_594316, "Bucket", newJString(Bucket))
  result = call_594315.call(path_594316, query_594317, nil, nil, nil)

var deleteBucketEncryption* = Call_DeleteBucketEncryption_594308(
    name: "deleteBucketEncryption", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#encryption",
    validator: validate_DeleteBucketEncryption_594309, base: "/",
    url: url_DeleteBucketEncryption_594310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketInventoryConfiguration_594329 = ref object of OpenApiRestCall_593437
proc url_PutBucketInventoryConfiguration_594331(protocol: Scheme; host: string;
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

proc validate_PutBucketInventoryConfiguration_594330(path: JsonNode;
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
  var valid_594332 = path.getOrDefault("Bucket")
  valid_594332 = validateParameter(valid_594332, JString, required = true,
                                 default = nil)
  if valid_594332 != nil:
    section.add "Bucket", valid_594332
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_594333 = query.getOrDefault("inventory")
  valid_594333 = validateParameter(valid_594333, JBool, required = true, default = nil)
  if valid_594333 != nil:
    section.add "inventory", valid_594333
  var valid_594334 = query.getOrDefault("id")
  valid_594334 = validateParameter(valid_594334, JString, required = true,
                                 default = nil)
  if valid_594334 != nil:
    section.add "id", valid_594334
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594335 = header.getOrDefault("x-amz-security-token")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "x-amz-security-token", valid_594335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594337: Call_PutBucketInventoryConfiguration_594329;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_594337.validator(path, query, header, formData, body)
  let scheme = call_594337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594337.url(scheme.get, call_594337.host, call_594337.base,
                         call_594337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594337, url, valid)

proc call*(call_594338: Call_PutBucketInventoryConfiguration_594329;
          inventory: bool; id: string; Bucket: string; body: JsonNode): Recallable =
  ## putBucketInventoryConfiguration
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket where the inventory configuration will be stored.
  ##   body: JObject (required)
  var path_594339 = newJObject()
  var query_594340 = newJObject()
  var body_594341 = newJObject()
  add(query_594340, "inventory", newJBool(inventory))
  add(query_594340, "id", newJString(id))
  add(path_594339, "Bucket", newJString(Bucket))
  if body != nil:
    body_594341 = body
  result = call_594338.call(path_594339, query_594340, nil, nil, body_594341)

var putBucketInventoryConfiguration* = Call_PutBucketInventoryConfiguration_594329(
    name: "putBucketInventoryConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_PutBucketInventoryConfiguration_594330, base: "/",
    url: url_PutBucketInventoryConfiguration_594331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketInventoryConfiguration_594318 = ref object of OpenApiRestCall_593437
proc url_GetBucketInventoryConfiguration_594320(protocol: Scheme; host: string;
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

proc validate_GetBucketInventoryConfiguration_594319(path: JsonNode;
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
  var valid_594321 = path.getOrDefault("Bucket")
  valid_594321 = validateParameter(valid_594321, JString, required = true,
                                 default = nil)
  if valid_594321 != nil:
    section.add "Bucket", valid_594321
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_594322 = query.getOrDefault("inventory")
  valid_594322 = validateParameter(valid_594322, JBool, required = true, default = nil)
  if valid_594322 != nil:
    section.add "inventory", valid_594322
  var valid_594323 = query.getOrDefault("id")
  valid_594323 = validateParameter(valid_594323, JString, required = true,
                                 default = nil)
  if valid_594323 != nil:
    section.add "id", valid_594323
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594324 = header.getOrDefault("x-amz-security-token")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "x-amz-security-token", valid_594324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594325: Call_GetBucketInventoryConfiguration_594318;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_594325.validator(path, query, header, formData, body)
  let scheme = call_594325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594325.url(scheme.get, call_594325.host, call_594325.base,
                         call_594325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594325, url, valid)

proc call*(call_594326: Call_GetBucketInventoryConfiguration_594318;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## getBucketInventoryConfiguration
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to retrieve.
  var path_594327 = newJObject()
  var query_594328 = newJObject()
  add(query_594328, "inventory", newJBool(inventory))
  add(query_594328, "id", newJString(id))
  add(path_594327, "Bucket", newJString(Bucket))
  result = call_594326.call(path_594327, query_594328, nil, nil, nil)

var getBucketInventoryConfiguration* = Call_GetBucketInventoryConfiguration_594318(
    name: "getBucketInventoryConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_GetBucketInventoryConfiguration_594319, base: "/",
    url: url_GetBucketInventoryConfiguration_594320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketInventoryConfiguration_594342 = ref object of OpenApiRestCall_593437
proc url_DeleteBucketInventoryConfiguration_594344(protocol: Scheme; host: string;
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

proc validate_DeleteBucketInventoryConfiguration_594343(path: JsonNode;
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
  var valid_594345 = path.getOrDefault("Bucket")
  valid_594345 = validateParameter(valid_594345, JString, required = true,
                                 default = nil)
  if valid_594345 != nil:
    section.add "Bucket", valid_594345
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_594346 = query.getOrDefault("inventory")
  valid_594346 = validateParameter(valid_594346, JBool, required = true, default = nil)
  if valid_594346 != nil:
    section.add "inventory", valid_594346
  var valid_594347 = query.getOrDefault("id")
  valid_594347 = validateParameter(valid_594347, JString, required = true,
                                 default = nil)
  if valid_594347 != nil:
    section.add "id", valid_594347
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594348 = header.getOrDefault("x-amz-security-token")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "x-amz-security-token", valid_594348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594349: Call_DeleteBucketInventoryConfiguration_594342;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_594349.validator(path, query, header, formData, body)
  let scheme = call_594349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594349.url(scheme.get, call_594349.host, call_594349.base,
                         call_594349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594349, url, valid)

proc call*(call_594350: Call_DeleteBucketInventoryConfiguration_594342;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## deleteBucketInventoryConfiguration
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to delete.
  var path_594351 = newJObject()
  var query_594352 = newJObject()
  add(query_594352, "inventory", newJBool(inventory))
  add(query_594352, "id", newJString(id))
  add(path_594351, "Bucket", newJString(Bucket))
  result = call_594350.call(path_594351, query_594352, nil, nil, nil)

var deleteBucketInventoryConfiguration* = Call_DeleteBucketInventoryConfiguration_594342(
    name: "deleteBucketInventoryConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_DeleteBucketInventoryConfiguration_594343, base: "/",
    url: url_DeleteBucketInventoryConfiguration_594344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycleConfiguration_594363 = ref object of OpenApiRestCall_593437
proc url_PutBucketLifecycleConfiguration_594365(protocol: Scheme; host: string;
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

proc validate_PutBucketLifecycleConfiguration_594364(path: JsonNode;
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
  var valid_594366 = path.getOrDefault("Bucket")
  valid_594366 = validateParameter(valid_594366, JString, required = true,
                                 default = nil)
  if valid_594366 != nil:
    section.add "Bucket", valid_594366
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_594367 = query.getOrDefault("lifecycle")
  valid_594367 = validateParameter(valid_594367, JBool, required = true, default = nil)
  if valid_594367 != nil:
    section.add "lifecycle", valid_594367
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594368 = header.getOrDefault("x-amz-security-token")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "x-amz-security-token", valid_594368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594370: Call_PutBucketLifecycleConfiguration_594363;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ## 
  let valid = call_594370.validator(path, query, header, formData, body)
  let scheme = call_594370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594370.url(scheme.get, call_594370.host, call_594370.base,
                         call_594370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594370, url, valid)

proc call*(call_594371: Call_PutBucketLifecycleConfiguration_594363;
          Bucket: string; lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycleConfiguration
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_594372 = newJObject()
  var query_594373 = newJObject()
  var body_594374 = newJObject()
  add(path_594372, "Bucket", newJString(Bucket))
  add(query_594373, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_594374 = body
  result = call_594371.call(path_594372, query_594373, nil, nil, body_594374)

var putBucketLifecycleConfiguration* = Call_PutBucketLifecycleConfiguration_594363(
    name: "putBucketLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_PutBucketLifecycleConfiguration_594364, base: "/",
    url: url_PutBucketLifecycleConfiguration_594365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycleConfiguration_594353 = ref object of OpenApiRestCall_593437
proc url_GetBucketLifecycleConfiguration_594355(protocol: Scheme; host: string;
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

proc validate_GetBucketLifecycleConfiguration_594354(path: JsonNode;
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
  var valid_594356 = path.getOrDefault("Bucket")
  valid_594356 = validateParameter(valid_594356, JString, required = true,
                                 default = nil)
  if valid_594356 != nil:
    section.add "Bucket", valid_594356
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_594357 = query.getOrDefault("lifecycle")
  valid_594357 = validateParameter(valid_594357, JBool, required = true, default = nil)
  if valid_594357 != nil:
    section.add "lifecycle", valid_594357
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594358 = header.getOrDefault("x-amz-security-token")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "x-amz-security-token", valid_594358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594359: Call_GetBucketLifecycleConfiguration_594353;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the lifecycle configuration information set on the bucket.
  ## 
  let valid = call_594359.validator(path, query, header, formData, body)
  let scheme = call_594359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594359.url(scheme.get, call_594359.host, call_594359.base,
                         call_594359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594359, url, valid)

proc call*(call_594360: Call_GetBucketLifecycleConfiguration_594353;
          Bucket: string; lifecycle: bool): Recallable =
  ## getBucketLifecycleConfiguration
  ## Returns the lifecycle configuration information set on the bucket.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_594361 = newJObject()
  var query_594362 = newJObject()
  add(path_594361, "Bucket", newJString(Bucket))
  add(query_594362, "lifecycle", newJBool(lifecycle))
  result = call_594360.call(path_594361, query_594362, nil, nil, nil)

var getBucketLifecycleConfiguration* = Call_GetBucketLifecycleConfiguration_594353(
    name: "getBucketLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_GetBucketLifecycleConfiguration_594354, base: "/",
    url: url_GetBucketLifecycleConfiguration_594355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketLifecycle_594375 = ref object of OpenApiRestCall_593437
proc url_DeleteBucketLifecycle_594377(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketLifecycle_594376(path: JsonNode; query: JsonNode;
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
  var valid_594378 = path.getOrDefault("Bucket")
  valid_594378 = validateParameter(valid_594378, JString, required = true,
                                 default = nil)
  if valid_594378 != nil:
    section.add "Bucket", valid_594378
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_594379 = query.getOrDefault("lifecycle")
  valid_594379 = validateParameter(valid_594379, JBool, required = true, default = nil)
  if valid_594379 != nil:
    section.add "lifecycle", valid_594379
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594380 = header.getOrDefault("x-amz-security-token")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "x-amz-security-token", valid_594380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594381: Call_DeleteBucketLifecycle_594375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the lifecycle configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  let valid = call_594381.validator(path, query, header, formData, body)
  let scheme = call_594381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594381.url(scheme.get, call_594381.host, call_594381.base,
                         call_594381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594381, url, valid)

proc call*(call_594382: Call_DeleteBucketLifecycle_594375; Bucket: string;
          lifecycle: bool): Recallable =
  ## deleteBucketLifecycle
  ## Deletes the lifecycle configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_594383 = newJObject()
  var query_594384 = newJObject()
  add(path_594383, "Bucket", newJString(Bucket))
  add(query_594384, "lifecycle", newJBool(lifecycle))
  result = call_594382.call(path_594383, query_594384, nil, nil, nil)

var deleteBucketLifecycle* = Call_DeleteBucketLifecycle_594375(
    name: "deleteBucketLifecycle", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_DeleteBucketLifecycle_594376, base: "/",
    url: url_DeleteBucketLifecycle_594377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketMetricsConfiguration_594396 = ref object of OpenApiRestCall_593437
proc url_PutBucketMetricsConfiguration_594398(protocol: Scheme; host: string;
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

proc validate_PutBucketMetricsConfiguration_594397(path: JsonNode; query: JsonNode;
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
  var valid_594399 = path.getOrDefault("Bucket")
  valid_594399 = validateParameter(valid_594399, JString, required = true,
                                 default = nil)
  if valid_594399 != nil:
    section.add "Bucket", valid_594399
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_594400 = query.getOrDefault("id")
  valid_594400 = validateParameter(valid_594400, JString, required = true,
                                 default = nil)
  if valid_594400 != nil:
    section.add "id", valid_594400
  var valid_594401 = query.getOrDefault("metrics")
  valid_594401 = validateParameter(valid_594401, JBool, required = true, default = nil)
  if valid_594401 != nil:
    section.add "metrics", valid_594401
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594402 = header.getOrDefault("x-amz-security-token")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "x-amz-security-token", valid_594402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594404: Call_PutBucketMetricsConfiguration_594396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ## 
  let valid = call_594404.validator(path, query, header, formData, body)
  let scheme = call_594404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594404.url(scheme.get, call_594404.host, call_594404.base,
                         call_594404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594404, url, valid)

proc call*(call_594405: Call_PutBucketMetricsConfiguration_594396; id: string;
          metrics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketMetricsConfiguration
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket for which the metrics configuration is set.
  ##   body: JObject (required)
  var path_594406 = newJObject()
  var query_594407 = newJObject()
  var body_594408 = newJObject()
  add(query_594407, "id", newJString(id))
  add(query_594407, "metrics", newJBool(metrics))
  add(path_594406, "Bucket", newJString(Bucket))
  if body != nil:
    body_594408 = body
  result = call_594405.call(path_594406, query_594407, nil, nil, body_594408)

var putBucketMetricsConfiguration* = Call_PutBucketMetricsConfiguration_594396(
    name: "putBucketMetricsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_PutBucketMetricsConfiguration_594397, base: "/",
    url: url_PutBucketMetricsConfiguration_594398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketMetricsConfiguration_594385 = ref object of OpenApiRestCall_593437
proc url_GetBucketMetricsConfiguration_594387(protocol: Scheme; host: string;
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

proc validate_GetBucketMetricsConfiguration_594386(path: JsonNode; query: JsonNode;
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
  var valid_594388 = path.getOrDefault("Bucket")
  valid_594388 = validateParameter(valid_594388, JString, required = true,
                                 default = nil)
  if valid_594388 != nil:
    section.add "Bucket", valid_594388
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_594389 = query.getOrDefault("id")
  valid_594389 = validateParameter(valid_594389, JString, required = true,
                                 default = nil)
  if valid_594389 != nil:
    section.add "id", valid_594389
  var valid_594390 = query.getOrDefault("metrics")
  valid_594390 = validateParameter(valid_594390, JBool, required = true, default = nil)
  if valid_594390 != nil:
    section.add "metrics", valid_594390
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594391 = header.getOrDefault("x-amz-security-token")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "x-amz-security-token", valid_594391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594392: Call_GetBucketMetricsConfiguration_594385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_594392.validator(path, query, header, formData, body)
  let scheme = call_594392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594392.url(scheme.get, call_594392.host, call_594392.base,
                         call_594392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594392, url, valid)

proc call*(call_594393: Call_GetBucketMetricsConfiguration_594385; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## getBucketMetricsConfiguration
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to retrieve.
  var path_594394 = newJObject()
  var query_594395 = newJObject()
  add(query_594395, "id", newJString(id))
  add(query_594395, "metrics", newJBool(metrics))
  add(path_594394, "Bucket", newJString(Bucket))
  result = call_594393.call(path_594394, query_594395, nil, nil, nil)

var getBucketMetricsConfiguration* = Call_GetBucketMetricsConfiguration_594385(
    name: "getBucketMetricsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_GetBucketMetricsConfiguration_594386, base: "/",
    url: url_GetBucketMetricsConfiguration_594387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketMetricsConfiguration_594409 = ref object of OpenApiRestCall_593437
proc url_DeleteBucketMetricsConfiguration_594411(protocol: Scheme; host: string;
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

proc validate_DeleteBucketMetricsConfiguration_594410(path: JsonNode;
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
  var valid_594412 = path.getOrDefault("Bucket")
  valid_594412 = validateParameter(valid_594412, JString, required = true,
                                 default = nil)
  if valid_594412 != nil:
    section.add "Bucket", valid_594412
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_594413 = query.getOrDefault("id")
  valid_594413 = validateParameter(valid_594413, JString, required = true,
                                 default = nil)
  if valid_594413 != nil:
    section.add "id", valid_594413
  var valid_594414 = query.getOrDefault("metrics")
  valid_594414 = validateParameter(valid_594414, JBool, required = true, default = nil)
  if valid_594414 != nil:
    section.add "metrics", valid_594414
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594415 = header.getOrDefault("x-amz-security-token")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "x-amz-security-token", valid_594415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594416: Call_DeleteBucketMetricsConfiguration_594409;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_594416.validator(path, query, header, formData, body)
  let scheme = call_594416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594416.url(scheme.get, call_594416.host, call_594416.base,
                         call_594416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594416, url, valid)

proc call*(call_594417: Call_DeleteBucketMetricsConfiguration_594409; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## deleteBucketMetricsConfiguration
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to delete.
  var path_594418 = newJObject()
  var query_594419 = newJObject()
  add(query_594419, "id", newJString(id))
  add(query_594419, "metrics", newJBool(metrics))
  add(path_594418, "Bucket", newJString(Bucket))
  result = call_594417.call(path_594418, query_594419, nil, nil, nil)

var deleteBucketMetricsConfiguration* = Call_DeleteBucketMetricsConfiguration_594409(
    name: "deleteBucketMetricsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_DeleteBucketMetricsConfiguration_594410, base: "/",
    url: url_DeleteBucketMetricsConfiguration_594411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketPolicy_594430 = ref object of OpenApiRestCall_593437
proc url_PutBucketPolicy_594432(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketPolicy_594431(path: JsonNode; query: JsonNode;
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
  var valid_594433 = path.getOrDefault("Bucket")
  valid_594433 = validateParameter(valid_594433, JString, required = true,
                                 default = nil)
  if valid_594433 != nil:
    section.add "Bucket", valid_594433
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_594434 = query.getOrDefault("policy")
  valid_594434 = validateParameter(valid_594434, JBool, required = true, default = nil)
  if valid_594434 != nil:
    section.add "policy", valid_594434
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-confirm-remove-self-bucket-access: JBool
  ##                                          : Set this parameter to true to confirm that you want to remove your permissions to change this bucket policy in the future.
  section = newJObject()
  var valid_594435 = header.getOrDefault("x-amz-security-token")
  valid_594435 = validateParameter(valid_594435, JString, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "x-amz-security-token", valid_594435
  var valid_594436 = header.getOrDefault("Content-MD5")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "Content-MD5", valid_594436
  var valid_594437 = header.getOrDefault("x-amz-confirm-remove-self-bucket-access")
  valid_594437 = validateParameter(valid_594437, JBool, required = false, default = nil)
  if valid_594437 != nil:
    section.add "x-amz-confirm-remove-self-bucket-access", valid_594437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594439: Call_PutBucketPolicy_594430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  let valid = call_594439.validator(path, query, header, formData, body)
  let scheme = call_594439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594439.url(scheme.get, call_594439.host, call_594439.base,
                         call_594439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594439, url, valid)

proc call*(call_594440: Call_PutBucketPolicy_594430; policy: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketPolicy
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594441 = newJObject()
  var query_594442 = newJObject()
  var body_594443 = newJObject()
  add(query_594442, "policy", newJBool(policy))
  add(path_594441, "Bucket", newJString(Bucket))
  if body != nil:
    body_594443 = body
  result = call_594440.call(path_594441, query_594442, nil, nil, body_594443)

var putBucketPolicy* = Call_PutBucketPolicy_594430(name: "putBucketPolicy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_PutBucketPolicy_594431, base: "/", url: url_PutBucketPolicy_594432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicy_594420 = ref object of OpenApiRestCall_593437
proc url_GetBucketPolicy_594422(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketPolicy_594421(path: JsonNode; query: JsonNode;
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
  var valid_594423 = path.getOrDefault("Bucket")
  valid_594423 = validateParameter(valid_594423, JString, required = true,
                                 default = nil)
  if valid_594423 != nil:
    section.add "Bucket", valid_594423
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_594424 = query.getOrDefault("policy")
  valid_594424 = validateParameter(valid_594424, JBool, required = true, default = nil)
  if valid_594424 != nil:
    section.add "policy", valid_594424
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594425 = header.getOrDefault("x-amz-security-token")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "x-amz-security-token", valid_594425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594426: Call_GetBucketPolicy_594420; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the policy of a specified bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  let valid = call_594426.validator(path, query, header, formData, body)
  let scheme = call_594426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594426.url(scheme.get, call_594426.host, call_594426.base,
                         call_594426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594426, url, valid)

proc call*(call_594427: Call_GetBucketPolicy_594420; policy: bool; Bucket: string): Recallable =
  ## getBucketPolicy
  ## Returns the policy of a specified bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594428 = newJObject()
  var query_594429 = newJObject()
  add(query_594429, "policy", newJBool(policy))
  add(path_594428, "Bucket", newJString(Bucket))
  result = call_594427.call(path_594428, query_594429, nil, nil, nil)

var getBucketPolicy* = Call_GetBucketPolicy_594420(name: "getBucketPolicy",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_GetBucketPolicy_594421, base: "/", url: url_GetBucketPolicy_594422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketPolicy_594444 = ref object of OpenApiRestCall_593437
proc url_DeleteBucketPolicy_594446(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketPolicy_594445(path: JsonNode; query: JsonNode;
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
  var valid_594447 = path.getOrDefault("Bucket")
  valid_594447 = validateParameter(valid_594447, JString, required = true,
                                 default = nil)
  if valid_594447 != nil:
    section.add "Bucket", valid_594447
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_594448 = query.getOrDefault("policy")
  valid_594448 = validateParameter(valid_594448, JBool, required = true, default = nil)
  if valid_594448 != nil:
    section.add "policy", valid_594448
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594449 = header.getOrDefault("x-amz-security-token")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "x-amz-security-token", valid_594449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594450: Call_DeleteBucketPolicy_594444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  let valid = call_594450.validator(path, query, header, formData, body)
  let scheme = call_594450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594450.url(scheme.get, call_594450.host, call_594450.base,
                         call_594450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594450, url, valid)

proc call*(call_594451: Call_DeleteBucketPolicy_594444; policy: bool; Bucket: string): Recallable =
  ## deleteBucketPolicy
  ## Deletes the policy from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594452 = newJObject()
  var query_594453 = newJObject()
  add(query_594453, "policy", newJBool(policy))
  add(path_594452, "Bucket", newJString(Bucket))
  result = call_594451.call(path_594452, query_594453, nil, nil, nil)

var deleteBucketPolicy* = Call_DeleteBucketPolicy_594444(
    name: "deleteBucketPolicy", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_DeleteBucketPolicy_594445, base: "/",
    url: url_DeleteBucketPolicy_594446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketReplication_594464 = ref object of OpenApiRestCall_593437
proc url_PutBucketReplication_594466(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketReplication_594465(path: JsonNode; query: JsonNode;
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
  var valid_594467 = path.getOrDefault("Bucket")
  valid_594467 = validateParameter(valid_594467, JString, required = true,
                                 default = nil)
  if valid_594467 != nil:
    section.add "Bucket", valid_594467
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_594468 = query.getOrDefault("replication")
  valid_594468 = validateParameter(valid_594468, JBool, required = true, default = nil)
  if valid_594468 != nil:
    section.add "replication", valid_594468
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit.
  ##   x-amz-bucket-object-lock-token: JString
  ##                                 : A token that allows Amazon S3 object lock to be enabled for an existing bucket.
  section = newJObject()
  var valid_594469 = header.getOrDefault("x-amz-security-token")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "x-amz-security-token", valid_594469
  var valid_594470 = header.getOrDefault("Content-MD5")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "Content-MD5", valid_594470
  var valid_594471 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_594471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594473: Call_PutBucketReplication_594464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_594473.validator(path, query, header, formData, body)
  let scheme = call_594473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594473.url(scheme.get, call_594473.host, call_594473.base,
                         call_594473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594473, url, valid)

proc call*(call_594474: Call_PutBucketReplication_594464; replication: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketReplication
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594475 = newJObject()
  var query_594476 = newJObject()
  var body_594477 = newJObject()
  add(query_594476, "replication", newJBool(replication))
  add(path_594475, "Bucket", newJString(Bucket))
  if body != nil:
    body_594477 = body
  result = call_594474.call(path_594475, query_594476, nil, nil, body_594477)

var putBucketReplication* = Call_PutBucketReplication_594464(
    name: "putBucketReplication", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_PutBucketReplication_594465, base: "/",
    url: url_PutBucketReplication_594466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketReplication_594454 = ref object of OpenApiRestCall_593437
proc url_GetBucketReplication_594456(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketReplication_594455(path: JsonNode; query: JsonNode;
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
  var valid_594457 = path.getOrDefault("Bucket")
  valid_594457 = validateParameter(valid_594457, JString, required = true,
                                 default = nil)
  if valid_594457 != nil:
    section.add "Bucket", valid_594457
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_594458 = query.getOrDefault("replication")
  valid_594458 = validateParameter(valid_594458, JBool, required = true, default = nil)
  if valid_594458 != nil:
    section.add "replication", valid_594458
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594459 = header.getOrDefault("x-amz-security-token")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "x-amz-security-token", valid_594459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594460: Call_GetBucketReplication_594454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ## 
  let valid = call_594460.validator(path, query, header, formData, body)
  let scheme = call_594460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594460.url(scheme.get, call_594460.host, call_594460.base,
                         call_594460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594460, url, valid)

proc call*(call_594461: Call_GetBucketReplication_594454; replication: bool;
          Bucket: string): Recallable =
  ## getBucketReplication
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594462 = newJObject()
  var query_594463 = newJObject()
  add(query_594463, "replication", newJBool(replication))
  add(path_594462, "Bucket", newJString(Bucket))
  result = call_594461.call(path_594462, query_594463, nil, nil, nil)

var getBucketReplication* = Call_GetBucketReplication_594454(
    name: "getBucketReplication", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_GetBucketReplication_594455, base: "/",
    url: url_GetBucketReplication_594456, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketReplication_594478 = ref object of OpenApiRestCall_593437
proc url_DeleteBucketReplication_594480(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketReplication_594479(path: JsonNode; query: JsonNode;
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
  var valid_594481 = path.getOrDefault("Bucket")
  valid_594481 = validateParameter(valid_594481, JString, required = true,
                                 default = nil)
  if valid_594481 != nil:
    section.add "Bucket", valid_594481
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_594482 = query.getOrDefault("replication")
  valid_594482 = validateParameter(valid_594482, JBool, required = true, default = nil)
  if valid_594482 != nil:
    section.add "replication", valid_594482
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594483 = header.getOrDefault("x-amz-security-token")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "x-amz-security-token", valid_594483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594484: Call_DeleteBucketReplication_594478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_594484.validator(path, query, header, formData, body)
  let scheme = call_594484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594484.url(scheme.get, call_594484.host, call_594484.base,
                         call_594484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594484, url, valid)

proc call*(call_594485: Call_DeleteBucketReplication_594478; replication: bool;
          Bucket: string): Recallable =
  ## deleteBucketReplication
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p> The bucket name. </p> <note> <p>It can take a while to propagate the deletion of a replication configuration to all Amazon S3 systems.</p> </note>
  var path_594486 = newJObject()
  var query_594487 = newJObject()
  add(query_594487, "replication", newJBool(replication))
  add(path_594486, "Bucket", newJString(Bucket))
  result = call_594485.call(path_594486, query_594487, nil, nil, nil)

var deleteBucketReplication* = Call_DeleteBucketReplication_594478(
    name: "deleteBucketReplication", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_DeleteBucketReplication_594479, base: "/",
    url: url_DeleteBucketReplication_594480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketTagging_594498 = ref object of OpenApiRestCall_593437
proc url_PutBucketTagging_594500(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketTagging_594499(path: JsonNode; query: JsonNode;
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
  var valid_594501 = path.getOrDefault("Bucket")
  valid_594501 = validateParameter(valid_594501, JString, required = true,
                                 default = nil)
  if valid_594501 != nil:
    section.add "Bucket", valid_594501
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_594502 = query.getOrDefault("tagging")
  valid_594502 = validateParameter(valid_594502, JBool, required = true, default = nil)
  if valid_594502 != nil:
    section.add "tagging", valid_594502
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_594503 = header.getOrDefault("x-amz-security-token")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "x-amz-security-token", valid_594503
  var valid_594504 = header.getOrDefault("Content-MD5")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "Content-MD5", valid_594504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594506: Call_PutBucketTagging_594498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the tags for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  let valid = call_594506.validator(path, query, header, formData, body)
  let scheme = call_594506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594506.url(scheme.get, call_594506.host, call_594506.base,
                         call_594506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594506, url, valid)

proc call*(call_594507: Call_PutBucketTagging_594498; tagging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketTagging
  ## Sets the tags for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594508 = newJObject()
  var query_594509 = newJObject()
  var body_594510 = newJObject()
  add(query_594509, "tagging", newJBool(tagging))
  add(path_594508, "Bucket", newJString(Bucket))
  if body != nil:
    body_594510 = body
  result = call_594507.call(path_594508, query_594509, nil, nil, body_594510)

var putBucketTagging* = Call_PutBucketTagging_594498(name: "putBucketTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_PutBucketTagging_594499, base: "/",
    url: url_PutBucketTagging_594500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketTagging_594488 = ref object of OpenApiRestCall_593437
proc url_GetBucketTagging_594490(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketTagging_594489(path: JsonNode; query: JsonNode;
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
  var valid_594491 = path.getOrDefault("Bucket")
  valid_594491 = validateParameter(valid_594491, JString, required = true,
                                 default = nil)
  if valid_594491 != nil:
    section.add "Bucket", valid_594491
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_594492 = query.getOrDefault("tagging")
  valid_594492 = validateParameter(valid_594492, JBool, required = true, default = nil)
  if valid_594492 != nil:
    section.add "tagging", valid_594492
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594493 = header.getOrDefault("x-amz-security-token")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "x-amz-security-token", valid_594493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594494: Call_GetBucketTagging_594488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag set associated with the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  let valid = call_594494.validator(path, query, header, formData, body)
  let scheme = call_594494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594494.url(scheme.get, call_594494.host, call_594494.base,
                         call_594494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594494, url, valid)

proc call*(call_594495: Call_GetBucketTagging_594488; tagging: bool; Bucket: string): Recallable =
  ## getBucketTagging
  ## Returns the tag set associated with the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594496 = newJObject()
  var query_594497 = newJObject()
  add(query_594497, "tagging", newJBool(tagging))
  add(path_594496, "Bucket", newJString(Bucket))
  result = call_594495.call(path_594496, query_594497, nil, nil, nil)

var getBucketTagging* = Call_GetBucketTagging_594488(name: "getBucketTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_GetBucketTagging_594489, base: "/",
    url: url_GetBucketTagging_594490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketTagging_594511 = ref object of OpenApiRestCall_593437
proc url_DeleteBucketTagging_594513(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketTagging_594512(path: JsonNode; query: JsonNode;
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
  var valid_594514 = path.getOrDefault("Bucket")
  valid_594514 = validateParameter(valid_594514, JString, required = true,
                                 default = nil)
  if valid_594514 != nil:
    section.add "Bucket", valid_594514
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_594515 = query.getOrDefault("tagging")
  valid_594515 = validateParameter(valid_594515, JBool, required = true, default = nil)
  if valid_594515 != nil:
    section.add "tagging", valid_594515
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594516 = header.getOrDefault("x-amz-security-token")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "x-amz-security-token", valid_594516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594517: Call_DeleteBucketTagging_594511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the tags from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  let valid = call_594517.validator(path, query, header, formData, body)
  let scheme = call_594517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594517.url(scheme.get, call_594517.host, call_594517.base,
                         call_594517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594517, url, valid)

proc call*(call_594518: Call_DeleteBucketTagging_594511; tagging: bool;
          Bucket: string): Recallable =
  ## deleteBucketTagging
  ## Deletes the tags from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594519 = newJObject()
  var query_594520 = newJObject()
  add(query_594520, "tagging", newJBool(tagging))
  add(path_594519, "Bucket", newJString(Bucket))
  result = call_594518.call(path_594519, query_594520, nil, nil, nil)

var deleteBucketTagging* = Call_DeleteBucketTagging_594511(
    name: "deleteBucketTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_DeleteBucketTagging_594512, base: "/",
    url: url_DeleteBucketTagging_594513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketWebsite_594531 = ref object of OpenApiRestCall_593437
proc url_PutBucketWebsite_594533(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketWebsite_594532(path: JsonNode; query: JsonNode;
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
  var valid_594534 = path.getOrDefault("Bucket")
  valid_594534 = validateParameter(valid_594534, JString, required = true,
                                 default = nil)
  if valid_594534 != nil:
    section.add "Bucket", valid_594534
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_594535 = query.getOrDefault("website")
  valid_594535 = validateParameter(valid_594535, JBool, required = true, default = nil)
  if valid_594535 != nil:
    section.add "website", valid_594535
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_594536 = header.getOrDefault("x-amz-security-token")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "x-amz-security-token", valid_594536
  var valid_594537 = header.getOrDefault("Content-MD5")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "Content-MD5", valid_594537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594539: Call_PutBucketWebsite_594531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  let valid = call_594539.validator(path, query, header, formData, body)
  let scheme = call_594539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594539.url(scheme.get, call_594539.host, call_594539.base,
                         call_594539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594539, url, valid)

proc call*(call_594540: Call_PutBucketWebsite_594531; website: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketWebsite
  ## Set the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594541 = newJObject()
  var query_594542 = newJObject()
  var body_594543 = newJObject()
  add(query_594542, "website", newJBool(website))
  add(path_594541, "Bucket", newJString(Bucket))
  if body != nil:
    body_594543 = body
  result = call_594540.call(path_594541, query_594542, nil, nil, body_594543)

var putBucketWebsite* = Call_PutBucketWebsite_594531(name: "putBucketWebsite",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_PutBucketWebsite_594532, base: "/",
    url: url_PutBucketWebsite_594533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketWebsite_594521 = ref object of OpenApiRestCall_593437
proc url_GetBucketWebsite_594523(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketWebsite_594522(path: JsonNode; query: JsonNode;
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
  var valid_594524 = path.getOrDefault("Bucket")
  valid_594524 = validateParameter(valid_594524, JString, required = true,
                                 default = nil)
  if valid_594524 != nil:
    section.add "Bucket", valid_594524
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_594525 = query.getOrDefault("website")
  valid_594525 = validateParameter(valid_594525, JBool, required = true, default = nil)
  if valid_594525 != nil:
    section.add "website", valid_594525
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594526 = header.getOrDefault("x-amz-security-token")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "x-amz-security-token", valid_594526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594527: Call_GetBucketWebsite_594521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  let valid = call_594527.validator(path, query, header, formData, body)
  let scheme = call_594527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594527.url(scheme.get, call_594527.host, call_594527.base,
                         call_594527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594527, url, valid)

proc call*(call_594528: Call_GetBucketWebsite_594521; website: bool; Bucket: string): Recallable =
  ## getBucketWebsite
  ## Returns the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594529 = newJObject()
  var query_594530 = newJObject()
  add(query_594530, "website", newJBool(website))
  add(path_594529, "Bucket", newJString(Bucket))
  result = call_594528.call(path_594529, query_594530, nil, nil, nil)

var getBucketWebsite* = Call_GetBucketWebsite_594521(name: "getBucketWebsite",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_GetBucketWebsite_594522, base: "/",
    url: url_GetBucketWebsite_594523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketWebsite_594544 = ref object of OpenApiRestCall_593437
proc url_DeleteBucketWebsite_594546(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketWebsite_594545(path: JsonNode; query: JsonNode;
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
  var valid_594547 = path.getOrDefault("Bucket")
  valid_594547 = validateParameter(valid_594547, JString, required = true,
                                 default = nil)
  if valid_594547 != nil:
    section.add "Bucket", valid_594547
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_594548 = query.getOrDefault("website")
  valid_594548 = validateParameter(valid_594548, JBool, required = true, default = nil)
  if valid_594548 != nil:
    section.add "website", valid_594548
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594549 = header.getOrDefault("x-amz-security-token")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "x-amz-security-token", valid_594549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594550: Call_DeleteBucketWebsite_594544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes the website configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  let valid = call_594550.validator(path, query, header, formData, body)
  let scheme = call_594550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594550.url(scheme.get, call_594550.host, call_594550.base,
                         call_594550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594550, url, valid)

proc call*(call_594551: Call_DeleteBucketWebsite_594544; website: bool;
          Bucket: string): Recallable =
  ## deleteBucketWebsite
  ## This operation removes the website configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594552 = newJObject()
  var query_594553 = newJObject()
  add(query_594553, "website", newJBool(website))
  add(path_594552, "Bucket", newJString(Bucket))
  result = call_594551.call(path_594552, query_594553, nil, nil, nil)

var deleteBucketWebsite* = Call_DeleteBucketWebsite_594544(
    name: "deleteBucketWebsite", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_DeleteBucketWebsite_594545, base: "/",
    url: url_DeleteBucketWebsite_594546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObject_594581 = ref object of OpenApiRestCall_593437
proc url_PutObject_594583(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutObject_594582(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594584 = path.getOrDefault("Key")
  valid_594584 = validateParameter(valid_594584, JString, required = true,
                                 default = nil)
  if valid_594584 != nil:
    section.add "Key", valid_594584
  var valid_594585 = path.getOrDefault("Bucket")
  valid_594585 = validateParameter(valid_594585, JString, required = true,
                                 default = nil)
  if valid_594585 != nil:
    section.add "Bucket", valid_594585
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
  var valid_594586 = header.getOrDefault("Content-Disposition")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "Content-Disposition", valid_594586
  var valid_594587 = header.getOrDefault("x-amz-grant-full-control")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "x-amz-grant-full-control", valid_594587
  var valid_594588 = header.getOrDefault("x-amz-security-token")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "x-amz-security-token", valid_594588
  var valid_594589 = header.getOrDefault("Content-MD5")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "Content-MD5", valid_594589
  var valid_594590 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_594590
  var valid_594591 = header.getOrDefault("x-amz-object-lock-mode")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_594591 != nil:
    section.add "x-amz-object-lock-mode", valid_594591
  var valid_594592 = header.getOrDefault("Cache-Control")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "Cache-Control", valid_594592
  var valid_594593 = header.getOrDefault("Content-Language")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "Content-Language", valid_594593
  var valid_594594 = header.getOrDefault("Content-Type")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "Content-Type", valid_594594
  var valid_594595 = header.getOrDefault("Expires")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "Expires", valid_594595
  var valid_594596 = header.getOrDefault("x-amz-website-redirect-location")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "x-amz-website-redirect-location", valid_594596
  var valid_594597 = header.getOrDefault("x-amz-acl")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = newJString("private"))
  if valid_594597 != nil:
    section.add "x-amz-acl", valid_594597
  var valid_594598 = header.getOrDefault("x-amz-grant-read")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "x-amz-grant-read", valid_594598
  var valid_594599 = header.getOrDefault("x-amz-storage-class")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_594599 != nil:
    section.add "x-amz-storage-class", valid_594599
  var valid_594600 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_594600 = validateParameter(valid_594600, JString, required = false,
                                 default = newJString("ON"))
  if valid_594600 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_594600
  var valid_594601 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_594601
  var valid_594602 = header.getOrDefault("x-amz-tagging")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "x-amz-tagging", valid_594602
  var valid_594603 = header.getOrDefault("x-amz-grant-read-acp")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "x-amz-grant-read-acp", valid_594603
  var valid_594604 = header.getOrDefault("Content-Length")
  valid_594604 = validateParameter(valid_594604, JInt, required = false, default = nil)
  if valid_594604 != nil:
    section.add "Content-Length", valid_594604
  var valid_594605 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "x-amz-server-side-encryption-context", valid_594605
  var valid_594606 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_594606
  var valid_594607 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_594607
  var valid_594608 = header.getOrDefault("x-amz-grant-write-acp")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "x-amz-grant-write-acp", valid_594608
  var valid_594609 = header.getOrDefault("Content-Encoding")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "Content-Encoding", valid_594609
  var valid_594610 = header.getOrDefault("x-amz-request-payer")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = newJString("requester"))
  if valid_594610 != nil:
    section.add "x-amz-request-payer", valid_594610
  var valid_594611 = header.getOrDefault("x-amz-server-side-encryption")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = newJString("AES256"))
  if valid_594611 != nil:
    section.add "x-amz-server-side-encryption", valid_594611
  var valid_594612 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_594612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594614: Call_PutObject_594581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an object to a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  let valid = call_594614.validator(path, query, header, formData, body)
  let scheme = call_594614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594614.url(scheme.get, call_594614.host, call_594614.base,
                         call_594614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594614, url, valid)

proc call*(call_594615: Call_PutObject_594581; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## putObject
  ## Adds an object to a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  ##   Key: string (required)
  ##      : Object key for which the PUT operation was initiated.
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the PUT operation was initiated.
  ##   body: JObject (required)
  var path_594616 = newJObject()
  var body_594617 = newJObject()
  add(path_594616, "Key", newJString(Key))
  add(path_594616, "Bucket", newJString(Bucket))
  if body != nil:
    body_594617 = body
  result = call_594615.call(path_594616, nil, nil, nil, body_594617)

var putObject* = Call_PutObject_594581(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_PutObject_594582,
                                    base: "/", url: url_PutObject_594583,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadObject_594632 = ref object of OpenApiRestCall_593437
proc url_HeadObject_594634(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_HeadObject_594633(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594635 = path.getOrDefault("Key")
  valid_594635 = validateParameter(valid_594635, JString, required = true,
                                 default = nil)
  if valid_594635 != nil:
    section.add "Key", valid_594635
  var valid_594636 = path.getOrDefault("Bucket")
  valid_594636 = validateParameter(valid_594636, JString, required = true,
                                 default = nil)
  if valid_594636 != nil:
    section.add "Bucket", valid_594636
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   partNumber: JInt
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
  section = newJObject()
  var valid_594637 = query.getOrDefault("versionId")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "versionId", valid_594637
  var valid_594638 = query.getOrDefault("partNumber")
  valid_594638 = validateParameter(valid_594638, JInt, required = false, default = nil)
  if valid_594638 != nil:
    section.add "partNumber", valid_594638
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
  var valid_594639 = header.getOrDefault("x-amz-security-token")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "x-amz-security-token", valid_594639
  var valid_594640 = header.getOrDefault("If-Match")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "If-Match", valid_594640
  var valid_594641 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_594641
  var valid_594642 = header.getOrDefault("If-Unmodified-Since")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "If-Unmodified-Since", valid_594642
  var valid_594643 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_594643
  var valid_594644 = header.getOrDefault("If-Modified-Since")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "If-Modified-Since", valid_594644
  var valid_594645 = header.getOrDefault("If-None-Match")
  valid_594645 = validateParameter(valid_594645, JString, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "If-None-Match", valid_594645
  var valid_594646 = header.getOrDefault("x-amz-request-payer")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = newJString("requester"))
  if valid_594646 != nil:
    section.add "x-amz-request-payer", valid_594646
  var valid_594647 = header.getOrDefault("Range")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "Range", valid_594647
  var valid_594648 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_594648 = validateParameter(valid_594648, JString, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_594648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594649: Call_HeadObject_594632; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  let valid = call_594649.validator(path, query, header, formData, body)
  let scheme = call_594649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594649.url(scheme.get, call_594649.host, call_594649.base,
                         call_594649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594649, url, valid)

proc call*(call_594650: Call_HeadObject_594632; Key: string; Bucket: string;
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
  var path_594651 = newJObject()
  var query_594652 = newJObject()
  add(query_594652, "versionId", newJString(versionId))
  add(query_594652, "partNumber", newJInt(partNumber))
  add(path_594651, "Key", newJString(Key))
  add(path_594651, "Bucket", newJString(Bucket))
  result = call_594650.call(path_594651, query_594652, nil, nil, nil)

var headObject* = Call_HeadObject_594632(name: "headObject",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}/{Key}",
                                      validator: validate_HeadObject_594633,
                                      base: "/", url: url_HeadObject_594634,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_594554 = ref object of OpenApiRestCall_593437
proc url_GetObject_594556(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetObject_594555(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594557 = path.getOrDefault("Key")
  valid_594557 = validateParameter(valid_594557, JString, required = true,
                                 default = nil)
  if valid_594557 != nil:
    section.add "Key", valid_594557
  var valid_594558 = path.getOrDefault("Bucket")
  valid_594558 = validateParameter(valid_594558, JString, required = true,
                                 default = nil)
  if valid_594558 != nil:
    section.add "Bucket", valid_594558
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
  var valid_594559 = query.getOrDefault("versionId")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "versionId", valid_594559
  var valid_594560 = query.getOrDefault("partNumber")
  valid_594560 = validateParameter(valid_594560, JInt, required = false, default = nil)
  if valid_594560 != nil:
    section.add "partNumber", valid_594560
  var valid_594561 = query.getOrDefault("response-expires")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "response-expires", valid_594561
  var valid_594562 = query.getOrDefault("response-content-language")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "response-content-language", valid_594562
  var valid_594563 = query.getOrDefault("response-content-encoding")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "response-content-encoding", valid_594563
  var valid_594564 = query.getOrDefault("response-cache-control")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "response-cache-control", valid_594564
  var valid_594565 = query.getOrDefault("response-content-disposition")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "response-content-disposition", valid_594565
  var valid_594566 = query.getOrDefault("response-content-type")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "response-content-type", valid_594566
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
  var valid_594567 = header.getOrDefault("x-amz-security-token")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "x-amz-security-token", valid_594567
  var valid_594568 = header.getOrDefault("If-Match")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "If-Match", valid_594568
  var valid_594569 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_594569
  var valid_594570 = header.getOrDefault("If-Unmodified-Since")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "If-Unmodified-Since", valid_594570
  var valid_594571 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_594571
  var valid_594572 = header.getOrDefault("If-Modified-Since")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "If-Modified-Since", valid_594572
  var valid_594573 = header.getOrDefault("If-None-Match")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "If-None-Match", valid_594573
  var valid_594574 = header.getOrDefault("x-amz-request-payer")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = newJString("requester"))
  if valid_594574 != nil:
    section.add "x-amz-request-payer", valid_594574
  var valid_594575 = header.getOrDefault("Range")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "Range", valid_594575
  var valid_594576 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_594576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594577: Call_GetObject_594554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves objects from Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  let valid = call_594577.validator(path, query, header, formData, body)
  let scheme = call_594577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594577.url(scheme.get, call_594577.host, call_594577.base,
                         call_594577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594577, url, valid)

proc call*(call_594578: Call_GetObject_594554; Key: string; Bucket: string;
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
  var path_594579 = newJObject()
  var query_594580 = newJObject()
  add(query_594580, "versionId", newJString(versionId))
  add(query_594580, "partNumber", newJInt(partNumber))
  add(query_594580, "response-expires", newJString(responseExpires))
  add(query_594580, "response-content-language",
      newJString(responseContentLanguage))
  add(path_594579, "Key", newJString(Key))
  add(query_594580, "response-content-encoding",
      newJString(responseContentEncoding))
  add(query_594580, "response-cache-control", newJString(responseCacheControl))
  add(path_594579, "Bucket", newJString(Bucket))
  add(query_594580, "response-content-disposition",
      newJString(responseContentDisposition))
  add(query_594580, "response-content-type", newJString(responseContentType))
  result = call_594578.call(path_594579, query_594580, nil, nil, nil)

var getObject* = Call_GetObject_594554(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_GetObject_594555,
                                    base: "/", url: url_GetObject_594556,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_594618 = ref object of OpenApiRestCall_593437
proc url_DeleteObject_594620(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObject_594619(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594621 = path.getOrDefault("Key")
  valid_594621 = validateParameter(valid_594621, JString, required = true,
                                 default = nil)
  if valid_594621 != nil:
    section.add "Key", valid_594621
  var valid_594622 = path.getOrDefault("Bucket")
  valid_594622 = validateParameter(valid_594622, JString, required = true,
                                 default = nil)
  if valid_594622 != nil:
    section.add "Bucket", valid_594622
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  var valid_594623 = query.getOrDefault("versionId")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "versionId", valid_594623
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
  var valid_594624 = header.getOrDefault("x-amz-security-token")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "x-amz-security-token", valid_594624
  var valid_594625 = header.getOrDefault("x-amz-mfa")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "x-amz-mfa", valid_594625
  var valid_594626 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_594626 = validateParameter(valid_594626, JBool, required = false, default = nil)
  if valid_594626 != nil:
    section.add "x-amz-bypass-governance-retention", valid_594626
  var valid_594627 = header.getOrDefault("x-amz-request-payer")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = newJString("requester"))
  if valid_594627 != nil:
    section.add "x-amz-request-payer", valid_594627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594628: Call_DeleteObject_594618; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  let valid = call_594628.validator(path, query, header, formData, body)
  let scheme = call_594628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594628.url(scheme.get, call_594628.host, call_594628.base,
                         call_594628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594628, url, valid)

proc call*(call_594629: Call_DeleteObject_594618; Key: string; Bucket: string;
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
  var path_594630 = newJObject()
  var query_594631 = newJObject()
  add(query_594631, "versionId", newJString(versionId))
  add(path_594630, "Key", newJString(Key))
  add(path_594630, "Bucket", newJString(Bucket))
  result = call_594629.call(path_594630, query_594631, nil, nil, nil)

var deleteObject* = Call_DeleteObject_594618(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}/{Key}",
    validator: validate_DeleteObject_594619, base: "/", url: url_DeleteObject_594620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectTagging_594665 = ref object of OpenApiRestCall_593437
proc url_PutObjectTagging_594667(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectTagging_594666(path: JsonNode; query: JsonNode;
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
  var valid_594668 = path.getOrDefault("Key")
  valid_594668 = validateParameter(valid_594668, JString, required = true,
                                 default = nil)
  if valid_594668 != nil:
    section.add "Key", valid_594668
  var valid_594669 = path.getOrDefault("Bucket")
  valid_594669 = validateParameter(valid_594669, JString, required = true,
                                 default = nil)
  if valid_594669 != nil:
    section.add "Bucket", valid_594669
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_594670 = query.getOrDefault("versionId")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "versionId", valid_594670
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_594671 = query.getOrDefault("tagging")
  valid_594671 = validateParameter(valid_594671, JBool, required = true, default = nil)
  if valid_594671 != nil:
    section.add "tagging", valid_594671
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_594672 = header.getOrDefault("x-amz-security-token")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "x-amz-security-token", valid_594672
  var valid_594673 = header.getOrDefault("Content-MD5")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "Content-MD5", valid_594673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594675: Call_PutObjectTagging_594665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ## 
  let valid = call_594675.validator(path, query, header, formData, body)
  let scheme = call_594675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594675.url(scheme.get, call_594675.host, call_594675.base,
                         call_594675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594675, url, valid)

proc call*(call_594676: Call_PutObjectTagging_594665; tagging: bool; Key: string;
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
  var path_594677 = newJObject()
  var query_594678 = newJObject()
  var body_594679 = newJObject()
  add(query_594678, "versionId", newJString(versionId))
  add(query_594678, "tagging", newJBool(tagging))
  add(path_594677, "Key", newJString(Key))
  add(path_594677, "Bucket", newJString(Bucket))
  if body != nil:
    body_594679 = body
  result = call_594676.call(path_594677, query_594678, nil, nil, body_594679)

var putObjectTagging* = Call_PutObjectTagging_594665(name: "putObjectTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_PutObjectTagging_594666,
    base: "/", url: url_PutObjectTagging_594667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTagging_594653 = ref object of OpenApiRestCall_593437
proc url_GetObjectTagging_594655(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectTagging_594654(path: JsonNode; query: JsonNode;
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
  var valid_594656 = path.getOrDefault("Key")
  valid_594656 = validateParameter(valid_594656, JString, required = true,
                                 default = nil)
  if valid_594656 != nil:
    section.add "Key", valid_594656
  var valid_594657 = path.getOrDefault("Bucket")
  valid_594657 = validateParameter(valid_594657, JString, required = true,
                                 default = nil)
  if valid_594657 != nil:
    section.add "Bucket", valid_594657
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_594658 = query.getOrDefault("versionId")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "versionId", valid_594658
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_594659 = query.getOrDefault("tagging")
  valid_594659 = validateParameter(valid_594659, JBool, required = true, default = nil)
  if valid_594659 != nil:
    section.add "tagging", valid_594659
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594660 = header.getOrDefault("x-amz-security-token")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "x-amz-security-token", valid_594660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594661: Call_GetObjectTagging_594653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag-set of an object.
  ## 
  let valid = call_594661.validator(path, query, header, formData, body)
  let scheme = call_594661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594661.url(scheme.get, call_594661.host, call_594661.base,
                         call_594661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594661, url, valid)

proc call*(call_594662: Call_GetObjectTagging_594653; tagging: bool; Key: string;
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
  var path_594663 = newJObject()
  var query_594664 = newJObject()
  add(query_594664, "versionId", newJString(versionId))
  add(query_594664, "tagging", newJBool(tagging))
  add(path_594663, "Key", newJString(Key))
  add(path_594663, "Bucket", newJString(Bucket))
  result = call_594662.call(path_594663, query_594664, nil, nil, nil)

var getObjectTagging* = Call_GetObjectTagging_594653(name: "getObjectTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_GetObjectTagging_594654,
    base: "/", url: url_GetObjectTagging_594655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjectTagging_594680 = ref object of OpenApiRestCall_593437
proc url_DeleteObjectTagging_594682(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObjectTagging_594681(path: JsonNode; query: JsonNode;
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
  var valid_594683 = path.getOrDefault("Key")
  valid_594683 = validateParameter(valid_594683, JString, required = true,
                                 default = nil)
  if valid_594683 != nil:
    section.add "Key", valid_594683
  var valid_594684 = path.getOrDefault("Bucket")
  valid_594684 = validateParameter(valid_594684, JString, required = true,
                                 default = nil)
  if valid_594684 != nil:
    section.add "Bucket", valid_594684
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The versionId of the object that the tag-set will be removed from.
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_594685 = query.getOrDefault("versionId")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "versionId", valid_594685
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_594686 = query.getOrDefault("tagging")
  valid_594686 = validateParameter(valid_594686, JBool, required = true, default = nil)
  if valid_594686 != nil:
    section.add "tagging", valid_594686
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594687 = header.getOrDefault("x-amz-security-token")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "x-amz-security-token", valid_594687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594688: Call_DeleteObjectTagging_594680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the tag-set from an existing object.
  ## 
  let valid = call_594688.validator(path, query, header, formData, body)
  let scheme = call_594688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594688.url(scheme.get, call_594688.host, call_594688.base,
                         call_594688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594688, url, valid)

proc call*(call_594689: Call_DeleteObjectTagging_594680; tagging: bool; Key: string;
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
  var path_594690 = newJObject()
  var query_594691 = newJObject()
  add(query_594691, "versionId", newJString(versionId))
  add(query_594691, "tagging", newJBool(tagging))
  add(path_594690, "Key", newJString(Key))
  add(path_594690, "Bucket", newJString(Bucket))
  result = call_594689.call(path_594690, query_594691, nil, nil, nil)

var deleteObjectTagging* = Call_DeleteObjectTagging_594680(
    name: "deleteObjectTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#tagging",
    validator: validate_DeleteObjectTagging_594681, base: "/",
    url: url_DeleteObjectTagging_594682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjects_594692 = ref object of OpenApiRestCall_593437
proc url_DeleteObjects_594694(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObjects_594693(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594695 = path.getOrDefault("Bucket")
  valid_594695 = validateParameter(valid_594695, JString, required = true,
                                 default = nil)
  if valid_594695 != nil:
    section.add "Bucket", valid_594695
  result.add "path", section
  ## parameters in `query` object:
  ##   delete: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `delete` field"
  var valid_594696 = query.getOrDefault("delete")
  valid_594696 = validateParameter(valid_594696, JBool, required = true, default = nil)
  if valid_594696 != nil:
    section.add "delete", valid_594696
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
  var valid_594697 = header.getOrDefault("x-amz-security-token")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "x-amz-security-token", valid_594697
  var valid_594698 = header.getOrDefault("x-amz-mfa")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "x-amz-mfa", valid_594698
  var valid_594699 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_594699 = validateParameter(valid_594699, JBool, required = false, default = nil)
  if valid_594699 != nil:
    section.add "x-amz-bypass-governance-retention", valid_594699
  var valid_594700 = header.getOrDefault("x-amz-request-payer")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = newJString("requester"))
  if valid_594700 != nil:
    section.add "x-amz-request-payer", valid_594700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594702: Call_DeleteObjects_594692; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  let valid = call_594702.validator(path, query, header, formData, body)
  let scheme = call_594702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594702.url(scheme.get, call_594702.host, call_594702.base,
                         call_594702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594702, url, valid)

proc call*(call_594703: Call_DeleteObjects_594692; Bucket: string; body: JsonNode;
          delete: bool): Recallable =
  ## deleteObjects
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   delete: bool (required)
  var path_594704 = newJObject()
  var query_594705 = newJObject()
  var body_594706 = newJObject()
  add(path_594704, "Bucket", newJString(Bucket))
  if body != nil:
    body_594706 = body
  add(query_594705, "delete", newJBool(delete))
  result = call_594703.call(path_594704, query_594705, nil, nil, body_594706)

var deleteObjects* = Call_DeleteObjects_594692(name: "deleteObjects",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com", route: "/{Bucket}#delete",
    validator: validate_DeleteObjects_594693, base: "/", url: url_DeleteObjects_594694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_594717 = ref object of OpenApiRestCall_593437
proc url_PutPublicAccessBlock_594719(protocol: Scheme; host: string; base: string;
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

proc validate_PutPublicAccessBlock_594718(path: JsonNode; query: JsonNode;
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
  var valid_594720 = path.getOrDefault("Bucket")
  valid_594720 = validateParameter(valid_594720, JString, required = true,
                                 default = nil)
  if valid_594720 != nil:
    section.add "Bucket", valid_594720
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_594721 = query.getOrDefault("publicAccessBlock")
  valid_594721 = validateParameter(valid_594721, JBool, required = true, default = nil)
  if valid_594721 != nil:
    section.add "publicAccessBlock", valid_594721
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash of the <code>PutPublicAccessBlock</code> request body. 
  section = newJObject()
  var valid_594722 = header.getOrDefault("x-amz-security-token")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "x-amz-security-token", valid_594722
  var valid_594723 = header.getOrDefault("Content-MD5")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "Content-MD5", valid_594723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594725: Call_PutPublicAccessBlock_594717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_594725.validator(path, query, header, formData, body)
  let scheme = call_594725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594725.url(scheme.get, call_594725.host, call_594725.base,
                         call_594725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594725, url, valid)

proc call*(call_594726: Call_PutPublicAccessBlock_594717; publicAccessBlock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to set.
  ##   body: JObject (required)
  var path_594727 = newJObject()
  var query_594728 = newJObject()
  var body_594729 = newJObject()
  add(query_594728, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_594727, "Bucket", newJString(Bucket))
  if body != nil:
    body_594729 = body
  result = call_594726.call(path_594727, query_594728, nil, nil, body_594729)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_594717(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_PutPublicAccessBlock_594718, base: "/",
    url: url_PutPublicAccessBlock_594719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_594707 = ref object of OpenApiRestCall_593437
proc url_GetPublicAccessBlock_594709(protocol: Scheme; host: string; base: string;
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

proc validate_GetPublicAccessBlock_594708(path: JsonNode; query: JsonNode;
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
  var valid_594710 = path.getOrDefault("Bucket")
  valid_594710 = validateParameter(valid_594710, JString, required = true,
                                 default = nil)
  if valid_594710 != nil:
    section.add "Bucket", valid_594710
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_594711 = query.getOrDefault("publicAccessBlock")
  valid_594711 = validateParameter(valid_594711, JBool, required = true, default = nil)
  if valid_594711 != nil:
    section.add "publicAccessBlock", valid_594711
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594712 = header.getOrDefault("x-amz-security-token")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "x-amz-security-token", valid_594712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594713: Call_GetPublicAccessBlock_594707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_594713.validator(path, query, header, formData, body)
  let scheme = call_594713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594713.url(scheme.get, call_594713.host, call_594713.base,
                         call_594713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594713, url, valid)

proc call*(call_594714: Call_GetPublicAccessBlock_594707; publicAccessBlock: bool;
          Bucket: string): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to retrieve. 
  var path_594715 = newJObject()
  var query_594716 = newJObject()
  add(query_594716, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_594715, "Bucket", newJString(Bucket))
  result = call_594714.call(path_594715, query_594716, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_594707(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_GetPublicAccessBlock_594708, base: "/",
    url: url_GetPublicAccessBlock_594709, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_594730 = ref object of OpenApiRestCall_593437
proc url_DeletePublicAccessBlock_594732(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePublicAccessBlock_594731(path: JsonNode; query: JsonNode;
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
  var valid_594733 = path.getOrDefault("Bucket")
  valid_594733 = validateParameter(valid_594733, JString, required = true,
                                 default = nil)
  if valid_594733 != nil:
    section.add "Bucket", valid_594733
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_594734 = query.getOrDefault("publicAccessBlock")
  valid_594734 = validateParameter(valid_594734, JBool, required = true, default = nil)
  if valid_594734 != nil:
    section.add "publicAccessBlock", valid_594734
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594735 = header.getOrDefault("x-amz-security-token")
  valid_594735 = validateParameter(valid_594735, JString, required = false,
                                 default = nil)
  if valid_594735 != nil:
    section.add "x-amz-security-token", valid_594735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594736: Call_DeletePublicAccessBlock_594730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ## 
  let valid = call_594736.validator(path, query, header, formData, body)
  let scheme = call_594736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594736.url(scheme.get, call_594736.host, call_594736.base,
                         call_594736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594736, url, valid)

proc call*(call_594737: Call_DeletePublicAccessBlock_594730;
          publicAccessBlock: bool; Bucket: string): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to delete. 
  var path_594738 = newJObject()
  var query_594739 = newJObject()
  add(query_594739, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_594738, "Bucket", newJString(Bucket))
  result = call_594737.call(path_594738, query_594739, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_594730(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_DeletePublicAccessBlock_594731, base: "/",
    url: url_DeletePublicAccessBlock_594732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAccelerateConfiguration_594750 = ref object of OpenApiRestCall_593437
proc url_PutBucketAccelerateConfiguration_594752(protocol: Scheme; host: string;
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

proc validate_PutBucketAccelerateConfiguration_594751(path: JsonNode;
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
  var valid_594753 = path.getOrDefault("Bucket")
  valid_594753 = validateParameter(valid_594753, JString, required = true,
                                 default = nil)
  if valid_594753 != nil:
    section.add "Bucket", valid_594753
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_594754 = query.getOrDefault("accelerate")
  valid_594754 = validateParameter(valid_594754, JBool, required = true, default = nil)
  if valid_594754 != nil:
    section.add "accelerate", valid_594754
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594755 = header.getOrDefault("x-amz-security-token")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "x-amz-security-token", valid_594755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594757: Call_PutBucketAccelerateConfiguration_594750;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the accelerate configuration of an existing bucket.
  ## 
  let valid = call_594757.validator(path, query, header, formData, body)
  let scheme = call_594757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594757.url(scheme.get, call_594757.host, call_594757.base,
                         call_594757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594757, url, valid)

proc call*(call_594758: Call_PutBucketAccelerateConfiguration_594750;
          accelerate: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAccelerateConfiguration
  ## Sets the accelerate configuration of an existing bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is set.
  ##   body: JObject (required)
  var path_594759 = newJObject()
  var query_594760 = newJObject()
  var body_594761 = newJObject()
  add(query_594760, "accelerate", newJBool(accelerate))
  add(path_594759, "Bucket", newJString(Bucket))
  if body != nil:
    body_594761 = body
  result = call_594758.call(path_594759, query_594760, nil, nil, body_594761)

var putBucketAccelerateConfiguration* = Call_PutBucketAccelerateConfiguration_594750(
    name: "putBucketAccelerateConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_PutBucketAccelerateConfiguration_594751, base: "/",
    url: url_PutBucketAccelerateConfiguration_594752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAccelerateConfiguration_594740 = ref object of OpenApiRestCall_593437
proc url_GetBucketAccelerateConfiguration_594742(protocol: Scheme; host: string;
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

proc validate_GetBucketAccelerateConfiguration_594741(path: JsonNode;
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
  var valid_594743 = path.getOrDefault("Bucket")
  valid_594743 = validateParameter(valid_594743, JString, required = true,
                                 default = nil)
  if valid_594743 != nil:
    section.add "Bucket", valid_594743
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_594744 = query.getOrDefault("accelerate")
  valid_594744 = validateParameter(valid_594744, JBool, required = true, default = nil)
  if valid_594744 != nil:
    section.add "accelerate", valid_594744
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594745 = header.getOrDefault("x-amz-security-token")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "x-amz-security-token", valid_594745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594746: Call_GetBucketAccelerateConfiguration_594740;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the accelerate configuration of a bucket.
  ## 
  let valid = call_594746.validator(path, query, header, formData, body)
  let scheme = call_594746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594746.url(scheme.get, call_594746.host, call_594746.base,
                         call_594746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594746, url, valid)

proc call*(call_594747: Call_GetBucketAccelerateConfiguration_594740;
          accelerate: bool; Bucket: string): Recallable =
  ## getBucketAccelerateConfiguration
  ## Returns the accelerate configuration of a bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is retrieved.
  var path_594748 = newJObject()
  var query_594749 = newJObject()
  add(query_594749, "accelerate", newJBool(accelerate))
  add(path_594748, "Bucket", newJString(Bucket))
  result = call_594747.call(path_594748, query_594749, nil, nil, nil)

var getBucketAccelerateConfiguration* = Call_GetBucketAccelerateConfiguration_594740(
    name: "getBucketAccelerateConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_GetBucketAccelerateConfiguration_594741, base: "/",
    url: url_GetBucketAccelerateConfiguration_594742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAcl_594772 = ref object of OpenApiRestCall_593437
proc url_PutBucketAcl_594774(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketAcl_594773(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594775 = path.getOrDefault("Bucket")
  valid_594775 = validateParameter(valid_594775, JString, required = true,
                                 default = nil)
  if valid_594775 != nil:
    section.add "Bucket", valid_594775
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_594776 = query.getOrDefault("acl")
  valid_594776 = validateParameter(valid_594776, JBool, required = true, default = nil)
  if valid_594776 != nil:
    section.add "acl", valid_594776
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
  var valid_594777 = header.getOrDefault("x-amz-security-token")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "x-amz-security-token", valid_594777
  var valid_594778 = header.getOrDefault("Content-MD5")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "Content-MD5", valid_594778
  var valid_594779 = header.getOrDefault("x-amz-acl")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = newJString("private"))
  if valid_594779 != nil:
    section.add "x-amz-acl", valid_594779
  var valid_594780 = header.getOrDefault("x-amz-grant-read")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "x-amz-grant-read", valid_594780
  var valid_594781 = header.getOrDefault("x-amz-grant-read-acp")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "x-amz-grant-read-acp", valid_594781
  var valid_594782 = header.getOrDefault("x-amz-grant-write")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "x-amz-grant-write", valid_594782
  var valid_594783 = header.getOrDefault("x-amz-grant-write-acp")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "x-amz-grant-write-acp", valid_594783
  var valid_594784 = header.getOrDefault("x-amz-grant-full-control")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "x-amz-grant-full-control", valid_594784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594786: Call_PutBucketAcl_594772; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  let valid = call_594786.validator(path, query, header, formData, body)
  let scheme = call_594786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594786.url(scheme.get, call_594786.host, call_594786.base,
                         call_594786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594786, url, valid)

proc call*(call_594787: Call_PutBucketAcl_594772; acl: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketAcl
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594788 = newJObject()
  var query_594789 = newJObject()
  var body_594790 = newJObject()
  add(query_594789, "acl", newJBool(acl))
  add(path_594788, "Bucket", newJString(Bucket))
  if body != nil:
    body_594790 = body
  result = call_594787.call(path_594788, query_594789, nil, nil, body_594790)

var putBucketAcl* = Call_PutBucketAcl_594772(name: "putBucketAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_PutBucketAcl_594773, base: "/", url: url_PutBucketAcl_594774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAcl_594762 = ref object of OpenApiRestCall_593437
proc url_GetBucketAcl_594764(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketAcl_594763(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594765 = path.getOrDefault("Bucket")
  valid_594765 = validateParameter(valid_594765, JString, required = true,
                                 default = nil)
  if valid_594765 != nil:
    section.add "Bucket", valid_594765
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_594766 = query.getOrDefault("acl")
  valid_594766 = validateParameter(valid_594766, JBool, required = true, default = nil)
  if valid_594766 != nil:
    section.add "acl", valid_594766
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594767 = header.getOrDefault("x-amz-security-token")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "x-amz-security-token", valid_594767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594768: Call_GetBucketAcl_594762; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the access control policy for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  let valid = call_594768.validator(path, query, header, formData, body)
  let scheme = call_594768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594768.url(scheme.get, call_594768.host, call_594768.base,
                         call_594768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594768, url, valid)

proc call*(call_594769: Call_GetBucketAcl_594762; acl: bool; Bucket: string): Recallable =
  ## getBucketAcl
  ## Gets the access control policy for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594770 = newJObject()
  var query_594771 = newJObject()
  add(query_594771, "acl", newJBool(acl))
  add(path_594770, "Bucket", newJString(Bucket))
  result = call_594769.call(path_594770, query_594771, nil, nil, nil)

var getBucketAcl* = Call_GetBucketAcl_594762(name: "getBucketAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_GetBucketAcl_594763, base: "/", url: url_GetBucketAcl_594764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycle_594801 = ref object of OpenApiRestCall_593437
proc url_PutBucketLifecycle_594803(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketLifecycle_594802(path: JsonNode; query: JsonNode;
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
  var valid_594804 = path.getOrDefault("Bucket")
  valid_594804 = validateParameter(valid_594804, JString, required = true,
                                 default = nil)
  if valid_594804 != nil:
    section.add "Bucket", valid_594804
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_594805 = query.getOrDefault("lifecycle")
  valid_594805 = validateParameter(valid_594805, JBool, required = true, default = nil)
  if valid_594805 != nil:
    section.add "lifecycle", valid_594805
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_594806 = header.getOrDefault("x-amz-security-token")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "x-amz-security-token", valid_594806
  var valid_594807 = header.getOrDefault("Content-MD5")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "Content-MD5", valid_594807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594809: Call_PutBucketLifecycle_594801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  let valid = call_594809.validator(path, query, header, formData, body)
  let scheme = call_594809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594809.url(scheme.get, call_594809.host, call_594809.base,
                         call_594809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594809, url, valid)

proc call*(call_594810: Call_PutBucketLifecycle_594801; Bucket: string;
          lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycle
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_594811 = newJObject()
  var query_594812 = newJObject()
  var body_594813 = newJObject()
  add(path_594811, "Bucket", newJString(Bucket))
  add(query_594812, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_594813 = body
  result = call_594810.call(path_594811, query_594812, nil, nil, body_594813)

var putBucketLifecycle* = Call_PutBucketLifecycle_594801(
    name: "putBucketLifecycle", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_PutBucketLifecycle_594802, base: "/",
    url: url_PutBucketLifecycle_594803, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycle_594791 = ref object of OpenApiRestCall_593437
proc url_GetBucketLifecycle_594793(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLifecycle_594792(path: JsonNode; query: JsonNode;
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
  var valid_594794 = path.getOrDefault("Bucket")
  valid_594794 = validateParameter(valid_594794, JString, required = true,
                                 default = nil)
  if valid_594794 != nil:
    section.add "Bucket", valid_594794
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_594795 = query.getOrDefault("lifecycle")
  valid_594795 = validateParameter(valid_594795, JBool, required = true, default = nil)
  if valid_594795 != nil:
    section.add "lifecycle", valid_594795
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594796 = header.getOrDefault("x-amz-security-token")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "x-amz-security-token", valid_594796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594797: Call_GetBucketLifecycle_594791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  let valid = call_594797.validator(path, query, header, formData, body)
  let scheme = call_594797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594797.url(scheme.get, call_594797.host, call_594797.base,
                         call_594797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594797, url, valid)

proc call*(call_594798: Call_GetBucketLifecycle_594791; Bucket: string;
          lifecycle: bool): Recallable =
  ## getBucketLifecycle
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_594799 = newJObject()
  var query_594800 = newJObject()
  add(path_594799, "Bucket", newJString(Bucket))
  add(query_594800, "lifecycle", newJBool(lifecycle))
  result = call_594798.call(path_594799, query_594800, nil, nil, nil)

var getBucketLifecycle* = Call_GetBucketLifecycle_594791(
    name: "getBucketLifecycle", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_GetBucketLifecycle_594792, base: "/",
    url: url_GetBucketLifecycle_594793, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLocation_594814 = ref object of OpenApiRestCall_593437
proc url_GetBucketLocation_594816(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLocation_594815(path: JsonNode; query: JsonNode;
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
  var valid_594817 = path.getOrDefault("Bucket")
  valid_594817 = validateParameter(valid_594817, JString, required = true,
                                 default = nil)
  if valid_594817 != nil:
    section.add "Bucket", valid_594817
  result.add "path", section
  ## parameters in `query` object:
  ##   location: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `location` field"
  var valid_594818 = query.getOrDefault("location")
  valid_594818 = validateParameter(valid_594818, JBool, required = true, default = nil)
  if valid_594818 != nil:
    section.add "location", valid_594818
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594819 = header.getOrDefault("x-amz-security-token")
  valid_594819 = validateParameter(valid_594819, JString, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "x-amz-security-token", valid_594819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594820: Call_GetBucketLocation_594814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the region the bucket resides in.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  let valid = call_594820.validator(path, query, header, formData, body)
  let scheme = call_594820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594820.url(scheme.get, call_594820.host, call_594820.base,
                         call_594820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594820, url, valid)

proc call*(call_594821: Call_GetBucketLocation_594814; location: bool; Bucket: string): Recallable =
  ## getBucketLocation
  ## Returns the region the bucket resides in.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  ##   location: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594822 = newJObject()
  var query_594823 = newJObject()
  add(query_594823, "location", newJBool(location))
  add(path_594822, "Bucket", newJString(Bucket))
  result = call_594821.call(path_594822, query_594823, nil, nil, nil)

var getBucketLocation* = Call_GetBucketLocation_594814(name: "getBucketLocation",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#location",
    validator: validate_GetBucketLocation_594815, base: "/",
    url: url_GetBucketLocation_594816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLogging_594834 = ref object of OpenApiRestCall_593437
proc url_PutBucketLogging_594836(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketLogging_594835(path: JsonNode; query: JsonNode;
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
  var valid_594837 = path.getOrDefault("Bucket")
  valid_594837 = validateParameter(valid_594837, JString, required = true,
                                 default = nil)
  if valid_594837 != nil:
    section.add "Bucket", valid_594837
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_594838 = query.getOrDefault("logging")
  valid_594838 = validateParameter(valid_594838, JBool, required = true, default = nil)
  if valid_594838 != nil:
    section.add "logging", valid_594838
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_594839 = header.getOrDefault("x-amz-security-token")
  valid_594839 = validateParameter(valid_594839, JString, required = false,
                                 default = nil)
  if valid_594839 != nil:
    section.add "x-amz-security-token", valid_594839
  var valid_594840 = header.getOrDefault("Content-MD5")
  valid_594840 = validateParameter(valid_594840, JString, required = false,
                                 default = nil)
  if valid_594840 != nil:
    section.add "Content-MD5", valid_594840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594842: Call_PutBucketLogging_594834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  let valid = call_594842.validator(path, query, header, formData, body)
  let scheme = call_594842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594842.url(scheme.get, call_594842.host, call_594842.base,
                         call_594842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594842, url, valid)

proc call*(call_594843: Call_PutBucketLogging_594834; logging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketLogging
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594844 = newJObject()
  var query_594845 = newJObject()
  var body_594846 = newJObject()
  add(query_594845, "logging", newJBool(logging))
  add(path_594844, "Bucket", newJString(Bucket))
  if body != nil:
    body_594846 = body
  result = call_594843.call(path_594844, query_594845, nil, nil, body_594846)

var putBucketLogging* = Call_PutBucketLogging_594834(name: "putBucketLogging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_PutBucketLogging_594835, base: "/",
    url: url_PutBucketLogging_594836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLogging_594824 = ref object of OpenApiRestCall_593437
proc url_GetBucketLogging_594826(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLogging_594825(path: JsonNode; query: JsonNode;
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
  var valid_594827 = path.getOrDefault("Bucket")
  valid_594827 = validateParameter(valid_594827, JString, required = true,
                                 default = nil)
  if valid_594827 != nil:
    section.add "Bucket", valid_594827
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_594828 = query.getOrDefault("logging")
  valid_594828 = validateParameter(valid_594828, JBool, required = true, default = nil)
  if valid_594828 != nil:
    section.add "logging", valid_594828
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594829 = header.getOrDefault("x-amz-security-token")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "x-amz-security-token", valid_594829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594830: Call_GetBucketLogging_594824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  let valid = call_594830.validator(path, query, header, formData, body)
  let scheme = call_594830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594830.url(scheme.get, call_594830.host, call_594830.base,
                         call_594830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594830, url, valid)

proc call*(call_594831: Call_GetBucketLogging_594824; logging: bool; Bucket: string): Recallable =
  ## getBucketLogging
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594832 = newJObject()
  var query_594833 = newJObject()
  add(query_594833, "logging", newJBool(logging))
  add(path_594832, "Bucket", newJString(Bucket))
  result = call_594831.call(path_594832, query_594833, nil, nil, nil)

var getBucketLogging* = Call_GetBucketLogging_594824(name: "getBucketLogging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_GetBucketLogging_594825, base: "/",
    url: url_GetBucketLogging_594826, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotificationConfiguration_594857 = ref object of OpenApiRestCall_593437
proc url_PutBucketNotificationConfiguration_594859(protocol: Scheme; host: string;
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

proc validate_PutBucketNotificationConfiguration_594858(path: JsonNode;
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
  var valid_594860 = path.getOrDefault("Bucket")
  valid_594860 = validateParameter(valid_594860, JString, required = true,
                                 default = nil)
  if valid_594860 != nil:
    section.add "Bucket", valid_594860
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_594861 = query.getOrDefault("notification")
  valid_594861 = validateParameter(valid_594861, JBool, required = true, default = nil)
  if valid_594861 != nil:
    section.add "notification", valid_594861
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594862 = header.getOrDefault("x-amz-security-token")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "x-amz-security-token", valid_594862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594864: Call_PutBucketNotificationConfiguration_594857;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enables notifications of specified events for a bucket.
  ## 
  let valid = call_594864.validator(path, query, header, formData, body)
  let scheme = call_594864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594864.url(scheme.get, call_594864.host, call_594864.base,
                         call_594864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594864, url, valid)

proc call*(call_594865: Call_PutBucketNotificationConfiguration_594857;
          notification: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotificationConfiguration
  ## Enables notifications of specified events for a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594866 = newJObject()
  var query_594867 = newJObject()
  var body_594868 = newJObject()
  add(query_594867, "notification", newJBool(notification))
  add(path_594866, "Bucket", newJString(Bucket))
  if body != nil:
    body_594868 = body
  result = call_594865.call(path_594866, query_594867, nil, nil, body_594868)

var putBucketNotificationConfiguration* = Call_PutBucketNotificationConfiguration_594857(
    name: "putBucketNotificationConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_PutBucketNotificationConfiguration_594858, base: "/",
    url: url_PutBucketNotificationConfiguration_594859,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotificationConfiguration_594847 = ref object of OpenApiRestCall_593437
proc url_GetBucketNotificationConfiguration_594849(protocol: Scheme; host: string;
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

proc validate_GetBucketNotificationConfiguration_594848(path: JsonNode;
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
  var valid_594850 = path.getOrDefault("Bucket")
  valid_594850 = validateParameter(valid_594850, JString, required = true,
                                 default = nil)
  if valid_594850 != nil:
    section.add "Bucket", valid_594850
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_594851 = query.getOrDefault("notification")
  valid_594851 = validateParameter(valid_594851, JBool, required = true, default = nil)
  if valid_594851 != nil:
    section.add "notification", valid_594851
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594852 = header.getOrDefault("x-amz-security-token")
  valid_594852 = validateParameter(valid_594852, JString, required = false,
                                 default = nil)
  if valid_594852 != nil:
    section.add "x-amz-security-token", valid_594852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594853: Call_GetBucketNotificationConfiguration_594847;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the notification configuration of a bucket.
  ## 
  let valid = call_594853.validator(path, query, header, formData, body)
  let scheme = call_594853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594853.url(scheme.get, call_594853.host, call_594853.base,
                         call_594853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594853, url, valid)

proc call*(call_594854: Call_GetBucketNotificationConfiguration_594847;
          notification: bool; Bucket: string): Recallable =
  ## getBucketNotificationConfiguration
  ## Returns the notification configuration of a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_594855 = newJObject()
  var query_594856 = newJObject()
  add(query_594856, "notification", newJBool(notification))
  add(path_594855, "Bucket", newJString(Bucket))
  result = call_594854.call(path_594855, query_594856, nil, nil, nil)

var getBucketNotificationConfiguration* = Call_GetBucketNotificationConfiguration_594847(
    name: "getBucketNotificationConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_GetBucketNotificationConfiguration_594848, base: "/",
    url: url_GetBucketNotificationConfiguration_594849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotification_594879 = ref object of OpenApiRestCall_593437
proc url_PutBucketNotification_594881(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketNotification_594880(path: JsonNode; query: JsonNode;
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
  var valid_594882 = path.getOrDefault("Bucket")
  valid_594882 = validateParameter(valid_594882, JString, required = true,
                                 default = nil)
  if valid_594882 != nil:
    section.add "Bucket", valid_594882
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_594883 = query.getOrDefault("notification")
  valid_594883 = validateParameter(valid_594883, JBool, required = true, default = nil)
  if valid_594883 != nil:
    section.add "notification", valid_594883
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_594884 = header.getOrDefault("x-amz-security-token")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "x-amz-security-token", valid_594884
  var valid_594885 = header.getOrDefault("Content-MD5")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "Content-MD5", valid_594885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594887: Call_PutBucketNotification_594879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  let valid = call_594887.validator(path, query, header, formData, body)
  let scheme = call_594887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594887.url(scheme.get, call_594887.host, call_594887.base,
                         call_594887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594887, url, valid)

proc call*(call_594888: Call_PutBucketNotification_594879; notification: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotification
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594889 = newJObject()
  var query_594890 = newJObject()
  var body_594891 = newJObject()
  add(query_594890, "notification", newJBool(notification))
  add(path_594889, "Bucket", newJString(Bucket))
  if body != nil:
    body_594891 = body
  result = call_594888.call(path_594889, query_594890, nil, nil, body_594891)

var putBucketNotification* = Call_PutBucketNotification_594879(
    name: "putBucketNotification", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_PutBucketNotification_594880, base: "/",
    url: url_PutBucketNotification_594881, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotification_594869 = ref object of OpenApiRestCall_593437
proc url_GetBucketNotification_594871(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketNotification_594870(path: JsonNode; query: JsonNode;
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
  var valid_594872 = path.getOrDefault("Bucket")
  valid_594872 = validateParameter(valid_594872, JString, required = true,
                                 default = nil)
  if valid_594872 != nil:
    section.add "Bucket", valid_594872
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_594873 = query.getOrDefault("notification")
  valid_594873 = validateParameter(valid_594873, JBool, required = true, default = nil)
  if valid_594873 != nil:
    section.add "notification", valid_594873
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594874 = header.getOrDefault("x-amz-security-token")
  valid_594874 = validateParameter(valid_594874, JString, required = false,
                                 default = nil)
  if valid_594874 != nil:
    section.add "x-amz-security-token", valid_594874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594875: Call_GetBucketNotification_594869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  let valid = call_594875.validator(path, query, header, formData, body)
  let scheme = call_594875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594875.url(scheme.get, call_594875.host, call_594875.base,
                         call_594875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594875, url, valid)

proc call*(call_594876: Call_GetBucketNotification_594869; notification: bool;
          Bucket: string): Recallable =
  ## getBucketNotification
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_594877 = newJObject()
  var query_594878 = newJObject()
  add(query_594878, "notification", newJBool(notification))
  add(path_594877, "Bucket", newJString(Bucket))
  result = call_594876.call(path_594877, query_594878, nil, nil, nil)

var getBucketNotification* = Call_GetBucketNotification_594869(
    name: "getBucketNotification", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_GetBucketNotification_594870, base: "/",
    url: url_GetBucketNotification_594871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicyStatus_594892 = ref object of OpenApiRestCall_593437
proc url_GetBucketPolicyStatus_594894(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketPolicyStatus_594893(path: JsonNode; query: JsonNode;
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
  var valid_594895 = path.getOrDefault("Bucket")
  valid_594895 = validateParameter(valid_594895, JString, required = true,
                                 default = nil)
  if valid_594895 != nil:
    section.add "Bucket", valid_594895
  result.add "path", section
  ## parameters in `query` object:
  ##   policyStatus: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `policyStatus` field"
  var valid_594896 = query.getOrDefault("policyStatus")
  valid_594896 = validateParameter(valid_594896, JBool, required = true, default = nil)
  if valid_594896 != nil:
    section.add "policyStatus", valid_594896
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594897 = header.getOrDefault("x-amz-security-token")
  valid_594897 = validateParameter(valid_594897, JString, required = false,
                                 default = nil)
  if valid_594897 != nil:
    section.add "x-amz-security-token", valid_594897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594898: Call_GetBucketPolicyStatus_594892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ## 
  let valid = call_594898.validator(path, query, header, formData, body)
  let scheme = call_594898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594898.url(scheme.get, call_594898.host, call_594898.base,
                         call_594898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594898, url, valid)

proc call*(call_594899: Call_GetBucketPolicyStatus_594892; policyStatus: bool;
          Bucket: string): Recallable =
  ## getBucketPolicyStatus
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ##   policyStatus: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose policy status you want to retrieve.
  var path_594900 = newJObject()
  var query_594901 = newJObject()
  add(query_594901, "policyStatus", newJBool(policyStatus))
  add(path_594900, "Bucket", newJString(Bucket))
  result = call_594899.call(path_594900, query_594901, nil, nil, nil)

var getBucketPolicyStatus* = Call_GetBucketPolicyStatus_594892(
    name: "getBucketPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#policyStatus",
    validator: validate_GetBucketPolicyStatus_594893, base: "/",
    url: url_GetBucketPolicyStatus_594894, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketRequestPayment_594912 = ref object of OpenApiRestCall_593437
proc url_PutBucketRequestPayment_594914(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketRequestPayment_594913(path: JsonNode; query: JsonNode;
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
  var valid_594915 = path.getOrDefault("Bucket")
  valid_594915 = validateParameter(valid_594915, JString, required = true,
                                 default = nil)
  if valid_594915 != nil:
    section.add "Bucket", valid_594915
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_594916 = query.getOrDefault("requestPayment")
  valid_594916 = validateParameter(valid_594916, JBool, required = true, default = nil)
  if valid_594916 != nil:
    section.add "requestPayment", valid_594916
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_594917 = header.getOrDefault("x-amz-security-token")
  valid_594917 = validateParameter(valid_594917, JString, required = false,
                                 default = nil)
  if valid_594917 != nil:
    section.add "x-amz-security-token", valid_594917
  var valid_594918 = header.getOrDefault("Content-MD5")
  valid_594918 = validateParameter(valid_594918, JString, required = false,
                                 default = nil)
  if valid_594918 != nil:
    section.add "Content-MD5", valid_594918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594920: Call_PutBucketRequestPayment_594912; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  let valid = call_594920.validator(path, query, header, formData, body)
  let scheme = call_594920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594920.url(scheme.get, call_594920.host, call_594920.base,
                         call_594920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594920, url, valid)

proc call*(call_594921: Call_PutBucketRequestPayment_594912; requestPayment: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketRequestPayment
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_594922 = newJObject()
  var query_594923 = newJObject()
  var body_594924 = newJObject()
  add(query_594923, "requestPayment", newJBool(requestPayment))
  add(path_594922, "Bucket", newJString(Bucket))
  if body != nil:
    body_594924 = body
  result = call_594921.call(path_594922, query_594923, nil, nil, body_594924)

var putBucketRequestPayment* = Call_PutBucketRequestPayment_594912(
    name: "putBucketRequestPayment", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_PutBucketRequestPayment_594913, base: "/",
    url: url_PutBucketRequestPayment_594914, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketRequestPayment_594902 = ref object of OpenApiRestCall_593437
proc url_GetBucketRequestPayment_594904(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketRequestPayment_594903(path: JsonNode; query: JsonNode;
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
  var valid_594905 = path.getOrDefault("Bucket")
  valid_594905 = validateParameter(valid_594905, JString, required = true,
                                 default = nil)
  if valid_594905 != nil:
    section.add "Bucket", valid_594905
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_594906 = query.getOrDefault("requestPayment")
  valid_594906 = validateParameter(valid_594906, JBool, required = true, default = nil)
  if valid_594906 != nil:
    section.add "requestPayment", valid_594906
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594907 = header.getOrDefault("x-amz-security-token")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "x-amz-security-token", valid_594907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594908: Call_GetBucketRequestPayment_594902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the request payment configuration of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  let valid = call_594908.validator(path, query, header, formData, body)
  let scheme = call_594908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594908.url(scheme.get, call_594908.host, call_594908.base,
                         call_594908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594908, url, valid)

proc call*(call_594909: Call_GetBucketRequestPayment_594902; requestPayment: bool;
          Bucket: string): Recallable =
  ## getBucketRequestPayment
  ## Returns the request payment configuration of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_594910 = newJObject()
  var query_594911 = newJObject()
  add(query_594911, "requestPayment", newJBool(requestPayment))
  add(path_594910, "Bucket", newJString(Bucket))
  result = call_594909.call(path_594910, query_594911, nil, nil, nil)

var getBucketRequestPayment* = Call_GetBucketRequestPayment_594902(
    name: "getBucketRequestPayment", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_GetBucketRequestPayment_594903, base: "/",
    url: url_GetBucketRequestPayment_594904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketVersioning_594935 = ref object of OpenApiRestCall_593437
proc url_PutBucketVersioning_594937(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketVersioning_594936(path: JsonNode; query: JsonNode;
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
  var valid_594938 = path.getOrDefault("Bucket")
  valid_594938 = validateParameter(valid_594938, JString, required = true,
                                 default = nil)
  if valid_594938 != nil:
    section.add "Bucket", valid_594938
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_594939 = query.getOrDefault("versioning")
  valid_594939 = validateParameter(valid_594939, JBool, required = true, default = nil)
  if valid_594939 != nil:
    section.add "versioning", valid_594939
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  section = newJObject()
  var valid_594940 = header.getOrDefault("x-amz-security-token")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "x-amz-security-token", valid_594940
  var valid_594941 = header.getOrDefault("Content-MD5")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "Content-MD5", valid_594941
  var valid_594942 = header.getOrDefault("x-amz-mfa")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "x-amz-mfa", valid_594942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594944: Call_PutBucketVersioning_594935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  let valid = call_594944.validator(path, query, header, formData, body)
  let scheme = call_594944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594944.url(scheme.get, call_594944.host, call_594944.base,
                         call_594944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594944, url, valid)

proc call*(call_594945: Call_PutBucketVersioning_594935; Bucket: string;
          body: JsonNode; versioning: bool): Recallable =
  ## putBucketVersioning
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   versioning: bool (required)
  var path_594946 = newJObject()
  var query_594947 = newJObject()
  var body_594948 = newJObject()
  add(path_594946, "Bucket", newJString(Bucket))
  if body != nil:
    body_594948 = body
  add(query_594947, "versioning", newJBool(versioning))
  result = call_594945.call(path_594946, query_594947, nil, nil, body_594948)

var putBucketVersioning* = Call_PutBucketVersioning_594935(
    name: "putBucketVersioning", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_PutBucketVersioning_594936,
    base: "/", url: url_PutBucketVersioning_594937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketVersioning_594925 = ref object of OpenApiRestCall_593437
proc url_GetBucketVersioning_594927(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketVersioning_594926(path: JsonNode; query: JsonNode;
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
  var valid_594928 = path.getOrDefault("Bucket")
  valid_594928 = validateParameter(valid_594928, JString, required = true,
                                 default = nil)
  if valid_594928 != nil:
    section.add "Bucket", valid_594928
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_594929 = query.getOrDefault("versioning")
  valid_594929 = validateParameter(valid_594929, JBool, required = true, default = nil)
  if valid_594929 != nil:
    section.add "versioning", valid_594929
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594930 = header.getOrDefault("x-amz-security-token")
  valid_594930 = validateParameter(valid_594930, JString, required = false,
                                 default = nil)
  if valid_594930 != nil:
    section.add "x-amz-security-token", valid_594930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594931: Call_GetBucketVersioning_594925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the versioning state of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  let valid = call_594931.validator(path, query, header, formData, body)
  let scheme = call_594931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594931.url(scheme.get, call_594931.host, call_594931.base,
                         call_594931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594931, url, valid)

proc call*(call_594932: Call_GetBucketVersioning_594925; Bucket: string;
          versioning: bool): Recallable =
  ## getBucketVersioning
  ## Returns the versioning state of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versioning: bool (required)
  var path_594933 = newJObject()
  var query_594934 = newJObject()
  add(path_594933, "Bucket", newJString(Bucket))
  add(query_594934, "versioning", newJBool(versioning))
  result = call_594932.call(path_594933, query_594934, nil, nil, nil)

var getBucketVersioning* = Call_GetBucketVersioning_594925(
    name: "getBucketVersioning", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_GetBucketVersioning_594926,
    base: "/", url: url_GetBucketVersioning_594927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectAcl_594962 = ref object of OpenApiRestCall_593437
proc url_PutObjectAcl_594964(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectAcl_594963(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594965 = path.getOrDefault("Key")
  valid_594965 = validateParameter(valid_594965, JString, required = true,
                                 default = nil)
  if valid_594965 != nil:
    section.add "Key", valid_594965
  var valid_594966 = path.getOrDefault("Bucket")
  valid_594966 = validateParameter(valid_594966, JString, required = true,
                                 default = nil)
  if valid_594966 != nil:
    section.add "Bucket", valid_594966
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_594967 = query.getOrDefault("versionId")
  valid_594967 = validateParameter(valid_594967, JString, required = false,
                                 default = nil)
  if valid_594967 != nil:
    section.add "versionId", valid_594967
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_594968 = query.getOrDefault("acl")
  valid_594968 = validateParameter(valid_594968, JBool, required = true, default = nil)
  if valid_594968 != nil:
    section.add "acl", valid_594968
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
  var valid_594969 = header.getOrDefault("x-amz-security-token")
  valid_594969 = validateParameter(valid_594969, JString, required = false,
                                 default = nil)
  if valid_594969 != nil:
    section.add "x-amz-security-token", valid_594969
  var valid_594970 = header.getOrDefault("Content-MD5")
  valid_594970 = validateParameter(valid_594970, JString, required = false,
                                 default = nil)
  if valid_594970 != nil:
    section.add "Content-MD5", valid_594970
  var valid_594971 = header.getOrDefault("x-amz-acl")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = newJString("private"))
  if valid_594971 != nil:
    section.add "x-amz-acl", valid_594971
  var valid_594972 = header.getOrDefault("x-amz-grant-read")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "x-amz-grant-read", valid_594972
  var valid_594973 = header.getOrDefault("x-amz-grant-read-acp")
  valid_594973 = validateParameter(valid_594973, JString, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "x-amz-grant-read-acp", valid_594973
  var valid_594974 = header.getOrDefault("x-amz-grant-write")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "x-amz-grant-write", valid_594974
  var valid_594975 = header.getOrDefault("x-amz-grant-write-acp")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "x-amz-grant-write-acp", valid_594975
  var valid_594976 = header.getOrDefault("x-amz-request-payer")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = newJString("requester"))
  if valid_594976 != nil:
    section.add "x-amz-request-payer", valid_594976
  var valid_594977 = header.getOrDefault("x-amz-grant-full-control")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "x-amz-grant-full-control", valid_594977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594979: Call_PutObjectAcl_594962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  let valid = call_594979.validator(path, query, header, formData, body)
  let scheme = call_594979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594979.url(scheme.get, call_594979.host, call_594979.base,
                         call_594979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594979, url, valid)

proc call*(call_594980: Call_PutObjectAcl_594962; Key: string; acl: bool;
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
  var path_594981 = newJObject()
  var query_594982 = newJObject()
  var body_594983 = newJObject()
  add(query_594982, "versionId", newJString(versionId))
  add(path_594981, "Key", newJString(Key))
  add(query_594982, "acl", newJBool(acl))
  add(path_594981, "Bucket", newJString(Bucket))
  if body != nil:
    body_594983 = body
  result = call_594980.call(path_594981, query_594982, nil, nil, body_594983)

var putObjectAcl* = Call_PutObjectAcl_594962(name: "putObjectAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_PutObjectAcl_594963,
    base: "/", url: url_PutObjectAcl_594964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAcl_594949 = ref object of OpenApiRestCall_593437
proc url_GetObjectAcl_594951(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectAcl_594950(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594952 = path.getOrDefault("Key")
  valid_594952 = validateParameter(valid_594952, JString, required = true,
                                 default = nil)
  if valid_594952 != nil:
    section.add "Key", valid_594952
  var valid_594953 = path.getOrDefault("Bucket")
  valid_594953 = validateParameter(valid_594953, JString, required = true,
                                 default = nil)
  if valid_594953 != nil:
    section.add "Bucket", valid_594953
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_594954 = query.getOrDefault("versionId")
  valid_594954 = validateParameter(valid_594954, JString, required = false,
                                 default = nil)
  if valid_594954 != nil:
    section.add "versionId", valid_594954
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_594955 = query.getOrDefault("acl")
  valid_594955 = validateParameter(valid_594955, JBool, required = true, default = nil)
  if valid_594955 != nil:
    section.add "acl", valid_594955
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_594956 = header.getOrDefault("x-amz-security-token")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "x-amz-security-token", valid_594956
  var valid_594957 = header.getOrDefault("x-amz-request-payer")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = newJString("requester"))
  if valid_594957 != nil:
    section.add "x-amz-request-payer", valid_594957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594958: Call_GetObjectAcl_594949; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access control list (ACL) of an object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  let valid = call_594958.validator(path, query, header, formData, body)
  let scheme = call_594958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594958.url(scheme.get, call_594958.host, call_594958.base,
                         call_594958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594958, url, valid)

proc call*(call_594959: Call_GetObjectAcl_594949; Key: string; acl: bool;
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
  var path_594960 = newJObject()
  var query_594961 = newJObject()
  add(query_594961, "versionId", newJString(versionId))
  add(path_594960, "Key", newJString(Key))
  add(query_594961, "acl", newJBool(acl))
  add(path_594960, "Bucket", newJString(Bucket))
  result = call_594959.call(path_594960, query_594961, nil, nil, nil)

var getObjectAcl* = Call_GetObjectAcl_594949(name: "getObjectAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_GetObjectAcl_594950,
    base: "/", url: url_GetObjectAcl_594951, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLegalHold_594997 = ref object of OpenApiRestCall_593437
proc url_PutObjectLegalHold_594999(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectLegalHold_594998(path: JsonNode; query: JsonNode;
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
  var valid_595000 = path.getOrDefault("Key")
  valid_595000 = validateParameter(valid_595000, JString, required = true,
                                 default = nil)
  if valid_595000 != nil:
    section.add "Key", valid_595000
  var valid_595001 = path.getOrDefault("Bucket")
  valid_595001 = validateParameter(valid_595001, JString, required = true,
                                 default = nil)
  if valid_595001 != nil:
    section.add "Bucket", valid_595001
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object that you want to place a Legal Hold on.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_595002 = query.getOrDefault("versionId")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "versionId", valid_595002
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_595003 = query.getOrDefault("legal-hold")
  valid_595003 = validateParameter(valid_595003, JBool, required = true, default = nil)
  if valid_595003 != nil:
    section.add "legal-hold", valid_595003
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_595004 = header.getOrDefault("x-amz-security-token")
  valid_595004 = validateParameter(valid_595004, JString, required = false,
                                 default = nil)
  if valid_595004 != nil:
    section.add "x-amz-security-token", valid_595004
  var valid_595005 = header.getOrDefault("Content-MD5")
  valid_595005 = validateParameter(valid_595005, JString, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "Content-MD5", valid_595005
  var valid_595006 = header.getOrDefault("x-amz-request-payer")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = newJString("requester"))
  if valid_595006 != nil:
    section.add "x-amz-request-payer", valid_595006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595008: Call_PutObjectLegalHold_594997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a Legal Hold configuration to the specified object.
  ## 
  let valid = call_595008.validator(path, query, header, formData, body)
  let scheme = call_595008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595008.url(scheme.get, call_595008.host, call_595008.base,
                         call_595008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595008, url, valid)

proc call*(call_595009: Call_PutObjectLegalHold_594997; Key: string; legalHold: bool;
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
  var path_595010 = newJObject()
  var query_595011 = newJObject()
  var body_595012 = newJObject()
  add(query_595011, "versionId", newJString(versionId))
  add(path_595010, "Key", newJString(Key))
  add(query_595011, "legal-hold", newJBool(legalHold))
  add(path_595010, "Bucket", newJString(Bucket))
  if body != nil:
    body_595012 = body
  result = call_595009.call(path_595010, query_595011, nil, nil, body_595012)

var putObjectLegalHold* = Call_PutObjectLegalHold_594997(
    name: "putObjectLegalHold", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_PutObjectLegalHold_594998,
    base: "/", url: url_PutObjectLegalHold_594999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLegalHold_594984 = ref object of OpenApiRestCall_593437
proc url_GetObjectLegalHold_594986(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectLegalHold_594985(path: JsonNode; query: JsonNode;
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
  var valid_594987 = path.getOrDefault("Key")
  valid_594987 = validateParameter(valid_594987, JString, required = true,
                                 default = nil)
  if valid_594987 != nil:
    section.add "Key", valid_594987
  var valid_594988 = path.getOrDefault("Bucket")
  valid_594988 = validateParameter(valid_594988, JString, required = true,
                                 default = nil)
  if valid_594988 != nil:
    section.add "Bucket", valid_594988
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object whose Legal Hold status you want to retrieve.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_594989 = query.getOrDefault("versionId")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "versionId", valid_594989
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_594990 = query.getOrDefault("legal-hold")
  valid_594990 = validateParameter(valid_594990, JBool, required = true, default = nil)
  if valid_594990 != nil:
    section.add "legal-hold", valid_594990
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_594991 = header.getOrDefault("x-amz-security-token")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "x-amz-security-token", valid_594991
  var valid_594992 = header.getOrDefault("x-amz-request-payer")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = newJString("requester"))
  if valid_594992 != nil:
    section.add "x-amz-request-payer", valid_594992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594993: Call_GetObjectLegalHold_594984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an object's current Legal Hold status.
  ## 
  let valid = call_594993.validator(path, query, header, formData, body)
  let scheme = call_594993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594993.url(scheme.get, call_594993.host, call_594993.base,
                         call_594993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594993, url, valid)

proc call*(call_594994: Call_GetObjectLegalHold_594984; Key: string; legalHold: bool;
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
  var path_594995 = newJObject()
  var query_594996 = newJObject()
  add(query_594996, "versionId", newJString(versionId))
  add(path_594995, "Key", newJString(Key))
  add(query_594996, "legal-hold", newJBool(legalHold))
  add(path_594995, "Bucket", newJString(Bucket))
  result = call_594994.call(path_594995, query_594996, nil, nil, nil)

var getObjectLegalHold* = Call_GetObjectLegalHold_594984(
    name: "getObjectLegalHold", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_GetObjectLegalHold_594985,
    base: "/", url: url_GetObjectLegalHold_594986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLockConfiguration_595023 = ref object of OpenApiRestCall_593437
proc url_PutObjectLockConfiguration_595025(protocol: Scheme; host: string;
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

proc validate_PutObjectLockConfiguration_595024(path: JsonNode; query: JsonNode;
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
  var valid_595026 = path.getOrDefault("Bucket")
  valid_595026 = validateParameter(valid_595026, JString, required = true,
                                 default = nil)
  if valid_595026 != nil:
    section.add "Bucket", valid_595026
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_595027 = query.getOrDefault("object-lock")
  valid_595027 = validateParameter(valid_595027, JBool, required = true, default = nil)
  if valid_595027 != nil:
    section.add "object-lock", valid_595027
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
  var valid_595028 = header.getOrDefault("x-amz-security-token")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "x-amz-security-token", valid_595028
  var valid_595029 = header.getOrDefault("Content-MD5")
  valid_595029 = validateParameter(valid_595029, JString, required = false,
                                 default = nil)
  if valid_595029 != nil:
    section.add "Content-MD5", valid_595029
  var valid_595030 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_595030
  var valid_595031 = header.getOrDefault("x-amz-request-payer")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = newJString("requester"))
  if valid_595031 != nil:
    section.add "x-amz-request-payer", valid_595031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595033: Call_PutObjectLockConfiguration_595023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_595033.validator(path, query, header, formData, body)
  let scheme = call_595033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595033.url(scheme.get, call_595033.host, call_595033.base,
                         call_595033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595033, url, valid)

proc call*(call_595034: Call_PutObjectLockConfiguration_595023; objectLock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putObjectLockConfiguration
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to create or replace.
  ##   body: JObject (required)
  var path_595035 = newJObject()
  var query_595036 = newJObject()
  var body_595037 = newJObject()
  add(query_595036, "object-lock", newJBool(objectLock))
  add(path_595035, "Bucket", newJString(Bucket))
  if body != nil:
    body_595037 = body
  result = call_595034.call(path_595035, query_595036, nil, nil, body_595037)

var putObjectLockConfiguration* = Call_PutObjectLockConfiguration_595023(
    name: "putObjectLockConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_PutObjectLockConfiguration_595024, base: "/",
    url: url_PutObjectLockConfiguration_595025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLockConfiguration_595013 = ref object of OpenApiRestCall_593437
proc url_GetObjectLockConfiguration_595015(protocol: Scheme; host: string;
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

proc validate_GetObjectLockConfiguration_595014(path: JsonNode; query: JsonNode;
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
  var valid_595016 = path.getOrDefault("Bucket")
  valid_595016 = validateParameter(valid_595016, JString, required = true,
                                 default = nil)
  if valid_595016 != nil:
    section.add "Bucket", valid_595016
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_595017 = query.getOrDefault("object-lock")
  valid_595017 = validateParameter(valid_595017, JBool, required = true, default = nil)
  if valid_595017 != nil:
    section.add "object-lock", valid_595017
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_595018 = header.getOrDefault("x-amz-security-token")
  valid_595018 = validateParameter(valid_595018, JString, required = false,
                                 default = nil)
  if valid_595018 != nil:
    section.add "x-amz-security-token", valid_595018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595019: Call_GetObjectLockConfiguration_595013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_595019.validator(path, query, header, formData, body)
  let scheme = call_595019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595019.url(scheme.get, call_595019.host, call_595019.base,
                         call_595019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595019, url, valid)

proc call*(call_595020: Call_GetObjectLockConfiguration_595013; objectLock: bool;
          Bucket: string): Recallable =
  ## getObjectLockConfiguration
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to retrieve.
  var path_595021 = newJObject()
  var query_595022 = newJObject()
  add(query_595022, "object-lock", newJBool(objectLock))
  add(path_595021, "Bucket", newJString(Bucket))
  result = call_595020.call(path_595021, query_595022, nil, nil, nil)

var getObjectLockConfiguration* = Call_GetObjectLockConfiguration_595013(
    name: "getObjectLockConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_GetObjectLockConfiguration_595014, base: "/",
    url: url_GetObjectLockConfiguration_595015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectRetention_595051 = ref object of OpenApiRestCall_593437
proc url_PutObjectRetention_595053(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectRetention_595052(path: JsonNode; query: JsonNode;
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
  var valid_595054 = path.getOrDefault("Key")
  valid_595054 = validateParameter(valid_595054, JString, required = true,
                                 default = nil)
  if valid_595054 != nil:
    section.add "Key", valid_595054
  var valid_595055 = path.getOrDefault("Bucket")
  valid_595055 = validateParameter(valid_595055, JString, required = true,
                                 default = nil)
  if valid_595055 != nil:
    section.add "Bucket", valid_595055
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object that you want to apply this Object Retention configuration to.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_595056 = query.getOrDefault("versionId")
  valid_595056 = validateParameter(valid_595056, JString, required = false,
                                 default = nil)
  if valid_595056 != nil:
    section.add "versionId", valid_595056
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_595057 = query.getOrDefault("retention")
  valid_595057 = validateParameter(valid_595057, JBool, required = true, default = nil)
  if valid_595057 != nil:
    section.add "retention", valid_595057
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
  var valid_595058 = header.getOrDefault("x-amz-security-token")
  valid_595058 = validateParameter(valid_595058, JString, required = false,
                                 default = nil)
  if valid_595058 != nil:
    section.add "x-amz-security-token", valid_595058
  var valid_595059 = header.getOrDefault("Content-MD5")
  valid_595059 = validateParameter(valid_595059, JString, required = false,
                                 default = nil)
  if valid_595059 != nil:
    section.add "Content-MD5", valid_595059
  var valid_595060 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_595060 = validateParameter(valid_595060, JBool, required = false, default = nil)
  if valid_595060 != nil:
    section.add "x-amz-bypass-governance-retention", valid_595060
  var valid_595061 = header.getOrDefault("x-amz-request-payer")
  valid_595061 = validateParameter(valid_595061, JString, required = false,
                                 default = newJString("requester"))
  if valid_595061 != nil:
    section.add "x-amz-request-payer", valid_595061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595063: Call_PutObjectRetention_595051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an Object Retention configuration on an object.
  ## 
  let valid = call_595063.validator(path, query, header, formData, body)
  let scheme = call_595063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595063.url(scheme.get, call_595063.host, call_595063.base,
                         call_595063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595063, url, valid)

proc call*(call_595064: Call_PutObjectRetention_595051; retention: bool; Key: string;
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
  var path_595065 = newJObject()
  var query_595066 = newJObject()
  var body_595067 = newJObject()
  add(query_595066, "versionId", newJString(versionId))
  add(query_595066, "retention", newJBool(retention))
  add(path_595065, "Key", newJString(Key))
  add(path_595065, "Bucket", newJString(Bucket))
  if body != nil:
    body_595067 = body
  result = call_595064.call(path_595065, query_595066, nil, nil, body_595067)

var putObjectRetention* = Call_PutObjectRetention_595051(
    name: "putObjectRetention", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_PutObjectRetention_595052,
    base: "/", url: url_PutObjectRetention_595053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectRetention_595038 = ref object of OpenApiRestCall_593437
proc url_GetObjectRetention_595040(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectRetention_595039(path: JsonNode; query: JsonNode;
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
  var valid_595041 = path.getOrDefault("Key")
  valid_595041 = validateParameter(valid_595041, JString, required = true,
                                 default = nil)
  if valid_595041 != nil:
    section.add "Key", valid_595041
  var valid_595042 = path.getOrDefault("Bucket")
  valid_595042 = validateParameter(valid_595042, JString, required = true,
                                 default = nil)
  if valid_595042 != nil:
    section.add "Bucket", valid_595042
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object whose retention settings you want to retrieve.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_595043 = query.getOrDefault("versionId")
  valid_595043 = validateParameter(valid_595043, JString, required = false,
                                 default = nil)
  if valid_595043 != nil:
    section.add "versionId", valid_595043
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_595044 = query.getOrDefault("retention")
  valid_595044 = validateParameter(valid_595044, JBool, required = true, default = nil)
  if valid_595044 != nil:
    section.add "retention", valid_595044
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_595045 = header.getOrDefault("x-amz-security-token")
  valid_595045 = validateParameter(valid_595045, JString, required = false,
                                 default = nil)
  if valid_595045 != nil:
    section.add "x-amz-security-token", valid_595045
  var valid_595046 = header.getOrDefault("x-amz-request-payer")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = newJString("requester"))
  if valid_595046 != nil:
    section.add "x-amz-request-payer", valid_595046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595047: Call_GetObjectRetention_595038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an object's retention settings.
  ## 
  let valid = call_595047.validator(path, query, header, formData, body)
  let scheme = call_595047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595047.url(scheme.get, call_595047.host, call_595047.base,
                         call_595047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595047, url, valid)

proc call*(call_595048: Call_GetObjectRetention_595038; retention: bool; Key: string;
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
  var path_595049 = newJObject()
  var query_595050 = newJObject()
  add(query_595050, "versionId", newJString(versionId))
  add(query_595050, "retention", newJBool(retention))
  add(path_595049, "Key", newJString(Key))
  add(path_595049, "Bucket", newJString(Bucket))
  result = call_595048.call(path_595049, query_595050, nil, nil, nil)

var getObjectRetention* = Call_GetObjectRetention_595038(
    name: "getObjectRetention", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_GetObjectRetention_595039,
    base: "/", url: url_GetObjectRetention_595040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTorrent_595068 = ref object of OpenApiRestCall_593437
proc url_GetObjectTorrent_595070(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectTorrent_595069(path: JsonNode; query: JsonNode;
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
  var valid_595071 = path.getOrDefault("Key")
  valid_595071 = validateParameter(valid_595071, JString, required = true,
                                 default = nil)
  if valid_595071 != nil:
    section.add "Key", valid_595071
  var valid_595072 = path.getOrDefault("Bucket")
  valid_595072 = validateParameter(valid_595072, JString, required = true,
                                 default = nil)
  if valid_595072 != nil:
    section.add "Bucket", valid_595072
  result.add "path", section
  ## parameters in `query` object:
  ##   torrent: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `torrent` field"
  var valid_595073 = query.getOrDefault("torrent")
  valid_595073 = validateParameter(valid_595073, JBool, required = true, default = nil)
  if valid_595073 != nil:
    section.add "torrent", valid_595073
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_595074 = header.getOrDefault("x-amz-security-token")
  valid_595074 = validateParameter(valid_595074, JString, required = false,
                                 default = nil)
  if valid_595074 != nil:
    section.add "x-amz-security-token", valid_595074
  var valid_595075 = header.getOrDefault("x-amz-request-payer")
  valid_595075 = validateParameter(valid_595075, JString, required = false,
                                 default = newJString("requester"))
  if valid_595075 != nil:
    section.add "x-amz-request-payer", valid_595075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595076: Call_GetObjectTorrent_595068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return torrent files from a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  let valid = call_595076.validator(path, query, header, formData, body)
  let scheme = call_595076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595076.url(scheme.get, call_595076.host, call_595076.base,
                         call_595076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595076, url, valid)

proc call*(call_595077: Call_GetObjectTorrent_595068; torrent: bool; Key: string;
          Bucket: string): Recallable =
  ## getObjectTorrent
  ## Return torrent files from a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  ##   torrent: bool (required)
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_595078 = newJObject()
  var query_595079 = newJObject()
  add(query_595079, "torrent", newJBool(torrent))
  add(path_595078, "Key", newJString(Key))
  add(path_595078, "Bucket", newJString(Bucket))
  result = call_595077.call(path_595078, query_595079, nil, nil, nil)

var getObjectTorrent* = Call_GetObjectTorrent_595068(name: "getObjectTorrent",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#torrent", validator: validate_GetObjectTorrent_595069,
    base: "/", url: url_GetObjectTorrent_595070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketAnalyticsConfigurations_595080 = ref object of OpenApiRestCall_593437
proc url_ListBucketAnalyticsConfigurations_595082(protocol: Scheme; host: string;
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

proc validate_ListBucketAnalyticsConfigurations_595081(path: JsonNode;
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
  var valid_595083 = path.getOrDefault("Bucket")
  valid_595083 = validateParameter(valid_595083, JString, required = true,
                                 default = nil)
  if valid_595083 != nil:
    section.add "Bucket", valid_595083
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   continuation-token: JString
  ##                     : The ContinuationToken that represents a placeholder from where this request should begin.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_595084 = query.getOrDefault("analytics")
  valid_595084 = validateParameter(valid_595084, JBool, required = true, default = nil)
  if valid_595084 != nil:
    section.add "analytics", valid_595084
  var valid_595085 = query.getOrDefault("continuation-token")
  valid_595085 = validateParameter(valid_595085, JString, required = false,
                                 default = nil)
  if valid_595085 != nil:
    section.add "continuation-token", valid_595085
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_595086 = header.getOrDefault("x-amz-security-token")
  valid_595086 = validateParameter(valid_595086, JString, required = false,
                                 default = nil)
  if valid_595086 != nil:
    section.add "x-amz-security-token", valid_595086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595087: Call_ListBucketAnalyticsConfigurations_595080;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the analytics configurations for the bucket.
  ## 
  let valid = call_595087.validator(path, query, header, formData, body)
  let scheme = call_595087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595087.url(scheme.get, call_595087.host, call_595087.base,
                         call_595087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595087, url, valid)

proc call*(call_595088: Call_ListBucketAnalyticsConfigurations_595080;
          analytics: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketAnalyticsConfigurations
  ## Lists the analytics configurations for the bucket.
  ##   analytics: bool (required)
  ##   continuationToken: string
  ##                    : The ContinuationToken that represents a placeholder from where this request should begin.
  ##   Bucket: string (required)
  ##         : The name of the bucket from which analytics configurations are retrieved.
  var path_595089 = newJObject()
  var query_595090 = newJObject()
  add(query_595090, "analytics", newJBool(analytics))
  add(query_595090, "continuation-token", newJString(continuationToken))
  add(path_595089, "Bucket", newJString(Bucket))
  result = call_595088.call(path_595089, query_595090, nil, nil, nil)

var listBucketAnalyticsConfigurations* = Call_ListBucketAnalyticsConfigurations_595080(
    name: "listBucketAnalyticsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics",
    validator: validate_ListBucketAnalyticsConfigurations_595081, base: "/",
    url: url_ListBucketAnalyticsConfigurations_595082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketInventoryConfigurations_595091 = ref object of OpenApiRestCall_593437
proc url_ListBucketInventoryConfigurations_595093(protocol: Scheme; host: string;
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

proc validate_ListBucketInventoryConfigurations_595092(path: JsonNode;
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
  var valid_595094 = path.getOrDefault("Bucket")
  valid_595094 = validateParameter(valid_595094, JString, required = true,
                                 default = nil)
  if valid_595094 != nil:
    section.add "Bucket", valid_595094
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_595095 = query.getOrDefault("inventory")
  valid_595095 = validateParameter(valid_595095, JBool, required = true, default = nil)
  if valid_595095 != nil:
    section.add "inventory", valid_595095
  var valid_595096 = query.getOrDefault("continuation-token")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "continuation-token", valid_595096
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_595097 = header.getOrDefault("x-amz-security-token")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "x-amz-security-token", valid_595097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595098: Call_ListBucketInventoryConfigurations_595091;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of inventory configurations for the bucket.
  ## 
  let valid = call_595098.validator(path, query, header, formData, body)
  let scheme = call_595098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595098.url(scheme.get, call_595098.host, call_595098.base,
                         call_595098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595098, url, valid)

proc call*(call_595099: Call_ListBucketInventoryConfigurations_595091;
          inventory: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketInventoryConfigurations
  ## Returns a list of inventory configurations for the bucket.
  ##   inventory: bool (required)
  ##   continuationToken: string
  ##                    : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configurations to retrieve.
  var path_595100 = newJObject()
  var query_595101 = newJObject()
  add(query_595101, "inventory", newJBool(inventory))
  add(query_595101, "continuation-token", newJString(continuationToken))
  add(path_595100, "Bucket", newJString(Bucket))
  result = call_595099.call(path_595100, query_595101, nil, nil, nil)

var listBucketInventoryConfigurations* = Call_ListBucketInventoryConfigurations_595091(
    name: "listBucketInventoryConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory",
    validator: validate_ListBucketInventoryConfigurations_595092, base: "/",
    url: url_ListBucketInventoryConfigurations_595093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketMetricsConfigurations_595102 = ref object of OpenApiRestCall_593437
proc url_ListBucketMetricsConfigurations_595104(protocol: Scheme; host: string;
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

proc validate_ListBucketMetricsConfigurations_595103(path: JsonNode;
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
  var valid_595105 = path.getOrDefault("Bucket")
  valid_595105 = validateParameter(valid_595105, JString, required = true,
                                 default = nil)
  if valid_595105 != nil:
    section.add "Bucket", valid_595105
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_595106 = query.getOrDefault("metrics")
  valid_595106 = validateParameter(valid_595106, JBool, required = true, default = nil)
  if valid_595106 != nil:
    section.add "metrics", valid_595106
  var valid_595107 = query.getOrDefault("continuation-token")
  valid_595107 = validateParameter(valid_595107, JString, required = false,
                                 default = nil)
  if valid_595107 != nil:
    section.add "continuation-token", valid_595107
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_595108 = header.getOrDefault("x-amz-security-token")
  valid_595108 = validateParameter(valid_595108, JString, required = false,
                                 default = nil)
  if valid_595108 != nil:
    section.add "x-amz-security-token", valid_595108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595109: Call_ListBucketMetricsConfigurations_595102;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the metrics configurations for the bucket.
  ## 
  let valid = call_595109.validator(path, query, header, formData, body)
  let scheme = call_595109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595109.url(scheme.get, call_595109.host, call_595109.base,
                         call_595109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595109, url, valid)

proc call*(call_595110: Call_ListBucketMetricsConfigurations_595102; metrics: bool;
          Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketMetricsConfigurations
  ## Lists the metrics configurations for the bucket.
  ##   metrics: bool (required)
  ##   continuationToken: string
  ##                    : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configurations to retrieve.
  var path_595111 = newJObject()
  var query_595112 = newJObject()
  add(query_595112, "metrics", newJBool(metrics))
  add(query_595112, "continuation-token", newJString(continuationToken))
  add(path_595111, "Bucket", newJString(Bucket))
  result = call_595110.call(path_595111, query_595112, nil, nil, nil)

var listBucketMetricsConfigurations* = Call_ListBucketMetricsConfigurations_595102(
    name: "listBucketMetricsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics",
    validator: validate_ListBucketMetricsConfigurations_595103, base: "/",
    url: url_ListBucketMetricsConfigurations_595104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuckets_595113 = ref object of OpenApiRestCall_593437
proc url_ListBuckets_595115(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuckets_595114(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595116 = header.getOrDefault("x-amz-security-token")
  valid_595116 = validateParameter(valid_595116, JString, required = false,
                                 default = nil)
  if valid_595116 != nil:
    section.add "x-amz-security-token", valid_595116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595117: Call_ListBuckets_595113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  let valid = call_595117.validator(path, query, header, formData, body)
  let scheme = call_595117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595117.url(scheme.get, call_595117.host, call_595117.base,
                         call_595117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595117, url, valid)

proc call*(call_595118: Call_ListBuckets_595113): Recallable =
  ## listBuckets
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  result = call_595118.call(nil, nil, nil, nil, nil)

var listBuckets* = Call_ListBuckets_595113(name: "listBuckets",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com", route: "/",
                                        validator: validate_ListBuckets_595114,
                                        base: "/", url: url_ListBuckets_595115,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultipartUploads_595119 = ref object of OpenApiRestCall_593437
proc url_ListMultipartUploads_595121(protocol: Scheme; host: string; base: string;
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

proc validate_ListMultipartUploads_595120(path: JsonNode; query: JsonNode;
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
  var valid_595122 = path.getOrDefault("Bucket")
  valid_595122 = validateParameter(valid_595122, JString, required = true,
                                 default = nil)
  if valid_595122 != nil:
    section.add "Bucket", valid_595122
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
  var valid_595123 = query.getOrDefault("max-uploads")
  valid_595123 = validateParameter(valid_595123, JInt, required = false, default = nil)
  if valid_595123 != nil:
    section.add "max-uploads", valid_595123
  var valid_595124 = query.getOrDefault("key-marker")
  valid_595124 = validateParameter(valid_595124, JString, required = false,
                                 default = nil)
  if valid_595124 != nil:
    section.add "key-marker", valid_595124
  var valid_595125 = query.getOrDefault("encoding-type")
  valid_595125 = validateParameter(valid_595125, JString, required = false,
                                 default = newJString("url"))
  if valid_595125 != nil:
    section.add "encoding-type", valid_595125
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_595126 = query.getOrDefault("uploads")
  valid_595126 = validateParameter(valid_595126, JBool, required = true, default = nil)
  if valid_595126 != nil:
    section.add "uploads", valid_595126
  var valid_595127 = query.getOrDefault("MaxUploads")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "MaxUploads", valid_595127
  var valid_595128 = query.getOrDefault("delimiter")
  valid_595128 = validateParameter(valid_595128, JString, required = false,
                                 default = nil)
  if valid_595128 != nil:
    section.add "delimiter", valid_595128
  var valid_595129 = query.getOrDefault("prefix")
  valid_595129 = validateParameter(valid_595129, JString, required = false,
                                 default = nil)
  if valid_595129 != nil:
    section.add "prefix", valid_595129
  var valid_595130 = query.getOrDefault("upload-id-marker")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "upload-id-marker", valid_595130
  var valid_595131 = query.getOrDefault("KeyMarker")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = nil)
  if valid_595131 != nil:
    section.add "KeyMarker", valid_595131
  var valid_595132 = query.getOrDefault("UploadIdMarker")
  valid_595132 = validateParameter(valid_595132, JString, required = false,
                                 default = nil)
  if valid_595132 != nil:
    section.add "UploadIdMarker", valid_595132
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_595133 = header.getOrDefault("x-amz-security-token")
  valid_595133 = validateParameter(valid_595133, JString, required = false,
                                 default = nil)
  if valid_595133 != nil:
    section.add "x-amz-security-token", valid_595133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595134: Call_ListMultipartUploads_595119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists in-progress multipart uploads.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
  let valid = call_595134.validator(path, query, header, formData, body)
  let scheme = call_595134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595134.url(scheme.get, call_595134.host, call_595134.base,
                         call_595134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595134, url, valid)

proc call*(call_595135: Call_ListMultipartUploads_595119; uploads: bool;
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
  var path_595136 = newJObject()
  var query_595137 = newJObject()
  add(query_595137, "max-uploads", newJInt(maxUploads))
  add(query_595137, "key-marker", newJString(keyMarker))
  add(query_595137, "encoding-type", newJString(encodingType))
  add(query_595137, "uploads", newJBool(uploads))
  add(query_595137, "MaxUploads", newJString(MaxUploads))
  add(query_595137, "delimiter", newJString(delimiter))
  add(path_595136, "Bucket", newJString(Bucket))
  add(query_595137, "prefix", newJString(prefix))
  add(query_595137, "upload-id-marker", newJString(uploadIdMarker))
  add(query_595137, "KeyMarker", newJString(KeyMarker))
  add(query_595137, "UploadIdMarker", newJString(UploadIdMarker))
  result = call_595135.call(path_595136, query_595137, nil, nil, nil)

var listMultipartUploads* = Call_ListMultipartUploads_595119(
    name: "listMultipartUploads", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#uploads",
    validator: validate_ListMultipartUploads_595120, base: "/",
    url: url_ListMultipartUploads_595121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectVersions_595138 = ref object of OpenApiRestCall_593437
proc url_ListObjectVersions_595140(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectVersions_595139(path: JsonNode; query: JsonNode;
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
  var valid_595141 = path.getOrDefault("Bucket")
  valid_595141 = validateParameter(valid_595141, JString, required = true,
                                 default = nil)
  if valid_595141 != nil:
    section.add "Bucket", valid_595141
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
  var valid_595142 = query.getOrDefault("key-marker")
  valid_595142 = validateParameter(valid_595142, JString, required = false,
                                 default = nil)
  if valid_595142 != nil:
    section.add "key-marker", valid_595142
  var valid_595143 = query.getOrDefault("max-keys")
  valid_595143 = validateParameter(valid_595143, JInt, required = false, default = nil)
  if valid_595143 != nil:
    section.add "max-keys", valid_595143
  var valid_595144 = query.getOrDefault("VersionIdMarker")
  valid_595144 = validateParameter(valid_595144, JString, required = false,
                                 default = nil)
  if valid_595144 != nil:
    section.add "VersionIdMarker", valid_595144
  assert query != nil,
        "query argument is necessary due to required `versions` field"
  var valid_595145 = query.getOrDefault("versions")
  valid_595145 = validateParameter(valid_595145, JBool, required = true, default = nil)
  if valid_595145 != nil:
    section.add "versions", valid_595145
  var valid_595146 = query.getOrDefault("encoding-type")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = newJString("url"))
  if valid_595146 != nil:
    section.add "encoding-type", valid_595146
  var valid_595147 = query.getOrDefault("version-id-marker")
  valid_595147 = validateParameter(valid_595147, JString, required = false,
                                 default = nil)
  if valid_595147 != nil:
    section.add "version-id-marker", valid_595147
  var valid_595148 = query.getOrDefault("delimiter")
  valid_595148 = validateParameter(valid_595148, JString, required = false,
                                 default = nil)
  if valid_595148 != nil:
    section.add "delimiter", valid_595148
  var valid_595149 = query.getOrDefault("prefix")
  valid_595149 = validateParameter(valid_595149, JString, required = false,
                                 default = nil)
  if valid_595149 != nil:
    section.add "prefix", valid_595149
  var valid_595150 = query.getOrDefault("MaxKeys")
  valid_595150 = validateParameter(valid_595150, JString, required = false,
                                 default = nil)
  if valid_595150 != nil:
    section.add "MaxKeys", valid_595150
  var valid_595151 = query.getOrDefault("KeyMarker")
  valid_595151 = validateParameter(valid_595151, JString, required = false,
                                 default = nil)
  if valid_595151 != nil:
    section.add "KeyMarker", valid_595151
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_595152 = header.getOrDefault("x-amz-security-token")
  valid_595152 = validateParameter(valid_595152, JString, required = false,
                                 default = nil)
  if valid_595152 != nil:
    section.add "x-amz-security-token", valid_595152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595153: Call_ListObjectVersions_595138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about all of the versions of objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
  let valid = call_595153.validator(path, query, header, formData, body)
  let scheme = call_595153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595153.url(scheme.get, call_595153.host, call_595153.base,
                         call_595153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595153, url, valid)

proc call*(call_595154: Call_ListObjectVersions_595138; versions: bool;
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
  var path_595155 = newJObject()
  var query_595156 = newJObject()
  add(query_595156, "key-marker", newJString(keyMarker))
  add(query_595156, "max-keys", newJInt(maxKeys))
  add(query_595156, "VersionIdMarker", newJString(VersionIdMarker))
  add(query_595156, "versions", newJBool(versions))
  add(query_595156, "encoding-type", newJString(encodingType))
  add(query_595156, "version-id-marker", newJString(versionIdMarker))
  add(query_595156, "delimiter", newJString(delimiter))
  add(path_595155, "Bucket", newJString(Bucket))
  add(query_595156, "prefix", newJString(prefix))
  add(query_595156, "MaxKeys", newJString(MaxKeys))
  add(query_595156, "KeyMarker", newJString(KeyMarker))
  result = call_595154.call(path_595155, query_595156, nil, nil, nil)

var listObjectVersions* = Call_ListObjectVersions_595138(
    name: "listObjectVersions", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versions", validator: validate_ListObjectVersions_595139,
    base: "/", url: url_ListObjectVersions_595140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectsV2_595157 = ref object of OpenApiRestCall_593437
proc url_ListObjectsV2_595159(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectsV2_595158(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595160 = path.getOrDefault("Bucket")
  valid_595160 = validateParameter(valid_595160, JString, required = true,
                                 default = nil)
  if valid_595160 != nil:
    section.add "Bucket", valid_595160
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
  var valid_595161 = query.getOrDefault("list-type")
  valid_595161 = validateParameter(valid_595161, JString, required = true,
                                 default = newJString("2"))
  if valid_595161 != nil:
    section.add "list-type", valid_595161
  var valid_595162 = query.getOrDefault("max-keys")
  valid_595162 = validateParameter(valid_595162, JInt, required = false, default = nil)
  if valid_595162 != nil:
    section.add "max-keys", valid_595162
  var valid_595163 = query.getOrDefault("encoding-type")
  valid_595163 = validateParameter(valid_595163, JString, required = false,
                                 default = newJString("url"))
  if valid_595163 != nil:
    section.add "encoding-type", valid_595163
  var valid_595164 = query.getOrDefault("continuation-token")
  valid_595164 = validateParameter(valid_595164, JString, required = false,
                                 default = nil)
  if valid_595164 != nil:
    section.add "continuation-token", valid_595164
  var valid_595165 = query.getOrDefault("fetch-owner")
  valid_595165 = validateParameter(valid_595165, JBool, required = false, default = nil)
  if valid_595165 != nil:
    section.add "fetch-owner", valid_595165
  var valid_595166 = query.getOrDefault("delimiter")
  valid_595166 = validateParameter(valid_595166, JString, required = false,
                                 default = nil)
  if valid_595166 != nil:
    section.add "delimiter", valid_595166
  var valid_595167 = query.getOrDefault("start-after")
  valid_595167 = validateParameter(valid_595167, JString, required = false,
                                 default = nil)
  if valid_595167 != nil:
    section.add "start-after", valid_595167
  var valid_595168 = query.getOrDefault("ContinuationToken")
  valid_595168 = validateParameter(valid_595168, JString, required = false,
                                 default = nil)
  if valid_595168 != nil:
    section.add "ContinuationToken", valid_595168
  var valid_595169 = query.getOrDefault("prefix")
  valid_595169 = validateParameter(valid_595169, JString, required = false,
                                 default = nil)
  if valid_595169 != nil:
    section.add "prefix", valid_595169
  var valid_595170 = query.getOrDefault("MaxKeys")
  valid_595170 = validateParameter(valid_595170, JString, required = false,
                                 default = nil)
  if valid_595170 != nil:
    section.add "MaxKeys", valid_595170
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_595171 = header.getOrDefault("x-amz-security-token")
  valid_595171 = validateParameter(valid_595171, JString, required = false,
                                 default = nil)
  if valid_595171 != nil:
    section.add "x-amz-security-token", valid_595171
  var valid_595172 = header.getOrDefault("x-amz-request-payer")
  valid_595172 = validateParameter(valid_595172, JString, required = false,
                                 default = newJString("requester"))
  if valid_595172 != nil:
    section.add "x-amz-request-payer", valid_595172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595173: Call_ListObjectsV2_595157; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. Note: ListObjectsV2 is the revised List Objects API and we recommend you use this revised API for new application development.
  ## 
  let valid = call_595173.validator(path, query, header, formData, body)
  let scheme = call_595173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595173.url(scheme.get, call_595173.host, call_595173.base,
                         call_595173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595173, url, valid)

proc call*(call_595174: Call_ListObjectsV2_595157; Bucket: string;
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
  var path_595175 = newJObject()
  var query_595176 = newJObject()
  add(query_595176, "list-type", newJString(listType))
  add(query_595176, "max-keys", newJInt(maxKeys))
  add(query_595176, "encoding-type", newJString(encodingType))
  add(query_595176, "continuation-token", newJString(continuationToken))
  add(query_595176, "fetch-owner", newJBool(fetchOwner))
  add(query_595176, "delimiter", newJString(delimiter))
  add(path_595175, "Bucket", newJString(Bucket))
  add(query_595176, "start-after", newJString(startAfter))
  add(query_595176, "ContinuationToken", newJString(ContinuationToken))
  add(query_595176, "prefix", newJString(prefix))
  add(query_595176, "MaxKeys", newJString(MaxKeys))
  result = call_595174.call(path_595175, query_595176, nil, nil, nil)

var listObjectsV2* = Call_ListObjectsV2_595157(name: "listObjectsV2",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#list-type=2", validator: validate_ListObjectsV2_595158,
    base: "/", url: url_ListObjectsV2_595159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreObject_595177 = ref object of OpenApiRestCall_593437
proc url_RestoreObject_595179(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreObject_595178(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595180 = path.getOrDefault("Key")
  valid_595180 = validateParameter(valid_595180, JString, required = true,
                                 default = nil)
  if valid_595180 != nil:
    section.add "Key", valid_595180
  var valid_595181 = path.getOrDefault("Bucket")
  valid_595181 = validateParameter(valid_595181, JString, required = true,
                                 default = nil)
  if valid_595181 != nil:
    section.add "Bucket", valid_595181
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   restore: JBool (required)
  section = newJObject()
  var valid_595182 = query.getOrDefault("versionId")
  valid_595182 = validateParameter(valid_595182, JString, required = false,
                                 default = nil)
  if valid_595182 != nil:
    section.add "versionId", valid_595182
  assert query != nil, "query argument is necessary due to required `restore` field"
  var valid_595183 = query.getOrDefault("restore")
  valid_595183 = validateParameter(valid_595183, JBool, required = true, default = nil)
  if valid_595183 != nil:
    section.add "restore", valid_595183
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_595184 = header.getOrDefault("x-amz-security-token")
  valid_595184 = validateParameter(valid_595184, JString, required = false,
                                 default = nil)
  if valid_595184 != nil:
    section.add "x-amz-security-token", valid_595184
  var valid_595185 = header.getOrDefault("x-amz-request-payer")
  valid_595185 = validateParameter(valid_595185, JString, required = false,
                                 default = newJString("requester"))
  if valid_595185 != nil:
    section.add "x-amz-request-payer", valid_595185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595187: Call_RestoreObject_595177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restores an archived copy of an object back into Amazon S3
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  let valid = call_595187.validator(path, query, header, formData, body)
  let scheme = call_595187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595187.url(scheme.get, call_595187.host, call_595187.base,
                         call_595187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595187, url, valid)

proc call*(call_595188: Call_RestoreObject_595177; Key: string; restore: bool;
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
  var path_595189 = newJObject()
  var query_595190 = newJObject()
  var body_595191 = newJObject()
  add(query_595190, "versionId", newJString(versionId))
  add(path_595189, "Key", newJString(Key))
  add(query_595190, "restore", newJBool(restore))
  add(path_595189, "Bucket", newJString(Bucket))
  if body != nil:
    body_595191 = body
  result = call_595188.call(path_595189, query_595190, nil, nil, body_595191)

var restoreObject* = Call_RestoreObject_595177(name: "restoreObject",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#restore", validator: validate_RestoreObject_595178,
    base: "/", url: url_RestoreObject_595179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SelectObjectContent_595192 = ref object of OpenApiRestCall_593437
proc url_SelectObjectContent_595194(protocol: Scheme; host: string; base: string;
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

proc validate_SelectObjectContent_595193(path: JsonNode; query: JsonNode;
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
  var valid_595195 = path.getOrDefault("Key")
  valid_595195 = validateParameter(valid_595195, JString, required = true,
                                 default = nil)
  if valid_595195 != nil:
    section.add "Key", valid_595195
  var valid_595196 = path.getOrDefault("Bucket")
  valid_595196 = validateParameter(valid_595196, JString, required = true,
                                 default = nil)
  if valid_595196 != nil:
    section.add "Bucket", valid_595196
  result.add "path", section
  ## parameters in `query` object:
  ##   select: JBool (required)
  ##   select-type: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `select` field"
  var valid_595197 = query.getOrDefault("select")
  valid_595197 = validateParameter(valid_595197, JBool, required = true, default = nil)
  if valid_595197 != nil:
    section.add "select", valid_595197
  var valid_595198 = query.getOrDefault("select-type")
  valid_595198 = validateParameter(valid_595198, JString, required = true,
                                 default = newJString("2"))
  if valid_595198 != nil:
    section.add "select-type", valid_595198
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
  var valid_595199 = header.getOrDefault("x-amz-security-token")
  valid_595199 = validateParameter(valid_595199, JString, required = false,
                                 default = nil)
  if valid_595199 != nil:
    section.add "x-amz-security-token", valid_595199
  var valid_595200 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_595200 = validateParameter(valid_595200, JString, required = false,
                                 default = nil)
  if valid_595200 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_595200
  var valid_595201 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_595201 = validateParameter(valid_595201, JString, required = false,
                                 default = nil)
  if valid_595201 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_595201
  var valid_595202 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_595202 = validateParameter(valid_595202, JString, required = false,
                                 default = nil)
  if valid_595202 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_595202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595204: Call_SelectObjectContent_595192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ## 
  let valid = call_595204.validator(path, query, header, formData, body)
  let scheme = call_595204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595204.url(scheme.get, call_595204.host, call_595204.base,
                         call_595204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595204, url, valid)

proc call*(call_595205: Call_SelectObjectContent_595192; select: bool; Key: string;
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
  var path_595206 = newJObject()
  var query_595207 = newJObject()
  var body_595208 = newJObject()
  add(query_595207, "select", newJBool(select))
  add(path_595206, "Key", newJString(Key))
  add(path_595206, "Bucket", newJString(Bucket))
  if body != nil:
    body_595208 = body
  add(query_595207, "select-type", newJString(selectType))
  result = call_595205.call(path_595206, query_595207, nil, nil, body_595208)

var selectObjectContent* = Call_SelectObjectContent_595192(
    name: "selectObjectContent", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#select&select-type=2",
    validator: validate_SelectObjectContent_595193, base: "/",
    url: url_SelectObjectContent_595194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPart_595209 = ref object of OpenApiRestCall_593437
proc url_UploadPart_595211(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UploadPart_595210(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595212 = path.getOrDefault("Key")
  valid_595212 = validateParameter(valid_595212, JString, required = true,
                                 default = nil)
  if valid_595212 != nil:
    section.add "Key", valid_595212
  var valid_595213 = path.getOrDefault("Bucket")
  valid_595213 = validateParameter(valid_595213, JString, required = true,
                                 default = nil)
  if valid_595213 != nil:
    section.add "Bucket", valid_595213
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being uploaded.
  ##   partNumber: JInt (required)
  ##             : Part number of part being uploaded. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_595214 = query.getOrDefault("uploadId")
  valid_595214 = validateParameter(valid_595214, JString, required = true,
                                 default = nil)
  if valid_595214 != nil:
    section.add "uploadId", valid_595214
  var valid_595215 = query.getOrDefault("partNumber")
  valid_595215 = validateParameter(valid_595215, JInt, required = true, default = nil)
  if valid_595215 != nil:
    section.add "partNumber", valid_595215
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
  var valid_595216 = header.getOrDefault("x-amz-security-token")
  valid_595216 = validateParameter(valid_595216, JString, required = false,
                                 default = nil)
  if valid_595216 != nil:
    section.add "x-amz-security-token", valid_595216
  var valid_595217 = header.getOrDefault("Content-MD5")
  valid_595217 = validateParameter(valid_595217, JString, required = false,
                                 default = nil)
  if valid_595217 != nil:
    section.add "Content-MD5", valid_595217
  var valid_595218 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_595218
  var valid_595219 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_595219 = validateParameter(valid_595219, JString, required = false,
                                 default = nil)
  if valid_595219 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_595219
  var valid_595220 = header.getOrDefault("Content-Length")
  valid_595220 = validateParameter(valid_595220, JInt, required = false, default = nil)
  if valid_595220 != nil:
    section.add "Content-Length", valid_595220
  var valid_595221 = header.getOrDefault("x-amz-request-payer")
  valid_595221 = validateParameter(valid_595221, JString, required = false,
                                 default = newJString("requester"))
  if valid_595221 != nil:
    section.add "x-amz-request-payer", valid_595221
  var valid_595222 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_595222 = validateParameter(valid_595222, JString, required = false,
                                 default = nil)
  if valid_595222 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_595222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595224: Call_UploadPart_595209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  let valid = call_595224.validator(path, query, header, formData, body)
  let scheme = call_595224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595224.url(scheme.get, call_595224.host, call_595224.base,
                         call_595224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595224, url, valid)

proc call*(call_595225: Call_UploadPart_595209; uploadId: string; partNumber: int;
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
  var path_595226 = newJObject()
  var query_595227 = newJObject()
  var body_595228 = newJObject()
  add(query_595227, "uploadId", newJString(uploadId))
  add(query_595227, "partNumber", newJInt(partNumber))
  add(path_595226, "Key", newJString(Key))
  add(path_595226, "Bucket", newJString(Bucket))
  if body != nil:
    body_595228 = body
  result = call_595225.call(path_595226, query_595227, nil, nil, body_595228)

var uploadPart* = Call_UploadPart_595209(name: "uploadPart",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#partNumber&uploadId",
                                      validator: validate_UploadPart_595210,
                                      base: "/", url: url_UploadPart_595211,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPartCopy_595229 = ref object of OpenApiRestCall_593437
proc url_UploadPartCopy_595231(protocol: Scheme; host: string; base: string;
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

proc validate_UploadPartCopy_595230(path: JsonNode; query: JsonNode;
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
  var valid_595232 = path.getOrDefault("Key")
  valid_595232 = validateParameter(valid_595232, JString, required = true,
                                 default = nil)
  if valid_595232 != nil:
    section.add "Key", valid_595232
  var valid_595233 = path.getOrDefault("Bucket")
  valid_595233 = validateParameter(valid_595233, JString, required = true,
                                 default = nil)
  if valid_595233 != nil:
    section.add "Bucket", valid_595233
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being copied.
  ##   partNumber: JInt (required)
  ##             : Part number of part being copied. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_595234 = query.getOrDefault("uploadId")
  valid_595234 = validateParameter(valid_595234, JString, required = true,
                                 default = nil)
  if valid_595234 != nil:
    section.add "uploadId", valid_595234
  var valid_595235 = query.getOrDefault("partNumber")
  valid_595235 = validateParameter(valid_595235, JInt, required = true, default = nil)
  if valid_595235 != nil:
    section.add "partNumber", valid_595235
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
  var valid_595236 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_595236 = validateParameter(valid_595236, JString, required = false,
                                 default = nil)
  if valid_595236 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_595236
  var valid_595237 = header.getOrDefault("x-amz-security-token")
  valid_595237 = validateParameter(valid_595237, JString, required = false,
                                 default = nil)
  if valid_595237 != nil:
    section.add "x-amz-security-token", valid_595237
  var valid_595238 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_595238 = validateParameter(valid_595238, JString, required = false,
                                 default = nil)
  if valid_595238 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_595238
  var valid_595239 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_595239 = validateParameter(valid_595239, JString, required = false,
                                 default = nil)
  if valid_595239 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_595239
  var valid_595240 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_595240 = validateParameter(valid_595240, JString, required = false,
                                 default = nil)
  if valid_595240 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_595240
  var valid_595241 = header.getOrDefault("x-amz-copy-source-range")
  valid_595241 = validateParameter(valid_595241, JString, required = false,
                                 default = nil)
  if valid_595241 != nil:
    section.add "x-amz-copy-source-range", valid_595241
  var valid_595242 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_595242 = validateParameter(valid_595242, JString, required = false,
                                 default = nil)
  if valid_595242 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_595242
  var valid_595243 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_595243 = validateParameter(valid_595243, JString, required = false,
                                 default = nil)
  if valid_595243 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_595243
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_595244 = header.getOrDefault("x-amz-copy-source")
  valid_595244 = validateParameter(valid_595244, JString, required = true,
                                 default = nil)
  if valid_595244 != nil:
    section.add "x-amz-copy-source", valid_595244
  var valid_595245 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_595245 = validateParameter(valid_595245, JString, required = false,
                                 default = nil)
  if valid_595245 != nil:
    section.add "x-amz-copy-source-if-match", valid_595245
  var valid_595246 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_595246 = validateParameter(valid_595246, JString, required = false,
                                 default = nil)
  if valid_595246 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_595246
  var valid_595247 = header.getOrDefault("x-amz-request-payer")
  valid_595247 = validateParameter(valid_595247, JString, required = false,
                                 default = newJString("requester"))
  if valid_595247 != nil:
    section.add "x-amz-request-payer", valid_595247
  var valid_595248 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_595248 = validateParameter(valid_595248, JString, required = false,
                                 default = nil)
  if valid_595248 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_595248
  var valid_595249 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_595249 = validateParameter(valid_595249, JString, required = false,
                                 default = nil)
  if valid_595249 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_595249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595250: Call_UploadPartCopy_595229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads a part by copying data from an existing object as data source.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  let valid = call_595250.validator(path, query, header, formData, body)
  let scheme = call_595250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595250.url(scheme.get, call_595250.host, call_595250.base,
                         call_595250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595250, url, valid)

proc call*(call_595251: Call_UploadPartCopy_595229; uploadId: string;
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
  var path_595252 = newJObject()
  var query_595253 = newJObject()
  add(query_595253, "uploadId", newJString(uploadId))
  add(query_595253, "partNumber", newJInt(partNumber))
  add(path_595252, "Key", newJString(Key))
  add(path_595252, "Bucket", newJString(Bucket))
  result = call_595251.call(path_595252, query_595253, nil, nil, nil)

var uploadPartCopy* = Call_UploadPartCopy_595229(name: "uploadPartCopy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#x-amz-copy-source&partNumber&uploadId",
    validator: validate_UploadPartCopy_595230, base: "/", url: url_UploadPartCopy_595231,
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
