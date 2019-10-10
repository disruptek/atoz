
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
  Call_CompleteMultipartUpload_603088 = ref object of OpenApiRestCall_602466
proc url_CompleteMultipartUpload_603090(protocol: Scheme; host: string; base: string;
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

proc validate_CompleteMultipartUpload_603089(path: JsonNode; query: JsonNode;
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
  var valid_603091 = path.getOrDefault("Key")
  valid_603091 = validateParameter(valid_603091, JString, required = true,
                                 default = nil)
  if valid_603091 != nil:
    section.add "Key", valid_603091
  var valid_603092 = path.getOrDefault("Bucket")
  valid_603092 = validateParameter(valid_603092, JString, required = true,
                                 default = nil)
  if valid_603092 != nil:
    section.add "Bucket", valid_603092
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : <p/>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_603093 = query.getOrDefault("uploadId")
  valid_603093 = validateParameter(valid_603093, JString, required = true,
                                 default = nil)
  if valid_603093 != nil:
    section.add "uploadId", valid_603093
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_603094 = header.getOrDefault("x-amz-security-token")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "x-amz-security-token", valid_603094
  var valid_603095 = header.getOrDefault("x-amz-request-payer")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = newJString("requester"))
  if valid_603095 != nil:
    section.add "x-amz-request-payer", valid_603095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603097: Call_CompleteMultipartUpload_603088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  let valid = call_603097.validator(path, query, header, formData, body)
  let scheme = call_603097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603097.url(scheme.get, call_603097.host, call_603097.base,
                         call_603097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603097, url, valid)

proc call*(call_603098: Call_CompleteMultipartUpload_603088; uploadId: string;
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
  var path_603099 = newJObject()
  var query_603100 = newJObject()
  var body_603101 = newJObject()
  add(query_603100, "uploadId", newJString(uploadId))
  add(path_603099, "Key", newJString(Key))
  add(path_603099, "Bucket", newJString(Bucket))
  if body != nil:
    body_603101 = body
  result = call_603098.call(path_603099, query_603100, nil, nil, body_603101)

var completeMultipartUpload* = Call_CompleteMultipartUpload_603088(
    name: "completeMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_CompleteMultipartUpload_603089, base: "/",
    url: url_CompleteMultipartUpload_603090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParts_602803 = ref object of OpenApiRestCall_602466
proc url_ListParts_602805(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListParts_602804(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602931 = path.getOrDefault("Key")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = nil)
  if valid_602931 != nil:
    section.add "Key", valid_602931
  var valid_602932 = path.getOrDefault("Bucket")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = nil)
  if valid_602932 != nil:
    section.add "Bucket", valid_602932
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
  var valid_602933 = query.getOrDefault("max-parts")
  valid_602933 = validateParameter(valid_602933, JInt, required = false, default = nil)
  if valid_602933 != nil:
    section.add "max-parts", valid_602933
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_602934 = query.getOrDefault("uploadId")
  valid_602934 = validateParameter(valid_602934, JString, required = true,
                                 default = nil)
  if valid_602934 != nil:
    section.add "uploadId", valid_602934
  var valid_602935 = query.getOrDefault("MaxParts")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "MaxParts", valid_602935
  var valid_602936 = query.getOrDefault("part-number-marker")
  valid_602936 = validateParameter(valid_602936, JInt, required = false, default = nil)
  if valid_602936 != nil:
    section.add "part-number-marker", valid_602936
  var valid_602937 = query.getOrDefault("PartNumberMarker")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "PartNumberMarker", valid_602937
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602938 = header.getOrDefault("x-amz-security-token")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "x-amz-security-token", valid_602938
  var valid_602952 = header.getOrDefault("x-amz-request-payer")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = newJString("requester"))
  if valid_602952 != nil:
    section.add "x-amz-request-payer", valid_602952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602975: Call_ListParts_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  let valid = call_602975.validator(path, query, header, formData, body)
  let scheme = call_602975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602975.url(scheme.get, call_602975.host, call_602975.base,
                         call_602975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602975, url, valid)

proc call*(call_603046: Call_ListParts_602803; uploadId: string; Key: string;
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
  var path_603047 = newJObject()
  var query_603049 = newJObject()
  add(query_603049, "max-parts", newJInt(maxParts))
  add(query_603049, "uploadId", newJString(uploadId))
  add(query_603049, "MaxParts", newJString(MaxParts))
  add(query_603049, "part-number-marker", newJInt(partNumberMarker))
  add(query_603049, "PartNumberMarker", newJString(PartNumberMarker))
  add(path_603047, "Key", newJString(Key))
  add(path_603047, "Bucket", newJString(Bucket))
  result = call_603046.call(path_603047, query_603049, nil, nil, nil)

var listParts* = Call_ListParts_602803(name: "listParts", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}#uploadId",
                                    validator: validate_ListParts_602804,
                                    base: "/", url: url_ListParts_602805,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortMultipartUpload_603102 = ref object of OpenApiRestCall_602466
proc url_AbortMultipartUpload_603104(protocol: Scheme; host: string; base: string;
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

proc validate_AbortMultipartUpload_603103(path: JsonNode; query: JsonNode;
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
  var valid_603105 = path.getOrDefault("Key")
  valid_603105 = validateParameter(valid_603105, JString, required = true,
                                 default = nil)
  if valid_603105 != nil:
    section.add "Key", valid_603105
  var valid_603106 = path.getOrDefault("Bucket")
  valid_603106 = validateParameter(valid_603106, JString, required = true,
                                 default = nil)
  if valid_603106 != nil:
    section.add "Bucket", valid_603106
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID that identifies the multipart upload.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_603107 = query.getOrDefault("uploadId")
  valid_603107 = validateParameter(valid_603107, JString, required = true,
                                 default = nil)
  if valid_603107 != nil:
    section.add "uploadId", valid_603107
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_603108 = header.getOrDefault("x-amz-security-token")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "x-amz-security-token", valid_603108
  var valid_603109 = header.getOrDefault("x-amz-request-payer")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = newJString("requester"))
  if valid_603109 != nil:
    section.add "x-amz-request-payer", valid_603109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603110: Call_AbortMultipartUpload_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  let valid = call_603110.validator(path, query, header, formData, body)
  let scheme = call_603110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603110.url(scheme.get, call_603110.host, call_603110.base,
                         call_603110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603110, url, valid)

proc call*(call_603111: Call_AbortMultipartUpload_603102; uploadId: string;
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
  var path_603112 = newJObject()
  var query_603113 = newJObject()
  add(query_603113, "uploadId", newJString(uploadId))
  add(path_603112, "Key", newJString(Key))
  add(path_603112, "Bucket", newJString(Bucket))
  result = call_603111.call(path_603112, query_603113, nil, nil, nil)

var abortMultipartUpload* = Call_AbortMultipartUpload_603102(
    name: "abortMultipartUpload", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_AbortMultipartUpload_603103, base: "/",
    url: url_AbortMultipartUpload_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyObject_603114 = ref object of OpenApiRestCall_602466
proc url_CopyObject_603116(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CopyObject_603115(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603117 = path.getOrDefault("Key")
  valid_603117 = validateParameter(valid_603117, JString, required = true,
                                 default = nil)
  if valid_603117 != nil:
    section.add "Key", valid_603117
  var valid_603118 = path.getOrDefault("Bucket")
  valid_603118 = validateParameter(valid_603118, JString, required = true,
                                 default = nil)
  if valid_603118 != nil:
    section.add "Bucket", valid_603118
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
  var valid_603119 = header.getOrDefault("Content-Disposition")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "Content-Disposition", valid_603119
  var valid_603120 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_603120
  var valid_603121 = header.getOrDefault("x-amz-grant-full-control")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "x-amz-grant-full-control", valid_603121
  var valid_603122 = header.getOrDefault("x-amz-security-token")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "x-amz-security-token", valid_603122
  var valid_603123 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_603123
  var valid_603124 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_603124
  var valid_603125 = header.getOrDefault("x-amz-tagging-directive")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = newJString("COPY"))
  if valid_603125 != nil:
    section.add "x-amz-tagging-directive", valid_603125
  var valid_603126 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_603126
  var valid_603127 = header.getOrDefault("x-amz-object-lock-mode")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_603127 != nil:
    section.add "x-amz-object-lock-mode", valid_603127
  var valid_603128 = header.getOrDefault("Cache-Control")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "Cache-Control", valid_603128
  var valid_603129 = header.getOrDefault("Content-Language")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "Content-Language", valid_603129
  var valid_603130 = header.getOrDefault("Content-Type")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "Content-Type", valid_603130
  var valid_603131 = header.getOrDefault("Expires")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "Expires", valid_603131
  var valid_603132 = header.getOrDefault("x-amz-website-redirect-location")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "x-amz-website-redirect-location", valid_603132
  var valid_603133 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_603133
  var valid_603134 = header.getOrDefault("x-amz-acl")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = newJString("private"))
  if valid_603134 != nil:
    section.add "x-amz-acl", valid_603134
  var valid_603135 = header.getOrDefault("x-amz-grant-read")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "x-amz-grant-read", valid_603135
  var valid_603136 = header.getOrDefault("x-amz-storage-class")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_603136 != nil:
    section.add "x-amz-storage-class", valid_603136
  var valid_603137 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = newJString("ON"))
  if valid_603137 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_603137
  var valid_603138 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_603138
  var valid_603139 = header.getOrDefault("x-amz-tagging")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "x-amz-tagging", valid_603139
  var valid_603140 = header.getOrDefault("x-amz-grant-read-acp")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "x-amz-grant-read-acp", valid_603140
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_603141 = header.getOrDefault("x-amz-copy-source")
  valid_603141 = validateParameter(valid_603141, JString, required = true,
                                 default = nil)
  if valid_603141 != nil:
    section.add "x-amz-copy-source", valid_603141
  var valid_603142 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "x-amz-server-side-encryption-context", valid_603142
  var valid_603143 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_603143
  var valid_603144 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_603144
  var valid_603145 = header.getOrDefault("x-amz-metadata-directive")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = newJString("COPY"))
  if valid_603145 != nil:
    section.add "x-amz-metadata-directive", valid_603145
  var valid_603146 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "x-amz-copy-source-if-match", valid_603146
  var valid_603147 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_603147
  var valid_603148 = header.getOrDefault("x-amz-grant-write-acp")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "x-amz-grant-write-acp", valid_603148
  var valid_603149 = header.getOrDefault("Content-Encoding")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "Content-Encoding", valid_603149
  var valid_603150 = header.getOrDefault("x-amz-request-payer")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = newJString("requester"))
  if valid_603150 != nil:
    section.add "x-amz-request-payer", valid_603150
  var valid_603151 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_603151
  var valid_603152 = header.getOrDefault("x-amz-server-side-encryption")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = newJString("AES256"))
  if valid_603152 != nil:
    section.add "x-amz-server-side-encryption", valid_603152
  var valid_603153 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_603153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603155: Call_CopyObject_603114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  let valid = call_603155.validator(path, query, header, formData, body)
  let scheme = call_603155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603155.url(scheme.get, call_603155.host, call_603155.base,
                         call_603155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603155, url, valid)

proc call*(call_603156: Call_CopyObject_603114; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## copyObject
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603157 = newJObject()
  var body_603158 = newJObject()
  add(path_603157, "Key", newJString(Key))
  add(path_603157, "Bucket", newJString(Bucket))
  if body != nil:
    body_603158 = body
  result = call_603156.call(path_603157, nil, nil, nil, body_603158)

var copyObject* = Call_CopyObject_603114(name: "copyObject",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#x-amz-copy-source",
                                      validator: validate_CopyObject_603115,
                                      base: "/", url: url_CopyObject_603116,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBucket_603176 = ref object of OpenApiRestCall_602466
proc url_CreateBucket_603178(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBucket_603177(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603179 = path.getOrDefault("Bucket")
  valid_603179 = validateParameter(valid_603179, JString, required = true,
                                 default = nil)
  if valid_603179 != nil:
    section.add "Bucket", valid_603179
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
  var valid_603180 = header.getOrDefault("x-amz-security-token")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "x-amz-security-token", valid_603180
  var valid_603181 = header.getOrDefault("x-amz-acl")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = newJString("private"))
  if valid_603181 != nil:
    section.add "x-amz-acl", valid_603181
  var valid_603182 = header.getOrDefault("x-amz-grant-read")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "x-amz-grant-read", valid_603182
  var valid_603183 = header.getOrDefault("x-amz-grant-read-acp")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "x-amz-grant-read-acp", valid_603183
  var valid_603184 = header.getOrDefault("x-amz-bucket-object-lock-enabled")
  valid_603184 = validateParameter(valid_603184, JBool, required = false, default = nil)
  if valid_603184 != nil:
    section.add "x-amz-bucket-object-lock-enabled", valid_603184
  var valid_603185 = header.getOrDefault("x-amz-grant-write")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "x-amz-grant-write", valid_603185
  var valid_603186 = header.getOrDefault("x-amz-grant-write-acp")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "x-amz-grant-write-acp", valid_603186
  var valid_603187 = header.getOrDefault("x-amz-grant-full-control")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "x-amz-grant-full-control", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_CreateBucket_603176; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_CreateBucket_603176; Bucket: string; body: JsonNode): Recallable =
  ## createBucket
  ## Creates a new bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603191 = newJObject()
  var body_603192 = newJObject()
  add(path_603191, "Bucket", newJString(Bucket))
  if body != nil:
    body_603192 = body
  result = call_603190.call(path_603191, nil, nil, nil, body_603192)

var createBucket* = Call_CreateBucket_603176(name: "createBucket",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_CreateBucket_603177, base: "/", url: url_CreateBucket_603178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadBucket_603201 = ref object of OpenApiRestCall_602466
proc url_HeadBucket_603203(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_HeadBucket_603202(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603204 = path.getOrDefault("Bucket")
  valid_603204 = validateParameter(valid_603204, JString, required = true,
                                 default = nil)
  if valid_603204 != nil:
    section.add "Bucket", valid_603204
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603205 = header.getOrDefault("x-amz-security-token")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "x-amz-security-token", valid_603205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603206: Call_HeadBucket_603201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  let valid = call_603206.validator(path, query, header, formData, body)
  let scheme = call_603206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603206.url(scheme.get, call_603206.host, call_603206.base,
                         call_603206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603206, url, valid)

proc call*(call_603207: Call_HeadBucket_603201; Bucket: string): Recallable =
  ## headBucket
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603208 = newJObject()
  add(path_603208, "Bucket", newJString(Bucket))
  result = call_603207.call(path_603208, nil, nil, nil, nil)

var headBucket* = Call_HeadBucket_603201(name: "headBucket",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}",
                                      validator: validate_HeadBucket_603202,
                                      base: "/", url: url_HeadBucket_603203,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjects_603159 = ref object of OpenApiRestCall_602466
proc url_ListObjects_603161(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjects_603160(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603162 = path.getOrDefault("Bucket")
  valid_603162 = validateParameter(valid_603162, JString, required = true,
                                 default = nil)
  if valid_603162 != nil:
    section.add "Bucket", valid_603162
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
  var valid_603163 = query.getOrDefault("max-keys")
  valid_603163 = validateParameter(valid_603163, JInt, required = false, default = nil)
  if valid_603163 != nil:
    section.add "max-keys", valid_603163
  var valid_603164 = query.getOrDefault("encoding-type")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = newJString("url"))
  if valid_603164 != nil:
    section.add "encoding-type", valid_603164
  var valid_603165 = query.getOrDefault("marker")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "marker", valid_603165
  var valid_603166 = query.getOrDefault("Marker")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "Marker", valid_603166
  var valid_603167 = query.getOrDefault("delimiter")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "delimiter", valid_603167
  var valid_603168 = query.getOrDefault("prefix")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "prefix", valid_603168
  var valid_603169 = query.getOrDefault("MaxKeys")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "MaxKeys", valid_603169
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_603170 = header.getOrDefault("x-amz-security-token")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "x-amz-security-token", valid_603170
  var valid_603171 = header.getOrDefault("x-amz-request-payer")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = newJString("requester"))
  if valid_603171 != nil:
    section.add "x-amz-request-payer", valid_603171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603172: Call_ListObjects_603159; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
  let valid = call_603172.validator(path, query, header, formData, body)
  let scheme = call_603172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603172.url(scheme.get, call_603172.host, call_603172.base,
                         call_603172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603172, url, valid)

proc call*(call_603173: Call_ListObjects_603159; Bucket: string; maxKeys: int = 0;
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
  var path_603174 = newJObject()
  var query_603175 = newJObject()
  add(query_603175, "max-keys", newJInt(maxKeys))
  add(query_603175, "encoding-type", newJString(encodingType))
  add(query_603175, "marker", newJString(marker))
  add(query_603175, "Marker", newJString(Marker))
  add(query_603175, "delimiter", newJString(delimiter))
  add(path_603174, "Bucket", newJString(Bucket))
  add(query_603175, "prefix", newJString(prefix))
  add(query_603175, "MaxKeys", newJString(MaxKeys))
  result = call_603173.call(path_603174, query_603175, nil, nil, nil)

var listObjects* = Call_ListObjects_603159(name: "listObjects",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com",
                                        route: "/{Bucket}",
                                        validator: validate_ListObjects_603160,
                                        base: "/", url: url_ListObjects_603161,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucket_603193 = ref object of OpenApiRestCall_602466
proc url_DeleteBucket_603195(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucket_603194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603196 = path.getOrDefault("Bucket")
  valid_603196 = validateParameter(valid_603196, JString, required = true,
                                 default = nil)
  if valid_603196 != nil:
    section.add "Bucket", valid_603196
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603197 = header.getOrDefault("x-amz-security-token")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "x-amz-security-token", valid_603197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603198: Call_DeleteBucket_603193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  let valid = call_603198.validator(path, query, header, formData, body)
  let scheme = call_603198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603198.url(scheme.get, call_603198.host, call_603198.base,
                         call_603198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603198, url, valid)

proc call*(call_603199: Call_DeleteBucket_603193; Bucket: string): Recallable =
  ## deleteBucket
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603200 = newJObject()
  add(path_603200, "Bucket", newJString(Bucket))
  result = call_603199.call(path_603200, nil, nil, nil, nil)

var deleteBucket* = Call_DeleteBucket_603193(name: "deleteBucket",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_DeleteBucket_603194, base: "/", url: url_DeleteBucket_603195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultipartUpload_603209 = ref object of OpenApiRestCall_602466
proc url_CreateMultipartUpload_603211(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMultipartUpload_603210(path: JsonNode; query: JsonNode;
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
  var valid_603212 = path.getOrDefault("Key")
  valid_603212 = validateParameter(valid_603212, JString, required = true,
                                 default = nil)
  if valid_603212 != nil:
    section.add "Key", valid_603212
  var valid_603213 = path.getOrDefault("Bucket")
  valid_603213 = validateParameter(valid_603213, JString, required = true,
                                 default = nil)
  if valid_603213 != nil:
    section.add "Bucket", valid_603213
  result.add "path", section
  ## parameters in `query` object:
  ##   uploads: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_603214 = query.getOrDefault("uploads")
  valid_603214 = validateParameter(valid_603214, JBool, required = true, default = nil)
  if valid_603214 != nil:
    section.add "uploads", valid_603214
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
  var valid_603215 = header.getOrDefault("Content-Disposition")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "Content-Disposition", valid_603215
  var valid_603216 = header.getOrDefault("x-amz-grant-full-control")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "x-amz-grant-full-control", valid_603216
  var valid_603217 = header.getOrDefault("x-amz-security-token")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "x-amz-security-token", valid_603217
  var valid_603218 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_603218
  var valid_603219 = header.getOrDefault("x-amz-object-lock-mode")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_603219 != nil:
    section.add "x-amz-object-lock-mode", valid_603219
  var valid_603220 = header.getOrDefault("Cache-Control")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "Cache-Control", valid_603220
  var valid_603221 = header.getOrDefault("Content-Language")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "Content-Language", valid_603221
  var valid_603222 = header.getOrDefault("Content-Type")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "Content-Type", valid_603222
  var valid_603223 = header.getOrDefault("Expires")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "Expires", valid_603223
  var valid_603224 = header.getOrDefault("x-amz-website-redirect-location")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "x-amz-website-redirect-location", valid_603224
  var valid_603225 = header.getOrDefault("x-amz-acl")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = newJString("private"))
  if valid_603225 != nil:
    section.add "x-amz-acl", valid_603225
  var valid_603226 = header.getOrDefault("x-amz-grant-read")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "x-amz-grant-read", valid_603226
  var valid_603227 = header.getOrDefault("x-amz-storage-class")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_603227 != nil:
    section.add "x-amz-storage-class", valid_603227
  var valid_603228 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = newJString("ON"))
  if valid_603228 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_603228
  var valid_603229 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_603229
  var valid_603230 = header.getOrDefault("x-amz-tagging")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "x-amz-tagging", valid_603230
  var valid_603231 = header.getOrDefault("x-amz-grant-read-acp")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "x-amz-grant-read-acp", valid_603231
  var valid_603232 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "x-amz-server-side-encryption-context", valid_603232
  var valid_603233 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_603233
  var valid_603234 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_603234
  var valid_603235 = header.getOrDefault("x-amz-grant-write-acp")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "x-amz-grant-write-acp", valid_603235
  var valid_603236 = header.getOrDefault("Content-Encoding")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "Content-Encoding", valid_603236
  var valid_603237 = header.getOrDefault("x-amz-request-payer")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = newJString("requester"))
  if valid_603237 != nil:
    section.add "x-amz-request-payer", valid_603237
  var valid_603238 = header.getOrDefault("x-amz-server-side-encryption")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = newJString("AES256"))
  if valid_603238 != nil:
    section.add "x-amz-server-side-encryption", valid_603238
  var valid_603239 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_603239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603241: Call_CreateMultipartUpload_603209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  let valid = call_603241.validator(path, query, header, formData, body)
  let scheme = call_603241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603241.url(scheme.get, call_603241.host, call_603241.base,
                         call_603241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603241, url, valid)

proc call*(call_603242: Call_CreateMultipartUpload_603209; Key: string;
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
  var path_603243 = newJObject()
  var query_603244 = newJObject()
  var body_603245 = newJObject()
  add(path_603243, "Key", newJString(Key))
  add(query_603244, "uploads", newJBool(uploads))
  add(path_603243, "Bucket", newJString(Bucket))
  if body != nil:
    body_603245 = body
  result = call_603242.call(path_603243, query_603244, nil, nil, body_603245)

var createMultipartUpload* = Call_CreateMultipartUpload_603209(
    name: "createMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploads",
    validator: validate_CreateMultipartUpload_603210, base: "/",
    url: url_CreateMultipartUpload_603211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAnalyticsConfiguration_603257 = ref object of OpenApiRestCall_602466
proc url_PutBucketAnalyticsConfiguration_603259(protocol: Scheme; host: string;
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

proc validate_PutBucketAnalyticsConfiguration_603258(path: JsonNode;
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
  var valid_603260 = path.getOrDefault("Bucket")
  valid_603260 = validateParameter(valid_603260, JString, required = true,
                                 default = nil)
  if valid_603260 != nil:
    section.add "Bucket", valid_603260
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603261 = query.getOrDefault("id")
  valid_603261 = validateParameter(valid_603261, JString, required = true,
                                 default = nil)
  if valid_603261 != nil:
    section.add "id", valid_603261
  var valid_603262 = query.getOrDefault("analytics")
  valid_603262 = validateParameter(valid_603262, JBool, required = true, default = nil)
  if valid_603262 != nil:
    section.add "analytics", valid_603262
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603263 = header.getOrDefault("x-amz-security-token")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "x-amz-security-token", valid_603263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603265: Call_PutBucketAnalyticsConfiguration_603257;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_603265.validator(path, query, header, formData, body)
  let scheme = call_603265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603265.url(scheme.get, call_603265.host, call_603265.base,
                         call_603265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603265, url, valid)

proc call*(call_603266: Call_PutBucketAnalyticsConfiguration_603257; id: string;
          analytics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAnalyticsConfiguration
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket to which an analytics configuration is stored.
  ##   body: JObject (required)
  var path_603267 = newJObject()
  var query_603268 = newJObject()
  var body_603269 = newJObject()
  add(query_603268, "id", newJString(id))
  add(query_603268, "analytics", newJBool(analytics))
  add(path_603267, "Bucket", newJString(Bucket))
  if body != nil:
    body_603269 = body
  result = call_603266.call(path_603267, query_603268, nil, nil, body_603269)

var putBucketAnalyticsConfiguration* = Call_PutBucketAnalyticsConfiguration_603257(
    name: "putBucketAnalyticsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_PutBucketAnalyticsConfiguration_603258, base: "/",
    url: url_PutBucketAnalyticsConfiguration_603259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAnalyticsConfiguration_603246 = ref object of OpenApiRestCall_602466
proc url_GetBucketAnalyticsConfiguration_603248(protocol: Scheme; host: string;
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

proc validate_GetBucketAnalyticsConfiguration_603247(path: JsonNode;
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
  var valid_603249 = path.getOrDefault("Bucket")
  valid_603249 = validateParameter(valid_603249, JString, required = true,
                                 default = nil)
  if valid_603249 != nil:
    section.add "Bucket", valid_603249
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603250 = query.getOrDefault("id")
  valid_603250 = validateParameter(valid_603250, JString, required = true,
                                 default = nil)
  if valid_603250 != nil:
    section.add "id", valid_603250
  var valid_603251 = query.getOrDefault("analytics")
  valid_603251 = validateParameter(valid_603251, JBool, required = true, default = nil)
  if valid_603251 != nil:
    section.add "analytics", valid_603251
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603252 = header.getOrDefault("x-amz-security-token")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "x-amz-security-token", valid_603252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603253: Call_GetBucketAnalyticsConfiguration_603246;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_603253.validator(path, query, header, formData, body)
  let scheme = call_603253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603253.url(scheme.get, call_603253.host, call_603253.base,
                         call_603253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603253, url, valid)

proc call*(call_603254: Call_GetBucketAnalyticsConfiguration_603246; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## getBucketAnalyticsConfiguration
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is retrieved.
  var path_603255 = newJObject()
  var query_603256 = newJObject()
  add(query_603256, "id", newJString(id))
  add(query_603256, "analytics", newJBool(analytics))
  add(path_603255, "Bucket", newJString(Bucket))
  result = call_603254.call(path_603255, query_603256, nil, nil, nil)

var getBucketAnalyticsConfiguration* = Call_GetBucketAnalyticsConfiguration_603246(
    name: "getBucketAnalyticsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_GetBucketAnalyticsConfiguration_603247, base: "/",
    url: url_GetBucketAnalyticsConfiguration_603248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketAnalyticsConfiguration_603270 = ref object of OpenApiRestCall_602466
proc url_DeleteBucketAnalyticsConfiguration_603272(protocol: Scheme; host: string;
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

proc validate_DeleteBucketAnalyticsConfiguration_603271(path: JsonNode;
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
  var valid_603273 = path.getOrDefault("Bucket")
  valid_603273 = validateParameter(valid_603273, JString, required = true,
                                 default = nil)
  if valid_603273 != nil:
    section.add "Bucket", valid_603273
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603274 = query.getOrDefault("id")
  valid_603274 = validateParameter(valid_603274, JString, required = true,
                                 default = nil)
  if valid_603274 != nil:
    section.add "id", valid_603274
  var valid_603275 = query.getOrDefault("analytics")
  valid_603275 = validateParameter(valid_603275, JBool, required = true, default = nil)
  if valid_603275 != nil:
    section.add "analytics", valid_603275
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603276 = header.getOrDefault("x-amz-security-token")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "x-amz-security-token", valid_603276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603277: Call_DeleteBucketAnalyticsConfiguration_603270;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ## 
  let valid = call_603277.validator(path, query, header, formData, body)
  let scheme = call_603277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603277.url(scheme.get, call_603277.host, call_603277.base,
                         call_603277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603277, url, valid)

proc call*(call_603278: Call_DeleteBucketAnalyticsConfiguration_603270; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## deleteBucketAnalyticsConfiguration
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is deleted.
  var path_603279 = newJObject()
  var query_603280 = newJObject()
  add(query_603280, "id", newJString(id))
  add(query_603280, "analytics", newJBool(analytics))
  add(path_603279, "Bucket", newJString(Bucket))
  result = call_603278.call(path_603279, query_603280, nil, nil, nil)

var deleteBucketAnalyticsConfiguration* = Call_DeleteBucketAnalyticsConfiguration_603270(
    name: "deleteBucketAnalyticsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_DeleteBucketAnalyticsConfiguration_603271, base: "/",
    url: url_DeleteBucketAnalyticsConfiguration_603272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketCors_603291 = ref object of OpenApiRestCall_602466
proc url_PutBucketCors_603293(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketCors_603292(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603294 = path.getOrDefault("Bucket")
  valid_603294 = validateParameter(valid_603294, JString, required = true,
                                 default = nil)
  if valid_603294 != nil:
    section.add "Bucket", valid_603294
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_603295 = query.getOrDefault("cors")
  valid_603295 = validateParameter(valid_603295, JBool, required = true, default = nil)
  if valid_603295 != nil:
    section.add "cors", valid_603295
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603296 = header.getOrDefault("x-amz-security-token")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "x-amz-security-token", valid_603296
  var valid_603297 = header.getOrDefault("Content-MD5")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "Content-MD5", valid_603297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603299: Call_PutBucketCors_603291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the CORS configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  let valid = call_603299.validator(path, query, header, formData, body)
  let scheme = call_603299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603299.url(scheme.get, call_603299.host, call_603299.base,
                         call_603299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603299, url, valid)

proc call*(call_603300: Call_PutBucketCors_603291; cors: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketCors
  ## Sets the CORS configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603301 = newJObject()
  var query_603302 = newJObject()
  var body_603303 = newJObject()
  add(query_603302, "cors", newJBool(cors))
  add(path_603301, "Bucket", newJString(Bucket))
  if body != nil:
    body_603303 = body
  result = call_603300.call(path_603301, query_603302, nil, nil, body_603303)

var putBucketCors* = Call_PutBucketCors_603291(name: "putBucketCors",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_PutBucketCors_603292, base: "/", url: url_PutBucketCors_603293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketCors_603281 = ref object of OpenApiRestCall_602466
proc url_GetBucketCors_603283(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketCors_603282(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603284 = path.getOrDefault("Bucket")
  valid_603284 = validateParameter(valid_603284, JString, required = true,
                                 default = nil)
  if valid_603284 != nil:
    section.add "Bucket", valid_603284
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_603285 = query.getOrDefault("cors")
  valid_603285 = validateParameter(valid_603285, JBool, required = true, default = nil)
  if valid_603285 != nil:
    section.add "cors", valid_603285
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603286 = header.getOrDefault("x-amz-security-token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "x-amz-security-token", valid_603286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603287: Call_GetBucketCors_603281; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the CORS configuration for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  let valid = call_603287.validator(path, query, header, formData, body)
  let scheme = call_603287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603287.url(scheme.get, call_603287.host, call_603287.base,
                         call_603287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603287, url, valid)

proc call*(call_603288: Call_GetBucketCors_603281; cors: bool; Bucket: string): Recallable =
  ## getBucketCors
  ## Returns the CORS configuration for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603289 = newJObject()
  var query_603290 = newJObject()
  add(query_603290, "cors", newJBool(cors))
  add(path_603289, "Bucket", newJString(Bucket))
  result = call_603288.call(path_603289, query_603290, nil, nil, nil)

var getBucketCors* = Call_GetBucketCors_603281(name: "getBucketCors",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_GetBucketCors_603282, base: "/", url: url_GetBucketCors_603283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketCors_603304 = ref object of OpenApiRestCall_602466
proc url_DeleteBucketCors_603306(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketCors_603305(path: JsonNode; query: JsonNode;
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
  var valid_603307 = path.getOrDefault("Bucket")
  valid_603307 = validateParameter(valid_603307, JString, required = true,
                                 default = nil)
  if valid_603307 != nil:
    section.add "Bucket", valid_603307
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_603308 = query.getOrDefault("cors")
  valid_603308 = validateParameter(valid_603308, JBool, required = true, default = nil)
  if valid_603308 != nil:
    section.add "cors", valid_603308
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603309 = header.getOrDefault("x-amz-security-token")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "x-amz-security-token", valid_603309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603310: Call_DeleteBucketCors_603304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the CORS configuration information set for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  let valid = call_603310.validator(path, query, header, formData, body)
  let scheme = call_603310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603310.url(scheme.get, call_603310.host, call_603310.base,
                         call_603310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603310, url, valid)

proc call*(call_603311: Call_DeleteBucketCors_603304; cors: bool; Bucket: string): Recallable =
  ## deleteBucketCors
  ## Deletes the CORS configuration information set for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603312 = newJObject()
  var query_603313 = newJObject()
  add(query_603313, "cors", newJBool(cors))
  add(path_603312, "Bucket", newJString(Bucket))
  result = call_603311.call(path_603312, query_603313, nil, nil, nil)

var deleteBucketCors* = Call_DeleteBucketCors_603304(name: "deleteBucketCors",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_DeleteBucketCors_603305, base: "/",
    url: url_DeleteBucketCors_603306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketEncryption_603324 = ref object of OpenApiRestCall_602466
proc url_PutBucketEncryption_603326(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketEncryption_603325(path: JsonNode; query: JsonNode;
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
  var valid_603327 = path.getOrDefault("Bucket")
  valid_603327 = validateParameter(valid_603327, JString, required = true,
                                 default = nil)
  if valid_603327 != nil:
    section.add "Bucket", valid_603327
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_603328 = query.getOrDefault("encryption")
  valid_603328 = validateParameter(valid_603328, JBool, required = true, default = nil)
  if valid_603328 != nil:
    section.add "encryption", valid_603328
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the server-side encryption configuration. This parameter is auto-populated when using the command from the CLI.
  section = newJObject()
  var valid_603329 = header.getOrDefault("x-amz-security-token")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "x-amz-security-token", valid_603329
  var valid_603330 = header.getOrDefault("Content-MD5")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "Content-MD5", valid_603330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603332: Call_PutBucketEncryption_603324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ## 
  let valid = call_603332.validator(path, query, header, formData, body)
  let scheme = call_603332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603332.url(scheme.get, call_603332.host, call_603332.base,
                         call_603332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603332, url, valid)

proc call*(call_603333: Call_PutBucketEncryption_603324; encryption: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketEncryption
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : Specifies default encryption for a bucket using server-side encryption with Amazon S3-managed keys (SSE-S3) or AWS KMS-managed keys (SSE-KMS). For information about the Amazon S3 default encryption feature, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 Default Bucket Encryption</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   body: JObject (required)
  var path_603334 = newJObject()
  var query_603335 = newJObject()
  var body_603336 = newJObject()
  add(query_603335, "encryption", newJBool(encryption))
  add(path_603334, "Bucket", newJString(Bucket))
  if body != nil:
    body_603336 = body
  result = call_603333.call(path_603334, query_603335, nil, nil, body_603336)

var putBucketEncryption* = Call_PutBucketEncryption_603324(
    name: "putBucketEncryption", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_PutBucketEncryption_603325,
    base: "/", url: url_PutBucketEncryption_603326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketEncryption_603314 = ref object of OpenApiRestCall_602466
proc url_GetBucketEncryption_603316(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketEncryption_603315(path: JsonNode; query: JsonNode;
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
  var valid_603317 = path.getOrDefault("Bucket")
  valid_603317 = validateParameter(valid_603317, JString, required = true,
                                 default = nil)
  if valid_603317 != nil:
    section.add "Bucket", valid_603317
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_603318 = query.getOrDefault("encryption")
  valid_603318 = validateParameter(valid_603318, JBool, required = true, default = nil)
  if valid_603318 != nil:
    section.add "encryption", valid_603318
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603319 = header.getOrDefault("x-amz-security-token")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "x-amz-security-token", valid_603319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603320: Call_GetBucketEncryption_603314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the server-side encryption configuration of a bucket.
  ## 
  let valid = call_603320.validator(path, query, header, formData, body)
  let scheme = call_603320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603320.url(scheme.get, call_603320.host, call_603320.base,
                         call_603320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603320, url, valid)

proc call*(call_603321: Call_GetBucketEncryption_603314; encryption: bool;
          Bucket: string): Recallable =
  ## getBucketEncryption
  ## Returns the server-side encryption configuration of a bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which the server-side encryption configuration is retrieved.
  var path_603322 = newJObject()
  var query_603323 = newJObject()
  add(query_603323, "encryption", newJBool(encryption))
  add(path_603322, "Bucket", newJString(Bucket))
  result = call_603321.call(path_603322, query_603323, nil, nil, nil)

var getBucketEncryption* = Call_GetBucketEncryption_603314(
    name: "getBucketEncryption", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_GetBucketEncryption_603315,
    base: "/", url: url_GetBucketEncryption_603316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketEncryption_603337 = ref object of OpenApiRestCall_602466
proc url_DeleteBucketEncryption_603339(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketEncryption_603338(path: JsonNode; query: JsonNode;
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
  var valid_603340 = path.getOrDefault("Bucket")
  valid_603340 = validateParameter(valid_603340, JString, required = true,
                                 default = nil)
  if valid_603340 != nil:
    section.add "Bucket", valid_603340
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_603341 = query.getOrDefault("encryption")
  valid_603341 = validateParameter(valid_603341, JBool, required = true, default = nil)
  if valid_603341 != nil:
    section.add "encryption", valid_603341
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603342 = header.getOrDefault("x-amz-security-token")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "x-amz-security-token", valid_603342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603343: Call_DeleteBucketEncryption_603337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the server-side encryption configuration from the bucket.
  ## 
  let valid = call_603343.validator(path, query, header, formData, body)
  let scheme = call_603343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603343.url(scheme.get, call_603343.host, call_603343.base,
                         call_603343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603343, url, valid)

proc call*(call_603344: Call_DeleteBucketEncryption_603337; encryption: bool;
          Bucket: string): Recallable =
  ## deleteBucketEncryption
  ## Deletes the server-side encryption configuration from the bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the server-side encryption configuration to delete.
  var path_603345 = newJObject()
  var query_603346 = newJObject()
  add(query_603346, "encryption", newJBool(encryption))
  add(path_603345, "Bucket", newJString(Bucket))
  result = call_603344.call(path_603345, query_603346, nil, nil, nil)

var deleteBucketEncryption* = Call_DeleteBucketEncryption_603337(
    name: "deleteBucketEncryption", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#encryption",
    validator: validate_DeleteBucketEncryption_603338, base: "/",
    url: url_DeleteBucketEncryption_603339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketInventoryConfiguration_603358 = ref object of OpenApiRestCall_602466
proc url_PutBucketInventoryConfiguration_603360(protocol: Scheme; host: string;
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

proc validate_PutBucketInventoryConfiguration_603359(path: JsonNode;
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
  var valid_603361 = path.getOrDefault("Bucket")
  valid_603361 = validateParameter(valid_603361, JString, required = true,
                                 default = nil)
  if valid_603361 != nil:
    section.add "Bucket", valid_603361
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_603362 = query.getOrDefault("inventory")
  valid_603362 = validateParameter(valid_603362, JBool, required = true, default = nil)
  if valid_603362 != nil:
    section.add "inventory", valid_603362
  var valid_603363 = query.getOrDefault("id")
  valid_603363 = validateParameter(valid_603363, JString, required = true,
                                 default = nil)
  if valid_603363 != nil:
    section.add "id", valid_603363
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603364 = header.getOrDefault("x-amz-security-token")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "x-amz-security-token", valid_603364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603366: Call_PutBucketInventoryConfiguration_603358;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_603366.validator(path, query, header, formData, body)
  let scheme = call_603366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603366.url(scheme.get, call_603366.host, call_603366.base,
                         call_603366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603366, url, valid)

proc call*(call_603367: Call_PutBucketInventoryConfiguration_603358;
          inventory: bool; id: string; Bucket: string; body: JsonNode): Recallable =
  ## putBucketInventoryConfiguration
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket where the inventory configuration will be stored.
  ##   body: JObject (required)
  var path_603368 = newJObject()
  var query_603369 = newJObject()
  var body_603370 = newJObject()
  add(query_603369, "inventory", newJBool(inventory))
  add(query_603369, "id", newJString(id))
  add(path_603368, "Bucket", newJString(Bucket))
  if body != nil:
    body_603370 = body
  result = call_603367.call(path_603368, query_603369, nil, nil, body_603370)

var putBucketInventoryConfiguration* = Call_PutBucketInventoryConfiguration_603358(
    name: "putBucketInventoryConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_PutBucketInventoryConfiguration_603359, base: "/",
    url: url_PutBucketInventoryConfiguration_603360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketInventoryConfiguration_603347 = ref object of OpenApiRestCall_602466
proc url_GetBucketInventoryConfiguration_603349(protocol: Scheme; host: string;
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

proc validate_GetBucketInventoryConfiguration_603348(path: JsonNode;
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
  var valid_603350 = path.getOrDefault("Bucket")
  valid_603350 = validateParameter(valid_603350, JString, required = true,
                                 default = nil)
  if valid_603350 != nil:
    section.add "Bucket", valid_603350
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_603351 = query.getOrDefault("inventory")
  valid_603351 = validateParameter(valid_603351, JBool, required = true, default = nil)
  if valid_603351 != nil:
    section.add "inventory", valid_603351
  var valid_603352 = query.getOrDefault("id")
  valid_603352 = validateParameter(valid_603352, JString, required = true,
                                 default = nil)
  if valid_603352 != nil:
    section.add "id", valid_603352
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603353 = header.getOrDefault("x-amz-security-token")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "x-amz-security-token", valid_603353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_GetBucketInventoryConfiguration_603347;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_GetBucketInventoryConfiguration_603347;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## getBucketInventoryConfiguration
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to retrieve.
  var path_603356 = newJObject()
  var query_603357 = newJObject()
  add(query_603357, "inventory", newJBool(inventory))
  add(query_603357, "id", newJString(id))
  add(path_603356, "Bucket", newJString(Bucket))
  result = call_603355.call(path_603356, query_603357, nil, nil, nil)

var getBucketInventoryConfiguration* = Call_GetBucketInventoryConfiguration_603347(
    name: "getBucketInventoryConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_GetBucketInventoryConfiguration_603348, base: "/",
    url: url_GetBucketInventoryConfiguration_603349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketInventoryConfiguration_603371 = ref object of OpenApiRestCall_602466
proc url_DeleteBucketInventoryConfiguration_603373(protocol: Scheme; host: string;
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

proc validate_DeleteBucketInventoryConfiguration_603372(path: JsonNode;
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
  var valid_603374 = path.getOrDefault("Bucket")
  valid_603374 = validateParameter(valid_603374, JString, required = true,
                                 default = nil)
  if valid_603374 != nil:
    section.add "Bucket", valid_603374
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_603375 = query.getOrDefault("inventory")
  valid_603375 = validateParameter(valid_603375, JBool, required = true, default = nil)
  if valid_603375 != nil:
    section.add "inventory", valid_603375
  var valid_603376 = query.getOrDefault("id")
  valid_603376 = validateParameter(valid_603376, JString, required = true,
                                 default = nil)
  if valid_603376 != nil:
    section.add "id", valid_603376
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603377 = header.getOrDefault("x-amz-security-token")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "x-amz-security-token", valid_603377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603378: Call_DeleteBucketInventoryConfiguration_603371;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_603378.validator(path, query, header, formData, body)
  let scheme = call_603378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603378.url(scheme.get, call_603378.host, call_603378.base,
                         call_603378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603378, url, valid)

proc call*(call_603379: Call_DeleteBucketInventoryConfiguration_603371;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## deleteBucketInventoryConfiguration
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to delete.
  var path_603380 = newJObject()
  var query_603381 = newJObject()
  add(query_603381, "inventory", newJBool(inventory))
  add(query_603381, "id", newJString(id))
  add(path_603380, "Bucket", newJString(Bucket))
  result = call_603379.call(path_603380, query_603381, nil, nil, nil)

var deleteBucketInventoryConfiguration* = Call_DeleteBucketInventoryConfiguration_603371(
    name: "deleteBucketInventoryConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_DeleteBucketInventoryConfiguration_603372, base: "/",
    url: url_DeleteBucketInventoryConfiguration_603373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycleConfiguration_603392 = ref object of OpenApiRestCall_602466
proc url_PutBucketLifecycleConfiguration_603394(protocol: Scheme; host: string;
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

proc validate_PutBucketLifecycleConfiguration_603393(path: JsonNode;
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
  var valid_603395 = path.getOrDefault("Bucket")
  valid_603395 = validateParameter(valid_603395, JString, required = true,
                                 default = nil)
  if valid_603395 != nil:
    section.add "Bucket", valid_603395
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_603396 = query.getOrDefault("lifecycle")
  valid_603396 = validateParameter(valid_603396, JBool, required = true, default = nil)
  if valid_603396 != nil:
    section.add "lifecycle", valid_603396
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603397 = header.getOrDefault("x-amz-security-token")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "x-amz-security-token", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603399: Call_PutBucketLifecycleConfiguration_603392;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ## 
  let valid = call_603399.validator(path, query, header, formData, body)
  let scheme = call_603399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603399.url(scheme.get, call_603399.host, call_603399.base,
                         call_603399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603399, url, valid)

proc call*(call_603400: Call_PutBucketLifecycleConfiguration_603392;
          Bucket: string; lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycleConfiguration
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_603401 = newJObject()
  var query_603402 = newJObject()
  var body_603403 = newJObject()
  add(path_603401, "Bucket", newJString(Bucket))
  add(query_603402, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_603403 = body
  result = call_603400.call(path_603401, query_603402, nil, nil, body_603403)

var putBucketLifecycleConfiguration* = Call_PutBucketLifecycleConfiguration_603392(
    name: "putBucketLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_PutBucketLifecycleConfiguration_603393, base: "/",
    url: url_PutBucketLifecycleConfiguration_603394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycleConfiguration_603382 = ref object of OpenApiRestCall_602466
proc url_GetBucketLifecycleConfiguration_603384(protocol: Scheme; host: string;
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

proc validate_GetBucketLifecycleConfiguration_603383(path: JsonNode;
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
  var valid_603385 = path.getOrDefault("Bucket")
  valid_603385 = validateParameter(valid_603385, JString, required = true,
                                 default = nil)
  if valid_603385 != nil:
    section.add "Bucket", valid_603385
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_603386 = query.getOrDefault("lifecycle")
  valid_603386 = validateParameter(valid_603386, JBool, required = true, default = nil)
  if valid_603386 != nil:
    section.add "lifecycle", valid_603386
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603387 = header.getOrDefault("x-amz-security-token")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "x-amz-security-token", valid_603387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603388: Call_GetBucketLifecycleConfiguration_603382;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the lifecycle configuration information set on the bucket.
  ## 
  let valid = call_603388.validator(path, query, header, formData, body)
  let scheme = call_603388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603388.url(scheme.get, call_603388.host, call_603388.base,
                         call_603388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603388, url, valid)

proc call*(call_603389: Call_GetBucketLifecycleConfiguration_603382;
          Bucket: string; lifecycle: bool): Recallable =
  ## getBucketLifecycleConfiguration
  ## Returns the lifecycle configuration information set on the bucket.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_603390 = newJObject()
  var query_603391 = newJObject()
  add(path_603390, "Bucket", newJString(Bucket))
  add(query_603391, "lifecycle", newJBool(lifecycle))
  result = call_603389.call(path_603390, query_603391, nil, nil, nil)

var getBucketLifecycleConfiguration* = Call_GetBucketLifecycleConfiguration_603382(
    name: "getBucketLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_GetBucketLifecycleConfiguration_603383, base: "/",
    url: url_GetBucketLifecycleConfiguration_603384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketLifecycle_603404 = ref object of OpenApiRestCall_602466
proc url_DeleteBucketLifecycle_603406(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketLifecycle_603405(path: JsonNode; query: JsonNode;
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
  var valid_603407 = path.getOrDefault("Bucket")
  valid_603407 = validateParameter(valid_603407, JString, required = true,
                                 default = nil)
  if valid_603407 != nil:
    section.add "Bucket", valid_603407
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_603408 = query.getOrDefault("lifecycle")
  valid_603408 = validateParameter(valid_603408, JBool, required = true, default = nil)
  if valid_603408 != nil:
    section.add "lifecycle", valid_603408
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603409 = header.getOrDefault("x-amz-security-token")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "x-amz-security-token", valid_603409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603410: Call_DeleteBucketLifecycle_603404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the lifecycle configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  let valid = call_603410.validator(path, query, header, formData, body)
  let scheme = call_603410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603410.url(scheme.get, call_603410.host, call_603410.base,
                         call_603410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603410, url, valid)

proc call*(call_603411: Call_DeleteBucketLifecycle_603404; Bucket: string;
          lifecycle: bool): Recallable =
  ## deleteBucketLifecycle
  ## Deletes the lifecycle configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_603412 = newJObject()
  var query_603413 = newJObject()
  add(path_603412, "Bucket", newJString(Bucket))
  add(query_603413, "lifecycle", newJBool(lifecycle))
  result = call_603411.call(path_603412, query_603413, nil, nil, nil)

var deleteBucketLifecycle* = Call_DeleteBucketLifecycle_603404(
    name: "deleteBucketLifecycle", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_DeleteBucketLifecycle_603405, base: "/",
    url: url_DeleteBucketLifecycle_603406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketMetricsConfiguration_603425 = ref object of OpenApiRestCall_602466
proc url_PutBucketMetricsConfiguration_603427(protocol: Scheme; host: string;
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

proc validate_PutBucketMetricsConfiguration_603426(path: JsonNode; query: JsonNode;
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
  var valid_603428 = path.getOrDefault("Bucket")
  valid_603428 = validateParameter(valid_603428, JString, required = true,
                                 default = nil)
  if valid_603428 != nil:
    section.add "Bucket", valid_603428
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603429 = query.getOrDefault("id")
  valid_603429 = validateParameter(valid_603429, JString, required = true,
                                 default = nil)
  if valid_603429 != nil:
    section.add "id", valid_603429
  var valid_603430 = query.getOrDefault("metrics")
  valid_603430 = validateParameter(valid_603430, JBool, required = true, default = nil)
  if valid_603430 != nil:
    section.add "metrics", valid_603430
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603431 = header.getOrDefault("x-amz-security-token")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "x-amz-security-token", valid_603431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603433: Call_PutBucketMetricsConfiguration_603425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ## 
  let valid = call_603433.validator(path, query, header, formData, body)
  let scheme = call_603433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603433.url(scheme.get, call_603433.host, call_603433.base,
                         call_603433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603433, url, valid)

proc call*(call_603434: Call_PutBucketMetricsConfiguration_603425; id: string;
          metrics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketMetricsConfiguration
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket for which the metrics configuration is set.
  ##   body: JObject (required)
  var path_603435 = newJObject()
  var query_603436 = newJObject()
  var body_603437 = newJObject()
  add(query_603436, "id", newJString(id))
  add(query_603436, "metrics", newJBool(metrics))
  add(path_603435, "Bucket", newJString(Bucket))
  if body != nil:
    body_603437 = body
  result = call_603434.call(path_603435, query_603436, nil, nil, body_603437)

var putBucketMetricsConfiguration* = Call_PutBucketMetricsConfiguration_603425(
    name: "putBucketMetricsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_PutBucketMetricsConfiguration_603426, base: "/",
    url: url_PutBucketMetricsConfiguration_603427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketMetricsConfiguration_603414 = ref object of OpenApiRestCall_602466
proc url_GetBucketMetricsConfiguration_603416(protocol: Scheme; host: string;
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

proc validate_GetBucketMetricsConfiguration_603415(path: JsonNode; query: JsonNode;
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
  var valid_603417 = path.getOrDefault("Bucket")
  valid_603417 = validateParameter(valid_603417, JString, required = true,
                                 default = nil)
  if valid_603417 != nil:
    section.add "Bucket", valid_603417
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603418 = query.getOrDefault("id")
  valid_603418 = validateParameter(valid_603418, JString, required = true,
                                 default = nil)
  if valid_603418 != nil:
    section.add "id", valid_603418
  var valid_603419 = query.getOrDefault("metrics")
  valid_603419 = validateParameter(valid_603419, JBool, required = true, default = nil)
  if valid_603419 != nil:
    section.add "metrics", valid_603419
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603420 = header.getOrDefault("x-amz-security-token")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "x-amz-security-token", valid_603420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603421: Call_GetBucketMetricsConfiguration_603414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_603421.validator(path, query, header, formData, body)
  let scheme = call_603421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603421.url(scheme.get, call_603421.host, call_603421.base,
                         call_603421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603421, url, valid)

proc call*(call_603422: Call_GetBucketMetricsConfiguration_603414; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## getBucketMetricsConfiguration
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to retrieve.
  var path_603423 = newJObject()
  var query_603424 = newJObject()
  add(query_603424, "id", newJString(id))
  add(query_603424, "metrics", newJBool(metrics))
  add(path_603423, "Bucket", newJString(Bucket))
  result = call_603422.call(path_603423, query_603424, nil, nil, nil)

var getBucketMetricsConfiguration* = Call_GetBucketMetricsConfiguration_603414(
    name: "getBucketMetricsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_GetBucketMetricsConfiguration_603415, base: "/",
    url: url_GetBucketMetricsConfiguration_603416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketMetricsConfiguration_603438 = ref object of OpenApiRestCall_602466
proc url_DeleteBucketMetricsConfiguration_603440(protocol: Scheme; host: string;
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

proc validate_DeleteBucketMetricsConfiguration_603439(path: JsonNode;
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
  var valid_603441 = path.getOrDefault("Bucket")
  valid_603441 = validateParameter(valid_603441, JString, required = true,
                                 default = nil)
  if valid_603441 != nil:
    section.add "Bucket", valid_603441
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603442 = query.getOrDefault("id")
  valid_603442 = validateParameter(valid_603442, JString, required = true,
                                 default = nil)
  if valid_603442 != nil:
    section.add "id", valid_603442
  var valid_603443 = query.getOrDefault("metrics")
  valid_603443 = validateParameter(valid_603443, JBool, required = true, default = nil)
  if valid_603443 != nil:
    section.add "metrics", valid_603443
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603444 = header.getOrDefault("x-amz-security-token")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "x-amz-security-token", valid_603444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603445: Call_DeleteBucketMetricsConfiguration_603438;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_603445.validator(path, query, header, formData, body)
  let scheme = call_603445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603445.url(scheme.get, call_603445.host, call_603445.base,
                         call_603445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603445, url, valid)

proc call*(call_603446: Call_DeleteBucketMetricsConfiguration_603438; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## deleteBucketMetricsConfiguration
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to delete.
  var path_603447 = newJObject()
  var query_603448 = newJObject()
  add(query_603448, "id", newJString(id))
  add(query_603448, "metrics", newJBool(metrics))
  add(path_603447, "Bucket", newJString(Bucket))
  result = call_603446.call(path_603447, query_603448, nil, nil, nil)

var deleteBucketMetricsConfiguration* = Call_DeleteBucketMetricsConfiguration_603438(
    name: "deleteBucketMetricsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_DeleteBucketMetricsConfiguration_603439, base: "/",
    url: url_DeleteBucketMetricsConfiguration_603440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketPolicy_603459 = ref object of OpenApiRestCall_602466
proc url_PutBucketPolicy_603461(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketPolicy_603460(path: JsonNode; query: JsonNode;
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
  var valid_603462 = path.getOrDefault("Bucket")
  valid_603462 = validateParameter(valid_603462, JString, required = true,
                                 default = nil)
  if valid_603462 != nil:
    section.add "Bucket", valid_603462
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_603463 = query.getOrDefault("policy")
  valid_603463 = validateParameter(valid_603463, JBool, required = true, default = nil)
  if valid_603463 != nil:
    section.add "policy", valid_603463
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-confirm-remove-self-bucket-access: JBool
  ##                                          : Set this parameter to true to confirm that you want to remove your permissions to change this bucket policy in the future.
  section = newJObject()
  var valid_603464 = header.getOrDefault("x-amz-security-token")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "x-amz-security-token", valid_603464
  var valid_603465 = header.getOrDefault("Content-MD5")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "Content-MD5", valid_603465
  var valid_603466 = header.getOrDefault("x-amz-confirm-remove-self-bucket-access")
  valid_603466 = validateParameter(valid_603466, JBool, required = false, default = nil)
  if valid_603466 != nil:
    section.add "x-amz-confirm-remove-self-bucket-access", valid_603466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603468: Call_PutBucketPolicy_603459; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  let valid = call_603468.validator(path, query, header, formData, body)
  let scheme = call_603468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603468.url(scheme.get, call_603468.host, call_603468.base,
                         call_603468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603468, url, valid)

proc call*(call_603469: Call_PutBucketPolicy_603459; policy: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketPolicy
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603470 = newJObject()
  var query_603471 = newJObject()
  var body_603472 = newJObject()
  add(query_603471, "policy", newJBool(policy))
  add(path_603470, "Bucket", newJString(Bucket))
  if body != nil:
    body_603472 = body
  result = call_603469.call(path_603470, query_603471, nil, nil, body_603472)

var putBucketPolicy* = Call_PutBucketPolicy_603459(name: "putBucketPolicy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_PutBucketPolicy_603460, base: "/", url: url_PutBucketPolicy_603461,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicy_603449 = ref object of OpenApiRestCall_602466
proc url_GetBucketPolicy_603451(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketPolicy_603450(path: JsonNode; query: JsonNode;
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
  var valid_603452 = path.getOrDefault("Bucket")
  valid_603452 = validateParameter(valid_603452, JString, required = true,
                                 default = nil)
  if valid_603452 != nil:
    section.add "Bucket", valid_603452
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_603453 = query.getOrDefault("policy")
  valid_603453 = validateParameter(valid_603453, JBool, required = true, default = nil)
  if valid_603453 != nil:
    section.add "policy", valid_603453
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603454 = header.getOrDefault("x-amz-security-token")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "x-amz-security-token", valid_603454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603455: Call_GetBucketPolicy_603449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the policy of a specified bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  let valid = call_603455.validator(path, query, header, formData, body)
  let scheme = call_603455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603455.url(scheme.get, call_603455.host, call_603455.base,
                         call_603455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603455, url, valid)

proc call*(call_603456: Call_GetBucketPolicy_603449; policy: bool; Bucket: string): Recallable =
  ## getBucketPolicy
  ## Returns the policy of a specified bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603457 = newJObject()
  var query_603458 = newJObject()
  add(query_603458, "policy", newJBool(policy))
  add(path_603457, "Bucket", newJString(Bucket))
  result = call_603456.call(path_603457, query_603458, nil, nil, nil)

var getBucketPolicy* = Call_GetBucketPolicy_603449(name: "getBucketPolicy",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_GetBucketPolicy_603450, base: "/", url: url_GetBucketPolicy_603451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketPolicy_603473 = ref object of OpenApiRestCall_602466
proc url_DeleteBucketPolicy_603475(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketPolicy_603474(path: JsonNode; query: JsonNode;
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
  var valid_603476 = path.getOrDefault("Bucket")
  valid_603476 = validateParameter(valid_603476, JString, required = true,
                                 default = nil)
  if valid_603476 != nil:
    section.add "Bucket", valid_603476
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_603477 = query.getOrDefault("policy")
  valid_603477 = validateParameter(valid_603477, JBool, required = true, default = nil)
  if valid_603477 != nil:
    section.add "policy", valid_603477
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603478 = header.getOrDefault("x-amz-security-token")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "x-amz-security-token", valid_603478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603479: Call_DeleteBucketPolicy_603473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  let valid = call_603479.validator(path, query, header, formData, body)
  let scheme = call_603479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603479.url(scheme.get, call_603479.host, call_603479.base,
                         call_603479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603479, url, valid)

proc call*(call_603480: Call_DeleteBucketPolicy_603473; policy: bool; Bucket: string): Recallable =
  ## deleteBucketPolicy
  ## Deletes the policy from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603481 = newJObject()
  var query_603482 = newJObject()
  add(query_603482, "policy", newJBool(policy))
  add(path_603481, "Bucket", newJString(Bucket))
  result = call_603480.call(path_603481, query_603482, nil, nil, nil)

var deleteBucketPolicy* = Call_DeleteBucketPolicy_603473(
    name: "deleteBucketPolicy", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_DeleteBucketPolicy_603474, base: "/",
    url: url_DeleteBucketPolicy_603475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketReplication_603493 = ref object of OpenApiRestCall_602466
proc url_PutBucketReplication_603495(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketReplication_603494(path: JsonNode; query: JsonNode;
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
  var valid_603496 = path.getOrDefault("Bucket")
  valid_603496 = validateParameter(valid_603496, JString, required = true,
                                 default = nil)
  if valid_603496 != nil:
    section.add "Bucket", valid_603496
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_603497 = query.getOrDefault("replication")
  valid_603497 = validateParameter(valid_603497, JBool, required = true, default = nil)
  if valid_603497 != nil:
    section.add "replication", valid_603497
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit.
  ##   x-amz-bucket-object-lock-token: JString
  ##                                 : A token that allows Amazon S3 object lock to be enabled for an existing bucket.
  section = newJObject()
  var valid_603498 = header.getOrDefault("x-amz-security-token")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "x-amz-security-token", valid_603498
  var valid_603499 = header.getOrDefault("Content-MD5")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "Content-MD5", valid_603499
  var valid_603500 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_603500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603502: Call_PutBucketReplication_603493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_603502.validator(path, query, header, formData, body)
  let scheme = call_603502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603502.url(scheme.get, call_603502.host, call_603502.base,
                         call_603502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603502, url, valid)

proc call*(call_603503: Call_PutBucketReplication_603493; replication: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketReplication
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603504 = newJObject()
  var query_603505 = newJObject()
  var body_603506 = newJObject()
  add(query_603505, "replication", newJBool(replication))
  add(path_603504, "Bucket", newJString(Bucket))
  if body != nil:
    body_603506 = body
  result = call_603503.call(path_603504, query_603505, nil, nil, body_603506)

var putBucketReplication* = Call_PutBucketReplication_603493(
    name: "putBucketReplication", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_PutBucketReplication_603494, base: "/",
    url: url_PutBucketReplication_603495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketReplication_603483 = ref object of OpenApiRestCall_602466
proc url_GetBucketReplication_603485(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketReplication_603484(path: JsonNode; query: JsonNode;
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
  var valid_603486 = path.getOrDefault("Bucket")
  valid_603486 = validateParameter(valid_603486, JString, required = true,
                                 default = nil)
  if valid_603486 != nil:
    section.add "Bucket", valid_603486
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_603487 = query.getOrDefault("replication")
  valid_603487 = validateParameter(valid_603487, JBool, required = true, default = nil)
  if valid_603487 != nil:
    section.add "replication", valid_603487
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603488 = header.getOrDefault("x-amz-security-token")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "x-amz-security-token", valid_603488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603489: Call_GetBucketReplication_603483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ## 
  let valid = call_603489.validator(path, query, header, formData, body)
  let scheme = call_603489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603489.url(scheme.get, call_603489.host, call_603489.base,
                         call_603489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603489, url, valid)

proc call*(call_603490: Call_GetBucketReplication_603483; replication: bool;
          Bucket: string): Recallable =
  ## getBucketReplication
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603491 = newJObject()
  var query_603492 = newJObject()
  add(query_603492, "replication", newJBool(replication))
  add(path_603491, "Bucket", newJString(Bucket))
  result = call_603490.call(path_603491, query_603492, nil, nil, nil)

var getBucketReplication* = Call_GetBucketReplication_603483(
    name: "getBucketReplication", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_GetBucketReplication_603484, base: "/",
    url: url_GetBucketReplication_603485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketReplication_603507 = ref object of OpenApiRestCall_602466
proc url_DeleteBucketReplication_603509(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketReplication_603508(path: JsonNode; query: JsonNode;
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
  var valid_603510 = path.getOrDefault("Bucket")
  valid_603510 = validateParameter(valid_603510, JString, required = true,
                                 default = nil)
  if valid_603510 != nil:
    section.add "Bucket", valid_603510
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_603511 = query.getOrDefault("replication")
  valid_603511 = validateParameter(valid_603511, JBool, required = true, default = nil)
  if valid_603511 != nil:
    section.add "replication", valid_603511
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603512 = header.getOrDefault("x-amz-security-token")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "x-amz-security-token", valid_603512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603513: Call_DeleteBucketReplication_603507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_603513.validator(path, query, header, formData, body)
  let scheme = call_603513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603513.url(scheme.get, call_603513.host, call_603513.base,
                         call_603513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603513, url, valid)

proc call*(call_603514: Call_DeleteBucketReplication_603507; replication: bool;
          Bucket: string): Recallable =
  ## deleteBucketReplication
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p> The bucket name. </p> <note> <p>It can take a while to propagate the deletion of a replication configuration to all Amazon S3 systems.</p> </note>
  var path_603515 = newJObject()
  var query_603516 = newJObject()
  add(query_603516, "replication", newJBool(replication))
  add(path_603515, "Bucket", newJString(Bucket))
  result = call_603514.call(path_603515, query_603516, nil, nil, nil)

var deleteBucketReplication* = Call_DeleteBucketReplication_603507(
    name: "deleteBucketReplication", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_DeleteBucketReplication_603508, base: "/",
    url: url_DeleteBucketReplication_603509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketTagging_603527 = ref object of OpenApiRestCall_602466
proc url_PutBucketTagging_603529(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketTagging_603528(path: JsonNode; query: JsonNode;
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
  var valid_603530 = path.getOrDefault("Bucket")
  valid_603530 = validateParameter(valid_603530, JString, required = true,
                                 default = nil)
  if valid_603530 != nil:
    section.add "Bucket", valid_603530
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603531 = query.getOrDefault("tagging")
  valid_603531 = validateParameter(valid_603531, JBool, required = true, default = nil)
  if valid_603531 != nil:
    section.add "tagging", valid_603531
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603532 = header.getOrDefault("x-amz-security-token")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "x-amz-security-token", valid_603532
  var valid_603533 = header.getOrDefault("Content-MD5")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "Content-MD5", valid_603533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603535: Call_PutBucketTagging_603527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the tags for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  let valid = call_603535.validator(path, query, header, formData, body)
  let scheme = call_603535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603535.url(scheme.get, call_603535.host, call_603535.base,
                         call_603535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603535, url, valid)

proc call*(call_603536: Call_PutBucketTagging_603527; tagging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketTagging
  ## Sets the tags for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603537 = newJObject()
  var query_603538 = newJObject()
  var body_603539 = newJObject()
  add(query_603538, "tagging", newJBool(tagging))
  add(path_603537, "Bucket", newJString(Bucket))
  if body != nil:
    body_603539 = body
  result = call_603536.call(path_603537, query_603538, nil, nil, body_603539)

var putBucketTagging* = Call_PutBucketTagging_603527(name: "putBucketTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_PutBucketTagging_603528, base: "/",
    url: url_PutBucketTagging_603529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketTagging_603517 = ref object of OpenApiRestCall_602466
proc url_GetBucketTagging_603519(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketTagging_603518(path: JsonNode; query: JsonNode;
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
  var valid_603520 = path.getOrDefault("Bucket")
  valid_603520 = validateParameter(valid_603520, JString, required = true,
                                 default = nil)
  if valid_603520 != nil:
    section.add "Bucket", valid_603520
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603521 = query.getOrDefault("tagging")
  valid_603521 = validateParameter(valid_603521, JBool, required = true, default = nil)
  if valid_603521 != nil:
    section.add "tagging", valid_603521
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603522 = header.getOrDefault("x-amz-security-token")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "x-amz-security-token", valid_603522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603523: Call_GetBucketTagging_603517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag set associated with the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  let valid = call_603523.validator(path, query, header, formData, body)
  let scheme = call_603523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603523.url(scheme.get, call_603523.host, call_603523.base,
                         call_603523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603523, url, valid)

proc call*(call_603524: Call_GetBucketTagging_603517; tagging: bool; Bucket: string): Recallable =
  ## getBucketTagging
  ## Returns the tag set associated with the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603525 = newJObject()
  var query_603526 = newJObject()
  add(query_603526, "tagging", newJBool(tagging))
  add(path_603525, "Bucket", newJString(Bucket))
  result = call_603524.call(path_603525, query_603526, nil, nil, nil)

var getBucketTagging* = Call_GetBucketTagging_603517(name: "getBucketTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_GetBucketTagging_603518, base: "/",
    url: url_GetBucketTagging_603519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketTagging_603540 = ref object of OpenApiRestCall_602466
proc url_DeleteBucketTagging_603542(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketTagging_603541(path: JsonNode; query: JsonNode;
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
  var valid_603543 = path.getOrDefault("Bucket")
  valid_603543 = validateParameter(valid_603543, JString, required = true,
                                 default = nil)
  if valid_603543 != nil:
    section.add "Bucket", valid_603543
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603544 = query.getOrDefault("tagging")
  valid_603544 = validateParameter(valid_603544, JBool, required = true, default = nil)
  if valid_603544 != nil:
    section.add "tagging", valid_603544
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603545 = header.getOrDefault("x-amz-security-token")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "x-amz-security-token", valid_603545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603546: Call_DeleteBucketTagging_603540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the tags from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  let valid = call_603546.validator(path, query, header, formData, body)
  let scheme = call_603546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603546.url(scheme.get, call_603546.host, call_603546.base,
                         call_603546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603546, url, valid)

proc call*(call_603547: Call_DeleteBucketTagging_603540; tagging: bool;
          Bucket: string): Recallable =
  ## deleteBucketTagging
  ## Deletes the tags from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603548 = newJObject()
  var query_603549 = newJObject()
  add(query_603549, "tagging", newJBool(tagging))
  add(path_603548, "Bucket", newJString(Bucket))
  result = call_603547.call(path_603548, query_603549, nil, nil, nil)

var deleteBucketTagging* = Call_DeleteBucketTagging_603540(
    name: "deleteBucketTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_DeleteBucketTagging_603541, base: "/",
    url: url_DeleteBucketTagging_603542, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketWebsite_603560 = ref object of OpenApiRestCall_602466
proc url_PutBucketWebsite_603562(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketWebsite_603561(path: JsonNode; query: JsonNode;
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
  var valid_603563 = path.getOrDefault("Bucket")
  valid_603563 = validateParameter(valid_603563, JString, required = true,
                                 default = nil)
  if valid_603563 != nil:
    section.add "Bucket", valid_603563
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_603564 = query.getOrDefault("website")
  valid_603564 = validateParameter(valid_603564, JBool, required = true, default = nil)
  if valid_603564 != nil:
    section.add "website", valid_603564
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603565 = header.getOrDefault("x-amz-security-token")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "x-amz-security-token", valid_603565
  var valid_603566 = header.getOrDefault("Content-MD5")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "Content-MD5", valid_603566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603568: Call_PutBucketWebsite_603560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  let valid = call_603568.validator(path, query, header, formData, body)
  let scheme = call_603568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603568.url(scheme.get, call_603568.host, call_603568.base,
                         call_603568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603568, url, valid)

proc call*(call_603569: Call_PutBucketWebsite_603560; website: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketWebsite
  ## Set the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603570 = newJObject()
  var query_603571 = newJObject()
  var body_603572 = newJObject()
  add(query_603571, "website", newJBool(website))
  add(path_603570, "Bucket", newJString(Bucket))
  if body != nil:
    body_603572 = body
  result = call_603569.call(path_603570, query_603571, nil, nil, body_603572)

var putBucketWebsite* = Call_PutBucketWebsite_603560(name: "putBucketWebsite",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_PutBucketWebsite_603561, base: "/",
    url: url_PutBucketWebsite_603562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketWebsite_603550 = ref object of OpenApiRestCall_602466
proc url_GetBucketWebsite_603552(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketWebsite_603551(path: JsonNode; query: JsonNode;
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
  var valid_603553 = path.getOrDefault("Bucket")
  valid_603553 = validateParameter(valid_603553, JString, required = true,
                                 default = nil)
  if valid_603553 != nil:
    section.add "Bucket", valid_603553
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_603554 = query.getOrDefault("website")
  valid_603554 = validateParameter(valid_603554, JBool, required = true, default = nil)
  if valid_603554 != nil:
    section.add "website", valid_603554
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603555 = header.getOrDefault("x-amz-security-token")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "x-amz-security-token", valid_603555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603556: Call_GetBucketWebsite_603550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  let valid = call_603556.validator(path, query, header, formData, body)
  let scheme = call_603556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603556.url(scheme.get, call_603556.host, call_603556.base,
                         call_603556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603556, url, valid)

proc call*(call_603557: Call_GetBucketWebsite_603550; website: bool; Bucket: string): Recallable =
  ## getBucketWebsite
  ## Returns the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603558 = newJObject()
  var query_603559 = newJObject()
  add(query_603559, "website", newJBool(website))
  add(path_603558, "Bucket", newJString(Bucket))
  result = call_603557.call(path_603558, query_603559, nil, nil, nil)

var getBucketWebsite* = Call_GetBucketWebsite_603550(name: "getBucketWebsite",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_GetBucketWebsite_603551, base: "/",
    url: url_GetBucketWebsite_603552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketWebsite_603573 = ref object of OpenApiRestCall_602466
proc url_DeleteBucketWebsite_603575(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketWebsite_603574(path: JsonNode; query: JsonNode;
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
  var valid_603576 = path.getOrDefault("Bucket")
  valid_603576 = validateParameter(valid_603576, JString, required = true,
                                 default = nil)
  if valid_603576 != nil:
    section.add "Bucket", valid_603576
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_603577 = query.getOrDefault("website")
  valid_603577 = validateParameter(valid_603577, JBool, required = true, default = nil)
  if valid_603577 != nil:
    section.add "website", valid_603577
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603578 = header.getOrDefault("x-amz-security-token")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "x-amz-security-token", valid_603578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603579: Call_DeleteBucketWebsite_603573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes the website configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  let valid = call_603579.validator(path, query, header, formData, body)
  let scheme = call_603579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603579.url(scheme.get, call_603579.host, call_603579.base,
                         call_603579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603579, url, valid)

proc call*(call_603580: Call_DeleteBucketWebsite_603573; website: bool;
          Bucket: string): Recallable =
  ## deleteBucketWebsite
  ## This operation removes the website configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603581 = newJObject()
  var query_603582 = newJObject()
  add(query_603582, "website", newJBool(website))
  add(path_603581, "Bucket", newJString(Bucket))
  result = call_603580.call(path_603581, query_603582, nil, nil, nil)

var deleteBucketWebsite* = Call_DeleteBucketWebsite_603573(
    name: "deleteBucketWebsite", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_DeleteBucketWebsite_603574, base: "/",
    url: url_DeleteBucketWebsite_603575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObject_603610 = ref object of OpenApiRestCall_602466
proc url_PutObject_603612(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutObject_603611(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603613 = path.getOrDefault("Key")
  valid_603613 = validateParameter(valid_603613, JString, required = true,
                                 default = nil)
  if valid_603613 != nil:
    section.add "Key", valid_603613
  var valid_603614 = path.getOrDefault("Bucket")
  valid_603614 = validateParameter(valid_603614, JString, required = true,
                                 default = nil)
  if valid_603614 != nil:
    section.add "Bucket", valid_603614
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
  var valid_603615 = header.getOrDefault("Content-Disposition")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "Content-Disposition", valid_603615
  var valid_603616 = header.getOrDefault("x-amz-grant-full-control")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "x-amz-grant-full-control", valid_603616
  var valid_603617 = header.getOrDefault("x-amz-security-token")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "x-amz-security-token", valid_603617
  var valid_603618 = header.getOrDefault("Content-MD5")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "Content-MD5", valid_603618
  var valid_603619 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_603619
  var valid_603620 = header.getOrDefault("x-amz-object-lock-mode")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_603620 != nil:
    section.add "x-amz-object-lock-mode", valid_603620
  var valid_603621 = header.getOrDefault("Cache-Control")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "Cache-Control", valid_603621
  var valid_603622 = header.getOrDefault("Content-Language")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "Content-Language", valid_603622
  var valid_603623 = header.getOrDefault("Content-Type")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "Content-Type", valid_603623
  var valid_603624 = header.getOrDefault("Expires")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "Expires", valid_603624
  var valid_603625 = header.getOrDefault("x-amz-website-redirect-location")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "x-amz-website-redirect-location", valid_603625
  var valid_603626 = header.getOrDefault("x-amz-acl")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = newJString("private"))
  if valid_603626 != nil:
    section.add "x-amz-acl", valid_603626
  var valid_603627 = header.getOrDefault("x-amz-grant-read")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "x-amz-grant-read", valid_603627
  var valid_603628 = header.getOrDefault("x-amz-storage-class")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_603628 != nil:
    section.add "x-amz-storage-class", valid_603628
  var valid_603629 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = newJString("ON"))
  if valid_603629 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_603629
  var valid_603630 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_603630
  var valid_603631 = header.getOrDefault("x-amz-tagging")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "x-amz-tagging", valid_603631
  var valid_603632 = header.getOrDefault("x-amz-grant-read-acp")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "x-amz-grant-read-acp", valid_603632
  var valid_603633 = header.getOrDefault("Content-Length")
  valid_603633 = validateParameter(valid_603633, JInt, required = false, default = nil)
  if valid_603633 != nil:
    section.add "Content-Length", valid_603633
  var valid_603634 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "x-amz-server-side-encryption-context", valid_603634
  var valid_603635 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_603635
  var valid_603636 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_603636
  var valid_603637 = header.getOrDefault("x-amz-grant-write-acp")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "x-amz-grant-write-acp", valid_603637
  var valid_603638 = header.getOrDefault("Content-Encoding")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "Content-Encoding", valid_603638
  var valid_603639 = header.getOrDefault("x-amz-request-payer")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = newJString("requester"))
  if valid_603639 != nil:
    section.add "x-amz-request-payer", valid_603639
  var valid_603640 = header.getOrDefault("x-amz-server-side-encryption")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = newJString("AES256"))
  if valid_603640 != nil:
    section.add "x-amz-server-side-encryption", valid_603640
  var valid_603641 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_603641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603643: Call_PutObject_603610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an object to a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  let valid = call_603643.validator(path, query, header, formData, body)
  let scheme = call_603643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603643.url(scheme.get, call_603643.host, call_603643.base,
                         call_603643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603643, url, valid)

proc call*(call_603644: Call_PutObject_603610; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## putObject
  ## Adds an object to a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  ##   Key: string (required)
  ##      : Object key for which the PUT operation was initiated.
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the PUT operation was initiated.
  ##   body: JObject (required)
  var path_603645 = newJObject()
  var body_603646 = newJObject()
  add(path_603645, "Key", newJString(Key))
  add(path_603645, "Bucket", newJString(Bucket))
  if body != nil:
    body_603646 = body
  result = call_603644.call(path_603645, nil, nil, nil, body_603646)

var putObject* = Call_PutObject_603610(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_PutObject_603611,
                                    base: "/", url: url_PutObject_603612,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadObject_603661 = ref object of OpenApiRestCall_602466
proc url_HeadObject_603663(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_HeadObject_603662(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603664 = path.getOrDefault("Key")
  valid_603664 = validateParameter(valid_603664, JString, required = true,
                                 default = nil)
  if valid_603664 != nil:
    section.add "Key", valid_603664
  var valid_603665 = path.getOrDefault("Bucket")
  valid_603665 = validateParameter(valid_603665, JString, required = true,
                                 default = nil)
  if valid_603665 != nil:
    section.add "Bucket", valid_603665
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   partNumber: JInt
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
  section = newJObject()
  var valid_603666 = query.getOrDefault("versionId")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "versionId", valid_603666
  var valid_603667 = query.getOrDefault("partNumber")
  valid_603667 = validateParameter(valid_603667, JInt, required = false, default = nil)
  if valid_603667 != nil:
    section.add "partNumber", valid_603667
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
  var valid_603668 = header.getOrDefault("x-amz-security-token")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "x-amz-security-token", valid_603668
  var valid_603669 = header.getOrDefault("If-Match")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "If-Match", valid_603669
  var valid_603670 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_603670
  var valid_603671 = header.getOrDefault("If-Unmodified-Since")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "If-Unmodified-Since", valid_603671
  var valid_603672 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_603672
  var valid_603673 = header.getOrDefault("If-Modified-Since")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "If-Modified-Since", valid_603673
  var valid_603674 = header.getOrDefault("If-None-Match")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "If-None-Match", valid_603674
  var valid_603675 = header.getOrDefault("x-amz-request-payer")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = newJString("requester"))
  if valid_603675 != nil:
    section.add "x-amz-request-payer", valid_603675
  var valid_603676 = header.getOrDefault("Range")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "Range", valid_603676
  var valid_603677 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_603677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603678: Call_HeadObject_603661; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  let valid = call_603678.validator(path, query, header, formData, body)
  let scheme = call_603678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603678.url(scheme.get, call_603678.host, call_603678.base,
                         call_603678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603678, url, valid)

proc call*(call_603679: Call_HeadObject_603661; Key: string; Bucket: string;
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
  var path_603680 = newJObject()
  var query_603681 = newJObject()
  add(query_603681, "versionId", newJString(versionId))
  add(query_603681, "partNumber", newJInt(partNumber))
  add(path_603680, "Key", newJString(Key))
  add(path_603680, "Bucket", newJString(Bucket))
  result = call_603679.call(path_603680, query_603681, nil, nil, nil)

var headObject* = Call_HeadObject_603661(name: "headObject",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}/{Key}",
                                      validator: validate_HeadObject_603662,
                                      base: "/", url: url_HeadObject_603663,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_603583 = ref object of OpenApiRestCall_602466
proc url_GetObject_603585(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetObject_603584(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603586 = path.getOrDefault("Key")
  valid_603586 = validateParameter(valid_603586, JString, required = true,
                                 default = nil)
  if valid_603586 != nil:
    section.add "Key", valid_603586
  var valid_603587 = path.getOrDefault("Bucket")
  valid_603587 = validateParameter(valid_603587, JString, required = true,
                                 default = nil)
  if valid_603587 != nil:
    section.add "Bucket", valid_603587
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
  var valid_603588 = query.getOrDefault("versionId")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "versionId", valid_603588
  var valid_603589 = query.getOrDefault("partNumber")
  valid_603589 = validateParameter(valid_603589, JInt, required = false, default = nil)
  if valid_603589 != nil:
    section.add "partNumber", valid_603589
  var valid_603590 = query.getOrDefault("response-expires")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "response-expires", valid_603590
  var valid_603591 = query.getOrDefault("response-content-language")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "response-content-language", valid_603591
  var valid_603592 = query.getOrDefault("response-content-encoding")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "response-content-encoding", valid_603592
  var valid_603593 = query.getOrDefault("response-cache-control")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "response-cache-control", valid_603593
  var valid_603594 = query.getOrDefault("response-content-disposition")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "response-content-disposition", valid_603594
  var valid_603595 = query.getOrDefault("response-content-type")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "response-content-type", valid_603595
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
  var valid_603596 = header.getOrDefault("x-amz-security-token")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "x-amz-security-token", valid_603596
  var valid_603597 = header.getOrDefault("If-Match")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "If-Match", valid_603597
  var valid_603598 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_603598
  var valid_603599 = header.getOrDefault("If-Unmodified-Since")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "If-Unmodified-Since", valid_603599
  var valid_603600 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_603600
  var valid_603601 = header.getOrDefault("If-Modified-Since")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "If-Modified-Since", valid_603601
  var valid_603602 = header.getOrDefault("If-None-Match")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "If-None-Match", valid_603602
  var valid_603603 = header.getOrDefault("x-amz-request-payer")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = newJString("requester"))
  if valid_603603 != nil:
    section.add "x-amz-request-payer", valid_603603
  var valid_603604 = header.getOrDefault("Range")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "Range", valid_603604
  var valid_603605 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_603605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603606: Call_GetObject_603583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves objects from Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  let valid = call_603606.validator(path, query, header, formData, body)
  let scheme = call_603606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603606.url(scheme.get, call_603606.host, call_603606.base,
                         call_603606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603606, url, valid)

proc call*(call_603607: Call_GetObject_603583; Key: string; Bucket: string;
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
  var path_603608 = newJObject()
  var query_603609 = newJObject()
  add(query_603609, "versionId", newJString(versionId))
  add(query_603609, "partNumber", newJInt(partNumber))
  add(query_603609, "response-expires", newJString(responseExpires))
  add(query_603609, "response-content-language",
      newJString(responseContentLanguage))
  add(path_603608, "Key", newJString(Key))
  add(query_603609, "response-content-encoding",
      newJString(responseContentEncoding))
  add(query_603609, "response-cache-control", newJString(responseCacheControl))
  add(path_603608, "Bucket", newJString(Bucket))
  add(query_603609, "response-content-disposition",
      newJString(responseContentDisposition))
  add(query_603609, "response-content-type", newJString(responseContentType))
  result = call_603607.call(path_603608, query_603609, nil, nil, nil)

var getObject* = Call_GetObject_603583(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_GetObject_603584,
                                    base: "/", url: url_GetObject_603585,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_603647 = ref object of OpenApiRestCall_602466
proc url_DeleteObject_603649(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObject_603648(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603650 = path.getOrDefault("Key")
  valid_603650 = validateParameter(valid_603650, JString, required = true,
                                 default = nil)
  if valid_603650 != nil:
    section.add "Key", valid_603650
  var valid_603651 = path.getOrDefault("Bucket")
  valid_603651 = validateParameter(valid_603651, JString, required = true,
                                 default = nil)
  if valid_603651 != nil:
    section.add "Bucket", valid_603651
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  var valid_603652 = query.getOrDefault("versionId")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "versionId", valid_603652
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
  var valid_603653 = header.getOrDefault("x-amz-security-token")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "x-amz-security-token", valid_603653
  var valid_603654 = header.getOrDefault("x-amz-mfa")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "x-amz-mfa", valid_603654
  var valid_603655 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_603655 = validateParameter(valid_603655, JBool, required = false, default = nil)
  if valid_603655 != nil:
    section.add "x-amz-bypass-governance-retention", valid_603655
  var valid_603656 = header.getOrDefault("x-amz-request-payer")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = newJString("requester"))
  if valid_603656 != nil:
    section.add "x-amz-request-payer", valid_603656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603657: Call_DeleteObject_603647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  let valid = call_603657.validator(path, query, header, formData, body)
  let scheme = call_603657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603657.url(scheme.get, call_603657.host, call_603657.base,
                         call_603657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603657, url, valid)

proc call*(call_603658: Call_DeleteObject_603647; Key: string; Bucket: string;
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
  var path_603659 = newJObject()
  var query_603660 = newJObject()
  add(query_603660, "versionId", newJString(versionId))
  add(path_603659, "Key", newJString(Key))
  add(path_603659, "Bucket", newJString(Bucket))
  result = call_603658.call(path_603659, query_603660, nil, nil, nil)

var deleteObject* = Call_DeleteObject_603647(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}/{Key}",
    validator: validate_DeleteObject_603648, base: "/", url: url_DeleteObject_603649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectTagging_603694 = ref object of OpenApiRestCall_602466
proc url_PutObjectTagging_603696(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectTagging_603695(path: JsonNode; query: JsonNode;
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
  var valid_603697 = path.getOrDefault("Key")
  valid_603697 = validateParameter(valid_603697, JString, required = true,
                                 default = nil)
  if valid_603697 != nil:
    section.add "Key", valid_603697
  var valid_603698 = path.getOrDefault("Bucket")
  valid_603698 = validateParameter(valid_603698, JString, required = true,
                                 default = nil)
  if valid_603698 != nil:
    section.add "Bucket", valid_603698
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_603699 = query.getOrDefault("versionId")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "versionId", valid_603699
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603700 = query.getOrDefault("tagging")
  valid_603700 = validateParameter(valid_603700, JBool, required = true, default = nil)
  if valid_603700 != nil:
    section.add "tagging", valid_603700
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603701 = header.getOrDefault("x-amz-security-token")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "x-amz-security-token", valid_603701
  var valid_603702 = header.getOrDefault("Content-MD5")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "Content-MD5", valid_603702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603704: Call_PutObjectTagging_603694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ## 
  let valid = call_603704.validator(path, query, header, formData, body)
  let scheme = call_603704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603704.url(scheme.get, call_603704.host, call_603704.base,
                         call_603704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603704, url, valid)

proc call*(call_603705: Call_PutObjectTagging_603694; tagging: bool; Key: string;
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
  var path_603706 = newJObject()
  var query_603707 = newJObject()
  var body_603708 = newJObject()
  add(query_603707, "versionId", newJString(versionId))
  add(query_603707, "tagging", newJBool(tagging))
  add(path_603706, "Key", newJString(Key))
  add(path_603706, "Bucket", newJString(Bucket))
  if body != nil:
    body_603708 = body
  result = call_603705.call(path_603706, query_603707, nil, nil, body_603708)

var putObjectTagging* = Call_PutObjectTagging_603694(name: "putObjectTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_PutObjectTagging_603695,
    base: "/", url: url_PutObjectTagging_603696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTagging_603682 = ref object of OpenApiRestCall_602466
proc url_GetObjectTagging_603684(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectTagging_603683(path: JsonNode; query: JsonNode;
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
  var valid_603685 = path.getOrDefault("Key")
  valid_603685 = validateParameter(valid_603685, JString, required = true,
                                 default = nil)
  if valid_603685 != nil:
    section.add "Key", valid_603685
  var valid_603686 = path.getOrDefault("Bucket")
  valid_603686 = validateParameter(valid_603686, JString, required = true,
                                 default = nil)
  if valid_603686 != nil:
    section.add "Bucket", valid_603686
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_603687 = query.getOrDefault("versionId")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "versionId", valid_603687
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603688 = query.getOrDefault("tagging")
  valid_603688 = validateParameter(valid_603688, JBool, required = true, default = nil)
  if valid_603688 != nil:
    section.add "tagging", valid_603688
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603689 = header.getOrDefault("x-amz-security-token")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "x-amz-security-token", valid_603689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603690: Call_GetObjectTagging_603682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag-set of an object.
  ## 
  let valid = call_603690.validator(path, query, header, formData, body)
  let scheme = call_603690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603690.url(scheme.get, call_603690.host, call_603690.base,
                         call_603690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603690, url, valid)

proc call*(call_603691: Call_GetObjectTagging_603682; tagging: bool; Key: string;
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
  var path_603692 = newJObject()
  var query_603693 = newJObject()
  add(query_603693, "versionId", newJString(versionId))
  add(query_603693, "tagging", newJBool(tagging))
  add(path_603692, "Key", newJString(Key))
  add(path_603692, "Bucket", newJString(Bucket))
  result = call_603691.call(path_603692, query_603693, nil, nil, nil)

var getObjectTagging* = Call_GetObjectTagging_603682(name: "getObjectTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_GetObjectTagging_603683,
    base: "/", url: url_GetObjectTagging_603684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjectTagging_603709 = ref object of OpenApiRestCall_602466
proc url_DeleteObjectTagging_603711(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObjectTagging_603710(path: JsonNode; query: JsonNode;
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
  var valid_603712 = path.getOrDefault("Key")
  valid_603712 = validateParameter(valid_603712, JString, required = true,
                                 default = nil)
  if valid_603712 != nil:
    section.add "Key", valid_603712
  var valid_603713 = path.getOrDefault("Bucket")
  valid_603713 = validateParameter(valid_603713, JString, required = true,
                                 default = nil)
  if valid_603713 != nil:
    section.add "Bucket", valid_603713
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The versionId of the object that the tag-set will be removed from.
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_603714 = query.getOrDefault("versionId")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "versionId", valid_603714
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603715 = query.getOrDefault("tagging")
  valid_603715 = validateParameter(valid_603715, JBool, required = true, default = nil)
  if valid_603715 != nil:
    section.add "tagging", valid_603715
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603716 = header.getOrDefault("x-amz-security-token")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "x-amz-security-token", valid_603716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603717: Call_DeleteObjectTagging_603709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the tag-set from an existing object.
  ## 
  let valid = call_603717.validator(path, query, header, formData, body)
  let scheme = call_603717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603717.url(scheme.get, call_603717.host, call_603717.base,
                         call_603717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603717, url, valid)

proc call*(call_603718: Call_DeleteObjectTagging_603709; tagging: bool; Key: string;
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
  var path_603719 = newJObject()
  var query_603720 = newJObject()
  add(query_603720, "versionId", newJString(versionId))
  add(query_603720, "tagging", newJBool(tagging))
  add(path_603719, "Key", newJString(Key))
  add(path_603719, "Bucket", newJString(Bucket))
  result = call_603718.call(path_603719, query_603720, nil, nil, nil)

var deleteObjectTagging* = Call_DeleteObjectTagging_603709(
    name: "deleteObjectTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#tagging",
    validator: validate_DeleteObjectTagging_603710, base: "/",
    url: url_DeleteObjectTagging_603711, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjects_603721 = ref object of OpenApiRestCall_602466
proc url_DeleteObjects_603723(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObjects_603722(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603724 = path.getOrDefault("Bucket")
  valid_603724 = validateParameter(valid_603724, JString, required = true,
                                 default = nil)
  if valid_603724 != nil:
    section.add "Bucket", valid_603724
  result.add "path", section
  ## parameters in `query` object:
  ##   delete: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `delete` field"
  var valid_603725 = query.getOrDefault("delete")
  valid_603725 = validateParameter(valid_603725, JBool, required = true, default = nil)
  if valid_603725 != nil:
    section.add "delete", valid_603725
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
  var valid_603726 = header.getOrDefault("x-amz-security-token")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "x-amz-security-token", valid_603726
  var valid_603727 = header.getOrDefault("x-amz-mfa")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "x-amz-mfa", valid_603727
  var valid_603728 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_603728 = validateParameter(valid_603728, JBool, required = false, default = nil)
  if valid_603728 != nil:
    section.add "x-amz-bypass-governance-retention", valid_603728
  var valid_603729 = header.getOrDefault("x-amz-request-payer")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = newJString("requester"))
  if valid_603729 != nil:
    section.add "x-amz-request-payer", valid_603729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603731: Call_DeleteObjects_603721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  let valid = call_603731.validator(path, query, header, formData, body)
  let scheme = call_603731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603731.url(scheme.get, call_603731.host, call_603731.base,
                         call_603731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603731, url, valid)

proc call*(call_603732: Call_DeleteObjects_603721; Bucket: string; body: JsonNode;
          delete: bool): Recallable =
  ## deleteObjects
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   delete: bool (required)
  var path_603733 = newJObject()
  var query_603734 = newJObject()
  var body_603735 = newJObject()
  add(path_603733, "Bucket", newJString(Bucket))
  if body != nil:
    body_603735 = body
  add(query_603734, "delete", newJBool(delete))
  result = call_603732.call(path_603733, query_603734, nil, nil, body_603735)

var deleteObjects* = Call_DeleteObjects_603721(name: "deleteObjects",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com", route: "/{Bucket}#delete",
    validator: validate_DeleteObjects_603722, base: "/", url: url_DeleteObjects_603723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_603746 = ref object of OpenApiRestCall_602466
proc url_PutPublicAccessBlock_603748(protocol: Scheme; host: string; base: string;
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

proc validate_PutPublicAccessBlock_603747(path: JsonNode; query: JsonNode;
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
  var valid_603749 = path.getOrDefault("Bucket")
  valid_603749 = validateParameter(valid_603749, JString, required = true,
                                 default = nil)
  if valid_603749 != nil:
    section.add "Bucket", valid_603749
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_603750 = query.getOrDefault("publicAccessBlock")
  valid_603750 = validateParameter(valid_603750, JBool, required = true, default = nil)
  if valid_603750 != nil:
    section.add "publicAccessBlock", valid_603750
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash of the <code>PutPublicAccessBlock</code> request body. 
  section = newJObject()
  var valid_603751 = header.getOrDefault("x-amz-security-token")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "x-amz-security-token", valid_603751
  var valid_603752 = header.getOrDefault("Content-MD5")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "Content-MD5", valid_603752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603754: Call_PutPublicAccessBlock_603746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_603754.validator(path, query, header, formData, body)
  let scheme = call_603754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603754.url(scheme.get, call_603754.host, call_603754.base,
                         call_603754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603754, url, valid)

proc call*(call_603755: Call_PutPublicAccessBlock_603746; publicAccessBlock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to set.
  ##   body: JObject (required)
  var path_603756 = newJObject()
  var query_603757 = newJObject()
  var body_603758 = newJObject()
  add(query_603757, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_603756, "Bucket", newJString(Bucket))
  if body != nil:
    body_603758 = body
  result = call_603755.call(path_603756, query_603757, nil, nil, body_603758)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_603746(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_PutPublicAccessBlock_603747, base: "/",
    url: url_PutPublicAccessBlock_603748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_603736 = ref object of OpenApiRestCall_602466
proc url_GetPublicAccessBlock_603738(protocol: Scheme; host: string; base: string;
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

proc validate_GetPublicAccessBlock_603737(path: JsonNode; query: JsonNode;
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
  var valid_603739 = path.getOrDefault("Bucket")
  valid_603739 = validateParameter(valid_603739, JString, required = true,
                                 default = nil)
  if valid_603739 != nil:
    section.add "Bucket", valid_603739
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_603740 = query.getOrDefault("publicAccessBlock")
  valid_603740 = validateParameter(valid_603740, JBool, required = true, default = nil)
  if valid_603740 != nil:
    section.add "publicAccessBlock", valid_603740
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603741 = header.getOrDefault("x-amz-security-token")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "x-amz-security-token", valid_603741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603742: Call_GetPublicAccessBlock_603736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_603742.validator(path, query, header, formData, body)
  let scheme = call_603742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603742.url(scheme.get, call_603742.host, call_603742.base,
                         call_603742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603742, url, valid)

proc call*(call_603743: Call_GetPublicAccessBlock_603736; publicAccessBlock: bool;
          Bucket: string): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to retrieve. 
  var path_603744 = newJObject()
  var query_603745 = newJObject()
  add(query_603745, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_603744, "Bucket", newJString(Bucket))
  result = call_603743.call(path_603744, query_603745, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_603736(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_GetPublicAccessBlock_603737, base: "/",
    url: url_GetPublicAccessBlock_603738, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_603759 = ref object of OpenApiRestCall_602466
proc url_DeletePublicAccessBlock_603761(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePublicAccessBlock_603760(path: JsonNode; query: JsonNode;
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
  var valid_603762 = path.getOrDefault("Bucket")
  valid_603762 = validateParameter(valid_603762, JString, required = true,
                                 default = nil)
  if valid_603762 != nil:
    section.add "Bucket", valid_603762
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_603763 = query.getOrDefault("publicAccessBlock")
  valid_603763 = validateParameter(valid_603763, JBool, required = true, default = nil)
  if valid_603763 != nil:
    section.add "publicAccessBlock", valid_603763
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603764 = header.getOrDefault("x-amz-security-token")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "x-amz-security-token", valid_603764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603765: Call_DeletePublicAccessBlock_603759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ## 
  let valid = call_603765.validator(path, query, header, formData, body)
  let scheme = call_603765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603765.url(scheme.get, call_603765.host, call_603765.base,
                         call_603765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603765, url, valid)

proc call*(call_603766: Call_DeletePublicAccessBlock_603759;
          publicAccessBlock: bool; Bucket: string): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to delete. 
  var path_603767 = newJObject()
  var query_603768 = newJObject()
  add(query_603768, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_603767, "Bucket", newJString(Bucket))
  result = call_603766.call(path_603767, query_603768, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_603759(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_DeletePublicAccessBlock_603760, base: "/",
    url: url_DeletePublicAccessBlock_603761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAccelerateConfiguration_603779 = ref object of OpenApiRestCall_602466
proc url_PutBucketAccelerateConfiguration_603781(protocol: Scheme; host: string;
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

proc validate_PutBucketAccelerateConfiguration_603780(path: JsonNode;
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
  var valid_603782 = path.getOrDefault("Bucket")
  valid_603782 = validateParameter(valid_603782, JString, required = true,
                                 default = nil)
  if valid_603782 != nil:
    section.add "Bucket", valid_603782
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_603783 = query.getOrDefault("accelerate")
  valid_603783 = validateParameter(valid_603783, JBool, required = true, default = nil)
  if valid_603783 != nil:
    section.add "accelerate", valid_603783
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603784 = header.getOrDefault("x-amz-security-token")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "x-amz-security-token", valid_603784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603786: Call_PutBucketAccelerateConfiguration_603779;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the accelerate configuration of an existing bucket.
  ## 
  let valid = call_603786.validator(path, query, header, formData, body)
  let scheme = call_603786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603786.url(scheme.get, call_603786.host, call_603786.base,
                         call_603786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603786, url, valid)

proc call*(call_603787: Call_PutBucketAccelerateConfiguration_603779;
          accelerate: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAccelerateConfiguration
  ## Sets the accelerate configuration of an existing bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is set.
  ##   body: JObject (required)
  var path_603788 = newJObject()
  var query_603789 = newJObject()
  var body_603790 = newJObject()
  add(query_603789, "accelerate", newJBool(accelerate))
  add(path_603788, "Bucket", newJString(Bucket))
  if body != nil:
    body_603790 = body
  result = call_603787.call(path_603788, query_603789, nil, nil, body_603790)

var putBucketAccelerateConfiguration* = Call_PutBucketAccelerateConfiguration_603779(
    name: "putBucketAccelerateConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_PutBucketAccelerateConfiguration_603780, base: "/",
    url: url_PutBucketAccelerateConfiguration_603781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAccelerateConfiguration_603769 = ref object of OpenApiRestCall_602466
proc url_GetBucketAccelerateConfiguration_603771(protocol: Scheme; host: string;
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

proc validate_GetBucketAccelerateConfiguration_603770(path: JsonNode;
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
  var valid_603772 = path.getOrDefault("Bucket")
  valid_603772 = validateParameter(valid_603772, JString, required = true,
                                 default = nil)
  if valid_603772 != nil:
    section.add "Bucket", valid_603772
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_603773 = query.getOrDefault("accelerate")
  valid_603773 = validateParameter(valid_603773, JBool, required = true, default = nil)
  if valid_603773 != nil:
    section.add "accelerate", valid_603773
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603774 = header.getOrDefault("x-amz-security-token")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "x-amz-security-token", valid_603774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603775: Call_GetBucketAccelerateConfiguration_603769;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the accelerate configuration of a bucket.
  ## 
  let valid = call_603775.validator(path, query, header, formData, body)
  let scheme = call_603775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603775.url(scheme.get, call_603775.host, call_603775.base,
                         call_603775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603775, url, valid)

proc call*(call_603776: Call_GetBucketAccelerateConfiguration_603769;
          accelerate: bool; Bucket: string): Recallable =
  ## getBucketAccelerateConfiguration
  ## Returns the accelerate configuration of a bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is retrieved.
  var path_603777 = newJObject()
  var query_603778 = newJObject()
  add(query_603778, "accelerate", newJBool(accelerate))
  add(path_603777, "Bucket", newJString(Bucket))
  result = call_603776.call(path_603777, query_603778, nil, nil, nil)

var getBucketAccelerateConfiguration* = Call_GetBucketAccelerateConfiguration_603769(
    name: "getBucketAccelerateConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_GetBucketAccelerateConfiguration_603770, base: "/",
    url: url_GetBucketAccelerateConfiguration_603771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAcl_603801 = ref object of OpenApiRestCall_602466
proc url_PutBucketAcl_603803(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketAcl_603802(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603804 = path.getOrDefault("Bucket")
  valid_603804 = validateParameter(valid_603804, JString, required = true,
                                 default = nil)
  if valid_603804 != nil:
    section.add "Bucket", valid_603804
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_603805 = query.getOrDefault("acl")
  valid_603805 = validateParameter(valid_603805, JBool, required = true, default = nil)
  if valid_603805 != nil:
    section.add "acl", valid_603805
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
  var valid_603806 = header.getOrDefault("x-amz-security-token")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "x-amz-security-token", valid_603806
  var valid_603807 = header.getOrDefault("Content-MD5")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "Content-MD5", valid_603807
  var valid_603808 = header.getOrDefault("x-amz-acl")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = newJString("private"))
  if valid_603808 != nil:
    section.add "x-amz-acl", valid_603808
  var valid_603809 = header.getOrDefault("x-amz-grant-read")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "x-amz-grant-read", valid_603809
  var valid_603810 = header.getOrDefault("x-amz-grant-read-acp")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "x-amz-grant-read-acp", valid_603810
  var valid_603811 = header.getOrDefault("x-amz-grant-write")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "x-amz-grant-write", valid_603811
  var valid_603812 = header.getOrDefault("x-amz-grant-write-acp")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "x-amz-grant-write-acp", valid_603812
  var valid_603813 = header.getOrDefault("x-amz-grant-full-control")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "x-amz-grant-full-control", valid_603813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603815: Call_PutBucketAcl_603801; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  let valid = call_603815.validator(path, query, header, formData, body)
  let scheme = call_603815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603815.url(scheme.get, call_603815.host, call_603815.base,
                         call_603815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603815, url, valid)

proc call*(call_603816: Call_PutBucketAcl_603801; acl: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketAcl
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603817 = newJObject()
  var query_603818 = newJObject()
  var body_603819 = newJObject()
  add(query_603818, "acl", newJBool(acl))
  add(path_603817, "Bucket", newJString(Bucket))
  if body != nil:
    body_603819 = body
  result = call_603816.call(path_603817, query_603818, nil, nil, body_603819)

var putBucketAcl* = Call_PutBucketAcl_603801(name: "putBucketAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_PutBucketAcl_603802, base: "/", url: url_PutBucketAcl_603803,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAcl_603791 = ref object of OpenApiRestCall_602466
proc url_GetBucketAcl_603793(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketAcl_603792(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603794 = path.getOrDefault("Bucket")
  valid_603794 = validateParameter(valid_603794, JString, required = true,
                                 default = nil)
  if valid_603794 != nil:
    section.add "Bucket", valid_603794
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_603795 = query.getOrDefault("acl")
  valid_603795 = validateParameter(valid_603795, JBool, required = true, default = nil)
  if valid_603795 != nil:
    section.add "acl", valid_603795
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603796 = header.getOrDefault("x-amz-security-token")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "x-amz-security-token", valid_603796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603797: Call_GetBucketAcl_603791; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the access control policy for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  let valid = call_603797.validator(path, query, header, formData, body)
  let scheme = call_603797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603797.url(scheme.get, call_603797.host, call_603797.base,
                         call_603797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603797, url, valid)

proc call*(call_603798: Call_GetBucketAcl_603791; acl: bool; Bucket: string): Recallable =
  ## getBucketAcl
  ## Gets the access control policy for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603799 = newJObject()
  var query_603800 = newJObject()
  add(query_603800, "acl", newJBool(acl))
  add(path_603799, "Bucket", newJString(Bucket))
  result = call_603798.call(path_603799, query_603800, nil, nil, nil)

var getBucketAcl* = Call_GetBucketAcl_603791(name: "getBucketAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_GetBucketAcl_603792, base: "/", url: url_GetBucketAcl_603793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycle_603830 = ref object of OpenApiRestCall_602466
proc url_PutBucketLifecycle_603832(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketLifecycle_603831(path: JsonNode; query: JsonNode;
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
  var valid_603833 = path.getOrDefault("Bucket")
  valid_603833 = validateParameter(valid_603833, JString, required = true,
                                 default = nil)
  if valid_603833 != nil:
    section.add "Bucket", valid_603833
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_603834 = query.getOrDefault("lifecycle")
  valid_603834 = validateParameter(valid_603834, JBool, required = true, default = nil)
  if valid_603834 != nil:
    section.add "lifecycle", valid_603834
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603835 = header.getOrDefault("x-amz-security-token")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "x-amz-security-token", valid_603835
  var valid_603836 = header.getOrDefault("Content-MD5")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "Content-MD5", valid_603836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603838: Call_PutBucketLifecycle_603830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  let valid = call_603838.validator(path, query, header, formData, body)
  let scheme = call_603838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603838.url(scheme.get, call_603838.host, call_603838.base,
                         call_603838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603838, url, valid)

proc call*(call_603839: Call_PutBucketLifecycle_603830; Bucket: string;
          lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycle
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_603840 = newJObject()
  var query_603841 = newJObject()
  var body_603842 = newJObject()
  add(path_603840, "Bucket", newJString(Bucket))
  add(query_603841, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_603842 = body
  result = call_603839.call(path_603840, query_603841, nil, nil, body_603842)

var putBucketLifecycle* = Call_PutBucketLifecycle_603830(
    name: "putBucketLifecycle", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_PutBucketLifecycle_603831, base: "/",
    url: url_PutBucketLifecycle_603832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycle_603820 = ref object of OpenApiRestCall_602466
proc url_GetBucketLifecycle_603822(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLifecycle_603821(path: JsonNode; query: JsonNode;
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
  var valid_603823 = path.getOrDefault("Bucket")
  valid_603823 = validateParameter(valid_603823, JString, required = true,
                                 default = nil)
  if valid_603823 != nil:
    section.add "Bucket", valid_603823
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_603824 = query.getOrDefault("lifecycle")
  valid_603824 = validateParameter(valid_603824, JBool, required = true, default = nil)
  if valid_603824 != nil:
    section.add "lifecycle", valid_603824
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603825 = header.getOrDefault("x-amz-security-token")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "x-amz-security-token", valid_603825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603826: Call_GetBucketLifecycle_603820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  let valid = call_603826.validator(path, query, header, formData, body)
  let scheme = call_603826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603826.url(scheme.get, call_603826.host, call_603826.base,
                         call_603826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603826, url, valid)

proc call*(call_603827: Call_GetBucketLifecycle_603820; Bucket: string;
          lifecycle: bool): Recallable =
  ## getBucketLifecycle
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_603828 = newJObject()
  var query_603829 = newJObject()
  add(path_603828, "Bucket", newJString(Bucket))
  add(query_603829, "lifecycle", newJBool(lifecycle))
  result = call_603827.call(path_603828, query_603829, nil, nil, nil)

var getBucketLifecycle* = Call_GetBucketLifecycle_603820(
    name: "getBucketLifecycle", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_GetBucketLifecycle_603821, base: "/",
    url: url_GetBucketLifecycle_603822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLocation_603843 = ref object of OpenApiRestCall_602466
proc url_GetBucketLocation_603845(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLocation_603844(path: JsonNode; query: JsonNode;
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
  var valid_603846 = path.getOrDefault("Bucket")
  valid_603846 = validateParameter(valid_603846, JString, required = true,
                                 default = nil)
  if valid_603846 != nil:
    section.add "Bucket", valid_603846
  result.add "path", section
  ## parameters in `query` object:
  ##   location: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `location` field"
  var valid_603847 = query.getOrDefault("location")
  valid_603847 = validateParameter(valid_603847, JBool, required = true, default = nil)
  if valid_603847 != nil:
    section.add "location", valid_603847
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603848 = header.getOrDefault("x-amz-security-token")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "x-amz-security-token", valid_603848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603849: Call_GetBucketLocation_603843; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the region the bucket resides in.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  let valid = call_603849.validator(path, query, header, formData, body)
  let scheme = call_603849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603849.url(scheme.get, call_603849.host, call_603849.base,
                         call_603849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603849, url, valid)

proc call*(call_603850: Call_GetBucketLocation_603843; location: bool; Bucket: string): Recallable =
  ## getBucketLocation
  ## Returns the region the bucket resides in.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  ##   location: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603851 = newJObject()
  var query_603852 = newJObject()
  add(query_603852, "location", newJBool(location))
  add(path_603851, "Bucket", newJString(Bucket))
  result = call_603850.call(path_603851, query_603852, nil, nil, nil)

var getBucketLocation* = Call_GetBucketLocation_603843(name: "getBucketLocation",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#location",
    validator: validate_GetBucketLocation_603844, base: "/",
    url: url_GetBucketLocation_603845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLogging_603863 = ref object of OpenApiRestCall_602466
proc url_PutBucketLogging_603865(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketLogging_603864(path: JsonNode; query: JsonNode;
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
  var valid_603866 = path.getOrDefault("Bucket")
  valid_603866 = validateParameter(valid_603866, JString, required = true,
                                 default = nil)
  if valid_603866 != nil:
    section.add "Bucket", valid_603866
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_603867 = query.getOrDefault("logging")
  valid_603867 = validateParameter(valid_603867, JBool, required = true, default = nil)
  if valid_603867 != nil:
    section.add "logging", valid_603867
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603868 = header.getOrDefault("x-amz-security-token")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "x-amz-security-token", valid_603868
  var valid_603869 = header.getOrDefault("Content-MD5")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "Content-MD5", valid_603869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603871: Call_PutBucketLogging_603863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  let valid = call_603871.validator(path, query, header, formData, body)
  let scheme = call_603871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603871.url(scheme.get, call_603871.host, call_603871.base,
                         call_603871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603871, url, valid)

proc call*(call_603872: Call_PutBucketLogging_603863; logging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketLogging
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603873 = newJObject()
  var query_603874 = newJObject()
  var body_603875 = newJObject()
  add(query_603874, "logging", newJBool(logging))
  add(path_603873, "Bucket", newJString(Bucket))
  if body != nil:
    body_603875 = body
  result = call_603872.call(path_603873, query_603874, nil, nil, body_603875)

var putBucketLogging* = Call_PutBucketLogging_603863(name: "putBucketLogging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_PutBucketLogging_603864, base: "/",
    url: url_PutBucketLogging_603865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLogging_603853 = ref object of OpenApiRestCall_602466
proc url_GetBucketLogging_603855(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLogging_603854(path: JsonNode; query: JsonNode;
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
  var valid_603856 = path.getOrDefault("Bucket")
  valid_603856 = validateParameter(valid_603856, JString, required = true,
                                 default = nil)
  if valid_603856 != nil:
    section.add "Bucket", valid_603856
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_603857 = query.getOrDefault("logging")
  valid_603857 = validateParameter(valid_603857, JBool, required = true, default = nil)
  if valid_603857 != nil:
    section.add "logging", valid_603857
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603858 = header.getOrDefault("x-amz-security-token")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "x-amz-security-token", valid_603858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603859: Call_GetBucketLogging_603853; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  let valid = call_603859.validator(path, query, header, formData, body)
  let scheme = call_603859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603859.url(scheme.get, call_603859.host, call_603859.base,
                         call_603859.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603859, url, valid)

proc call*(call_603860: Call_GetBucketLogging_603853; logging: bool; Bucket: string): Recallable =
  ## getBucketLogging
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603861 = newJObject()
  var query_603862 = newJObject()
  add(query_603862, "logging", newJBool(logging))
  add(path_603861, "Bucket", newJString(Bucket))
  result = call_603860.call(path_603861, query_603862, nil, nil, nil)

var getBucketLogging* = Call_GetBucketLogging_603853(name: "getBucketLogging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_GetBucketLogging_603854, base: "/",
    url: url_GetBucketLogging_603855, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotificationConfiguration_603886 = ref object of OpenApiRestCall_602466
proc url_PutBucketNotificationConfiguration_603888(protocol: Scheme; host: string;
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

proc validate_PutBucketNotificationConfiguration_603887(path: JsonNode;
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
  var valid_603889 = path.getOrDefault("Bucket")
  valid_603889 = validateParameter(valid_603889, JString, required = true,
                                 default = nil)
  if valid_603889 != nil:
    section.add "Bucket", valid_603889
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_603890 = query.getOrDefault("notification")
  valid_603890 = validateParameter(valid_603890, JBool, required = true, default = nil)
  if valid_603890 != nil:
    section.add "notification", valid_603890
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603891 = header.getOrDefault("x-amz-security-token")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "x-amz-security-token", valid_603891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603893: Call_PutBucketNotificationConfiguration_603886;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enables notifications of specified events for a bucket.
  ## 
  let valid = call_603893.validator(path, query, header, formData, body)
  let scheme = call_603893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603893.url(scheme.get, call_603893.host, call_603893.base,
                         call_603893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603893, url, valid)

proc call*(call_603894: Call_PutBucketNotificationConfiguration_603886;
          notification: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotificationConfiguration
  ## Enables notifications of specified events for a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603895 = newJObject()
  var query_603896 = newJObject()
  var body_603897 = newJObject()
  add(query_603896, "notification", newJBool(notification))
  add(path_603895, "Bucket", newJString(Bucket))
  if body != nil:
    body_603897 = body
  result = call_603894.call(path_603895, query_603896, nil, nil, body_603897)

var putBucketNotificationConfiguration* = Call_PutBucketNotificationConfiguration_603886(
    name: "putBucketNotificationConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_PutBucketNotificationConfiguration_603887, base: "/",
    url: url_PutBucketNotificationConfiguration_603888,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotificationConfiguration_603876 = ref object of OpenApiRestCall_602466
proc url_GetBucketNotificationConfiguration_603878(protocol: Scheme; host: string;
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

proc validate_GetBucketNotificationConfiguration_603877(path: JsonNode;
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
  var valid_603879 = path.getOrDefault("Bucket")
  valid_603879 = validateParameter(valid_603879, JString, required = true,
                                 default = nil)
  if valid_603879 != nil:
    section.add "Bucket", valid_603879
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_603880 = query.getOrDefault("notification")
  valid_603880 = validateParameter(valid_603880, JBool, required = true, default = nil)
  if valid_603880 != nil:
    section.add "notification", valid_603880
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603881 = header.getOrDefault("x-amz-security-token")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "x-amz-security-token", valid_603881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603882: Call_GetBucketNotificationConfiguration_603876;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the notification configuration of a bucket.
  ## 
  let valid = call_603882.validator(path, query, header, formData, body)
  let scheme = call_603882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603882.url(scheme.get, call_603882.host, call_603882.base,
                         call_603882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603882, url, valid)

proc call*(call_603883: Call_GetBucketNotificationConfiguration_603876;
          notification: bool; Bucket: string): Recallable =
  ## getBucketNotificationConfiguration
  ## Returns the notification configuration of a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_603884 = newJObject()
  var query_603885 = newJObject()
  add(query_603885, "notification", newJBool(notification))
  add(path_603884, "Bucket", newJString(Bucket))
  result = call_603883.call(path_603884, query_603885, nil, nil, nil)

var getBucketNotificationConfiguration* = Call_GetBucketNotificationConfiguration_603876(
    name: "getBucketNotificationConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_GetBucketNotificationConfiguration_603877, base: "/",
    url: url_GetBucketNotificationConfiguration_603878,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotification_603908 = ref object of OpenApiRestCall_602466
proc url_PutBucketNotification_603910(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketNotification_603909(path: JsonNode; query: JsonNode;
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
  var valid_603911 = path.getOrDefault("Bucket")
  valid_603911 = validateParameter(valid_603911, JString, required = true,
                                 default = nil)
  if valid_603911 != nil:
    section.add "Bucket", valid_603911
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_603912 = query.getOrDefault("notification")
  valid_603912 = validateParameter(valid_603912, JBool, required = true, default = nil)
  if valid_603912 != nil:
    section.add "notification", valid_603912
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603913 = header.getOrDefault("x-amz-security-token")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "x-amz-security-token", valid_603913
  var valid_603914 = header.getOrDefault("Content-MD5")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "Content-MD5", valid_603914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603916: Call_PutBucketNotification_603908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  let valid = call_603916.validator(path, query, header, formData, body)
  let scheme = call_603916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603916.url(scheme.get, call_603916.host, call_603916.base,
                         call_603916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603916, url, valid)

proc call*(call_603917: Call_PutBucketNotification_603908; notification: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotification
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603918 = newJObject()
  var query_603919 = newJObject()
  var body_603920 = newJObject()
  add(query_603919, "notification", newJBool(notification))
  add(path_603918, "Bucket", newJString(Bucket))
  if body != nil:
    body_603920 = body
  result = call_603917.call(path_603918, query_603919, nil, nil, body_603920)

var putBucketNotification* = Call_PutBucketNotification_603908(
    name: "putBucketNotification", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_PutBucketNotification_603909, base: "/",
    url: url_PutBucketNotification_603910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotification_603898 = ref object of OpenApiRestCall_602466
proc url_GetBucketNotification_603900(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketNotification_603899(path: JsonNode; query: JsonNode;
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
  var valid_603901 = path.getOrDefault("Bucket")
  valid_603901 = validateParameter(valid_603901, JString, required = true,
                                 default = nil)
  if valid_603901 != nil:
    section.add "Bucket", valid_603901
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_603902 = query.getOrDefault("notification")
  valid_603902 = validateParameter(valid_603902, JBool, required = true, default = nil)
  if valid_603902 != nil:
    section.add "notification", valid_603902
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603903 = header.getOrDefault("x-amz-security-token")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "x-amz-security-token", valid_603903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603904: Call_GetBucketNotification_603898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  let valid = call_603904.validator(path, query, header, formData, body)
  let scheme = call_603904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603904.url(scheme.get, call_603904.host, call_603904.base,
                         call_603904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603904, url, valid)

proc call*(call_603905: Call_GetBucketNotification_603898; notification: bool;
          Bucket: string): Recallable =
  ## getBucketNotification
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_603906 = newJObject()
  var query_603907 = newJObject()
  add(query_603907, "notification", newJBool(notification))
  add(path_603906, "Bucket", newJString(Bucket))
  result = call_603905.call(path_603906, query_603907, nil, nil, nil)

var getBucketNotification* = Call_GetBucketNotification_603898(
    name: "getBucketNotification", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_GetBucketNotification_603899, base: "/",
    url: url_GetBucketNotification_603900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicyStatus_603921 = ref object of OpenApiRestCall_602466
proc url_GetBucketPolicyStatus_603923(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketPolicyStatus_603922(path: JsonNode; query: JsonNode;
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
  var valid_603924 = path.getOrDefault("Bucket")
  valid_603924 = validateParameter(valid_603924, JString, required = true,
                                 default = nil)
  if valid_603924 != nil:
    section.add "Bucket", valid_603924
  result.add "path", section
  ## parameters in `query` object:
  ##   policyStatus: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `policyStatus` field"
  var valid_603925 = query.getOrDefault("policyStatus")
  valid_603925 = validateParameter(valid_603925, JBool, required = true, default = nil)
  if valid_603925 != nil:
    section.add "policyStatus", valid_603925
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603926 = header.getOrDefault("x-amz-security-token")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "x-amz-security-token", valid_603926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603927: Call_GetBucketPolicyStatus_603921; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ## 
  let valid = call_603927.validator(path, query, header, formData, body)
  let scheme = call_603927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603927.url(scheme.get, call_603927.host, call_603927.base,
                         call_603927.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603927, url, valid)

proc call*(call_603928: Call_GetBucketPolicyStatus_603921; policyStatus: bool;
          Bucket: string): Recallable =
  ## getBucketPolicyStatus
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ##   policyStatus: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose policy status you want to retrieve.
  var path_603929 = newJObject()
  var query_603930 = newJObject()
  add(query_603930, "policyStatus", newJBool(policyStatus))
  add(path_603929, "Bucket", newJString(Bucket))
  result = call_603928.call(path_603929, query_603930, nil, nil, nil)

var getBucketPolicyStatus* = Call_GetBucketPolicyStatus_603921(
    name: "getBucketPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#policyStatus",
    validator: validate_GetBucketPolicyStatus_603922, base: "/",
    url: url_GetBucketPolicyStatus_603923, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketRequestPayment_603941 = ref object of OpenApiRestCall_602466
proc url_PutBucketRequestPayment_603943(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketRequestPayment_603942(path: JsonNode; query: JsonNode;
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
  var valid_603944 = path.getOrDefault("Bucket")
  valid_603944 = validateParameter(valid_603944, JString, required = true,
                                 default = nil)
  if valid_603944 != nil:
    section.add "Bucket", valid_603944
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_603945 = query.getOrDefault("requestPayment")
  valid_603945 = validateParameter(valid_603945, JBool, required = true, default = nil)
  if valid_603945 != nil:
    section.add "requestPayment", valid_603945
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603946 = header.getOrDefault("x-amz-security-token")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "x-amz-security-token", valid_603946
  var valid_603947 = header.getOrDefault("Content-MD5")
  valid_603947 = validateParameter(valid_603947, JString, required = false,
                                 default = nil)
  if valid_603947 != nil:
    section.add "Content-MD5", valid_603947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603949: Call_PutBucketRequestPayment_603941; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  let valid = call_603949.validator(path, query, header, formData, body)
  let scheme = call_603949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603949.url(scheme.get, call_603949.host, call_603949.base,
                         call_603949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603949, url, valid)

proc call*(call_603950: Call_PutBucketRequestPayment_603941; requestPayment: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketRequestPayment
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603951 = newJObject()
  var query_603952 = newJObject()
  var body_603953 = newJObject()
  add(query_603952, "requestPayment", newJBool(requestPayment))
  add(path_603951, "Bucket", newJString(Bucket))
  if body != nil:
    body_603953 = body
  result = call_603950.call(path_603951, query_603952, nil, nil, body_603953)

var putBucketRequestPayment* = Call_PutBucketRequestPayment_603941(
    name: "putBucketRequestPayment", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_PutBucketRequestPayment_603942, base: "/",
    url: url_PutBucketRequestPayment_603943, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketRequestPayment_603931 = ref object of OpenApiRestCall_602466
proc url_GetBucketRequestPayment_603933(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketRequestPayment_603932(path: JsonNode; query: JsonNode;
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
  var valid_603934 = path.getOrDefault("Bucket")
  valid_603934 = validateParameter(valid_603934, JString, required = true,
                                 default = nil)
  if valid_603934 != nil:
    section.add "Bucket", valid_603934
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_603935 = query.getOrDefault("requestPayment")
  valid_603935 = validateParameter(valid_603935, JBool, required = true, default = nil)
  if valid_603935 != nil:
    section.add "requestPayment", valid_603935
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603936 = header.getOrDefault("x-amz-security-token")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "x-amz-security-token", valid_603936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603937: Call_GetBucketRequestPayment_603931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the request payment configuration of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  let valid = call_603937.validator(path, query, header, formData, body)
  let scheme = call_603937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603937.url(scheme.get, call_603937.host, call_603937.base,
                         call_603937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603937, url, valid)

proc call*(call_603938: Call_GetBucketRequestPayment_603931; requestPayment: bool;
          Bucket: string): Recallable =
  ## getBucketRequestPayment
  ## Returns the request payment configuration of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603939 = newJObject()
  var query_603940 = newJObject()
  add(query_603940, "requestPayment", newJBool(requestPayment))
  add(path_603939, "Bucket", newJString(Bucket))
  result = call_603938.call(path_603939, query_603940, nil, nil, nil)

var getBucketRequestPayment* = Call_GetBucketRequestPayment_603931(
    name: "getBucketRequestPayment", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_GetBucketRequestPayment_603932, base: "/",
    url: url_GetBucketRequestPayment_603933, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketVersioning_603964 = ref object of OpenApiRestCall_602466
proc url_PutBucketVersioning_603966(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketVersioning_603965(path: JsonNode; query: JsonNode;
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
  var valid_603967 = path.getOrDefault("Bucket")
  valid_603967 = validateParameter(valid_603967, JString, required = true,
                                 default = nil)
  if valid_603967 != nil:
    section.add "Bucket", valid_603967
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_603968 = query.getOrDefault("versioning")
  valid_603968 = validateParameter(valid_603968, JBool, required = true, default = nil)
  if valid_603968 != nil:
    section.add "versioning", valid_603968
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  section = newJObject()
  var valid_603969 = header.getOrDefault("x-amz-security-token")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "x-amz-security-token", valid_603969
  var valid_603970 = header.getOrDefault("Content-MD5")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "Content-MD5", valid_603970
  var valid_603971 = header.getOrDefault("x-amz-mfa")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "x-amz-mfa", valid_603971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603973: Call_PutBucketVersioning_603964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  let valid = call_603973.validator(path, query, header, formData, body)
  let scheme = call_603973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603973.url(scheme.get, call_603973.host, call_603973.base,
                         call_603973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603973, url, valid)

proc call*(call_603974: Call_PutBucketVersioning_603964; Bucket: string;
          body: JsonNode; versioning: bool): Recallable =
  ## putBucketVersioning
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   versioning: bool (required)
  var path_603975 = newJObject()
  var query_603976 = newJObject()
  var body_603977 = newJObject()
  add(path_603975, "Bucket", newJString(Bucket))
  if body != nil:
    body_603977 = body
  add(query_603976, "versioning", newJBool(versioning))
  result = call_603974.call(path_603975, query_603976, nil, nil, body_603977)

var putBucketVersioning* = Call_PutBucketVersioning_603964(
    name: "putBucketVersioning", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_PutBucketVersioning_603965,
    base: "/", url: url_PutBucketVersioning_603966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketVersioning_603954 = ref object of OpenApiRestCall_602466
proc url_GetBucketVersioning_603956(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketVersioning_603955(path: JsonNode; query: JsonNode;
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
  var valid_603957 = path.getOrDefault("Bucket")
  valid_603957 = validateParameter(valid_603957, JString, required = true,
                                 default = nil)
  if valid_603957 != nil:
    section.add "Bucket", valid_603957
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_603958 = query.getOrDefault("versioning")
  valid_603958 = validateParameter(valid_603958, JBool, required = true, default = nil)
  if valid_603958 != nil:
    section.add "versioning", valid_603958
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603959 = header.getOrDefault("x-amz-security-token")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "x-amz-security-token", valid_603959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603960: Call_GetBucketVersioning_603954; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the versioning state of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  let valid = call_603960.validator(path, query, header, formData, body)
  let scheme = call_603960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603960.url(scheme.get, call_603960.host, call_603960.base,
                         call_603960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603960, url, valid)

proc call*(call_603961: Call_GetBucketVersioning_603954; Bucket: string;
          versioning: bool): Recallable =
  ## getBucketVersioning
  ## Returns the versioning state of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versioning: bool (required)
  var path_603962 = newJObject()
  var query_603963 = newJObject()
  add(path_603962, "Bucket", newJString(Bucket))
  add(query_603963, "versioning", newJBool(versioning))
  result = call_603961.call(path_603962, query_603963, nil, nil, nil)

var getBucketVersioning* = Call_GetBucketVersioning_603954(
    name: "getBucketVersioning", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_GetBucketVersioning_603955,
    base: "/", url: url_GetBucketVersioning_603956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectAcl_603991 = ref object of OpenApiRestCall_602466
proc url_PutObjectAcl_603993(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectAcl_603992(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603994 = path.getOrDefault("Key")
  valid_603994 = validateParameter(valid_603994, JString, required = true,
                                 default = nil)
  if valid_603994 != nil:
    section.add "Key", valid_603994
  var valid_603995 = path.getOrDefault("Bucket")
  valid_603995 = validateParameter(valid_603995, JString, required = true,
                                 default = nil)
  if valid_603995 != nil:
    section.add "Bucket", valid_603995
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_603996 = query.getOrDefault("versionId")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "versionId", valid_603996
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_603997 = query.getOrDefault("acl")
  valid_603997 = validateParameter(valid_603997, JBool, required = true, default = nil)
  if valid_603997 != nil:
    section.add "acl", valid_603997
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
  var valid_603998 = header.getOrDefault("x-amz-security-token")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "x-amz-security-token", valid_603998
  var valid_603999 = header.getOrDefault("Content-MD5")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "Content-MD5", valid_603999
  var valid_604000 = header.getOrDefault("x-amz-acl")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = newJString("private"))
  if valid_604000 != nil:
    section.add "x-amz-acl", valid_604000
  var valid_604001 = header.getOrDefault("x-amz-grant-read")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "x-amz-grant-read", valid_604001
  var valid_604002 = header.getOrDefault("x-amz-grant-read-acp")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "x-amz-grant-read-acp", valid_604002
  var valid_604003 = header.getOrDefault("x-amz-grant-write")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "x-amz-grant-write", valid_604003
  var valid_604004 = header.getOrDefault("x-amz-grant-write-acp")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "x-amz-grant-write-acp", valid_604004
  var valid_604005 = header.getOrDefault("x-amz-request-payer")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = newJString("requester"))
  if valid_604005 != nil:
    section.add "x-amz-request-payer", valid_604005
  var valid_604006 = header.getOrDefault("x-amz-grant-full-control")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "x-amz-grant-full-control", valid_604006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604008: Call_PutObjectAcl_603991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  let valid = call_604008.validator(path, query, header, formData, body)
  let scheme = call_604008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604008.url(scheme.get, call_604008.host, call_604008.base,
                         call_604008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604008, url, valid)

proc call*(call_604009: Call_PutObjectAcl_603991; Key: string; acl: bool;
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
  var path_604010 = newJObject()
  var query_604011 = newJObject()
  var body_604012 = newJObject()
  add(query_604011, "versionId", newJString(versionId))
  add(path_604010, "Key", newJString(Key))
  add(query_604011, "acl", newJBool(acl))
  add(path_604010, "Bucket", newJString(Bucket))
  if body != nil:
    body_604012 = body
  result = call_604009.call(path_604010, query_604011, nil, nil, body_604012)

var putObjectAcl* = Call_PutObjectAcl_603991(name: "putObjectAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_PutObjectAcl_603992,
    base: "/", url: url_PutObjectAcl_603993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAcl_603978 = ref object of OpenApiRestCall_602466
proc url_GetObjectAcl_603980(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectAcl_603979(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603981 = path.getOrDefault("Key")
  valid_603981 = validateParameter(valid_603981, JString, required = true,
                                 default = nil)
  if valid_603981 != nil:
    section.add "Key", valid_603981
  var valid_603982 = path.getOrDefault("Bucket")
  valid_603982 = validateParameter(valid_603982, JString, required = true,
                                 default = nil)
  if valid_603982 != nil:
    section.add "Bucket", valid_603982
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_603983 = query.getOrDefault("versionId")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "versionId", valid_603983
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_603984 = query.getOrDefault("acl")
  valid_603984 = validateParameter(valid_603984, JBool, required = true, default = nil)
  if valid_603984 != nil:
    section.add "acl", valid_603984
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_603985 = header.getOrDefault("x-amz-security-token")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "x-amz-security-token", valid_603985
  var valid_603986 = header.getOrDefault("x-amz-request-payer")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = newJString("requester"))
  if valid_603986 != nil:
    section.add "x-amz-request-payer", valid_603986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603987: Call_GetObjectAcl_603978; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access control list (ACL) of an object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  let valid = call_603987.validator(path, query, header, formData, body)
  let scheme = call_603987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603987.url(scheme.get, call_603987.host, call_603987.base,
                         call_603987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603987, url, valid)

proc call*(call_603988: Call_GetObjectAcl_603978; Key: string; acl: bool;
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
  var path_603989 = newJObject()
  var query_603990 = newJObject()
  add(query_603990, "versionId", newJString(versionId))
  add(path_603989, "Key", newJString(Key))
  add(query_603990, "acl", newJBool(acl))
  add(path_603989, "Bucket", newJString(Bucket))
  result = call_603988.call(path_603989, query_603990, nil, nil, nil)

var getObjectAcl* = Call_GetObjectAcl_603978(name: "getObjectAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_GetObjectAcl_603979,
    base: "/", url: url_GetObjectAcl_603980, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLegalHold_604026 = ref object of OpenApiRestCall_602466
proc url_PutObjectLegalHold_604028(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectLegalHold_604027(path: JsonNode; query: JsonNode;
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
  var valid_604029 = path.getOrDefault("Key")
  valid_604029 = validateParameter(valid_604029, JString, required = true,
                                 default = nil)
  if valid_604029 != nil:
    section.add "Key", valid_604029
  var valid_604030 = path.getOrDefault("Bucket")
  valid_604030 = validateParameter(valid_604030, JString, required = true,
                                 default = nil)
  if valid_604030 != nil:
    section.add "Bucket", valid_604030
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object that you want to place a Legal Hold on.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_604031 = query.getOrDefault("versionId")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "versionId", valid_604031
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_604032 = query.getOrDefault("legal-hold")
  valid_604032 = validateParameter(valid_604032, JBool, required = true, default = nil)
  if valid_604032 != nil:
    section.add "legal-hold", valid_604032
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_604033 = header.getOrDefault("x-amz-security-token")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "x-amz-security-token", valid_604033
  var valid_604034 = header.getOrDefault("Content-MD5")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "Content-MD5", valid_604034
  var valid_604035 = header.getOrDefault("x-amz-request-payer")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = newJString("requester"))
  if valid_604035 != nil:
    section.add "x-amz-request-payer", valid_604035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604037: Call_PutObjectLegalHold_604026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a Legal Hold configuration to the specified object.
  ## 
  let valid = call_604037.validator(path, query, header, formData, body)
  let scheme = call_604037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604037.url(scheme.get, call_604037.host, call_604037.base,
                         call_604037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604037, url, valid)

proc call*(call_604038: Call_PutObjectLegalHold_604026; Key: string; legalHold: bool;
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
  var path_604039 = newJObject()
  var query_604040 = newJObject()
  var body_604041 = newJObject()
  add(query_604040, "versionId", newJString(versionId))
  add(path_604039, "Key", newJString(Key))
  add(query_604040, "legal-hold", newJBool(legalHold))
  add(path_604039, "Bucket", newJString(Bucket))
  if body != nil:
    body_604041 = body
  result = call_604038.call(path_604039, query_604040, nil, nil, body_604041)

var putObjectLegalHold* = Call_PutObjectLegalHold_604026(
    name: "putObjectLegalHold", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_PutObjectLegalHold_604027,
    base: "/", url: url_PutObjectLegalHold_604028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLegalHold_604013 = ref object of OpenApiRestCall_602466
proc url_GetObjectLegalHold_604015(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectLegalHold_604014(path: JsonNode; query: JsonNode;
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
  var valid_604016 = path.getOrDefault("Key")
  valid_604016 = validateParameter(valid_604016, JString, required = true,
                                 default = nil)
  if valid_604016 != nil:
    section.add "Key", valid_604016
  var valid_604017 = path.getOrDefault("Bucket")
  valid_604017 = validateParameter(valid_604017, JString, required = true,
                                 default = nil)
  if valid_604017 != nil:
    section.add "Bucket", valid_604017
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object whose Legal Hold status you want to retrieve.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_604018 = query.getOrDefault("versionId")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "versionId", valid_604018
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_604019 = query.getOrDefault("legal-hold")
  valid_604019 = validateParameter(valid_604019, JBool, required = true, default = nil)
  if valid_604019 != nil:
    section.add "legal-hold", valid_604019
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_604020 = header.getOrDefault("x-amz-security-token")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "x-amz-security-token", valid_604020
  var valid_604021 = header.getOrDefault("x-amz-request-payer")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = newJString("requester"))
  if valid_604021 != nil:
    section.add "x-amz-request-payer", valid_604021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604022: Call_GetObjectLegalHold_604013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an object's current Legal Hold status.
  ## 
  let valid = call_604022.validator(path, query, header, formData, body)
  let scheme = call_604022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604022.url(scheme.get, call_604022.host, call_604022.base,
                         call_604022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604022, url, valid)

proc call*(call_604023: Call_GetObjectLegalHold_604013; Key: string; legalHold: bool;
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
  var path_604024 = newJObject()
  var query_604025 = newJObject()
  add(query_604025, "versionId", newJString(versionId))
  add(path_604024, "Key", newJString(Key))
  add(query_604025, "legal-hold", newJBool(legalHold))
  add(path_604024, "Bucket", newJString(Bucket))
  result = call_604023.call(path_604024, query_604025, nil, nil, nil)

var getObjectLegalHold* = Call_GetObjectLegalHold_604013(
    name: "getObjectLegalHold", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_GetObjectLegalHold_604014,
    base: "/", url: url_GetObjectLegalHold_604015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLockConfiguration_604052 = ref object of OpenApiRestCall_602466
proc url_PutObjectLockConfiguration_604054(protocol: Scheme; host: string;
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

proc validate_PutObjectLockConfiguration_604053(path: JsonNode; query: JsonNode;
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
  var valid_604055 = path.getOrDefault("Bucket")
  valid_604055 = validateParameter(valid_604055, JString, required = true,
                                 default = nil)
  if valid_604055 != nil:
    section.add "Bucket", valid_604055
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_604056 = query.getOrDefault("object-lock")
  valid_604056 = validateParameter(valid_604056, JBool, required = true, default = nil)
  if valid_604056 != nil:
    section.add "object-lock", valid_604056
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
  var valid_604057 = header.getOrDefault("x-amz-security-token")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "x-amz-security-token", valid_604057
  var valid_604058 = header.getOrDefault("Content-MD5")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "Content-MD5", valid_604058
  var valid_604059 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_604059
  var valid_604060 = header.getOrDefault("x-amz-request-payer")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = newJString("requester"))
  if valid_604060 != nil:
    section.add "x-amz-request-payer", valid_604060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604062: Call_PutObjectLockConfiguration_604052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_604062.validator(path, query, header, formData, body)
  let scheme = call_604062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604062.url(scheme.get, call_604062.host, call_604062.base,
                         call_604062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604062, url, valid)

proc call*(call_604063: Call_PutObjectLockConfiguration_604052; objectLock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putObjectLockConfiguration
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to create or replace.
  ##   body: JObject (required)
  var path_604064 = newJObject()
  var query_604065 = newJObject()
  var body_604066 = newJObject()
  add(query_604065, "object-lock", newJBool(objectLock))
  add(path_604064, "Bucket", newJString(Bucket))
  if body != nil:
    body_604066 = body
  result = call_604063.call(path_604064, query_604065, nil, nil, body_604066)

var putObjectLockConfiguration* = Call_PutObjectLockConfiguration_604052(
    name: "putObjectLockConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_PutObjectLockConfiguration_604053, base: "/",
    url: url_PutObjectLockConfiguration_604054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLockConfiguration_604042 = ref object of OpenApiRestCall_602466
proc url_GetObjectLockConfiguration_604044(protocol: Scheme; host: string;
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

proc validate_GetObjectLockConfiguration_604043(path: JsonNode; query: JsonNode;
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
  var valid_604045 = path.getOrDefault("Bucket")
  valid_604045 = validateParameter(valid_604045, JString, required = true,
                                 default = nil)
  if valid_604045 != nil:
    section.add "Bucket", valid_604045
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_604046 = query.getOrDefault("object-lock")
  valid_604046 = validateParameter(valid_604046, JBool, required = true, default = nil)
  if valid_604046 != nil:
    section.add "object-lock", valid_604046
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604047 = header.getOrDefault("x-amz-security-token")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "x-amz-security-token", valid_604047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604048: Call_GetObjectLockConfiguration_604042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_604048.validator(path, query, header, formData, body)
  let scheme = call_604048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604048.url(scheme.get, call_604048.host, call_604048.base,
                         call_604048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604048, url, valid)

proc call*(call_604049: Call_GetObjectLockConfiguration_604042; objectLock: bool;
          Bucket: string): Recallable =
  ## getObjectLockConfiguration
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to retrieve.
  var path_604050 = newJObject()
  var query_604051 = newJObject()
  add(query_604051, "object-lock", newJBool(objectLock))
  add(path_604050, "Bucket", newJString(Bucket))
  result = call_604049.call(path_604050, query_604051, nil, nil, nil)

var getObjectLockConfiguration* = Call_GetObjectLockConfiguration_604042(
    name: "getObjectLockConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_GetObjectLockConfiguration_604043, base: "/",
    url: url_GetObjectLockConfiguration_604044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectRetention_604080 = ref object of OpenApiRestCall_602466
proc url_PutObjectRetention_604082(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectRetention_604081(path: JsonNode; query: JsonNode;
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
  var valid_604083 = path.getOrDefault("Key")
  valid_604083 = validateParameter(valid_604083, JString, required = true,
                                 default = nil)
  if valid_604083 != nil:
    section.add "Key", valid_604083
  var valid_604084 = path.getOrDefault("Bucket")
  valid_604084 = validateParameter(valid_604084, JString, required = true,
                                 default = nil)
  if valid_604084 != nil:
    section.add "Bucket", valid_604084
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object that you want to apply this Object Retention configuration to.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_604085 = query.getOrDefault("versionId")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "versionId", valid_604085
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_604086 = query.getOrDefault("retention")
  valid_604086 = validateParameter(valid_604086, JBool, required = true, default = nil)
  if valid_604086 != nil:
    section.add "retention", valid_604086
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
  var valid_604087 = header.getOrDefault("x-amz-security-token")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "x-amz-security-token", valid_604087
  var valid_604088 = header.getOrDefault("Content-MD5")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "Content-MD5", valid_604088
  var valid_604089 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_604089 = validateParameter(valid_604089, JBool, required = false, default = nil)
  if valid_604089 != nil:
    section.add "x-amz-bypass-governance-retention", valid_604089
  var valid_604090 = header.getOrDefault("x-amz-request-payer")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = newJString("requester"))
  if valid_604090 != nil:
    section.add "x-amz-request-payer", valid_604090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604092: Call_PutObjectRetention_604080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an Object Retention configuration on an object.
  ## 
  let valid = call_604092.validator(path, query, header, formData, body)
  let scheme = call_604092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604092.url(scheme.get, call_604092.host, call_604092.base,
                         call_604092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604092, url, valid)

proc call*(call_604093: Call_PutObjectRetention_604080; retention: bool; Key: string;
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
  var path_604094 = newJObject()
  var query_604095 = newJObject()
  var body_604096 = newJObject()
  add(query_604095, "versionId", newJString(versionId))
  add(query_604095, "retention", newJBool(retention))
  add(path_604094, "Key", newJString(Key))
  add(path_604094, "Bucket", newJString(Bucket))
  if body != nil:
    body_604096 = body
  result = call_604093.call(path_604094, query_604095, nil, nil, body_604096)

var putObjectRetention* = Call_PutObjectRetention_604080(
    name: "putObjectRetention", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_PutObjectRetention_604081,
    base: "/", url: url_PutObjectRetention_604082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectRetention_604067 = ref object of OpenApiRestCall_602466
proc url_GetObjectRetention_604069(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectRetention_604068(path: JsonNode; query: JsonNode;
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
  var valid_604070 = path.getOrDefault("Key")
  valid_604070 = validateParameter(valid_604070, JString, required = true,
                                 default = nil)
  if valid_604070 != nil:
    section.add "Key", valid_604070
  var valid_604071 = path.getOrDefault("Bucket")
  valid_604071 = validateParameter(valid_604071, JString, required = true,
                                 default = nil)
  if valid_604071 != nil:
    section.add "Bucket", valid_604071
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object whose retention settings you want to retrieve.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_604072 = query.getOrDefault("versionId")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "versionId", valid_604072
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_604073 = query.getOrDefault("retention")
  valid_604073 = validateParameter(valid_604073, JBool, required = true, default = nil)
  if valid_604073 != nil:
    section.add "retention", valid_604073
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_604074 = header.getOrDefault("x-amz-security-token")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "x-amz-security-token", valid_604074
  var valid_604075 = header.getOrDefault("x-amz-request-payer")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = newJString("requester"))
  if valid_604075 != nil:
    section.add "x-amz-request-payer", valid_604075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604076: Call_GetObjectRetention_604067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an object's retention settings.
  ## 
  let valid = call_604076.validator(path, query, header, formData, body)
  let scheme = call_604076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604076.url(scheme.get, call_604076.host, call_604076.base,
                         call_604076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604076, url, valid)

proc call*(call_604077: Call_GetObjectRetention_604067; retention: bool; Key: string;
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
  var path_604078 = newJObject()
  var query_604079 = newJObject()
  add(query_604079, "versionId", newJString(versionId))
  add(query_604079, "retention", newJBool(retention))
  add(path_604078, "Key", newJString(Key))
  add(path_604078, "Bucket", newJString(Bucket))
  result = call_604077.call(path_604078, query_604079, nil, nil, nil)

var getObjectRetention* = Call_GetObjectRetention_604067(
    name: "getObjectRetention", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_GetObjectRetention_604068,
    base: "/", url: url_GetObjectRetention_604069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTorrent_604097 = ref object of OpenApiRestCall_602466
proc url_GetObjectTorrent_604099(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectTorrent_604098(path: JsonNode; query: JsonNode;
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
  var valid_604100 = path.getOrDefault("Key")
  valid_604100 = validateParameter(valid_604100, JString, required = true,
                                 default = nil)
  if valid_604100 != nil:
    section.add "Key", valid_604100
  var valid_604101 = path.getOrDefault("Bucket")
  valid_604101 = validateParameter(valid_604101, JString, required = true,
                                 default = nil)
  if valid_604101 != nil:
    section.add "Bucket", valid_604101
  result.add "path", section
  ## parameters in `query` object:
  ##   torrent: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `torrent` field"
  var valid_604102 = query.getOrDefault("torrent")
  valid_604102 = validateParameter(valid_604102, JBool, required = true, default = nil)
  if valid_604102 != nil:
    section.add "torrent", valid_604102
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_604103 = header.getOrDefault("x-amz-security-token")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "x-amz-security-token", valid_604103
  var valid_604104 = header.getOrDefault("x-amz-request-payer")
  valid_604104 = validateParameter(valid_604104, JString, required = false,
                                 default = newJString("requester"))
  if valid_604104 != nil:
    section.add "x-amz-request-payer", valid_604104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604105: Call_GetObjectTorrent_604097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return torrent files from a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  let valid = call_604105.validator(path, query, header, formData, body)
  let scheme = call_604105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604105.url(scheme.get, call_604105.host, call_604105.base,
                         call_604105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604105, url, valid)

proc call*(call_604106: Call_GetObjectTorrent_604097; torrent: bool; Key: string;
          Bucket: string): Recallable =
  ## getObjectTorrent
  ## Return torrent files from a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  ##   torrent: bool (required)
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_604107 = newJObject()
  var query_604108 = newJObject()
  add(query_604108, "torrent", newJBool(torrent))
  add(path_604107, "Key", newJString(Key))
  add(path_604107, "Bucket", newJString(Bucket))
  result = call_604106.call(path_604107, query_604108, nil, nil, nil)

var getObjectTorrent* = Call_GetObjectTorrent_604097(name: "getObjectTorrent",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#torrent", validator: validate_GetObjectTorrent_604098,
    base: "/", url: url_GetObjectTorrent_604099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketAnalyticsConfigurations_604109 = ref object of OpenApiRestCall_602466
proc url_ListBucketAnalyticsConfigurations_604111(protocol: Scheme; host: string;
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

proc validate_ListBucketAnalyticsConfigurations_604110(path: JsonNode;
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
  var valid_604112 = path.getOrDefault("Bucket")
  valid_604112 = validateParameter(valid_604112, JString, required = true,
                                 default = nil)
  if valid_604112 != nil:
    section.add "Bucket", valid_604112
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   continuation-token: JString
  ##                     : The ContinuationToken that represents a placeholder from where this request should begin.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_604113 = query.getOrDefault("analytics")
  valid_604113 = validateParameter(valid_604113, JBool, required = true, default = nil)
  if valid_604113 != nil:
    section.add "analytics", valid_604113
  var valid_604114 = query.getOrDefault("continuation-token")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "continuation-token", valid_604114
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604115 = header.getOrDefault("x-amz-security-token")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "x-amz-security-token", valid_604115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604116: Call_ListBucketAnalyticsConfigurations_604109;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the analytics configurations for the bucket.
  ## 
  let valid = call_604116.validator(path, query, header, formData, body)
  let scheme = call_604116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604116.url(scheme.get, call_604116.host, call_604116.base,
                         call_604116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604116, url, valid)

proc call*(call_604117: Call_ListBucketAnalyticsConfigurations_604109;
          analytics: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketAnalyticsConfigurations
  ## Lists the analytics configurations for the bucket.
  ##   analytics: bool (required)
  ##   continuationToken: string
  ##                    : The ContinuationToken that represents a placeholder from where this request should begin.
  ##   Bucket: string (required)
  ##         : The name of the bucket from which analytics configurations are retrieved.
  var path_604118 = newJObject()
  var query_604119 = newJObject()
  add(query_604119, "analytics", newJBool(analytics))
  add(query_604119, "continuation-token", newJString(continuationToken))
  add(path_604118, "Bucket", newJString(Bucket))
  result = call_604117.call(path_604118, query_604119, nil, nil, nil)

var listBucketAnalyticsConfigurations* = Call_ListBucketAnalyticsConfigurations_604109(
    name: "listBucketAnalyticsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics",
    validator: validate_ListBucketAnalyticsConfigurations_604110, base: "/",
    url: url_ListBucketAnalyticsConfigurations_604111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketInventoryConfigurations_604120 = ref object of OpenApiRestCall_602466
proc url_ListBucketInventoryConfigurations_604122(protocol: Scheme; host: string;
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

proc validate_ListBucketInventoryConfigurations_604121(path: JsonNode;
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
  var valid_604123 = path.getOrDefault("Bucket")
  valid_604123 = validateParameter(valid_604123, JString, required = true,
                                 default = nil)
  if valid_604123 != nil:
    section.add "Bucket", valid_604123
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_604124 = query.getOrDefault("inventory")
  valid_604124 = validateParameter(valid_604124, JBool, required = true, default = nil)
  if valid_604124 != nil:
    section.add "inventory", valid_604124
  var valid_604125 = query.getOrDefault("continuation-token")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "continuation-token", valid_604125
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604126 = header.getOrDefault("x-amz-security-token")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "x-amz-security-token", valid_604126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604127: Call_ListBucketInventoryConfigurations_604120;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of inventory configurations for the bucket.
  ## 
  let valid = call_604127.validator(path, query, header, formData, body)
  let scheme = call_604127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604127.url(scheme.get, call_604127.host, call_604127.base,
                         call_604127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604127, url, valid)

proc call*(call_604128: Call_ListBucketInventoryConfigurations_604120;
          inventory: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketInventoryConfigurations
  ## Returns a list of inventory configurations for the bucket.
  ##   inventory: bool (required)
  ##   continuationToken: string
  ##                    : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configurations to retrieve.
  var path_604129 = newJObject()
  var query_604130 = newJObject()
  add(query_604130, "inventory", newJBool(inventory))
  add(query_604130, "continuation-token", newJString(continuationToken))
  add(path_604129, "Bucket", newJString(Bucket))
  result = call_604128.call(path_604129, query_604130, nil, nil, nil)

var listBucketInventoryConfigurations* = Call_ListBucketInventoryConfigurations_604120(
    name: "listBucketInventoryConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory",
    validator: validate_ListBucketInventoryConfigurations_604121, base: "/",
    url: url_ListBucketInventoryConfigurations_604122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketMetricsConfigurations_604131 = ref object of OpenApiRestCall_602466
proc url_ListBucketMetricsConfigurations_604133(protocol: Scheme; host: string;
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

proc validate_ListBucketMetricsConfigurations_604132(path: JsonNode;
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
  var valid_604134 = path.getOrDefault("Bucket")
  valid_604134 = validateParameter(valid_604134, JString, required = true,
                                 default = nil)
  if valid_604134 != nil:
    section.add "Bucket", valid_604134
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_604135 = query.getOrDefault("metrics")
  valid_604135 = validateParameter(valid_604135, JBool, required = true, default = nil)
  if valid_604135 != nil:
    section.add "metrics", valid_604135
  var valid_604136 = query.getOrDefault("continuation-token")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "continuation-token", valid_604136
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604137 = header.getOrDefault("x-amz-security-token")
  valid_604137 = validateParameter(valid_604137, JString, required = false,
                                 default = nil)
  if valid_604137 != nil:
    section.add "x-amz-security-token", valid_604137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604138: Call_ListBucketMetricsConfigurations_604131;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the metrics configurations for the bucket.
  ## 
  let valid = call_604138.validator(path, query, header, formData, body)
  let scheme = call_604138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604138.url(scheme.get, call_604138.host, call_604138.base,
                         call_604138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604138, url, valid)

proc call*(call_604139: Call_ListBucketMetricsConfigurations_604131; metrics: bool;
          Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketMetricsConfigurations
  ## Lists the metrics configurations for the bucket.
  ##   metrics: bool (required)
  ##   continuationToken: string
  ##                    : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configurations to retrieve.
  var path_604140 = newJObject()
  var query_604141 = newJObject()
  add(query_604141, "metrics", newJBool(metrics))
  add(query_604141, "continuation-token", newJString(continuationToken))
  add(path_604140, "Bucket", newJString(Bucket))
  result = call_604139.call(path_604140, query_604141, nil, nil, nil)

var listBucketMetricsConfigurations* = Call_ListBucketMetricsConfigurations_604131(
    name: "listBucketMetricsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics",
    validator: validate_ListBucketMetricsConfigurations_604132, base: "/",
    url: url_ListBucketMetricsConfigurations_604133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuckets_604142 = ref object of OpenApiRestCall_602466
proc url_ListBuckets_604144(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuckets_604143(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604145 = header.getOrDefault("x-amz-security-token")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "x-amz-security-token", valid_604145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604146: Call_ListBuckets_604142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  let valid = call_604146.validator(path, query, header, formData, body)
  let scheme = call_604146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604146.url(scheme.get, call_604146.host, call_604146.base,
                         call_604146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604146, url, valid)

proc call*(call_604147: Call_ListBuckets_604142): Recallable =
  ## listBuckets
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  result = call_604147.call(nil, nil, nil, nil, nil)

var listBuckets* = Call_ListBuckets_604142(name: "listBuckets",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com", route: "/",
                                        validator: validate_ListBuckets_604143,
                                        base: "/", url: url_ListBuckets_604144,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultipartUploads_604148 = ref object of OpenApiRestCall_602466
proc url_ListMultipartUploads_604150(protocol: Scheme; host: string; base: string;
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

proc validate_ListMultipartUploads_604149(path: JsonNode; query: JsonNode;
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
  var valid_604151 = path.getOrDefault("Bucket")
  valid_604151 = validateParameter(valid_604151, JString, required = true,
                                 default = nil)
  if valid_604151 != nil:
    section.add "Bucket", valid_604151
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
  var valid_604152 = query.getOrDefault("max-uploads")
  valid_604152 = validateParameter(valid_604152, JInt, required = false, default = nil)
  if valid_604152 != nil:
    section.add "max-uploads", valid_604152
  var valid_604153 = query.getOrDefault("key-marker")
  valid_604153 = validateParameter(valid_604153, JString, required = false,
                                 default = nil)
  if valid_604153 != nil:
    section.add "key-marker", valid_604153
  var valid_604154 = query.getOrDefault("encoding-type")
  valid_604154 = validateParameter(valid_604154, JString, required = false,
                                 default = newJString("url"))
  if valid_604154 != nil:
    section.add "encoding-type", valid_604154
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_604155 = query.getOrDefault("uploads")
  valid_604155 = validateParameter(valid_604155, JBool, required = true, default = nil)
  if valid_604155 != nil:
    section.add "uploads", valid_604155
  var valid_604156 = query.getOrDefault("MaxUploads")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "MaxUploads", valid_604156
  var valid_604157 = query.getOrDefault("delimiter")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "delimiter", valid_604157
  var valid_604158 = query.getOrDefault("prefix")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "prefix", valid_604158
  var valid_604159 = query.getOrDefault("upload-id-marker")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "upload-id-marker", valid_604159
  var valid_604160 = query.getOrDefault("KeyMarker")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "KeyMarker", valid_604160
  var valid_604161 = query.getOrDefault("UploadIdMarker")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "UploadIdMarker", valid_604161
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604162 = header.getOrDefault("x-amz-security-token")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "x-amz-security-token", valid_604162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604163: Call_ListMultipartUploads_604148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists in-progress multipart uploads.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
  let valid = call_604163.validator(path, query, header, formData, body)
  let scheme = call_604163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604163.url(scheme.get, call_604163.host, call_604163.base,
                         call_604163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604163, url, valid)

proc call*(call_604164: Call_ListMultipartUploads_604148; uploads: bool;
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
  var path_604165 = newJObject()
  var query_604166 = newJObject()
  add(query_604166, "max-uploads", newJInt(maxUploads))
  add(query_604166, "key-marker", newJString(keyMarker))
  add(query_604166, "encoding-type", newJString(encodingType))
  add(query_604166, "uploads", newJBool(uploads))
  add(query_604166, "MaxUploads", newJString(MaxUploads))
  add(query_604166, "delimiter", newJString(delimiter))
  add(path_604165, "Bucket", newJString(Bucket))
  add(query_604166, "prefix", newJString(prefix))
  add(query_604166, "upload-id-marker", newJString(uploadIdMarker))
  add(query_604166, "KeyMarker", newJString(KeyMarker))
  add(query_604166, "UploadIdMarker", newJString(UploadIdMarker))
  result = call_604164.call(path_604165, query_604166, nil, nil, nil)

var listMultipartUploads* = Call_ListMultipartUploads_604148(
    name: "listMultipartUploads", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#uploads",
    validator: validate_ListMultipartUploads_604149, base: "/",
    url: url_ListMultipartUploads_604150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectVersions_604167 = ref object of OpenApiRestCall_602466
proc url_ListObjectVersions_604169(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectVersions_604168(path: JsonNode; query: JsonNode;
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
  var valid_604170 = path.getOrDefault("Bucket")
  valid_604170 = validateParameter(valid_604170, JString, required = true,
                                 default = nil)
  if valid_604170 != nil:
    section.add "Bucket", valid_604170
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
  var valid_604171 = query.getOrDefault("key-marker")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "key-marker", valid_604171
  var valid_604172 = query.getOrDefault("max-keys")
  valid_604172 = validateParameter(valid_604172, JInt, required = false, default = nil)
  if valid_604172 != nil:
    section.add "max-keys", valid_604172
  var valid_604173 = query.getOrDefault("VersionIdMarker")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "VersionIdMarker", valid_604173
  assert query != nil,
        "query argument is necessary due to required `versions` field"
  var valid_604174 = query.getOrDefault("versions")
  valid_604174 = validateParameter(valid_604174, JBool, required = true, default = nil)
  if valid_604174 != nil:
    section.add "versions", valid_604174
  var valid_604175 = query.getOrDefault("encoding-type")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = newJString("url"))
  if valid_604175 != nil:
    section.add "encoding-type", valid_604175
  var valid_604176 = query.getOrDefault("version-id-marker")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "version-id-marker", valid_604176
  var valid_604177 = query.getOrDefault("delimiter")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "delimiter", valid_604177
  var valid_604178 = query.getOrDefault("prefix")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "prefix", valid_604178
  var valid_604179 = query.getOrDefault("MaxKeys")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "MaxKeys", valid_604179
  var valid_604180 = query.getOrDefault("KeyMarker")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "KeyMarker", valid_604180
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604181 = header.getOrDefault("x-amz-security-token")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "x-amz-security-token", valid_604181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604182: Call_ListObjectVersions_604167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about all of the versions of objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
  let valid = call_604182.validator(path, query, header, formData, body)
  let scheme = call_604182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604182.url(scheme.get, call_604182.host, call_604182.base,
                         call_604182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604182, url, valid)

proc call*(call_604183: Call_ListObjectVersions_604167; versions: bool;
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
  var path_604184 = newJObject()
  var query_604185 = newJObject()
  add(query_604185, "key-marker", newJString(keyMarker))
  add(query_604185, "max-keys", newJInt(maxKeys))
  add(query_604185, "VersionIdMarker", newJString(VersionIdMarker))
  add(query_604185, "versions", newJBool(versions))
  add(query_604185, "encoding-type", newJString(encodingType))
  add(query_604185, "version-id-marker", newJString(versionIdMarker))
  add(query_604185, "delimiter", newJString(delimiter))
  add(path_604184, "Bucket", newJString(Bucket))
  add(query_604185, "prefix", newJString(prefix))
  add(query_604185, "MaxKeys", newJString(MaxKeys))
  add(query_604185, "KeyMarker", newJString(KeyMarker))
  result = call_604183.call(path_604184, query_604185, nil, nil, nil)

var listObjectVersions* = Call_ListObjectVersions_604167(
    name: "listObjectVersions", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versions", validator: validate_ListObjectVersions_604168,
    base: "/", url: url_ListObjectVersions_604169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectsV2_604186 = ref object of OpenApiRestCall_602466
proc url_ListObjectsV2_604188(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectsV2_604187(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604189 = path.getOrDefault("Bucket")
  valid_604189 = validateParameter(valid_604189, JString, required = true,
                                 default = nil)
  if valid_604189 != nil:
    section.add "Bucket", valid_604189
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
  var valid_604190 = query.getOrDefault("list-type")
  valid_604190 = validateParameter(valid_604190, JString, required = true,
                                 default = newJString("2"))
  if valid_604190 != nil:
    section.add "list-type", valid_604190
  var valid_604191 = query.getOrDefault("max-keys")
  valid_604191 = validateParameter(valid_604191, JInt, required = false, default = nil)
  if valid_604191 != nil:
    section.add "max-keys", valid_604191
  var valid_604192 = query.getOrDefault("encoding-type")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = newJString("url"))
  if valid_604192 != nil:
    section.add "encoding-type", valid_604192
  var valid_604193 = query.getOrDefault("continuation-token")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "continuation-token", valid_604193
  var valid_604194 = query.getOrDefault("fetch-owner")
  valid_604194 = validateParameter(valid_604194, JBool, required = false, default = nil)
  if valid_604194 != nil:
    section.add "fetch-owner", valid_604194
  var valid_604195 = query.getOrDefault("delimiter")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "delimiter", valid_604195
  var valid_604196 = query.getOrDefault("start-after")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "start-after", valid_604196
  var valid_604197 = query.getOrDefault("ContinuationToken")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "ContinuationToken", valid_604197
  var valid_604198 = query.getOrDefault("prefix")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "prefix", valid_604198
  var valid_604199 = query.getOrDefault("MaxKeys")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "MaxKeys", valid_604199
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_604200 = header.getOrDefault("x-amz-security-token")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "x-amz-security-token", valid_604200
  var valid_604201 = header.getOrDefault("x-amz-request-payer")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = newJString("requester"))
  if valid_604201 != nil:
    section.add "x-amz-request-payer", valid_604201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604202: Call_ListObjectsV2_604186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. Note: ListObjectsV2 is the revised List Objects API and we recommend you use this revised API for new application development.
  ## 
  let valid = call_604202.validator(path, query, header, formData, body)
  let scheme = call_604202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604202.url(scheme.get, call_604202.host, call_604202.base,
                         call_604202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604202, url, valid)

proc call*(call_604203: Call_ListObjectsV2_604186; Bucket: string;
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
  var path_604204 = newJObject()
  var query_604205 = newJObject()
  add(query_604205, "list-type", newJString(listType))
  add(query_604205, "max-keys", newJInt(maxKeys))
  add(query_604205, "encoding-type", newJString(encodingType))
  add(query_604205, "continuation-token", newJString(continuationToken))
  add(query_604205, "fetch-owner", newJBool(fetchOwner))
  add(query_604205, "delimiter", newJString(delimiter))
  add(path_604204, "Bucket", newJString(Bucket))
  add(query_604205, "start-after", newJString(startAfter))
  add(query_604205, "ContinuationToken", newJString(ContinuationToken))
  add(query_604205, "prefix", newJString(prefix))
  add(query_604205, "MaxKeys", newJString(MaxKeys))
  result = call_604203.call(path_604204, query_604205, nil, nil, nil)

var listObjectsV2* = Call_ListObjectsV2_604186(name: "listObjectsV2",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#list-type=2", validator: validate_ListObjectsV2_604187,
    base: "/", url: url_ListObjectsV2_604188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreObject_604206 = ref object of OpenApiRestCall_602466
proc url_RestoreObject_604208(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreObject_604207(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604209 = path.getOrDefault("Key")
  valid_604209 = validateParameter(valid_604209, JString, required = true,
                                 default = nil)
  if valid_604209 != nil:
    section.add "Key", valid_604209
  var valid_604210 = path.getOrDefault("Bucket")
  valid_604210 = validateParameter(valid_604210, JString, required = true,
                                 default = nil)
  if valid_604210 != nil:
    section.add "Bucket", valid_604210
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   restore: JBool (required)
  section = newJObject()
  var valid_604211 = query.getOrDefault("versionId")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "versionId", valid_604211
  assert query != nil, "query argument is necessary due to required `restore` field"
  var valid_604212 = query.getOrDefault("restore")
  valid_604212 = validateParameter(valid_604212, JBool, required = true, default = nil)
  if valid_604212 != nil:
    section.add "restore", valid_604212
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_604213 = header.getOrDefault("x-amz-security-token")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "x-amz-security-token", valid_604213
  var valid_604214 = header.getOrDefault("x-amz-request-payer")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = newJString("requester"))
  if valid_604214 != nil:
    section.add "x-amz-request-payer", valid_604214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604216: Call_RestoreObject_604206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restores an archived copy of an object back into Amazon S3
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  let valid = call_604216.validator(path, query, header, formData, body)
  let scheme = call_604216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604216.url(scheme.get, call_604216.host, call_604216.base,
                         call_604216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604216, url, valid)

proc call*(call_604217: Call_RestoreObject_604206; Key: string; restore: bool;
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
  var path_604218 = newJObject()
  var query_604219 = newJObject()
  var body_604220 = newJObject()
  add(query_604219, "versionId", newJString(versionId))
  add(path_604218, "Key", newJString(Key))
  add(query_604219, "restore", newJBool(restore))
  add(path_604218, "Bucket", newJString(Bucket))
  if body != nil:
    body_604220 = body
  result = call_604217.call(path_604218, query_604219, nil, nil, body_604220)

var restoreObject* = Call_RestoreObject_604206(name: "restoreObject",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#restore", validator: validate_RestoreObject_604207,
    base: "/", url: url_RestoreObject_604208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SelectObjectContent_604221 = ref object of OpenApiRestCall_602466
proc url_SelectObjectContent_604223(protocol: Scheme; host: string; base: string;
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

proc validate_SelectObjectContent_604222(path: JsonNode; query: JsonNode;
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
  var valid_604224 = path.getOrDefault("Key")
  valid_604224 = validateParameter(valid_604224, JString, required = true,
                                 default = nil)
  if valid_604224 != nil:
    section.add "Key", valid_604224
  var valid_604225 = path.getOrDefault("Bucket")
  valid_604225 = validateParameter(valid_604225, JString, required = true,
                                 default = nil)
  if valid_604225 != nil:
    section.add "Bucket", valid_604225
  result.add "path", section
  ## parameters in `query` object:
  ##   select: JBool (required)
  ##   select-type: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `select` field"
  var valid_604226 = query.getOrDefault("select")
  valid_604226 = validateParameter(valid_604226, JBool, required = true, default = nil)
  if valid_604226 != nil:
    section.add "select", valid_604226
  var valid_604227 = query.getOrDefault("select-type")
  valid_604227 = validateParameter(valid_604227, JString, required = true,
                                 default = newJString("2"))
  if valid_604227 != nil:
    section.add "select-type", valid_604227
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
  var valid_604228 = header.getOrDefault("x-amz-security-token")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "x-amz-security-token", valid_604228
  var valid_604229 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_604229
  var valid_604230 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_604230
  var valid_604231 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_604231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604233: Call_SelectObjectContent_604221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ## 
  let valid = call_604233.validator(path, query, header, formData, body)
  let scheme = call_604233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604233.url(scheme.get, call_604233.host, call_604233.base,
                         call_604233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604233, url, valid)

proc call*(call_604234: Call_SelectObjectContent_604221; select: bool; Key: string;
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
  var path_604235 = newJObject()
  var query_604236 = newJObject()
  var body_604237 = newJObject()
  add(query_604236, "select", newJBool(select))
  add(path_604235, "Key", newJString(Key))
  add(path_604235, "Bucket", newJString(Bucket))
  if body != nil:
    body_604237 = body
  add(query_604236, "select-type", newJString(selectType))
  result = call_604234.call(path_604235, query_604236, nil, nil, body_604237)

var selectObjectContent* = Call_SelectObjectContent_604221(
    name: "selectObjectContent", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#select&select-type=2",
    validator: validate_SelectObjectContent_604222, base: "/",
    url: url_SelectObjectContent_604223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPart_604238 = ref object of OpenApiRestCall_602466
proc url_UploadPart_604240(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UploadPart_604239(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604241 = path.getOrDefault("Key")
  valid_604241 = validateParameter(valid_604241, JString, required = true,
                                 default = nil)
  if valid_604241 != nil:
    section.add "Key", valid_604241
  var valid_604242 = path.getOrDefault("Bucket")
  valid_604242 = validateParameter(valid_604242, JString, required = true,
                                 default = nil)
  if valid_604242 != nil:
    section.add "Bucket", valid_604242
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being uploaded.
  ##   partNumber: JInt (required)
  ##             : Part number of part being uploaded. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_604243 = query.getOrDefault("uploadId")
  valid_604243 = validateParameter(valid_604243, JString, required = true,
                                 default = nil)
  if valid_604243 != nil:
    section.add "uploadId", valid_604243
  var valid_604244 = query.getOrDefault("partNumber")
  valid_604244 = validateParameter(valid_604244, JInt, required = true, default = nil)
  if valid_604244 != nil:
    section.add "partNumber", valid_604244
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
  var valid_604245 = header.getOrDefault("x-amz-security-token")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "x-amz-security-token", valid_604245
  var valid_604246 = header.getOrDefault("Content-MD5")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "Content-MD5", valid_604246
  var valid_604247 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_604247
  var valid_604248 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_604248
  var valid_604249 = header.getOrDefault("Content-Length")
  valid_604249 = validateParameter(valid_604249, JInt, required = false, default = nil)
  if valid_604249 != nil:
    section.add "Content-Length", valid_604249
  var valid_604250 = header.getOrDefault("x-amz-request-payer")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = newJString("requester"))
  if valid_604250 != nil:
    section.add "x-amz-request-payer", valid_604250
  var valid_604251 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_604251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604253: Call_UploadPart_604238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  let valid = call_604253.validator(path, query, header, formData, body)
  let scheme = call_604253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604253.url(scheme.get, call_604253.host, call_604253.base,
                         call_604253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604253, url, valid)

proc call*(call_604254: Call_UploadPart_604238; uploadId: string; partNumber: int;
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
  var path_604255 = newJObject()
  var query_604256 = newJObject()
  var body_604257 = newJObject()
  add(query_604256, "uploadId", newJString(uploadId))
  add(query_604256, "partNumber", newJInt(partNumber))
  add(path_604255, "Key", newJString(Key))
  add(path_604255, "Bucket", newJString(Bucket))
  if body != nil:
    body_604257 = body
  result = call_604254.call(path_604255, query_604256, nil, nil, body_604257)

var uploadPart* = Call_UploadPart_604238(name: "uploadPart",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#partNumber&uploadId",
                                      validator: validate_UploadPart_604239,
                                      base: "/", url: url_UploadPart_604240,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPartCopy_604258 = ref object of OpenApiRestCall_602466
proc url_UploadPartCopy_604260(protocol: Scheme; host: string; base: string;
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

proc validate_UploadPartCopy_604259(path: JsonNode; query: JsonNode;
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
  var valid_604261 = path.getOrDefault("Key")
  valid_604261 = validateParameter(valid_604261, JString, required = true,
                                 default = nil)
  if valid_604261 != nil:
    section.add "Key", valid_604261
  var valid_604262 = path.getOrDefault("Bucket")
  valid_604262 = validateParameter(valid_604262, JString, required = true,
                                 default = nil)
  if valid_604262 != nil:
    section.add "Bucket", valid_604262
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being copied.
  ##   partNumber: JInt (required)
  ##             : Part number of part being copied. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_604263 = query.getOrDefault("uploadId")
  valid_604263 = validateParameter(valid_604263, JString, required = true,
                                 default = nil)
  if valid_604263 != nil:
    section.add "uploadId", valid_604263
  var valid_604264 = query.getOrDefault("partNumber")
  valid_604264 = validateParameter(valid_604264, JInt, required = true, default = nil)
  if valid_604264 != nil:
    section.add "partNumber", valid_604264
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
  var valid_604265 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_604265
  var valid_604266 = header.getOrDefault("x-amz-security-token")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "x-amz-security-token", valid_604266
  var valid_604267 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_604267
  var valid_604268 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_604268
  var valid_604269 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_604269 = validateParameter(valid_604269, JString, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_604269
  var valid_604270 = header.getOrDefault("x-amz-copy-source-range")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "x-amz-copy-source-range", valid_604270
  var valid_604271 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_604271
  var valid_604272 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_604272 = validateParameter(valid_604272, JString, required = false,
                                 default = nil)
  if valid_604272 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_604272
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_604273 = header.getOrDefault("x-amz-copy-source")
  valid_604273 = validateParameter(valid_604273, JString, required = true,
                                 default = nil)
  if valid_604273 != nil:
    section.add "x-amz-copy-source", valid_604273
  var valid_604274 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "x-amz-copy-source-if-match", valid_604274
  var valid_604275 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_604275 = validateParameter(valid_604275, JString, required = false,
                                 default = nil)
  if valid_604275 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_604275
  var valid_604276 = header.getOrDefault("x-amz-request-payer")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = newJString("requester"))
  if valid_604276 != nil:
    section.add "x-amz-request-payer", valid_604276
  var valid_604277 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_604277 = validateParameter(valid_604277, JString, required = false,
                                 default = nil)
  if valid_604277 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_604277
  var valid_604278 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_604278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604279: Call_UploadPartCopy_604258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads a part by copying data from an existing object as data source.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  let valid = call_604279.validator(path, query, header, formData, body)
  let scheme = call_604279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604279.url(scheme.get, call_604279.host, call_604279.base,
                         call_604279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604279, url, valid)

proc call*(call_604280: Call_UploadPartCopy_604258; uploadId: string;
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
  var path_604281 = newJObject()
  var query_604282 = newJObject()
  add(query_604282, "uploadId", newJString(uploadId))
  add(query_604282, "partNumber", newJInt(partNumber))
  add(path_604281, "Key", newJString(Key))
  add(path_604281, "Bucket", newJString(Bucket))
  result = call_604280.call(path_604281, query_604282, nil, nil, nil)

var uploadPartCopy* = Call_UploadPartCopy_604258(name: "uploadPartCopy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#x-amz-copy-source&partNumber&uploadId",
    validator: validate_UploadPartCopy_604259, base: "/", url: url_UploadPartCopy_604260,
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
