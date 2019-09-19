
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CompleteMultipartUpload_601053 = ref object of OpenApiRestCall_600426
proc url_CompleteMultipartUpload_601055(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CompleteMultipartUpload_601054(path: JsonNode; query: JsonNode;
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
  var valid_601056 = path.getOrDefault("Key")
  valid_601056 = validateParameter(valid_601056, JString, required = true,
                                 default = nil)
  if valid_601056 != nil:
    section.add "Key", valid_601056
  var valid_601057 = path.getOrDefault("Bucket")
  valid_601057 = validateParameter(valid_601057, JString, required = true,
                                 default = nil)
  if valid_601057 != nil:
    section.add "Bucket", valid_601057
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : <p/>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_601058 = query.getOrDefault("uploadId")
  valid_601058 = validateParameter(valid_601058, JString, required = true,
                                 default = nil)
  if valid_601058 != nil:
    section.add "uploadId", valid_601058
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601059 = header.getOrDefault("x-amz-security-token")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "x-amz-security-token", valid_601059
  var valid_601060 = header.getOrDefault("x-amz-request-payer")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = newJString("requester"))
  if valid_601060 != nil:
    section.add "x-amz-request-payer", valid_601060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601062: Call_CompleteMultipartUpload_601053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  let valid = call_601062.validator(path, query, header, formData, body)
  let scheme = call_601062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601062.url(scheme.get, call_601062.host, call_601062.base,
                         call_601062.route, valid.getOrDefault("path"))
  result = hook(call_601062, url, valid)

proc call*(call_601063: Call_CompleteMultipartUpload_601053; uploadId: string;
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
  var path_601064 = newJObject()
  var query_601065 = newJObject()
  var body_601066 = newJObject()
  add(query_601065, "uploadId", newJString(uploadId))
  add(path_601064, "Key", newJString(Key))
  add(path_601064, "Bucket", newJString(Bucket))
  if body != nil:
    body_601066 = body
  result = call_601063.call(path_601064, query_601065, nil, nil, body_601066)

var completeMultipartUpload* = Call_CompleteMultipartUpload_601053(
    name: "completeMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_CompleteMultipartUpload_601054, base: "/",
    url: url_CompleteMultipartUpload_601055, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParts_600768 = ref object of OpenApiRestCall_600426
proc url_ListParts_600770(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListParts_600769(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600896 = path.getOrDefault("Key")
  valid_600896 = validateParameter(valid_600896, JString, required = true,
                                 default = nil)
  if valid_600896 != nil:
    section.add "Key", valid_600896
  var valid_600897 = path.getOrDefault("Bucket")
  valid_600897 = validateParameter(valid_600897, JString, required = true,
                                 default = nil)
  if valid_600897 != nil:
    section.add "Bucket", valid_600897
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
  var valid_600898 = query.getOrDefault("max-parts")
  valid_600898 = validateParameter(valid_600898, JInt, required = false, default = nil)
  if valid_600898 != nil:
    section.add "max-parts", valid_600898
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_600899 = query.getOrDefault("uploadId")
  valid_600899 = validateParameter(valid_600899, JString, required = true,
                                 default = nil)
  if valid_600899 != nil:
    section.add "uploadId", valid_600899
  var valid_600900 = query.getOrDefault("MaxParts")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "MaxParts", valid_600900
  var valid_600901 = query.getOrDefault("part-number-marker")
  valid_600901 = validateParameter(valid_600901, JInt, required = false, default = nil)
  if valid_600901 != nil:
    section.add "part-number-marker", valid_600901
  var valid_600902 = query.getOrDefault("PartNumberMarker")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "PartNumberMarker", valid_600902
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_600903 = header.getOrDefault("x-amz-security-token")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "x-amz-security-token", valid_600903
  var valid_600917 = header.getOrDefault("x-amz-request-payer")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = newJString("requester"))
  if valid_600917 != nil:
    section.add "x-amz-request-payer", valid_600917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600940: Call_ListParts_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  let valid = call_600940.validator(path, query, header, formData, body)
  let scheme = call_600940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600940.url(scheme.get, call_600940.host, call_600940.base,
                         call_600940.route, valid.getOrDefault("path"))
  result = hook(call_600940, url, valid)

proc call*(call_601011: Call_ListParts_600768; uploadId: string; Key: string;
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
  var path_601012 = newJObject()
  var query_601014 = newJObject()
  add(query_601014, "max-parts", newJInt(maxParts))
  add(query_601014, "uploadId", newJString(uploadId))
  add(query_601014, "MaxParts", newJString(MaxParts))
  add(query_601014, "part-number-marker", newJInt(partNumberMarker))
  add(query_601014, "PartNumberMarker", newJString(PartNumberMarker))
  add(path_601012, "Key", newJString(Key))
  add(path_601012, "Bucket", newJString(Bucket))
  result = call_601011.call(path_601012, query_601014, nil, nil, nil)

var listParts* = Call_ListParts_600768(name: "listParts", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}#uploadId",
                                    validator: validate_ListParts_600769,
                                    base: "/", url: url_ListParts_600770,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortMultipartUpload_601067 = ref object of OpenApiRestCall_600426
proc url_AbortMultipartUpload_601069(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_AbortMultipartUpload_601068(path: JsonNode; query: JsonNode;
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
  var valid_601070 = path.getOrDefault("Key")
  valid_601070 = validateParameter(valid_601070, JString, required = true,
                                 default = nil)
  if valid_601070 != nil:
    section.add "Key", valid_601070
  var valid_601071 = path.getOrDefault("Bucket")
  valid_601071 = validateParameter(valid_601071, JString, required = true,
                                 default = nil)
  if valid_601071 != nil:
    section.add "Bucket", valid_601071
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID that identifies the multipart upload.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_601072 = query.getOrDefault("uploadId")
  valid_601072 = validateParameter(valid_601072, JString, required = true,
                                 default = nil)
  if valid_601072 != nil:
    section.add "uploadId", valid_601072
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601073 = header.getOrDefault("x-amz-security-token")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "x-amz-security-token", valid_601073
  var valid_601074 = header.getOrDefault("x-amz-request-payer")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = newJString("requester"))
  if valid_601074 != nil:
    section.add "x-amz-request-payer", valid_601074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601075: Call_AbortMultipartUpload_601067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  let valid = call_601075.validator(path, query, header, formData, body)
  let scheme = call_601075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601075.url(scheme.get, call_601075.host, call_601075.base,
                         call_601075.route, valid.getOrDefault("path"))
  result = hook(call_601075, url, valid)

proc call*(call_601076: Call_AbortMultipartUpload_601067; uploadId: string;
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
  var path_601077 = newJObject()
  var query_601078 = newJObject()
  add(query_601078, "uploadId", newJString(uploadId))
  add(path_601077, "Key", newJString(Key))
  add(path_601077, "Bucket", newJString(Bucket))
  result = call_601076.call(path_601077, query_601078, nil, nil, nil)

var abortMultipartUpload* = Call_AbortMultipartUpload_601067(
    name: "abortMultipartUpload", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_AbortMultipartUpload_601068, base: "/",
    url: url_AbortMultipartUpload_601069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyObject_601079 = ref object of OpenApiRestCall_600426
proc url_CopyObject_601081(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CopyObject_601080(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601082 = path.getOrDefault("Key")
  valid_601082 = validateParameter(valid_601082, JString, required = true,
                                 default = nil)
  if valid_601082 != nil:
    section.add "Key", valid_601082
  var valid_601083 = path.getOrDefault("Bucket")
  valid_601083 = validateParameter(valid_601083, JString, required = true,
                                 default = nil)
  if valid_601083 != nil:
    section.add "Bucket", valid_601083
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
  var valid_601084 = header.getOrDefault("Content-Disposition")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "Content-Disposition", valid_601084
  var valid_601085 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_601085
  var valid_601086 = header.getOrDefault("x-amz-grant-full-control")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "x-amz-grant-full-control", valid_601086
  var valid_601087 = header.getOrDefault("x-amz-security-token")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "x-amz-security-token", valid_601087
  var valid_601088 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_601088
  var valid_601089 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_601089
  var valid_601090 = header.getOrDefault("x-amz-tagging-directive")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = newJString("COPY"))
  if valid_601090 != nil:
    section.add "x-amz-tagging-directive", valid_601090
  var valid_601091 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_601091
  var valid_601092 = header.getOrDefault("x-amz-object-lock-mode")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_601092 != nil:
    section.add "x-amz-object-lock-mode", valid_601092
  var valid_601093 = header.getOrDefault("Cache-Control")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "Cache-Control", valid_601093
  var valid_601094 = header.getOrDefault("Content-Language")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "Content-Language", valid_601094
  var valid_601095 = header.getOrDefault("Content-Type")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "Content-Type", valid_601095
  var valid_601096 = header.getOrDefault("Expires")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "Expires", valid_601096
  var valid_601097 = header.getOrDefault("x-amz-website-redirect-location")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "x-amz-website-redirect-location", valid_601097
  var valid_601098 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_601098
  var valid_601099 = header.getOrDefault("x-amz-acl")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = newJString("private"))
  if valid_601099 != nil:
    section.add "x-amz-acl", valid_601099
  var valid_601100 = header.getOrDefault("x-amz-grant-read")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "x-amz-grant-read", valid_601100
  var valid_601101 = header.getOrDefault("x-amz-storage-class")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_601101 != nil:
    section.add "x-amz-storage-class", valid_601101
  var valid_601102 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = newJString("ON"))
  if valid_601102 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_601102
  var valid_601103 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_601103
  var valid_601104 = header.getOrDefault("x-amz-tagging")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "x-amz-tagging", valid_601104
  var valid_601105 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "x-amz-grant-read-acp", valid_601105
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_601106 = header.getOrDefault("x-amz-copy-source")
  valid_601106 = validateParameter(valid_601106, JString, required = true,
                                 default = nil)
  if valid_601106 != nil:
    section.add "x-amz-copy-source", valid_601106
  var valid_601107 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "x-amz-server-side-encryption-context", valid_601107
  var valid_601108 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_601108
  var valid_601109 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_601109
  var valid_601110 = header.getOrDefault("x-amz-metadata-directive")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = newJString("COPY"))
  if valid_601110 != nil:
    section.add "x-amz-metadata-directive", valid_601110
  var valid_601111 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "x-amz-copy-source-if-match", valid_601111
  var valid_601112 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_601112
  var valid_601113 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "x-amz-grant-write-acp", valid_601113
  var valid_601114 = header.getOrDefault("Content-Encoding")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "Content-Encoding", valid_601114
  var valid_601115 = header.getOrDefault("x-amz-request-payer")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = newJString("requester"))
  if valid_601115 != nil:
    section.add "x-amz-request-payer", valid_601115
  var valid_601116 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_601116
  var valid_601117 = header.getOrDefault("x-amz-server-side-encryption")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = newJString("AES256"))
  if valid_601117 != nil:
    section.add "x-amz-server-side-encryption", valid_601117
  var valid_601118 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_601118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601120: Call_CopyObject_601079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  let valid = call_601120.validator(path, query, header, formData, body)
  let scheme = call_601120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601120.url(scheme.get, call_601120.host, call_601120.base,
                         call_601120.route, valid.getOrDefault("path"))
  result = hook(call_601120, url, valid)

proc call*(call_601121: Call_CopyObject_601079; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## copyObject
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601122 = newJObject()
  var body_601123 = newJObject()
  add(path_601122, "Key", newJString(Key))
  add(path_601122, "Bucket", newJString(Bucket))
  if body != nil:
    body_601123 = body
  result = call_601121.call(path_601122, nil, nil, nil, body_601123)

var copyObject* = Call_CopyObject_601079(name: "copyObject",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#x-amz-copy-source",
                                      validator: validate_CopyObject_601080,
                                      base: "/", url: url_CopyObject_601081,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBucket_601141 = ref object of OpenApiRestCall_600426
proc url_CreateBucket_601143(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateBucket_601142(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601144 = path.getOrDefault("Bucket")
  valid_601144 = validateParameter(valid_601144, JString, required = true,
                                 default = nil)
  if valid_601144 != nil:
    section.add "Bucket", valid_601144
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
  var valid_601145 = header.getOrDefault("x-amz-security-token")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "x-amz-security-token", valid_601145
  var valid_601146 = header.getOrDefault("x-amz-acl")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = newJString("private"))
  if valid_601146 != nil:
    section.add "x-amz-acl", valid_601146
  var valid_601147 = header.getOrDefault("x-amz-grant-read")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "x-amz-grant-read", valid_601147
  var valid_601148 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "x-amz-grant-read-acp", valid_601148
  var valid_601149 = header.getOrDefault("x-amz-bucket-object-lock-enabled")
  valid_601149 = validateParameter(valid_601149, JBool, required = false, default = nil)
  if valid_601149 != nil:
    section.add "x-amz-bucket-object-lock-enabled", valid_601149
  var valid_601150 = header.getOrDefault("x-amz-grant-write")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "x-amz-grant-write", valid_601150
  var valid_601151 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "x-amz-grant-write-acp", valid_601151
  var valid_601152 = header.getOrDefault("x-amz-grant-full-control")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "x-amz-grant-full-control", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_CreateBucket_601141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_CreateBucket_601141; Bucket: string; body: JsonNode): Recallable =
  ## createBucket
  ## Creates a new bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601156 = newJObject()
  var body_601157 = newJObject()
  add(path_601156, "Bucket", newJString(Bucket))
  if body != nil:
    body_601157 = body
  result = call_601155.call(path_601156, nil, nil, nil, body_601157)

var createBucket* = Call_CreateBucket_601141(name: "createBucket",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_CreateBucket_601142, base: "/", url: url_CreateBucket_601143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadBucket_601166 = ref object of OpenApiRestCall_600426
proc url_HeadBucket_601168(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_HeadBucket_601167(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601169 = path.getOrDefault("Bucket")
  valid_601169 = validateParameter(valid_601169, JString, required = true,
                                 default = nil)
  if valid_601169 != nil:
    section.add "Bucket", valid_601169
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601170 = header.getOrDefault("x-amz-security-token")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "x-amz-security-token", valid_601170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601171: Call_HeadBucket_601166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  let valid = call_601171.validator(path, query, header, formData, body)
  let scheme = call_601171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601171.url(scheme.get, call_601171.host, call_601171.base,
                         call_601171.route, valid.getOrDefault("path"))
  result = hook(call_601171, url, valid)

proc call*(call_601172: Call_HeadBucket_601166; Bucket: string): Recallable =
  ## headBucket
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601173 = newJObject()
  add(path_601173, "Bucket", newJString(Bucket))
  result = call_601172.call(path_601173, nil, nil, nil, nil)

var headBucket* = Call_HeadBucket_601166(name: "headBucket",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}",
                                      validator: validate_HeadBucket_601167,
                                      base: "/", url: url_HeadBucket_601168,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjects_601124 = ref object of OpenApiRestCall_600426
proc url_ListObjects_601126(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListObjects_601125(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601127 = path.getOrDefault("Bucket")
  valid_601127 = validateParameter(valid_601127, JString, required = true,
                                 default = nil)
  if valid_601127 != nil:
    section.add "Bucket", valid_601127
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
  var valid_601128 = query.getOrDefault("max-keys")
  valid_601128 = validateParameter(valid_601128, JInt, required = false, default = nil)
  if valid_601128 != nil:
    section.add "max-keys", valid_601128
  var valid_601129 = query.getOrDefault("encoding-type")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = newJString("url"))
  if valid_601129 != nil:
    section.add "encoding-type", valid_601129
  var valid_601130 = query.getOrDefault("marker")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "marker", valid_601130
  var valid_601131 = query.getOrDefault("Marker")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "Marker", valid_601131
  var valid_601132 = query.getOrDefault("delimiter")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "delimiter", valid_601132
  var valid_601133 = query.getOrDefault("prefix")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "prefix", valid_601133
  var valid_601134 = query.getOrDefault("MaxKeys")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "MaxKeys", valid_601134
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601135 = header.getOrDefault("x-amz-security-token")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "x-amz-security-token", valid_601135
  var valid_601136 = header.getOrDefault("x-amz-request-payer")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = newJString("requester"))
  if valid_601136 != nil:
    section.add "x-amz-request-payer", valid_601136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601137: Call_ListObjects_601124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
  let valid = call_601137.validator(path, query, header, formData, body)
  let scheme = call_601137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601137.url(scheme.get, call_601137.host, call_601137.base,
                         call_601137.route, valid.getOrDefault("path"))
  result = hook(call_601137, url, valid)

proc call*(call_601138: Call_ListObjects_601124; Bucket: string; maxKeys: int = 0;
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
  var path_601139 = newJObject()
  var query_601140 = newJObject()
  add(query_601140, "max-keys", newJInt(maxKeys))
  add(query_601140, "encoding-type", newJString(encodingType))
  add(query_601140, "marker", newJString(marker))
  add(query_601140, "Marker", newJString(Marker))
  add(query_601140, "delimiter", newJString(delimiter))
  add(path_601139, "Bucket", newJString(Bucket))
  add(query_601140, "prefix", newJString(prefix))
  add(query_601140, "MaxKeys", newJString(MaxKeys))
  result = call_601138.call(path_601139, query_601140, nil, nil, nil)

var listObjects* = Call_ListObjects_601124(name: "listObjects",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com",
                                        route: "/{Bucket}",
                                        validator: validate_ListObjects_601125,
                                        base: "/", url: url_ListObjects_601126,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucket_601158 = ref object of OpenApiRestCall_600426
proc url_DeleteBucket_601160(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBucket_601159(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601161 = path.getOrDefault("Bucket")
  valid_601161 = validateParameter(valid_601161, JString, required = true,
                                 default = nil)
  if valid_601161 != nil:
    section.add "Bucket", valid_601161
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601162 = header.getOrDefault("x-amz-security-token")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "x-amz-security-token", valid_601162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601163: Call_DeleteBucket_601158; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  let valid = call_601163.validator(path, query, header, formData, body)
  let scheme = call_601163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601163.url(scheme.get, call_601163.host, call_601163.base,
                         call_601163.route, valid.getOrDefault("path"))
  result = hook(call_601163, url, valid)

proc call*(call_601164: Call_DeleteBucket_601158; Bucket: string): Recallable =
  ## deleteBucket
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601165 = newJObject()
  add(path_601165, "Bucket", newJString(Bucket))
  result = call_601164.call(path_601165, nil, nil, nil, nil)

var deleteBucket* = Call_DeleteBucket_601158(name: "deleteBucket",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_DeleteBucket_601159, base: "/", url: url_DeleteBucket_601160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultipartUpload_601174 = ref object of OpenApiRestCall_600426
proc url_CreateMultipartUpload_601176(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateMultipartUpload_601175(path: JsonNode; query: JsonNode;
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
  var valid_601177 = path.getOrDefault("Key")
  valid_601177 = validateParameter(valid_601177, JString, required = true,
                                 default = nil)
  if valid_601177 != nil:
    section.add "Key", valid_601177
  var valid_601178 = path.getOrDefault("Bucket")
  valid_601178 = validateParameter(valid_601178, JString, required = true,
                                 default = nil)
  if valid_601178 != nil:
    section.add "Bucket", valid_601178
  result.add "path", section
  ## parameters in `query` object:
  ##   uploads: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_601179 = query.getOrDefault("uploads")
  valid_601179 = validateParameter(valid_601179, JBool, required = true, default = nil)
  if valid_601179 != nil:
    section.add "uploads", valid_601179
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
  var valid_601180 = header.getOrDefault("Content-Disposition")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "Content-Disposition", valid_601180
  var valid_601181 = header.getOrDefault("x-amz-grant-full-control")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "x-amz-grant-full-control", valid_601181
  var valid_601182 = header.getOrDefault("x-amz-security-token")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "x-amz-security-token", valid_601182
  var valid_601183 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_601183
  var valid_601184 = header.getOrDefault("x-amz-object-lock-mode")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_601184 != nil:
    section.add "x-amz-object-lock-mode", valid_601184
  var valid_601185 = header.getOrDefault("Cache-Control")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "Cache-Control", valid_601185
  var valid_601186 = header.getOrDefault("Content-Language")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "Content-Language", valid_601186
  var valid_601187 = header.getOrDefault("Content-Type")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "Content-Type", valid_601187
  var valid_601188 = header.getOrDefault("Expires")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "Expires", valid_601188
  var valid_601189 = header.getOrDefault("x-amz-website-redirect-location")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "x-amz-website-redirect-location", valid_601189
  var valid_601190 = header.getOrDefault("x-amz-acl")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = newJString("private"))
  if valid_601190 != nil:
    section.add "x-amz-acl", valid_601190
  var valid_601191 = header.getOrDefault("x-amz-grant-read")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "x-amz-grant-read", valid_601191
  var valid_601192 = header.getOrDefault("x-amz-storage-class")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_601192 != nil:
    section.add "x-amz-storage-class", valid_601192
  var valid_601193 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = newJString("ON"))
  if valid_601193 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_601193
  var valid_601194 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_601194
  var valid_601195 = header.getOrDefault("x-amz-tagging")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "x-amz-tagging", valid_601195
  var valid_601196 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "x-amz-grant-read-acp", valid_601196
  var valid_601197 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "x-amz-server-side-encryption-context", valid_601197
  var valid_601198 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_601198
  var valid_601199 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_601199
  var valid_601200 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "x-amz-grant-write-acp", valid_601200
  var valid_601201 = header.getOrDefault("Content-Encoding")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "Content-Encoding", valid_601201
  var valid_601202 = header.getOrDefault("x-amz-request-payer")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = newJString("requester"))
  if valid_601202 != nil:
    section.add "x-amz-request-payer", valid_601202
  var valid_601203 = header.getOrDefault("x-amz-server-side-encryption")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = newJString("AES256"))
  if valid_601203 != nil:
    section.add "x-amz-server-side-encryption", valid_601203
  var valid_601204 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_601204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601206: Call_CreateMultipartUpload_601174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  let valid = call_601206.validator(path, query, header, formData, body)
  let scheme = call_601206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601206.url(scheme.get, call_601206.host, call_601206.base,
                         call_601206.route, valid.getOrDefault("path"))
  result = hook(call_601206, url, valid)

proc call*(call_601207: Call_CreateMultipartUpload_601174; Key: string;
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
  var path_601208 = newJObject()
  var query_601209 = newJObject()
  var body_601210 = newJObject()
  add(path_601208, "Key", newJString(Key))
  add(query_601209, "uploads", newJBool(uploads))
  add(path_601208, "Bucket", newJString(Bucket))
  if body != nil:
    body_601210 = body
  result = call_601207.call(path_601208, query_601209, nil, nil, body_601210)

var createMultipartUpload* = Call_CreateMultipartUpload_601174(
    name: "createMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploads",
    validator: validate_CreateMultipartUpload_601175, base: "/",
    url: url_CreateMultipartUpload_601176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAnalyticsConfiguration_601222 = ref object of OpenApiRestCall_600426
proc url_PutBucketAnalyticsConfiguration_601224(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#analytics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketAnalyticsConfiguration_601223(path: JsonNode;
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
  var valid_601225 = path.getOrDefault("Bucket")
  valid_601225 = validateParameter(valid_601225, JString, required = true,
                                 default = nil)
  if valid_601225 != nil:
    section.add "Bucket", valid_601225
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601226 = query.getOrDefault("id")
  valid_601226 = validateParameter(valid_601226, JString, required = true,
                                 default = nil)
  if valid_601226 != nil:
    section.add "id", valid_601226
  var valid_601227 = query.getOrDefault("analytics")
  valid_601227 = validateParameter(valid_601227, JBool, required = true, default = nil)
  if valid_601227 != nil:
    section.add "analytics", valid_601227
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601228 = header.getOrDefault("x-amz-security-token")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "x-amz-security-token", valid_601228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601230: Call_PutBucketAnalyticsConfiguration_601222;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_601230.validator(path, query, header, formData, body)
  let scheme = call_601230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601230.url(scheme.get, call_601230.host, call_601230.base,
                         call_601230.route, valid.getOrDefault("path"))
  result = hook(call_601230, url, valid)

proc call*(call_601231: Call_PutBucketAnalyticsConfiguration_601222; id: string;
          analytics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAnalyticsConfiguration
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket to which an analytics configuration is stored.
  ##   body: JObject (required)
  var path_601232 = newJObject()
  var query_601233 = newJObject()
  var body_601234 = newJObject()
  add(query_601233, "id", newJString(id))
  add(query_601233, "analytics", newJBool(analytics))
  add(path_601232, "Bucket", newJString(Bucket))
  if body != nil:
    body_601234 = body
  result = call_601231.call(path_601232, query_601233, nil, nil, body_601234)

var putBucketAnalyticsConfiguration* = Call_PutBucketAnalyticsConfiguration_601222(
    name: "putBucketAnalyticsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_PutBucketAnalyticsConfiguration_601223, base: "/",
    url: url_PutBucketAnalyticsConfiguration_601224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAnalyticsConfiguration_601211 = ref object of OpenApiRestCall_600426
proc url_GetBucketAnalyticsConfiguration_601213(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#analytics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketAnalyticsConfiguration_601212(path: JsonNode;
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
  var valid_601214 = path.getOrDefault("Bucket")
  valid_601214 = validateParameter(valid_601214, JString, required = true,
                                 default = nil)
  if valid_601214 != nil:
    section.add "Bucket", valid_601214
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601215 = query.getOrDefault("id")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = nil)
  if valid_601215 != nil:
    section.add "id", valid_601215
  var valid_601216 = query.getOrDefault("analytics")
  valid_601216 = validateParameter(valid_601216, JBool, required = true, default = nil)
  if valid_601216 != nil:
    section.add "analytics", valid_601216
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601217 = header.getOrDefault("x-amz-security-token")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "x-amz-security-token", valid_601217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601218: Call_GetBucketAnalyticsConfiguration_601211;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_601218.validator(path, query, header, formData, body)
  let scheme = call_601218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601218.url(scheme.get, call_601218.host, call_601218.base,
                         call_601218.route, valid.getOrDefault("path"))
  result = hook(call_601218, url, valid)

proc call*(call_601219: Call_GetBucketAnalyticsConfiguration_601211; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## getBucketAnalyticsConfiguration
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is retrieved.
  var path_601220 = newJObject()
  var query_601221 = newJObject()
  add(query_601221, "id", newJString(id))
  add(query_601221, "analytics", newJBool(analytics))
  add(path_601220, "Bucket", newJString(Bucket))
  result = call_601219.call(path_601220, query_601221, nil, nil, nil)

var getBucketAnalyticsConfiguration* = Call_GetBucketAnalyticsConfiguration_601211(
    name: "getBucketAnalyticsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_GetBucketAnalyticsConfiguration_601212, base: "/",
    url: url_GetBucketAnalyticsConfiguration_601213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketAnalyticsConfiguration_601235 = ref object of OpenApiRestCall_600426
proc url_DeleteBucketAnalyticsConfiguration_601237(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#analytics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBucketAnalyticsConfiguration_601236(path: JsonNode;
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
  var valid_601238 = path.getOrDefault("Bucket")
  valid_601238 = validateParameter(valid_601238, JString, required = true,
                                 default = nil)
  if valid_601238 != nil:
    section.add "Bucket", valid_601238
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601239 = query.getOrDefault("id")
  valid_601239 = validateParameter(valid_601239, JString, required = true,
                                 default = nil)
  if valid_601239 != nil:
    section.add "id", valid_601239
  var valid_601240 = query.getOrDefault("analytics")
  valid_601240 = validateParameter(valid_601240, JBool, required = true, default = nil)
  if valid_601240 != nil:
    section.add "analytics", valid_601240
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601241 = header.getOrDefault("x-amz-security-token")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "x-amz-security-token", valid_601241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601242: Call_DeleteBucketAnalyticsConfiguration_601235;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ## 
  let valid = call_601242.validator(path, query, header, formData, body)
  let scheme = call_601242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601242.url(scheme.get, call_601242.host, call_601242.base,
                         call_601242.route, valid.getOrDefault("path"))
  result = hook(call_601242, url, valid)

proc call*(call_601243: Call_DeleteBucketAnalyticsConfiguration_601235; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## deleteBucketAnalyticsConfiguration
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is deleted.
  var path_601244 = newJObject()
  var query_601245 = newJObject()
  add(query_601245, "id", newJString(id))
  add(query_601245, "analytics", newJBool(analytics))
  add(path_601244, "Bucket", newJString(Bucket))
  result = call_601243.call(path_601244, query_601245, nil, nil, nil)

var deleteBucketAnalyticsConfiguration* = Call_DeleteBucketAnalyticsConfiguration_601235(
    name: "deleteBucketAnalyticsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_DeleteBucketAnalyticsConfiguration_601236, base: "/",
    url: url_DeleteBucketAnalyticsConfiguration_601237,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketCors_601256 = ref object of OpenApiRestCall_600426
proc url_PutBucketCors_601258(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#cors")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketCors_601257(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601259 = path.getOrDefault("Bucket")
  valid_601259 = validateParameter(valid_601259, JString, required = true,
                                 default = nil)
  if valid_601259 != nil:
    section.add "Bucket", valid_601259
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_601260 = query.getOrDefault("cors")
  valid_601260 = validateParameter(valid_601260, JBool, required = true, default = nil)
  if valid_601260 != nil:
    section.add "cors", valid_601260
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601261 = header.getOrDefault("x-amz-security-token")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "x-amz-security-token", valid_601261
  var valid_601262 = header.getOrDefault("Content-MD5")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "Content-MD5", valid_601262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601264: Call_PutBucketCors_601256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the CORS configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  let valid = call_601264.validator(path, query, header, formData, body)
  let scheme = call_601264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601264.url(scheme.get, call_601264.host, call_601264.base,
                         call_601264.route, valid.getOrDefault("path"))
  result = hook(call_601264, url, valid)

proc call*(call_601265: Call_PutBucketCors_601256; cors: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketCors
  ## Sets the CORS configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601266 = newJObject()
  var query_601267 = newJObject()
  var body_601268 = newJObject()
  add(query_601267, "cors", newJBool(cors))
  add(path_601266, "Bucket", newJString(Bucket))
  if body != nil:
    body_601268 = body
  result = call_601265.call(path_601266, query_601267, nil, nil, body_601268)

var putBucketCors* = Call_PutBucketCors_601256(name: "putBucketCors",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_PutBucketCors_601257, base: "/", url: url_PutBucketCors_601258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketCors_601246 = ref object of OpenApiRestCall_600426
proc url_GetBucketCors_601248(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#cors")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketCors_601247(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601249 = path.getOrDefault("Bucket")
  valid_601249 = validateParameter(valid_601249, JString, required = true,
                                 default = nil)
  if valid_601249 != nil:
    section.add "Bucket", valid_601249
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_601250 = query.getOrDefault("cors")
  valid_601250 = validateParameter(valid_601250, JBool, required = true, default = nil)
  if valid_601250 != nil:
    section.add "cors", valid_601250
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601251 = header.getOrDefault("x-amz-security-token")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "x-amz-security-token", valid_601251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601252: Call_GetBucketCors_601246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the CORS configuration for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  let valid = call_601252.validator(path, query, header, formData, body)
  let scheme = call_601252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601252.url(scheme.get, call_601252.host, call_601252.base,
                         call_601252.route, valid.getOrDefault("path"))
  result = hook(call_601252, url, valid)

proc call*(call_601253: Call_GetBucketCors_601246; cors: bool; Bucket: string): Recallable =
  ## getBucketCors
  ## Returns the CORS configuration for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601254 = newJObject()
  var query_601255 = newJObject()
  add(query_601255, "cors", newJBool(cors))
  add(path_601254, "Bucket", newJString(Bucket))
  result = call_601253.call(path_601254, query_601255, nil, nil, nil)

var getBucketCors* = Call_GetBucketCors_601246(name: "getBucketCors",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_GetBucketCors_601247, base: "/", url: url_GetBucketCors_601248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketCors_601269 = ref object of OpenApiRestCall_600426
proc url_DeleteBucketCors_601271(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#cors")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBucketCors_601270(path: JsonNode; query: JsonNode;
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
  var valid_601272 = path.getOrDefault("Bucket")
  valid_601272 = validateParameter(valid_601272, JString, required = true,
                                 default = nil)
  if valid_601272 != nil:
    section.add "Bucket", valid_601272
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_601273 = query.getOrDefault("cors")
  valid_601273 = validateParameter(valid_601273, JBool, required = true, default = nil)
  if valid_601273 != nil:
    section.add "cors", valid_601273
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601274 = header.getOrDefault("x-amz-security-token")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "x-amz-security-token", valid_601274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601275: Call_DeleteBucketCors_601269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the CORS configuration information set for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  let valid = call_601275.validator(path, query, header, formData, body)
  let scheme = call_601275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601275.url(scheme.get, call_601275.host, call_601275.base,
                         call_601275.route, valid.getOrDefault("path"))
  result = hook(call_601275, url, valid)

proc call*(call_601276: Call_DeleteBucketCors_601269; cors: bool; Bucket: string): Recallable =
  ## deleteBucketCors
  ## Deletes the CORS configuration information set for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601277 = newJObject()
  var query_601278 = newJObject()
  add(query_601278, "cors", newJBool(cors))
  add(path_601277, "Bucket", newJString(Bucket))
  result = call_601276.call(path_601277, query_601278, nil, nil, nil)

var deleteBucketCors* = Call_DeleteBucketCors_601269(name: "deleteBucketCors",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_DeleteBucketCors_601270, base: "/",
    url: url_DeleteBucketCors_601271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketEncryption_601289 = ref object of OpenApiRestCall_600426
proc url_PutBucketEncryption_601291(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#encryption")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketEncryption_601290(path: JsonNode; query: JsonNode;
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
  var valid_601292 = path.getOrDefault("Bucket")
  valid_601292 = validateParameter(valid_601292, JString, required = true,
                                 default = nil)
  if valid_601292 != nil:
    section.add "Bucket", valid_601292
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_601293 = query.getOrDefault("encryption")
  valid_601293 = validateParameter(valid_601293, JBool, required = true, default = nil)
  if valid_601293 != nil:
    section.add "encryption", valid_601293
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the server-side encryption configuration. This parameter is auto-populated when using the command from the CLI.
  section = newJObject()
  var valid_601294 = header.getOrDefault("x-amz-security-token")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "x-amz-security-token", valid_601294
  var valid_601295 = header.getOrDefault("Content-MD5")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "Content-MD5", valid_601295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601297: Call_PutBucketEncryption_601289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ## 
  let valid = call_601297.validator(path, query, header, formData, body)
  let scheme = call_601297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601297.url(scheme.get, call_601297.host, call_601297.base,
                         call_601297.route, valid.getOrDefault("path"))
  result = hook(call_601297, url, valid)

proc call*(call_601298: Call_PutBucketEncryption_601289; encryption: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketEncryption
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : Specifies default encryption for a bucket using server-side encryption with Amazon S3-managed keys (SSE-S3) or AWS KMS-managed keys (SSE-KMS). For information about the Amazon S3 default encryption feature, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 Default Bucket Encryption</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   body: JObject (required)
  var path_601299 = newJObject()
  var query_601300 = newJObject()
  var body_601301 = newJObject()
  add(query_601300, "encryption", newJBool(encryption))
  add(path_601299, "Bucket", newJString(Bucket))
  if body != nil:
    body_601301 = body
  result = call_601298.call(path_601299, query_601300, nil, nil, body_601301)

var putBucketEncryption* = Call_PutBucketEncryption_601289(
    name: "putBucketEncryption", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_PutBucketEncryption_601290,
    base: "/", url: url_PutBucketEncryption_601291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketEncryption_601279 = ref object of OpenApiRestCall_600426
proc url_GetBucketEncryption_601281(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#encryption")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketEncryption_601280(path: JsonNode; query: JsonNode;
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
  var valid_601282 = path.getOrDefault("Bucket")
  valid_601282 = validateParameter(valid_601282, JString, required = true,
                                 default = nil)
  if valid_601282 != nil:
    section.add "Bucket", valid_601282
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_601283 = query.getOrDefault("encryption")
  valid_601283 = validateParameter(valid_601283, JBool, required = true, default = nil)
  if valid_601283 != nil:
    section.add "encryption", valid_601283
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601284 = header.getOrDefault("x-amz-security-token")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "x-amz-security-token", valid_601284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601285: Call_GetBucketEncryption_601279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the server-side encryption configuration of a bucket.
  ## 
  let valid = call_601285.validator(path, query, header, formData, body)
  let scheme = call_601285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601285.url(scheme.get, call_601285.host, call_601285.base,
                         call_601285.route, valid.getOrDefault("path"))
  result = hook(call_601285, url, valid)

proc call*(call_601286: Call_GetBucketEncryption_601279; encryption: bool;
          Bucket: string): Recallable =
  ## getBucketEncryption
  ## Returns the server-side encryption configuration of a bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which the server-side encryption configuration is retrieved.
  var path_601287 = newJObject()
  var query_601288 = newJObject()
  add(query_601288, "encryption", newJBool(encryption))
  add(path_601287, "Bucket", newJString(Bucket))
  result = call_601286.call(path_601287, query_601288, nil, nil, nil)

var getBucketEncryption* = Call_GetBucketEncryption_601279(
    name: "getBucketEncryption", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_GetBucketEncryption_601280,
    base: "/", url: url_GetBucketEncryption_601281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketEncryption_601302 = ref object of OpenApiRestCall_600426
proc url_DeleteBucketEncryption_601304(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#encryption")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBucketEncryption_601303(path: JsonNode; query: JsonNode;
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
  var valid_601305 = path.getOrDefault("Bucket")
  valid_601305 = validateParameter(valid_601305, JString, required = true,
                                 default = nil)
  if valid_601305 != nil:
    section.add "Bucket", valid_601305
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_601306 = query.getOrDefault("encryption")
  valid_601306 = validateParameter(valid_601306, JBool, required = true, default = nil)
  if valid_601306 != nil:
    section.add "encryption", valid_601306
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601307 = header.getOrDefault("x-amz-security-token")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "x-amz-security-token", valid_601307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601308: Call_DeleteBucketEncryption_601302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the server-side encryption configuration from the bucket.
  ## 
  let valid = call_601308.validator(path, query, header, formData, body)
  let scheme = call_601308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601308.url(scheme.get, call_601308.host, call_601308.base,
                         call_601308.route, valid.getOrDefault("path"))
  result = hook(call_601308, url, valid)

proc call*(call_601309: Call_DeleteBucketEncryption_601302; encryption: bool;
          Bucket: string): Recallable =
  ## deleteBucketEncryption
  ## Deletes the server-side encryption configuration from the bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the server-side encryption configuration to delete.
  var path_601310 = newJObject()
  var query_601311 = newJObject()
  add(query_601311, "encryption", newJBool(encryption))
  add(path_601310, "Bucket", newJString(Bucket))
  result = call_601309.call(path_601310, query_601311, nil, nil, nil)

var deleteBucketEncryption* = Call_DeleteBucketEncryption_601302(
    name: "deleteBucketEncryption", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#encryption",
    validator: validate_DeleteBucketEncryption_601303, base: "/",
    url: url_DeleteBucketEncryption_601304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketInventoryConfiguration_601323 = ref object of OpenApiRestCall_600426
proc url_PutBucketInventoryConfiguration_601325(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#inventory&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketInventoryConfiguration_601324(path: JsonNode;
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
  var valid_601326 = path.getOrDefault("Bucket")
  valid_601326 = validateParameter(valid_601326, JString, required = true,
                                 default = nil)
  if valid_601326 != nil:
    section.add "Bucket", valid_601326
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_601327 = query.getOrDefault("inventory")
  valid_601327 = validateParameter(valid_601327, JBool, required = true, default = nil)
  if valid_601327 != nil:
    section.add "inventory", valid_601327
  var valid_601328 = query.getOrDefault("id")
  valid_601328 = validateParameter(valid_601328, JString, required = true,
                                 default = nil)
  if valid_601328 != nil:
    section.add "id", valid_601328
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601329 = header.getOrDefault("x-amz-security-token")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "x-amz-security-token", valid_601329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601331: Call_PutBucketInventoryConfiguration_601323;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_601331.validator(path, query, header, formData, body)
  let scheme = call_601331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601331.url(scheme.get, call_601331.host, call_601331.base,
                         call_601331.route, valid.getOrDefault("path"))
  result = hook(call_601331, url, valid)

proc call*(call_601332: Call_PutBucketInventoryConfiguration_601323;
          inventory: bool; id: string; Bucket: string; body: JsonNode): Recallable =
  ## putBucketInventoryConfiguration
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket where the inventory configuration will be stored.
  ##   body: JObject (required)
  var path_601333 = newJObject()
  var query_601334 = newJObject()
  var body_601335 = newJObject()
  add(query_601334, "inventory", newJBool(inventory))
  add(query_601334, "id", newJString(id))
  add(path_601333, "Bucket", newJString(Bucket))
  if body != nil:
    body_601335 = body
  result = call_601332.call(path_601333, query_601334, nil, nil, body_601335)

var putBucketInventoryConfiguration* = Call_PutBucketInventoryConfiguration_601323(
    name: "putBucketInventoryConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_PutBucketInventoryConfiguration_601324, base: "/",
    url: url_PutBucketInventoryConfiguration_601325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketInventoryConfiguration_601312 = ref object of OpenApiRestCall_600426
proc url_GetBucketInventoryConfiguration_601314(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#inventory&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketInventoryConfiguration_601313(path: JsonNode;
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
  var valid_601315 = path.getOrDefault("Bucket")
  valid_601315 = validateParameter(valid_601315, JString, required = true,
                                 default = nil)
  if valid_601315 != nil:
    section.add "Bucket", valid_601315
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_601316 = query.getOrDefault("inventory")
  valid_601316 = validateParameter(valid_601316, JBool, required = true, default = nil)
  if valid_601316 != nil:
    section.add "inventory", valid_601316
  var valid_601317 = query.getOrDefault("id")
  valid_601317 = validateParameter(valid_601317, JString, required = true,
                                 default = nil)
  if valid_601317 != nil:
    section.add "id", valid_601317
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601318 = header.getOrDefault("x-amz-security-token")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "x-amz-security-token", valid_601318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601319: Call_GetBucketInventoryConfiguration_601312;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_601319.validator(path, query, header, formData, body)
  let scheme = call_601319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601319.url(scheme.get, call_601319.host, call_601319.base,
                         call_601319.route, valid.getOrDefault("path"))
  result = hook(call_601319, url, valid)

proc call*(call_601320: Call_GetBucketInventoryConfiguration_601312;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## getBucketInventoryConfiguration
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to retrieve.
  var path_601321 = newJObject()
  var query_601322 = newJObject()
  add(query_601322, "inventory", newJBool(inventory))
  add(query_601322, "id", newJString(id))
  add(path_601321, "Bucket", newJString(Bucket))
  result = call_601320.call(path_601321, query_601322, nil, nil, nil)

var getBucketInventoryConfiguration* = Call_GetBucketInventoryConfiguration_601312(
    name: "getBucketInventoryConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_GetBucketInventoryConfiguration_601313, base: "/",
    url: url_GetBucketInventoryConfiguration_601314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketInventoryConfiguration_601336 = ref object of OpenApiRestCall_600426
proc url_DeleteBucketInventoryConfiguration_601338(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#inventory&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBucketInventoryConfiguration_601337(path: JsonNode;
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
  var valid_601339 = path.getOrDefault("Bucket")
  valid_601339 = validateParameter(valid_601339, JString, required = true,
                                 default = nil)
  if valid_601339 != nil:
    section.add "Bucket", valid_601339
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_601340 = query.getOrDefault("inventory")
  valid_601340 = validateParameter(valid_601340, JBool, required = true, default = nil)
  if valid_601340 != nil:
    section.add "inventory", valid_601340
  var valid_601341 = query.getOrDefault("id")
  valid_601341 = validateParameter(valid_601341, JString, required = true,
                                 default = nil)
  if valid_601341 != nil:
    section.add "id", valid_601341
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601342 = header.getOrDefault("x-amz-security-token")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "x-amz-security-token", valid_601342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601343: Call_DeleteBucketInventoryConfiguration_601336;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_601343.validator(path, query, header, formData, body)
  let scheme = call_601343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601343.url(scheme.get, call_601343.host, call_601343.base,
                         call_601343.route, valid.getOrDefault("path"))
  result = hook(call_601343, url, valid)

proc call*(call_601344: Call_DeleteBucketInventoryConfiguration_601336;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## deleteBucketInventoryConfiguration
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to delete.
  var path_601345 = newJObject()
  var query_601346 = newJObject()
  add(query_601346, "inventory", newJBool(inventory))
  add(query_601346, "id", newJString(id))
  add(path_601345, "Bucket", newJString(Bucket))
  result = call_601344.call(path_601345, query_601346, nil, nil, nil)

var deleteBucketInventoryConfiguration* = Call_DeleteBucketInventoryConfiguration_601336(
    name: "deleteBucketInventoryConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_DeleteBucketInventoryConfiguration_601337, base: "/",
    url: url_DeleteBucketInventoryConfiguration_601338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycleConfiguration_601357 = ref object of OpenApiRestCall_600426
proc url_PutBucketLifecycleConfiguration_601359(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#lifecycle")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketLifecycleConfiguration_601358(path: JsonNode;
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
  var valid_601360 = path.getOrDefault("Bucket")
  valid_601360 = validateParameter(valid_601360, JString, required = true,
                                 default = nil)
  if valid_601360 != nil:
    section.add "Bucket", valid_601360
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_601361 = query.getOrDefault("lifecycle")
  valid_601361 = validateParameter(valid_601361, JBool, required = true, default = nil)
  if valid_601361 != nil:
    section.add "lifecycle", valid_601361
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601362 = header.getOrDefault("x-amz-security-token")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "x-amz-security-token", valid_601362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601364: Call_PutBucketLifecycleConfiguration_601357;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ## 
  let valid = call_601364.validator(path, query, header, formData, body)
  let scheme = call_601364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601364.url(scheme.get, call_601364.host, call_601364.base,
                         call_601364.route, valid.getOrDefault("path"))
  result = hook(call_601364, url, valid)

proc call*(call_601365: Call_PutBucketLifecycleConfiguration_601357;
          Bucket: string; lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycleConfiguration
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_601366 = newJObject()
  var query_601367 = newJObject()
  var body_601368 = newJObject()
  add(path_601366, "Bucket", newJString(Bucket))
  add(query_601367, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_601368 = body
  result = call_601365.call(path_601366, query_601367, nil, nil, body_601368)

var putBucketLifecycleConfiguration* = Call_PutBucketLifecycleConfiguration_601357(
    name: "putBucketLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_PutBucketLifecycleConfiguration_601358, base: "/",
    url: url_PutBucketLifecycleConfiguration_601359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycleConfiguration_601347 = ref object of OpenApiRestCall_600426
proc url_GetBucketLifecycleConfiguration_601349(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#lifecycle")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketLifecycleConfiguration_601348(path: JsonNode;
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
  var valid_601350 = path.getOrDefault("Bucket")
  valid_601350 = validateParameter(valid_601350, JString, required = true,
                                 default = nil)
  if valid_601350 != nil:
    section.add "Bucket", valid_601350
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_601351 = query.getOrDefault("lifecycle")
  valid_601351 = validateParameter(valid_601351, JBool, required = true, default = nil)
  if valid_601351 != nil:
    section.add "lifecycle", valid_601351
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601352 = header.getOrDefault("x-amz-security-token")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "x-amz-security-token", valid_601352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601353: Call_GetBucketLifecycleConfiguration_601347;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the lifecycle configuration information set on the bucket.
  ## 
  let valid = call_601353.validator(path, query, header, formData, body)
  let scheme = call_601353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601353.url(scheme.get, call_601353.host, call_601353.base,
                         call_601353.route, valid.getOrDefault("path"))
  result = hook(call_601353, url, valid)

proc call*(call_601354: Call_GetBucketLifecycleConfiguration_601347;
          Bucket: string; lifecycle: bool): Recallable =
  ## getBucketLifecycleConfiguration
  ## Returns the lifecycle configuration information set on the bucket.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_601355 = newJObject()
  var query_601356 = newJObject()
  add(path_601355, "Bucket", newJString(Bucket))
  add(query_601356, "lifecycle", newJBool(lifecycle))
  result = call_601354.call(path_601355, query_601356, nil, nil, nil)

var getBucketLifecycleConfiguration* = Call_GetBucketLifecycleConfiguration_601347(
    name: "getBucketLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_GetBucketLifecycleConfiguration_601348, base: "/",
    url: url_GetBucketLifecycleConfiguration_601349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketLifecycle_601369 = ref object of OpenApiRestCall_600426
proc url_DeleteBucketLifecycle_601371(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#lifecycle")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBucketLifecycle_601370(path: JsonNode; query: JsonNode;
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
  var valid_601372 = path.getOrDefault("Bucket")
  valid_601372 = validateParameter(valid_601372, JString, required = true,
                                 default = nil)
  if valid_601372 != nil:
    section.add "Bucket", valid_601372
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_601373 = query.getOrDefault("lifecycle")
  valid_601373 = validateParameter(valid_601373, JBool, required = true, default = nil)
  if valid_601373 != nil:
    section.add "lifecycle", valid_601373
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601374 = header.getOrDefault("x-amz-security-token")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "x-amz-security-token", valid_601374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601375: Call_DeleteBucketLifecycle_601369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the lifecycle configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  let valid = call_601375.validator(path, query, header, formData, body)
  let scheme = call_601375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601375.url(scheme.get, call_601375.host, call_601375.base,
                         call_601375.route, valid.getOrDefault("path"))
  result = hook(call_601375, url, valid)

proc call*(call_601376: Call_DeleteBucketLifecycle_601369; Bucket: string;
          lifecycle: bool): Recallable =
  ## deleteBucketLifecycle
  ## Deletes the lifecycle configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_601377 = newJObject()
  var query_601378 = newJObject()
  add(path_601377, "Bucket", newJString(Bucket))
  add(query_601378, "lifecycle", newJBool(lifecycle))
  result = call_601376.call(path_601377, query_601378, nil, nil, nil)

var deleteBucketLifecycle* = Call_DeleteBucketLifecycle_601369(
    name: "deleteBucketLifecycle", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_DeleteBucketLifecycle_601370, base: "/",
    url: url_DeleteBucketLifecycle_601371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketMetricsConfiguration_601390 = ref object of OpenApiRestCall_600426
proc url_PutBucketMetricsConfiguration_601392(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#metrics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketMetricsConfiguration_601391(path: JsonNode; query: JsonNode;
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
  var valid_601393 = path.getOrDefault("Bucket")
  valid_601393 = validateParameter(valid_601393, JString, required = true,
                                 default = nil)
  if valid_601393 != nil:
    section.add "Bucket", valid_601393
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601394 = query.getOrDefault("id")
  valid_601394 = validateParameter(valid_601394, JString, required = true,
                                 default = nil)
  if valid_601394 != nil:
    section.add "id", valid_601394
  var valid_601395 = query.getOrDefault("metrics")
  valid_601395 = validateParameter(valid_601395, JBool, required = true, default = nil)
  if valid_601395 != nil:
    section.add "metrics", valid_601395
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601396 = header.getOrDefault("x-amz-security-token")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "x-amz-security-token", valid_601396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601398: Call_PutBucketMetricsConfiguration_601390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ## 
  let valid = call_601398.validator(path, query, header, formData, body)
  let scheme = call_601398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601398.url(scheme.get, call_601398.host, call_601398.base,
                         call_601398.route, valid.getOrDefault("path"))
  result = hook(call_601398, url, valid)

proc call*(call_601399: Call_PutBucketMetricsConfiguration_601390; id: string;
          metrics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketMetricsConfiguration
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket for which the metrics configuration is set.
  ##   body: JObject (required)
  var path_601400 = newJObject()
  var query_601401 = newJObject()
  var body_601402 = newJObject()
  add(query_601401, "id", newJString(id))
  add(query_601401, "metrics", newJBool(metrics))
  add(path_601400, "Bucket", newJString(Bucket))
  if body != nil:
    body_601402 = body
  result = call_601399.call(path_601400, query_601401, nil, nil, body_601402)

var putBucketMetricsConfiguration* = Call_PutBucketMetricsConfiguration_601390(
    name: "putBucketMetricsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_PutBucketMetricsConfiguration_601391, base: "/",
    url: url_PutBucketMetricsConfiguration_601392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketMetricsConfiguration_601379 = ref object of OpenApiRestCall_600426
proc url_GetBucketMetricsConfiguration_601381(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#metrics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketMetricsConfiguration_601380(path: JsonNode; query: JsonNode;
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
  var valid_601382 = path.getOrDefault("Bucket")
  valid_601382 = validateParameter(valid_601382, JString, required = true,
                                 default = nil)
  if valid_601382 != nil:
    section.add "Bucket", valid_601382
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601383 = query.getOrDefault("id")
  valid_601383 = validateParameter(valid_601383, JString, required = true,
                                 default = nil)
  if valid_601383 != nil:
    section.add "id", valid_601383
  var valid_601384 = query.getOrDefault("metrics")
  valid_601384 = validateParameter(valid_601384, JBool, required = true, default = nil)
  if valid_601384 != nil:
    section.add "metrics", valid_601384
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601385 = header.getOrDefault("x-amz-security-token")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "x-amz-security-token", valid_601385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601386: Call_GetBucketMetricsConfiguration_601379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_601386.validator(path, query, header, formData, body)
  let scheme = call_601386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601386.url(scheme.get, call_601386.host, call_601386.base,
                         call_601386.route, valid.getOrDefault("path"))
  result = hook(call_601386, url, valid)

proc call*(call_601387: Call_GetBucketMetricsConfiguration_601379; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## getBucketMetricsConfiguration
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to retrieve.
  var path_601388 = newJObject()
  var query_601389 = newJObject()
  add(query_601389, "id", newJString(id))
  add(query_601389, "metrics", newJBool(metrics))
  add(path_601388, "Bucket", newJString(Bucket))
  result = call_601387.call(path_601388, query_601389, nil, nil, nil)

var getBucketMetricsConfiguration* = Call_GetBucketMetricsConfiguration_601379(
    name: "getBucketMetricsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_GetBucketMetricsConfiguration_601380, base: "/",
    url: url_GetBucketMetricsConfiguration_601381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketMetricsConfiguration_601403 = ref object of OpenApiRestCall_600426
proc url_DeleteBucketMetricsConfiguration_601405(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#metrics&id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBucketMetricsConfiguration_601404(path: JsonNode;
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
  var valid_601406 = path.getOrDefault("Bucket")
  valid_601406 = validateParameter(valid_601406, JString, required = true,
                                 default = nil)
  if valid_601406 != nil:
    section.add "Bucket", valid_601406
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_601407 = query.getOrDefault("id")
  valid_601407 = validateParameter(valid_601407, JString, required = true,
                                 default = nil)
  if valid_601407 != nil:
    section.add "id", valid_601407
  var valid_601408 = query.getOrDefault("metrics")
  valid_601408 = validateParameter(valid_601408, JBool, required = true, default = nil)
  if valid_601408 != nil:
    section.add "metrics", valid_601408
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601409 = header.getOrDefault("x-amz-security-token")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "x-amz-security-token", valid_601409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601410: Call_DeleteBucketMetricsConfiguration_601403;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_601410.validator(path, query, header, formData, body)
  let scheme = call_601410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601410.url(scheme.get, call_601410.host, call_601410.base,
                         call_601410.route, valid.getOrDefault("path"))
  result = hook(call_601410, url, valid)

proc call*(call_601411: Call_DeleteBucketMetricsConfiguration_601403; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## deleteBucketMetricsConfiguration
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to delete.
  var path_601412 = newJObject()
  var query_601413 = newJObject()
  add(query_601413, "id", newJString(id))
  add(query_601413, "metrics", newJBool(metrics))
  add(path_601412, "Bucket", newJString(Bucket))
  result = call_601411.call(path_601412, query_601413, nil, nil, nil)

var deleteBucketMetricsConfiguration* = Call_DeleteBucketMetricsConfiguration_601403(
    name: "deleteBucketMetricsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_DeleteBucketMetricsConfiguration_601404, base: "/",
    url: url_DeleteBucketMetricsConfiguration_601405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketPolicy_601424 = ref object of OpenApiRestCall_600426
proc url_PutBucketPolicy_601426(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketPolicy_601425(path: JsonNode; query: JsonNode;
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
  var valid_601427 = path.getOrDefault("Bucket")
  valid_601427 = validateParameter(valid_601427, JString, required = true,
                                 default = nil)
  if valid_601427 != nil:
    section.add "Bucket", valid_601427
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_601428 = query.getOrDefault("policy")
  valid_601428 = validateParameter(valid_601428, JBool, required = true, default = nil)
  if valid_601428 != nil:
    section.add "policy", valid_601428
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-confirm-remove-self-bucket-access: JBool
  ##                                          : Set this parameter to true to confirm that you want to remove your permissions to change this bucket policy in the future.
  section = newJObject()
  var valid_601429 = header.getOrDefault("x-amz-security-token")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "x-amz-security-token", valid_601429
  var valid_601430 = header.getOrDefault("Content-MD5")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "Content-MD5", valid_601430
  var valid_601431 = header.getOrDefault("x-amz-confirm-remove-self-bucket-access")
  valid_601431 = validateParameter(valid_601431, JBool, required = false, default = nil)
  if valid_601431 != nil:
    section.add "x-amz-confirm-remove-self-bucket-access", valid_601431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601433: Call_PutBucketPolicy_601424; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  let valid = call_601433.validator(path, query, header, formData, body)
  let scheme = call_601433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601433.url(scheme.get, call_601433.host, call_601433.base,
                         call_601433.route, valid.getOrDefault("path"))
  result = hook(call_601433, url, valid)

proc call*(call_601434: Call_PutBucketPolicy_601424; policy: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketPolicy
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601435 = newJObject()
  var query_601436 = newJObject()
  var body_601437 = newJObject()
  add(query_601436, "policy", newJBool(policy))
  add(path_601435, "Bucket", newJString(Bucket))
  if body != nil:
    body_601437 = body
  result = call_601434.call(path_601435, query_601436, nil, nil, body_601437)

var putBucketPolicy* = Call_PutBucketPolicy_601424(name: "putBucketPolicy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_PutBucketPolicy_601425, base: "/", url: url_PutBucketPolicy_601426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicy_601414 = ref object of OpenApiRestCall_600426
proc url_GetBucketPolicy_601416(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketPolicy_601415(path: JsonNode; query: JsonNode;
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
  var valid_601417 = path.getOrDefault("Bucket")
  valid_601417 = validateParameter(valid_601417, JString, required = true,
                                 default = nil)
  if valid_601417 != nil:
    section.add "Bucket", valid_601417
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_601418 = query.getOrDefault("policy")
  valid_601418 = validateParameter(valid_601418, JBool, required = true, default = nil)
  if valid_601418 != nil:
    section.add "policy", valid_601418
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601419 = header.getOrDefault("x-amz-security-token")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "x-amz-security-token", valid_601419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601420: Call_GetBucketPolicy_601414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the policy of a specified bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  let valid = call_601420.validator(path, query, header, formData, body)
  let scheme = call_601420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601420.url(scheme.get, call_601420.host, call_601420.base,
                         call_601420.route, valid.getOrDefault("path"))
  result = hook(call_601420, url, valid)

proc call*(call_601421: Call_GetBucketPolicy_601414; policy: bool; Bucket: string): Recallable =
  ## getBucketPolicy
  ## Returns the policy of a specified bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601422 = newJObject()
  var query_601423 = newJObject()
  add(query_601423, "policy", newJBool(policy))
  add(path_601422, "Bucket", newJString(Bucket))
  result = call_601421.call(path_601422, query_601423, nil, nil, nil)

var getBucketPolicy* = Call_GetBucketPolicy_601414(name: "getBucketPolicy",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_GetBucketPolicy_601415, base: "/", url: url_GetBucketPolicy_601416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketPolicy_601438 = ref object of OpenApiRestCall_600426
proc url_DeleteBucketPolicy_601440(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBucketPolicy_601439(path: JsonNode; query: JsonNode;
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
  var valid_601441 = path.getOrDefault("Bucket")
  valid_601441 = validateParameter(valid_601441, JString, required = true,
                                 default = nil)
  if valid_601441 != nil:
    section.add "Bucket", valid_601441
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_601442 = query.getOrDefault("policy")
  valid_601442 = validateParameter(valid_601442, JBool, required = true, default = nil)
  if valid_601442 != nil:
    section.add "policy", valid_601442
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601443 = header.getOrDefault("x-amz-security-token")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "x-amz-security-token", valid_601443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601444: Call_DeleteBucketPolicy_601438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  let valid = call_601444.validator(path, query, header, formData, body)
  let scheme = call_601444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601444.url(scheme.get, call_601444.host, call_601444.base,
                         call_601444.route, valid.getOrDefault("path"))
  result = hook(call_601444, url, valid)

proc call*(call_601445: Call_DeleteBucketPolicy_601438; policy: bool; Bucket: string): Recallable =
  ## deleteBucketPolicy
  ## Deletes the policy from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601446 = newJObject()
  var query_601447 = newJObject()
  add(query_601447, "policy", newJBool(policy))
  add(path_601446, "Bucket", newJString(Bucket))
  result = call_601445.call(path_601446, query_601447, nil, nil, nil)

var deleteBucketPolicy* = Call_DeleteBucketPolicy_601438(
    name: "deleteBucketPolicy", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_DeleteBucketPolicy_601439, base: "/",
    url: url_DeleteBucketPolicy_601440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketReplication_601458 = ref object of OpenApiRestCall_600426
proc url_PutBucketReplication_601460(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#replication")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketReplication_601459(path: JsonNode; query: JsonNode;
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
  var valid_601461 = path.getOrDefault("Bucket")
  valid_601461 = validateParameter(valid_601461, JString, required = true,
                                 default = nil)
  if valid_601461 != nil:
    section.add "Bucket", valid_601461
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_601462 = query.getOrDefault("replication")
  valid_601462 = validateParameter(valid_601462, JBool, required = true, default = nil)
  if valid_601462 != nil:
    section.add "replication", valid_601462
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit.
  ##   x-amz-bucket-object-lock-token: JString
  ##                                 : A token that allows Amazon S3 object lock to be enabled for an existing bucket.
  section = newJObject()
  var valid_601463 = header.getOrDefault("x-amz-security-token")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "x-amz-security-token", valid_601463
  var valid_601464 = header.getOrDefault("Content-MD5")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "Content-MD5", valid_601464
  var valid_601465 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_601465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601467: Call_PutBucketReplication_601458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_601467.validator(path, query, header, formData, body)
  let scheme = call_601467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601467.url(scheme.get, call_601467.host, call_601467.base,
                         call_601467.route, valid.getOrDefault("path"))
  result = hook(call_601467, url, valid)

proc call*(call_601468: Call_PutBucketReplication_601458; replication: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketReplication
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601469 = newJObject()
  var query_601470 = newJObject()
  var body_601471 = newJObject()
  add(query_601470, "replication", newJBool(replication))
  add(path_601469, "Bucket", newJString(Bucket))
  if body != nil:
    body_601471 = body
  result = call_601468.call(path_601469, query_601470, nil, nil, body_601471)

var putBucketReplication* = Call_PutBucketReplication_601458(
    name: "putBucketReplication", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_PutBucketReplication_601459, base: "/",
    url: url_PutBucketReplication_601460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketReplication_601448 = ref object of OpenApiRestCall_600426
proc url_GetBucketReplication_601450(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#replication")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketReplication_601449(path: JsonNode; query: JsonNode;
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
  var valid_601451 = path.getOrDefault("Bucket")
  valid_601451 = validateParameter(valid_601451, JString, required = true,
                                 default = nil)
  if valid_601451 != nil:
    section.add "Bucket", valid_601451
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_601452 = query.getOrDefault("replication")
  valid_601452 = validateParameter(valid_601452, JBool, required = true, default = nil)
  if valid_601452 != nil:
    section.add "replication", valid_601452
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601453 = header.getOrDefault("x-amz-security-token")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "x-amz-security-token", valid_601453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601454: Call_GetBucketReplication_601448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ## 
  let valid = call_601454.validator(path, query, header, formData, body)
  let scheme = call_601454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601454.url(scheme.get, call_601454.host, call_601454.base,
                         call_601454.route, valid.getOrDefault("path"))
  result = hook(call_601454, url, valid)

proc call*(call_601455: Call_GetBucketReplication_601448; replication: bool;
          Bucket: string): Recallable =
  ## getBucketReplication
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601456 = newJObject()
  var query_601457 = newJObject()
  add(query_601457, "replication", newJBool(replication))
  add(path_601456, "Bucket", newJString(Bucket))
  result = call_601455.call(path_601456, query_601457, nil, nil, nil)

var getBucketReplication* = Call_GetBucketReplication_601448(
    name: "getBucketReplication", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_GetBucketReplication_601449, base: "/",
    url: url_GetBucketReplication_601450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketReplication_601472 = ref object of OpenApiRestCall_600426
proc url_DeleteBucketReplication_601474(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#replication")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBucketReplication_601473(path: JsonNode; query: JsonNode;
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
  var valid_601475 = path.getOrDefault("Bucket")
  valid_601475 = validateParameter(valid_601475, JString, required = true,
                                 default = nil)
  if valid_601475 != nil:
    section.add "Bucket", valid_601475
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_601476 = query.getOrDefault("replication")
  valid_601476 = validateParameter(valid_601476, JBool, required = true, default = nil)
  if valid_601476 != nil:
    section.add "replication", valid_601476
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601477 = header.getOrDefault("x-amz-security-token")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "x-amz-security-token", valid_601477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601478: Call_DeleteBucketReplication_601472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_601478.validator(path, query, header, formData, body)
  let scheme = call_601478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601478.url(scheme.get, call_601478.host, call_601478.base,
                         call_601478.route, valid.getOrDefault("path"))
  result = hook(call_601478, url, valid)

proc call*(call_601479: Call_DeleteBucketReplication_601472; replication: bool;
          Bucket: string): Recallable =
  ## deleteBucketReplication
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p> The bucket name. </p> <note> <p>It can take a while to propagate the deletion of a replication configuration to all Amazon S3 systems.</p> </note>
  var path_601480 = newJObject()
  var query_601481 = newJObject()
  add(query_601481, "replication", newJBool(replication))
  add(path_601480, "Bucket", newJString(Bucket))
  result = call_601479.call(path_601480, query_601481, nil, nil, nil)

var deleteBucketReplication* = Call_DeleteBucketReplication_601472(
    name: "deleteBucketReplication", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_DeleteBucketReplication_601473, base: "/",
    url: url_DeleteBucketReplication_601474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketTagging_601492 = ref object of OpenApiRestCall_600426
proc url_PutBucketTagging_601494(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#tagging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketTagging_601493(path: JsonNode; query: JsonNode;
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
  var valid_601495 = path.getOrDefault("Bucket")
  valid_601495 = validateParameter(valid_601495, JString, required = true,
                                 default = nil)
  if valid_601495 != nil:
    section.add "Bucket", valid_601495
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601496 = query.getOrDefault("tagging")
  valid_601496 = validateParameter(valid_601496, JBool, required = true, default = nil)
  if valid_601496 != nil:
    section.add "tagging", valid_601496
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601497 = header.getOrDefault("x-amz-security-token")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "x-amz-security-token", valid_601497
  var valid_601498 = header.getOrDefault("Content-MD5")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "Content-MD5", valid_601498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601500: Call_PutBucketTagging_601492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the tags for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  let valid = call_601500.validator(path, query, header, formData, body)
  let scheme = call_601500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601500.url(scheme.get, call_601500.host, call_601500.base,
                         call_601500.route, valid.getOrDefault("path"))
  result = hook(call_601500, url, valid)

proc call*(call_601501: Call_PutBucketTagging_601492; tagging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketTagging
  ## Sets the tags for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601502 = newJObject()
  var query_601503 = newJObject()
  var body_601504 = newJObject()
  add(query_601503, "tagging", newJBool(tagging))
  add(path_601502, "Bucket", newJString(Bucket))
  if body != nil:
    body_601504 = body
  result = call_601501.call(path_601502, query_601503, nil, nil, body_601504)

var putBucketTagging* = Call_PutBucketTagging_601492(name: "putBucketTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_PutBucketTagging_601493, base: "/",
    url: url_PutBucketTagging_601494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketTagging_601482 = ref object of OpenApiRestCall_600426
proc url_GetBucketTagging_601484(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#tagging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketTagging_601483(path: JsonNode; query: JsonNode;
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
  var valid_601485 = path.getOrDefault("Bucket")
  valid_601485 = validateParameter(valid_601485, JString, required = true,
                                 default = nil)
  if valid_601485 != nil:
    section.add "Bucket", valid_601485
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601486 = query.getOrDefault("tagging")
  valid_601486 = validateParameter(valid_601486, JBool, required = true, default = nil)
  if valid_601486 != nil:
    section.add "tagging", valid_601486
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601487 = header.getOrDefault("x-amz-security-token")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "x-amz-security-token", valid_601487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601488: Call_GetBucketTagging_601482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag set associated with the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  let valid = call_601488.validator(path, query, header, formData, body)
  let scheme = call_601488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601488.url(scheme.get, call_601488.host, call_601488.base,
                         call_601488.route, valid.getOrDefault("path"))
  result = hook(call_601488, url, valid)

proc call*(call_601489: Call_GetBucketTagging_601482; tagging: bool; Bucket: string): Recallable =
  ## getBucketTagging
  ## Returns the tag set associated with the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601490 = newJObject()
  var query_601491 = newJObject()
  add(query_601491, "tagging", newJBool(tagging))
  add(path_601490, "Bucket", newJString(Bucket))
  result = call_601489.call(path_601490, query_601491, nil, nil, nil)

var getBucketTagging* = Call_GetBucketTagging_601482(name: "getBucketTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_GetBucketTagging_601483, base: "/",
    url: url_GetBucketTagging_601484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketTagging_601505 = ref object of OpenApiRestCall_600426
proc url_DeleteBucketTagging_601507(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#tagging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBucketTagging_601506(path: JsonNode; query: JsonNode;
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
  var valid_601508 = path.getOrDefault("Bucket")
  valid_601508 = validateParameter(valid_601508, JString, required = true,
                                 default = nil)
  if valid_601508 != nil:
    section.add "Bucket", valid_601508
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601509 = query.getOrDefault("tagging")
  valid_601509 = validateParameter(valid_601509, JBool, required = true, default = nil)
  if valid_601509 != nil:
    section.add "tagging", valid_601509
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601510 = header.getOrDefault("x-amz-security-token")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "x-amz-security-token", valid_601510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601511: Call_DeleteBucketTagging_601505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the tags from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  let valid = call_601511.validator(path, query, header, formData, body)
  let scheme = call_601511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601511.url(scheme.get, call_601511.host, call_601511.base,
                         call_601511.route, valid.getOrDefault("path"))
  result = hook(call_601511, url, valid)

proc call*(call_601512: Call_DeleteBucketTagging_601505; tagging: bool;
          Bucket: string): Recallable =
  ## deleteBucketTagging
  ## Deletes the tags from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601513 = newJObject()
  var query_601514 = newJObject()
  add(query_601514, "tagging", newJBool(tagging))
  add(path_601513, "Bucket", newJString(Bucket))
  result = call_601512.call(path_601513, query_601514, nil, nil, nil)

var deleteBucketTagging* = Call_DeleteBucketTagging_601505(
    name: "deleteBucketTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_DeleteBucketTagging_601506, base: "/",
    url: url_DeleteBucketTagging_601507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketWebsite_601525 = ref object of OpenApiRestCall_600426
proc url_PutBucketWebsite_601527(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#website")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketWebsite_601526(path: JsonNode; query: JsonNode;
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
  var valid_601528 = path.getOrDefault("Bucket")
  valid_601528 = validateParameter(valid_601528, JString, required = true,
                                 default = nil)
  if valid_601528 != nil:
    section.add "Bucket", valid_601528
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_601529 = query.getOrDefault("website")
  valid_601529 = validateParameter(valid_601529, JBool, required = true, default = nil)
  if valid_601529 != nil:
    section.add "website", valid_601529
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601530 = header.getOrDefault("x-amz-security-token")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "x-amz-security-token", valid_601530
  var valid_601531 = header.getOrDefault("Content-MD5")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "Content-MD5", valid_601531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601533: Call_PutBucketWebsite_601525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  let valid = call_601533.validator(path, query, header, formData, body)
  let scheme = call_601533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601533.url(scheme.get, call_601533.host, call_601533.base,
                         call_601533.route, valid.getOrDefault("path"))
  result = hook(call_601533, url, valid)

proc call*(call_601534: Call_PutBucketWebsite_601525; website: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketWebsite
  ## Set the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601535 = newJObject()
  var query_601536 = newJObject()
  var body_601537 = newJObject()
  add(query_601536, "website", newJBool(website))
  add(path_601535, "Bucket", newJString(Bucket))
  if body != nil:
    body_601537 = body
  result = call_601534.call(path_601535, query_601536, nil, nil, body_601537)

var putBucketWebsite* = Call_PutBucketWebsite_601525(name: "putBucketWebsite",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_PutBucketWebsite_601526, base: "/",
    url: url_PutBucketWebsite_601527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketWebsite_601515 = ref object of OpenApiRestCall_600426
proc url_GetBucketWebsite_601517(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#website")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketWebsite_601516(path: JsonNode; query: JsonNode;
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
  var valid_601518 = path.getOrDefault("Bucket")
  valid_601518 = validateParameter(valid_601518, JString, required = true,
                                 default = nil)
  if valid_601518 != nil:
    section.add "Bucket", valid_601518
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_601519 = query.getOrDefault("website")
  valid_601519 = validateParameter(valid_601519, JBool, required = true, default = nil)
  if valid_601519 != nil:
    section.add "website", valid_601519
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601520 = header.getOrDefault("x-amz-security-token")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "x-amz-security-token", valid_601520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601521: Call_GetBucketWebsite_601515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  let valid = call_601521.validator(path, query, header, formData, body)
  let scheme = call_601521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601521.url(scheme.get, call_601521.host, call_601521.base,
                         call_601521.route, valid.getOrDefault("path"))
  result = hook(call_601521, url, valid)

proc call*(call_601522: Call_GetBucketWebsite_601515; website: bool; Bucket: string): Recallable =
  ## getBucketWebsite
  ## Returns the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601523 = newJObject()
  var query_601524 = newJObject()
  add(query_601524, "website", newJBool(website))
  add(path_601523, "Bucket", newJString(Bucket))
  result = call_601522.call(path_601523, query_601524, nil, nil, nil)

var getBucketWebsite* = Call_GetBucketWebsite_601515(name: "getBucketWebsite",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_GetBucketWebsite_601516, base: "/",
    url: url_GetBucketWebsite_601517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketWebsite_601538 = ref object of OpenApiRestCall_600426
proc url_DeleteBucketWebsite_601540(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#website")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteBucketWebsite_601539(path: JsonNode; query: JsonNode;
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
  var valid_601541 = path.getOrDefault("Bucket")
  valid_601541 = validateParameter(valid_601541, JString, required = true,
                                 default = nil)
  if valid_601541 != nil:
    section.add "Bucket", valid_601541
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_601542 = query.getOrDefault("website")
  valid_601542 = validateParameter(valid_601542, JBool, required = true, default = nil)
  if valid_601542 != nil:
    section.add "website", valid_601542
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601543 = header.getOrDefault("x-amz-security-token")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "x-amz-security-token", valid_601543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601544: Call_DeleteBucketWebsite_601538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes the website configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  let valid = call_601544.validator(path, query, header, formData, body)
  let scheme = call_601544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601544.url(scheme.get, call_601544.host, call_601544.base,
                         call_601544.route, valid.getOrDefault("path"))
  result = hook(call_601544, url, valid)

proc call*(call_601545: Call_DeleteBucketWebsite_601538; website: bool;
          Bucket: string): Recallable =
  ## deleteBucketWebsite
  ## This operation removes the website configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601546 = newJObject()
  var query_601547 = newJObject()
  add(query_601547, "website", newJBool(website))
  add(path_601546, "Bucket", newJString(Bucket))
  result = call_601545.call(path_601546, query_601547, nil, nil, nil)

var deleteBucketWebsite* = Call_DeleteBucketWebsite_601538(
    name: "deleteBucketWebsite", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_DeleteBucketWebsite_601539, base: "/",
    url: url_DeleteBucketWebsite_601540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObject_601575 = ref object of OpenApiRestCall_600426
proc url_PutObject_601577(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutObject_601576(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601578 = path.getOrDefault("Key")
  valid_601578 = validateParameter(valid_601578, JString, required = true,
                                 default = nil)
  if valid_601578 != nil:
    section.add "Key", valid_601578
  var valid_601579 = path.getOrDefault("Bucket")
  valid_601579 = validateParameter(valid_601579, JString, required = true,
                                 default = nil)
  if valid_601579 != nil:
    section.add "Bucket", valid_601579
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
  var valid_601580 = header.getOrDefault("Content-Disposition")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "Content-Disposition", valid_601580
  var valid_601581 = header.getOrDefault("x-amz-grant-full-control")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "x-amz-grant-full-control", valid_601581
  var valid_601582 = header.getOrDefault("x-amz-security-token")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "x-amz-security-token", valid_601582
  var valid_601583 = header.getOrDefault("Content-MD5")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "Content-MD5", valid_601583
  var valid_601584 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_601584
  var valid_601585 = header.getOrDefault("x-amz-object-lock-mode")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_601585 != nil:
    section.add "x-amz-object-lock-mode", valid_601585
  var valid_601586 = header.getOrDefault("Cache-Control")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "Cache-Control", valid_601586
  var valid_601587 = header.getOrDefault("Content-Language")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "Content-Language", valid_601587
  var valid_601588 = header.getOrDefault("Content-Type")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "Content-Type", valid_601588
  var valid_601589 = header.getOrDefault("Expires")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "Expires", valid_601589
  var valid_601590 = header.getOrDefault("x-amz-website-redirect-location")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "x-amz-website-redirect-location", valid_601590
  var valid_601591 = header.getOrDefault("x-amz-acl")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = newJString("private"))
  if valid_601591 != nil:
    section.add "x-amz-acl", valid_601591
  var valid_601592 = header.getOrDefault("x-amz-grant-read")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "x-amz-grant-read", valid_601592
  var valid_601593 = header.getOrDefault("x-amz-storage-class")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_601593 != nil:
    section.add "x-amz-storage-class", valid_601593
  var valid_601594 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = newJString("ON"))
  if valid_601594 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_601594
  var valid_601595 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_601595
  var valid_601596 = header.getOrDefault("x-amz-tagging")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "x-amz-tagging", valid_601596
  var valid_601597 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "x-amz-grant-read-acp", valid_601597
  var valid_601598 = header.getOrDefault("Content-Length")
  valid_601598 = validateParameter(valid_601598, JInt, required = false, default = nil)
  if valid_601598 != nil:
    section.add "Content-Length", valid_601598
  var valid_601599 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "x-amz-server-side-encryption-context", valid_601599
  var valid_601600 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_601600
  var valid_601601 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_601601
  var valid_601602 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "x-amz-grant-write-acp", valid_601602
  var valid_601603 = header.getOrDefault("Content-Encoding")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "Content-Encoding", valid_601603
  var valid_601604 = header.getOrDefault("x-amz-request-payer")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = newJString("requester"))
  if valid_601604 != nil:
    section.add "x-amz-request-payer", valid_601604
  var valid_601605 = header.getOrDefault("x-amz-server-side-encryption")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = newJString("AES256"))
  if valid_601605 != nil:
    section.add "x-amz-server-side-encryption", valid_601605
  var valid_601606 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_601606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601608: Call_PutObject_601575; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an object to a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  let valid = call_601608.validator(path, query, header, formData, body)
  let scheme = call_601608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601608.url(scheme.get, call_601608.host, call_601608.base,
                         call_601608.route, valid.getOrDefault("path"))
  result = hook(call_601608, url, valid)

proc call*(call_601609: Call_PutObject_601575; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## putObject
  ## Adds an object to a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  ##   Key: string (required)
  ##      : Object key for which the PUT operation was initiated.
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the PUT operation was initiated.
  ##   body: JObject (required)
  var path_601610 = newJObject()
  var body_601611 = newJObject()
  add(path_601610, "Key", newJString(Key))
  add(path_601610, "Bucket", newJString(Bucket))
  if body != nil:
    body_601611 = body
  result = call_601609.call(path_601610, nil, nil, nil, body_601611)

var putObject* = Call_PutObject_601575(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_PutObject_601576,
                                    base: "/", url: url_PutObject_601577,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadObject_601626 = ref object of OpenApiRestCall_600426
proc url_HeadObject_601628(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_HeadObject_601627(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601629 = path.getOrDefault("Key")
  valid_601629 = validateParameter(valid_601629, JString, required = true,
                                 default = nil)
  if valid_601629 != nil:
    section.add "Key", valid_601629
  var valid_601630 = path.getOrDefault("Bucket")
  valid_601630 = validateParameter(valid_601630, JString, required = true,
                                 default = nil)
  if valid_601630 != nil:
    section.add "Bucket", valid_601630
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   partNumber: JInt
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
  section = newJObject()
  var valid_601631 = query.getOrDefault("versionId")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "versionId", valid_601631
  var valid_601632 = query.getOrDefault("partNumber")
  valid_601632 = validateParameter(valid_601632, JInt, required = false, default = nil)
  if valid_601632 != nil:
    section.add "partNumber", valid_601632
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
  var valid_601633 = header.getOrDefault("x-amz-security-token")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "x-amz-security-token", valid_601633
  var valid_601634 = header.getOrDefault("If-Match")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "If-Match", valid_601634
  var valid_601635 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_601635
  var valid_601636 = header.getOrDefault("If-Unmodified-Since")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "If-Unmodified-Since", valid_601636
  var valid_601637 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_601637
  var valid_601638 = header.getOrDefault("If-Modified-Since")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "If-Modified-Since", valid_601638
  var valid_601639 = header.getOrDefault("If-None-Match")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "If-None-Match", valid_601639
  var valid_601640 = header.getOrDefault("x-amz-request-payer")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = newJString("requester"))
  if valid_601640 != nil:
    section.add "x-amz-request-payer", valid_601640
  var valid_601641 = header.getOrDefault("Range")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "Range", valid_601641
  var valid_601642 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_601642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601643: Call_HeadObject_601626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  let valid = call_601643.validator(path, query, header, formData, body)
  let scheme = call_601643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601643.url(scheme.get, call_601643.host, call_601643.base,
                         call_601643.route, valid.getOrDefault("path"))
  result = hook(call_601643, url, valid)

proc call*(call_601644: Call_HeadObject_601626; Key: string; Bucket: string;
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
  var path_601645 = newJObject()
  var query_601646 = newJObject()
  add(query_601646, "versionId", newJString(versionId))
  add(query_601646, "partNumber", newJInt(partNumber))
  add(path_601645, "Key", newJString(Key))
  add(path_601645, "Bucket", newJString(Bucket))
  result = call_601644.call(path_601645, query_601646, nil, nil, nil)

var headObject* = Call_HeadObject_601626(name: "headObject",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}/{Key}",
                                      validator: validate_HeadObject_601627,
                                      base: "/", url: url_HeadObject_601628,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_601548 = ref object of OpenApiRestCall_600426
proc url_GetObject_601550(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetObject_601549(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601551 = path.getOrDefault("Key")
  valid_601551 = validateParameter(valid_601551, JString, required = true,
                                 default = nil)
  if valid_601551 != nil:
    section.add "Key", valid_601551
  var valid_601552 = path.getOrDefault("Bucket")
  valid_601552 = validateParameter(valid_601552, JString, required = true,
                                 default = nil)
  if valid_601552 != nil:
    section.add "Bucket", valid_601552
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
  var valid_601553 = query.getOrDefault("versionId")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "versionId", valid_601553
  var valid_601554 = query.getOrDefault("partNumber")
  valid_601554 = validateParameter(valid_601554, JInt, required = false, default = nil)
  if valid_601554 != nil:
    section.add "partNumber", valid_601554
  var valid_601555 = query.getOrDefault("response-expires")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "response-expires", valid_601555
  var valid_601556 = query.getOrDefault("response-content-language")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "response-content-language", valid_601556
  var valid_601557 = query.getOrDefault("response-content-encoding")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "response-content-encoding", valid_601557
  var valid_601558 = query.getOrDefault("response-cache-control")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "response-cache-control", valid_601558
  var valid_601559 = query.getOrDefault("response-content-disposition")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "response-content-disposition", valid_601559
  var valid_601560 = query.getOrDefault("response-content-type")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "response-content-type", valid_601560
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
  var valid_601561 = header.getOrDefault("x-amz-security-token")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "x-amz-security-token", valid_601561
  var valid_601562 = header.getOrDefault("If-Match")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "If-Match", valid_601562
  var valid_601563 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_601563
  var valid_601564 = header.getOrDefault("If-Unmodified-Since")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "If-Unmodified-Since", valid_601564
  var valid_601565 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_601565
  var valid_601566 = header.getOrDefault("If-Modified-Since")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "If-Modified-Since", valid_601566
  var valid_601567 = header.getOrDefault("If-None-Match")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "If-None-Match", valid_601567
  var valid_601568 = header.getOrDefault("x-amz-request-payer")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = newJString("requester"))
  if valid_601568 != nil:
    section.add "x-amz-request-payer", valid_601568
  var valid_601569 = header.getOrDefault("Range")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "Range", valid_601569
  var valid_601570 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_601570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601571: Call_GetObject_601548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves objects from Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  let valid = call_601571.validator(path, query, header, formData, body)
  let scheme = call_601571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601571.url(scheme.get, call_601571.host, call_601571.base,
                         call_601571.route, valid.getOrDefault("path"))
  result = hook(call_601571, url, valid)

proc call*(call_601572: Call_GetObject_601548; Key: string; Bucket: string;
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
  var path_601573 = newJObject()
  var query_601574 = newJObject()
  add(query_601574, "versionId", newJString(versionId))
  add(query_601574, "partNumber", newJInt(partNumber))
  add(query_601574, "response-expires", newJString(responseExpires))
  add(query_601574, "response-content-language",
      newJString(responseContentLanguage))
  add(path_601573, "Key", newJString(Key))
  add(query_601574, "response-content-encoding",
      newJString(responseContentEncoding))
  add(query_601574, "response-cache-control", newJString(responseCacheControl))
  add(path_601573, "Bucket", newJString(Bucket))
  add(query_601574, "response-content-disposition",
      newJString(responseContentDisposition))
  add(query_601574, "response-content-type", newJString(responseContentType))
  result = call_601572.call(path_601573, query_601574, nil, nil, nil)

var getObject* = Call_GetObject_601548(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_GetObject_601549,
                                    base: "/", url: url_GetObject_601550,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_601612 = ref object of OpenApiRestCall_600426
proc url_DeleteObject_601614(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteObject_601613(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601615 = path.getOrDefault("Key")
  valid_601615 = validateParameter(valid_601615, JString, required = true,
                                 default = nil)
  if valid_601615 != nil:
    section.add "Key", valid_601615
  var valid_601616 = path.getOrDefault("Bucket")
  valid_601616 = validateParameter(valid_601616, JString, required = true,
                                 default = nil)
  if valid_601616 != nil:
    section.add "Bucket", valid_601616
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  var valid_601617 = query.getOrDefault("versionId")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "versionId", valid_601617
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
  var valid_601618 = header.getOrDefault("x-amz-security-token")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "x-amz-security-token", valid_601618
  var valid_601619 = header.getOrDefault("x-amz-mfa")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "x-amz-mfa", valid_601619
  var valid_601620 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_601620 = validateParameter(valid_601620, JBool, required = false, default = nil)
  if valid_601620 != nil:
    section.add "x-amz-bypass-governance-retention", valid_601620
  var valid_601621 = header.getOrDefault("x-amz-request-payer")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = newJString("requester"))
  if valid_601621 != nil:
    section.add "x-amz-request-payer", valid_601621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601622: Call_DeleteObject_601612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  let valid = call_601622.validator(path, query, header, formData, body)
  let scheme = call_601622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601622.url(scheme.get, call_601622.host, call_601622.base,
                         call_601622.route, valid.getOrDefault("path"))
  result = hook(call_601622, url, valid)

proc call*(call_601623: Call_DeleteObject_601612; Key: string; Bucket: string;
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
  var path_601624 = newJObject()
  var query_601625 = newJObject()
  add(query_601625, "versionId", newJString(versionId))
  add(path_601624, "Key", newJString(Key))
  add(path_601624, "Bucket", newJString(Bucket))
  result = call_601623.call(path_601624, query_601625, nil, nil, nil)

var deleteObject* = Call_DeleteObject_601612(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}/{Key}",
    validator: validate_DeleteObject_601613, base: "/", url: url_DeleteObject_601614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectTagging_601659 = ref object of OpenApiRestCall_600426
proc url_PutObjectTagging_601661(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutObjectTagging_601660(path: JsonNode; query: JsonNode;
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
  var valid_601662 = path.getOrDefault("Key")
  valid_601662 = validateParameter(valid_601662, JString, required = true,
                                 default = nil)
  if valid_601662 != nil:
    section.add "Key", valid_601662
  var valid_601663 = path.getOrDefault("Bucket")
  valid_601663 = validateParameter(valid_601663, JString, required = true,
                                 default = nil)
  if valid_601663 != nil:
    section.add "Bucket", valid_601663
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_601664 = query.getOrDefault("versionId")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "versionId", valid_601664
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601665 = query.getOrDefault("tagging")
  valid_601665 = validateParameter(valid_601665, JBool, required = true, default = nil)
  if valid_601665 != nil:
    section.add "tagging", valid_601665
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601666 = header.getOrDefault("x-amz-security-token")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "x-amz-security-token", valid_601666
  var valid_601667 = header.getOrDefault("Content-MD5")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "Content-MD5", valid_601667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601669: Call_PutObjectTagging_601659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ## 
  let valid = call_601669.validator(path, query, header, formData, body)
  let scheme = call_601669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601669.url(scheme.get, call_601669.host, call_601669.base,
                         call_601669.route, valid.getOrDefault("path"))
  result = hook(call_601669, url, valid)

proc call*(call_601670: Call_PutObjectTagging_601659; tagging: bool; Key: string;
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
  var path_601671 = newJObject()
  var query_601672 = newJObject()
  var body_601673 = newJObject()
  add(query_601672, "versionId", newJString(versionId))
  add(query_601672, "tagging", newJBool(tagging))
  add(path_601671, "Key", newJString(Key))
  add(path_601671, "Bucket", newJString(Bucket))
  if body != nil:
    body_601673 = body
  result = call_601670.call(path_601671, query_601672, nil, nil, body_601673)

var putObjectTagging* = Call_PutObjectTagging_601659(name: "putObjectTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_PutObjectTagging_601660,
    base: "/", url: url_PutObjectTagging_601661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTagging_601647 = ref object of OpenApiRestCall_600426
proc url_GetObjectTagging_601649(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetObjectTagging_601648(path: JsonNode; query: JsonNode;
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
  var valid_601650 = path.getOrDefault("Key")
  valid_601650 = validateParameter(valid_601650, JString, required = true,
                                 default = nil)
  if valid_601650 != nil:
    section.add "Key", valid_601650
  var valid_601651 = path.getOrDefault("Bucket")
  valid_601651 = validateParameter(valid_601651, JString, required = true,
                                 default = nil)
  if valid_601651 != nil:
    section.add "Bucket", valid_601651
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_601652 = query.getOrDefault("versionId")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "versionId", valid_601652
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601653 = query.getOrDefault("tagging")
  valid_601653 = validateParameter(valid_601653, JBool, required = true, default = nil)
  if valid_601653 != nil:
    section.add "tagging", valid_601653
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601654 = header.getOrDefault("x-amz-security-token")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "x-amz-security-token", valid_601654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601655: Call_GetObjectTagging_601647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag-set of an object.
  ## 
  let valid = call_601655.validator(path, query, header, formData, body)
  let scheme = call_601655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601655.url(scheme.get, call_601655.host, call_601655.base,
                         call_601655.route, valid.getOrDefault("path"))
  result = hook(call_601655, url, valid)

proc call*(call_601656: Call_GetObjectTagging_601647; tagging: bool; Key: string;
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
  var path_601657 = newJObject()
  var query_601658 = newJObject()
  add(query_601658, "versionId", newJString(versionId))
  add(query_601658, "tagging", newJBool(tagging))
  add(path_601657, "Key", newJString(Key))
  add(path_601657, "Bucket", newJString(Bucket))
  result = call_601656.call(path_601657, query_601658, nil, nil, nil)

var getObjectTagging* = Call_GetObjectTagging_601647(name: "getObjectTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_GetObjectTagging_601648,
    base: "/", url: url_GetObjectTagging_601649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjectTagging_601674 = ref object of OpenApiRestCall_600426
proc url_DeleteObjectTagging_601676(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteObjectTagging_601675(path: JsonNode; query: JsonNode;
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
  var valid_601677 = path.getOrDefault("Key")
  valid_601677 = validateParameter(valid_601677, JString, required = true,
                                 default = nil)
  if valid_601677 != nil:
    section.add "Key", valid_601677
  var valid_601678 = path.getOrDefault("Bucket")
  valid_601678 = validateParameter(valid_601678, JString, required = true,
                                 default = nil)
  if valid_601678 != nil:
    section.add "Bucket", valid_601678
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The versionId of the object that the tag-set will be removed from.
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_601679 = query.getOrDefault("versionId")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "versionId", valid_601679
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_601680 = query.getOrDefault("tagging")
  valid_601680 = validateParameter(valid_601680, JBool, required = true, default = nil)
  if valid_601680 != nil:
    section.add "tagging", valid_601680
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601681 = header.getOrDefault("x-amz-security-token")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "x-amz-security-token", valid_601681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601682: Call_DeleteObjectTagging_601674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the tag-set from an existing object.
  ## 
  let valid = call_601682.validator(path, query, header, formData, body)
  let scheme = call_601682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601682.url(scheme.get, call_601682.host, call_601682.base,
                         call_601682.route, valid.getOrDefault("path"))
  result = hook(call_601682, url, valid)

proc call*(call_601683: Call_DeleteObjectTagging_601674; tagging: bool; Key: string;
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
  var path_601684 = newJObject()
  var query_601685 = newJObject()
  add(query_601685, "versionId", newJString(versionId))
  add(query_601685, "tagging", newJBool(tagging))
  add(path_601684, "Key", newJString(Key))
  add(path_601684, "Bucket", newJString(Bucket))
  result = call_601683.call(path_601684, query_601685, nil, nil, nil)

var deleteObjectTagging* = Call_DeleteObjectTagging_601674(
    name: "deleteObjectTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#tagging",
    validator: validate_DeleteObjectTagging_601675, base: "/",
    url: url_DeleteObjectTagging_601676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjects_601686 = ref object of OpenApiRestCall_600426
proc url_DeleteObjects_601688(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#delete")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteObjects_601687(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601689 = path.getOrDefault("Bucket")
  valid_601689 = validateParameter(valid_601689, JString, required = true,
                                 default = nil)
  if valid_601689 != nil:
    section.add "Bucket", valid_601689
  result.add "path", section
  ## parameters in `query` object:
  ##   delete: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `delete` field"
  var valid_601690 = query.getOrDefault("delete")
  valid_601690 = validateParameter(valid_601690, JBool, required = true, default = nil)
  if valid_601690 != nil:
    section.add "delete", valid_601690
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
  var valid_601691 = header.getOrDefault("x-amz-security-token")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "x-amz-security-token", valid_601691
  var valid_601692 = header.getOrDefault("x-amz-mfa")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "x-amz-mfa", valid_601692
  var valid_601693 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_601693 = validateParameter(valid_601693, JBool, required = false, default = nil)
  if valid_601693 != nil:
    section.add "x-amz-bypass-governance-retention", valid_601693
  var valid_601694 = header.getOrDefault("x-amz-request-payer")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = newJString("requester"))
  if valid_601694 != nil:
    section.add "x-amz-request-payer", valid_601694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601696: Call_DeleteObjects_601686; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  let valid = call_601696.validator(path, query, header, formData, body)
  let scheme = call_601696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601696.url(scheme.get, call_601696.host, call_601696.base,
                         call_601696.route, valid.getOrDefault("path"))
  result = hook(call_601696, url, valid)

proc call*(call_601697: Call_DeleteObjects_601686; Bucket: string; body: JsonNode;
          delete: bool): Recallable =
  ## deleteObjects
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   delete: bool (required)
  var path_601698 = newJObject()
  var query_601699 = newJObject()
  var body_601700 = newJObject()
  add(path_601698, "Bucket", newJString(Bucket))
  if body != nil:
    body_601700 = body
  add(query_601699, "delete", newJBool(delete))
  result = call_601697.call(path_601698, query_601699, nil, nil, body_601700)

var deleteObjects* = Call_DeleteObjects_601686(name: "deleteObjects",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com", route: "/{Bucket}#delete",
    validator: validate_DeleteObjects_601687, base: "/", url: url_DeleteObjects_601688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_601711 = ref object of OpenApiRestCall_600426
proc url_PutPublicAccessBlock_601713(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#publicAccessBlock")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutPublicAccessBlock_601712(path: JsonNode; query: JsonNode;
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
  var valid_601714 = path.getOrDefault("Bucket")
  valid_601714 = validateParameter(valid_601714, JString, required = true,
                                 default = nil)
  if valid_601714 != nil:
    section.add "Bucket", valid_601714
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_601715 = query.getOrDefault("publicAccessBlock")
  valid_601715 = validateParameter(valid_601715, JBool, required = true, default = nil)
  if valid_601715 != nil:
    section.add "publicAccessBlock", valid_601715
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash of the <code>PutPublicAccessBlock</code> request body. 
  section = newJObject()
  var valid_601716 = header.getOrDefault("x-amz-security-token")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "x-amz-security-token", valid_601716
  var valid_601717 = header.getOrDefault("Content-MD5")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "Content-MD5", valid_601717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601719: Call_PutPublicAccessBlock_601711; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_601719.validator(path, query, header, formData, body)
  let scheme = call_601719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601719.url(scheme.get, call_601719.host, call_601719.base,
                         call_601719.route, valid.getOrDefault("path"))
  result = hook(call_601719, url, valid)

proc call*(call_601720: Call_PutPublicAccessBlock_601711; publicAccessBlock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to set.
  ##   body: JObject (required)
  var path_601721 = newJObject()
  var query_601722 = newJObject()
  var body_601723 = newJObject()
  add(query_601722, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_601721, "Bucket", newJString(Bucket))
  if body != nil:
    body_601723 = body
  result = call_601720.call(path_601721, query_601722, nil, nil, body_601723)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_601711(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_PutPublicAccessBlock_601712, base: "/",
    url: url_PutPublicAccessBlock_601713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_601701 = ref object of OpenApiRestCall_600426
proc url_GetPublicAccessBlock_601703(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#publicAccessBlock")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetPublicAccessBlock_601702(path: JsonNode; query: JsonNode;
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
  var valid_601704 = path.getOrDefault("Bucket")
  valid_601704 = validateParameter(valid_601704, JString, required = true,
                                 default = nil)
  if valid_601704 != nil:
    section.add "Bucket", valid_601704
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_601705 = query.getOrDefault("publicAccessBlock")
  valid_601705 = validateParameter(valid_601705, JBool, required = true, default = nil)
  if valid_601705 != nil:
    section.add "publicAccessBlock", valid_601705
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601706 = header.getOrDefault("x-amz-security-token")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "x-amz-security-token", valid_601706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601707: Call_GetPublicAccessBlock_601701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_601707.validator(path, query, header, formData, body)
  let scheme = call_601707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601707.url(scheme.get, call_601707.host, call_601707.base,
                         call_601707.route, valid.getOrDefault("path"))
  result = hook(call_601707, url, valid)

proc call*(call_601708: Call_GetPublicAccessBlock_601701; publicAccessBlock: bool;
          Bucket: string): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to retrieve. 
  var path_601709 = newJObject()
  var query_601710 = newJObject()
  add(query_601710, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_601709, "Bucket", newJString(Bucket))
  result = call_601708.call(path_601709, query_601710, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_601701(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_GetPublicAccessBlock_601702, base: "/",
    url: url_GetPublicAccessBlock_601703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_601724 = ref object of OpenApiRestCall_600426
proc url_DeletePublicAccessBlock_601726(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#publicAccessBlock")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeletePublicAccessBlock_601725(path: JsonNode; query: JsonNode;
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
  var valid_601727 = path.getOrDefault("Bucket")
  valid_601727 = validateParameter(valid_601727, JString, required = true,
                                 default = nil)
  if valid_601727 != nil:
    section.add "Bucket", valid_601727
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_601728 = query.getOrDefault("publicAccessBlock")
  valid_601728 = validateParameter(valid_601728, JBool, required = true, default = nil)
  if valid_601728 != nil:
    section.add "publicAccessBlock", valid_601728
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601729 = header.getOrDefault("x-amz-security-token")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "x-amz-security-token", valid_601729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601730: Call_DeletePublicAccessBlock_601724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ## 
  let valid = call_601730.validator(path, query, header, formData, body)
  let scheme = call_601730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601730.url(scheme.get, call_601730.host, call_601730.base,
                         call_601730.route, valid.getOrDefault("path"))
  result = hook(call_601730, url, valid)

proc call*(call_601731: Call_DeletePublicAccessBlock_601724;
          publicAccessBlock: bool; Bucket: string): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to delete. 
  var path_601732 = newJObject()
  var query_601733 = newJObject()
  add(query_601733, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_601732, "Bucket", newJString(Bucket))
  result = call_601731.call(path_601732, query_601733, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_601724(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_DeletePublicAccessBlock_601725, base: "/",
    url: url_DeletePublicAccessBlock_601726, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAccelerateConfiguration_601744 = ref object of OpenApiRestCall_600426
proc url_PutBucketAccelerateConfiguration_601746(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#accelerate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketAccelerateConfiguration_601745(path: JsonNode;
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
  var valid_601747 = path.getOrDefault("Bucket")
  valid_601747 = validateParameter(valid_601747, JString, required = true,
                                 default = nil)
  if valid_601747 != nil:
    section.add "Bucket", valid_601747
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_601748 = query.getOrDefault("accelerate")
  valid_601748 = validateParameter(valid_601748, JBool, required = true, default = nil)
  if valid_601748 != nil:
    section.add "accelerate", valid_601748
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601749 = header.getOrDefault("x-amz-security-token")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "x-amz-security-token", valid_601749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601751: Call_PutBucketAccelerateConfiguration_601744;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the accelerate configuration of an existing bucket.
  ## 
  let valid = call_601751.validator(path, query, header, formData, body)
  let scheme = call_601751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601751.url(scheme.get, call_601751.host, call_601751.base,
                         call_601751.route, valid.getOrDefault("path"))
  result = hook(call_601751, url, valid)

proc call*(call_601752: Call_PutBucketAccelerateConfiguration_601744;
          accelerate: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAccelerateConfiguration
  ## Sets the accelerate configuration of an existing bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is set.
  ##   body: JObject (required)
  var path_601753 = newJObject()
  var query_601754 = newJObject()
  var body_601755 = newJObject()
  add(query_601754, "accelerate", newJBool(accelerate))
  add(path_601753, "Bucket", newJString(Bucket))
  if body != nil:
    body_601755 = body
  result = call_601752.call(path_601753, query_601754, nil, nil, body_601755)

var putBucketAccelerateConfiguration* = Call_PutBucketAccelerateConfiguration_601744(
    name: "putBucketAccelerateConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_PutBucketAccelerateConfiguration_601745, base: "/",
    url: url_PutBucketAccelerateConfiguration_601746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAccelerateConfiguration_601734 = ref object of OpenApiRestCall_600426
proc url_GetBucketAccelerateConfiguration_601736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#accelerate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketAccelerateConfiguration_601735(path: JsonNode;
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
  var valid_601737 = path.getOrDefault("Bucket")
  valid_601737 = validateParameter(valid_601737, JString, required = true,
                                 default = nil)
  if valid_601737 != nil:
    section.add "Bucket", valid_601737
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_601738 = query.getOrDefault("accelerate")
  valid_601738 = validateParameter(valid_601738, JBool, required = true, default = nil)
  if valid_601738 != nil:
    section.add "accelerate", valid_601738
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601739 = header.getOrDefault("x-amz-security-token")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "x-amz-security-token", valid_601739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601740: Call_GetBucketAccelerateConfiguration_601734;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the accelerate configuration of a bucket.
  ## 
  let valid = call_601740.validator(path, query, header, formData, body)
  let scheme = call_601740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601740.url(scheme.get, call_601740.host, call_601740.base,
                         call_601740.route, valid.getOrDefault("path"))
  result = hook(call_601740, url, valid)

proc call*(call_601741: Call_GetBucketAccelerateConfiguration_601734;
          accelerate: bool; Bucket: string): Recallable =
  ## getBucketAccelerateConfiguration
  ## Returns the accelerate configuration of a bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is retrieved.
  var path_601742 = newJObject()
  var query_601743 = newJObject()
  add(query_601743, "accelerate", newJBool(accelerate))
  add(path_601742, "Bucket", newJString(Bucket))
  result = call_601741.call(path_601742, query_601743, nil, nil, nil)

var getBucketAccelerateConfiguration* = Call_GetBucketAccelerateConfiguration_601734(
    name: "getBucketAccelerateConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_GetBucketAccelerateConfiguration_601735, base: "/",
    url: url_GetBucketAccelerateConfiguration_601736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAcl_601766 = ref object of OpenApiRestCall_600426
proc url_PutBucketAcl_601768(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#acl")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketAcl_601767(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601769 = path.getOrDefault("Bucket")
  valid_601769 = validateParameter(valid_601769, JString, required = true,
                                 default = nil)
  if valid_601769 != nil:
    section.add "Bucket", valid_601769
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_601770 = query.getOrDefault("acl")
  valid_601770 = validateParameter(valid_601770, JBool, required = true, default = nil)
  if valid_601770 != nil:
    section.add "acl", valid_601770
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
  var valid_601771 = header.getOrDefault("x-amz-security-token")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "x-amz-security-token", valid_601771
  var valid_601772 = header.getOrDefault("Content-MD5")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "Content-MD5", valid_601772
  var valid_601773 = header.getOrDefault("x-amz-acl")
  valid_601773 = validateParameter(valid_601773, JString, required = false,
                                 default = newJString("private"))
  if valid_601773 != nil:
    section.add "x-amz-acl", valid_601773
  var valid_601774 = header.getOrDefault("x-amz-grant-read")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "x-amz-grant-read", valid_601774
  var valid_601775 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "x-amz-grant-read-acp", valid_601775
  var valid_601776 = header.getOrDefault("x-amz-grant-write")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "x-amz-grant-write", valid_601776
  var valid_601777 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "x-amz-grant-write-acp", valid_601777
  var valid_601778 = header.getOrDefault("x-amz-grant-full-control")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "x-amz-grant-full-control", valid_601778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601780: Call_PutBucketAcl_601766; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  let valid = call_601780.validator(path, query, header, formData, body)
  let scheme = call_601780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601780.url(scheme.get, call_601780.host, call_601780.base,
                         call_601780.route, valid.getOrDefault("path"))
  result = hook(call_601780, url, valid)

proc call*(call_601781: Call_PutBucketAcl_601766; acl: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketAcl
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601782 = newJObject()
  var query_601783 = newJObject()
  var body_601784 = newJObject()
  add(query_601783, "acl", newJBool(acl))
  add(path_601782, "Bucket", newJString(Bucket))
  if body != nil:
    body_601784 = body
  result = call_601781.call(path_601782, query_601783, nil, nil, body_601784)

var putBucketAcl* = Call_PutBucketAcl_601766(name: "putBucketAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_PutBucketAcl_601767, base: "/", url: url_PutBucketAcl_601768,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAcl_601756 = ref object of OpenApiRestCall_600426
proc url_GetBucketAcl_601758(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#acl")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketAcl_601757(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601759 = path.getOrDefault("Bucket")
  valid_601759 = validateParameter(valid_601759, JString, required = true,
                                 default = nil)
  if valid_601759 != nil:
    section.add "Bucket", valid_601759
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_601760 = query.getOrDefault("acl")
  valid_601760 = validateParameter(valid_601760, JBool, required = true, default = nil)
  if valid_601760 != nil:
    section.add "acl", valid_601760
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601761 = header.getOrDefault("x-amz-security-token")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "x-amz-security-token", valid_601761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601762: Call_GetBucketAcl_601756; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the access control policy for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  let valid = call_601762.validator(path, query, header, formData, body)
  let scheme = call_601762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601762.url(scheme.get, call_601762.host, call_601762.base,
                         call_601762.route, valid.getOrDefault("path"))
  result = hook(call_601762, url, valid)

proc call*(call_601763: Call_GetBucketAcl_601756; acl: bool; Bucket: string): Recallable =
  ## getBucketAcl
  ## Gets the access control policy for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601764 = newJObject()
  var query_601765 = newJObject()
  add(query_601765, "acl", newJBool(acl))
  add(path_601764, "Bucket", newJString(Bucket))
  result = call_601763.call(path_601764, query_601765, nil, nil, nil)

var getBucketAcl* = Call_GetBucketAcl_601756(name: "getBucketAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_GetBucketAcl_601757, base: "/", url: url_GetBucketAcl_601758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycle_601795 = ref object of OpenApiRestCall_600426
proc url_PutBucketLifecycle_601797(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#lifecycle&deprecated!")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketLifecycle_601796(path: JsonNode; query: JsonNode;
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
  var valid_601798 = path.getOrDefault("Bucket")
  valid_601798 = validateParameter(valid_601798, JString, required = true,
                                 default = nil)
  if valid_601798 != nil:
    section.add "Bucket", valid_601798
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_601799 = query.getOrDefault("lifecycle")
  valid_601799 = validateParameter(valid_601799, JBool, required = true, default = nil)
  if valid_601799 != nil:
    section.add "lifecycle", valid_601799
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601800 = header.getOrDefault("x-amz-security-token")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "x-amz-security-token", valid_601800
  var valid_601801 = header.getOrDefault("Content-MD5")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "Content-MD5", valid_601801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601803: Call_PutBucketLifecycle_601795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  let valid = call_601803.validator(path, query, header, formData, body)
  let scheme = call_601803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601803.url(scheme.get, call_601803.host, call_601803.base,
                         call_601803.route, valid.getOrDefault("path"))
  result = hook(call_601803, url, valid)

proc call*(call_601804: Call_PutBucketLifecycle_601795; Bucket: string;
          lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycle
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_601805 = newJObject()
  var query_601806 = newJObject()
  var body_601807 = newJObject()
  add(path_601805, "Bucket", newJString(Bucket))
  add(query_601806, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_601807 = body
  result = call_601804.call(path_601805, query_601806, nil, nil, body_601807)

var putBucketLifecycle* = Call_PutBucketLifecycle_601795(
    name: "putBucketLifecycle", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_PutBucketLifecycle_601796, base: "/",
    url: url_PutBucketLifecycle_601797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycle_601785 = ref object of OpenApiRestCall_600426
proc url_GetBucketLifecycle_601787(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#lifecycle&deprecated!")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketLifecycle_601786(path: JsonNode; query: JsonNode;
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
  var valid_601788 = path.getOrDefault("Bucket")
  valid_601788 = validateParameter(valid_601788, JString, required = true,
                                 default = nil)
  if valid_601788 != nil:
    section.add "Bucket", valid_601788
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_601789 = query.getOrDefault("lifecycle")
  valid_601789 = validateParameter(valid_601789, JBool, required = true, default = nil)
  if valid_601789 != nil:
    section.add "lifecycle", valid_601789
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601790 = header.getOrDefault("x-amz-security-token")
  valid_601790 = validateParameter(valid_601790, JString, required = false,
                                 default = nil)
  if valid_601790 != nil:
    section.add "x-amz-security-token", valid_601790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601791: Call_GetBucketLifecycle_601785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  let valid = call_601791.validator(path, query, header, formData, body)
  let scheme = call_601791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601791.url(scheme.get, call_601791.host, call_601791.base,
                         call_601791.route, valid.getOrDefault("path"))
  result = hook(call_601791, url, valid)

proc call*(call_601792: Call_GetBucketLifecycle_601785; Bucket: string;
          lifecycle: bool): Recallable =
  ## getBucketLifecycle
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_601793 = newJObject()
  var query_601794 = newJObject()
  add(path_601793, "Bucket", newJString(Bucket))
  add(query_601794, "lifecycle", newJBool(lifecycle))
  result = call_601792.call(path_601793, query_601794, nil, nil, nil)

var getBucketLifecycle* = Call_GetBucketLifecycle_601785(
    name: "getBucketLifecycle", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_GetBucketLifecycle_601786, base: "/",
    url: url_GetBucketLifecycle_601787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLocation_601808 = ref object of OpenApiRestCall_600426
proc url_GetBucketLocation_601810(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#location")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketLocation_601809(path: JsonNode; query: JsonNode;
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
  var valid_601811 = path.getOrDefault("Bucket")
  valid_601811 = validateParameter(valid_601811, JString, required = true,
                                 default = nil)
  if valid_601811 != nil:
    section.add "Bucket", valid_601811
  result.add "path", section
  ## parameters in `query` object:
  ##   location: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `location` field"
  var valid_601812 = query.getOrDefault("location")
  valid_601812 = validateParameter(valid_601812, JBool, required = true, default = nil)
  if valid_601812 != nil:
    section.add "location", valid_601812
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601813 = header.getOrDefault("x-amz-security-token")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "x-amz-security-token", valid_601813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601814: Call_GetBucketLocation_601808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the region the bucket resides in.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  let valid = call_601814.validator(path, query, header, formData, body)
  let scheme = call_601814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601814.url(scheme.get, call_601814.host, call_601814.base,
                         call_601814.route, valid.getOrDefault("path"))
  result = hook(call_601814, url, valid)

proc call*(call_601815: Call_GetBucketLocation_601808; location: bool; Bucket: string): Recallable =
  ## getBucketLocation
  ## Returns the region the bucket resides in.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  ##   location: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601816 = newJObject()
  var query_601817 = newJObject()
  add(query_601817, "location", newJBool(location))
  add(path_601816, "Bucket", newJString(Bucket))
  result = call_601815.call(path_601816, query_601817, nil, nil, nil)

var getBucketLocation* = Call_GetBucketLocation_601808(name: "getBucketLocation",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#location",
    validator: validate_GetBucketLocation_601809, base: "/",
    url: url_GetBucketLocation_601810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLogging_601828 = ref object of OpenApiRestCall_600426
proc url_PutBucketLogging_601830(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#logging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketLogging_601829(path: JsonNode; query: JsonNode;
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
  var valid_601831 = path.getOrDefault("Bucket")
  valid_601831 = validateParameter(valid_601831, JString, required = true,
                                 default = nil)
  if valid_601831 != nil:
    section.add "Bucket", valid_601831
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_601832 = query.getOrDefault("logging")
  valid_601832 = validateParameter(valid_601832, JBool, required = true, default = nil)
  if valid_601832 != nil:
    section.add "logging", valid_601832
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601833 = header.getOrDefault("x-amz-security-token")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "x-amz-security-token", valid_601833
  var valid_601834 = header.getOrDefault("Content-MD5")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "Content-MD5", valid_601834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601836: Call_PutBucketLogging_601828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  let valid = call_601836.validator(path, query, header, formData, body)
  let scheme = call_601836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601836.url(scheme.get, call_601836.host, call_601836.base,
                         call_601836.route, valid.getOrDefault("path"))
  result = hook(call_601836, url, valid)

proc call*(call_601837: Call_PutBucketLogging_601828; logging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketLogging
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601838 = newJObject()
  var query_601839 = newJObject()
  var body_601840 = newJObject()
  add(query_601839, "logging", newJBool(logging))
  add(path_601838, "Bucket", newJString(Bucket))
  if body != nil:
    body_601840 = body
  result = call_601837.call(path_601838, query_601839, nil, nil, body_601840)

var putBucketLogging* = Call_PutBucketLogging_601828(name: "putBucketLogging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_PutBucketLogging_601829, base: "/",
    url: url_PutBucketLogging_601830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLogging_601818 = ref object of OpenApiRestCall_600426
proc url_GetBucketLogging_601820(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#logging")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketLogging_601819(path: JsonNode; query: JsonNode;
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
  var valid_601821 = path.getOrDefault("Bucket")
  valid_601821 = validateParameter(valid_601821, JString, required = true,
                                 default = nil)
  if valid_601821 != nil:
    section.add "Bucket", valid_601821
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_601822 = query.getOrDefault("logging")
  valid_601822 = validateParameter(valid_601822, JBool, required = true, default = nil)
  if valid_601822 != nil:
    section.add "logging", valid_601822
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601823 = header.getOrDefault("x-amz-security-token")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "x-amz-security-token", valid_601823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601824: Call_GetBucketLogging_601818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  let valid = call_601824.validator(path, query, header, formData, body)
  let scheme = call_601824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601824.url(scheme.get, call_601824.host, call_601824.base,
                         call_601824.route, valid.getOrDefault("path"))
  result = hook(call_601824, url, valid)

proc call*(call_601825: Call_GetBucketLogging_601818; logging: bool; Bucket: string): Recallable =
  ## getBucketLogging
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601826 = newJObject()
  var query_601827 = newJObject()
  add(query_601827, "logging", newJBool(logging))
  add(path_601826, "Bucket", newJString(Bucket))
  result = call_601825.call(path_601826, query_601827, nil, nil, nil)

var getBucketLogging* = Call_GetBucketLogging_601818(name: "getBucketLogging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_GetBucketLogging_601819, base: "/",
    url: url_GetBucketLogging_601820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotificationConfiguration_601851 = ref object of OpenApiRestCall_600426
proc url_PutBucketNotificationConfiguration_601853(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#notification")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketNotificationConfiguration_601852(path: JsonNode;
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
  var valid_601854 = path.getOrDefault("Bucket")
  valid_601854 = validateParameter(valid_601854, JString, required = true,
                                 default = nil)
  if valid_601854 != nil:
    section.add "Bucket", valid_601854
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_601855 = query.getOrDefault("notification")
  valid_601855 = validateParameter(valid_601855, JBool, required = true, default = nil)
  if valid_601855 != nil:
    section.add "notification", valid_601855
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601856 = header.getOrDefault("x-amz-security-token")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "x-amz-security-token", valid_601856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601858: Call_PutBucketNotificationConfiguration_601851;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enables notifications of specified events for a bucket.
  ## 
  let valid = call_601858.validator(path, query, header, formData, body)
  let scheme = call_601858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601858.url(scheme.get, call_601858.host, call_601858.base,
                         call_601858.route, valid.getOrDefault("path"))
  result = hook(call_601858, url, valid)

proc call*(call_601859: Call_PutBucketNotificationConfiguration_601851;
          notification: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotificationConfiguration
  ## Enables notifications of specified events for a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601860 = newJObject()
  var query_601861 = newJObject()
  var body_601862 = newJObject()
  add(query_601861, "notification", newJBool(notification))
  add(path_601860, "Bucket", newJString(Bucket))
  if body != nil:
    body_601862 = body
  result = call_601859.call(path_601860, query_601861, nil, nil, body_601862)

var putBucketNotificationConfiguration* = Call_PutBucketNotificationConfiguration_601851(
    name: "putBucketNotificationConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_PutBucketNotificationConfiguration_601852, base: "/",
    url: url_PutBucketNotificationConfiguration_601853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotificationConfiguration_601841 = ref object of OpenApiRestCall_600426
proc url_GetBucketNotificationConfiguration_601843(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#notification")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketNotificationConfiguration_601842(path: JsonNode;
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
  var valid_601844 = path.getOrDefault("Bucket")
  valid_601844 = validateParameter(valid_601844, JString, required = true,
                                 default = nil)
  if valid_601844 != nil:
    section.add "Bucket", valid_601844
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_601845 = query.getOrDefault("notification")
  valid_601845 = validateParameter(valid_601845, JBool, required = true, default = nil)
  if valid_601845 != nil:
    section.add "notification", valid_601845
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601846 = header.getOrDefault("x-amz-security-token")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "x-amz-security-token", valid_601846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601847: Call_GetBucketNotificationConfiguration_601841;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the notification configuration of a bucket.
  ## 
  let valid = call_601847.validator(path, query, header, formData, body)
  let scheme = call_601847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601847.url(scheme.get, call_601847.host, call_601847.base,
                         call_601847.route, valid.getOrDefault("path"))
  result = hook(call_601847, url, valid)

proc call*(call_601848: Call_GetBucketNotificationConfiguration_601841;
          notification: bool; Bucket: string): Recallable =
  ## getBucketNotificationConfiguration
  ## Returns the notification configuration of a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_601849 = newJObject()
  var query_601850 = newJObject()
  add(query_601850, "notification", newJBool(notification))
  add(path_601849, "Bucket", newJString(Bucket))
  result = call_601848.call(path_601849, query_601850, nil, nil, nil)

var getBucketNotificationConfiguration* = Call_GetBucketNotificationConfiguration_601841(
    name: "getBucketNotificationConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_GetBucketNotificationConfiguration_601842, base: "/",
    url: url_GetBucketNotificationConfiguration_601843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotification_601873 = ref object of OpenApiRestCall_600426
proc url_PutBucketNotification_601875(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#notification&deprecated!")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketNotification_601874(path: JsonNode; query: JsonNode;
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
  var valid_601876 = path.getOrDefault("Bucket")
  valid_601876 = validateParameter(valid_601876, JString, required = true,
                                 default = nil)
  if valid_601876 != nil:
    section.add "Bucket", valid_601876
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_601877 = query.getOrDefault("notification")
  valid_601877 = validateParameter(valid_601877, JBool, required = true, default = nil)
  if valid_601877 != nil:
    section.add "notification", valid_601877
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601878 = header.getOrDefault("x-amz-security-token")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "x-amz-security-token", valid_601878
  var valid_601879 = header.getOrDefault("Content-MD5")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "Content-MD5", valid_601879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601881: Call_PutBucketNotification_601873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  let valid = call_601881.validator(path, query, header, formData, body)
  let scheme = call_601881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601881.url(scheme.get, call_601881.host, call_601881.base,
                         call_601881.route, valid.getOrDefault("path"))
  result = hook(call_601881, url, valid)

proc call*(call_601882: Call_PutBucketNotification_601873; notification: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotification
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601883 = newJObject()
  var query_601884 = newJObject()
  var body_601885 = newJObject()
  add(query_601884, "notification", newJBool(notification))
  add(path_601883, "Bucket", newJString(Bucket))
  if body != nil:
    body_601885 = body
  result = call_601882.call(path_601883, query_601884, nil, nil, body_601885)

var putBucketNotification* = Call_PutBucketNotification_601873(
    name: "putBucketNotification", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_PutBucketNotification_601874, base: "/",
    url: url_PutBucketNotification_601875, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotification_601863 = ref object of OpenApiRestCall_600426
proc url_GetBucketNotification_601865(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#notification&deprecated!")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketNotification_601864(path: JsonNode; query: JsonNode;
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
  var valid_601866 = path.getOrDefault("Bucket")
  valid_601866 = validateParameter(valid_601866, JString, required = true,
                                 default = nil)
  if valid_601866 != nil:
    section.add "Bucket", valid_601866
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_601867 = query.getOrDefault("notification")
  valid_601867 = validateParameter(valid_601867, JBool, required = true, default = nil)
  if valid_601867 != nil:
    section.add "notification", valid_601867
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601868 = header.getOrDefault("x-amz-security-token")
  valid_601868 = validateParameter(valid_601868, JString, required = false,
                                 default = nil)
  if valid_601868 != nil:
    section.add "x-amz-security-token", valid_601868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601869: Call_GetBucketNotification_601863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  let valid = call_601869.validator(path, query, header, formData, body)
  let scheme = call_601869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601869.url(scheme.get, call_601869.host, call_601869.base,
                         call_601869.route, valid.getOrDefault("path"))
  result = hook(call_601869, url, valid)

proc call*(call_601870: Call_GetBucketNotification_601863; notification: bool;
          Bucket: string): Recallable =
  ## getBucketNotification
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_601871 = newJObject()
  var query_601872 = newJObject()
  add(query_601872, "notification", newJBool(notification))
  add(path_601871, "Bucket", newJString(Bucket))
  result = call_601870.call(path_601871, query_601872, nil, nil, nil)

var getBucketNotification* = Call_GetBucketNotification_601863(
    name: "getBucketNotification", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_GetBucketNotification_601864, base: "/",
    url: url_GetBucketNotification_601865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicyStatus_601886 = ref object of OpenApiRestCall_600426
proc url_GetBucketPolicyStatus_601888(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#policyStatus")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketPolicyStatus_601887(path: JsonNode; query: JsonNode;
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
  var valid_601889 = path.getOrDefault("Bucket")
  valid_601889 = validateParameter(valid_601889, JString, required = true,
                                 default = nil)
  if valid_601889 != nil:
    section.add "Bucket", valid_601889
  result.add "path", section
  ## parameters in `query` object:
  ##   policyStatus: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `policyStatus` field"
  var valid_601890 = query.getOrDefault("policyStatus")
  valid_601890 = validateParameter(valid_601890, JBool, required = true, default = nil)
  if valid_601890 != nil:
    section.add "policyStatus", valid_601890
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601891 = header.getOrDefault("x-amz-security-token")
  valid_601891 = validateParameter(valid_601891, JString, required = false,
                                 default = nil)
  if valid_601891 != nil:
    section.add "x-amz-security-token", valid_601891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601892: Call_GetBucketPolicyStatus_601886; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ## 
  let valid = call_601892.validator(path, query, header, formData, body)
  let scheme = call_601892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601892.url(scheme.get, call_601892.host, call_601892.base,
                         call_601892.route, valid.getOrDefault("path"))
  result = hook(call_601892, url, valid)

proc call*(call_601893: Call_GetBucketPolicyStatus_601886; policyStatus: bool;
          Bucket: string): Recallable =
  ## getBucketPolicyStatus
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ##   policyStatus: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose policy status you want to retrieve.
  var path_601894 = newJObject()
  var query_601895 = newJObject()
  add(query_601895, "policyStatus", newJBool(policyStatus))
  add(path_601894, "Bucket", newJString(Bucket))
  result = call_601893.call(path_601894, query_601895, nil, nil, nil)

var getBucketPolicyStatus* = Call_GetBucketPolicyStatus_601886(
    name: "getBucketPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#policyStatus",
    validator: validate_GetBucketPolicyStatus_601887, base: "/",
    url: url_GetBucketPolicyStatus_601888, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketRequestPayment_601906 = ref object of OpenApiRestCall_600426
proc url_PutBucketRequestPayment_601908(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#requestPayment")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketRequestPayment_601907(path: JsonNode; query: JsonNode;
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
  var valid_601909 = path.getOrDefault("Bucket")
  valid_601909 = validateParameter(valid_601909, JString, required = true,
                                 default = nil)
  if valid_601909 != nil:
    section.add "Bucket", valid_601909
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_601910 = query.getOrDefault("requestPayment")
  valid_601910 = validateParameter(valid_601910, JBool, required = true, default = nil)
  if valid_601910 != nil:
    section.add "requestPayment", valid_601910
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_601911 = header.getOrDefault("x-amz-security-token")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "x-amz-security-token", valid_601911
  var valid_601912 = header.getOrDefault("Content-MD5")
  valid_601912 = validateParameter(valid_601912, JString, required = false,
                                 default = nil)
  if valid_601912 != nil:
    section.add "Content-MD5", valid_601912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601914: Call_PutBucketRequestPayment_601906; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  let valid = call_601914.validator(path, query, header, formData, body)
  let scheme = call_601914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601914.url(scheme.get, call_601914.host, call_601914.base,
                         call_601914.route, valid.getOrDefault("path"))
  result = hook(call_601914, url, valid)

proc call*(call_601915: Call_PutBucketRequestPayment_601906; requestPayment: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketRequestPayment
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_601916 = newJObject()
  var query_601917 = newJObject()
  var body_601918 = newJObject()
  add(query_601917, "requestPayment", newJBool(requestPayment))
  add(path_601916, "Bucket", newJString(Bucket))
  if body != nil:
    body_601918 = body
  result = call_601915.call(path_601916, query_601917, nil, nil, body_601918)

var putBucketRequestPayment* = Call_PutBucketRequestPayment_601906(
    name: "putBucketRequestPayment", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_PutBucketRequestPayment_601907, base: "/",
    url: url_PutBucketRequestPayment_601908, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketRequestPayment_601896 = ref object of OpenApiRestCall_600426
proc url_GetBucketRequestPayment_601898(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#requestPayment")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketRequestPayment_601897(path: JsonNode; query: JsonNode;
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
  var valid_601899 = path.getOrDefault("Bucket")
  valid_601899 = validateParameter(valid_601899, JString, required = true,
                                 default = nil)
  if valid_601899 != nil:
    section.add "Bucket", valid_601899
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_601900 = query.getOrDefault("requestPayment")
  valid_601900 = validateParameter(valid_601900, JBool, required = true, default = nil)
  if valid_601900 != nil:
    section.add "requestPayment", valid_601900
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601901 = header.getOrDefault("x-amz-security-token")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "x-amz-security-token", valid_601901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601902: Call_GetBucketRequestPayment_601896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the request payment configuration of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  let valid = call_601902.validator(path, query, header, formData, body)
  let scheme = call_601902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601902.url(scheme.get, call_601902.host, call_601902.base,
                         call_601902.route, valid.getOrDefault("path"))
  result = hook(call_601902, url, valid)

proc call*(call_601903: Call_GetBucketRequestPayment_601896; requestPayment: bool;
          Bucket: string): Recallable =
  ## getBucketRequestPayment
  ## Returns the request payment configuration of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_601904 = newJObject()
  var query_601905 = newJObject()
  add(query_601905, "requestPayment", newJBool(requestPayment))
  add(path_601904, "Bucket", newJString(Bucket))
  result = call_601903.call(path_601904, query_601905, nil, nil, nil)

var getBucketRequestPayment* = Call_GetBucketRequestPayment_601896(
    name: "getBucketRequestPayment", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_GetBucketRequestPayment_601897, base: "/",
    url: url_GetBucketRequestPayment_601898, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketVersioning_601929 = ref object of OpenApiRestCall_600426
proc url_PutBucketVersioning_601931(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#versioning")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutBucketVersioning_601930(path: JsonNode; query: JsonNode;
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
  var valid_601932 = path.getOrDefault("Bucket")
  valid_601932 = validateParameter(valid_601932, JString, required = true,
                                 default = nil)
  if valid_601932 != nil:
    section.add "Bucket", valid_601932
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_601933 = query.getOrDefault("versioning")
  valid_601933 = validateParameter(valid_601933, JBool, required = true, default = nil)
  if valid_601933 != nil:
    section.add "versioning", valid_601933
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  section = newJObject()
  var valid_601934 = header.getOrDefault("x-amz-security-token")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "x-amz-security-token", valid_601934
  var valid_601935 = header.getOrDefault("Content-MD5")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "Content-MD5", valid_601935
  var valid_601936 = header.getOrDefault("x-amz-mfa")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "x-amz-mfa", valid_601936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601938: Call_PutBucketVersioning_601929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  let valid = call_601938.validator(path, query, header, formData, body)
  let scheme = call_601938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601938.url(scheme.get, call_601938.host, call_601938.base,
                         call_601938.route, valid.getOrDefault("path"))
  result = hook(call_601938, url, valid)

proc call*(call_601939: Call_PutBucketVersioning_601929; Bucket: string;
          body: JsonNode; versioning: bool): Recallable =
  ## putBucketVersioning
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   versioning: bool (required)
  var path_601940 = newJObject()
  var query_601941 = newJObject()
  var body_601942 = newJObject()
  add(path_601940, "Bucket", newJString(Bucket))
  if body != nil:
    body_601942 = body
  add(query_601941, "versioning", newJBool(versioning))
  result = call_601939.call(path_601940, query_601941, nil, nil, body_601942)

var putBucketVersioning* = Call_PutBucketVersioning_601929(
    name: "putBucketVersioning", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_PutBucketVersioning_601930,
    base: "/", url: url_PutBucketVersioning_601931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketVersioning_601919 = ref object of OpenApiRestCall_600426
proc url_GetBucketVersioning_601921(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#versioning")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBucketVersioning_601920(path: JsonNode; query: JsonNode;
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
  var valid_601922 = path.getOrDefault("Bucket")
  valid_601922 = validateParameter(valid_601922, JString, required = true,
                                 default = nil)
  if valid_601922 != nil:
    section.add "Bucket", valid_601922
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_601923 = query.getOrDefault("versioning")
  valid_601923 = validateParameter(valid_601923, JBool, required = true, default = nil)
  if valid_601923 != nil:
    section.add "versioning", valid_601923
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_601924 = header.getOrDefault("x-amz-security-token")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "x-amz-security-token", valid_601924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601925: Call_GetBucketVersioning_601919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the versioning state of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  let valid = call_601925.validator(path, query, header, formData, body)
  let scheme = call_601925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601925.url(scheme.get, call_601925.host, call_601925.base,
                         call_601925.route, valid.getOrDefault("path"))
  result = hook(call_601925, url, valid)

proc call*(call_601926: Call_GetBucketVersioning_601919; Bucket: string;
          versioning: bool): Recallable =
  ## getBucketVersioning
  ## Returns the versioning state of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versioning: bool (required)
  var path_601927 = newJObject()
  var query_601928 = newJObject()
  add(path_601927, "Bucket", newJString(Bucket))
  add(query_601928, "versioning", newJBool(versioning))
  result = call_601926.call(path_601927, query_601928, nil, nil, nil)

var getBucketVersioning* = Call_GetBucketVersioning_601919(
    name: "getBucketVersioning", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_GetBucketVersioning_601920,
    base: "/", url: url_GetBucketVersioning_601921,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectAcl_601956 = ref object of OpenApiRestCall_600426
proc url_PutObjectAcl_601958(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutObjectAcl_601957(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601959 = path.getOrDefault("Key")
  valid_601959 = validateParameter(valid_601959, JString, required = true,
                                 default = nil)
  if valid_601959 != nil:
    section.add "Key", valid_601959
  var valid_601960 = path.getOrDefault("Bucket")
  valid_601960 = validateParameter(valid_601960, JString, required = true,
                                 default = nil)
  if valid_601960 != nil:
    section.add "Bucket", valid_601960
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_601961 = query.getOrDefault("versionId")
  valid_601961 = validateParameter(valid_601961, JString, required = false,
                                 default = nil)
  if valid_601961 != nil:
    section.add "versionId", valid_601961
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_601962 = query.getOrDefault("acl")
  valid_601962 = validateParameter(valid_601962, JBool, required = true, default = nil)
  if valid_601962 != nil:
    section.add "acl", valid_601962
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
  var valid_601963 = header.getOrDefault("x-amz-security-token")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "x-amz-security-token", valid_601963
  var valid_601964 = header.getOrDefault("Content-MD5")
  valid_601964 = validateParameter(valid_601964, JString, required = false,
                                 default = nil)
  if valid_601964 != nil:
    section.add "Content-MD5", valid_601964
  var valid_601965 = header.getOrDefault("x-amz-acl")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = newJString("private"))
  if valid_601965 != nil:
    section.add "x-amz-acl", valid_601965
  var valid_601966 = header.getOrDefault("x-amz-grant-read")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "x-amz-grant-read", valid_601966
  var valid_601967 = header.getOrDefault("x-amz-grant-read-acp")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "x-amz-grant-read-acp", valid_601967
  var valid_601968 = header.getOrDefault("x-amz-grant-write")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "x-amz-grant-write", valid_601968
  var valid_601969 = header.getOrDefault("x-amz-grant-write-acp")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "x-amz-grant-write-acp", valid_601969
  var valid_601970 = header.getOrDefault("x-amz-request-payer")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = newJString("requester"))
  if valid_601970 != nil:
    section.add "x-amz-request-payer", valid_601970
  var valid_601971 = header.getOrDefault("x-amz-grant-full-control")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "x-amz-grant-full-control", valid_601971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601973: Call_PutObjectAcl_601956; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  let valid = call_601973.validator(path, query, header, formData, body)
  let scheme = call_601973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601973.url(scheme.get, call_601973.host, call_601973.base,
                         call_601973.route, valid.getOrDefault("path"))
  result = hook(call_601973, url, valid)

proc call*(call_601974: Call_PutObjectAcl_601956; Key: string; acl: bool;
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
  var path_601975 = newJObject()
  var query_601976 = newJObject()
  var body_601977 = newJObject()
  add(query_601976, "versionId", newJString(versionId))
  add(path_601975, "Key", newJString(Key))
  add(query_601976, "acl", newJBool(acl))
  add(path_601975, "Bucket", newJString(Bucket))
  if body != nil:
    body_601977 = body
  result = call_601974.call(path_601975, query_601976, nil, nil, body_601977)

var putObjectAcl* = Call_PutObjectAcl_601956(name: "putObjectAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_PutObjectAcl_601957,
    base: "/", url: url_PutObjectAcl_601958, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAcl_601943 = ref object of OpenApiRestCall_600426
proc url_GetObjectAcl_601945(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetObjectAcl_601944(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601946 = path.getOrDefault("Key")
  valid_601946 = validateParameter(valid_601946, JString, required = true,
                                 default = nil)
  if valid_601946 != nil:
    section.add "Key", valid_601946
  var valid_601947 = path.getOrDefault("Bucket")
  valid_601947 = validateParameter(valid_601947, JString, required = true,
                                 default = nil)
  if valid_601947 != nil:
    section.add "Bucket", valid_601947
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_601948 = query.getOrDefault("versionId")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "versionId", valid_601948
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_601949 = query.getOrDefault("acl")
  valid_601949 = validateParameter(valid_601949, JBool, required = true, default = nil)
  if valid_601949 != nil:
    section.add "acl", valid_601949
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601950 = header.getOrDefault("x-amz-security-token")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "x-amz-security-token", valid_601950
  var valid_601951 = header.getOrDefault("x-amz-request-payer")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = newJString("requester"))
  if valid_601951 != nil:
    section.add "x-amz-request-payer", valid_601951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601952: Call_GetObjectAcl_601943; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access control list (ACL) of an object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  let valid = call_601952.validator(path, query, header, formData, body)
  let scheme = call_601952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601952.url(scheme.get, call_601952.host, call_601952.base,
                         call_601952.route, valid.getOrDefault("path"))
  result = hook(call_601952, url, valid)

proc call*(call_601953: Call_GetObjectAcl_601943; Key: string; acl: bool;
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
  var path_601954 = newJObject()
  var query_601955 = newJObject()
  add(query_601955, "versionId", newJString(versionId))
  add(path_601954, "Key", newJString(Key))
  add(query_601955, "acl", newJBool(acl))
  add(path_601954, "Bucket", newJString(Bucket))
  result = call_601953.call(path_601954, query_601955, nil, nil, nil)

var getObjectAcl* = Call_GetObjectAcl_601943(name: "getObjectAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_GetObjectAcl_601944,
    base: "/", url: url_GetObjectAcl_601945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLegalHold_601991 = ref object of OpenApiRestCall_600426
proc url_PutObjectLegalHold_601993(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutObjectLegalHold_601992(path: JsonNode; query: JsonNode;
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
  var valid_601994 = path.getOrDefault("Key")
  valid_601994 = validateParameter(valid_601994, JString, required = true,
                                 default = nil)
  if valid_601994 != nil:
    section.add "Key", valid_601994
  var valid_601995 = path.getOrDefault("Bucket")
  valid_601995 = validateParameter(valid_601995, JString, required = true,
                                 default = nil)
  if valid_601995 != nil:
    section.add "Bucket", valid_601995
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object that you want to place a Legal Hold on.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_601996 = query.getOrDefault("versionId")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "versionId", valid_601996
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_601997 = query.getOrDefault("legal-hold")
  valid_601997 = validateParameter(valid_601997, JBool, required = true, default = nil)
  if valid_601997 != nil:
    section.add "legal-hold", valid_601997
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601998 = header.getOrDefault("x-amz-security-token")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "x-amz-security-token", valid_601998
  var valid_601999 = header.getOrDefault("Content-MD5")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "Content-MD5", valid_601999
  var valid_602000 = header.getOrDefault("x-amz-request-payer")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = newJString("requester"))
  if valid_602000 != nil:
    section.add "x-amz-request-payer", valid_602000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602002: Call_PutObjectLegalHold_601991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a Legal Hold configuration to the specified object.
  ## 
  let valid = call_602002.validator(path, query, header, formData, body)
  let scheme = call_602002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602002.url(scheme.get, call_602002.host, call_602002.base,
                         call_602002.route, valid.getOrDefault("path"))
  result = hook(call_602002, url, valid)

proc call*(call_602003: Call_PutObjectLegalHold_601991; Key: string; legalHold: bool;
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
  var path_602004 = newJObject()
  var query_602005 = newJObject()
  var body_602006 = newJObject()
  add(query_602005, "versionId", newJString(versionId))
  add(path_602004, "Key", newJString(Key))
  add(query_602005, "legal-hold", newJBool(legalHold))
  add(path_602004, "Bucket", newJString(Bucket))
  if body != nil:
    body_602006 = body
  result = call_602003.call(path_602004, query_602005, nil, nil, body_602006)

var putObjectLegalHold* = Call_PutObjectLegalHold_601991(
    name: "putObjectLegalHold", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_PutObjectLegalHold_601992,
    base: "/", url: url_PutObjectLegalHold_601993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLegalHold_601978 = ref object of OpenApiRestCall_600426
proc url_GetObjectLegalHold_601980(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetObjectLegalHold_601979(path: JsonNode; query: JsonNode;
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
  var valid_601981 = path.getOrDefault("Key")
  valid_601981 = validateParameter(valid_601981, JString, required = true,
                                 default = nil)
  if valid_601981 != nil:
    section.add "Key", valid_601981
  var valid_601982 = path.getOrDefault("Bucket")
  valid_601982 = validateParameter(valid_601982, JString, required = true,
                                 default = nil)
  if valid_601982 != nil:
    section.add "Bucket", valid_601982
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object whose Legal Hold status you want to retrieve.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_601983 = query.getOrDefault("versionId")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "versionId", valid_601983
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_601984 = query.getOrDefault("legal-hold")
  valid_601984 = validateParameter(valid_601984, JBool, required = true, default = nil)
  if valid_601984 != nil:
    section.add "legal-hold", valid_601984
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_601985 = header.getOrDefault("x-amz-security-token")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "x-amz-security-token", valid_601985
  var valid_601986 = header.getOrDefault("x-amz-request-payer")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = newJString("requester"))
  if valid_601986 != nil:
    section.add "x-amz-request-payer", valid_601986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601987: Call_GetObjectLegalHold_601978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an object's current Legal Hold status.
  ## 
  let valid = call_601987.validator(path, query, header, formData, body)
  let scheme = call_601987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601987.url(scheme.get, call_601987.host, call_601987.base,
                         call_601987.route, valid.getOrDefault("path"))
  result = hook(call_601987, url, valid)

proc call*(call_601988: Call_GetObjectLegalHold_601978; Key: string; legalHold: bool;
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
  var path_601989 = newJObject()
  var query_601990 = newJObject()
  add(query_601990, "versionId", newJString(versionId))
  add(path_601989, "Key", newJString(Key))
  add(query_601990, "legal-hold", newJBool(legalHold))
  add(path_601989, "Bucket", newJString(Bucket))
  result = call_601988.call(path_601989, query_601990, nil, nil, nil)

var getObjectLegalHold* = Call_GetObjectLegalHold_601978(
    name: "getObjectLegalHold", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_GetObjectLegalHold_601979,
    base: "/", url: url_GetObjectLegalHold_601980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLockConfiguration_602017 = ref object of OpenApiRestCall_600426
proc url_PutObjectLockConfiguration_602019(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#object-lock")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutObjectLockConfiguration_602018(path: JsonNode; query: JsonNode;
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
  var valid_602020 = path.getOrDefault("Bucket")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = nil)
  if valid_602020 != nil:
    section.add "Bucket", valid_602020
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_602021 = query.getOrDefault("object-lock")
  valid_602021 = validateParameter(valid_602021, JBool, required = true, default = nil)
  if valid_602021 != nil:
    section.add "object-lock", valid_602021
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
  var valid_602022 = header.getOrDefault("x-amz-security-token")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "x-amz-security-token", valid_602022
  var valid_602023 = header.getOrDefault("Content-MD5")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "Content-MD5", valid_602023
  var valid_602024 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_602024
  var valid_602025 = header.getOrDefault("x-amz-request-payer")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = newJString("requester"))
  if valid_602025 != nil:
    section.add "x-amz-request-payer", valid_602025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602027: Call_PutObjectLockConfiguration_602017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_602027.validator(path, query, header, formData, body)
  let scheme = call_602027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602027.url(scheme.get, call_602027.host, call_602027.base,
                         call_602027.route, valid.getOrDefault("path"))
  result = hook(call_602027, url, valid)

proc call*(call_602028: Call_PutObjectLockConfiguration_602017; objectLock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putObjectLockConfiguration
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to create or replace.
  ##   body: JObject (required)
  var path_602029 = newJObject()
  var query_602030 = newJObject()
  var body_602031 = newJObject()
  add(query_602030, "object-lock", newJBool(objectLock))
  add(path_602029, "Bucket", newJString(Bucket))
  if body != nil:
    body_602031 = body
  result = call_602028.call(path_602029, query_602030, nil, nil, body_602031)

var putObjectLockConfiguration* = Call_PutObjectLockConfiguration_602017(
    name: "putObjectLockConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_PutObjectLockConfiguration_602018, base: "/",
    url: url_PutObjectLockConfiguration_602019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLockConfiguration_602007 = ref object of OpenApiRestCall_600426
proc url_GetObjectLockConfiguration_602009(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#object-lock")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetObjectLockConfiguration_602008(path: JsonNode; query: JsonNode;
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
  var valid_602010 = path.getOrDefault("Bucket")
  valid_602010 = validateParameter(valid_602010, JString, required = true,
                                 default = nil)
  if valid_602010 != nil:
    section.add "Bucket", valid_602010
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_602011 = query.getOrDefault("object-lock")
  valid_602011 = validateParameter(valid_602011, JBool, required = true, default = nil)
  if valid_602011 != nil:
    section.add "object-lock", valid_602011
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602012 = header.getOrDefault("x-amz-security-token")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "x-amz-security-token", valid_602012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602013: Call_GetObjectLockConfiguration_602007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_602013.validator(path, query, header, formData, body)
  let scheme = call_602013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602013.url(scheme.get, call_602013.host, call_602013.base,
                         call_602013.route, valid.getOrDefault("path"))
  result = hook(call_602013, url, valid)

proc call*(call_602014: Call_GetObjectLockConfiguration_602007; objectLock: bool;
          Bucket: string): Recallable =
  ## getObjectLockConfiguration
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to retrieve.
  var path_602015 = newJObject()
  var query_602016 = newJObject()
  add(query_602016, "object-lock", newJBool(objectLock))
  add(path_602015, "Bucket", newJString(Bucket))
  result = call_602014.call(path_602015, query_602016, nil, nil, nil)

var getObjectLockConfiguration* = Call_GetObjectLockConfiguration_602007(
    name: "getObjectLockConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_GetObjectLockConfiguration_602008, base: "/",
    url: url_GetObjectLockConfiguration_602009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectRetention_602045 = ref object of OpenApiRestCall_600426
proc url_PutObjectRetention_602047(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutObjectRetention_602046(path: JsonNode; query: JsonNode;
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
  var valid_602048 = path.getOrDefault("Key")
  valid_602048 = validateParameter(valid_602048, JString, required = true,
                                 default = nil)
  if valid_602048 != nil:
    section.add "Key", valid_602048
  var valid_602049 = path.getOrDefault("Bucket")
  valid_602049 = validateParameter(valid_602049, JString, required = true,
                                 default = nil)
  if valid_602049 != nil:
    section.add "Bucket", valid_602049
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object that you want to apply this Object Retention configuration to.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_602050 = query.getOrDefault("versionId")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "versionId", valid_602050
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_602051 = query.getOrDefault("retention")
  valid_602051 = validateParameter(valid_602051, JBool, required = true, default = nil)
  if valid_602051 != nil:
    section.add "retention", valid_602051
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
  var valid_602052 = header.getOrDefault("x-amz-security-token")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "x-amz-security-token", valid_602052
  var valid_602053 = header.getOrDefault("Content-MD5")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "Content-MD5", valid_602053
  var valid_602054 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_602054 = validateParameter(valid_602054, JBool, required = false, default = nil)
  if valid_602054 != nil:
    section.add "x-amz-bypass-governance-retention", valid_602054
  var valid_602055 = header.getOrDefault("x-amz-request-payer")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = newJString("requester"))
  if valid_602055 != nil:
    section.add "x-amz-request-payer", valid_602055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602057: Call_PutObjectRetention_602045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an Object Retention configuration on an object.
  ## 
  let valid = call_602057.validator(path, query, header, formData, body)
  let scheme = call_602057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602057.url(scheme.get, call_602057.host, call_602057.base,
                         call_602057.route, valid.getOrDefault("path"))
  result = hook(call_602057, url, valid)

proc call*(call_602058: Call_PutObjectRetention_602045; retention: bool; Key: string;
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
  var path_602059 = newJObject()
  var query_602060 = newJObject()
  var body_602061 = newJObject()
  add(query_602060, "versionId", newJString(versionId))
  add(query_602060, "retention", newJBool(retention))
  add(path_602059, "Key", newJString(Key))
  add(path_602059, "Bucket", newJString(Bucket))
  if body != nil:
    body_602061 = body
  result = call_602058.call(path_602059, query_602060, nil, nil, body_602061)

var putObjectRetention* = Call_PutObjectRetention_602045(
    name: "putObjectRetention", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_PutObjectRetention_602046,
    base: "/", url: url_PutObjectRetention_602047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectRetention_602032 = ref object of OpenApiRestCall_600426
proc url_GetObjectRetention_602034(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetObjectRetention_602033(path: JsonNode; query: JsonNode;
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
  var valid_602035 = path.getOrDefault("Key")
  valid_602035 = validateParameter(valid_602035, JString, required = true,
                                 default = nil)
  if valid_602035 != nil:
    section.add "Key", valid_602035
  var valid_602036 = path.getOrDefault("Bucket")
  valid_602036 = validateParameter(valid_602036, JString, required = true,
                                 default = nil)
  if valid_602036 != nil:
    section.add "Bucket", valid_602036
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object whose retention settings you want to retrieve.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_602037 = query.getOrDefault("versionId")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "versionId", valid_602037
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_602038 = query.getOrDefault("retention")
  valid_602038 = validateParameter(valid_602038, JBool, required = true, default = nil)
  if valid_602038 != nil:
    section.add "retention", valid_602038
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602039 = header.getOrDefault("x-amz-security-token")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "x-amz-security-token", valid_602039
  var valid_602040 = header.getOrDefault("x-amz-request-payer")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = newJString("requester"))
  if valid_602040 != nil:
    section.add "x-amz-request-payer", valid_602040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602041: Call_GetObjectRetention_602032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an object's retention settings.
  ## 
  let valid = call_602041.validator(path, query, header, formData, body)
  let scheme = call_602041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602041.url(scheme.get, call_602041.host, call_602041.base,
                         call_602041.route, valid.getOrDefault("path"))
  result = hook(call_602041, url, valid)

proc call*(call_602042: Call_GetObjectRetention_602032; retention: bool; Key: string;
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
  var path_602043 = newJObject()
  var query_602044 = newJObject()
  add(query_602044, "versionId", newJString(versionId))
  add(query_602044, "retention", newJBool(retention))
  add(path_602043, "Key", newJString(Key))
  add(path_602043, "Bucket", newJString(Bucket))
  result = call_602042.call(path_602043, query_602044, nil, nil, nil)

var getObjectRetention* = Call_GetObjectRetention_602032(
    name: "getObjectRetention", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_GetObjectRetention_602033,
    base: "/", url: url_GetObjectRetention_602034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTorrent_602062 = ref object of OpenApiRestCall_600426
proc url_GetObjectTorrent_602064(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetObjectTorrent_602063(path: JsonNode; query: JsonNode;
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
  var valid_602065 = path.getOrDefault("Key")
  valid_602065 = validateParameter(valid_602065, JString, required = true,
                                 default = nil)
  if valid_602065 != nil:
    section.add "Key", valid_602065
  var valid_602066 = path.getOrDefault("Bucket")
  valid_602066 = validateParameter(valid_602066, JString, required = true,
                                 default = nil)
  if valid_602066 != nil:
    section.add "Bucket", valid_602066
  result.add "path", section
  ## parameters in `query` object:
  ##   torrent: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `torrent` field"
  var valid_602067 = query.getOrDefault("torrent")
  valid_602067 = validateParameter(valid_602067, JBool, required = true, default = nil)
  if valid_602067 != nil:
    section.add "torrent", valid_602067
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602068 = header.getOrDefault("x-amz-security-token")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "x-amz-security-token", valid_602068
  var valid_602069 = header.getOrDefault("x-amz-request-payer")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = newJString("requester"))
  if valid_602069 != nil:
    section.add "x-amz-request-payer", valid_602069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602070: Call_GetObjectTorrent_602062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return torrent files from a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  let valid = call_602070.validator(path, query, header, formData, body)
  let scheme = call_602070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602070.url(scheme.get, call_602070.host, call_602070.base,
                         call_602070.route, valid.getOrDefault("path"))
  result = hook(call_602070, url, valid)

proc call*(call_602071: Call_GetObjectTorrent_602062; torrent: bool; Key: string;
          Bucket: string): Recallable =
  ## getObjectTorrent
  ## Return torrent files from a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  ##   torrent: bool (required)
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_602072 = newJObject()
  var query_602073 = newJObject()
  add(query_602073, "torrent", newJBool(torrent))
  add(path_602072, "Key", newJString(Key))
  add(path_602072, "Bucket", newJString(Bucket))
  result = call_602071.call(path_602072, query_602073, nil, nil, nil)

var getObjectTorrent* = Call_GetObjectTorrent_602062(name: "getObjectTorrent",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#torrent", validator: validate_GetObjectTorrent_602063,
    base: "/", url: url_GetObjectTorrent_602064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketAnalyticsConfigurations_602074 = ref object of OpenApiRestCall_600426
proc url_ListBucketAnalyticsConfigurations_602076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#analytics")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListBucketAnalyticsConfigurations_602075(path: JsonNode;
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
  var valid_602077 = path.getOrDefault("Bucket")
  valid_602077 = validateParameter(valid_602077, JString, required = true,
                                 default = nil)
  if valid_602077 != nil:
    section.add "Bucket", valid_602077
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   continuation-token: JString
  ##                     : The ContinuationToken that represents a placeholder from where this request should begin.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_602078 = query.getOrDefault("analytics")
  valid_602078 = validateParameter(valid_602078, JBool, required = true, default = nil)
  if valid_602078 != nil:
    section.add "analytics", valid_602078
  var valid_602079 = query.getOrDefault("continuation-token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "continuation-token", valid_602079
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602080 = header.getOrDefault("x-amz-security-token")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "x-amz-security-token", valid_602080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602081: Call_ListBucketAnalyticsConfigurations_602074;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the analytics configurations for the bucket.
  ## 
  let valid = call_602081.validator(path, query, header, formData, body)
  let scheme = call_602081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602081.url(scheme.get, call_602081.host, call_602081.base,
                         call_602081.route, valid.getOrDefault("path"))
  result = hook(call_602081, url, valid)

proc call*(call_602082: Call_ListBucketAnalyticsConfigurations_602074;
          analytics: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketAnalyticsConfigurations
  ## Lists the analytics configurations for the bucket.
  ##   analytics: bool (required)
  ##   continuationToken: string
  ##                    : The ContinuationToken that represents a placeholder from where this request should begin.
  ##   Bucket: string (required)
  ##         : The name of the bucket from which analytics configurations are retrieved.
  var path_602083 = newJObject()
  var query_602084 = newJObject()
  add(query_602084, "analytics", newJBool(analytics))
  add(query_602084, "continuation-token", newJString(continuationToken))
  add(path_602083, "Bucket", newJString(Bucket))
  result = call_602082.call(path_602083, query_602084, nil, nil, nil)

var listBucketAnalyticsConfigurations* = Call_ListBucketAnalyticsConfigurations_602074(
    name: "listBucketAnalyticsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics",
    validator: validate_ListBucketAnalyticsConfigurations_602075, base: "/",
    url: url_ListBucketAnalyticsConfigurations_602076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketInventoryConfigurations_602085 = ref object of OpenApiRestCall_600426
proc url_ListBucketInventoryConfigurations_602087(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#inventory")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListBucketInventoryConfigurations_602086(path: JsonNode;
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
  var valid_602088 = path.getOrDefault("Bucket")
  valid_602088 = validateParameter(valid_602088, JString, required = true,
                                 default = nil)
  if valid_602088 != nil:
    section.add "Bucket", valid_602088
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_602089 = query.getOrDefault("inventory")
  valid_602089 = validateParameter(valid_602089, JBool, required = true, default = nil)
  if valid_602089 != nil:
    section.add "inventory", valid_602089
  var valid_602090 = query.getOrDefault("continuation-token")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "continuation-token", valid_602090
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602091 = header.getOrDefault("x-amz-security-token")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "x-amz-security-token", valid_602091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602092: Call_ListBucketInventoryConfigurations_602085;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of inventory configurations for the bucket.
  ## 
  let valid = call_602092.validator(path, query, header, formData, body)
  let scheme = call_602092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602092.url(scheme.get, call_602092.host, call_602092.base,
                         call_602092.route, valid.getOrDefault("path"))
  result = hook(call_602092, url, valid)

proc call*(call_602093: Call_ListBucketInventoryConfigurations_602085;
          inventory: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketInventoryConfigurations
  ## Returns a list of inventory configurations for the bucket.
  ##   inventory: bool (required)
  ##   continuationToken: string
  ##                    : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configurations to retrieve.
  var path_602094 = newJObject()
  var query_602095 = newJObject()
  add(query_602095, "inventory", newJBool(inventory))
  add(query_602095, "continuation-token", newJString(continuationToken))
  add(path_602094, "Bucket", newJString(Bucket))
  result = call_602093.call(path_602094, query_602095, nil, nil, nil)

var listBucketInventoryConfigurations* = Call_ListBucketInventoryConfigurations_602085(
    name: "listBucketInventoryConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory",
    validator: validate_ListBucketInventoryConfigurations_602086, base: "/",
    url: url_ListBucketInventoryConfigurations_602087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketMetricsConfigurations_602096 = ref object of OpenApiRestCall_600426
proc url_ListBucketMetricsConfigurations_602098(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#metrics")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListBucketMetricsConfigurations_602097(path: JsonNode;
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
  var valid_602099 = path.getOrDefault("Bucket")
  valid_602099 = validateParameter(valid_602099, JString, required = true,
                                 default = nil)
  if valid_602099 != nil:
    section.add "Bucket", valid_602099
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_602100 = query.getOrDefault("metrics")
  valid_602100 = validateParameter(valid_602100, JBool, required = true, default = nil)
  if valid_602100 != nil:
    section.add "metrics", valid_602100
  var valid_602101 = query.getOrDefault("continuation-token")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "continuation-token", valid_602101
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602102 = header.getOrDefault("x-amz-security-token")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "x-amz-security-token", valid_602102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602103: Call_ListBucketMetricsConfigurations_602096;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the metrics configurations for the bucket.
  ## 
  let valid = call_602103.validator(path, query, header, formData, body)
  let scheme = call_602103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602103.url(scheme.get, call_602103.host, call_602103.base,
                         call_602103.route, valid.getOrDefault("path"))
  result = hook(call_602103, url, valid)

proc call*(call_602104: Call_ListBucketMetricsConfigurations_602096; metrics: bool;
          Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketMetricsConfigurations
  ## Lists the metrics configurations for the bucket.
  ##   metrics: bool (required)
  ##   continuationToken: string
  ##                    : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configurations to retrieve.
  var path_602105 = newJObject()
  var query_602106 = newJObject()
  add(query_602106, "metrics", newJBool(metrics))
  add(query_602106, "continuation-token", newJString(continuationToken))
  add(path_602105, "Bucket", newJString(Bucket))
  result = call_602104.call(path_602105, query_602106, nil, nil, nil)

var listBucketMetricsConfigurations* = Call_ListBucketMetricsConfigurations_602096(
    name: "listBucketMetricsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics",
    validator: validate_ListBucketMetricsConfigurations_602097, base: "/",
    url: url_ListBucketMetricsConfigurations_602098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuckets_602107 = ref object of OpenApiRestCall_600426
proc url_ListBuckets_602109(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBuckets_602108(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602110 = header.getOrDefault("x-amz-security-token")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "x-amz-security-token", valid_602110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602111: Call_ListBuckets_602107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  let valid = call_602111.validator(path, query, header, formData, body)
  let scheme = call_602111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602111.url(scheme.get, call_602111.host, call_602111.base,
                         call_602111.route, valid.getOrDefault("path"))
  result = hook(call_602111, url, valid)

proc call*(call_602112: Call_ListBuckets_602107): Recallable =
  ## listBuckets
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  result = call_602112.call(nil, nil, nil, nil, nil)

var listBuckets* = Call_ListBuckets_602107(name: "listBuckets",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com", route: "/",
                                        validator: validate_ListBuckets_602108,
                                        base: "/", url: url_ListBuckets_602109,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultipartUploads_602113 = ref object of OpenApiRestCall_600426
proc url_ListMultipartUploads_602115(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#uploads")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListMultipartUploads_602114(path: JsonNode; query: JsonNode;
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
  var valid_602116 = path.getOrDefault("Bucket")
  valid_602116 = validateParameter(valid_602116, JString, required = true,
                                 default = nil)
  if valid_602116 != nil:
    section.add "Bucket", valid_602116
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
  var valid_602117 = query.getOrDefault("max-uploads")
  valid_602117 = validateParameter(valid_602117, JInt, required = false, default = nil)
  if valid_602117 != nil:
    section.add "max-uploads", valid_602117
  var valid_602118 = query.getOrDefault("key-marker")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "key-marker", valid_602118
  var valid_602119 = query.getOrDefault("encoding-type")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = newJString("url"))
  if valid_602119 != nil:
    section.add "encoding-type", valid_602119
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_602120 = query.getOrDefault("uploads")
  valid_602120 = validateParameter(valid_602120, JBool, required = true, default = nil)
  if valid_602120 != nil:
    section.add "uploads", valid_602120
  var valid_602121 = query.getOrDefault("MaxUploads")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "MaxUploads", valid_602121
  var valid_602122 = query.getOrDefault("delimiter")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "delimiter", valid_602122
  var valid_602123 = query.getOrDefault("prefix")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "prefix", valid_602123
  var valid_602124 = query.getOrDefault("upload-id-marker")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "upload-id-marker", valid_602124
  var valid_602125 = query.getOrDefault("KeyMarker")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "KeyMarker", valid_602125
  var valid_602126 = query.getOrDefault("UploadIdMarker")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "UploadIdMarker", valid_602126
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602127 = header.getOrDefault("x-amz-security-token")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "x-amz-security-token", valid_602127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_ListMultipartUploads_602113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists in-progress multipart uploads.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"))
  result = hook(call_602128, url, valid)

proc call*(call_602129: Call_ListMultipartUploads_602113; uploads: bool;
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
  var path_602130 = newJObject()
  var query_602131 = newJObject()
  add(query_602131, "max-uploads", newJInt(maxUploads))
  add(query_602131, "key-marker", newJString(keyMarker))
  add(query_602131, "encoding-type", newJString(encodingType))
  add(query_602131, "uploads", newJBool(uploads))
  add(query_602131, "MaxUploads", newJString(MaxUploads))
  add(query_602131, "delimiter", newJString(delimiter))
  add(path_602130, "Bucket", newJString(Bucket))
  add(query_602131, "prefix", newJString(prefix))
  add(query_602131, "upload-id-marker", newJString(uploadIdMarker))
  add(query_602131, "KeyMarker", newJString(KeyMarker))
  add(query_602131, "UploadIdMarker", newJString(UploadIdMarker))
  result = call_602129.call(path_602130, query_602131, nil, nil, nil)

var listMultipartUploads* = Call_ListMultipartUploads_602113(
    name: "listMultipartUploads", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#uploads",
    validator: validate_ListMultipartUploads_602114, base: "/",
    url: url_ListMultipartUploads_602115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectVersions_602132 = ref object of OpenApiRestCall_600426
proc url_ListObjectVersions_602134(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListObjectVersions_602133(path: JsonNode; query: JsonNode;
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
  var valid_602135 = path.getOrDefault("Bucket")
  valid_602135 = validateParameter(valid_602135, JString, required = true,
                                 default = nil)
  if valid_602135 != nil:
    section.add "Bucket", valid_602135
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
  var valid_602136 = query.getOrDefault("key-marker")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "key-marker", valid_602136
  var valid_602137 = query.getOrDefault("max-keys")
  valid_602137 = validateParameter(valid_602137, JInt, required = false, default = nil)
  if valid_602137 != nil:
    section.add "max-keys", valid_602137
  var valid_602138 = query.getOrDefault("VersionIdMarker")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "VersionIdMarker", valid_602138
  assert query != nil,
        "query argument is necessary due to required `versions` field"
  var valid_602139 = query.getOrDefault("versions")
  valid_602139 = validateParameter(valid_602139, JBool, required = true, default = nil)
  if valid_602139 != nil:
    section.add "versions", valid_602139
  var valid_602140 = query.getOrDefault("encoding-type")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = newJString("url"))
  if valid_602140 != nil:
    section.add "encoding-type", valid_602140
  var valid_602141 = query.getOrDefault("version-id-marker")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "version-id-marker", valid_602141
  var valid_602142 = query.getOrDefault("delimiter")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "delimiter", valid_602142
  var valid_602143 = query.getOrDefault("prefix")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "prefix", valid_602143
  var valid_602144 = query.getOrDefault("MaxKeys")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "MaxKeys", valid_602144
  var valid_602145 = query.getOrDefault("KeyMarker")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "KeyMarker", valid_602145
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_602146 = header.getOrDefault("x-amz-security-token")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "x-amz-security-token", valid_602146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602147: Call_ListObjectVersions_602132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about all of the versions of objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
  let valid = call_602147.validator(path, query, header, formData, body)
  let scheme = call_602147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602147.url(scheme.get, call_602147.host, call_602147.base,
                         call_602147.route, valid.getOrDefault("path"))
  result = hook(call_602147, url, valid)

proc call*(call_602148: Call_ListObjectVersions_602132; versions: bool;
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
  var path_602149 = newJObject()
  var query_602150 = newJObject()
  add(query_602150, "key-marker", newJString(keyMarker))
  add(query_602150, "max-keys", newJInt(maxKeys))
  add(query_602150, "VersionIdMarker", newJString(VersionIdMarker))
  add(query_602150, "versions", newJBool(versions))
  add(query_602150, "encoding-type", newJString(encodingType))
  add(query_602150, "version-id-marker", newJString(versionIdMarker))
  add(query_602150, "delimiter", newJString(delimiter))
  add(path_602149, "Bucket", newJString(Bucket))
  add(query_602150, "prefix", newJString(prefix))
  add(query_602150, "MaxKeys", newJString(MaxKeys))
  add(query_602150, "KeyMarker", newJString(KeyMarker))
  result = call_602148.call(path_602149, query_602150, nil, nil, nil)

var listObjectVersions* = Call_ListObjectVersions_602132(
    name: "listObjectVersions", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versions", validator: validate_ListObjectVersions_602133,
    base: "/", url: url_ListObjectVersions_602134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectsV2_602151 = ref object of OpenApiRestCall_600426
proc url_ListObjectsV2_602153(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket"),
               (kind: ConstantSegment, value: "#list-type=2")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListObjectsV2_602152(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602154 = path.getOrDefault("Bucket")
  valid_602154 = validateParameter(valid_602154, JString, required = true,
                                 default = nil)
  if valid_602154 != nil:
    section.add "Bucket", valid_602154
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
  var valid_602155 = query.getOrDefault("list-type")
  valid_602155 = validateParameter(valid_602155, JString, required = true,
                                 default = newJString("2"))
  if valid_602155 != nil:
    section.add "list-type", valid_602155
  var valid_602156 = query.getOrDefault("max-keys")
  valid_602156 = validateParameter(valid_602156, JInt, required = false, default = nil)
  if valid_602156 != nil:
    section.add "max-keys", valid_602156
  var valid_602157 = query.getOrDefault("encoding-type")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = newJString("url"))
  if valid_602157 != nil:
    section.add "encoding-type", valid_602157
  var valid_602158 = query.getOrDefault("continuation-token")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "continuation-token", valid_602158
  var valid_602159 = query.getOrDefault("fetch-owner")
  valid_602159 = validateParameter(valid_602159, JBool, required = false, default = nil)
  if valid_602159 != nil:
    section.add "fetch-owner", valid_602159
  var valid_602160 = query.getOrDefault("delimiter")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "delimiter", valid_602160
  var valid_602161 = query.getOrDefault("start-after")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "start-after", valid_602161
  var valid_602162 = query.getOrDefault("ContinuationToken")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "ContinuationToken", valid_602162
  var valid_602163 = query.getOrDefault("prefix")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "prefix", valid_602163
  var valid_602164 = query.getOrDefault("MaxKeys")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "MaxKeys", valid_602164
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602165 = header.getOrDefault("x-amz-security-token")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "x-amz-security-token", valid_602165
  var valid_602166 = header.getOrDefault("x-amz-request-payer")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = newJString("requester"))
  if valid_602166 != nil:
    section.add "x-amz-request-payer", valid_602166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602167: Call_ListObjectsV2_602151; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. Note: ListObjectsV2 is the revised List Objects API and we recommend you use this revised API for new application development.
  ## 
  let valid = call_602167.validator(path, query, header, formData, body)
  let scheme = call_602167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602167.url(scheme.get, call_602167.host, call_602167.base,
                         call_602167.route, valid.getOrDefault("path"))
  result = hook(call_602167, url, valid)

proc call*(call_602168: Call_ListObjectsV2_602151; Bucket: string;
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
  var path_602169 = newJObject()
  var query_602170 = newJObject()
  add(query_602170, "list-type", newJString(listType))
  add(query_602170, "max-keys", newJInt(maxKeys))
  add(query_602170, "encoding-type", newJString(encodingType))
  add(query_602170, "continuation-token", newJString(continuationToken))
  add(query_602170, "fetch-owner", newJBool(fetchOwner))
  add(query_602170, "delimiter", newJString(delimiter))
  add(path_602169, "Bucket", newJString(Bucket))
  add(query_602170, "start-after", newJString(startAfter))
  add(query_602170, "ContinuationToken", newJString(ContinuationToken))
  add(query_602170, "prefix", newJString(prefix))
  add(query_602170, "MaxKeys", newJString(MaxKeys))
  result = call_602168.call(path_602169, query_602170, nil, nil, nil)

var listObjectsV2* = Call_ListObjectsV2_602151(name: "listObjectsV2",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#list-type=2", validator: validate_ListObjectsV2_602152,
    base: "/", url: url_ListObjectsV2_602153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreObject_602171 = ref object of OpenApiRestCall_600426
proc url_RestoreObject_602173(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RestoreObject_602172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602174 = path.getOrDefault("Key")
  valid_602174 = validateParameter(valid_602174, JString, required = true,
                                 default = nil)
  if valid_602174 != nil:
    section.add "Key", valid_602174
  var valid_602175 = path.getOrDefault("Bucket")
  valid_602175 = validateParameter(valid_602175, JString, required = true,
                                 default = nil)
  if valid_602175 != nil:
    section.add "Bucket", valid_602175
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   restore: JBool (required)
  section = newJObject()
  var valid_602176 = query.getOrDefault("versionId")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "versionId", valid_602176
  assert query != nil, "query argument is necessary due to required `restore` field"
  var valid_602177 = query.getOrDefault("restore")
  valid_602177 = validateParameter(valid_602177, JBool, required = true, default = nil)
  if valid_602177 != nil:
    section.add "restore", valid_602177
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602178 = header.getOrDefault("x-amz-security-token")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "x-amz-security-token", valid_602178
  var valid_602179 = header.getOrDefault("x-amz-request-payer")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = newJString("requester"))
  if valid_602179 != nil:
    section.add "x-amz-request-payer", valid_602179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602181: Call_RestoreObject_602171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restores an archived copy of an object back into Amazon S3
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  let valid = call_602181.validator(path, query, header, formData, body)
  let scheme = call_602181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602181.url(scheme.get, call_602181.host, call_602181.base,
                         call_602181.route, valid.getOrDefault("path"))
  result = hook(call_602181, url, valid)

proc call*(call_602182: Call_RestoreObject_602171; Key: string; restore: bool;
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
  var path_602183 = newJObject()
  var query_602184 = newJObject()
  var body_602185 = newJObject()
  add(query_602184, "versionId", newJString(versionId))
  add(path_602183, "Key", newJString(Key))
  add(query_602184, "restore", newJBool(restore))
  add(path_602183, "Bucket", newJString(Bucket))
  if body != nil:
    body_602185 = body
  result = call_602182.call(path_602183, query_602184, nil, nil, body_602185)

var restoreObject* = Call_RestoreObject_602171(name: "restoreObject",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#restore", validator: validate_RestoreObject_602172,
    base: "/", url: url_RestoreObject_602173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SelectObjectContent_602186 = ref object of OpenApiRestCall_600426
proc url_SelectObjectContent_602188(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_SelectObjectContent_602187(path: JsonNode; query: JsonNode;
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
  var valid_602189 = path.getOrDefault("Key")
  valid_602189 = validateParameter(valid_602189, JString, required = true,
                                 default = nil)
  if valid_602189 != nil:
    section.add "Key", valid_602189
  var valid_602190 = path.getOrDefault("Bucket")
  valid_602190 = validateParameter(valid_602190, JString, required = true,
                                 default = nil)
  if valid_602190 != nil:
    section.add "Bucket", valid_602190
  result.add "path", section
  ## parameters in `query` object:
  ##   select: JBool (required)
  ##   select-type: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `select` field"
  var valid_602191 = query.getOrDefault("select")
  valid_602191 = validateParameter(valid_602191, JBool, required = true, default = nil)
  if valid_602191 != nil:
    section.add "select", valid_602191
  var valid_602192 = query.getOrDefault("select-type")
  valid_602192 = validateParameter(valid_602192, JString, required = true,
                                 default = newJString("2"))
  if valid_602192 != nil:
    section.add "select-type", valid_602192
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
  var valid_602193 = header.getOrDefault("x-amz-security-token")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "x-amz-security-token", valid_602193
  var valid_602194 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_602194
  var valid_602195 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_602195
  var valid_602196 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_602196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602198: Call_SelectObjectContent_602186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ## 
  let valid = call_602198.validator(path, query, header, formData, body)
  let scheme = call_602198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602198.url(scheme.get, call_602198.host, call_602198.base,
                         call_602198.route, valid.getOrDefault("path"))
  result = hook(call_602198, url, valid)

proc call*(call_602199: Call_SelectObjectContent_602186; select: bool; Key: string;
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
  var path_602200 = newJObject()
  var query_602201 = newJObject()
  var body_602202 = newJObject()
  add(query_602201, "select", newJBool(select))
  add(path_602200, "Key", newJString(Key))
  add(path_602200, "Bucket", newJString(Bucket))
  if body != nil:
    body_602202 = body
  add(query_602201, "select-type", newJString(selectType))
  result = call_602199.call(path_602200, query_602201, nil, nil, body_602202)

var selectObjectContent* = Call_SelectObjectContent_602186(
    name: "selectObjectContent", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#select&select-type=2",
    validator: validate_SelectObjectContent_602187, base: "/",
    url: url_SelectObjectContent_602188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPart_602203 = ref object of OpenApiRestCall_600426
proc url_UploadPart_602205(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UploadPart_602204(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602206 = path.getOrDefault("Key")
  valid_602206 = validateParameter(valid_602206, JString, required = true,
                                 default = nil)
  if valid_602206 != nil:
    section.add "Key", valid_602206
  var valid_602207 = path.getOrDefault("Bucket")
  valid_602207 = validateParameter(valid_602207, JString, required = true,
                                 default = nil)
  if valid_602207 != nil:
    section.add "Bucket", valid_602207
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being uploaded.
  ##   partNumber: JInt (required)
  ##             : Part number of part being uploaded. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_602208 = query.getOrDefault("uploadId")
  valid_602208 = validateParameter(valid_602208, JString, required = true,
                                 default = nil)
  if valid_602208 != nil:
    section.add "uploadId", valid_602208
  var valid_602209 = query.getOrDefault("partNumber")
  valid_602209 = validateParameter(valid_602209, JInt, required = true, default = nil)
  if valid_602209 != nil:
    section.add "partNumber", valid_602209
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
  var valid_602210 = header.getOrDefault("x-amz-security-token")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "x-amz-security-token", valid_602210
  var valid_602211 = header.getOrDefault("Content-MD5")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "Content-MD5", valid_602211
  var valid_602212 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_602212
  var valid_602213 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_602213
  var valid_602214 = header.getOrDefault("Content-Length")
  valid_602214 = validateParameter(valid_602214, JInt, required = false, default = nil)
  if valid_602214 != nil:
    section.add "Content-Length", valid_602214
  var valid_602215 = header.getOrDefault("x-amz-request-payer")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = newJString("requester"))
  if valid_602215 != nil:
    section.add "x-amz-request-payer", valid_602215
  var valid_602216 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_602216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602218: Call_UploadPart_602203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  let valid = call_602218.validator(path, query, header, formData, body)
  let scheme = call_602218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602218.url(scheme.get, call_602218.host, call_602218.base,
                         call_602218.route, valid.getOrDefault("path"))
  result = hook(call_602218, url, valid)

proc call*(call_602219: Call_UploadPart_602203; uploadId: string; partNumber: int;
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
  var path_602220 = newJObject()
  var query_602221 = newJObject()
  var body_602222 = newJObject()
  add(query_602221, "uploadId", newJString(uploadId))
  add(query_602221, "partNumber", newJInt(partNumber))
  add(path_602220, "Key", newJString(Key))
  add(path_602220, "Bucket", newJString(Bucket))
  if body != nil:
    body_602222 = body
  result = call_602219.call(path_602220, query_602221, nil, nil, body_602222)

var uploadPart* = Call_UploadPart_602203(name: "uploadPart",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#partNumber&uploadId",
                                      validator: validate_UploadPart_602204,
                                      base: "/", url: url_UploadPart_602205,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPartCopy_602223 = ref object of OpenApiRestCall_600426
proc url_UploadPartCopy_602225(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UploadPartCopy_602224(path: JsonNode; query: JsonNode;
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
  var valid_602226 = path.getOrDefault("Key")
  valid_602226 = validateParameter(valid_602226, JString, required = true,
                                 default = nil)
  if valid_602226 != nil:
    section.add "Key", valid_602226
  var valid_602227 = path.getOrDefault("Bucket")
  valid_602227 = validateParameter(valid_602227, JString, required = true,
                                 default = nil)
  if valid_602227 != nil:
    section.add "Bucket", valid_602227
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being copied.
  ##   partNumber: JInt (required)
  ##             : Part number of part being copied. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_602228 = query.getOrDefault("uploadId")
  valid_602228 = validateParameter(valid_602228, JString, required = true,
                                 default = nil)
  if valid_602228 != nil:
    section.add "uploadId", valid_602228
  var valid_602229 = query.getOrDefault("partNumber")
  valid_602229 = validateParameter(valid_602229, JInt, required = true, default = nil)
  if valid_602229 != nil:
    section.add "partNumber", valid_602229
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
  var valid_602230 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_602230
  var valid_602231 = header.getOrDefault("x-amz-security-token")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "x-amz-security-token", valid_602231
  var valid_602232 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_602232
  var valid_602233 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_602233
  var valid_602234 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_602234
  var valid_602235 = header.getOrDefault("x-amz-copy-source-range")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "x-amz-copy-source-range", valid_602235
  var valid_602236 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_602236
  var valid_602237 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_602237
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_602238 = header.getOrDefault("x-amz-copy-source")
  valid_602238 = validateParameter(valid_602238, JString, required = true,
                                 default = nil)
  if valid_602238 != nil:
    section.add "x-amz-copy-source", valid_602238
  var valid_602239 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "x-amz-copy-source-if-match", valid_602239
  var valid_602240 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_602240
  var valid_602241 = header.getOrDefault("x-amz-request-payer")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = newJString("requester"))
  if valid_602241 != nil:
    section.add "x-amz-request-payer", valid_602241
  var valid_602242 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_602242
  var valid_602243 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_602243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602244: Call_UploadPartCopy_602223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads a part by copying data from an existing object as data source.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  let valid = call_602244.validator(path, query, header, formData, body)
  let scheme = call_602244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602244.url(scheme.get, call_602244.host, call_602244.base,
                         call_602244.route, valid.getOrDefault("path"))
  result = hook(call_602244, url, valid)

proc call*(call_602245: Call_UploadPartCopy_602223; uploadId: string;
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
  var path_602246 = newJObject()
  var query_602247 = newJObject()
  add(query_602247, "uploadId", newJString(uploadId))
  add(query_602247, "partNumber", newJInt(partNumber))
  add(path_602246, "Key", newJString(Key))
  add(path_602246, "Bucket", newJString(Bucket))
  result = call_602245.call(path_602246, query_602247, nil, nil, nil)

var uploadPartCopy* = Call_UploadPartCopy_602223(name: "uploadPartCopy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#x-amz-copy-source&partNumber&uploadId",
    validator: validate_UploadPartCopy_602224, base: "/", url: url_UploadPartCopy_602225,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
