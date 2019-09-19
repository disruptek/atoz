
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  Call_CompleteMultipartUpload_773218 = ref object of OpenApiRestCall_772597
proc url_CompleteMultipartUpload_773220(protocol: Scheme; host: string; base: string;
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

proc validate_CompleteMultipartUpload_773219(path: JsonNode; query: JsonNode;
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
  var valid_773221 = path.getOrDefault("Key")
  valid_773221 = validateParameter(valid_773221, JString, required = true,
                                 default = nil)
  if valid_773221 != nil:
    section.add "Key", valid_773221
  var valid_773222 = path.getOrDefault("Bucket")
  valid_773222 = validateParameter(valid_773222, JString, required = true,
                                 default = nil)
  if valid_773222 != nil:
    section.add "Bucket", valid_773222
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : <p/>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_773223 = query.getOrDefault("uploadId")
  valid_773223 = validateParameter(valid_773223, JString, required = true,
                                 default = nil)
  if valid_773223 != nil:
    section.add "uploadId", valid_773223
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_773224 = header.getOrDefault("x-amz-security-token")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "x-amz-security-token", valid_773224
  var valid_773225 = header.getOrDefault("x-amz-request-payer")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = newJString("requester"))
  if valid_773225 != nil:
    section.add "x-amz-request-payer", valid_773225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773227: Call_CompleteMultipartUpload_773218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  let valid = call_773227.validator(path, query, header, formData, body)
  let scheme = call_773227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773227.url(scheme.get, call_773227.host, call_773227.base,
                         call_773227.route, valid.getOrDefault("path"))
  result = hook(call_773227, url, valid)

proc call*(call_773228: Call_CompleteMultipartUpload_773218; uploadId: string;
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
  var path_773229 = newJObject()
  var query_773230 = newJObject()
  var body_773231 = newJObject()
  add(query_773230, "uploadId", newJString(uploadId))
  add(path_773229, "Key", newJString(Key))
  add(path_773229, "Bucket", newJString(Bucket))
  if body != nil:
    body_773231 = body
  result = call_773228.call(path_773229, query_773230, nil, nil, body_773231)

var completeMultipartUpload* = Call_CompleteMultipartUpload_773218(
    name: "completeMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_CompleteMultipartUpload_773219, base: "/",
    url: url_CompleteMultipartUpload_773220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParts_772933 = ref object of OpenApiRestCall_772597
proc url_ListParts_772935(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListParts_772934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773061 = path.getOrDefault("Key")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = nil)
  if valid_773061 != nil:
    section.add "Key", valid_773061
  var valid_773062 = path.getOrDefault("Bucket")
  valid_773062 = validateParameter(valid_773062, JString, required = true,
                                 default = nil)
  if valid_773062 != nil:
    section.add "Bucket", valid_773062
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
  var valid_773063 = query.getOrDefault("max-parts")
  valid_773063 = validateParameter(valid_773063, JInt, required = false, default = nil)
  if valid_773063 != nil:
    section.add "max-parts", valid_773063
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_773064 = query.getOrDefault("uploadId")
  valid_773064 = validateParameter(valid_773064, JString, required = true,
                                 default = nil)
  if valid_773064 != nil:
    section.add "uploadId", valid_773064
  var valid_773065 = query.getOrDefault("MaxParts")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "MaxParts", valid_773065
  var valid_773066 = query.getOrDefault("part-number-marker")
  valid_773066 = validateParameter(valid_773066, JInt, required = false, default = nil)
  if valid_773066 != nil:
    section.add "part-number-marker", valid_773066
  var valid_773067 = query.getOrDefault("PartNumberMarker")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "PartNumberMarker", valid_773067
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_773068 = header.getOrDefault("x-amz-security-token")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "x-amz-security-token", valid_773068
  var valid_773082 = header.getOrDefault("x-amz-request-payer")
  valid_773082 = validateParameter(valid_773082, JString, required = false,
                                 default = newJString("requester"))
  if valid_773082 != nil:
    section.add "x-amz-request-payer", valid_773082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773105: Call_ListParts_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  let valid = call_773105.validator(path, query, header, formData, body)
  let scheme = call_773105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773105.url(scheme.get, call_773105.host, call_773105.base,
                         call_773105.route, valid.getOrDefault("path"))
  result = hook(call_773105, url, valid)

proc call*(call_773176: Call_ListParts_772933; uploadId: string; Key: string;
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
  var path_773177 = newJObject()
  var query_773179 = newJObject()
  add(query_773179, "max-parts", newJInt(maxParts))
  add(query_773179, "uploadId", newJString(uploadId))
  add(query_773179, "MaxParts", newJString(MaxParts))
  add(query_773179, "part-number-marker", newJInt(partNumberMarker))
  add(query_773179, "PartNumberMarker", newJString(PartNumberMarker))
  add(path_773177, "Key", newJString(Key))
  add(path_773177, "Bucket", newJString(Bucket))
  result = call_773176.call(path_773177, query_773179, nil, nil, nil)

var listParts* = Call_ListParts_772933(name: "listParts", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}#uploadId",
                                    validator: validate_ListParts_772934,
                                    base: "/", url: url_ListParts_772935,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortMultipartUpload_773232 = ref object of OpenApiRestCall_772597
proc url_AbortMultipartUpload_773234(protocol: Scheme; host: string; base: string;
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

proc validate_AbortMultipartUpload_773233(path: JsonNode; query: JsonNode;
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
  var valid_773235 = path.getOrDefault("Key")
  valid_773235 = validateParameter(valid_773235, JString, required = true,
                                 default = nil)
  if valid_773235 != nil:
    section.add "Key", valid_773235
  var valid_773236 = path.getOrDefault("Bucket")
  valid_773236 = validateParameter(valid_773236, JString, required = true,
                                 default = nil)
  if valid_773236 != nil:
    section.add "Bucket", valid_773236
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID that identifies the multipart upload.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_773237 = query.getOrDefault("uploadId")
  valid_773237 = validateParameter(valid_773237, JString, required = true,
                                 default = nil)
  if valid_773237 != nil:
    section.add "uploadId", valid_773237
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_773238 = header.getOrDefault("x-amz-security-token")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "x-amz-security-token", valid_773238
  var valid_773239 = header.getOrDefault("x-amz-request-payer")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = newJString("requester"))
  if valid_773239 != nil:
    section.add "x-amz-request-payer", valid_773239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773240: Call_AbortMultipartUpload_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  let valid = call_773240.validator(path, query, header, formData, body)
  let scheme = call_773240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773240.url(scheme.get, call_773240.host, call_773240.base,
                         call_773240.route, valid.getOrDefault("path"))
  result = hook(call_773240, url, valid)

proc call*(call_773241: Call_AbortMultipartUpload_773232; uploadId: string;
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
  var path_773242 = newJObject()
  var query_773243 = newJObject()
  add(query_773243, "uploadId", newJString(uploadId))
  add(path_773242, "Key", newJString(Key))
  add(path_773242, "Bucket", newJString(Bucket))
  result = call_773241.call(path_773242, query_773243, nil, nil, nil)

var abortMultipartUpload* = Call_AbortMultipartUpload_773232(
    name: "abortMultipartUpload", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_AbortMultipartUpload_773233, base: "/",
    url: url_AbortMultipartUpload_773234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyObject_773244 = ref object of OpenApiRestCall_772597
proc url_CopyObject_773246(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CopyObject_773245(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773247 = path.getOrDefault("Key")
  valid_773247 = validateParameter(valid_773247, JString, required = true,
                                 default = nil)
  if valid_773247 != nil:
    section.add "Key", valid_773247
  var valid_773248 = path.getOrDefault("Bucket")
  valid_773248 = validateParameter(valid_773248, JString, required = true,
                                 default = nil)
  if valid_773248 != nil:
    section.add "Bucket", valid_773248
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
  var valid_773249 = header.getOrDefault("Content-Disposition")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "Content-Disposition", valid_773249
  var valid_773250 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_773250
  var valid_773251 = header.getOrDefault("x-amz-grant-full-control")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "x-amz-grant-full-control", valid_773251
  var valid_773252 = header.getOrDefault("x-amz-security-token")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "x-amz-security-token", valid_773252
  var valid_773253 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_773253
  var valid_773254 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_773254
  var valid_773255 = header.getOrDefault("x-amz-tagging-directive")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = newJString("COPY"))
  if valid_773255 != nil:
    section.add "x-amz-tagging-directive", valid_773255
  var valid_773256 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_773256
  var valid_773257 = header.getOrDefault("x-amz-object-lock-mode")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_773257 != nil:
    section.add "x-amz-object-lock-mode", valid_773257
  var valid_773258 = header.getOrDefault("Cache-Control")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "Cache-Control", valid_773258
  var valid_773259 = header.getOrDefault("Content-Language")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "Content-Language", valid_773259
  var valid_773260 = header.getOrDefault("Content-Type")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "Content-Type", valid_773260
  var valid_773261 = header.getOrDefault("Expires")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "Expires", valid_773261
  var valid_773262 = header.getOrDefault("x-amz-website-redirect-location")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "x-amz-website-redirect-location", valid_773262
  var valid_773263 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_773263
  var valid_773264 = header.getOrDefault("x-amz-acl")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = newJString("private"))
  if valid_773264 != nil:
    section.add "x-amz-acl", valid_773264
  var valid_773265 = header.getOrDefault("x-amz-grant-read")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "x-amz-grant-read", valid_773265
  var valid_773266 = header.getOrDefault("x-amz-storage-class")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_773266 != nil:
    section.add "x-amz-storage-class", valid_773266
  var valid_773267 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = newJString("ON"))
  if valid_773267 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_773267
  var valid_773268 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_773268
  var valid_773269 = header.getOrDefault("x-amz-tagging")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "x-amz-tagging", valid_773269
  var valid_773270 = header.getOrDefault("x-amz-grant-read-acp")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "x-amz-grant-read-acp", valid_773270
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_773271 = header.getOrDefault("x-amz-copy-source")
  valid_773271 = validateParameter(valid_773271, JString, required = true,
                                 default = nil)
  if valid_773271 != nil:
    section.add "x-amz-copy-source", valid_773271
  var valid_773272 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "x-amz-server-side-encryption-context", valid_773272
  var valid_773273 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_773273
  var valid_773274 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_773274
  var valid_773275 = header.getOrDefault("x-amz-metadata-directive")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = newJString("COPY"))
  if valid_773275 != nil:
    section.add "x-amz-metadata-directive", valid_773275
  var valid_773276 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "x-amz-copy-source-if-match", valid_773276
  var valid_773277 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_773277
  var valid_773278 = header.getOrDefault("x-amz-grant-write-acp")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "x-amz-grant-write-acp", valid_773278
  var valid_773279 = header.getOrDefault("Content-Encoding")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "Content-Encoding", valid_773279
  var valid_773280 = header.getOrDefault("x-amz-request-payer")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = newJString("requester"))
  if valid_773280 != nil:
    section.add "x-amz-request-payer", valid_773280
  var valid_773281 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_773281
  var valid_773282 = header.getOrDefault("x-amz-server-side-encryption")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = newJString("AES256"))
  if valid_773282 != nil:
    section.add "x-amz-server-side-encryption", valid_773282
  var valid_773283 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_773283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773285: Call_CopyObject_773244; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  let valid = call_773285.validator(path, query, header, formData, body)
  let scheme = call_773285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773285.url(scheme.get, call_773285.host, call_773285.base,
                         call_773285.route, valid.getOrDefault("path"))
  result = hook(call_773285, url, valid)

proc call*(call_773286: Call_CopyObject_773244; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## copyObject
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_773287 = newJObject()
  var body_773288 = newJObject()
  add(path_773287, "Key", newJString(Key))
  add(path_773287, "Bucket", newJString(Bucket))
  if body != nil:
    body_773288 = body
  result = call_773286.call(path_773287, nil, nil, nil, body_773288)

var copyObject* = Call_CopyObject_773244(name: "copyObject",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#x-amz-copy-source",
                                      validator: validate_CopyObject_773245,
                                      base: "/", url: url_CopyObject_773246,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBucket_773306 = ref object of OpenApiRestCall_772597
proc url_CreateBucket_773308(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBucket_773307(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773309 = path.getOrDefault("Bucket")
  valid_773309 = validateParameter(valid_773309, JString, required = true,
                                 default = nil)
  if valid_773309 != nil:
    section.add "Bucket", valid_773309
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
  var valid_773310 = header.getOrDefault("x-amz-security-token")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "x-amz-security-token", valid_773310
  var valid_773311 = header.getOrDefault("x-amz-acl")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = newJString("private"))
  if valid_773311 != nil:
    section.add "x-amz-acl", valid_773311
  var valid_773312 = header.getOrDefault("x-amz-grant-read")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "x-amz-grant-read", valid_773312
  var valid_773313 = header.getOrDefault("x-amz-grant-read-acp")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "x-amz-grant-read-acp", valid_773313
  var valid_773314 = header.getOrDefault("x-amz-bucket-object-lock-enabled")
  valid_773314 = validateParameter(valid_773314, JBool, required = false, default = nil)
  if valid_773314 != nil:
    section.add "x-amz-bucket-object-lock-enabled", valid_773314
  var valid_773315 = header.getOrDefault("x-amz-grant-write")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "x-amz-grant-write", valid_773315
  var valid_773316 = header.getOrDefault("x-amz-grant-write-acp")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "x-amz-grant-write-acp", valid_773316
  var valid_773317 = header.getOrDefault("x-amz-grant-full-control")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "x-amz-grant-full-control", valid_773317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773319: Call_CreateBucket_773306; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  let valid = call_773319.validator(path, query, header, formData, body)
  let scheme = call_773319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773319.url(scheme.get, call_773319.host, call_773319.base,
                         call_773319.route, valid.getOrDefault("path"))
  result = hook(call_773319, url, valid)

proc call*(call_773320: Call_CreateBucket_773306; Bucket: string; body: JsonNode): Recallable =
  ## createBucket
  ## Creates a new bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_773321 = newJObject()
  var body_773322 = newJObject()
  add(path_773321, "Bucket", newJString(Bucket))
  if body != nil:
    body_773322 = body
  result = call_773320.call(path_773321, nil, nil, nil, body_773322)

var createBucket* = Call_CreateBucket_773306(name: "createBucket",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_CreateBucket_773307, base: "/", url: url_CreateBucket_773308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadBucket_773331 = ref object of OpenApiRestCall_772597
proc url_HeadBucket_773333(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_HeadBucket_773332(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773334 = path.getOrDefault("Bucket")
  valid_773334 = validateParameter(valid_773334, JString, required = true,
                                 default = nil)
  if valid_773334 != nil:
    section.add "Bucket", valid_773334
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773335 = header.getOrDefault("x-amz-security-token")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "x-amz-security-token", valid_773335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773336: Call_HeadBucket_773331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  let valid = call_773336.validator(path, query, header, formData, body)
  let scheme = call_773336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773336.url(scheme.get, call_773336.host, call_773336.base,
                         call_773336.route, valid.getOrDefault("path"))
  result = hook(call_773336, url, valid)

proc call*(call_773337: Call_HeadBucket_773331; Bucket: string): Recallable =
  ## headBucket
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773338 = newJObject()
  add(path_773338, "Bucket", newJString(Bucket))
  result = call_773337.call(path_773338, nil, nil, nil, nil)

var headBucket* = Call_HeadBucket_773331(name: "headBucket",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}",
                                      validator: validate_HeadBucket_773332,
                                      base: "/", url: url_HeadBucket_773333,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjects_773289 = ref object of OpenApiRestCall_772597
proc url_ListObjects_773291(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjects_773290(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773292 = path.getOrDefault("Bucket")
  valid_773292 = validateParameter(valid_773292, JString, required = true,
                                 default = nil)
  if valid_773292 != nil:
    section.add "Bucket", valid_773292
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
  var valid_773293 = query.getOrDefault("max-keys")
  valid_773293 = validateParameter(valid_773293, JInt, required = false, default = nil)
  if valid_773293 != nil:
    section.add "max-keys", valid_773293
  var valid_773294 = query.getOrDefault("encoding-type")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = newJString("url"))
  if valid_773294 != nil:
    section.add "encoding-type", valid_773294
  var valid_773295 = query.getOrDefault("marker")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "marker", valid_773295
  var valid_773296 = query.getOrDefault("Marker")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "Marker", valid_773296
  var valid_773297 = query.getOrDefault("delimiter")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "delimiter", valid_773297
  var valid_773298 = query.getOrDefault("prefix")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "prefix", valid_773298
  var valid_773299 = query.getOrDefault("MaxKeys")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "MaxKeys", valid_773299
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_773300 = header.getOrDefault("x-amz-security-token")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "x-amz-security-token", valid_773300
  var valid_773301 = header.getOrDefault("x-amz-request-payer")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = newJString("requester"))
  if valid_773301 != nil:
    section.add "x-amz-request-payer", valid_773301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773302: Call_ListObjects_773289; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
  let valid = call_773302.validator(path, query, header, formData, body)
  let scheme = call_773302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773302.url(scheme.get, call_773302.host, call_773302.base,
                         call_773302.route, valid.getOrDefault("path"))
  result = hook(call_773302, url, valid)

proc call*(call_773303: Call_ListObjects_773289; Bucket: string; maxKeys: int = 0;
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
  var path_773304 = newJObject()
  var query_773305 = newJObject()
  add(query_773305, "max-keys", newJInt(maxKeys))
  add(query_773305, "encoding-type", newJString(encodingType))
  add(query_773305, "marker", newJString(marker))
  add(query_773305, "Marker", newJString(Marker))
  add(query_773305, "delimiter", newJString(delimiter))
  add(path_773304, "Bucket", newJString(Bucket))
  add(query_773305, "prefix", newJString(prefix))
  add(query_773305, "MaxKeys", newJString(MaxKeys))
  result = call_773303.call(path_773304, query_773305, nil, nil, nil)

var listObjects* = Call_ListObjects_773289(name: "listObjects",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com",
                                        route: "/{Bucket}",
                                        validator: validate_ListObjects_773290,
                                        base: "/", url: url_ListObjects_773291,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucket_773323 = ref object of OpenApiRestCall_772597
proc url_DeleteBucket_773325(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucket_773324(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773326 = path.getOrDefault("Bucket")
  valid_773326 = validateParameter(valid_773326, JString, required = true,
                                 default = nil)
  if valid_773326 != nil:
    section.add "Bucket", valid_773326
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773327 = header.getOrDefault("x-amz-security-token")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "x-amz-security-token", valid_773327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773328: Call_DeleteBucket_773323; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  let valid = call_773328.validator(path, query, header, formData, body)
  let scheme = call_773328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773328.url(scheme.get, call_773328.host, call_773328.base,
                         call_773328.route, valid.getOrDefault("path"))
  result = hook(call_773328, url, valid)

proc call*(call_773329: Call_DeleteBucket_773323; Bucket: string): Recallable =
  ## deleteBucket
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773330 = newJObject()
  add(path_773330, "Bucket", newJString(Bucket))
  result = call_773329.call(path_773330, nil, nil, nil, nil)

var deleteBucket* = Call_DeleteBucket_773323(name: "deleteBucket",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_DeleteBucket_773324, base: "/", url: url_DeleteBucket_773325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultipartUpload_773339 = ref object of OpenApiRestCall_772597
proc url_CreateMultipartUpload_773341(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMultipartUpload_773340(path: JsonNode; query: JsonNode;
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
  var valid_773342 = path.getOrDefault("Key")
  valid_773342 = validateParameter(valid_773342, JString, required = true,
                                 default = nil)
  if valid_773342 != nil:
    section.add "Key", valid_773342
  var valid_773343 = path.getOrDefault("Bucket")
  valid_773343 = validateParameter(valid_773343, JString, required = true,
                                 default = nil)
  if valid_773343 != nil:
    section.add "Bucket", valid_773343
  result.add "path", section
  ## parameters in `query` object:
  ##   uploads: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_773344 = query.getOrDefault("uploads")
  valid_773344 = validateParameter(valid_773344, JBool, required = true, default = nil)
  if valid_773344 != nil:
    section.add "uploads", valid_773344
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
  var valid_773345 = header.getOrDefault("Content-Disposition")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "Content-Disposition", valid_773345
  var valid_773346 = header.getOrDefault("x-amz-grant-full-control")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "x-amz-grant-full-control", valid_773346
  var valid_773347 = header.getOrDefault("x-amz-security-token")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "x-amz-security-token", valid_773347
  var valid_773348 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_773348
  var valid_773349 = header.getOrDefault("x-amz-object-lock-mode")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_773349 != nil:
    section.add "x-amz-object-lock-mode", valid_773349
  var valid_773350 = header.getOrDefault("Cache-Control")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "Cache-Control", valid_773350
  var valid_773351 = header.getOrDefault("Content-Language")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "Content-Language", valid_773351
  var valid_773352 = header.getOrDefault("Content-Type")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "Content-Type", valid_773352
  var valid_773353 = header.getOrDefault("Expires")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "Expires", valid_773353
  var valid_773354 = header.getOrDefault("x-amz-website-redirect-location")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "x-amz-website-redirect-location", valid_773354
  var valid_773355 = header.getOrDefault("x-amz-acl")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = newJString("private"))
  if valid_773355 != nil:
    section.add "x-amz-acl", valid_773355
  var valid_773356 = header.getOrDefault("x-amz-grant-read")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "x-amz-grant-read", valid_773356
  var valid_773357 = header.getOrDefault("x-amz-storage-class")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_773357 != nil:
    section.add "x-amz-storage-class", valid_773357
  var valid_773358 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = newJString("ON"))
  if valid_773358 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_773358
  var valid_773359 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_773359
  var valid_773360 = header.getOrDefault("x-amz-tagging")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "x-amz-tagging", valid_773360
  var valid_773361 = header.getOrDefault("x-amz-grant-read-acp")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "x-amz-grant-read-acp", valid_773361
  var valid_773362 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "x-amz-server-side-encryption-context", valid_773362
  var valid_773363 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_773363
  var valid_773364 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_773364
  var valid_773365 = header.getOrDefault("x-amz-grant-write-acp")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "x-amz-grant-write-acp", valid_773365
  var valid_773366 = header.getOrDefault("Content-Encoding")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "Content-Encoding", valid_773366
  var valid_773367 = header.getOrDefault("x-amz-request-payer")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = newJString("requester"))
  if valid_773367 != nil:
    section.add "x-amz-request-payer", valid_773367
  var valid_773368 = header.getOrDefault("x-amz-server-side-encryption")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = newJString("AES256"))
  if valid_773368 != nil:
    section.add "x-amz-server-side-encryption", valid_773368
  var valid_773369 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_773369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773371: Call_CreateMultipartUpload_773339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  let valid = call_773371.validator(path, query, header, formData, body)
  let scheme = call_773371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773371.url(scheme.get, call_773371.host, call_773371.base,
                         call_773371.route, valid.getOrDefault("path"))
  result = hook(call_773371, url, valid)

proc call*(call_773372: Call_CreateMultipartUpload_773339; Key: string;
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
  var path_773373 = newJObject()
  var query_773374 = newJObject()
  var body_773375 = newJObject()
  add(path_773373, "Key", newJString(Key))
  add(query_773374, "uploads", newJBool(uploads))
  add(path_773373, "Bucket", newJString(Bucket))
  if body != nil:
    body_773375 = body
  result = call_773372.call(path_773373, query_773374, nil, nil, body_773375)

var createMultipartUpload* = Call_CreateMultipartUpload_773339(
    name: "createMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploads",
    validator: validate_CreateMultipartUpload_773340, base: "/",
    url: url_CreateMultipartUpload_773341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAnalyticsConfiguration_773387 = ref object of OpenApiRestCall_772597
proc url_PutBucketAnalyticsConfiguration_773389(protocol: Scheme; host: string;
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

proc validate_PutBucketAnalyticsConfiguration_773388(path: JsonNode;
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
  var valid_773390 = path.getOrDefault("Bucket")
  valid_773390 = validateParameter(valid_773390, JString, required = true,
                                 default = nil)
  if valid_773390 != nil:
    section.add "Bucket", valid_773390
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_773391 = query.getOrDefault("id")
  valid_773391 = validateParameter(valid_773391, JString, required = true,
                                 default = nil)
  if valid_773391 != nil:
    section.add "id", valid_773391
  var valid_773392 = query.getOrDefault("analytics")
  valid_773392 = validateParameter(valid_773392, JBool, required = true, default = nil)
  if valid_773392 != nil:
    section.add "analytics", valid_773392
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773393 = header.getOrDefault("x-amz-security-token")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "x-amz-security-token", valid_773393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773395: Call_PutBucketAnalyticsConfiguration_773387;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_773395.validator(path, query, header, formData, body)
  let scheme = call_773395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773395.url(scheme.get, call_773395.host, call_773395.base,
                         call_773395.route, valid.getOrDefault("path"))
  result = hook(call_773395, url, valid)

proc call*(call_773396: Call_PutBucketAnalyticsConfiguration_773387; id: string;
          analytics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAnalyticsConfiguration
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket to which an analytics configuration is stored.
  ##   body: JObject (required)
  var path_773397 = newJObject()
  var query_773398 = newJObject()
  var body_773399 = newJObject()
  add(query_773398, "id", newJString(id))
  add(query_773398, "analytics", newJBool(analytics))
  add(path_773397, "Bucket", newJString(Bucket))
  if body != nil:
    body_773399 = body
  result = call_773396.call(path_773397, query_773398, nil, nil, body_773399)

var putBucketAnalyticsConfiguration* = Call_PutBucketAnalyticsConfiguration_773387(
    name: "putBucketAnalyticsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_PutBucketAnalyticsConfiguration_773388, base: "/",
    url: url_PutBucketAnalyticsConfiguration_773389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAnalyticsConfiguration_773376 = ref object of OpenApiRestCall_772597
proc url_GetBucketAnalyticsConfiguration_773378(protocol: Scheme; host: string;
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

proc validate_GetBucketAnalyticsConfiguration_773377(path: JsonNode;
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
  var valid_773379 = path.getOrDefault("Bucket")
  valid_773379 = validateParameter(valid_773379, JString, required = true,
                                 default = nil)
  if valid_773379 != nil:
    section.add "Bucket", valid_773379
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_773380 = query.getOrDefault("id")
  valid_773380 = validateParameter(valid_773380, JString, required = true,
                                 default = nil)
  if valid_773380 != nil:
    section.add "id", valid_773380
  var valid_773381 = query.getOrDefault("analytics")
  valid_773381 = validateParameter(valid_773381, JBool, required = true, default = nil)
  if valid_773381 != nil:
    section.add "analytics", valid_773381
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773382 = header.getOrDefault("x-amz-security-token")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "x-amz-security-token", valid_773382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773383: Call_GetBucketAnalyticsConfiguration_773376;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_773383.validator(path, query, header, formData, body)
  let scheme = call_773383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773383.url(scheme.get, call_773383.host, call_773383.base,
                         call_773383.route, valid.getOrDefault("path"))
  result = hook(call_773383, url, valid)

proc call*(call_773384: Call_GetBucketAnalyticsConfiguration_773376; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## getBucketAnalyticsConfiguration
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is retrieved.
  var path_773385 = newJObject()
  var query_773386 = newJObject()
  add(query_773386, "id", newJString(id))
  add(query_773386, "analytics", newJBool(analytics))
  add(path_773385, "Bucket", newJString(Bucket))
  result = call_773384.call(path_773385, query_773386, nil, nil, nil)

var getBucketAnalyticsConfiguration* = Call_GetBucketAnalyticsConfiguration_773376(
    name: "getBucketAnalyticsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_GetBucketAnalyticsConfiguration_773377, base: "/",
    url: url_GetBucketAnalyticsConfiguration_773378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketAnalyticsConfiguration_773400 = ref object of OpenApiRestCall_772597
proc url_DeleteBucketAnalyticsConfiguration_773402(protocol: Scheme; host: string;
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

proc validate_DeleteBucketAnalyticsConfiguration_773401(path: JsonNode;
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
  var valid_773403 = path.getOrDefault("Bucket")
  valid_773403 = validateParameter(valid_773403, JString, required = true,
                                 default = nil)
  if valid_773403 != nil:
    section.add "Bucket", valid_773403
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_773404 = query.getOrDefault("id")
  valid_773404 = validateParameter(valid_773404, JString, required = true,
                                 default = nil)
  if valid_773404 != nil:
    section.add "id", valid_773404
  var valid_773405 = query.getOrDefault("analytics")
  valid_773405 = validateParameter(valid_773405, JBool, required = true, default = nil)
  if valid_773405 != nil:
    section.add "analytics", valid_773405
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773406 = header.getOrDefault("x-amz-security-token")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "x-amz-security-token", valid_773406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773407: Call_DeleteBucketAnalyticsConfiguration_773400;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ## 
  let valid = call_773407.validator(path, query, header, formData, body)
  let scheme = call_773407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773407.url(scheme.get, call_773407.host, call_773407.base,
                         call_773407.route, valid.getOrDefault("path"))
  result = hook(call_773407, url, valid)

proc call*(call_773408: Call_DeleteBucketAnalyticsConfiguration_773400; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## deleteBucketAnalyticsConfiguration
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is deleted.
  var path_773409 = newJObject()
  var query_773410 = newJObject()
  add(query_773410, "id", newJString(id))
  add(query_773410, "analytics", newJBool(analytics))
  add(path_773409, "Bucket", newJString(Bucket))
  result = call_773408.call(path_773409, query_773410, nil, nil, nil)

var deleteBucketAnalyticsConfiguration* = Call_DeleteBucketAnalyticsConfiguration_773400(
    name: "deleteBucketAnalyticsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_DeleteBucketAnalyticsConfiguration_773401, base: "/",
    url: url_DeleteBucketAnalyticsConfiguration_773402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketCors_773421 = ref object of OpenApiRestCall_772597
proc url_PutBucketCors_773423(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketCors_773422(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773424 = path.getOrDefault("Bucket")
  valid_773424 = validateParameter(valid_773424, JString, required = true,
                                 default = nil)
  if valid_773424 != nil:
    section.add "Bucket", valid_773424
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_773425 = query.getOrDefault("cors")
  valid_773425 = validateParameter(valid_773425, JBool, required = true, default = nil)
  if valid_773425 != nil:
    section.add "cors", valid_773425
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_773426 = header.getOrDefault("x-amz-security-token")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "x-amz-security-token", valid_773426
  var valid_773427 = header.getOrDefault("Content-MD5")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "Content-MD5", valid_773427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773429: Call_PutBucketCors_773421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the CORS configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  let valid = call_773429.validator(path, query, header, formData, body)
  let scheme = call_773429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773429.url(scheme.get, call_773429.host, call_773429.base,
                         call_773429.route, valid.getOrDefault("path"))
  result = hook(call_773429, url, valid)

proc call*(call_773430: Call_PutBucketCors_773421; cors: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketCors
  ## Sets the CORS configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_773431 = newJObject()
  var query_773432 = newJObject()
  var body_773433 = newJObject()
  add(query_773432, "cors", newJBool(cors))
  add(path_773431, "Bucket", newJString(Bucket))
  if body != nil:
    body_773433 = body
  result = call_773430.call(path_773431, query_773432, nil, nil, body_773433)

var putBucketCors* = Call_PutBucketCors_773421(name: "putBucketCors",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_PutBucketCors_773422, base: "/", url: url_PutBucketCors_773423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketCors_773411 = ref object of OpenApiRestCall_772597
proc url_GetBucketCors_773413(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketCors_773412(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773414 = path.getOrDefault("Bucket")
  valid_773414 = validateParameter(valid_773414, JString, required = true,
                                 default = nil)
  if valid_773414 != nil:
    section.add "Bucket", valid_773414
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_773415 = query.getOrDefault("cors")
  valid_773415 = validateParameter(valid_773415, JBool, required = true, default = nil)
  if valid_773415 != nil:
    section.add "cors", valid_773415
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773416 = header.getOrDefault("x-amz-security-token")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "x-amz-security-token", valid_773416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773417: Call_GetBucketCors_773411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the CORS configuration for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  let valid = call_773417.validator(path, query, header, formData, body)
  let scheme = call_773417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773417.url(scheme.get, call_773417.host, call_773417.base,
                         call_773417.route, valid.getOrDefault("path"))
  result = hook(call_773417, url, valid)

proc call*(call_773418: Call_GetBucketCors_773411; cors: bool; Bucket: string): Recallable =
  ## getBucketCors
  ## Returns the CORS configuration for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773419 = newJObject()
  var query_773420 = newJObject()
  add(query_773420, "cors", newJBool(cors))
  add(path_773419, "Bucket", newJString(Bucket))
  result = call_773418.call(path_773419, query_773420, nil, nil, nil)

var getBucketCors* = Call_GetBucketCors_773411(name: "getBucketCors",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_GetBucketCors_773412, base: "/", url: url_GetBucketCors_773413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketCors_773434 = ref object of OpenApiRestCall_772597
proc url_DeleteBucketCors_773436(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketCors_773435(path: JsonNode; query: JsonNode;
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
  var valid_773437 = path.getOrDefault("Bucket")
  valid_773437 = validateParameter(valid_773437, JString, required = true,
                                 default = nil)
  if valid_773437 != nil:
    section.add "Bucket", valid_773437
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_773438 = query.getOrDefault("cors")
  valid_773438 = validateParameter(valid_773438, JBool, required = true, default = nil)
  if valid_773438 != nil:
    section.add "cors", valid_773438
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773439 = header.getOrDefault("x-amz-security-token")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "x-amz-security-token", valid_773439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773440: Call_DeleteBucketCors_773434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the CORS configuration information set for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  let valid = call_773440.validator(path, query, header, formData, body)
  let scheme = call_773440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773440.url(scheme.get, call_773440.host, call_773440.base,
                         call_773440.route, valid.getOrDefault("path"))
  result = hook(call_773440, url, valid)

proc call*(call_773441: Call_DeleteBucketCors_773434; cors: bool; Bucket: string): Recallable =
  ## deleteBucketCors
  ## Deletes the CORS configuration information set for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773442 = newJObject()
  var query_773443 = newJObject()
  add(query_773443, "cors", newJBool(cors))
  add(path_773442, "Bucket", newJString(Bucket))
  result = call_773441.call(path_773442, query_773443, nil, nil, nil)

var deleteBucketCors* = Call_DeleteBucketCors_773434(name: "deleteBucketCors",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_DeleteBucketCors_773435, base: "/",
    url: url_DeleteBucketCors_773436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketEncryption_773454 = ref object of OpenApiRestCall_772597
proc url_PutBucketEncryption_773456(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketEncryption_773455(path: JsonNode; query: JsonNode;
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
  var valid_773457 = path.getOrDefault("Bucket")
  valid_773457 = validateParameter(valid_773457, JString, required = true,
                                 default = nil)
  if valid_773457 != nil:
    section.add "Bucket", valid_773457
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_773458 = query.getOrDefault("encryption")
  valid_773458 = validateParameter(valid_773458, JBool, required = true, default = nil)
  if valid_773458 != nil:
    section.add "encryption", valid_773458
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the server-side encryption configuration. This parameter is auto-populated when using the command from the CLI.
  section = newJObject()
  var valid_773459 = header.getOrDefault("x-amz-security-token")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "x-amz-security-token", valid_773459
  var valid_773460 = header.getOrDefault("Content-MD5")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "Content-MD5", valid_773460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773462: Call_PutBucketEncryption_773454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ## 
  let valid = call_773462.validator(path, query, header, formData, body)
  let scheme = call_773462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773462.url(scheme.get, call_773462.host, call_773462.base,
                         call_773462.route, valid.getOrDefault("path"))
  result = hook(call_773462, url, valid)

proc call*(call_773463: Call_PutBucketEncryption_773454; encryption: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketEncryption
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : Specifies default encryption for a bucket using server-side encryption with Amazon S3-managed keys (SSE-S3) or AWS KMS-managed keys (SSE-KMS). For information about the Amazon S3 default encryption feature, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 Default Bucket Encryption</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   body: JObject (required)
  var path_773464 = newJObject()
  var query_773465 = newJObject()
  var body_773466 = newJObject()
  add(query_773465, "encryption", newJBool(encryption))
  add(path_773464, "Bucket", newJString(Bucket))
  if body != nil:
    body_773466 = body
  result = call_773463.call(path_773464, query_773465, nil, nil, body_773466)

var putBucketEncryption* = Call_PutBucketEncryption_773454(
    name: "putBucketEncryption", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_PutBucketEncryption_773455,
    base: "/", url: url_PutBucketEncryption_773456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketEncryption_773444 = ref object of OpenApiRestCall_772597
proc url_GetBucketEncryption_773446(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketEncryption_773445(path: JsonNode; query: JsonNode;
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
  var valid_773447 = path.getOrDefault("Bucket")
  valid_773447 = validateParameter(valid_773447, JString, required = true,
                                 default = nil)
  if valid_773447 != nil:
    section.add "Bucket", valid_773447
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_773448 = query.getOrDefault("encryption")
  valid_773448 = validateParameter(valid_773448, JBool, required = true, default = nil)
  if valid_773448 != nil:
    section.add "encryption", valid_773448
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773449 = header.getOrDefault("x-amz-security-token")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "x-amz-security-token", valid_773449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773450: Call_GetBucketEncryption_773444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the server-side encryption configuration of a bucket.
  ## 
  let valid = call_773450.validator(path, query, header, formData, body)
  let scheme = call_773450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773450.url(scheme.get, call_773450.host, call_773450.base,
                         call_773450.route, valid.getOrDefault("path"))
  result = hook(call_773450, url, valid)

proc call*(call_773451: Call_GetBucketEncryption_773444; encryption: bool;
          Bucket: string): Recallable =
  ## getBucketEncryption
  ## Returns the server-side encryption configuration of a bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which the server-side encryption configuration is retrieved.
  var path_773452 = newJObject()
  var query_773453 = newJObject()
  add(query_773453, "encryption", newJBool(encryption))
  add(path_773452, "Bucket", newJString(Bucket))
  result = call_773451.call(path_773452, query_773453, nil, nil, nil)

var getBucketEncryption* = Call_GetBucketEncryption_773444(
    name: "getBucketEncryption", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_GetBucketEncryption_773445,
    base: "/", url: url_GetBucketEncryption_773446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketEncryption_773467 = ref object of OpenApiRestCall_772597
proc url_DeleteBucketEncryption_773469(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketEncryption_773468(path: JsonNode; query: JsonNode;
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
  var valid_773470 = path.getOrDefault("Bucket")
  valid_773470 = validateParameter(valid_773470, JString, required = true,
                                 default = nil)
  if valid_773470 != nil:
    section.add "Bucket", valid_773470
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_773471 = query.getOrDefault("encryption")
  valid_773471 = validateParameter(valid_773471, JBool, required = true, default = nil)
  if valid_773471 != nil:
    section.add "encryption", valid_773471
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773472 = header.getOrDefault("x-amz-security-token")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "x-amz-security-token", valid_773472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773473: Call_DeleteBucketEncryption_773467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the server-side encryption configuration from the bucket.
  ## 
  let valid = call_773473.validator(path, query, header, formData, body)
  let scheme = call_773473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773473.url(scheme.get, call_773473.host, call_773473.base,
                         call_773473.route, valid.getOrDefault("path"))
  result = hook(call_773473, url, valid)

proc call*(call_773474: Call_DeleteBucketEncryption_773467; encryption: bool;
          Bucket: string): Recallable =
  ## deleteBucketEncryption
  ## Deletes the server-side encryption configuration from the bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the server-side encryption configuration to delete.
  var path_773475 = newJObject()
  var query_773476 = newJObject()
  add(query_773476, "encryption", newJBool(encryption))
  add(path_773475, "Bucket", newJString(Bucket))
  result = call_773474.call(path_773475, query_773476, nil, nil, nil)

var deleteBucketEncryption* = Call_DeleteBucketEncryption_773467(
    name: "deleteBucketEncryption", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#encryption",
    validator: validate_DeleteBucketEncryption_773468, base: "/",
    url: url_DeleteBucketEncryption_773469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketInventoryConfiguration_773488 = ref object of OpenApiRestCall_772597
proc url_PutBucketInventoryConfiguration_773490(protocol: Scheme; host: string;
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

proc validate_PutBucketInventoryConfiguration_773489(path: JsonNode;
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
  var valid_773491 = path.getOrDefault("Bucket")
  valid_773491 = validateParameter(valid_773491, JString, required = true,
                                 default = nil)
  if valid_773491 != nil:
    section.add "Bucket", valid_773491
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_773492 = query.getOrDefault("inventory")
  valid_773492 = validateParameter(valid_773492, JBool, required = true, default = nil)
  if valid_773492 != nil:
    section.add "inventory", valid_773492
  var valid_773493 = query.getOrDefault("id")
  valid_773493 = validateParameter(valid_773493, JString, required = true,
                                 default = nil)
  if valid_773493 != nil:
    section.add "id", valid_773493
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773494 = header.getOrDefault("x-amz-security-token")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "x-amz-security-token", valid_773494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773496: Call_PutBucketInventoryConfiguration_773488;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_773496.validator(path, query, header, formData, body)
  let scheme = call_773496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773496.url(scheme.get, call_773496.host, call_773496.base,
                         call_773496.route, valid.getOrDefault("path"))
  result = hook(call_773496, url, valid)

proc call*(call_773497: Call_PutBucketInventoryConfiguration_773488;
          inventory: bool; id: string; Bucket: string; body: JsonNode): Recallable =
  ## putBucketInventoryConfiguration
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket where the inventory configuration will be stored.
  ##   body: JObject (required)
  var path_773498 = newJObject()
  var query_773499 = newJObject()
  var body_773500 = newJObject()
  add(query_773499, "inventory", newJBool(inventory))
  add(query_773499, "id", newJString(id))
  add(path_773498, "Bucket", newJString(Bucket))
  if body != nil:
    body_773500 = body
  result = call_773497.call(path_773498, query_773499, nil, nil, body_773500)

var putBucketInventoryConfiguration* = Call_PutBucketInventoryConfiguration_773488(
    name: "putBucketInventoryConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_PutBucketInventoryConfiguration_773489, base: "/",
    url: url_PutBucketInventoryConfiguration_773490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketInventoryConfiguration_773477 = ref object of OpenApiRestCall_772597
proc url_GetBucketInventoryConfiguration_773479(protocol: Scheme; host: string;
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

proc validate_GetBucketInventoryConfiguration_773478(path: JsonNode;
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
  var valid_773480 = path.getOrDefault("Bucket")
  valid_773480 = validateParameter(valid_773480, JString, required = true,
                                 default = nil)
  if valid_773480 != nil:
    section.add "Bucket", valid_773480
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_773481 = query.getOrDefault("inventory")
  valid_773481 = validateParameter(valid_773481, JBool, required = true, default = nil)
  if valid_773481 != nil:
    section.add "inventory", valid_773481
  var valid_773482 = query.getOrDefault("id")
  valid_773482 = validateParameter(valid_773482, JString, required = true,
                                 default = nil)
  if valid_773482 != nil:
    section.add "id", valid_773482
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773483 = header.getOrDefault("x-amz-security-token")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "x-amz-security-token", valid_773483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773484: Call_GetBucketInventoryConfiguration_773477;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_773484.validator(path, query, header, formData, body)
  let scheme = call_773484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773484.url(scheme.get, call_773484.host, call_773484.base,
                         call_773484.route, valid.getOrDefault("path"))
  result = hook(call_773484, url, valid)

proc call*(call_773485: Call_GetBucketInventoryConfiguration_773477;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## getBucketInventoryConfiguration
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to retrieve.
  var path_773486 = newJObject()
  var query_773487 = newJObject()
  add(query_773487, "inventory", newJBool(inventory))
  add(query_773487, "id", newJString(id))
  add(path_773486, "Bucket", newJString(Bucket))
  result = call_773485.call(path_773486, query_773487, nil, nil, nil)

var getBucketInventoryConfiguration* = Call_GetBucketInventoryConfiguration_773477(
    name: "getBucketInventoryConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_GetBucketInventoryConfiguration_773478, base: "/",
    url: url_GetBucketInventoryConfiguration_773479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketInventoryConfiguration_773501 = ref object of OpenApiRestCall_772597
proc url_DeleteBucketInventoryConfiguration_773503(protocol: Scheme; host: string;
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

proc validate_DeleteBucketInventoryConfiguration_773502(path: JsonNode;
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
  var valid_773504 = path.getOrDefault("Bucket")
  valid_773504 = validateParameter(valid_773504, JString, required = true,
                                 default = nil)
  if valid_773504 != nil:
    section.add "Bucket", valid_773504
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_773505 = query.getOrDefault("inventory")
  valid_773505 = validateParameter(valid_773505, JBool, required = true, default = nil)
  if valid_773505 != nil:
    section.add "inventory", valid_773505
  var valid_773506 = query.getOrDefault("id")
  valid_773506 = validateParameter(valid_773506, JString, required = true,
                                 default = nil)
  if valid_773506 != nil:
    section.add "id", valid_773506
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773507 = header.getOrDefault("x-amz-security-token")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "x-amz-security-token", valid_773507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773508: Call_DeleteBucketInventoryConfiguration_773501;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_773508.validator(path, query, header, formData, body)
  let scheme = call_773508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773508.url(scheme.get, call_773508.host, call_773508.base,
                         call_773508.route, valid.getOrDefault("path"))
  result = hook(call_773508, url, valid)

proc call*(call_773509: Call_DeleteBucketInventoryConfiguration_773501;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## deleteBucketInventoryConfiguration
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to delete.
  var path_773510 = newJObject()
  var query_773511 = newJObject()
  add(query_773511, "inventory", newJBool(inventory))
  add(query_773511, "id", newJString(id))
  add(path_773510, "Bucket", newJString(Bucket))
  result = call_773509.call(path_773510, query_773511, nil, nil, nil)

var deleteBucketInventoryConfiguration* = Call_DeleteBucketInventoryConfiguration_773501(
    name: "deleteBucketInventoryConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_DeleteBucketInventoryConfiguration_773502, base: "/",
    url: url_DeleteBucketInventoryConfiguration_773503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycleConfiguration_773522 = ref object of OpenApiRestCall_772597
proc url_PutBucketLifecycleConfiguration_773524(protocol: Scheme; host: string;
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

proc validate_PutBucketLifecycleConfiguration_773523(path: JsonNode;
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
  var valid_773525 = path.getOrDefault("Bucket")
  valid_773525 = validateParameter(valid_773525, JString, required = true,
                                 default = nil)
  if valid_773525 != nil:
    section.add "Bucket", valid_773525
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_773526 = query.getOrDefault("lifecycle")
  valid_773526 = validateParameter(valid_773526, JBool, required = true, default = nil)
  if valid_773526 != nil:
    section.add "lifecycle", valid_773526
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773527 = header.getOrDefault("x-amz-security-token")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "x-amz-security-token", valid_773527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773529: Call_PutBucketLifecycleConfiguration_773522;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ## 
  let valid = call_773529.validator(path, query, header, formData, body)
  let scheme = call_773529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773529.url(scheme.get, call_773529.host, call_773529.base,
                         call_773529.route, valid.getOrDefault("path"))
  result = hook(call_773529, url, valid)

proc call*(call_773530: Call_PutBucketLifecycleConfiguration_773522;
          Bucket: string; lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycleConfiguration
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_773531 = newJObject()
  var query_773532 = newJObject()
  var body_773533 = newJObject()
  add(path_773531, "Bucket", newJString(Bucket))
  add(query_773532, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_773533 = body
  result = call_773530.call(path_773531, query_773532, nil, nil, body_773533)

var putBucketLifecycleConfiguration* = Call_PutBucketLifecycleConfiguration_773522(
    name: "putBucketLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_PutBucketLifecycleConfiguration_773523, base: "/",
    url: url_PutBucketLifecycleConfiguration_773524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycleConfiguration_773512 = ref object of OpenApiRestCall_772597
proc url_GetBucketLifecycleConfiguration_773514(protocol: Scheme; host: string;
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

proc validate_GetBucketLifecycleConfiguration_773513(path: JsonNode;
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
  var valid_773515 = path.getOrDefault("Bucket")
  valid_773515 = validateParameter(valid_773515, JString, required = true,
                                 default = nil)
  if valid_773515 != nil:
    section.add "Bucket", valid_773515
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_773516 = query.getOrDefault("lifecycle")
  valid_773516 = validateParameter(valid_773516, JBool, required = true, default = nil)
  if valid_773516 != nil:
    section.add "lifecycle", valid_773516
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773517 = header.getOrDefault("x-amz-security-token")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "x-amz-security-token", valid_773517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773518: Call_GetBucketLifecycleConfiguration_773512;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the lifecycle configuration information set on the bucket.
  ## 
  let valid = call_773518.validator(path, query, header, formData, body)
  let scheme = call_773518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773518.url(scheme.get, call_773518.host, call_773518.base,
                         call_773518.route, valid.getOrDefault("path"))
  result = hook(call_773518, url, valid)

proc call*(call_773519: Call_GetBucketLifecycleConfiguration_773512;
          Bucket: string; lifecycle: bool): Recallable =
  ## getBucketLifecycleConfiguration
  ## Returns the lifecycle configuration information set on the bucket.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_773520 = newJObject()
  var query_773521 = newJObject()
  add(path_773520, "Bucket", newJString(Bucket))
  add(query_773521, "lifecycle", newJBool(lifecycle))
  result = call_773519.call(path_773520, query_773521, nil, nil, nil)

var getBucketLifecycleConfiguration* = Call_GetBucketLifecycleConfiguration_773512(
    name: "getBucketLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_GetBucketLifecycleConfiguration_773513, base: "/",
    url: url_GetBucketLifecycleConfiguration_773514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketLifecycle_773534 = ref object of OpenApiRestCall_772597
proc url_DeleteBucketLifecycle_773536(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketLifecycle_773535(path: JsonNode; query: JsonNode;
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
  var valid_773537 = path.getOrDefault("Bucket")
  valid_773537 = validateParameter(valid_773537, JString, required = true,
                                 default = nil)
  if valid_773537 != nil:
    section.add "Bucket", valid_773537
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_773538 = query.getOrDefault("lifecycle")
  valid_773538 = validateParameter(valid_773538, JBool, required = true, default = nil)
  if valid_773538 != nil:
    section.add "lifecycle", valid_773538
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773539 = header.getOrDefault("x-amz-security-token")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "x-amz-security-token", valid_773539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773540: Call_DeleteBucketLifecycle_773534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the lifecycle configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  let valid = call_773540.validator(path, query, header, formData, body)
  let scheme = call_773540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773540.url(scheme.get, call_773540.host, call_773540.base,
                         call_773540.route, valid.getOrDefault("path"))
  result = hook(call_773540, url, valid)

proc call*(call_773541: Call_DeleteBucketLifecycle_773534; Bucket: string;
          lifecycle: bool): Recallable =
  ## deleteBucketLifecycle
  ## Deletes the lifecycle configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_773542 = newJObject()
  var query_773543 = newJObject()
  add(path_773542, "Bucket", newJString(Bucket))
  add(query_773543, "lifecycle", newJBool(lifecycle))
  result = call_773541.call(path_773542, query_773543, nil, nil, nil)

var deleteBucketLifecycle* = Call_DeleteBucketLifecycle_773534(
    name: "deleteBucketLifecycle", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_DeleteBucketLifecycle_773535, base: "/",
    url: url_DeleteBucketLifecycle_773536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketMetricsConfiguration_773555 = ref object of OpenApiRestCall_772597
proc url_PutBucketMetricsConfiguration_773557(protocol: Scheme; host: string;
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

proc validate_PutBucketMetricsConfiguration_773556(path: JsonNode; query: JsonNode;
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
  var valid_773558 = path.getOrDefault("Bucket")
  valid_773558 = validateParameter(valid_773558, JString, required = true,
                                 default = nil)
  if valid_773558 != nil:
    section.add "Bucket", valid_773558
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_773559 = query.getOrDefault("id")
  valid_773559 = validateParameter(valid_773559, JString, required = true,
                                 default = nil)
  if valid_773559 != nil:
    section.add "id", valid_773559
  var valid_773560 = query.getOrDefault("metrics")
  valid_773560 = validateParameter(valid_773560, JBool, required = true, default = nil)
  if valid_773560 != nil:
    section.add "metrics", valid_773560
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773561 = header.getOrDefault("x-amz-security-token")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "x-amz-security-token", valid_773561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773563: Call_PutBucketMetricsConfiguration_773555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ## 
  let valid = call_773563.validator(path, query, header, formData, body)
  let scheme = call_773563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773563.url(scheme.get, call_773563.host, call_773563.base,
                         call_773563.route, valid.getOrDefault("path"))
  result = hook(call_773563, url, valid)

proc call*(call_773564: Call_PutBucketMetricsConfiguration_773555; id: string;
          metrics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketMetricsConfiguration
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket for which the metrics configuration is set.
  ##   body: JObject (required)
  var path_773565 = newJObject()
  var query_773566 = newJObject()
  var body_773567 = newJObject()
  add(query_773566, "id", newJString(id))
  add(query_773566, "metrics", newJBool(metrics))
  add(path_773565, "Bucket", newJString(Bucket))
  if body != nil:
    body_773567 = body
  result = call_773564.call(path_773565, query_773566, nil, nil, body_773567)

var putBucketMetricsConfiguration* = Call_PutBucketMetricsConfiguration_773555(
    name: "putBucketMetricsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_PutBucketMetricsConfiguration_773556, base: "/",
    url: url_PutBucketMetricsConfiguration_773557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketMetricsConfiguration_773544 = ref object of OpenApiRestCall_772597
proc url_GetBucketMetricsConfiguration_773546(protocol: Scheme; host: string;
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

proc validate_GetBucketMetricsConfiguration_773545(path: JsonNode; query: JsonNode;
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
  var valid_773547 = path.getOrDefault("Bucket")
  valid_773547 = validateParameter(valid_773547, JString, required = true,
                                 default = nil)
  if valid_773547 != nil:
    section.add "Bucket", valid_773547
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_773548 = query.getOrDefault("id")
  valid_773548 = validateParameter(valid_773548, JString, required = true,
                                 default = nil)
  if valid_773548 != nil:
    section.add "id", valid_773548
  var valid_773549 = query.getOrDefault("metrics")
  valid_773549 = validateParameter(valid_773549, JBool, required = true, default = nil)
  if valid_773549 != nil:
    section.add "metrics", valid_773549
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773550 = header.getOrDefault("x-amz-security-token")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "x-amz-security-token", valid_773550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773551: Call_GetBucketMetricsConfiguration_773544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_773551.validator(path, query, header, formData, body)
  let scheme = call_773551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773551.url(scheme.get, call_773551.host, call_773551.base,
                         call_773551.route, valid.getOrDefault("path"))
  result = hook(call_773551, url, valid)

proc call*(call_773552: Call_GetBucketMetricsConfiguration_773544; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## getBucketMetricsConfiguration
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to retrieve.
  var path_773553 = newJObject()
  var query_773554 = newJObject()
  add(query_773554, "id", newJString(id))
  add(query_773554, "metrics", newJBool(metrics))
  add(path_773553, "Bucket", newJString(Bucket))
  result = call_773552.call(path_773553, query_773554, nil, nil, nil)

var getBucketMetricsConfiguration* = Call_GetBucketMetricsConfiguration_773544(
    name: "getBucketMetricsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_GetBucketMetricsConfiguration_773545, base: "/",
    url: url_GetBucketMetricsConfiguration_773546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketMetricsConfiguration_773568 = ref object of OpenApiRestCall_772597
proc url_DeleteBucketMetricsConfiguration_773570(protocol: Scheme; host: string;
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

proc validate_DeleteBucketMetricsConfiguration_773569(path: JsonNode;
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
  var valid_773571 = path.getOrDefault("Bucket")
  valid_773571 = validateParameter(valid_773571, JString, required = true,
                                 default = nil)
  if valid_773571 != nil:
    section.add "Bucket", valid_773571
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_773572 = query.getOrDefault("id")
  valid_773572 = validateParameter(valid_773572, JString, required = true,
                                 default = nil)
  if valid_773572 != nil:
    section.add "id", valid_773572
  var valid_773573 = query.getOrDefault("metrics")
  valid_773573 = validateParameter(valid_773573, JBool, required = true, default = nil)
  if valid_773573 != nil:
    section.add "metrics", valid_773573
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773574 = header.getOrDefault("x-amz-security-token")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "x-amz-security-token", valid_773574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773575: Call_DeleteBucketMetricsConfiguration_773568;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_773575.validator(path, query, header, formData, body)
  let scheme = call_773575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773575.url(scheme.get, call_773575.host, call_773575.base,
                         call_773575.route, valid.getOrDefault("path"))
  result = hook(call_773575, url, valid)

proc call*(call_773576: Call_DeleteBucketMetricsConfiguration_773568; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## deleteBucketMetricsConfiguration
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to delete.
  var path_773577 = newJObject()
  var query_773578 = newJObject()
  add(query_773578, "id", newJString(id))
  add(query_773578, "metrics", newJBool(metrics))
  add(path_773577, "Bucket", newJString(Bucket))
  result = call_773576.call(path_773577, query_773578, nil, nil, nil)

var deleteBucketMetricsConfiguration* = Call_DeleteBucketMetricsConfiguration_773568(
    name: "deleteBucketMetricsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_DeleteBucketMetricsConfiguration_773569, base: "/",
    url: url_DeleteBucketMetricsConfiguration_773570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketPolicy_773589 = ref object of OpenApiRestCall_772597
proc url_PutBucketPolicy_773591(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketPolicy_773590(path: JsonNode; query: JsonNode;
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
  var valid_773592 = path.getOrDefault("Bucket")
  valid_773592 = validateParameter(valid_773592, JString, required = true,
                                 default = nil)
  if valid_773592 != nil:
    section.add "Bucket", valid_773592
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_773593 = query.getOrDefault("policy")
  valid_773593 = validateParameter(valid_773593, JBool, required = true, default = nil)
  if valid_773593 != nil:
    section.add "policy", valid_773593
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-confirm-remove-self-bucket-access: JBool
  ##                                          : Set this parameter to true to confirm that you want to remove your permissions to change this bucket policy in the future.
  section = newJObject()
  var valid_773594 = header.getOrDefault("x-amz-security-token")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "x-amz-security-token", valid_773594
  var valid_773595 = header.getOrDefault("Content-MD5")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "Content-MD5", valid_773595
  var valid_773596 = header.getOrDefault("x-amz-confirm-remove-self-bucket-access")
  valid_773596 = validateParameter(valid_773596, JBool, required = false, default = nil)
  if valid_773596 != nil:
    section.add "x-amz-confirm-remove-self-bucket-access", valid_773596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773598: Call_PutBucketPolicy_773589; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  let valid = call_773598.validator(path, query, header, formData, body)
  let scheme = call_773598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773598.url(scheme.get, call_773598.host, call_773598.base,
                         call_773598.route, valid.getOrDefault("path"))
  result = hook(call_773598, url, valid)

proc call*(call_773599: Call_PutBucketPolicy_773589; policy: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketPolicy
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_773600 = newJObject()
  var query_773601 = newJObject()
  var body_773602 = newJObject()
  add(query_773601, "policy", newJBool(policy))
  add(path_773600, "Bucket", newJString(Bucket))
  if body != nil:
    body_773602 = body
  result = call_773599.call(path_773600, query_773601, nil, nil, body_773602)

var putBucketPolicy* = Call_PutBucketPolicy_773589(name: "putBucketPolicy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_PutBucketPolicy_773590, base: "/", url: url_PutBucketPolicy_773591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicy_773579 = ref object of OpenApiRestCall_772597
proc url_GetBucketPolicy_773581(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketPolicy_773580(path: JsonNode; query: JsonNode;
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
  var valid_773582 = path.getOrDefault("Bucket")
  valid_773582 = validateParameter(valid_773582, JString, required = true,
                                 default = nil)
  if valid_773582 != nil:
    section.add "Bucket", valid_773582
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_773583 = query.getOrDefault("policy")
  valid_773583 = validateParameter(valid_773583, JBool, required = true, default = nil)
  if valid_773583 != nil:
    section.add "policy", valid_773583
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773584 = header.getOrDefault("x-amz-security-token")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "x-amz-security-token", valid_773584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773585: Call_GetBucketPolicy_773579; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the policy of a specified bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  let valid = call_773585.validator(path, query, header, formData, body)
  let scheme = call_773585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773585.url(scheme.get, call_773585.host, call_773585.base,
                         call_773585.route, valid.getOrDefault("path"))
  result = hook(call_773585, url, valid)

proc call*(call_773586: Call_GetBucketPolicy_773579; policy: bool; Bucket: string): Recallable =
  ## getBucketPolicy
  ## Returns the policy of a specified bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773587 = newJObject()
  var query_773588 = newJObject()
  add(query_773588, "policy", newJBool(policy))
  add(path_773587, "Bucket", newJString(Bucket))
  result = call_773586.call(path_773587, query_773588, nil, nil, nil)

var getBucketPolicy* = Call_GetBucketPolicy_773579(name: "getBucketPolicy",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_GetBucketPolicy_773580, base: "/", url: url_GetBucketPolicy_773581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketPolicy_773603 = ref object of OpenApiRestCall_772597
proc url_DeleteBucketPolicy_773605(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketPolicy_773604(path: JsonNode; query: JsonNode;
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
  var valid_773606 = path.getOrDefault("Bucket")
  valid_773606 = validateParameter(valid_773606, JString, required = true,
                                 default = nil)
  if valid_773606 != nil:
    section.add "Bucket", valid_773606
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_773607 = query.getOrDefault("policy")
  valid_773607 = validateParameter(valid_773607, JBool, required = true, default = nil)
  if valid_773607 != nil:
    section.add "policy", valid_773607
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773608 = header.getOrDefault("x-amz-security-token")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "x-amz-security-token", valid_773608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773609: Call_DeleteBucketPolicy_773603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  let valid = call_773609.validator(path, query, header, formData, body)
  let scheme = call_773609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773609.url(scheme.get, call_773609.host, call_773609.base,
                         call_773609.route, valid.getOrDefault("path"))
  result = hook(call_773609, url, valid)

proc call*(call_773610: Call_DeleteBucketPolicy_773603; policy: bool; Bucket: string): Recallable =
  ## deleteBucketPolicy
  ## Deletes the policy from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773611 = newJObject()
  var query_773612 = newJObject()
  add(query_773612, "policy", newJBool(policy))
  add(path_773611, "Bucket", newJString(Bucket))
  result = call_773610.call(path_773611, query_773612, nil, nil, nil)

var deleteBucketPolicy* = Call_DeleteBucketPolicy_773603(
    name: "deleteBucketPolicy", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_DeleteBucketPolicy_773604, base: "/",
    url: url_DeleteBucketPolicy_773605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketReplication_773623 = ref object of OpenApiRestCall_772597
proc url_PutBucketReplication_773625(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketReplication_773624(path: JsonNode; query: JsonNode;
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
  var valid_773626 = path.getOrDefault("Bucket")
  valid_773626 = validateParameter(valid_773626, JString, required = true,
                                 default = nil)
  if valid_773626 != nil:
    section.add "Bucket", valid_773626
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_773627 = query.getOrDefault("replication")
  valid_773627 = validateParameter(valid_773627, JBool, required = true, default = nil)
  if valid_773627 != nil:
    section.add "replication", valid_773627
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit.
  ##   x-amz-bucket-object-lock-token: JString
  ##                                 : A token that allows Amazon S3 object lock to be enabled for an existing bucket.
  section = newJObject()
  var valid_773628 = header.getOrDefault("x-amz-security-token")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "x-amz-security-token", valid_773628
  var valid_773629 = header.getOrDefault("Content-MD5")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "Content-MD5", valid_773629
  var valid_773630 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_773630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773632: Call_PutBucketReplication_773623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_773632.validator(path, query, header, formData, body)
  let scheme = call_773632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773632.url(scheme.get, call_773632.host, call_773632.base,
                         call_773632.route, valid.getOrDefault("path"))
  result = hook(call_773632, url, valid)

proc call*(call_773633: Call_PutBucketReplication_773623; replication: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketReplication
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_773634 = newJObject()
  var query_773635 = newJObject()
  var body_773636 = newJObject()
  add(query_773635, "replication", newJBool(replication))
  add(path_773634, "Bucket", newJString(Bucket))
  if body != nil:
    body_773636 = body
  result = call_773633.call(path_773634, query_773635, nil, nil, body_773636)

var putBucketReplication* = Call_PutBucketReplication_773623(
    name: "putBucketReplication", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_PutBucketReplication_773624, base: "/",
    url: url_PutBucketReplication_773625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketReplication_773613 = ref object of OpenApiRestCall_772597
proc url_GetBucketReplication_773615(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketReplication_773614(path: JsonNode; query: JsonNode;
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
  var valid_773616 = path.getOrDefault("Bucket")
  valid_773616 = validateParameter(valid_773616, JString, required = true,
                                 default = nil)
  if valid_773616 != nil:
    section.add "Bucket", valid_773616
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_773617 = query.getOrDefault("replication")
  valid_773617 = validateParameter(valid_773617, JBool, required = true, default = nil)
  if valid_773617 != nil:
    section.add "replication", valid_773617
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773618 = header.getOrDefault("x-amz-security-token")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "x-amz-security-token", valid_773618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773619: Call_GetBucketReplication_773613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ## 
  let valid = call_773619.validator(path, query, header, formData, body)
  let scheme = call_773619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773619.url(scheme.get, call_773619.host, call_773619.base,
                         call_773619.route, valid.getOrDefault("path"))
  result = hook(call_773619, url, valid)

proc call*(call_773620: Call_GetBucketReplication_773613; replication: bool;
          Bucket: string): Recallable =
  ## getBucketReplication
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773621 = newJObject()
  var query_773622 = newJObject()
  add(query_773622, "replication", newJBool(replication))
  add(path_773621, "Bucket", newJString(Bucket))
  result = call_773620.call(path_773621, query_773622, nil, nil, nil)

var getBucketReplication* = Call_GetBucketReplication_773613(
    name: "getBucketReplication", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_GetBucketReplication_773614, base: "/",
    url: url_GetBucketReplication_773615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketReplication_773637 = ref object of OpenApiRestCall_772597
proc url_DeleteBucketReplication_773639(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketReplication_773638(path: JsonNode; query: JsonNode;
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
  var valid_773640 = path.getOrDefault("Bucket")
  valid_773640 = validateParameter(valid_773640, JString, required = true,
                                 default = nil)
  if valid_773640 != nil:
    section.add "Bucket", valid_773640
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_773641 = query.getOrDefault("replication")
  valid_773641 = validateParameter(valid_773641, JBool, required = true, default = nil)
  if valid_773641 != nil:
    section.add "replication", valid_773641
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773642 = header.getOrDefault("x-amz-security-token")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "x-amz-security-token", valid_773642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773643: Call_DeleteBucketReplication_773637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_773643.validator(path, query, header, formData, body)
  let scheme = call_773643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773643.url(scheme.get, call_773643.host, call_773643.base,
                         call_773643.route, valid.getOrDefault("path"))
  result = hook(call_773643, url, valid)

proc call*(call_773644: Call_DeleteBucketReplication_773637; replication: bool;
          Bucket: string): Recallable =
  ## deleteBucketReplication
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p> The bucket name. </p> <note> <p>It can take a while to propagate the deletion of a replication configuration to all Amazon S3 systems.</p> </note>
  var path_773645 = newJObject()
  var query_773646 = newJObject()
  add(query_773646, "replication", newJBool(replication))
  add(path_773645, "Bucket", newJString(Bucket))
  result = call_773644.call(path_773645, query_773646, nil, nil, nil)

var deleteBucketReplication* = Call_DeleteBucketReplication_773637(
    name: "deleteBucketReplication", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_DeleteBucketReplication_773638, base: "/",
    url: url_DeleteBucketReplication_773639, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketTagging_773657 = ref object of OpenApiRestCall_772597
proc url_PutBucketTagging_773659(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketTagging_773658(path: JsonNode; query: JsonNode;
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
  var valid_773660 = path.getOrDefault("Bucket")
  valid_773660 = validateParameter(valid_773660, JString, required = true,
                                 default = nil)
  if valid_773660 != nil:
    section.add "Bucket", valid_773660
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_773661 = query.getOrDefault("tagging")
  valid_773661 = validateParameter(valid_773661, JBool, required = true, default = nil)
  if valid_773661 != nil:
    section.add "tagging", valid_773661
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_773662 = header.getOrDefault("x-amz-security-token")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "x-amz-security-token", valid_773662
  var valid_773663 = header.getOrDefault("Content-MD5")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "Content-MD5", valid_773663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773665: Call_PutBucketTagging_773657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the tags for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  let valid = call_773665.validator(path, query, header, formData, body)
  let scheme = call_773665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773665.url(scheme.get, call_773665.host, call_773665.base,
                         call_773665.route, valid.getOrDefault("path"))
  result = hook(call_773665, url, valid)

proc call*(call_773666: Call_PutBucketTagging_773657; tagging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketTagging
  ## Sets the tags for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_773667 = newJObject()
  var query_773668 = newJObject()
  var body_773669 = newJObject()
  add(query_773668, "tagging", newJBool(tagging))
  add(path_773667, "Bucket", newJString(Bucket))
  if body != nil:
    body_773669 = body
  result = call_773666.call(path_773667, query_773668, nil, nil, body_773669)

var putBucketTagging* = Call_PutBucketTagging_773657(name: "putBucketTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_PutBucketTagging_773658, base: "/",
    url: url_PutBucketTagging_773659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketTagging_773647 = ref object of OpenApiRestCall_772597
proc url_GetBucketTagging_773649(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketTagging_773648(path: JsonNode; query: JsonNode;
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
  var valid_773650 = path.getOrDefault("Bucket")
  valid_773650 = validateParameter(valid_773650, JString, required = true,
                                 default = nil)
  if valid_773650 != nil:
    section.add "Bucket", valid_773650
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_773651 = query.getOrDefault("tagging")
  valid_773651 = validateParameter(valid_773651, JBool, required = true, default = nil)
  if valid_773651 != nil:
    section.add "tagging", valid_773651
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773652 = header.getOrDefault("x-amz-security-token")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "x-amz-security-token", valid_773652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773653: Call_GetBucketTagging_773647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag set associated with the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  let valid = call_773653.validator(path, query, header, formData, body)
  let scheme = call_773653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773653.url(scheme.get, call_773653.host, call_773653.base,
                         call_773653.route, valid.getOrDefault("path"))
  result = hook(call_773653, url, valid)

proc call*(call_773654: Call_GetBucketTagging_773647; tagging: bool; Bucket: string): Recallable =
  ## getBucketTagging
  ## Returns the tag set associated with the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773655 = newJObject()
  var query_773656 = newJObject()
  add(query_773656, "tagging", newJBool(tagging))
  add(path_773655, "Bucket", newJString(Bucket))
  result = call_773654.call(path_773655, query_773656, nil, nil, nil)

var getBucketTagging* = Call_GetBucketTagging_773647(name: "getBucketTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_GetBucketTagging_773648, base: "/",
    url: url_GetBucketTagging_773649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketTagging_773670 = ref object of OpenApiRestCall_772597
proc url_DeleteBucketTagging_773672(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketTagging_773671(path: JsonNode; query: JsonNode;
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
  var valid_773673 = path.getOrDefault("Bucket")
  valid_773673 = validateParameter(valid_773673, JString, required = true,
                                 default = nil)
  if valid_773673 != nil:
    section.add "Bucket", valid_773673
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_773674 = query.getOrDefault("tagging")
  valid_773674 = validateParameter(valid_773674, JBool, required = true, default = nil)
  if valid_773674 != nil:
    section.add "tagging", valid_773674
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773675 = header.getOrDefault("x-amz-security-token")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "x-amz-security-token", valid_773675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773676: Call_DeleteBucketTagging_773670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the tags from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  let valid = call_773676.validator(path, query, header, formData, body)
  let scheme = call_773676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773676.url(scheme.get, call_773676.host, call_773676.base,
                         call_773676.route, valid.getOrDefault("path"))
  result = hook(call_773676, url, valid)

proc call*(call_773677: Call_DeleteBucketTagging_773670; tagging: bool;
          Bucket: string): Recallable =
  ## deleteBucketTagging
  ## Deletes the tags from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773678 = newJObject()
  var query_773679 = newJObject()
  add(query_773679, "tagging", newJBool(tagging))
  add(path_773678, "Bucket", newJString(Bucket))
  result = call_773677.call(path_773678, query_773679, nil, nil, nil)

var deleteBucketTagging* = Call_DeleteBucketTagging_773670(
    name: "deleteBucketTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_DeleteBucketTagging_773671, base: "/",
    url: url_DeleteBucketTagging_773672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketWebsite_773690 = ref object of OpenApiRestCall_772597
proc url_PutBucketWebsite_773692(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketWebsite_773691(path: JsonNode; query: JsonNode;
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
  var valid_773693 = path.getOrDefault("Bucket")
  valid_773693 = validateParameter(valid_773693, JString, required = true,
                                 default = nil)
  if valid_773693 != nil:
    section.add "Bucket", valid_773693
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_773694 = query.getOrDefault("website")
  valid_773694 = validateParameter(valid_773694, JBool, required = true, default = nil)
  if valid_773694 != nil:
    section.add "website", valid_773694
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_773695 = header.getOrDefault("x-amz-security-token")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "x-amz-security-token", valid_773695
  var valid_773696 = header.getOrDefault("Content-MD5")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "Content-MD5", valid_773696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773698: Call_PutBucketWebsite_773690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  let valid = call_773698.validator(path, query, header, formData, body)
  let scheme = call_773698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773698.url(scheme.get, call_773698.host, call_773698.base,
                         call_773698.route, valid.getOrDefault("path"))
  result = hook(call_773698, url, valid)

proc call*(call_773699: Call_PutBucketWebsite_773690; website: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketWebsite
  ## Set the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_773700 = newJObject()
  var query_773701 = newJObject()
  var body_773702 = newJObject()
  add(query_773701, "website", newJBool(website))
  add(path_773700, "Bucket", newJString(Bucket))
  if body != nil:
    body_773702 = body
  result = call_773699.call(path_773700, query_773701, nil, nil, body_773702)

var putBucketWebsite* = Call_PutBucketWebsite_773690(name: "putBucketWebsite",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_PutBucketWebsite_773691, base: "/",
    url: url_PutBucketWebsite_773692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketWebsite_773680 = ref object of OpenApiRestCall_772597
proc url_GetBucketWebsite_773682(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketWebsite_773681(path: JsonNode; query: JsonNode;
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
  var valid_773683 = path.getOrDefault("Bucket")
  valid_773683 = validateParameter(valid_773683, JString, required = true,
                                 default = nil)
  if valid_773683 != nil:
    section.add "Bucket", valid_773683
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_773684 = query.getOrDefault("website")
  valid_773684 = validateParameter(valid_773684, JBool, required = true, default = nil)
  if valid_773684 != nil:
    section.add "website", valid_773684
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773685 = header.getOrDefault("x-amz-security-token")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "x-amz-security-token", valid_773685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773686: Call_GetBucketWebsite_773680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  let valid = call_773686.validator(path, query, header, formData, body)
  let scheme = call_773686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773686.url(scheme.get, call_773686.host, call_773686.base,
                         call_773686.route, valid.getOrDefault("path"))
  result = hook(call_773686, url, valid)

proc call*(call_773687: Call_GetBucketWebsite_773680; website: bool; Bucket: string): Recallable =
  ## getBucketWebsite
  ## Returns the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773688 = newJObject()
  var query_773689 = newJObject()
  add(query_773689, "website", newJBool(website))
  add(path_773688, "Bucket", newJString(Bucket))
  result = call_773687.call(path_773688, query_773689, nil, nil, nil)

var getBucketWebsite* = Call_GetBucketWebsite_773680(name: "getBucketWebsite",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_GetBucketWebsite_773681, base: "/",
    url: url_GetBucketWebsite_773682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketWebsite_773703 = ref object of OpenApiRestCall_772597
proc url_DeleteBucketWebsite_773705(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketWebsite_773704(path: JsonNode; query: JsonNode;
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
  var valid_773706 = path.getOrDefault("Bucket")
  valid_773706 = validateParameter(valid_773706, JString, required = true,
                                 default = nil)
  if valid_773706 != nil:
    section.add "Bucket", valid_773706
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_773707 = query.getOrDefault("website")
  valid_773707 = validateParameter(valid_773707, JBool, required = true, default = nil)
  if valid_773707 != nil:
    section.add "website", valid_773707
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773708 = header.getOrDefault("x-amz-security-token")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "x-amz-security-token", valid_773708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773709: Call_DeleteBucketWebsite_773703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes the website configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  let valid = call_773709.validator(path, query, header, formData, body)
  let scheme = call_773709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773709.url(scheme.get, call_773709.host, call_773709.base,
                         call_773709.route, valid.getOrDefault("path"))
  result = hook(call_773709, url, valid)

proc call*(call_773710: Call_DeleteBucketWebsite_773703; website: bool;
          Bucket: string): Recallable =
  ## deleteBucketWebsite
  ## This operation removes the website configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773711 = newJObject()
  var query_773712 = newJObject()
  add(query_773712, "website", newJBool(website))
  add(path_773711, "Bucket", newJString(Bucket))
  result = call_773710.call(path_773711, query_773712, nil, nil, nil)

var deleteBucketWebsite* = Call_DeleteBucketWebsite_773703(
    name: "deleteBucketWebsite", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_DeleteBucketWebsite_773704, base: "/",
    url: url_DeleteBucketWebsite_773705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObject_773740 = ref object of OpenApiRestCall_772597
proc url_PutObject_773742(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutObject_773741(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773743 = path.getOrDefault("Key")
  valid_773743 = validateParameter(valid_773743, JString, required = true,
                                 default = nil)
  if valid_773743 != nil:
    section.add "Key", valid_773743
  var valid_773744 = path.getOrDefault("Bucket")
  valid_773744 = validateParameter(valid_773744, JString, required = true,
                                 default = nil)
  if valid_773744 != nil:
    section.add "Bucket", valid_773744
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
  var valid_773745 = header.getOrDefault("Content-Disposition")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "Content-Disposition", valid_773745
  var valid_773746 = header.getOrDefault("x-amz-grant-full-control")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "x-amz-grant-full-control", valid_773746
  var valid_773747 = header.getOrDefault("x-amz-security-token")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "x-amz-security-token", valid_773747
  var valid_773748 = header.getOrDefault("Content-MD5")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "Content-MD5", valid_773748
  var valid_773749 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_773749
  var valid_773750 = header.getOrDefault("x-amz-object-lock-mode")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_773750 != nil:
    section.add "x-amz-object-lock-mode", valid_773750
  var valid_773751 = header.getOrDefault("Cache-Control")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "Cache-Control", valid_773751
  var valid_773752 = header.getOrDefault("Content-Language")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "Content-Language", valid_773752
  var valid_773753 = header.getOrDefault("Content-Type")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "Content-Type", valid_773753
  var valid_773754 = header.getOrDefault("Expires")
  valid_773754 = validateParameter(valid_773754, JString, required = false,
                                 default = nil)
  if valid_773754 != nil:
    section.add "Expires", valid_773754
  var valid_773755 = header.getOrDefault("x-amz-website-redirect-location")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "x-amz-website-redirect-location", valid_773755
  var valid_773756 = header.getOrDefault("x-amz-acl")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = newJString("private"))
  if valid_773756 != nil:
    section.add "x-amz-acl", valid_773756
  var valid_773757 = header.getOrDefault("x-amz-grant-read")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "x-amz-grant-read", valid_773757
  var valid_773758 = header.getOrDefault("x-amz-storage-class")
  valid_773758 = validateParameter(valid_773758, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_773758 != nil:
    section.add "x-amz-storage-class", valid_773758
  var valid_773759 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = newJString("ON"))
  if valid_773759 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_773759
  var valid_773760 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_773760
  var valid_773761 = header.getOrDefault("x-amz-tagging")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "x-amz-tagging", valid_773761
  var valid_773762 = header.getOrDefault("x-amz-grant-read-acp")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "x-amz-grant-read-acp", valid_773762
  var valid_773763 = header.getOrDefault("Content-Length")
  valid_773763 = validateParameter(valid_773763, JInt, required = false, default = nil)
  if valid_773763 != nil:
    section.add "Content-Length", valid_773763
  var valid_773764 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "x-amz-server-side-encryption-context", valid_773764
  var valid_773765 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_773765
  var valid_773766 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_773766
  var valid_773767 = header.getOrDefault("x-amz-grant-write-acp")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "x-amz-grant-write-acp", valid_773767
  var valid_773768 = header.getOrDefault("Content-Encoding")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "Content-Encoding", valid_773768
  var valid_773769 = header.getOrDefault("x-amz-request-payer")
  valid_773769 = validateParameter(valid_773769, JString, required = false,
                                 default = newJString("requester"))
  if valid_773769 != nil:
    section.add "x-amz-request-payer", valid_773769
  var valid_773770 = header.getOrDefault("x-amz-server-side-encryption")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = newJString("AES256"))
  if valid_773770 != nil:
    section.add "x-amz-server-side-encryption", valid_773770
  var valid_773771 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_773771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773773: Call_PutObject_773740; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an object to a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  let valid = call_773773.validator(path, query, header, formData, body)
  let scheme = call_773773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773773.url(scheme.get, call_773773.host, call_773773.base,
                         call_773773.route, valid.getOrDefault("path"))
  result = hook(call_773773, url, valid)

proc call*(call_773774: Call_PutObject_773740; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## putObject
  ## Adds an object to a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  ##   Key: string (required)
  ##      : Object key for which the PUT operation was initiated.
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the PUT operation was initiated.
  ##   body: JObject (required)
  var path_773775 = newJObject()
  var body_773776 = newJObject()
  add(path_773775, "Key", newJString(Key))
  add(path_773775, "Bucket", newJString(Bucket))
  if body != nil:
    body_773776 = body
  result = call_773774.call(path_773775, nil, nil, nil, body_773776)

var putObject* = Call_PutObject_773740(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_PutObject_773741,
                                    base: "/", url: url_PutObject_773742,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadObject_773791 = ref object of OpenApiRestCall_772597
proc url_HeadObject_773793(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_HeadObject_773792(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773794 = path.getOrDefault("Key")
  valid_773794 = validateParameter(valid_773794, JString, required = true,
                                 default = nil)
  if valid_773794 != nil:
    section.add "Key", valid_773794
  var valid_773795 = path.getOrDefault("Bucket")
  valid_773795 = validateParameter(valid_773795, JString, required = true,
                                 default = nil)
  if valid_773795 != nil:
    section.add "Bucket", valid_773795
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   partNumber: JInt
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
  section = newJObject()
  var valid_773796 = query.getOrDefault("versionId")
  valid_773796 = validateParameter(valid_773796, JString, required = false,
                                 default = nil)
  if valid_773796 != nil:
    section.add "versionId", valid_773796
  var valid_773797 = query.getOrDefault("partNumber")
  valid_773797 = validateParameter(valid_773797, JInt, required = false, default = nil)
  if valid_773797 != nil:
    section.add "partNumber", valid_773797
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
  var valid_773798 = header.getOrDefault("x-amz-security-token")
  valid_773798 = validateParameter(valid_773798, JString, required = false,
                                 default = nil)
  if valid_773798 != nil:
    section.add "x-amz-security-token", valid_773798
  var valid_773799 = header.getOrDefault("If-Match")
  valid_773799 = validateParameter(valid_773799, JString, required = false,
                                 default = nil)
  if valid_773799 != nil:
    section.add "If-Match", valid_773799
  var valid_773800 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_773800
  var valid_773801 = header.getOrDefault("If-Unmodified-Since")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "If-Unmodified-Since", valid_773801
  var valid_773802 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_773802
  var valid_773803 = header.getOrDefault("If-Modified-Since")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "If-Modified-Since", valid_773803
  var valid_773804 = header.getOrDefault("If-None-Match")
  valid_773804 = validateParameter(valid_773804, JString, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "If-None-Match", valid_773804
  var valid_773805 = header.getOrDefault("x-amz-request-payer")
  valid_773805 = validateParameter(valid_773805, JString, required = false,
                                 default = newJString("requester"))
  if valid_773805 != nil:
    section.add "x-amz-request-payer", valid_773805
  var valid_773806 = header.getOrDefault("Range")
  valid_773806 = validateParameter(valid_773806, JString, required = false,
                                 default = nil)
  if valid_773806 != nil:
    section.add "Range", valid_773806
  var valid_773807 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_773807 = validateParameter(valid_773807, JString, required = false,
                                 default = nil)
  if valid_773807 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_773807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773808: Call_HeadObject_773791; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  let valid = call_773808.validator(path, query, header, formData, body)
  let scheme = call_773808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773808.url(scheme.get, call_773808.host, call_773808.base,
                         call_773808.route, valid.getOrDefault("path"))
  result = hook(call_773808, url, valid)

proc call*(call_773809: Call_HeadObject_773791; Key: string; Bucket: string;
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
  var path_773810 = newJObject()
  var query_773811 = newJObject()
  add(query_773811, "versionId", newJString(versionId))
  add(query_773811, "partNumber", newJInt(partNumber))
  add(path_773810, "Key", newJString(Key))
  add(path_773810, "Bucket", newJString(Bucket))
  result = call_773809.call(path_773810, query_773811, nil, nil, nil)

var headObject* = Call_HeadObject_773791(name: "headObject",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}/{Key}",
                                      validator: validate_HeadObject_773792,
                                      base: "/", url: url_HeadObject_773793,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_773713 = ref object of OpenApiRestCall_772597
proc url_GetObject_773715(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetObject_773714(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773716 = path.getOrDefault("Key")
  valid_773716 = validateParameter(valid_773716, JString, required = true,
                                 default = nil)
  if valid_773716 != nil:
    section.add "Key", valid_773716
  var valid_773717 = path.getOrDefault("Bucket")
  valid_773717 = validateParameter(valid_773717, JString, required = true,
                                 default = nil)
  if valid_773717 != nil:
    section.add "Bucket", valid_773717
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
  var valid_773718 = query.getOrDefault("versionId")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "versionId", valid_773718
  var valid_773719 = query.getOrDefault("partNumber")
  valid_773719 = validateParameter(valid_773719, JInt, required = false, default = nil)
  if valid_773719 != nil:
    section.add "partNumber", valid_773719
  var valid_773720 = query.getOrDefault("response-expires")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "response-expires", valid_773720
  var valid_773721 = query.getOrDefault("response-content-language")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "response-content-language", valid_773721
  var valid_773722 = query.getOrDefault("response-content-encoding")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "response-content-encoding", valid_773722
  var valid_773723 = query.getOrDefault("response-cache-control")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "response-cache-control", valid_773723
  var valid_773724 = query.getOrDefault("response-content-disposition")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "response-content-disposition", valid_773724
  var valid_773725 = query.getOrDefault("response-content-type")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "response-content-type", valid_773725
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
  var valid_773726 = header.getOrDefault("x-amz-security-token")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "x-amz-security-token", valid_773726
  var valid_773727 = header.getOrDefault("If-Match")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "If-Match", valid_773727
  var valid_773728 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_773728
  var valid_773729 = header.getOrDefault("If-Unmodified-Since")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "If-Unmodified-Since", valid_773729
  var valid_773730 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_773730
  var valid_773731 = header.getOrDefault("If-Modified-Since")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "If-Modified-Since", valid_773731
  var valid_773732 = header.getOrDefault("If-None-Match")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "If-None-Match", valid_773732
  var valid_773733 = header.getOrDefault("x-amz-request-payer")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = newJString("requester"))
  if valid_773733 != nil:
    section.add "x-amz-request-payer", valid_773733
  var valid_773734 = header.getOrDefault("Range")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "Range", valid_773734
  var valid_773735 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_773735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773736: Call_GetObject_773713; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves objects from Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  let valid = call_773736.validator(path, query, header, formData, body)
  let scheme = call_773736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773736.url(scheme.get, call_773736.host, call_773736.base,
                         call_773736.route, valid.getOrDefault("path"))
  result = hook(call_773736, url, valid)

proc call*(call_773737: Call_GetObject_773713; Key: string; Bucket: string;
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
  var path_773738 = newJObject()
  var query_773739 = newJObject()
  add(query_773739, "versionId", newJString(versionId))
  add(query_773739, "partNumber", newJInt(partNumber))
  add(query_773739, "response-expires", newJString(responseExpires))
  add(query_773739, "response-content-language",
      newJString(responseContentLanguage))
  add(path_773738, "Key", newJString(Key))
  add(query_773739, "response-content-encoding",
      newJString(responseContentEncoding))
  add(query_773739, "response-cache-control", newJString(responseCacheControl))
  add(path_773738, "Bucket", newJString(Bucket))
  add(query_773739, "response-content-disposition",
      newJString(responseContentDisposition))
  add(query_773739, "response-content-type", newJString(responseContentType))
  result = call_773737.call(path_773738, query_773739, nil, nil, nil)

var getObject* = Call_GetObject_773713(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_GetObject_773714,
                                    base: "/", url: url_GetObject_773715,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_773777 = ref object of OpenApiRestCall_772597
proc url_DeleteObject_773779(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObject_773778(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773780 = path.getOrDefault("Key")
  valid_773780 = validateParameter(valid_773780, JString, required = true,
                                 default = nil)
  if valid_773780 != nil:
    section.add "Key", valid_773780
  var valid_773781 = path.getOrDefault("Bucket")
  valid_773781 = validateParameter(valid_773781, JString, required = true,
                                 default = nil)
  if valid_773781 != nil:
    section.add "Bucket", valid_773781
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  var valid_773782 = query.getOrDefault("versionId")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "versionId", valid_773782
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
  var valid_773783 = header.getOrDefault("x-amz-security-token")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "x-amz-security-token", valid_773783
  var valid_773784 = header.getOrDefault("x-amz-mfa")
  valid_773784 = validateParameter(valid_773784, JString, required = false,
                                 default = nil)
  if valid_773784 != nil:
    section.add "x-amz-mfa", valid_773784
  var valid_773785 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_773785 = validateParameter(valid_773785, JBool, required = false, default = nil)
  if valid_773785 != nil:
    section.add "x-amz-bypass-governance-retention", valid_773785
  var valid_773786 = header.getOrDefault("x-amz-request-payer")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = newJString("requester"))
  if valid_773786 != nil:
    section.add "x-amz-request-payer", valid_773786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773787: Call_DeleteObject_773777; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  let valid = call_773787.validator(path, query, header, formData, body)
  let scheme = call_773787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773787.url(scheme.get, call_773787.host, call_773787.base,
                         call_773787.route, valid.getOrDefault("path"))
  result = hook(call_773787, url, valid)

proc call*(call_773788: Call_DeleteObject_773777; Key: string; Bucket: string;
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
  var path_773789 = newJObject()
  var query_773790 = newJObject()
  add(query_773790, "versionId", newJString(versionId))
  add(path_773789, "Key", newJString(Key))
  add(path_773789, "Bucket", newJString(Bucket))
  result = call_773788.call(path_773789, query_773790, nil, nil, nil)

var deleteObject* = Call_DeleteObject_773777(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}/{Key}",
    validator: validate_DeleteObject_773778, base: "/", url: url_DeleteObject_773779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectTagging_773824 = ref object of OpenApiRestCall_772597
proc url_PutObjectTagging_773826(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectTagging_773825(path: JsonNode; query: JsonNode;
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
  var valid_773827 = path.getOrDefault("Key")
  valid_773827 = validateParameter(valid_773827, JString, required = true,
                                 default = nil)
  if valid_773827 != nil:
    section.add "Key", valid_773827
  var valid_773828 = path.getOrDefault("Bucket")
  valid_773828 = validateParameter(valid_773828, JString, required = true,
                                 default = nil)
  if valid_773828 != nil:
    section.add "Bucket", valid_773828
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_773829 = query.getOrDefault("versionId")
  valid_773829 = validateParameter(valid_773829, JString, required = false,
                                 default = nil)
  if valid_773829 != nil:
    section.add "versionId", valid_773829
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_773830 = query.getOrDefault("tagging")
  valid_773830 = validateParameter(valid_773830, JBool, required = true, default = nil)
  if valid_773830 != nil:
    section.add "tagging", valid_773830
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_773831 = header.getOrDefault("x-amz-security-token")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "x-amz-security-token", valid_773831
  var valid_773832 = header.getOrDefault("Content-MD5")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "Content-MD5", valid_773832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773834: Call_PutObjectTagging_773824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ## 
  let valid = call_773834.validator(path, query, header, formData, body)
  let scheme = call_773834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773834.url(scheme.get, call_773834.host, call_773834.base,
                         call_773834.route, valid.getOrDefault("path"))
  result = hook(call_773834, url, valid)

proc call*(call_773835: Call_PutObjectTagging_773824; tagging: bool; Key: string;
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
  var path_773836 = newJObject()
  var query_773837 = newJObject()
  var body_773838 = newJObject()
  add(query_773837, "versionId", newJString(versionId))
  add(query_773837, "tagging", newJBool(tagging))
  add(path_773836, "Key", newJString(Key))
  add(path_773836, "Bucket", newJString(Bucket))
  if body != nil:
    body_773838 = body
  result = call_773835.call(path_773836, query_773837, nil, nil, body_773838)

var putObjectTagging* = Call_PutObjectTagging_773824(name: "putObjectTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_PutObjectTagging_773825,
    base: "/", url: url_PutObjectTagging_773826,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTagging_773812 = ref object of OpenApiRestCall_772597
proc url_GetObjectTagging_773814(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectTagging_773813(path: JsonNode; query: JsonNode;
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
  var valid_773815 = path.getOrDefault("Key")
  valid_773815 = validateParameter(valid_773815, JString, required = true,
                                 default = nil)
  if valid_773815 != nil:
    section.add "Key", valid_773815
  var valid_773816 = path.getOrDefault("Bucket")
  valid_773816 = validateParameter(valid_773816, JString, required = true,
                                 default = nil)
  if valid_773816 != nil:
    section.add "Bucket", valid_773816
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_773817 = query.getOrDefault("versionId")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "versionId", valid_773817
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_773818 = query.getOrDefault("tagging")
  valid_773818 = validateParameter(valid_773818, JBool, required = true, default = nil)
  if valid_773818 != nil:
    section.add "tagging", valid_773818
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773819 = header.getOrDefault("x-amz-security-token")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "x-amz-security-token", valid_773819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773820: Call_GetObjectTagging_773812; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag-set of an object.
  ## 
  let valid = call_773820.validator(path, query, header, formData, body)
  let scheme = call_773820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773820.url(scheme.get, call_773820.host, call_773820.base,
                         call_773820.route, valid.getOrDefault("path"))
  result = hook(call_773820, url, valid)

proc call*(call_773821: Call_GetObjectTagging_773812; tagging: bool; Key: string;
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
  var path_773822 = newJObject()
  var query_773823 = newJObject()
  add(query_773823, "versionId", newJString(versionId))
  add(query_773823, "tagging", newJBool(tagging))
  add(path_773822, "Key", newJString(Key))
  add(path_773822, "Bucket", newJString(Bucket))
  result = call_773821.call(path_773822, query_773823, nil, nil, nil)

var getObjectTagging* = Call_GetObjectTagging_773812(name: "getObjectTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_GetObjectTagging_773813,
    base: "/", url: url_GetObjectTagging_773814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjectTagging_773839 = ref object of OpenApiRestCall_772597
proc url_DeleteObjectTagging_773841(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObjectTagging_773840(path: JsonNode; query: JsonNode;
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
  var valid_773842 = path.getOrDefault("Key")
  valid_773842 = validateParameter(valid_773842, JString, required = true,
                                 default = nil)
  if valid_773842 != nil:
    section.add "Key", valid_773842
  var valid_773843 = path.getOrDefault("Bucket")
  valid_773843 = validateParameter(valid_773843, JString, required = true,
                                 default = nil)
  if valid_773843 != nil:
    section.add "Bucket", valid_773843
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The versionId of the object that the tag-set will be removed from.
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_773844 = query.getOrDefault("versionId")
  valid_773844 = validateParameter(valid_773844, JString, required = false,
                                 default = nil)
  if valid_773844 != nil:
    section.add "versionId", valid_773844
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_773845 = query.getOrDefault("tagging")
  valid_773845 = validateParameter(valid_773845, JBool, required = true, default = nil)
  if valid_773845 != nil:
    section.add "tagging", valid_773845
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773846 = header.getOrDefault("x-amz-security-token")
  valid_773846 = validateParameter(valid_773846, JString, required = false,
                                 default = nil)
  if valid_773846 != nil:
    section.add "x-amz-security-token", valid_773846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773847: Call_DeleteObjectTagging_773839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the tag-set from an existing object.
  ## 
  let valid = call_773847.validator(path, query, header, formData, body)
  let scheme = call_773847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773847.url(scheme.get, call_773847.host, call_773847.base,
                         call_773847.route, valid.getOrDefault("path"))
  result = hook(call_773847, url, valid)

proc call*(call_773848: Call_DeleteObjectTagging_773839; tagging: bool; Key: string;
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
  var path_773849 = newJObject()
  var query_773850 = newJObject()
  add(query_773850, "versionId", newJString(versionId))
  add(query_773850, "tagging", newJBool(tagging))
  add(path_773849, "Key", newJString(Key))
  add(path_773849, "Bucket", newJString(Bucket))
  result = call_773848.call(path_773849, query_773850, nil, nil, nil)

var deleteObjectTagging* = Call_DeleteObjectTagging_773839(
    name: "deleteObjectTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#tagging",
    validator: validate_DeleteObjectTagging_773840, base: "/",
    url: url_DeleteObjectTagging_773841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjects_773851 = ref object of OpenApiRestCall_772597
proc url_DeleteObjects_773853(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObjects_773852(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773854 = path.getOrDefault("Bucket")
  valid_773854 = validateParameter(valid_773854, JString, required = true,
                                 default = nil)
  if valid_773854 != nil:
    section.add "Bucket", valid_773854
  result.add "path", section
  ## parameters in `query` object:
  ##   delete: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `delete` field"
  var valid_773855 = query.getOrDefault("delete")
  valid_773855 = validateParameter(valid_773855, JBool, required = true, default = nil)
  if valid_773855 != nil:
    section.add "delete", valid_773855
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
  var valid_773856 = header.getOrDefault("x-amz-security-token")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "x-amz-security-token", valid_773856
  var valid_773857 = header.getOrDefault("x-amz-mfa")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "x-amz-mfa", valid_773857
  var valid_773858 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_773858 = validateParameter(valid_773858, JBool, required = false, default = nil)
  if valid_773858 != nil:
    section.add "x-amz-bypass-governance-retention", valid_773858
  var valid_773859 = header.getOrDefault("x-amz-request-payer")
  valid_773859 = validateParameter(valid_773859, JString, required = false,
                                 default = newJString("requester"))
  if valid_773859 != nil:
    section.add "x-amz-request-payer", valid_773859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773861: Call_DeleteObjects_773851; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  let valid = call_773861.validator(path, query, header, formData, body)
  let scheme = call_773861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773861.url(scheme.get, call_773861.host, call_773861.base,
                         call_773861.route, valid.getOrDefault("path"))
  result = hook(call_773861, url, valid)

proc call*(call_773862: Call_DeleteObjects_773851; Bucket: string; body: JsonNode;
          delete: bool): Recallable =
  ## deleteObjects
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   delete: bool (required)
  var path_773863 = newJObject()
  var query_773864 = newJObject()
  var body_773865 = newJObject()
  add(path_773863, "Bucket", newJString(Bucket))
  if body != nil:
    body_773865 = body
  add(query_773864, "delete", newJBool(delete))
  result = call_773862.call(path_773863, query_773864, nil, nil, body_773865)

var deleteObjects* = Call_DeleteObjects_773851(name: "deleteObjects",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com", route: "/{Bucket}#delete",
    validator: validate_DeleteObjects_773852, base: "/", url: url_DeleteObjects_773853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_773876 = ref object of OpenApiRestCall_772597
proc url_PutPublicAccessBlock_773878(protocol: Scheme; host: string; base: string;
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

proc validate_PutPublicAccessBlock_773877(path: JsonNode; query: JsonNode;
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
  var valid_773879 = path.getOrDefault("Bucket")
  valid_773879 = validateParameter(valid_773879, JString, required = true,
                                 default = nil)
  if valid_773879 != nil:
    section.add "Bucket", valid_773879
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_773880 = query.getOrDefault("publicAccessBlock")
  valid_773880 = validateParameter(valid_773880, JBool, required = true, default = nil)
  if valid_773880 != nil:
    section.add "publicAccessBlock", valid_773880
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash of the <code>PutPublicAccessBlock</code> request body. 
  section = newJObject()
  var valid_773881 = header.getOrDefault("x-amz-security-token")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "x-amz-security-token", valid_773881
  var valid_773882 = header.getOrDefault("Content-MD5")
  valid_773882 = validateParameter(valid_773882, JString, required = false,
                                 default = nil)
  if valid_773882 != nil:
    section.add "Content-MD5", valid_773882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773884: Call_PutPublicAccessBlock_773876; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_773884.validator(path, query, header, formData, body)
  let scheme = call_773884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773884.url(scheme.get, call_773884.host, call_773884.base,
                         call_773884.route, valid.getOrDefault("path"))
  result = hook(call_773884, url, valid)

proc call*(call_773885: Call_PutPublicAccessBlock_773876; publicAccessBlock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to set.
  ##   body: JObject (required)
  var path_773886 = newJObject()
  var query_773887 = newJObject()
  var body_773888 = newJObject()
  add(query_773887, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_773886, "Bucket", newJString(Bucket))
  if body != nil:
    body_773888 = body
  result = call_773885.call(path_773886, query_773887, nil, nil, body_773888)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_773876(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_PutPublicAccessBlock_773877, base: "/",
    url: url_PutPublicAccessBlock_773878, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_773866 = ref object of OpenApiRestCall_772597
proc url_GetPublicAccessBlock_773868(protocol: Scheme; host: string; base: string;
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

proc validate_GetPublicAccessBlock_773867(path: JsonNode; query: JsonNode;
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
  var valid_773869 = path.getOrDefault("Bucket")
  valid_773869 = validateParameter(valid_773869, JString, required = true,
                                 default = nil)
  if valid_773869 != nil:
    section.add "Bucket", valid_773869
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_773870 = query.getOrDefault("publicAccessBlock")
  valid_773870 = validateParameter(valid_773870, JBool, required = true, default = nil)
  if valid_773870 != nil:
    section.add "publicAccessBlock", valid_773870
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773871 = header.getOrDefault("x-amz-security-token")
  valid_773871 = validateParameter(valid_773871, JString, required = false,
                                 default = nil)
  if valid_773871 != nil:
    section.add "x-amz-security-token", valid_773871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773872: Call_GetPublicAccessBlock_773866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_773872.validator(path, query, header, formData, body)
  let scheme = call_773872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773872.url(scheme.get, call_773872.host, call_773872.base,
                         call_773872.route, valid.getOrDefault("path"))
  result = hook(call_773872, url, valid)

proc call*(call_773873: Call_GetPublicAccessBlock_773866; publicAccessBlock: bool;
          Bucket: string): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to retrieve. 
  var path_773874 = newJObject()
  var query_773875 = newJObject()
  add(query_773875, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_773874, "Bucket", newJString(Bucket))
  result = call_773873.call(path_773874, query_773875, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_773866(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_GetPublicAccessBlock_773867, base: "/",
    url: url_GetPublicAccessBlock_773868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_773889 = ref object of OpenApiRestCall_772597
proc url_DeletePublicAccessBlock_773891(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePublicAccessBlock_773890(path: JsonNode; query: JsonNode;
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
  var valid_773892 = path.getOrDefault("Bucket")
  valid_773892 = validateParameter(valid_773892, JString, required = true,
                                 default = nil)
  if valid_773892 != nil:
    section.add "Bucket", valid_773892
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_773893 = query.getOrDefault("publicAccessBlock")
  valid_773893 = validateParameter(valid_773893, JBool, required = true, default = nil)
  if valid_773893 != nil:
    section.add "publicAccessBlock", valid_773893
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773894 = header.getOrDefault("x-amz-security-token")
  valid_773894 = validateParameter(valid_773894, JString, required = false,
                                 default = nil)
  if valid_773894 != nil:
    section.add "x-amz-security-token", valid_773894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773895: Call_DeletePublicAccessBlock_773889; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ## 
  let valid = call_773895.validator(path, query, header, formData, body)
  let scheme = call_773895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773895.url(scheme.get, call_773895.host, call_773895.base,
                         call_773895.route, valid.getOrDefault("path"))
  result = hook(call_773895, url, valid)

proc call*(call_773896: Call_DeletePublicAccessBlock_773889;
          publicAccessBlock: bool; Bucket: string): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to delete. 
  var path_773897 = newJObject()
  var query_773898 = newJObject()
  add(query_773898, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_773897, "Bucket", newJString(Bucket))
  result = call_773896.call(path_773897, query_773898, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_773889(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_DeletePublicAccessBlock_773890, base: "/",
    url: url_DeletePublicAccessBlock_773891, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAccelerateConfiguration_773909 = ref object of OpenApiRestCall_772597
proc url_PutBucketAccelerateConfiguration_773911(protocol: Scheme; host: string;
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

proc validate_PutBucketAccelerateConfiguration_773910(path: JsonNode;
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
  var valid_773912 = path.getOrDefault("Bucket")
  valid_773912 = validateParameter(valid_773912, JString, required = true,
                                 default = nil)
  if valid_773912 != nil:
    section.add "Bucket", valid_773912
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_773913 = query.getOrDefault("accelerate")
  valid_773913 = validateParameter(valid_773913, JBool, required = true, default = nil)
  if valid_773913 != nil:
    section.add "accelerate", valid_773913
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773914 = header.getOrDefault("x-amz-security-token")
  valid_773914 = validateParameter(valid_773914, JString, required = false,
                                 default = nil)
  if valid_773914 != nil:
    section.add "x-amz-security-token", valid_773914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773916: Call_PutBucketAccelerateConfiguration_773909;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the accelerate configuration of an existing bucket.
  ## 
  let valid = call_773916.validator(path, query, header, formData, body)
  let scheme = call_773916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773916.url(scheme.get, call_773916.host, call_773916.base,
                         call_773916.route, valid.getOrDefault("path"))
  result = hook(call_773916, url, valid)

proc call*(call_773917: Call_PutBucketAccelerateConfiguration_773909;
          accelerate: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAccelerateConfiguration
  ## Sets the accelerate configuration of an existing bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is set.
  ##   body: JObject (required)
  var path_773918 = newJObject()
  var query_773919 = newJObject()
  var body_773920 = newJObject()
  add(query_773919, "accelerate", newJBool(accelerate))
  add(path_773918, "Bucket", newJString(Bucket))
  if body != nil:
    body_773920 = body
  result = call_773917.call(path_773918, query_773919, nil, nil, body_773920)

var putBucketAccelerateConfiguration* = Call_PutBucketAccelerateConfiguration_773909(
    name: "putBucketAccelerateConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_PutBucketAccelerateConfiguration_773910, base: "/",
    url: url_PutBucketAccelerateConfiguration_773911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAccelerateConfiguration_773899 = ref object of OpenApiRestCall_772597
proc url_GetBucketAccelerateConfiguration_773901(protocol: Scheme; host: string;
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

proc validate_GetBucketAccelerateConfiguration_773900(path: JsonNode;
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
  var valid_773902 = path.getOrDefault("Bucket")
  valid_773902 = validateParameter(valid_773902, JString, required = true,
                                 default = nil)
  if valid_773902 != nil:
    section.add "Bucket", valid_773902
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_773903 = query.getOrDefault("accelerate")
  valid_773903 = validateParameter(valid_773903, JBool, required = true, default = nil)
  if valid_773903 != nil:
    section.add "accelerate", valid_773903
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773904 = header.getOrDefault("x-amz-security-token")
  valid_773904 = validateParameter(valid_773904, JString, required = false,
                                 default = nil)
  if valid_773904 != nil:
    section.add "x-amz-security-token", valid_773904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773905: Call_GetBucketAccelerateConfiguration_773899;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the accelerate configuration of a bucket.
  ## 
  let valid = call_773905.validator(path, query, header, formData, body)
  let scheme = call_773905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773905.url(scheme.get, call_773905.host, call_773905.base,
                         call_773905.route, valid.getOrDefault("path"))
  result = hook(call_773905, url, valid)

proc call*(call_773906: Call_GetBucketAccelerateConfiguration_773899;
          accelerate: bool; Bucket: string): Recallable =
  ## getBucketAccelerateConfiguration
  ## Returns the accelerate configuration of a bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is retrieved.
  var path_773907 = newJObject()
  var query_773908 = newJObject()
  add(query_773908, "accelerate", newJBool(accelerate))
  add(path_773907, "Bucket", newJString(Bucket))
  result = call_773906.call(path_773907, query_773908, nil, nil, nil)

var getBucketAccelerateConfiguration* = Call_GetBucketAccelerateConfiguration_773899(
    name: "getBucketAccelerateConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_GetBucketAccelerateConfiguration_773900, base: "/",
    url: url_GetBucketAccelerateConfiguration_773901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAcl_773931 = ref object of OpenApiRestCall_772597
proc url_PutBucketAcl_773933(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketAcl_773932(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773934 = path.getOrDefault("Bucket")
  valid_773934 = validateParameter(valid_773934, JString, required = true,
                                 default = nil)
  if valid_773934 != nil:
    section.add "Bucket", valid_773934
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_773935 = query.getOrDefault("acl")
  valid_773935 = validateParameter(valid_773935, JBool, required = true, default = nil)
  if valid_773935 != nil:
    section.add "acl", valid_773935
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
  var valid_773936 = header.getOrDefault("x-amz-security-token")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "x-amz-security-token", valid_773936
  var valid_773937 = header.getOrDefault("Content-MD5")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "Content-MD5", valid_773937
  var valid_773938 = header.getOrDefault("x-amz-acl")
  valid_773938 = validateParameter(valid_773938, JString, required = false,
                                 default = newJString("private"))
  if valid_773938 != nil:
    section.add "x-amz-acl", valid_773938
  var valid_773939 = header.getOrDefault("x-amz-grant-read")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "x-amz-grant-read", valid_773939
  var valid_773940 = header.getOrDefault("x-amz-grant-read-acp")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "x-amz-grant-read-acp", valid_773940
  var valid_773941 = header.getOrDefault("x-amz-grant-write")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "x-amz-grant-write", valid_773941
  var valid_773942 = header.getOrDefault("x-amz-grant-write-acp")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "x-amz-grant-write-acp", valid_773942
  var valid_773943 = header.getOrDefault("x-amz-grant-full-control")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "x-amz-grant-full-control", valid_773943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773945: Call_PutBucketAcl_773931; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  let valid = call_773945.validator(path, query, header, formData, body)
  let scheme = call_773945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773945.url(scheme.get, call_773945.host, call_773945.base,
                         call_773945.route, valid.getOrDefault("path"))
  result = hook(call_773945, url, valid)

proc call*(call_773946: Call_PutBucketAcl_773931; acl: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketAcl
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_773947 = newJObject()
  var query_773948 = newJObject()
  var body_773949 = newJObject()
  add(query_773948, "acl", newJBool(acl))
  add(path_773947, "Bucket", newJString(Bucket))
  if body != nil:
    body_773949 = body
  result = call_773946.call(path_773947, query_773948, nil, nil, body_773949)

var putBucketAcl* = Call_PutBucketAcl_773931(name: "putBucketAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_PutBucketAcl_773932, base: "/", url: url_PutBucketAcl_773933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAcl_773921 = ref object of OpenApiRestCall_772597
proc url_GetBucketAcl_773923(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketAcl_773922(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773924 = path.getOrDefault("Bucket")
  valid_773924 = validateParameter(valid_773924, JString, required = true,
                                 default = nil)
  if valid_773924 != nil:
    section.add "Bucket", valid_773924
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_773925 = query.getOrDefault("acl")
  valid_773925 = validateParameter(valid_773925, JBool, required = true, default = nil)
  if valid_773925 != nil:
    section.add "acl", valid_773925
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773926 = header.getOrDefault("x-amz-security-token")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "x-amz-security-token", valid_773926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773927: Call_GetBucketAcl_773921; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the access control policy for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  let valid = call_773927.validator(path, query, header, formData, body)
  let scheme = call_773927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773927.url(scheme.get, call_773927.host, call_773927.base,
                         call_773927.route, valid.getOrDefault("path"))
  result = hook(call_773927, url, valid)

proc call*(call_773928: Call_GetBucketAcl_773921; acl: bool; Bucket: string): Recallable =
  ## getBucketAcl
  ## Gets the access control policy for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773929 = newJObject()
  var query_773930 = newJObject()
  add(query_773930, "acl", newJBool(acl))
  add(path_773929, "Bucket", newJString(Bucket))
  result = call_773928.call(path_773929, query_773930, nil, nil, nil)

var getBucketAcl* = Call_GetBucketAcl_773921(name: "getBucketAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_GetBucketAcl_773922, base: "/", url: url_GetBucketAcl_773923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycle_773960 = ref object of OpenApiRestCall_772597
proc url_PutBucketLifecycle_773962(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketLifecycle_773961(path: JsonNode; query: JsonNode;
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
  var valid_773963 = path.getOrDefault("Bucket")
  valid_773963 = validateParameter(valid_773963, JString, required = true,
                                 default = nil)
  if valid_773963 != nil:
    section.add "Bucket", valid_773963
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_773964 = query.getOrDefault("lifecycle")
  valid_773964 = validateParameter(valid_773964, JBool, required = true, default = nil)
  if valid_773964 != nil:
    section.add "lifecycle", valid_773964
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_773965 = header.getOrDefault("x-amz-security-token")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "x-amz-security-token", valid_773965
  var valid_773966 = header.getOrDefault("Content-MD5")
  valid_773966 = validateParameter(valid_773966, JString, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "Content-MD5", valid_773966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773968: Call_PutBucketLifecycle_773960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  let valid = call_773968.validator(path, query, header, formData, body)
  let scheme = call_773968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773968.url(scheme.get, call_773968.host, call_773968.base,
                         call_773968.route, valid.getOrDefault("path"))
  result = hook(call_773968, url, valid)

proc call*(call_773969: Call_PutBucketLifecycle_773960; Bucket: string;
          lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycle
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_773970 = newJObject()
  var query_773971 = newJObject()
  var body_773972 = newJObject()
  add(path_773970, "Bucket", newJString(Bucket))
  add(query_773971, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_773972 = body
  result = call_773969.call(path_773970, query_773971, nil, nil, body_773972)

var putBucketLifecycle* = Call_PutBucketLifecycle_773960(
    name: "putBucketLifecycle", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_PutBucketLifecycle_773961, base: "/",
    url: url_PutBucketLifecycle_773962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycle_773950 = ref object of OpenApiRestCall_772597
proc url_GetBucketLifecycle_773952(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLifecycle_773951(path: JsonNode; query: JsonNode;
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
  var valid_773953 = path.getOrDefault("Bucket")
  valid_773953 = validateParameter(valid_773953, JString, required = true,
                                 default = nil)
  if valid_773953 != nil:
    section.add "Bucket", valid_773953
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_773954 = query.getOrDefault("lifecycle")
  valid_773954 = validateParameter(valid_773954, JBool, required = true, default = nil)
  if valid_773954 != nil:
    section.add "lifecycle", valid_773954
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773955 = header.getOrDefault("x-amz-security-token")
  valid_773955 = validateParameter(valid_773955, JString, required = false,
                                 default = nil)
  if valid_773955 != nil:
    section.add "x-amz-security-token", valid_773955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773956: Call_GetBucketLifecycle_773950; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  let valid = call_773956.validator(path, query, header, formData, body)
  let scheme = call_773956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773956.url(scheme.get, call_773956.host, call_773956.base,
                         call_773956.route, valid.getOrDefault("path"))
  result = hook(call_773956, url, valid)

proc call*(call_773957: Call_GetBucketLifecycle_773950; Bucket: string;
          lifecycle: bool): Recallable =
  ## getBucketLifecycle
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_773958 = newJObject()
  var query_773959 = newJObject()
  add(path_773958, "Bucket", newJString(Bucket))
  add(query_773959, "lifecycle", newJBool(lifecycle))
  result = call_773957.call(path_773958, query_773959, nil, nil, nil)

var getBucketLifecycle* = Call_GetBucketLifecycle_773950(
    name: "getBucketLifecycle", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_GetBucketLifecycle_773951, base: "/",
    url: url_GetBucketLifecycle_773952, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLocation_773973 = ref object of OpenApiRestCall_772597
proc url_GetBucketLocation_773975(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLocation_773974(path: JsonNode; query: JsonNode;
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
  var valid_773976 = path.getOrDefault("Bucket")
  valid_773976 = validateParameter(valid_773976, JString, required = true,
                                 default = nil)
  if valid_773976 != nil:
    section.add "Bucket", valid_773976
  result.add "path", section
  ## parameters in `query` object:
  ##   location: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `location` field"
  var valid_773977 = query.getOrDefault("location")
  valid_773977 = validateParameter(valid_773977, JBool, required = true, default = nil)
  if valid_773977 != nil:
    section.add "location", valid_773977
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773978 = header.getOrDefault("x-amz-security-token")
  valid_773978 = validateParameter(valid_773978, JString, required = false,
                                 default = nil)
  if valid_773978 != nil:
    section.add "x-amz-security-token", valid_773978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773979: Call_GetBucketLocation_773973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the region the bucket resides in.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  let valid = call_773979.validator(path, query, header, formData, body)
  let scheme = call_773979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773979.url(scheme.get, call_773979.host, call_773979.base,
                         call_773979.route, valid.getOrDefault("path"))
  result = hook(call_773979, url, valid)

proc call*(call_773980: Call_GetBucketLocation_773973; location: bool; Bucket: string): Recallable =
  ## getBucketLocation
  ## Returns the region the bucket resides in.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  ##   location: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773981 = newJObject()
  var query_773982 = newJObject()
  add(query_773982, "location", newJBool(location))
  add(path_773981, "Bucket", newJString(Bucket))
  result = call_773980.call(path_773981, query_773982, nil, nil, nil)

var getBucketLocation* = Call_GetBucketLocation_773973(name: "getBucketLocation",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#location",
    validator: validate_GetBucketLocation_773974, base: "/",
    url: url_GetBucketLocation_773975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLogging_773993 = ref object of OpenApiRestCall_772597
proc url_PutBucketLogging_773995(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketLogging_773994(path: JsonNode; query: JsonNode;
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
  var valid_773996 = path.getOrDefault("Bucket")
  valid_773996 = validateParameter(valid_773996, JString, required = true,
                                 default = nil)
  if valid_773996 != nil:
    section.add "Bucket", valid_773996
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_773997 = query.getOrDefault("logging")
  valid_773997 = validateParameter(valid_773997, JBool, required = true, default = nil)
  if valid_773997 != nil:
    section.add "logging", valid_773997
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_773998 = header.getOrDefault("x-amz-security-token")
  valid_773998 = validateParameter(valid_773998, JString, required = false,
                                 default = nil)
  if valid_773998 != nil:
    section.add "x-amz-security-token", valid_773998
  var valid_773999 = header.getOrDefault("Content-MD5")
  valid_773999 = validateParameter(valid_773999, JString, required = false,
                                 default = nil)
  if valid_773999 != nil:
    section.add "Content-MD5", valid_773999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774001: Call_PutBucketLogging_773993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  let valid = call_774001.validator(path, query, header, formData, body)
  let scheme = call_774001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774001.url(scheme.get, call_774001.host, call_774001.base,
                         call_774001.route, valid.getOrDefault("path"))
  result = hook(call_774001, url, valid)

proc call*(call_774002: Call_PutBucketLogging_773993; logging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketLogging
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_774003 = newJObject()
  var query_774004 = newJObject()
  var body_774005 = newJObject()
  add(query_774004, "logging", newJBool(logging))
  add(path_774003, "Bucket", newJString(Bucket))
  if body != nil:
    body_774005 = body
  result = call_774002.call(path_774003, query_774004, nil, nil, body_774005)

var putBucketLogging* = Call_PutBucketLogging_773993(name: "putBucketLogging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_PutBucketLogging_773994, base: "/",
    url: url_PutBucketLogging_773995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLogging_773983 = ref object of OpenApiRestCall_772597
proc url_GetBucketLogging_773985(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLogging_773984(path: JsonNode; query: JsonNode;
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
  var valid_773986 = path.getOrDefault("Bucket")
  valid_773986 = validateParameter(valid_773986, JString, required = true,
                                 default = nil)
  if valid_773986 != nil:
    section.add "Bucket", valid_773986
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_773987 = query.getOrDefault("logging")
  valid_773987 = validateParameter(valid_773987, JBool, required = true, default = nil)
  if valid_773987 != nil:
    section.add "logging", valid_773987
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_773988 = header.getOrDefault("x-amz-security-token")
  valid_773988 = validateParameter(valid_773988, JString, required = false,
                                 default = nil)
  if valid_773988 != nil:
    section.add "x-amz-security-token", valid_773988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773989: Call_GetBucketLogging_773983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  let valid = call_773989.validator(path, query, header, formData, body)
  let scheme = call_773989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773989.url(scheme.get, call_773989.host, call_773989.base,
                         call_773989.route, valid.getOrDefault("path"))
  result = hook(call_773989, url, valid)

proc call*(call_773990: Call_GetBucketLogging_773983; logging: bool; Bucket: string): Recallable =
  ## getBucketLogging
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_773991 = newJObject()
  var query_773992 = newJObject()
  add(query_773992, "logging", newJBool(logging))
  add(path_773991, "Bucket", newJString(Bucket))
  result = call_773990.call(path_773991, query_773992, nil, nil, nil)

var getBucketLogging* = Call_GetBucketLogging_773983(name: "getBucketLogging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_GetBucketLogging_773984, base: "/",
    url: url_GetBucketLogging_773985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotificationConfiguration_774016 = ref object of OpenApiRestCall_772597
proc url_PutBucketNotificationConfiguration_774018(protocol: Scheme; host: string;
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

proc validate_PutBucketNotificationConfiguration_774017(path: JsonNode;
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
  var valid_774019 = path.getOrDefault("Bucket")
  valid_774019 = validateParameter(valid_774019, JString, required = true,
                                 default = nil)
  if valid_774019 != nil:
    section.add "Bucket", valid_774019
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_774020 = query.getOrDefault("notification")
  valid_774020 = validateParameter(valid_774020, JBool, required = true, default = nil)
  if valid_774020 != nil:
    section.add "notification", valid_774020
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774021 = header.getOrDefault("x-amz-security-token")
  valid_774021 = validateParameter(valid_774021, JString, required = false,
                                 default = nil)
  if valid_774021 != nil:
    section.add "x-amz-security-token", valid_774021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774023: Call_PutBucketNotificationConfiguration_774016;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enables notifications of specified events for a bucket.
  ## 
  let valid = call_774023.validator(path, query, header, formData, body)
  let scheme = call_774023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774023.url(scheme.get, call_774023.host, call_774023.base,
                         call_774023.route, valid.getOrDefault("path"))
  result = hook(call_774023, url, valid)

proc call*(call_774024: Call_PutBucketNotificationConfiguration_774016;
          notification: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotificationConfiguration
  ## Enables notifications of specified events for a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_774025 = newJObject()
  var query_774026 = newJObject()
  var body_774027 = newJObject()
  add(query_774026, "notification", newJBool(notification))
  add(path_774025, "Bucket", newJString(Bucket))
  if body != nil:
    body_774027 = body
  result = call_774024.call(path_774025, query_774026, nil, nil, body_774027)

var putBucketNotificationConfiguration* = Call_PutBucketNotificationConfiguration_774016(
    name: "putBucketNotificationConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_PutBucketNotificationConfiguration_774017, base: "/",
    url: url_PutBucketNotificationConfiguration_774018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotificationConfiguration_774006 = ref object of OpenApiRestCall_772597
proc url_GetBucketNotificationConfiguration_774008(protocol: Scheme; host: string;
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

proc validate_GetBucketNotificationConfiguration_774007(path: JsonNode;
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
  var valid_774009 = path.getOrDefault("Bucket")
  valid_774009 = validateParameter(valid_774009, JString, required = true,
                                 default = nil)
  if valid_774009 != nil:
    section.add "Bucket", valid_774009
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_774010 = query.getOrDefault("notification")
  valid_774010 = validateParameter(valid_774010, JBool, required = true, default = nil)
  if valid_774010 != nil:
    section.add "notification", valid_774010
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774011 = header.getOrDefault("x-amz-security-token")
  valid_774011 = validateParameter(valid_774011, JString, required = false,
                                 default = nil)
  if valid_774011 != nil:
    section.add "x-amz-security-token", valid_774011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774012: Call_GetBucketNotificationConfiguration_774006;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the notification configuration of a bucket.
  ## 
  let valid = call_774012.validator(path, query, header, formData, body)
  let scheme = call_774012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774012.url(scheme.get, call_774012.host, call_774012.base,
                         call_774012.route, valid.getOrDefault("path"))
  result = hook(call_774012, url, valid)

proc call*(call_774013: Call_GetBucketNotificationConfiguration_774006;
          notification: bool; Bucket: string): Recallable =
  ## getBucketNotificationConfiguration
  ## Returns the notification configuration of a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_774014 = newJObject()
  var query_774015 = newJObject()
  add(query_774015, "notification", newJBool(notification))
  add(path_774014, "Bucket", newJString(Bucket))
  result = call_774013.call(path_774014, query_774015, nil, nil, nil)

var getBucketNotificationConfiguration* = Call_GetBucketNotificationConfiguration_774006(
    name: "getBucketNotificationConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_GetBucketNotificationConfiguration_774007, base: "/",
    url: url_GetBucketNotificationConfiguration_774008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotification_774038 = ref object of OpenApiRestCall_772597
proc url_PutBucketNotification_774040(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketNotification_774039(path: JsonNode; query: JsonNode;
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
  var valid_774041 = path.getOrDefault("Bucket")
  valid_774041 = validateParameter(valid_774041, JString, required = true,
                                 default = nil)
  if valid_774041 != nil:
    section.add "Bucket", valid_774041
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_774042 = query.getOrDefault("notification")
  valid_774042 = validateParameter(valid_774042, JBool, required = true, default = nil)
  if valid_774042 != nil:
    section.add "notification", valid_774042
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_774043 = header.getOrDefault("x-amz-security-token")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "x-amz-security-token", valid_774043
  var valid_774044 = header.getOrDefault("Content-MD5")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "Content-MD5", valid_774044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774046: Call_PutBucketNotification_774038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  let valid = call_774046.validator(path, query, header, formData, body)
  let scheme = call_774046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774046.url(scheme.get, call_774046.host, call_774046.base,
                         call_774046.route, valid.getOrDefault("path"))
  result = hook(call_774046, url, valid)

proc call*(call_774047: Call_PutBucketNotification_774038; notification: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotification
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_774048 = newJObject()
  var query_774049 = newJObject()
  var body_774050 = newJObject()
  add(query_774049, "notification", newJBool(notification))
  add(path_774048, "Bucket", newJString(Bucket))
  if body != nil:
    body_774050 = body
  result = call_774047.call(path_774048, query_774049, nil, nil, body_774050)

var putBucketNotification* = Call_PutBucketNotification_774038(
    name: "putBucketNotification", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_PutBucketNotification_774039, base: "/",
    url: url_PutBucketNotification_774040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotification_774028 = ref object of OpenApiRestCall_772597
proc url_GetBucketNotification_774030(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketNotification_774029(path: JsonNode; query: JsonNode;
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
  var valid_774031 = path.getOrDefault("Bucket")
  valid_774031 = validateParameter(valid_774031, JString, required = true,
                                 default = nil)
  if valid_774031 != nil:
    section.add "Bucket", valid_774031
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_774032 = query.getOrDefault("notification")
  valid_774032 = validateParameter(valid_774032, JBool, required = true, default = nil)
  if valid_774032 != nil:
    section.add "notification", valid_774032
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774033 = header.getOrDefault("x-amz-security-token")
  valid_774033 = validateParameter(valid_774033, JString, required = false,
                                 default = nil)
  if valid_774033 != nil:
    section.add "x-amz-security-token", valid_774033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774034: Call_GetBucketNotification_774028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  let valid = call_774034.validator(path, query, header, formData, body)
  let scheme = call_774034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774034.url(scheme.get, call_774034.host, call_774034.base,
                         call_774034.route, valid.getOrDefault("path"))
  result = hook(call_774034, url, valid)

proc call*(call_774035: Call_GetBucketNotification_774028; notification: bool;
          Bucket: string): Recallable =
  ## getBucketNotification
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_774036 = newJObject()
  var query_774037 = newJObject()
  add(query_774037, "notification", newJBool(notification))
  add(path_774036, "Bucket", newJString(Bucket))
  result = call_774035.call(path_774036, query_774037, nil, nil, nil)

var getBucketNotification* = Call_GetBucketNotification_774028(
    name: "getBucketNotification", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_GetBucketNotification_774029, base: "/",
    url: url_GetBucketNotification_774030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicyStatus_774051 = ref object of OpenApiRestCall_772597
proc url_GetBucketPolicyStatus_774053(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketPolicyStatus_774052(path: JsonNode; query: JsonNode;
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
  var valid_774054 = path.getOrDefault("Bucket")
  valid_774054 = validateParameter(valid_774054, JString, required = true,
                                 default = nil)
  if valid_774054 != nil:
    section.add "Bucket", valid_774054
  result.add "path", section
  ## parameters in `query` object:
  ##   policyStatus: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `policyStatus` field"
  var valid_774055 = query.getOrDefault("policyStatus")
  valid_774055 = validateParameter(valid_774055, JBool, required = true, default = nil)
  if valid_774055 != nil:
    section.add "policyStatus", valid_774055
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774056 = header.getOrDefault("x-amz-security-token")
  valid_774056 = validateParameter(valid_774056, JString, required = false,
                                 default = nil)
  if valid_774056 != nil:
    section.add "x-amz-security-token", valid_774056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774057: Call_GetBucketPolicyStatus_774051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ## 
  let valid = call_774057.validator(path, query, header, formData, body)
  let scheme = call_774057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774057.url(scheme.get, call_774057.host, call_774057.base,
                         call_774057.route, valid.getOrDefault("path"))
  result = hook(call_774057, url, valid)

proc call*(call_774058: Call_GetBucketPolicyStatus_774051; policyStatus: bool;
          Bucket: string): Recallable =
  ## getBucketPolicyStatus
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ##   policyStatus: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose policy status you want to retrieve.
  var path_774059 = newJObject()
  var query_774060 = newJObject()
  add(query_774060, "policyStatus", newJBool(policyStatus))
  add(path_774059, "Bucket", newJString(Bucket))
  result = call_774058.call(path_774059, query_774060, nil, nil, nil)

var getBucketPolicyStatus* = Call_GetBucketPolicyStatus_774051(
    name: "getBucketPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#policyStatus",
    validator: validate_GetBucketPolicyStatus_774052, base: "/",
    url: url_GetBucketPolicyStatus_774053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketRequestPayment_774071 = ref object of OpenApiRestCall_772597
proc url_PutBucketRequestPayment_774073(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketRequestPayment_774072(path: JsonNode; query: JsonNode;
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
  var valid_774074 = path.getOrDefault("Bucket")
  valid_774074 = validateParameter(valid_774074, JString, required = true,
                                 default = nil)
  if valid_774074 != nil:
    section.add "Bucket", valid_774074
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_774075 = query.getOrDefault("requestPayment")
  valid_774075 = validateParameter(valid_774075, JBool, required = true, default = nil)
  if valid_774075 != nil:
    section.add "requestPayment", valid_774075
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_774076 = header.getOrDefault("x-amz-security-token")
  valid_774076 = validateParameter(valid_774076, JString, required = false,
                                 default = nil)
  if valid_774076 != nil:
    section.add "x-amz-security-token", valid_774076
  var valid_774077 = header.getOrDefault("Content-MD5")
  valid_774077 = validateParameter(valid_774077, JString, required = false,
                                 default = nil)
  if valid_774077 != nil:
    section.add "Content-MD5", valid_774077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774079: Call_PutBucketRequestPayment_774071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  let valid = call_774079.validator(path, query, header, formData, body)
  let scheme = call_774079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774079.url(scheme.get, call_774079.host, call_774079.base,
                         call_774079.route, valid.getOrDefault("path"))
  result = hook(call_774079, url, valid)

proc call*(call_774080: Call_PutBucketRequestPayment_774071; requestPayment: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketRequestPayment
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_774081 = newJObject()
  var query_774082 = newJObject()
  var body_774083 = newJObject()
  add(query_774082, "requestPayment", newJBool(requestPayment))
  add(path_774081, "Bucket", newJString(Bucket))
  if body != nil:
    body_774083 = body
  result = call_774080.call(path_774081, query_774082, nil, nil, body_774083)

var putBucketRequestPayment* = Call_PutBucketRequestPayment_774071(
    name: "putBucketRequestPayment", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_PutBucketRequestPayment_774072, base: "/",
    url: url_PutBucketRequestPayment_774073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketRequestPayment_774061 = ref object of OpenApiRestCall_772597
proc url_GetBucketRequestPayment_774063(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketRequestPayment_774062(path: JsonNode; query: JsonNode;
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
  var valid_774064 = path.getOrDefault("Bucket")
  valid_774064 = validateParameter(valid_774064, JString, required = true,
                                 default = nil)
  if valid_774064 != nil:
    section.add "Bucket", valid_774064
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_774065 = query.getOrDefault("requestPayment")
  valid_774065 = validateParameter(valid_774065, JBool, required = true, default = nil)
  if valid_774065 != nil:
    section.add "requestPayment", valid_774065
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774066 = header.getOrDefault("x-amz-security-token")
  valid_774066 = validateParameter(valid_774066, JString, required = false,
                                 default = nil)
  if valid_774066 != nil:
    section.add "x-amz-security-token", valid_774066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774067: Call_GetBucketRequestPayment_774061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the request payment configuration of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  let valid = call_774067.validator(path, query, header, formData, body)
  let scheme = call_774067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774067.url(scheme.get, call_774067.host, call_774067.base,
                         call_774067.route, valid.getOrDefault("path"))
  result = hook(call_774067, url, valid)

proc call*(call_774068: Call_GetBucketRequestPayment_774061; requestPayment: bool;
          Bucket: string): Recallable =
  ## getBucketRequestPayment
  ## Returns the request payment configuration of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_774069 = newJObject()
  var query_774070 = newJObject()
  add(query_774070, "requestPayment", newJBool(requestPayment))
  add(path_774069, "Bucket", newJString(Bucket))
  result = call_774068.call(path_774069, query_774070, nil, nil, nil)

var getBucketRequestPayment* = Call_GetBucketRequestPayment_774061(
    name: "getBucketRequestPayment", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_GetBucketRequestPayment_774062, base: "/",
    url: url_GetBucketRequestPayment_774063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketVersioning_774094 = ref object of OpenApiRestCall_772597
proc url_PutBucketVersioning_774096(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketVersioning_774095(path: JsonNode; query: JsonNode;
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
  var valid_774097 = path.getOrDefault("Bucket")
  valid_774097 = validateParameter(valid_774097, JString, required = true,
                                 default = nil)
  if valid_774097 != nil:
    section.add "Bucket", valid_774097
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_774098 = query.getOrDefault("versioning")
  valid_774098 = validateParameter(valid_774098, JBool, required = true, default = nil)
  if valid_774098 != nil:
    section.add "versioning", valid_774098
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  section = newJObject()
  var valid_774099 = header.getOrDefault("x-amz-security-token")
  valid_774099 = validateParameter(valid_774099, JString, required = false,
                                 default = nil)
  if valid_774099 != nil:
    section.add "x-amz-security-token", valid_774099
  var valid_774100 = header.getOrDefault("Content-MD5")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "Content-MD5", valid_774100
  var valid_774101 = header.getOrDefault("x-amz-mfa")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "x-amz-mfa", valid_774101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774103: Call_PutBucketVersioning_774094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  let valid = call_774103.validator(path, query, header, formData, body)
  let scheme = call_774103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774103.url(scheme.get, call_774103.host, call_774103.base,
                         call_774103.route, valid.getOrDefault("path"))
  result = hook(call_774103, url, valid)

proc call*(call_774104: Call_PutBucketVersioning_774094; Bucket: string;
          body: JsonNode; versioning: bool): Recallable =
  ## putBucketVersioning
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   versioning: bool (required)
  var path_774105 = newJObject()
  var query_774106 = newJObject()
  var body_774107 = newJObject()
  add(path_774105, "Bucket", newJString(Bucket))
  if body != nil:
    body_774107 = body
  add(query_774106, "versioning", newJBool(versioning))
  result = call_774104.call(path_774105, query_774106, nil, nil, body_774107)

var putBucketVersioning* = Call_PutBucketVersioning_774094(
    name: "putBucketVersioning", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_PutBucketVersioning_774095,
    base: "/", url: url_PutBucketVersioning_774096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketVersioning_774084 = ref object of OpenApiRestCall_772597
proc url_GetBucketVersioning_774086(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketVersioning_774085(path: JsonNode; query: JsonNode;
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
  var valid_774087 = path.getOrDefault("Bucket")
  valid_774087 = validateParameter(valid_774087, JString, required = true,
                                 default = nil)
  if valid_774087 != nil:
    section.add "Bucket", valid_774087
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_774088 = query.getOrDefault("versioning")
  valid_774088 = validateParameter(valid_774088, JBool, required = true, default = nil)
  if valid_774088 != nil:
    section.add "versioning", valid_774088
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774089 = header.getOrDefault("x-amz-security-token")
  valid_774089 = validateParameter(valid_774089, JString, required = false,
                                 default = nil)
  if valid_774089 != nil:
    section.add "x-amz-security-token", valid_774089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774090: Call_GetBucketVersioning_774084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the versioning state of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  let valid = call_774090.validator(path, query, header, formData, body)
  let scheme = call_774090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774090.url(scheme.get, call_774090.host, call_774090.base,
                         call_774090.route, valid.getOrDefault("path"))
  result = hook(call_774090, url, valid)

proc call*(call_774091: Call_GetBucketVersioning_774084; Bucket: string;
          versioning: bool): Recallable =
  ## getBucketVersioning
  ## Returns the versioning state of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versioning: bool (required)
  var path_774092 = newJObject()
  var query_774093 = newJObject()
  add(path_774092, "Bucket", newJString(Bucket))
  add(query_774093, "versioning", newJBool(versioning))
  result = call_774091.call(path_774092, query_774093, nil, nil, nil)

var getBucketVersioning* = Call_GetBucketVersioning_774084(
    name: "getBucketVersioning", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_GetBucketVersioning_774085,
    base: "/", url: url_GetBucketVersioning_774086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectAcl_774121 = ref object of OpenApiRestCall_772597
proc url_PutObjectAcl_774123(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectAcl_774122(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774124 = path.getOrDefault("Key")
  valid_774124 = validateParameter(valid_774124, JString, required = true,
                                 default = nil)
  if valid_774124 != nil:
    section.add "Key", valid_774124
  var valid_774125 = path.getOrDefault("Bucket")
  valid_774125 = validateParameter(valid_774125, JString, required = true,
                                 default = nil)
  if valid_774125 != nil:
    section.add "Bucket", valid_774125
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_774126 = query.getOrDefault("versionId")
  valid_774126 = validateParameter(valid_774126, JString, required = false,
                                 default = nil)
  if valid_774126 != nil:
    section.add "versionId", valid_774126
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_774127 = query.getOrDefault("acl")
  valid_774127 = validateParameter(valid_774127, JBool, required = true, default = nil)
  if valid_774127 != nil:
    section.add "acl", valid_774127
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
  var valid_774128 = header.getOrDefault("x-amz-security-token")
  valid_774128 = validateParameter(valid_774128, JString, required = false,
                                 default = nil)
  if valid_774128 != nil:
    section.add "x-amz-security-token", valid_774128
  var valid_774129 = header.getOrDefault("Content-MD5")
  valid_774129 = validateParameter(valid_774129, JString, required = false,
                                 default = nil)
  if valid_774129 != nil:
    section.add "Content-MD5", valid_774129
  var valid_774130 = header.getOrDefault("x-amz-acl")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = newJString("private"))
  if valid_774130 != nil:
    section.add "x-amz-acl", valid_774130
  var valid_774131 = header.getOrDefault("x-amz-grant-read")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "x-amz-grant-read", valid_774131
  var valid_774132 = header.getOrDefault("x-amz-grant-read-acp")
  valid_774132 = validateParameter(valid_774132, JString, required = false,
                                 default = nil)
  if valid_774132 != nil:
    section.add "x-amz-grant-read-acp", valid_774132
  var valid_774133 = header.getOrDefault("x-amz-grant-write")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "x-amz-grant-write", valid_774133
  var valid_774134 = header.getOrDefault("x-amz-grant-write-acp")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "x-amz-grant-write-acp", valid_774134
  var valid_774135 = header.getOrDefault("x-amz-request-payer")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = newJString("requester"))
  if valid_774135 != nil:
    section.add "x-amz-request-payer", valid_774135
  var valid_774136 = header.getOrDefault("x-amz-grant-full-control")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "x-amz-grant-full-control", valid_774136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774138: Call_PutObjectAcl_774121; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  let valid = call_774138.validator(path, query, header, formData, body)
  let scheme = call_774138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774138.url(scheme.get, call_774138.host, call_774138.base,
                         call_774138.route, valid.getOrDefault("path"))
  result = hook(call_774138, url, valid)

proc call*(call_774139: Call_PutObjectAcl_774121; Key: string; acl: bool;
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
  var path_774140 = newJObject()
  var query_774141 = newJObject()
  var body_774142 = newJObject()
  add(query_774141, "versionId", newJString(versionId))
  add(path_774140, "Key", newJString(Key))
  add(query_774141, "acl", newJBool(acl))
  add(path_774140, "Bucket", newJString(Bucket))
  if body != nil:
    body_774142 = body
  result = call_774139.call(path_774140, query_774141, nil, nil, body_774142)

var putObjectAcl* = Call_PutObjectAcl_774121(name: "putObjectAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_PutObjectAcl_774122,
    base: "/", url: url_PutObjectAcl_774123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAcl_774108 = ref object of OpenApiRestCall_772597
proc url_GetObjectAcl_774110(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectAcl_774109(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774111 = path.getOrDefault("Key")
  valid_774111 = validateParameter(valid_774111, JString, required = true,
                                 default = nil)
  if valid_774111 != nil:
    section.add "Key", valid_774111
  var valid_774112 = path.getOrDefault("Bucket")
  valid_774112 = validateParameter(valid_774112, JString, required = true,
                                 default = nil)
  if valid_774112 != nil:
    section.add "Bucket", valid_774112
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_774113 = query.getOrDefault("versionId")
  valid_774113 = validateParameter(valid_774113, JString, required = false,
                                 default = nil)
  if valid_774113 != nil:
    section.add "versionId", valid_774113
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_774114 = query.getOrDefault("acl")
  valid_774114 = validateParameter(valid_774114, JBool, required = true, default = nil)
  if valid_774114 != nil:
    section.add "acl", valid_774114
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_774115 = header.getOrDefault("x-amz-security-token")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "x-amz-security-token", valid_774115
  var valid_774116 = header.getOrDefault("x-amz-request-payer")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = newJString("requester"))
  if valid_774116 != nil:
    section.add "x-amz-request-payer", valid_774116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774117: Call_GetObjectAcl_774108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access control list (ACL) of an object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  let valid = call_774117.validator(path, query, header, formData, body)
  let scheme = call_774117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774117.url(scheme.get, call_774117.host, call_774117.base,
                         call_774117.route, valid.getOrDefault("path"))
  result = hook(call_774117, url, valid)

proc call*(call_774118: Call_GetObjectAcl_774108; Key: string; acl: bool;
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
  var path_774119 = newJObject()
  var query_774120 = newJObject()
  add(query_774120, "versionId", newJString(versionId))
  add(path_774119, "Key", newJString(Key))
  add(query_774120, "acl", newJBool(acl))
  add(path_774119, "Bucket", newJString(Bucket))
  result = call_774118.call(path_774119, query_774120, nil, nil, nil)

var getObjectAcl* = Call_GetObjectAcl_774108(name: "getObjectAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_GetObjectAcl_774109,
    base: "/", url: url_GetObjectAcl_774110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLegalHold_774156 = ref object of OpenApiRestCall_772597
proc url_PutObjectLegalHold_774158(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectLegalHold_774157(path: JsonNode; query: JsonNode;
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
  var valid_774159 = path.getOrDefault("Key")
  valid_774159 = validateParameter(valid_774159, JString, required = true,
                                 default = nil)
  if valid_774159 != nil:
    section.add "Key", valid_774159
  var valid_774160 = path.getOrDefault("Bucket")
  valid_774160 = validateParameter(valid_774160, JString, required = true,
                                 default = nil)
  if valid_774160 != nil:
    section.add "Bucket", valid_774160
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object that you want to place a Legal Hold on.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_774161 = query.getOrDefault("versionId")
  valid_774161 = validateParameter(valid_774161, JString, required = false,
                                 default = nil)
  if valid_774161 != nil:
    section.add "versionId", valid_774161
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_774162 = query.getOrDefault("legal-hold")
  valid_774162 = validateParameter(valid_774162, JBool, required = true, default = nil)
  if valid_774162 != nil:
    section.add "legal-hold", valid_774162
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_774163 = header.getOrDefault("x-amz-security-token")
  valid_774163 = validateParameter(valid_774163, JString, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "x-amz-security-token", valid_774163
  var valid_774164 = header.getOrDefault("Content-MD5")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "Content-MD5", valid_774164
  var valid_774165 = header.getOrDefault("x-amz-request-payer")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = newJString("requester"))
  if valid_774165 != nil:
    section.add "x-amz-request-payer", valid_774165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774167: Call_PutObjectLegalHold_774156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a Legal Hold configuration to the specified object.
  ## 
  let valid = call_774167.validator(path, query, header, formData, body)
  let scheme = call_774167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774167.url(scheme.get, call_774167.host, call_774167.base,
                         call_774167.route, valid.getOrDefault("path"))
  result = hook(call_774167, url, valid)

proc call*(call_774168: Call_PutObjectLegalHold_774156; Key: string; legalHold: bool;
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
  var path_774169 = newJObject()
  var query_774170 = newJObject()
  var body_774171 = newJObject()
  add(query_774170, "versionId", newJString(versionId))
  add(path_774169, "Key", newJString(Key))
  add(query_774170, "legal-hold", newJBool(legalHold))
  add(path_774169, "Bucket", newJString(Bucket))
  if body != nil:
    body_774171 = body
  result = call_774168.call(path_774169, query_774170, nil, nil, body_774171)

var putObjectLegalHold* = Call_PutObjectLegalHold_774156(
    name: "putObjectLegalHold", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_PutObjectLegalHold_774157,
    base: "/", url: url_PutObjectLegalHold_774158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLegalHold_774143 = ref object of OpenApiRestCall_772597
proc url_GetObjectLegalHold_774145(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectLegalHold_774144(path: JsonNode; query: JsonNode;
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
  var valid_774146 = path.getOrDefault("Key")
  valid_774146 = validateParameter(valid_774146, JString, required = true,
                                 default = nil)
  if valid_774146 != nil:
    section.add "Key", valid_774146
  var valid_774147 = path.getOrDefault("Bucket")
  valid_774147 = validateParameter(valid_774147, JString, required = true,
                                 default = nil)
  if valid_774147 != nil:
    section.add "Bucket", valid_774147
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object whose Legal Hold status you want to retrieve.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_774148 = query.getOrDefault("versionId")
  valid_774148 = validateParameter(valid_774148, JString, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "versionId", valid_774148
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_774149 = query.getOrDefault("legal-hold")
  valid_774149 = validateParameter(valid_774149, JBool, required = true, default = nil)
  if valid_774149 != nil:
    section.add "legal-hold", valid_774149
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_774150 = header.getOrDefault("x-amz-security-token")
  valid_774150 = validateParameter(valid_774150, JString, required = false,
                                 default = nil)
  if valid_774150 != nil:
    section.add "x-amz-security-token", valid_774150
  var valid_774151 = header.getOrDefault("x-amz-request-payer")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = newJString("requester"))
  if valid_774151 != nil:
    section.add "x-amz-request-payer", valid_774151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774152: Call_GetObjectLegalHold_774143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an object's current Legal Hold status.
  ## 
  let valid = call_774152.validator(path, query, header, formData, body)
  let scheme = call_774152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774152.url(scheme.get, call_774152.host, call_774152.base,
                         call_774152.route, valid.getOrDefault("path"))
  result = hook(call_774152, url, valid)

proc call*(call_774153: Call_GetObjectLegalHold_774143; Key: string; legalHold: bool;
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
  var path_774154 = newJObject()
  var query_774155 = newJObject()
  add(query_774155, "versionId", newJString(versionId))
  add(path_774154, "Key", newJString(Key))
  add(query_774155, "legal-hold", newJBool(legalHold))
  add(path_774154, "Bucket", newJString(Bucket))
  result = call_774153.call(path_774154, query_774155, nil, nil, nil)

var getObjectLegalHold* = Call_GetObjectLegalHold_774143(
    name: "getObjectLegalHold", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_GetObjectLegalHold_774144,
    base: "/", url: url_GetObjectLegalHold_774145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLockConfiguration_774182 = ref object of OpenApiRestCall_772597
proc url_PutObjectLockConfiguration_774184(protocol: Scheme; host: string;
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

proc validate_PutObjectLockConfiguration_774183(path: JsonNode; query: JsonNode;
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
  var valid_774185 = path.getOrDefault("Bucket")
  valid_774185 = validateParameter(valid_774185, JString, required = true,
                                 default = nil)
  if valid_774185 != nil:
    section.add "Bucket", valid_774185
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_774186 = query.getOrDefault("object-lock")
  valid_774186 = validateParameter(valid_774186, JBool, required = true, default = nil)
  if valid_774186 != nil:
    section.add "object-lock", valid_774186
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
  var valid_774187 = header.getOrDefault("x-amz-security-token")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "x-amz-security-token", valid_774187
  var valid_774188 = header.getOrDefault("Content-MD5")
  valid_774188 = validateParameter(valid_774188, JString, required = false,
                                 default = nil)
  if valid_774188 != nil:
    section.add "Content-MD5", valid_774188
  var valid_774189 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_774189 = validateParameter(valid_774189, JString, required = false,
                                 default = nil)
  if valid_774189 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_774189
  var valid_774190 = header.getOrDefault("x-amz-request-payer")
  valid_774190 = validateParameter(valid_774190, JString, required = false,
                                 default = newJString("requester"))
  if valid_774190 != nil:
    section.add "x-amz-request-payer", valid_774190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774192: Call_PutObjectLockConfiguration_774182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_774192.validator(path, query, header, formData, body)
  let scheme = call_774192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774192.url(scheme.get, call_774192.host, call_774192.base,
                         call_774192.route, valid.getOrDefault("path"))
  result = hook(call_774192, url, valid)

proc call*(call_774193: Call_PutObjectLockConfiguration_774182; objectLock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putObjectLockConfiguration
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to create or replace.
  ##   body: JObject (required)
  var path_774194 = newJObject()
  var query_774195 = newJObject()
  var body_774196 = newJObject()
  add(query_774195, "object-lock", newJBool(objectLock))
  add(path_774194, "Bucket", newJString(Bucket))
  if body != nil:
    body_774196 = body
  result = call_774193.call(path_774194, query_774195, nil, nil, body_774196)

var putObjectLockConfiguration* = Call_PutObjectLockConfiguration_774182(
    name: "putObjectLockConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_PutObjectLockConfiguration_774183, base: "/",
    url: url_PutObjectLockConfiguration_774184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLockConfiguration_774172 = ref object of OpenApiRestCall_772597
proc url_GetObjectLockConfiguration_774174(protocol: Scheme; host: string;
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

proc validate_GetObjectLockConfiguration_774173(path: JsonNode; query: JsonNode;
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
  var valid_774175 = path.getOrDefault("Bucket")
  valid_774175 = validateParameter(valid_774175, JString, required = true,
                                 default = nil)
  if valid_774175 != nil:
    section.add "Bucket", valid_774175
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_774176 = query.getOrDefault("object-lock")
  valid_774176 = validateParameter(valid_774176, JBool, required = true, default = nil)
  if valid_774176 != nil:
    section.add "object-lock", valid_774176
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774177 = header.getOrDefault("x-amz-security-token")
  valid_774177 = validateParameter(valid_774177, JString, required = false,
                                 default = nil)
  if valid_774177 != nil:
    section.add "x-amz-security-token", valid_774177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774178: Call_GetObjectLockConfiguration_774172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_774178.validator(path, query, header, formData, body)
  let scheme = call_774178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774178.url(scheme.get, call_774178.host, call_774178.base,
                         call_774178.route, valid.getOrDefault("path"))
  result = hook(call_774178, url, valid)

proc call*(call_774179: Call_GetObjectLockConfiguration_774172; objectLock: bool;
          Bucket: string): Recallable =
  ## getObjectLockConfiguration
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to retrieve.
  var path_774180 = newJObject()
  var query_774181 = newJObject()
  add(query_774181, "object-lock", newJBool(objectLock))
  add(path_774180, "Bucket", newJString(Bucket))
  result = call_774179.call(path_774180, query_774181, nil, nil, nil)

var getObjectLockConfiguration* = Call_GetObjectLockConfiguration_774172(
    name: "getObjectLockConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_GetObjectLockConfiguration_774173, base: "/",
    url: url_GetObjectLockConfiguration_774174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectRetention_774210 = ref object of OpenApiRestCall_772597
proc url_PutObjectRetention_774212(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectRetention_774211(path: JsonNode; query: JsonNode;
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
  var valid_774213 = path.getOrDefault("Key")
  valid_774213 = validateParameter(valid_774213, JString, required = true,
                                 default = nil)
  if valid_774213 != nil:
    section.add "Key", valid_774213
  var valid_774214 = path.getOrDefault("Bucket")
  valid_774214 = validateParameter(valid_774214, JString, required = true,
                                 default = nil)
  if valid_774214 != nil:
    section.add "Bucket", valid_774214
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object that you want to apply this Object Retention configuration to.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_774215 = query.getOrDefault("versionId")
  valid_774215 = validateParameter(valid_774215, JString, required = false,
                                 default = nil)
  if valid_774215 != nil:
    section.add "versionId", valid_774215
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_774216 = query.getOrDefault("retention")
  valid_774216 = validateParameter(valid_774216, JBool, required = true, default = nil)
  if valid_774216 != nil:
    section.add "retention", valid_774216
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
  var valid_774217 = header.getOrDefault("x-amz-security-token")
  valid_774217 = validateParameter(valid_774217, JString, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "x-amz-security-token", valid_774217
  var valid_774218 = header.getOrDefault("Content-MD5")
  valid_774218 = validateParameter(valid_774218, JString, required = false,
                                 default = nil)
  if valid_774218 != nil:
    section.add "Content-MD5", valid_774218
  var valid_774219 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_774219 = validateParameter(valid_774219, JBool, required = false, default = nil)
  if valid_774219 != nil:
    section.add "x-amz-bypass-governance-retention", valid_774219
  var valid_774220 = header.getOrDefault("x-amz-request-payer")
  valid_774220 = validateParameter(valid_774220, JString, required = false,
                                 default = newJString("requester"))
  if valid_774220 != nil:
    section.add "x-amz-request-payer", valid_774220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774222: Call_PutObjectRetention_774210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an Object Retention configuration on an object.
  ## 
  let valid = call_774222.validator(path, query, header, formData, body)
  let scheme = call_774222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774222.url(scheme.get, call_774222.host, call_774222.base,
                         call_774222.route, valid.getOrDefault("path"))
  result = hook(call_774222, url, valid)

proc call*(call_774223: Call_PutObjectRetention_774210; retention: bool; Key: string;
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
  var path_774224 = newJObject()
  var query_774225 = newJObject()
  var body_774226 = newJObject()
  add(query_774225, "versionId", newJString(versionId))
  add(query_774225, "retention", newJBool(retention))
  add(path_774224, "Key", newJString(Key))
  add(path_774224, "Bucket", newJString(Bucket))
  if body != nil:
    body_774226 = body
  result = call_774223.call(path_774224, query_774225, nil, nil, body_774226)

var putObjectRetention* = Call_PutObjectRetention_774210(
    name: "putObjectRetention", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_PutObjectRetention_774211,
    base: "/", url: url_PutObjectRetention_774212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectRetention_774197 = ref object of OpenApiRestCall_772597
proc url_GetObjectRetention_774199(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectRetention_774198(path: JsonNode; query: JsonNode;
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
  var valid_774200 = path.getOrDefault("Key")
  valid_774200 = validateParameter(valid_774200, JString, required = true,
                                 default = nil)
  if valid_774200 != nil:
    section.add "Key", valid_774200
  var valid_774201 = path.getOrDefault("Bucket")
  valid_774201 = validateParameter(valid_774201, JString, required = true,
                                 default = nil)
  if valid_774201 != nil:
    section.add "Bucket", valid_774201
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object whose retention settings you want to retrieve.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_774202 = query.getOrDefault("versionId")
  valid_774202 = validateParameter(valid_774202, JString, required = false,
                                 default = nil)
  if valid_774202 != nil:
    section.add "versionId", valid_774202
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_774203 = query.getOrDefault("retention")
  valid_774203 = validateParameter(valid_774203, JBool, required = true, default = nil)
  if valid_774203 != nil:
    section.add "retention", valid_774203
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_774204 = header.getOrDefault("x-amz-security-token")
  valid_774204 = validateParameter(valid_774204, JString, required = false,
                                 default = nil)
  if valid_774204 != nil:
    section.add "x-amz-security-token", valid_774204
  var valid_774205 = header.getOrDefault("x-amz-request-payer")
  valid_774205 = validateParameter(valid_774205, JString, required = false,
                                 default = newJString("requester"))
  if valid_774205 != nil:
    section.add "x-amz-request-payer", valid_774205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774206: Call_GetObjectRetention_774197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an object's retention settings.
  ## 
  let valid = call_774206.validator(path, query, header, formData, body)
  let scheme = call_774206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774206.url(scheme.get, call_774206.host, call_774206.base,
                         call_774206.route, valid.getOrDefault("path"))
  result = hook(call_774206, url, valid)

proc call*(call_774207: Call_GetObjectRetention_774197; retention: bool; Key: string;
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
  var path_774208 = newJObject()
  var query_774209 = newJObject()
  add(query_774209, "versionId", newJString(versionId))
  add(query_774209, "retention", newJBool(retention))
  add(path_774208, "Key", newJString(Key))
  add(path_774208, "Bucket", newJString(Bucket))
  result = call_774207.call(path_774208, query_774209, nil, nil, nil)

var getObjectRetention* = Call_GetObjectRetention_774197(
    name: "getObjectRetention", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_GetObjectRetention_774198,
    base: "/", url: url_GetObjectRetention_774199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTorrent_774227 = ref object of OpenApiRestCall_772597
proc url_GetObjectTorrent_774229(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectTorrent_774228(path: JsonNode; query: JsonNode;
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
  var valid_774230 = path.getOrDefault("Key")
  valid_774230 = validateParameter(valid_774230, JString, required = true,
                                 default = nil)
  if valid_774230 != nil:
    section.add "Key", valid_774230
  var valid_774231 = path.getOrDefault("Bucket")
  valid_774231 = validateParameter(valid_774231, JString, required = true,
                                 default = nil)
  if valid_774231 != nil:
    section.add "Bucket", valid_774231
  result.add "path", section
  ## parameters in `query` object:
  ##   torrent: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `torrent` field"
  var valid_774232 = query.getOrDefault("torrent")
  valid_774232 = validateParameter(valid_774232, JBool, required = true, default = nil)
  if valid_774232 != nil:
    section.add "torrent", valid_774232
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_774233 = header.getOrDefault("x-amz-security-token")
  valid_774233 = validateParameter(valid_774233, JString, required = false,
                                 default = nil)
  if valid_774233 != nil:
    section.add "x-amz-security-token", valid_774233
  var valid_774234 = header.getOrDefault("x-amz-request-payer")
  valid_774234 = validateParameter(valid_774234, JString, required = false,
                                 default = newJString("requester"))
  if valid_774234 != nil:
    section.add "x-amz-request-payer", valid_774234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774235: Call_GetObjectTorrent_774227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return torrent files from a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  let valid = call_774235.validator(path, query, header, formData, body)
  let scheme = call_774235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774235.url(scheme.get, call_774235.host, call_774235.base,
                         call_774235.route, valid.getOrDefault("path"))
  result = hook(call_774235, url, valid)

proc call*(call_774236: Call_GetObjectTorrent_774227; torrent: bool; Key: string;
          Bucket: string): Recallable =
  ## getObjectTorrent
  ## Return torrent files from a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  ##   torrent: bool (required)
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_774237 = newJObject()
  var query_774238 = newJObject()
  add(query_774238, "torrent", newJBool(torrent))
  add(path_774237, "Key", newJString(Key))
  add(path_774237, "Bucket", newJString(Bucket))
  result = call_774236.call(path_774237, query_774238, nil, nil, nil)

var getObjectTorrent* = Call_GetObjectTorrent_774227(name: "getObjectTorrent",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#torrent", validator: validate_GetObjectTorrent_774228,
    base: "/", url: url_GetObjectTorrent_774229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketAnalyticsConfigurations_774239 = ref object of OpenApiRestCall_772597
proc url_ListBucketAnalyticsConfigurations_774241(protocol: Scheme; host: string;
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

proc validate_ListBucketAnalyticsConfigurations_774240(path: JsonNode;
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
  var valid_774242 = path.getOrDefault("Bucket")
  valid_774242 = validateParameter(valid_774242, JString, required = true,
                                 default = nil)
  if valid_774242 != nil:
    section.add "Bucket", valid_774242
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   continuation-token: JString
  ##                     : The ContinuationToken that represents a placeholder from where this request should begin.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_774243 = query.getOrDefault("analytics")
  valid_774243 = validateParameter(valid_774243, JBool, required = true, default = nil)
  if valid_774243 != nil:
    section.add "analytics", valid_774243
  var valid_774244 = query.getOrDefault("continuation-token")
  valid_774244 = validateParameter(valid_774244, JString, required = false,
                                 default = nil)
  if valid_774244 != nil:
    section.add "continuation-token", valid_774244
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774245 = header.getOrDefault("x-amz-security-token")
  valid_774245 = validateParameter(valid_774245, JString, required = false,
                                 default = nil)
  if valid_774245 != nil:
    section.add "x-amz-security-token", valid_774245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774246: Call_ListBucketAnalyticsConfigurations_774239;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the analytics configurations for the bucket.
  ## 
  let valid = call_774246.validator(path, query, header, formData, body)
  let scheme = call_774246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774246.url(scheme.get, call_774246.host, call_774246.base,
                         call_774246.route, valid.getOrDefault("path"))
  result = hook(call_774246, url, valid)

proc call*(call_774247: Call_ListBucketAnalyticsConfigurations_774239;
          analytics: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketAnalyticsConfigurations
  ## Lists the analytics configurations for the bucket.
  ##   analytics: bool (required)
  ##   continuationToken: string
  ##                    : The ContinuationToken that represents a placeholder from where this request should begin.
  ##   Bucket: string (required)
  ##         : The name of the bucket from which analytics configurations are retrieved.
  var path_774248 = newJObject()
  var query_774249 = newJObject()
  add(query_774249, "analytics", newJBool(analytics))
  add(query_774249, "continuation-token", newJString(continuationToken))
  add(path_774248, "Bucket", newJString(Bucket))
  result = call_774247.call(path_774248, query_774249, nil, nil, nil)

var listBucketAnalyticsConfigurations* = Call_ListBucketAnalyticsConfigurations_774239(
    name: "listBucketAnalyticsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics",
    validator: validate_ListBucketAnalyticsConfigurations_774240, base: "/",
    url: url_ListBucketAnalyticsConfigurations_774241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketInventoryConfigurations_774250 = ref object of OpenApiRestCall_772597
proc url_ListBucketInventoryConfigurations_774252(protocol: Scheme; host: string;
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

proc validate_ListBucketInventoryConfigurations_774251(path: JsonNode;
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
  var valid_774253 = path.getOrDefault("Bucket")
  valid_774253 = validateParameter(valid_774253, JString, required = true,
                                 default = nil)
  if valid_774253 != nil:
    section.add "Bucket", valid_774253
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_774254 = query.getOrDefault("inventory")
  valid_774254 = validateParameter(valid_774254, JBool, required = true, default = nil)
  if valid_774254 != nil:
    section.add "inventory", valid_774254
  var valid_774255 = query.getOrDefault("continuation-token")
  valid_774255 = validateParameter(valid_774255, JString, required = false,
                                 default = nil)
  if valid_774255 != nil:
    section.add "continuation-token", valid_774255
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774256 = header.getOrDefault("x-amz-security-token")
  valid_774256 = validateParameter(valid_774256, JString, required = false,
                                 default = nil)
  if valid_774256 != nil:
    section.add "x-amz-security-token", valid_774256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774257: Call_ListBucketInventoryConfigurations_774250;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of inventory configurations for the bucket.
  ## 
  let valid = call_774257.validator(path, query, header, formData, body)
  let scheme = call_774257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774257.url(scheme.get, call_774257.host, call_774257.base,
                         call_774257.route, valid.getOrDefault("path"))
  result = hook(call_774257, url, valid)

proc call*(call_774258: Call_ListBucketInventoryConfigurations_774250;
          inventory: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketInventoryConfigurations
  ## Returns a list of inventory configurations for the bucket.
  ##   inventory: bool (required)
  ##   continuationToken: string
  ##                    : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configurations to retrieve.
  var path_774259 = newJObject()
  var query_774260 = newJObject()
  add(query_774260, "inventory", newJBool(inventory))
  add(query_774260, "continuation-token", newJString(continuationToken))
  add(path_774259, "Bucket", newJString(Bucket))
  result = call_774258.call(path_774259, query_774260, nil, nil, nil)

var listBucketInventoryConfigurations* = Call_ListBucketInventoryConfigurations_774250(
    name: "listBucketInventoryConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory",
    validator: validate_ListBucketInventoryConfigurations_774251, base: "/",
    url: url_ListBucketInventoryConfigurations_774252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketMetricsConfigurations_774261 = ref object of OpenApiRestCall_772597
proc url_ListBucketMetricsConfigurations_774263(protocol: Scheme; host: string;
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

proc validate_ListBucketMetricsConfigurations_774262(path: JsonNode;
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
  var valid_774264 = path.getOrDefault("Bucket")
  valid_774264 = validateParameter(valid_774264, JString, required = true,
                                 default = nil)
  if valid_774264 != nil:
    section.add "Bucket", valid_774264
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_774265 = query.getOrDefault("metrics")
  valid_774265 = validateParameter(valid_774265, JBool, required = true, default = nil)
  if valid_774265 != nil:
    section.add "metrics", valid_774265
  var valid_774266 = query.getOrDefault("continuation-token")
  valid_774266 = validateParameter(valid_774266, JString, required = false,
                                 default = nil)
  if valid_774266 != nil:
    section.add "continuation-token", valid_774266
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774267 = header.getOrDefault("x-amz-security-token")
  valid_774267 = validateParameter(valid_774267, JString, required = false,
                                 default = nil)
  if valid_774267 != nil:
    section.add "x-amz-security-token", valid_774267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774268: Call_ListBucketMetricsConfigurations_774261;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the metrics configurations for the bucket.
  ## 
  let valid = call_774268.validator(path, query, header, formData, body)
  let scheme = call_774268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774268.url(scheme.get, call_774268.host, call_774268.base,
                         call_774268.route, valid.getOrDefault("path"))
  result = hook(call_774268, url, valid)

proc call*(call_774269: Call_ListBucketMetricsConfigurations_774261; metrics: bool;
          Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketMetricsConfigurations
  ## Lists the metrics configurations for the bucket.
  ##   metrics: bool (required)
  ##   continuationToken: string
  ##                    : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configurations to retrieve.
  var path_774270 = newJObject()
  var query_774271 = newJObject()
  add(query_774271, "metrics", newJBool(metrics))
  add(query_774271, "continuation-token", newJString(continuationToken))
  add(path_774270, "Bucket", newJString(Bucket))
  result = call_774269.call(path_774270, query_774271, nil, nil, nil)

var listBucketMetricsConfigurations* = Call_ListBucketMetricsConfigurations_774261(
    name: "listBucketMetricsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics",
    validator: validate_ListBucketMetricsConfigurations_774262, base: "/",
    url: url_ListBucketMetricsConfigurations_774263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuckets_774272 = ref object of OpenApiRestCall_772597
proc url_ListBuckets_774274(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBuckets_774273(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774275 = header.getOrDefault("x-amz-security-token")
  valid_774275 = validateParameter(valid_774275, JString, required = false,
                                 default = nil)
  if valid_774275 != nil:
    section.add "x-amz-security-token", valid_774275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774276: Call_ListBuckets_774272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  let valid = call_774276.validator(path, query, header, formData, body)
  let scheme = call_774276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774276.url(scheme.get, call_774276.host, call_774276.base,
                         call_774276.route, valid.getOrDefault("path"))
  result = hook(call_774276, url, valid)

proc call*(call_774277: Call_ListBuckets_774272): Recallable =
  ## listBuckets
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  result = call_774277.call(nil, nil, nil, nil, nil)

var listBuckets* = Call_ListBuckets_774272(name: "listBuckets",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com", route: "/",
                                        validator: validate_ListBuckets_774273,
                                        base: "/", url: url_ListBuckets_774274,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultipartUploads_774278 = ref object of OpenApiRestCall_772597
proc url_ListMultipartUploads_774280(protocol: Scheme; host: string; base: string;
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

proc validate_ListMultipartUploads_774279(path: JsonNode; query: JsonNode;
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
  var valid_774281 = path.getOrDefault("Bucket")
  valid_774281 = validateParameter(valid_774281, JString, required = true,
                                 default = nil)
  if valid_774281 != nil:
    section.add "Bucket", valid_774281
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
  var valid_774282 = query.getOrDefault("max-uploads")
  valid_774282 = validateParameter(valid_774282, JInt, required = false, default = nil)
  if valid_774282 != nil:
    section.add "max-uploads", valid_774282
  var valid_774283 = query.getOrDefault("key-marker")
  valid_774283 = validateParameter(valid_774283, JString, required = false,
                                 default = nil)
  if valid_774283 != nil:
    section.add "key-marker", valid_774283
  var valid_774284 = query.getOrDefault("encoding-type")
  valid_774284 = validateParameter(valid_774284, JString, required = false,
                                 default = newJString("url"))
  if valid_774284 != nil:
    section.add "encoding-type", valid_774284
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_774285 = query.getOrDefault("uploads")
  valid_774285 = validateParameter(valid_774285, JBool, required = true, default = nil)
  if valid_774285 != nil:
    section.add "uploads", valid_774285
  var valid_774286 = query.getOrDefault("MaxUploads")
  valid_774286 = validateParameter(valid_774286, JString, required = false,
                                 default = nil)
  if valid_774286 != nil:
    section.add "MaxUploads", valid_774286
  var valid_774287 = query.getOrDefault("delimiter")
  valid_774287 = validateParameter(valid_774287, JString, required = false,
                                 default = nil)
  if valid_774287 != nil:
    section.add "delimiter", valid_774287
  var valid_774288 = query.getOrDefault("prefix")
  valid_774288 = validateParameter(valid_774288, JString, required = false,
                                 default = nil)
  if valid_774288 != nil:
    section.add "prefix", valid_774288
  var valid_774289 = query.getOrDefault("upload-id-marker")
  valid_774289 = validateParameter(valid_774289, JString, required = false,
                                 default = nil)
  if valid_774289 != nil:
    section.add "upload-id-marker", valid_774289
  var valid_774290 = query.getOrDefault("KeyMarker")
  valid_774290 = validateParameter(valid_774290, JString, required = false,
                                 default = nil)
  if valid_774290 != nil:
    section.add "KeyMarker", valid_774290
  var valid_774291 = query.getOrDefault("UploadIdMarker")
  valid_774291 = validateParameter(valid_774291, JString, required = false,
                                 default = nil)
  if valid_774291 != nil:
    section.add "UploadIdMarker", valid_774291
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774292 = header.getOrDefault("x-amz-security-token")
  valid_774292 = validateParameter(valid_774292, JString, required = false,
                                 default = nil)
  if valid_774292 != nil:
    section.add "x-amz-security-token", valid_774292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774293: Call_ListMultipartUploads_774278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists in-progress multipart uploads.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
  let valid = call_774293.validator(path, query, header, formData, body)
  let scheme = call_774293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774293.url(scheme.get, call_774293.host, call_774293.base,
                         call_774293.route, valid.getOrDefault("path"))
  result = hook(call_774293, url, valid)

proc call*(call_774294: Call_ListMultipartUploads_774278; uploads: bool;
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
  var path_774295 = newJObject()
  var query_774296 = newJObject()
  add(query_774296, "max-uploads", newJInt(maxUploads))
  add(query_774296, "key-marker", newJString(keyMarker))
  add(query_774296, "encoding-type", newJString(encodingType))
  add(query_774296, "uploads", newJBool(uploads))
  add(query_774296, "MaxUploads", newJString(MaxUploads))
  add(query_774296, "delimiter", newJString(delimiter))
  add(path_774295, "Bucket", newJString(Bucket))
  add(query_774296, "prefix", newJString(prefix))
  add(query_774296, "upload-id-marker", newJString(uploadIdMarker))
  add(query_774296, "KeyMarker", newJString(KeyMarker))
  add(query_774296, "UploadIdMarker", newJString(UploadIdMarker))
  result = call_774294.call(path_774295, query_774296, nil, nil, nil)

var listMultipartUploads* = Call_ListMultipartUploads_774278(
    name: "listMultipartUploads", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#uploads",
    validator: validate_ListMultipartUploads_774279, base: "/",
    url: url_ListMultipartUploads_774280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectVersions_774297 = ref object of OpenApiRestCall_772597
proc url_ListObjectVersions_774299(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectVersions_774298(path: JsonNode; query: JsonNode;
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
  var valid_774300 = path.getOrDefault("Bucket")
  valid_774300 = validateParameter(valid_774300, JString, required = true,
                                 default = nil)
  if valid_774300 != nil:
    section.add "Bucket", valid_774300
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
  var valid_774301 = query.getOrDefault("key-marker")
  valid_774301 = validateParameter(valid_774301, JString, required = false,
                                 default = nil)
  if valid_774301 != nil:
    section.add "key-marker", valid_774301
  var valid_774302 = query.getOrDefault("max-keys")
  valid_774302 = validateParameter(valid_774302, JInt, required = false, default = nil)
  if valid_774302 != nil:
    section.add "max-keys", valid_774302
  var valid_774303 = query.getOrDefault("VersionIdMarker")
  valid_774303 = validateParameter(valid_774303, JString, required = false,
                                 default = nil)
  if valid_774303 != nil:
    section.add "VersionIdMarker", valid_774303
  assert query != nil,
        "query argument is necessary due to required `versions` field"
  var valid_774304 = query.getOrDefault("versions")
  valid_774304 = validateParameter(valid_774304, JBool, required = true, default = nil)
  if valid_774304 != nil:
    section.add "versions", valid_774304
  var valid_774305 = query.getOrDefault("encoding-type")
  valid_774305 = validateParameter(valid_774305, JString, required = false,
                                 default = newJString("url"))
  if valid_774305 != nil:
    section.add "encoding-type", valid_774305
  var valid_774306 = query.getOrDefault("version-id-marker")
  valid_774306 = validateParameter(valid_774306, JString, required = false,
                                 default = nil)
  if valid_774306 != nil:
    section.add "version-id-marker", valid_774306
  var valid_774307 = query.getOrDefault("delimiter")
  valid_774307 = validateParameter(valid_774307, JString, required = false,
                                 default = nil)
  if valid_774307 != nil:
    section.add "delimiter", valid_774307
  var valid_774308 = query.getOrDefault("prefix")
  valid_774308 = validateParameter(valid_774308, JString, required = false,
                                 default = nil)
  if valid_774308 != nil:
    section.add "prefix", valid_774308
  var valid_774309 = query.getOrDefault("MaxKeys")
  valid_774309 = validateParameter(valid_774309, JString, required = false,
                                 default = nil)
  if valid_774309 != nil:
    section.add "MaxKeys", valid_774309
  var valid_774310 = query.getOrDefault("KeyMarker")
  valid_774310 = validateParameter(valid_774310, JString, required = false,
                                 default = nil)
  if valid_774310 != nil:
    section.add "KeyMarker", valid_774310
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_774311 = header.getOrDefault("x-amz-security-token")
  valid_774311 = validateParameter(valid_774311, JString, required = false,
                                 default = nil)
  if valid_774311 != nil:
    section.add "x-amz-security-token", valid_774311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774312: Call_ListObjectVersions_774297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about all of the versions of objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
  let valid = call_774312.validator(path, query, header, formData, body)
  let scheme = call_774312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774312.url(scheme.get, call_774312.host, call_774312.base,
                         call_774312.route, valid.getOrDefault("path"))
  result = hook(call_774312, url, valid)

proc call*(call_774313: Call_ListObjectVersions_774297; versions: bool;
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
  var path_774314 = newJObject()
  var query_774315 = newJObject()
  add(query_774315, "key-marker", newJString(keyMarker))
  add(query_774315, "max-keys", newJInt(maxKeys))
  add(query_774315, "VersionIdMarker", newJString(VersionIdMarker))
  add(query_774315, "versions", newJBool(versions))
  add(query_774315, "encoding-type", newJString(encodingType))
  add(query_774315, "version-id-marker", newJString(versionIdMarker))
  add(query_774315, "delimiter", newJString(delimiter))
  add(path_774314, "Bucket", newJString(Bucket))
  add(query_774315, "prefix", newJString(prefix))
  add(query_774315, "MaxKeys", newJString(MaxKeys))
  add(query_774315, "KeyMarker", newJString(KeyMarker))
  result = call_774313.call(path_774314, query_774315, nil, nil, nil)

var listObjectVersions* = Call_ListObjectVersions_774297(
    name: "listObjectVersions", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versions", validator: validate_ListObjectVersions_774298,
    base: "/", url: url_ListObjectVersions_774299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectsV2_774316 = ref object of OpenApiRestCall_772597
proc url_ListObjectsV2_774318(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectsV2_774317(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774319 = path.getOrDefault("Bucket")
  valid_774319 = validateParameter(valid_774319, JString, required = true,
                                 default = nil)
  if valid_774319 != nil:
    section.add "Bucket", valid_774319
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
  var valid_774320 = query.getOrDefault("list-type")
  valid_774320 = validateParameter(valid_774320, JString, required = true,
                                 default = newJString("2"))
  if valid_774320 != nil:
    section.add "list-type", valid_774320
  var valid_774321 = query.getOrDefault("max-keys")
  valid_774321 = validateParameter(valid_774321, JInt, required = false, default = nil)
  if valid_774321 != nil:
    section.add "max-keys", valid_774321
  var valid_774322 = query.getOrDefault("encoding-type")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = newJString("url"))
  if valid_774322 != nil:
    section.add "encoding-type", valid_774322
  var valid_774323 = query.getOrDefault("continuation-token")
  valid_774323 = validateParameter(valid_774323, JString, required = false,
                                 default = nil)
  if valid_774323 != nil:
    section.add "continuation-token", valid_774323
  var valid_774324 = query.getOrDefault("fetch-owner")
  valid_774324 = validateParameter(valid_774324, JBool, required = false, default = nil)
  if valid_774324 != nil:
    section.add "fetch-owner", valid_774324
  var valid_774325 = query.getOrDefault("delimiter")
  valid_774325 = validateParameter(valid_774325, JString, required = false,
                                 default = nil)
  if valid_774325 != nil:
    section.add "delimiter", valid_774325
  var valid_774326 = query.getOrDefault("start-after")
  valid_774326 = validateParameter(valid_774326, JString, required = false,
                                 default = nil)
  if valid_774326 != nil:
    section.add "start-after", valid_774326
  var valid_774327 = query.getOrDefault("ContinuationToken")
  valid_774327 = validateParameter(valid_774327, JString, required = false,
                                 default = nil)
  if valid_774327 != nil:
    section.add "ContinuationToken", valid_774327
  var valid_774328 = query.getOrDefault("prefix")
  valid_774328 = validateParameter(valid_774328, JString, required = false,
                                 default = nil)
  if valid_774328 != nil:
    section.add "prefix", valid_774328
  var valid_774329 = query.getOrDefault("MaxKeys")
  valid_774329 = validateParameter(valid_774329, JString, required = false,
                                 default = nil)
  if valid_774329 != nil:
    section.add "MaxKeys", valid_774329
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_774330 = header.getOrDefault("x-amz-security-token")
  valid_774330 = validateParameter(valid_774330, JString, required = false,
                                 default = nil)
  if valid_774330 != nil:
    section.add "x-amz-security-token", valid_774330
  var valid_774331 = header.getOrDefault("x-amz-request-payer")
  valid_774331 = validateParameter(valid_774331, JString, required = false,
                                 default = newJString("requester"))
  if valid_774331 != nil:
    section.add "x-amz-request-payer", valid_774331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774332: Call_ListObjectsV2_774316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. Note: ListObjectsV2 is the revised List Objects API and we recommend you use this revised API for new application development.
  ## 
  let valid = call_774332.validator(path, query, header, formData, body)
  let scheme = call_774332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774332.url(scheme.get, call_774332.host, call_774332.base,
                         call_774332.route, valid.getOrDefault("path"))
  result = hook(call_774332, url, valid)

proc call*(call_774333: Call_ListObjectsV2_774316; Bucket: string;
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
  var path_774334 = newJObject()
  var query_774335 = newJObject()
  add(query_774335, "list-type", newJString(listType))
  add(query_774335, "max-keys", newJInt(maxKeys))
  add(query_774335, "encoding-type", newJString(encodingType))
  add(query_774335, "continuation-token", newJString(continuationToken))
  add(query_774335, "fetch-owner", newJBool(fetchOwner))
  add(query_774335, "delimiter", newJString(delimiter))
  add(path_774334, "Bucket", newJString(Bucket))
  add(query_774335, "start-after", newJString(startAfter))
  add(query_774335, "ContinuationToken", newJString(ContinuationToken))
  add(query_774335, "prefix", newJString(prefix))
  add(query_774335, "MaxKeys", newJString(MaxKeys))
  result = call_774333.call(path_774334, query_774335, nil, nil, nil)

var listObjectsV2* = Call_ListObjectsV2_774316(name: "listObjectsV2",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#list-type=2", validator: validate_ListObjectsV2_774317,
    base: "/", url: url_ListObjectsV2_774318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreObject_774336 = ref object of OpenApiRestCall_772597
proc url_RestoreObject_774338(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreObject_774337(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774339 = path.getOrDefault("Key")
  valid_774339 = validateParameter(valid_774339, JString, required = true,
                                 default = nil)
  if valid_774339 != nil:
    section.add "Key", valid_774339
  var valid_774340 = path.getOrDefault("Bucket")
  valid_774340 = validateParameter(valid_774340, JString, required = true,
                                 default = nil)
  if valid_774340 != nil:
    section.add "Bucket", valid_774340
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   restore: JBool (required)
  section = newJObject()
  var valid_774341 = query.getOrDefault("versionId")
  valid_774341 = validateParameter(valid_774341, JString, required = false,
                                 default = nil)
  if valid_774341 != nil:
    section.add "versionId", valid_774341
  assert query != nil, "query argument is necessary due to required `restore` field"
  var valid_774342 = query.getOrDefault("restore")
  valid_774342 = validateParameter(valid_774342, JBool, required = true, default = nil)
  if valid_774342 != nil:
    section.add "restore", valid_774342
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_774343 = header.getOrDefault("x-amz-security-token")
  valid_774343 = validateParameter(valid_774343, JString, required = false,
                                 default = nil)
  if valid_774343 != nil:
    section.add "x-amz-security-token", valid_774343
  var valid_774344 = header.getOrDefault("x-amz-request-payer")
  valid_774344 = validateParameter(valid_774344, JString, required = false,
                                 default = newJString("requester"))
  if valid_774344 != nil:
    section.add "x-amz-request-payer", valid_774344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774346: Call_RestoreObject_774336; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restores an archived copy of an object back into Amazon S3
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  let valid = call_774346.validator(path, query, header, formData, body)
  let scheme = call_774346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774346.url(scheme.get, call_774346.host, call_774346.base,
                         call_774346.route, valid.getOrDefault("path"))
  result = hook(call_774346, url, valid)

proc call*(call_774347: Call_RestoreObject_774336; Key: string; restore: bool;
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
  var path_774348 = newJObject()
  var query_774349 = newJObject()
  var body_774350 = newJObject()
  add(query_774349, "versionId", newJString(versionId))
  add(path_774348, "Key", newJString(Key))
  add(query_774349, "restore", newJBool(restore))
  add(path_774348, "Bucket", newJString(Bucket))
  if body != nil:
    body_774350 = body
  result = call_774347.call(path_774348, query_774349, nil, nil, body_774350)

var restoreObject* = Call_RestoreObject_774336(name: "restoreObject",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#restore", validator: validate_RestoreObject_774337,
    base: "/", url: url_RestoreObject_774338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SelectObjectContent_774351 = ref object of OpenApiRestCall_772597
proc url_SelectObjectContent_774353(protocol: Scheme; host: string; base: string;
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

proc validate_SelectObjectContent_774352(path: JsonNode; query: JsonNode;
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
  var valid_774354 = path.getOrDefault("Key")
  valid_774354 = validateParameter(valid_774354, JString, required = true,
                                 default = nil)
  if valid_774354 != nil:
    section.add "Key", valid_774354
  var valid_774355 = path.getOrDefault("Bucket")
  valid_774355 = validateParameter(valid_774355, JString, required = true,
                                 default = nil)
  if valid_774355 != nil:
    section.add "Bucket", valid_774355
  result.add "path", section
  ## parameters in `query` object:
  ##   select: JBool (required)
  ##   select-type: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `select` field"
  var valid_774356 = query.getOrDefault("select")
  valid_774356 = validateParameter(valid_774356, JBool, required = true, default = nil)
  if valid_774356 != nil:
    section.add "select", valid_774356
  var valid_774357 = query.getOrDefault("select-type")
  valid_774357 = validateParameter(valid_774357, JString, required = true,
                                 default = newJString("2"))
  if valid_774357 != nil:
    section.add "select-type", valid_774357
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
  var valid_774358 = header.getOrDefault("x-amz-security-token")
  valid_774358 = validateParameter(valid_774358, JString, required = false,
                                 default = nil)
  if valid_774358 != nil:
    section.add "x-amz-security-token", valid_774358
  var valid_774359 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_774359 = validateParameter(valid_774359, JString, required = false,
                                 default = nil)
  if valid_774359 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_774359
  var valid_774360 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_774360 = validateParameter(valid_774360, JString, required = false,
                                 default = nil)
  if valid_774360 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_774360
  var valid_774361 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_774361 = validateParameter(valid_774361, JString, required = false,
                                 default = nil)
  if valid_774361 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_774361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774363: Call_SelectObjectContent_774351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ## 
  let valid = call_774363.validator(path, query, header, formData, body)
  let scheme = call_774363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774363.url(scheme.get, call_774363.host, call_774363.base,
                         call_774363.route, valid.getOrDefault("path"))
  result = hook(call_774363, url, valid)

proc call*(call_774364: Call_SelectObjectContent_774351; select: bool; Key: string;
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
  var path_774365 = newJObject()
  var query_774366 = newJObject()
  var body_774367 = newJObject()
  add(query_774366, "select", newJBool(select))
  add(path_774365, "Key", newJString(Key))
  add(path_774365, "Bucket", newJString(Bucket))
  if body != nil:
    body_774367 = body
  add(query_774366, "select-type", newJString(selectType))
  result = call_774364.call(path_774365, query_774366, nil, nil, body_774367)

var selectObjectContent* = Call_SelectObjectContent_774351(
    name: "selectObjectContent", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#select&select-type=2",
    validator: validate_SelectObjectContent_774352, base: "/",
    url: url_SelectObjectContent_774353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPart_774368 = ref object of OpenApiRestCall_772597
proc url_UploadPart_774370(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UploadPart_774369(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774371 = path.getOrDefault("Key")
  valid_774371 = validateParameter(valid_774371, JString, required = true,
                                 default = nil)
  if valid_774371 != nil:
    section.add "Key", valid_774371
  var valid_774372 = path.getOrDefault("Bucket")
  valid_774372 = validateParameter(valid_774372, JString, required = true,
                                 default = nil)
  if valid_774372 != nil:
    section.add "Bucket", valid_774372
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being uploaded.
  ##   partNumber: JInt (required)
  ##             : Part number of part being uploaded. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_774373 = query.getOrDefault("uploadId")
  valid_774373 = validateParameter(valid_774373, JString, required = true,
                                 default = nil)
  if valid_774373 != nil:
    section.add "uploadId", valid_774373
  var valid_774374 = query.getOrDefault("partNumber")
  valid_774374 = validateParameter(valid_774374, JInt, required = true, default = nil)
  if valid_774374 != nil:
    section.add "partNumber", valid_774374
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
  var valid_774375 = header.getOrDefault("x-amz-security-token")
  valid_774375 = validateParameter(valid_774375, JString, required = false,
                                 default = nil)
  if valid_774375 != nil:
    section.add "x-amz-security-token", valid_774375
  var valid_774376 = header.getOrDefault("Content-MD5")
  valid_774376 = validateParameter(valid_774376, JString, required = false,
                                 default = nil)
  if valid_774376 != nil:
    section.add "Content-MD5", valid_774376
  var valid_774377 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_774377
  var valid_774378 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_774378 = validateParameter(valid_774378, JString, required = false,
                                 default = nil)
  if valid_774378 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_774378
  var valid_774379 = header.getOrDefault("Content-Length")
  valid_774379 = validateParameter(valid_774379, JInt, required = false, default = nil)
  if valid_774379 != nil:
    section.add "Content-Length", valid_774379
  var valid_774380 = header.getOrDefault("x-amz-request-payer")
  valid_774380 = validateParameter(valid_774380, JString, required = false,
                                 default = newJString("requester"))
  if valid_774380 != nil:
    section.add "x-amz-request-payer", valid_774380
  var valid_774381 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_774381 = validateParameter(valid_774381, JString, required = false,
                                 default = nil)
  if valid_774381 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_774381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774383: Call_UploadPart_774368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  let valid = call_774383.validator(path, query, header, formData, body)
  let scheme = call_774383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774383.url(scheme.get, call_774383.host, call_774383.base,
                         call_774383.route, valid.getOrDefault("path"))
  result = hook(call_774383, url, valid)

proc call*(call_774384: Call_UploadPart_774368; uploadId: string; partNumber: int;
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
  var path_774385 = newJObject()
  var query_774386 = newJObject()
  var body_774387 = newJObject()
  add(query_774386, "uploadId", newJString(uploadId))
  add(query_774386, "partNumber", newJInt(partNumber))
  add(path_774385, "Key", newJString(Key))
  add(path_774385, "Bucket", newJString(Bucket))
  if body != nil:
    body_774387 = body
  result = call_774384.call(path_774385, query_774386, nil, nil, body_774387)

var uploadPart* = Call_UploadPart_774368(name: "uploadPart",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#partNumber&uploadId",
                                      validator: validate_UploadPart_774369,
                                      base: "/", url: url_UploadPart_774370,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPartCopy_774388 = ref object of OpenApiRestCall_772597
proc url_UploadPartCopy_774390(protocol: Scheme; host: string; base: string;
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

proc validate_UploadPartCopy_774389(path: JsonNode; query: JsonNode;
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
  var valid_774391 = path.getOrDefault("Key")
  valid_774391 = validateParameter(valid_774391, JString, required = true,
                                 default = nil)
  if valid_774391 != nil:
    section.add "Key", valid_774391
  var valid_774392 = path.getOrDefault("Bucket")
  valid_774392 = validateParameter(valid_774392, JString, required = true,
                                 default = nil)
  if valid_774392 != nil:
    section.add "Bucket", valid_774392
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being copied.
  ##   partNumber: JInt (required)
  ##             : Part number of part being copied. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_774393 = query.getOrDefault("uploadId")
  valid_774393 = validateParameter(valid_774393, JString, required = true,
                                 default = nil)
  if valid_774393 != nil:
    section.add "uploadId", valid_774393
  var valid_774394 = query.getOrDefault("partNumber")
  valid_774394 = validateParameter(valid_774394, JInt, required = true, default = nil)
  if valid_774394 != nil:
    section.add "partNumber", valid_774394
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
  var valid_774395 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_774395 = validateParameter(valid_774395, JString, required = false,
                                 default = nil)
  if valid_774395 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_774395
  var valid_774396 = header.getOrDefault("x-amz-security-token")
  valid_774396 = validateParameter(valid_774396, JString, required = false,
                                 default = nil)
  if valid_774396 != nil:
    section.add "x-amz-security-token", valid_774396
  var valid_774397 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_774397 = validateParameter(valid_774397, JString, required = false,
                                 default = nil)
  if valid_774397 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_774397
  var valid_774398 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_774398 = validateParameter(valid_774398, JString, required = false,
                                 default = nil)
  if valid_774398 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_774398
  var valid_774399 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_774399 = validateParameter(valid_774399, JString, required = false,
                                 default = nil)
  if valid_774399 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_774399
  var valid_774400 = header.getOrDefault("x-amz-copy-source-range")
  valid_774400 = validateParameter(valid_774400, JString, required = false,
                                 default = nil)
  if valid_774400 != nil:
    section.add "x-amz-copy-source-range", valid_774400
  var valid_774401 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_774401 = validateParameter(valid_774401, JString, required = false,
                                 default = nil)
  if valid_774401 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_774401
  var valid_774402 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_774402 = validateParameter(valid_774402, JString, required = false,
                                 default = nil)
  if valid_774402 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_774402
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_774403 = header.getOrDefault("x-amz-copy-source")
  valid_774403 = validateParameter(valid_774403, JString, required = true,
                                 default = nil)
  if valid_774403 != nil:
    section.add "x-amz-copy-source", valid_774403
  var valid_774404 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_774404 = validateParameter(valid_774404, JString, required = false,
                                 default = nil)
  if valid_774404 != nil:
    section.add "x-amz-copy-source-if-match", valid_774404
  var valid_774405 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_774405 = validateParameter(valid_774405, JString, required = false,
                                 default = nil)
  if valid_774405 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_774405
  var valid_774406 = header.getOrDefault("x-amz-request-payer")
  valid_774406 = validateParameter(valid_774406, JString, required = false,
                                 default = newJString("requester"))
  if valid_774406 != nil:
    section.add "x-amz-request-payer", valid_774406
  var valid_774407 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_774407 = validateParameter(valid_774407, JString, required = false,
                                 default = nil)
  if valid_774407 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_774407
  var valid_774408 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_774408 = validateParameter(valid_774408, JString, required = false,
                                 default = nil)
  if valid_774408 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_774408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774409: Call_UploadPartCopy_774388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads a part by copying data from an existing object as data source.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  let valid = call_774409.validator(path, query, header, formData, body)
  let scheme = call_774409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774409.url(scheme.get, call_774409.host, call_774409.base,
                         call_774409.route, valid.getOrDefault("path"))
  result = hook(call_774409, url, valid)

proc call*(call_774410: Call_UploadPartCopy_774388; uploadId: string;
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
  var path_774411 = newJObject()
  var query_774412 = newJObject()
  add(query_774412, "uploadId", newJString(uploadId))
  add(query_774412, "partNumber", newJInt(partNumber))
  add(path_774411, "Key", newJString(Key))
  add(path_774411, "Bucket", newJString(Bucket))
  result = call_774410.call(path_774411, query_774412, nil, nil, nil)

var uploadPartCopy* = Call_UploadPartCopy_774388(name: "uploadPartCopy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#x-amz-copy-source&partNumber&uploadId",
    validator: validate_UploadPartCopy_774389, base: "/", url: url_UploadPartCopy_774390,
    schemes: {Scheme.Https, Scheme.Http})
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
