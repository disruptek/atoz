
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CompleteMultipartUpload_603055 = ref object of OpenApiRestCall_602433
proc url_CompleteMultipartUpload_603057(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CompleteMultipartUpload_603056(path: JsonNode; query: JsonNode;
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
  var valid_603058 = path.getOrDefault("Key")
  valid_603058 = validateParameter(valid_603058, JString, required = true,
                                 default = nil)
  if valid_603058 != nil:
    section.add "Key", valid_603058
  var valid_603059 = path.getOrDefault("Bucket")
  valid_603059 = validateParameter(valid_603059, JString, required = true,
                                 default = nil)
  if valid_603059 != nil:
    section.add "Bucket", valid_603059
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : <p/>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_603060 = query.getOrDefault("uploadId")
  valid_603060 = validateParameter(valid_603060, JString, required = true,
                                 default = nil)
  if valid_603060 != nil:
    section.add "uploadId", valid_603060
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_603061 = header.getOrDefault("x-amz-security-token")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "x-amz-security-token", valid_603061
  var valid_603062 = header.getOrDefault("x-amz-request-payer")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = newJString("requester"))
  if valid_603062 != nil:
    section.add "x-amz-request-payer", valid_603062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603064: Call_CompleteMultipartUpload_603055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  let valid = call_603064.validator(path, query, header, formData, body)
  let scheme = call_603064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603064.url(scheme.get, call_603064.host, call_603064.base,
                         call_603064.route, valid.getOrDefault("path"))
  result = hook(call_603064, url, valid)

proc call*(call_603065: Call_CompleteMultipartUpload_603055; uploadId: string;
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
  var path_603066 = newJObject()
  var query_603067 = newJObject()
  var body_603068 = newJObject()
  add(query_603067, "uploadId", newJString(uploadId))
  add(path_603066, "Key", newJString(Key))
  add(path_603066, "Bucket", newJString(Bucket))
  if body != nil:
    body_603068 = body
  result = call_603065.call(path_603066, query_603067, nil, nil, body_603068)

var completeMultipartUpload* = Call_CompleteMultipartUpload_603055(
    name: "completeMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_CompleteMultipartUpload_603056, base: "/",
    url: url_CompleteMultipartUpload_603057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParts_602770 = ref object of OpenApiRestCall_602433
proc url_ListParts_602772(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListParts_602771(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602898 = path.getOrDefault("Key")
  valid_602898 = validateParameter(valid_602898, JString, required = true,
                                 default = nil)
  if valid_602898 != nil:
    section.add "Key", valid_602898
  var valid_602899 = path.getOrDefault("Bucket")
  valid_602899 = validateParameter(valid_602899, JString, required = true,
                                 default = nil)
  if valid_602899 != nil:
    section.add "Bucket", valid_602899
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
  var valid_602900 = query.getOrDefault("max-parts")
  valid_602900 = validateParameter(valid_602900, JInt, required = false, default = nil)
  if valid_602900 != nil:
    section.add "max-parts", valid_602900
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_602901 = query.getOrDefault("uploadId")
  valid_602901 = validateParameter(valid_602901, JString, required = true,
                                 default = nil)
  if valid_602901 != nil:
    section.add "uploadId", valid_602901
  var valid_602902 = query.getOrDefault("MaxParts")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "MaxParts", valid_602902
  var valid_602903 = query.getOrDefault("part-number-marker")
  valid_602903 = validateParameter(valid_602903, JInt, required = false, default = nil)
  if valid_602903 != nil:
    section.add "part-number-marker", valid_602903
  var valid_602904 = query.getOrDefault("PartNumberMarker")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "PartNumberMarker", valid_602904
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_602905 = header.getOrDefault("x-amz-security-token")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "x-amz-security-token", valid_602905
  var valid_602919 = header.getOrDefault("x-amz-request-payer")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = newJString("requester"))
  if valid_602919 != nil:
    section.add "x-amz-request-payer", valid_602919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602942: Call_ListParts_602770; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  let valid = call_602942.validator(path, query, header, formData, body)
  let scheme = call_602942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602942.url(scheme.get, call_602942.host, call_602942.base,
                         call_602942.route, valid.getOrDefault("path"))
  result = hook(call_602942, url, valid)

proc call*(call_603013: Call_ListParts_602770; uploadId: string; Key: string;
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
  var path_603014 = newJObject()
  var query_603016 = newJObject()
  add(query_603016, "max-parts", newJInt(maxParts))
  add(query_603016, "uploadId", newJString(uploadId))
  add(query_603016, "MaxParts", newJString(MaxParts))
  add(query_603016, "part-number-marker", newJInt(partNumberMarker))
  add(query_603016, "PartNumberMarker", newJString(PartNumberMarker))
  add(path_603014, "Key", newJString(Key))
  add(path_603014, "Bucket", newJString(Bucket))
  result = call_603013.call(path_603014, query_603016, nil, nil, nil)

var listParts* = Call_ListParts_602770(name: "listParts", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}#uploadId",
                                    validator: validate_ListParts_602771,
                                    base: "/", url: url_ListParts_602772,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortMultipartUpload_603069 = ref object of OpenApiRestCall_602433
proc url_AbortMultipartUpload_603071(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_AbortMultipartUpload_603070(path: JsonNode; query: JsonNode;
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
  var valid_603072 = path.getOrDefault("Key")
  valid_603072 = validateParameter(valid_603072, JString, required = true,
                                 default = nil)
  if valid_603072 != nil:
    section.add "Key", valid_603072
  var valid_603073 = path.getOrDefault("Bucket")
  valid_603073 = validateParameter(valid_603073, JString, required = true,
                                 default = nil)
  if valid_603073 != nil:
    section.add "Bucket", valid_603073
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID that identifies the multipart upload.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_603074 = query.getOrDefault("uploadId")
  valid_603074 = validateParameter(valid_603074, JString, required = true,
                                 default = nil)
  if valid_603074 != nil:
    section.add "uploadId", valid_603074
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_603075 = header.getOrDefault("x-amz-security-token")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "x-amz-security-token", valid_603075
  var valid_603076 = header.getOrDefault("x-amz-request-payer")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = newJString("requester"))
  if valid_603076 != nil:
    section.add "x-amz-request-payer", valid_603076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603077: Call_AbortMultipartUpload_603069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  let valid = call_603077.validator(path, query, header, formData, body)
  let scheme = call_603077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603077.url(scheme.get, call_603077.host, call_603077.base,
                         call_603077.route, valid.getOrDefault("path"))
  result = hook(call_603077, url, valid)

proc call*(call_603078: Call_AbortMultipartUpload_603069; uploadId: string;
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
  var path_603079 = newJObject()
  var query_603080 = newJObject()
  add(query_603080, "uploadId", newJString(uploadId))
  add(path_603079, "Key", newJString(Key))
  add(path_603079, "Bucket", newJString(Bucket))
  result = call_603078.call(path_603079, query_603080, nil, nil, nil)

var abortMultipartUpload* = Call_AbortMultipartUpload_603069(
    name: "abortMultipartUpload", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_AbortMultipartUpload_603070, base: "/",
    url: url_AbortMultipartUpload_603071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyObject_603081 = ref object of OpenApiRestCall_602433
proc url_CopyObject_603083(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CopyObject_603082(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603084 = path.getOrDefault("Key")
  valid_603084 = validateParameter(valid_603084, JString, required = true,
                                 default = nil)
  if valid_603084 != nil:
    section.add "Key", valid_603084
  var valid_603085 = path.getOrDefault("Bucket")
  valid_603085 = validateParameter(valid_603085, JString, required = true,
                                 default = nil)
  if valid_603085 != nil:
    section.add "Bucket", valid_603085
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
  var valid_603086 = header.getOrDefault("Content-Disposition")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "Content-Disposition", valid_603086
  var valid_603087 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_603087
  var valid_603088 = header.getOrDefault("x-amz-grant-full-control")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "x-amz-grant-full-control", valid_603088
  var valid_603089 = header.getOrDefault("x-amz-security-token")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "x-amz-security-token", valid_603089
  var valid_603090 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_603090
  var valid_603091 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_603091
  var valid_603092 = header.getOrDefault("x-amz-tagging-directive")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = newJString("COPY"))
  if valid_603092 != nil:
    section.add "x-amz-tagging-directive", valid_603092
  var valid_603093 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_603093
  var valid_603094 = header.getOrDefault("x-amz-object-lock-mode")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_603094 != nil:
    section.add "x-amz-object-lock-mode", valid_603094
  var valid_603095 = header.getOrDefault("Cache-Control")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "Cache-Control", valid_603095
  var valid_603096 = header.getOrDefault("Content-Language")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "Content-Language", valid_603096
  var valid_603097 = header.getOrDefault("Content-Type")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "Content-Type", valid_603097
  var valid_603098 = header.getOrDefault("Expires")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "Expires", valid_603098
  var valid_603099 = header.getOrDefault("x-amz-website-redirect-location")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "x-amz-website-redirect-location", valid_603099
  var valid_603100 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_603100
  var valid_603101 = header.getOrDefault("x-amz-acl")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = newJString("private"))
  if valid_603101 != nil:
    section.add "x-amz-acl", valid_603101
  var valid_603102 = header.getOrDefault("x-amz-grant-read")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "x-amz-grant-read", valid_603102
  var valid_603103 = header.getOrDefault("x-amz-storage-class")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_603103 != nil:
    section.add "x-amz-storage-class", valid_603103
  var valid_603104 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = newJString("ON"))
  if valid_603104 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_603104
  var valid_603105 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_603105
  var valid_603106 = header.getOrDefault("x-amz-tagging")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "x-amz-tagging", valid_603106
  var valid_603107 = header.getOrDefault("x-amz-grant-read-acp")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "x-amz-grant-read-acp", valid_603107
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_603108 = header.getOrDefault("x-amz-copy-source")
  valid_603108 = validateParameter(valid_603108, JString, required = true,
                                 default = nil)
  if valid_603108 != nil:
    section.add "x-amz-copy-source", valid_603108
  var valid_603109 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "x-amz-server-side-encryption-context", valid_603109
  var valid_603110 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_603110
  var valid_603111 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_603111
  var valid_603112 = header.getOrDefault("x-amz-metadata-directive")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = newJString("COPY"))
  if valid_603112 != nil:
    section.add "x-amz-metadata-directive", valid_603112
  var valid_603113 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "x-amz-copy-source-if-match", valid_603113
  var valid_603114 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_603114
  var valid_603115 = header.getOrDefault("x-amz-grant-write-acp")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "x-amz-grant-write-acp", valid_603115
  var valid_603116 = header.getOrDefault("Content-Encoding")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "Content-Encoding", valid_603116
  var valid_603117 = header.getOrDefault("x-amz-request-payer")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = newJString("requester"))
  if valid_603117 != nil:
    section.add "x-amz-request-payer", valid_603117
  var valid_603118 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_603118
  var valid_603119 = header.getOrDefault("x-amz-server-side-encryption")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = newJString("AES256"))
  if valid_603119 != nil:
    section.add "x-amz-server-side-encryption", valid_603119
  var valid_603120 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_603120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603122: Call_CopyObject_603081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  let valid = call_603122.validator(path, query, header, formData, body)
  let scheme = call_603122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603122.url(scheme.get, call_603122.host, call_603122.base,
                         call_603122.route, valid.getOrDefault("path"))
  result = hook(call_603122, url, valid)

proc call*(call_603123: Call_CopyObject_603081; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## copyObject
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603124 = newJObject()
  var body_603125 = newJObject()
  add(path_603124, "Key", newJString(Key))
  add(path_603124, "Bucket", newJString(Bucket))
  if body != nil:
    body_603125 = body
  result = call_603123.call(path_603124, nil, nil, nil, body_603125)

var copyObject* = Call_CopyObject_603081(name: "copyObject",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#x-amz-copy-source",
                                      validator: validate_CopyObject_603082,
                                      base: "/", url: url_CopyObject_603083,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBucket_603143 = ref object of OpenApiRestCall_602433
proc url_CreateBucket_603145(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateBucket_603144(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603146 = path.getOrDefault("Bucket")
  valid_603146 = validateParameter(valid_603146, JString, required = true,
                                 default = nil)
  if valid_603146 != nil:
    section.add "Bucket", valid_603146
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
  var valid_603147 = header.getOrDefault("x-amz-security-token")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "x-amz-security-token", valid_603147
  var valid_603148 = header.getOrDefault("x-amz-acl")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = newJString("private"))
  if valid_603148 != nil:
    section.add "x-amz-acl", valid_603148
  var valid_603149 = header.getOrDefault("x-amz-grant-read")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "x-amz-grant-read", valid_603149
  var valid_603150 = header.getOrDefault("x-amz-grant-read-acp")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "x-amz-grant-read-acp", valid_603150
  var valid_603151 = header.getOrDefault("x-amz-bucket-object-lock-enabled")
  valid_603151 = validateParameter(valid_603151, JBool, required = false, default = nil)
  if valid_603151 != nil:
    section.add "x-amz-bucket-object-lock-enabled", valid_603151
  var valid_603152 = header.getOrDefault("x-amz-grant-write")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "x-amz-grant-write", valid_603152
  var valid_603153 = header.getOrDefault("x-amz-grant-write-acp")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "x-amz-grant-write-acp", valid_603153
  var valid_603154 = header.getOrDefault("x-amz-grant-full-control")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "x-amz-grant-full-control", valid_603154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603156: Call_CreateBucket_603143; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"))
  result = hook(call_603156, url, valid)

proc call*(call_603157: Call_CreateBucket_603143; Bucket: string; body: JsonNode): Recallable =
  ## createBucket
  ## Creates a new bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603158 = newJObject()
  var body_603159 = newJObject()
  add(path_603158, "Bucket", newJString(Bucket))
  if body != nil:
    body_603159 = body
  result = call_603157.call(path_603158, nil, nil, nil, body_603159)

var createBucket* = Call_CreateBucket_603143(name: "createBucket",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_CreateBucket_603144, base: "/", url: url_CreateBucket_603145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadBucket_603168 = ref object of OpenApiRestCall_602433
proc url_HeadBucket_603170(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_HeadBucket_603169(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603171 = path.getOrDefault("Bucket")
  valid_603171 = validateParameter(valid_603171, JString, required = true,
                                 default = nil)
  if valid_603171 != nil:
    section.add "Bucket", valid_603171
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603172 = header.getOrDefault("x-amz-security-token")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "x-amz-security-token", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603173: Call_HeadBucket_603168; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  let valid = call_603173.validator(path, query, header, formData, body)
  let scheme = call_603173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603173.url(scheme.get, call_603173.host, call_603173.base,
                         call_603173.route, valid.getOrDefault("path"))
  result = hook(call_603173, url, valid)

proc call*(call_603174: Call_HeadBucket_603168; Bucket: string): Recallable =
  ## headBucket
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603175 = newJObject()
  add(path_603175, "Bucket", newJString(Bucket))
  result = call_603174.call(path_603175, nil, nil, nil, nil)

var headBucket* = Call_HeadBucket_603168(name: "headBucket",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}",
                                      validator: validate_HeadBucket_603169,
                                      base: "/", url: url_HeadBucket_603170,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjects_603126 = ref object of OpenApiRestCall_602433
proc url_ListObjects_603128(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListObjects_603127(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603129 = path.getOrDefault("Bucket")
  valid_603129 = validateParameter(valid_603129, JString, required = true,
                                 default = nil)
  if valid_603129 != nil:
    section.add "Bucket", valid_603129
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
  var valid_603130 = query.getOrDefault("max-keys")
  valid_603130 = validateParameter(valid_603130, JInt, required = false, default = nil)
  if valid_603130 != nil:
    section.add "max-keys", valid_603130
  var valid_603131 = query.getOrDefault("encoding-type")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = newJString("url"))
  if valid_603131 != nil:
    section.add "encoding-type", valid_603131
  var valid_603132 = query.getOrDefault("marker")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "marker", valid_603132
  var valid_603133 = query.getOrDefault("Marker")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "Marker", valid_603133
  var valid_603134 = query.getOrDefault("delimiter")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "delimiter", valid_603134
  var valid_603135 = query.getOrDefault("prefix")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "prefix", valid_603135
  var valid_603136 = query.getOrDefault("MaxKeys")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "MaxKeys", valid_603136
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_603137 = header.getOrDefault("x-amz-security-token")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "x-amz-security-token", valid_603137
  var valid_603138 = header.getOrDefault("x-amz-request-payer")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = newJString("requester"))
  if valid_603138 != nil:
    section.add "x-amz-request-payer", valid_603138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603139: Call_ListObjects_603126; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
  let valid = call_603139.validator(path, query, header, formData, body)
  let scheme = call_603139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603139.url(scheme.get, call_603139.host, call_603139.base,
                         call_603139.route, valid.getOrDefault("path"))
  result = hook(call_603139, url, valid)

proc call*(call_603140: Call_ListObjects_603126; Bucket: string; maxKeys: int = 0;
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
  var path_603141 = newJObject()
  var query_603142 = newJObject()
  add(query_603142, "max-keys", newJInt(maxKeys))
  add(query_603142, "encoding-type", newJString(encodingType))
  add(query_603142, "marker", newJString(marker))
  add(query_603142, "Marker", newJString(Marker))
  add(query_603142, "delimiter", newJString(delimiter))
  add(path_603141, "Bucket", newJString(Bucket))
  add(query_603142, "prefix", newJString(prefix))
  add(query_603142, "MaxKeys", newJString(MaxKeys))
  result = call_603140.call(path_603141, query_603142, nil, nil, nil)

var listObjects* = Call_ListObjects_603126(name: "listObjects",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com",
                                        route: "/{Bucket}",
                                        validator: validate_ListObjects_603127,
                                        base: "/", url: url_ListObjects_603128,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucket_603160 = ref object of OpenApiRestCall_602433
proc url_DeleteBucket_603162(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Bucket" in path, "`Bucket` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Bucket")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBucket_603161(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603163 = path.getOrDefault("Bucket")
  valid_603163 = validateParameter(valid_603163, JString, required = true,
                                 default = nil)
  if valid_603163 != nil:
    section.add "Bucket", valid_603163
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603164 = header.getOrDefault("x-amz-security-token")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "x-amz-security-token", valid_603164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603165: Call_DeleteBucket_603160; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  let valid = call_603165.validator(path, query, header, formData, body)
  let scheme = call_603165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603165.url(scheme.get, call_603165.host, call_603165.base,
                         call_603165.route, valid.getOrDefault("path"))
  result = hook(call_603165, url, valid)

proc call*(call_603166: Call_DeleteBucket_603160; Bucket: string): Recallable =
  ## deleteBucket
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603167 = newJObject()
  add(path_603167, "Bucket", newJString(Bucket))
  result = call_603166.call(path_603167, nil, nil, nil, nil)

var deleteBucket* = Call_DeleteBucket_603160(name: "deleteBucket",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_DeleteBucket_603161, base: "/", url: url_DeleteBucket_603162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultipartUpload_603176 = ref object of OpenApiRestCall_602433
proc url_CreateMultipartUpload_603178(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateMultipartUpload_603177(path: JsonNode; query: JsonNode;
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
  var valid_603179 = path.getOrDefault("Key")
  valid_603179 = validateParameter(valid_603179, JString, required = true,
                                 default = nil)
  if valid_603179 != nil:
    section.add "Key", valid_603179
  var valid_603180 = path.getOrDefault("Bucket")
  valid_603180 = validateParameter(valid_603180, JString, required = true,
                                 default = nil)
  if valid_603180 != nil:
    section.add "Bucket", valid_603180
  result.add "path", section
  ## parameters in `query` object:
  ##   uploads: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_603181 = query.getOrDefault("uploads")
  valid_603181 = validateParameter(valid_603181, JBool, required = true, default = nil)
  if valid_603181 != nil:
    section.add "uploads", valid_603181
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
  var valid_603182 = header.getOrDefault("Content-Disposition")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "Content-Disposition", valid_603182
  var valid_603183 = header.getOrDefault("x-amz-grant-full-control")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "x-amz-grant-full-control", valid_603183
  var valid_603184 = header.getOrDefault("x-amz-security-token")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "x-amz-security-token", valid_603184
  var valid_603185 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_603185
  var valid_603186 = header.getOrDefault("x-amz-object-lock-mode")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_603186 != nil:
    section.add "x-amz-object-lock-mode", valid_603186
  var valid_603187 = header.getOrDefault("Cache-Control")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "Cache-Control", valid_603187
  var valid_603188 = header.getOrDefault("Content-Language")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "Content-Language", valid_603188
  var valid_603189 = header.getOrDefault("Content-Type")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "Content-Type", valid_603189
  var valid_603190 = header.getOrDefault("Expires")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "Expires", valid_603190
  var valid_603191 = header.getOrDefault("x-amz-website-redirect-location")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "x-amz-website-redirect-location", valid_603191
  var valid_603192 = header.getOrDefault("x-amz-acl")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = newJString("private"))
  if valid_603192 != nil:
    section.add "x-amz-acl", valid_603192
  var valid_603193 = header.getOrDefault("x-amz-grant-read")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "x-amz-grant-read", valid_603193
  var valid_603194 = header.getOrDefault("x-amz-storage-class")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_603194 != nil:
    section.add "x-amz-storage-class", valid_603194
  var valid_603195 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = newJString("ON"))
  if valid_603195 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_603195
  var valid_603196 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_603196
  var valid_603197 = header.getOrDefault("x-amz-tagging")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "x-amz-tagging", valid_603197
  var valid_603198 = header.getOrDefault("x-amz-grant-read-acp")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "x-amz-grant-read-acp", valid_603198
  var valid_603199 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "x-amz-server-side-encryption-context", valid_603199
  var valid_603200 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_603200
  var valid_603201 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_603201
  var valid_603202 = header.getOrDefault("x-amz-grant-write-acp")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "x-amz-grant-write-acp", valid_603202
  var valid_603203 = header.getOrDefault("Content-Encoding")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "Content-Encoding", valid_603203
  var valid_603204 = header.getOrDefault("x-amz-request-payer")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = newJString("requester"))
  if valid_603204 != nil:
    section.add "x-amz-request-payer", valid_603204
  var valid_603205 = header.getOrDefault("x-amz-server-side-encryption")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = newJString("AES256"))
  if valid_603205 != nil:
    section.add "x-amz-server-side-encryption", valid_603205
  var valid_603206 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_603206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603208: Call_CreateMultipartUpload_603176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  let valid = call_603208.validator(path, query, header, formData, body)
  let scheme = call_603208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603208.url(scheme.get, call_603208.host, call_603208.base,
                         call_603208.route, valid.getOrDefault("path"))
  result = hook(call_603208, url, valid)

proc call*(call_603209: Call_CreateMultipartUpload_603176; Key: string;
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
  var path_603210 = newJObject()
  var query_603211 = newJObject()
  var body_603212 = newJObject()
  add(path_603210, "Key", newJString(Key))
  add(query_603211, "uploads", newJBool(uploads))
  add(path_603210, "Bucket", newJString(Bucket))
  if body != nil:
    body_603212 = body
  result = call_603209.call(path_603210, query_603211, nil, nil, body_603212)

var createMultipartUpload* = Call_CreateMultipartUpload_603176(
    name: "createMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploads",
    validator: validate_CreateMultipartUpload_603177, base: "/",
    url: url_CreateMultipartUpload_603178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAnalyticsConfiguration_603224 = ref object of OpenApiRestCall_602433
proc url_PutBucketAnalyticsConfiguration_603226(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketAnalyticsConfiguration_603225(path: JsonNode;
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
  var valid_603227 = path.getOrDefault("Bucket")
  valid_603227 = validateParameter(valid_603227, JString, required = true,
                                 default = nil)
  if valid_603227 != nil:
    section.add "Bucket", valid_603227
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603228 = query.getOrDefault("id")
  valid_603228 = validateParameter(valid_603228, JString, required = true,
                                 default = nil)
  if valid_603228 != nil:
    section.add "id", valid_603228
  var valid_603229 = query.getOrDefault("analytics")
  valid_603229 = validateParameter(valid_603229, JBool, required = true, default = nil)
  if valid_603229 != nil:
    section.add "analytics", valid_603229
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603230 = header.getOrDefault("x-amz-security-token")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "x-amz-security-token", valid_603230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603232: Call_PutBucketAnalyticsConfiguration_603224;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_603232.validator(path, query, header, formData, body)
  let scheme = call_603232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603232.url(scheme.get, call_603232.host, call_603232.base,
                         call_603232.route, valid.getOrDefault("path"))
  result = hook(call_603232, url, valid)

proc call*(call_603233: Call_PutBucketAnalyticsConfiguration_603224; id: string;
          analytics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAnalyticsConfiguration
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket to which an analytics configuration is stored.
  ##   body: JObject (required)
  var path_603234 = newJObject()
  var query_603235 = newJObject()
  var body_603236 = newJObject()
  add(query_603235, "id", newJString(id))
  add(query_603235, "analytics", newJBool(analytics))
  add(path_603234, "Bucket", newJString(Bucket))
  if body != nil:
    body_603236 = body
  result = call_603233.call(path_603234, query_603235, nil, nil, body_603236)

var putBucketAnalyticsConfiguration* = Call_PutBucketAnalyticsConfiguration_603224(
    name: "putBucketAnalyticsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_PutBucketAnalyticsConfiguration_603225, base: "/",
    url: url_PutBucketAnalyticsConfiguration_603226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAnalyticsConfiguration_603213 = ref object of OpenApiRestCall_602433
proc url_GetBucketAnalyticsConfiguration_603215(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketAnalyticsConfiguration_603214(path: JsonNode;
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
  var valid_603216 = path.getOrDefault("Bucket")
  valid_603216 = validateParameter(valid_603216, JString, required = true,
                                 default = nil)
  if valid_603216 != nil:
    section.add "Bucket", valid_603216
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603217 = query.getOrDefault("id")
  valid_603217 = validateParameter(valid_603217, JString, required = true,
                                 default = nil)
  if valid_603217 != nil:
    section.add "id", valid_603217
  var valid_603218 = query.getOrDefault("analytics")
  valid_603218 = validateParameter(valid_603218, JBool, required = true, default = nil)
  if valid_603218 != nil:
    section.add "analytics", valid_603218
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603219 = header.getOrDefault("x-amz-security-token")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "x-amz-security-token", valid_603219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603220: Call_GetBucketAnalyticsConfiguration_603213;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_603220.validator(path, query, header, formData, body)
  let scheme = call_603220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603220.url(scheme.get, call_603220.host, call_603220.base,
                         call_603220.route, valid.getOrDefault("path"))
  result = hook(call_603220, url, valid)

proc call*(call_603221: Call_GetBucketAnalyticsConfiguration_603213; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## getBucketAnalyticsConfiguration
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is retrieved.
  var path_603222 = newJObject()
  var query_603223 = newJObject()
  add(query_603223, "id", newJString(id))
  add(query_603223, "analytics", newJBool(analytics))
  add(path_603222, "Bucket", newJString(Bucket))
  result = call_603221.call(path_603222, query_603223, nil, nil, nil)

var getBucketAnalyticsConfiguration* = Call_GetBucketAnalyticsConfiguration_603213(
    name: "getBucketAnalyticsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_GetBucketAnalyticsConfiguration_603214, base: "/",
    url: url_GetBucketAnalyticsConfiguration_603215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketAnalyticsConfiguration_603237 = ref object of OpenApiRestCall_602433
proc url_DeleteBucketAnalyticsConfiguration_603239(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBucketAnalyticsConfiguration_603238(path: JsonNode;
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
  var valid_603240 = path.getOrDefault("Bucket")
  valid_603240 = validateParameter(valid_603240, JString, required = true,
                                 default = nil)
  if valid_603240 != nil:
    section.add "Bucket", valid_603240
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603241 = query.getOrDefault("id")
  valid_603241 = validateParameter(valid_603241, JString, required = true,
                                 default = nil)
  if valid_603241 != nil:
    section.add "id", valid_603241
  var valid_603242 = query.getOrDefault("analytics")
  valid_603242 = validateParameter(valid_603242, JBool, required = true, default = nil)
  if valid_603242 != nil:
    section.add "analytics", valid_603242
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603243 = header.getOrDefault("x-amz-security-token")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "x-amz-security-token", valid_603243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603244: Call_DeleteBucketAnalyticsConfiguration_603237;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ## 
  let valid = call_603244.validator(path, query, header, formData, body)
  let scheme = call_603244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603244.url(scheme.get, call_603244.host, call_603244.base,
                         call_603244.route, valid.getOrDefault("path"))
  result = hook(call_603244, url, valid)

proc call*(call_603245: Call_DeleteBucketAnalyticsConfiguration_603237; id: string;
          analytics: bool; Bucket: string): Recallable =
  ## deleteBucketAnalyticsConfiguration
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   analytics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is deleted.
  var path_603246 = newJObject()
  var query_603247 = newJObject()
  add(query_603247, "id", newJString(id))
  add(query_603247, "analytics", newJBool(analytics))
  add(path_603246, "Bucket", newJString(Bucket))
  result = call_603245.call(path_603246, query_603247, nil, nil, nil)

var deleteBucketAnalyticsConfiguration* = Call_DeleteBucketAnalyticsConfiguration_603237(
    name: "deleteBucketAnalyticsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_DeleteBucketAnalyticsConfiguration_603238, base: "/",
    url: url_DeleteBucketAnalyticsConfiguration_603239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketCors_603258 = ref object of OpenApiRestCall_602433
proc url_PutBucketCors_603260(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketCors_603259(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603261 = path.getOrDefault("Bucket")
  valid_603261 = validateParameter(valid_603261, JString, required = true,
                                 default = nil)
  if valid_603261 != nil:
    section.add "Bucket", valid_603261
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_603262 = query.getOrDefault("cors")
  valid_603262 = validateParameter(valid_603262, JBool, required = true, default = nil)
  if valid_603262 != nil:
    section.add "cors", valid_603262
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603263 = header.getOrDefault("x-amz-security-token")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "x-amz-security-token", valid_603263
  var valid_603264 = header.getOrDefault("Content-MD5")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "Content-MD5", valid_603264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603266: Call_PutBucketCors_603258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the CORS configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  let valid = call_603266.validator(path, query, header, formData, body)
  let scheme = call_603266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603266.url(scheme.get, call_603266.host, call_603266.base,
                         call_603266.route, valid.getOrDefault("path"))
  result = hook(call_603266, url, valid)

proc call*(call_603267: Call_PutBucketCors_603258; cors: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketCors
  ## Sets the CORS configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603268 = newJObject()
  var query_603269 = newJObject()
  var body_603270 = newJObject()
  add(query_603269, "cors", newJBool(cors))
  add(path_603268, "Bucket", newJString(Bucket))
  if body != nil:
    body_603270 = body
  result = call_603267.call(path_603268, query_603269, nil, nil, body_603270)

var putBucketCors* = Call_PutBucketCors_603258(name: "putBucketCors",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_PutBucketCors_603259, base: "/", url: url_PutBucketCors_603260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketCors_603248 = ref object of OpenApiRestCall_602433
proc url_GetBucketCors_603250(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketCors_603249(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603251 = path.getOrDefault("Bucket")
  valid_603251 = validateParameter(valid_603251, JString, required = true,
                                 default = nil)
  if valid_603251 != nil:
    section.add "Bucket", valid_603251
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_603252 = query.getOrDefault("cors")
  valid_603252 = validateParameter(valid_603252, JBool, required = true, default = nil)
  if valid_603252 != nil:
    section.add "cors", valid_603252
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603253 = header.getOrDefault("x-amz-security-token")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "x-amz-security-token", valid_603253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603254: Call_GetBucketCors_603248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the CORS configuration for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  let valid = call_603254.validator(path, query, header, formData, body)
  let scheme = call_603254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603254.url(scheme.get, call_603254.host, call_603254.base,
                         call_603254.route, valid.getOrDefault("path"))
  result = hook(call_603254, url, valid)

proc call*(call_603255: Call_GetBucketCors_603248; cors: bool; Bucket: string): Recallable =
  ## getBucketCors
  ## Returns the CORS configuration for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603256 = newJObject()
  var query_603257 = newJObject()
  add(query_603257, "cors", newJBool(cors))
  add(path_603256, "Bucket", newJString(Bucket))
  result = call_603255.call(path_603256, query_603257, nil, nil, nil)

var getBucketCors* = Call_GetBucketCors_603248(name: "getBucketCors",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_GetBucketCors_603249, base: "/", url: url_GetBucketCors_603250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketCors_603271 = ref object of OpenApiRestCall_602433
proc url_DeleteBucketCors_603273(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBucketCors_603272(path: JsonNode; query: JsonNode;
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
  var valid_603274 = path.getOrDefault("Bucket")
  valid_603274 = validateParameter(valid_603274, JString, required = true,
                                 default = nil)
  if valid_603274 != nil:
    section.add "Bucket", valid_603274
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_603275 = query.getOrDefault("cors")
  valid_603275 = validateParameter(valid_603275, JBool, required = true, default = nil)
  if valid_603275 != nil:
    section.add "cors", valid_603275
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

proc call*(call_603277: Call_DeleteBucketCors_603271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the CORS configuration information set for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  let valid = call_603277.validator(path, query, header, formData, body)
  let scheme = call_603277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603277.url(scheme.get, call_603277.host, call_603277.base,
                         call_603277.route, valid.getOrDefault("path"))
  result = hook(call_603277, url, valid)

proc call*(call_603278: Call_DeleteBucketCors_603271; cors: bool; Bucket: string): Recallable =
  ## deleteBucketCors
  ## Deletes the CORS configuration information set for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  ##   cors: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603279 = newJObject()
  var query_603280 = newJObject()
  add(query_603280, "cors", newJBool(cors))
  add(path_603279, "Bucket", newJString(Bucket))
  result = call_603278.call(path_603279, query_603280, nil, nil, nil)

var deleteBucketCors* = Call_DeleteBucketCors_603271(name: "deleteBucketCors",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_DeleteBucketCors_603272, base: "/",
    url: url_DeleteBucketCors_603273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketEncryption_603291 = ref object of OpenApiRestCall_602433
proc url_PutBucketEncryption_603293(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketEncryption_603292(path: JsonNode; query: JsonNode;
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
  var valid_603294 = path.getOrDefault("Bucket")
  valid_603294 = validateParameter(valid_603294, JString, required = true,
                                 default = nil)
  if valid_603294 != nil:
    section.add "Bucket", valid_603294
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_603295 = query.getOrDefault("encryption")
  valid_603295 = validateParameter(valid_603295, JBool, required = true, default = nil)
  if valid_603295 != nil:
    section.add "encryption", valid_603295
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the server-side encryption configuration. This parameter is auto-populated when using the command from the CLI.
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

proc call*(call_603299: Call_PutBucketEncryption_603291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ## 
  let valid = call_603299.validator(path, query, header, formData, body)
  let scheme = call_603299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603299.url(scheme.get, call_603299.host, call_603299.base,
                         call_603299.route, valid.getOrDefault("path"))
  result = hook(call_603299, url, valid)

proc call*(call_603300: Call_PutBucketEncryption_603291; encryption: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketEncryption
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : Specifies default encryption for a bucket using server-side encryption with Amazon S3-managed keys (SSE-S3) or AWS KMS-managed keys (SSE-KMS). For information about the Amazon S3 default encryption feature, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 Default Bucket Encryption</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   body: JObject (required)
  var path_603301 = newJObject()
  var query_603302 = newJObject()
  var body_603303 = newJObject()
  add(query_603302, "encryption", newJBool(encryption))
  add(path_603301, "Bucket", newJString(Bucket))
  if body != nil:
    body_603303 = body
  result = call_603300.call(path_603301, query_603302, nil, nil, body_603303)

var putBucketEncryption* = Call_PutBucketEncryption_603291(
    name: "putBucketEncryption", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_PutBucketEncryption_603292,
    base: "/", url: url_PutBucketEncryption_603293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketEncryption_603281 = ref object of OpenApiRestCall_602433
proc url_GetBucketEncryption_603283(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketEncryption_603282(path: JsonNode; query: JsonNode;
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
  var valid_603284 = path.getOrDefault("Bucket")
  valid_603284 = validateParameter(valid_603284, JString, required = true,
                                 default = nil)
  if valid_603284 != nil:
    section.add "Bucket", valid_603284
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_603285 = query.getOrDefault("encryption")
  valid_603285 = validateParameter(valid_603285, JBool, required = true, default = nil)
  if valid_603285 != nil:
    section.add "encryption", valid_603285
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

proc call*(call_603287: Call_GetBucketEncryption_603281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the server-side encryption configuration of a bucket.
  ## 
  let valid = call_603287.validator(path, query, header, formData, body)
  let scheme = call_603287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603287.url(scheme.get, call_603287.host, call_603287.base,
                         call_603287.route, valid.getOrDefault("path"))
  result = hook(call_603287, url, valid)

proc call*(call_603288: Call_GetBucketEncryption_603281; encryption: bool;
          Bucket: string): Recallable =
  ## getBucketEncryption
  ## Returns the server-side encryption configuration of a bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket from which the server-side encryption configuration is retrieved.
  var path_603289 = newJObject()
  var query_603290 = newJObject()
  add(query_603290, "encryption", newJBool(encryption))
  add(path_603289, "Bucket", newJString(Bucket))
  result = call_603288.call(path_603289, query_603290, nil, nil, nil)

var getBucketEncryption* = Call_GetBucketEncryption_603281(
    name: "getBucketEncryption", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_GetBucketEncryption_603282,
    base: "/", url: url_GetBucketEncryption_603283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketEncryption_603304 = ref object of OpenApiRestCall_602433
proc url_DeleteBucketEncryption_603306(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBucketEncryption_603305(path: JsonNode; query: JsonNode;
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
  var valid_603307 = path.getOrDefault("Bucket")
  valid_603307 = validateParameter(valid_603307, JString, required = true,
                                 default = nil)
  if valid_603307 != nil:
    section.add "Bucket", valid_603307
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_603308 = query.getOrDefault("encryption")
  valid_603308 = validateParameter(valid_603308, JBool, required = true, default = nil)
  if valid_603308 != nil:
    section.add "encryption", valid_603308
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

proc call*(call_603310: Call_DeleteBucketEncryption_603304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the server-side encryption configuration from the bucket.
  ## 
  let valid = call_603310.validator(path, query, header, formData, body)
  let scheme = call_603310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603310.url(scheme.get, call_603310.host, call_603310.base,
                         call_603310.route, valid.getOrDefault("path"))
  result = hook(call_603310, url, valid)

proc call*(call_603311: Call_DeleteBucketEncryption_603304; encryption: bool;
          Bucket: string): Recallable =
  ## deleteBucketEncryption
  ## Deletes the server-side encryption configuration from the bucket.
  ##   encryption: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the server-side encryption configuration to delete.
  var path_603312 = newJObject()
  var query_603313 = newJObject()
  add(query_603313, "encryption", newJBool(encryption))
  add(path_603312, "Bucket", newJString(Bucket))
  result = call_603311.call(path_603312, query_603313, nil, nil, nil)

var deleteBucketEncryption* = Call_DeleteBucketEncryption_603304(
    name: "deleteBucketEncryption", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#encryption",
    validator: validate_DeleteBucketEncryption_603305, base: "/",
    url: url_DeleteBucketEncryption_603306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketInventoryConfiguration_603325 = ref object of OpenApiRestCall_602433
proc url_PutBucketInventoryConfiguration_603327(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketInventoryConfiguration_603326(path: JsonNode;
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
  var valid_603328 = path.getOrDefault("Bucket")
  valid_603328 = validateParameter(valid_603328, JString, required = true,
                                 default = nil)
  if valid_603328 != nil:
    section.add "Bucket", valid_603328
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_603329 = query.getOrDefault("inventory")
  valid_603329 = validateParameter(valid_603329, JBool, required = true, default = nil)
  if valid_603329 != nil:
    section.add "inventory", valid_603329
  var valid_603330 = query.getOrDefault("id")
  valid_603330 = validateParameter(valid_603330, JString, required = true,
                                 default = nil)
  if valid_603330 != nil:
    section.add "id", valid_603330
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603331 = header.getOrDefault("x-amz-security-token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "x-amz-security-token", valid_603331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603333: Call_PutBucketInventoryConfiguration_603325;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_603333.validator(path, query, header, formData, body)
  let scheme = call_603333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603333.url(scheme.get, call_603333.host, call_603333.base,
                         call_603333.route, valid.getOrDefault("path"))
  result = hook(call_603333, url, valid)

proc call*(call_603334: Call_PutBucketInventoryConfiguration_603325;
          inventory: bool; id: string; Bucket: string; body: JsonNode): Recallable =
  ## putBucketInventoryConfiguration
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket where the inventory configuration will be stored.
  ##   body: JObject (required)
  var path_603335 = newJObject()
  var query_603336 = newJObject()
  var body_603337 = newJObject()
  add(query_603336, "inventory", newJBool(inventory))
  add(query_603336, "id", newJString(id))
  add(path_603335, "Bucket", newJString(Bucket))
  if body != nil:
    body_603337 = body
  result = call_603334.call(path_603335, query_603336, nil, nil, body_603337)

var putBucketInventoryConfiguration* = Call_PutBucketInventoryConfiguration_603325(
    name: "putBucketInventoryConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_PutBucketInventoryConfiguration_603326, base: "/",
    url: url_PutBucketInventoryConfiguration_603327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketInventoryConfiguration_603314 = ref object of OpenApiRestCall_602433
proc url_GetBucketInventoryConfiguration_603316(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketInventoryConfiguration_603315(path: JsonNode;
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
  var valid_603317 = path.getOrDefault("Bucket")
  valid_603317 = validateParameter(valid_603317, JString, required = true,
                                 default = nil)
  if valid_603317 != nil:
    section.add "Bucket", valid_603317
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_603318 = query.getOrDefault("inventory")
  valid_603318 = validateParameter(valid_603318, JBool, required = true, default = nil)
  if valid_603318 != nil:
    section.add "inventory", valid_603318
  var valid_603319 = query.getOrDefault("id")
  valid_603319 = validateParameter(valid_603319, JString, required = true,
                                 default = nil)
  if valid_603319 != nil:
    section.add "id", valid_603319
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603320 = header.getOrDefault("x-amz-security-token")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "x-amz-security-token", valid_603320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603321: Call_GetBucketInventoryConfiguration_603314;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_603321.validator(path, query, header, formData, body)
  let scheme = call_603321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603321.url(scheme.get, call_603321.host, call_603321.base,
                         call_603321.route, valid.getOrDefault("path"))
  result = hook(call_603321, url, valid)

proc call*(call_603322: Call_GetBucketInventoryConfiguration_603314;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## getBucketInventoryConfiguration
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to retrieve.
  var path_603323 = newJObject()
  var query_603324 = newJObject()
  add(query_603324, "inventory", newJBool(inventory))
  add(query_603324, "id", newJString(id))
  add(path_603323, "Bucket", newJString(Bucket))
  result = call_603322.call(path_603323, query_603324, nil, nil, nil)

var getBucketInventoryConfiguration* = Call_GetBucketInventoryConfiguration_603314(
    name: "getBucketInventoryConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_GetBucketInventoryConfiguration_603315, base: "/",
    url: url_GetBucketInventoryConfiguration_603316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketInventoryConfiguration_603338 = ref object of OpenApiRestCall_602433
proc url_DeleteBucketInventoryConfiguration_603340(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBucketInventoryConfiguration_603339(path: JsonNode;
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
  var valid_603341 = path.getOrDefault("Bucket")
  valid_603341 = validateParameter(valid_603341, JString, required = true,
                                 default = nil)
  if valid_603341 != nil:
    section.add "Bucket", valid_603341
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_603342 = query.getOrDefault("inventory")
  valid_603342 = validateParameter(valid_603342, JBool, required = true, default = nil)
  if valid_603342 != nil:
    section.add "inventory", valid_603342
  var valid_603343 = query.getOrDefault("id")
  valid_603343 = validateParameter(valid_603343, JString, required = true,
                                 default = nil)
  if valid_603343 != nil:
    section.add "id", valid_603343
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603344 = header.getOrDefault("x-amz-security-token")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "x-amz-security-token", valid_603344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603345: Call_DeleteBucketInventoryConfiguration_603338;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_603345.validator(path, query, header, formData, body)
  let scheme = call_603345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603345.url(scheme.get, call_603345.host, call_603345.base,
                         call_603345.route, valid.getOrDefault("path"))
  result = hook(call_603345, url, valid)

proc call*(call_603346: Call_DeleteBucketInventoryConfiguration_603338;
          inventory: bool; id: string; Bucket: string): Recallable =
  ## deleteBucketInventoryConfiguration
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ##   inventory: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to delete.
  var path_603347 = newJObject()
  var query_603348 = newJObject()
  add(query_603348, "inventory", newJBool(inventory))
  add(query_603348, "id", newJString(id))
  add(path_603347, "Bucket", newJString(Bucket))
  result = call_603346.call(path_603347, query_603348, nil, nil, nil)

var deleteBucketInventoryConfiguration* = Call_DeleteBucketInventoryConfiguration_603338(
    name: "deleteBucketInventoryConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_DeleteBucketInventoryConfiguration_603339, base: "/",
    url: url_DeleteBucketInventoryConfiguration_603340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycleConfiguration_603359 = ref object of OpenApiRestCall_602433
proc url_PutBucketLifecycleConfiguration_603361(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketLifecycleConfiguration_603360(path: JsonNode;
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
  var valid_603362 = path.getOrDefault("Bucket")
  valid_603362 = validateParameter(valid_603362, JString, required = true,
                                 default = nil)
  if valid_603362 != nil:
    section.add "Bucket", valid_603362
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_603363 = query.getOrDefault("lifecycle")
  valid_603363 = validateParameter(valid_603363, JBool, required = true, default = nil)
  if valid_603363 != nil:
    section.add "lifecycle", valid_603363
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

proc call*(call_603366: Call_PutBucketLifecycleConfiguration_603359;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ## 
  let valid = call_603366.validator(path, query, header, formData, body)
  let scheme = call_603366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603366.url(scheme.get, call_603366.host, call_603366.base,
                         call_603366.route, valid.getOrDefault("path"))
  result = hook(call_603366, url, valid)

proc call*(call_603367: Call_PutBucketLifecycleConfiguration_603359;
          Bucket: string; lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycleConfiguration
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_603368 = newJObject()
  var query_603369 = newJObject()
  var body_603370 = newJObject()
  add(path_603368, "Bucket", newJString(Bucket))
  add(query_603369, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_603370 = body
  result = call_603367.call(path_603368, query_603369, nil, nil, body_603370)

var putBucketLifecycleConfiguration* = Call_PutBucketLifecycleConfiguration_603359(
    name: "putBucketLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_PutBucketLifecycleConfiguration_603360, base: "/",
    url: url_PutBucketLifecycleConfiguration_603361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycleConfiguration_603349 = ref object of OpenApiRestCall_602433
proc url_GetBucketLifecycleConfiguration_603351(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketLifecycleConfiguration_603350(path: JsonNode;
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
  var valid_603352 = path.getOrDefault("Bucket")
  valid_603352 = validateParameter(valid_603352, JString, required = true,
                                 default = nil)
  if valid_603352 != nil:
    section.add "Bucket", valid_603352
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_603353 = query.getOrDefault("lifecycle")
  valid_603353 = validateParameter(valid_603353, JBool, required = true, default = nil)
  if valid_603353 != nil:
    section.add "lifecycle", valid_603353
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603354 = header.getOrDefault("x-amz-security-token")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "x-amz-security-token", valid_603354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603355: Call_GetBucketLifecycleConfiguration_603349;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the lifecycle configuration information set on the bucket.
  ## 
  let valid = call_603355.validator(path, query, header, formData, body)
  let scheme = call_603355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603355.url(scheme.get, call_603355.host, call_603355.base,
                         call_603355.route, valid.getOrDefault("path"))
  result = hook(call_603355, url, valid)

proc call*(call_603356: Call_GetBucketLifecycleConfiguration_603349;
          Bucket: string; lifecycle: bool): Recallable =
  ## getBucketLifecycleConfiguration
  ## Returns the lifecycle configuration information set on the bucket.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_603357 = newJObject()
  var query_603358 = newJObject()
  add(path_603357, "Bucket", newJString(Bucket))
  add(query_603358, "lifecycle", newJBool(lifecycle))
  result = call_603356.call(path_603357, query_603358, nil, nil, nil)

var getBucketLifecycleConfiguration* = Call_GetBucketLifecycleConfiguration_603349(
    name: "getBucketLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_GetBucketLifecycleConfiguration_603350, base: "/",
    url: url_GetBucketLifecycleConfiguration_603351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketLifecycle_603371 = ref object of OpenApiRestCall_602433
proc url_DeleteBucketLifecycle_603373(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBucketLifecycle_603372(path: JsonNode; query: JsonNode;
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
  var valid_603374 = path.getOrDefault("Bucket")
  valid_603374 = validateParameter(valid_603374, JString, required = true,
                                 default = nil)
  if valid_603374 != nil:
    section.add "Bucket", valid_603374
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_603375 = query.getOrDefault("lifecycle")
  valid_603375 = validateParameter(valid_603375, JBool, required = true, default = nil)
  if valid_603375 != nil:
    section.add "lifecycle", valid_603375
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603376 = header.getOrDefault("x-amz-security-token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "x-amz-security-token", valid_603376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603377: Call_DeleteBucketLifecycle_603371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the lifecycle configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  let valid = call_603377.validator(path, query, header, formData, body)
  let scheme = call_603377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603377.url(scheme.get, call_603377.host, call_603377.base,
                         call_603377.route, valid.getOrDefault("path"))
  result = hook(call_603377, url, valid)

proc call*(call_603378: Call_DeleteBucketLifecycle_603371; Bucket: string;
          lifecycle: bool): Recallable =
  ## deleteBucketLifecycle
  ## Deletes the lifecycle configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_603379 = newJObject()
  var query_603380 = newJObject()
  add(path_603379, "Bucket", newJString(Bucket))
  add(query_603380, "lifecycle", newJBool(lifecycle))
  result = call_603378.call(path_603379, query_603380, nil, nil, nil)

var deleteBucketLifecycle* = Call_DeleteBucketLifecycle_603371(
    name: "deleteBucketLifecycle", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_DeleteBucketLifecycle_603372, base: "/",
    url: url_DeleteBucketLifecycle_603373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketMetricsConfiguration_603392 = ref object of OpenApiRestCall_602433
proc url_PutBucketMetricsConfiguration_603394(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketMetricsConfiguration_603393(path: JsonNode; query: JsonNode;
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
  var valid_603395 = path.getOrDefault("Bucket")
  valid_603395 = validateParameter(valid_603395, JString, required = true,
                                 default = nil)
  if valid_603395 != nil:
    section.add "Bucket", valid_603395
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603396 = query.getOrDefault("id")
  valid_603396 = validateParameter(valid_603396, JString, required = true,
                                 default = nil)
  if valid_603396 != nil:
    section.add "id", valid_603396
  var valid_603397 = query.getOrDefault("metrics")
  valid_603397 = validateParameter(valid_603397, JBool, required = true, default = nil)
  if valid_603397 != nil:
    section.add "metrics", valid_603397
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603398 = header.getOrDefault("x-amz-security-token")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "x-amz-security-token", valid_603398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603400: Call_PutBucketMetricsConfiguration_603392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ## 
  let valid = call_603400.validator(path, query, header, formData, body)
  let scheme = call_603400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603400.url(scheme.get, call_603400.host, call_603400.base,
                         call_603400.route, valid.getOrDefault("path"))
  result = hook(call_603400, url, valid)

proc call*(call_603401: Call_PutBucketMetricsConfiguration_603392; id: string;
          metrics: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketMetricsConfiguration
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket for which the metrics configuration is set.
  ##   body: JObject (required)
  var path_603402 = newJObject()
  var query_603403 = newJObject()
  var body_603404 = newJObject()
  add(query_603403, "id", newJString(id))
  add(query_603403, "metrics", newJBool(metrics))
  add(path_603402, "Bucket", newJString(Bucket))
  if body != nil:
    body_603404 = body
  result = call_603401.call(path_603402, query_603403, nil, nil, body_603404)

var putBucketMetricsConfiguration* = Call_PutBucketMetricsConfiguration_603392(
    name: "putBucketMetricsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_PutBucketMetricsConfiguration_603393, base: "/",
    url: url_PutBucketMetricsConfiguration_603394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketMetricsConfiguration_603381 = ref object of OpenApiRestCall_602433
proc url_GetBucketMetricsConfiguration_603383(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketMetricsConfiguration_603382(path: JsonNode; query: JsonNode;
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
  var valid_603384 = path.getOrDefault("Bucket")
  valid_603384 = validateParameter(valid_603384, JString, required = true,
                                 default = nil)
  if valid_603384 != nil:
    section.add "Bucket", valid_603384
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603385 = query.getOrDefault("id")
  valid_603385 = validateParameter(valid_603385, JString, required = true,
                                 default = nil)
  if valid_603385 != nil:
    section.add "id", valid_603385
  var valid_603386 = query.getOrDefault("metrics")
  valid_603386 = validateParameter(valid_603386, JBool, required = true, default = nil)
  if valid_603386 != nil:
    section.add "metrics", valid_603386
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

proc call*(call_603388: Call_GetBucketMetricsConfiguration_603381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_603388.validator(path, query, header, formData, body)
  let scheme = call_603388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603388.url(scheme.get, call_603388.host, call_603388.base,
                         call_603388.route, valid.getOrDefault("path"))
  result = hook(call_603388, url, valid)

proc call*(call_603389: Call_GetBucketMetricsConfiguration_603381; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## getBucketMetricsConfiguration
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to retrieve.
  var path_603390 = newJObject()
  var query_603391 = newJObject()
  add(query_603391, "id", newJString(id))
  add(query_603391, "metrics", newJBool(metrics))
  add(path_603390, "Bucket", newJString(Bucket))
  result = call_603389.call(path_603390, query_603391, nil, nil, nil)

var getBucketMetricsConfiguration* = Call_GetBucketMetricsConfiguration_603381(
    name: "getBucketMetricsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_GetBucketMetricsConfiguration_603382, base: "/",
    url: url_GetBucketMetricsConfiguration_603383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketMetricsConfiguration_603405 = ref object of OpenApiRestCall_602433
proc url_DeleteBucketMetricsConfiguration_603407(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBucketMetricsConfiguration_603406(path: JsonNode;
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
  var valid_603408 = path.getOrDefault("Bucket")
  valid_603408 = validateParameter(valid_603408, JString, required = true,
                                 default = nil)
  if valid_603408 != nil:
    section.add "Bucket", valid_603408
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603409 = query.getOrDefault("id")
  valid_603409 = validateParameter(valid_603409, JString, required = true,
                                 default = nil)
  if valid_603409 != nil:
    section.add "id", valid_603409
  var valid_603410 = query.getOrDefault("metrics")
  valid_603410 = validateParameter(valid_603410, JBool, required = true, default = nil)
  if valid_603410 != nil:
    section.add "metrics", valid_603410
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603411 = header.getOrDefault("x-amz-security-token")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "x-amz-security-token", valid_603411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603412: Call_DeleteBucketMetricsConfiguration_603405;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_603412.validator(path, query, header, formData, body)
  let scheme = call_603412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603412.url(scheme.get, call_603412.host, call_603412.base,
                         call_603412.route, valid.getOrDefault("path"))
  result = hook(call_603412, url, valid)

proc call*(call_603413: Call_DeleteBucketMetricsConfiguration_603405; id: string;
          metrics: bool; Bucket: string): Recallable =
  ## deleteBucketMetricsConfiguration
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   metrics: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to delete.
  var path_603414 = newJObject()
  var query_603415 = newJObject()
  add(query_603415, "id", newJString(id))
  add(query_603415, "metrics", newJBool(metrics))
  add(path_603414, "Bucket", newJString(Bucket))
  result = call_603413.call(path_603414, query_603415, nil, nil, nil)

var deleteBucketMetricsConfiguration* = Call_DeleteBucketMetricsConfiguration_603405(
    name: "deleteBucketMetricsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_DeleteBucketMetricsConfiguration_603406, base: "/",
    url: url_DeleteBucketMetricsConfiguration_603407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketPolicy_603426 = ref object of OpenApiRestCall_602433
proc url_PutBucketPolicy_603428(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketPolicy_603427(path: JsonNode; query: JsonNode;
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
  var valid_603429 = path.getOrDefault("Bucket")
  valid_603429 = validateParameter(valid_603429, JString, required = true,
                                 default = nil)
  if valid_603429 != nil:
    section.add "Bucket", valid_603429
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_603430 = query.getOrDefault("policy")
  valid_603430 = validateParameter(valid_603430, JBool, required = true, default = nil)
  if valid_603430 != nil:
    section.add "policy", valid_603430
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-confirm-remove-self-bucket-access: JBool
  ##                                          : Set this parameter to true to confirm that you want to remove your permissions to change this bucket policy in the future.
  section = newJObject()
  var valid_603431 = header.getOrDefault("x-amz-security-token")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "x-amz-security-token", valid_603431
  var valid_603432 = header.getOrDefault("Content-MD5")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "Content-MD5", valid_603432
  var valid_603433 = header.getOrDefault("x-amz-confirm-remove-self-bucket-access")
  valid_603433 = validateParameter(valid_603433, JBool, required = false, default = nil)
  if valid_603433 != nil:
    section.add "x-amz-confirm-remove-self-bucket-access", valid_603433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603435: Call_PutBucketPolicy_603426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  let valid = call_603435.validator(path, query, header, formData, body)
  let scheme = call_603435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603435.url(scheme.get, call_603435.host, call_603435.base,
                         call_603435.route, valid.getOrDefault("path"))
  result = hook(call_603435, url, valid)

proc call*(call_603436: Call_PutBucketPolicy_603426; policy: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketPolicy
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603437 = newJObject()
  var query_603438 = newJObject()
  var body_603439 = newJObject()
  add(query_603438, "policy", newJBool(policy))
  add(path_603437, "Bucket", newJString(Bucket))
  if body != nil:
    body_603439 = body
  result = call_603436.call(path_603437, query_603438, nil, nil, body_603439)

var putBucketPolicy* = Call_PutBucketPolicy_603426(name: "putBucketPolicy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_PutBucketPolicy_603427, base: "/", url: url_PutBucketPolicy_603428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicy_603416 = ref object of OpenApiRestCall_602433
proc url_GetBucketPolicy_603418(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketPolicy_603417(path: JsonNode; query: JsonNode;
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
  var valid_603419 = path.getOrDefault("Bucket")
  valid_603419 = validateParameter(valid_603419, JString, required = true,
                                 default = nil)
  if valid_603419 != nil:
    section.add "Bucket", valid_603419
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_603420 = query.getOrDefault("policy")
  valid_603420 = validateParameter(valid_603420, JBool, required = true, default = nil)
  if valid_603420 != nil:
    section.add "policy", valid_603420
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603421 = header.getOrDefault("x-amz-security-token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "x-amz-security-token", valid_603421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603422: Call_GetBucketPolicy_603416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the policy of a specified bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  let valid = call_603422.validator(path, query, header, formData, body)
  let scheme = call_603422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603422.url(scheme.get, call_603422.host, call_603422.base,
                         call_603422.route, valid.getOrDefault("path"))
  result = hook(call_603422, url, valid)

proc call*(call_603423: Call_GetBucketPolicy_603416; policy: bool; Bucket: string): Recallable =
  ## getBucketPolicy
  ## Returns the policy of a specified bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603424 = newJObject()
  var query_603425 = newJObject()
  add(query_603425, "policy", newJBool(policy))
  add(path_603424, "Bucket", newJString(Bucket))
  result = call_603423.call(path_603424, query_603425, nil, nil, nil)

var getBucketPolicy* = Call_GetBucketPolicy_603416(name: "getBucketPolicy",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_GetBucketPolicy_603417, base: "/", url: url_GetBucketPolicy_603418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketPolicy_603440 = ref object of OpenApiRestCall_602433
proc url_DeleteBucketPolicy_603442(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBucketPolicy_603441(path: JsonNode; query: JsonNode;
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
  var valid_603443 = path.getOrDefault("Bucket")
  valid_603443 = validateParameter(valid_603443, JString, required = true,
                                 default = nil)
  if valid_603443 != nil:
    section.add "Bucket", valid_603443
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_603444 = query.getOrDefault("policy")
  valid_603444 = validateParameter(valid_603444, JBool, required = true, default = nil)
  if valid_603444 != nil:
    section.add "policy", valid_603444
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603445 = header.getOrDefault("x-amz-security-token")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "x-amz-security-token", valid_603445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603446: Call_DeleteBucketPolicy_603440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  let valid = call_603446.validator(path, query, header, formData, body)
  let scheme = call_603446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603446.url(scheme.get, call_603446.host, call_603446.base,
                         call_603446.route, valid.getOrDefault("path"))
  result = hook(call_603446, url, valid)

proc call*(call_603447: Call_DeleteBucketPolicy_603440; policy: bool; Bucket: string): Recallable =
  ## deleteBucketPolicy
  ## Deletes the policy from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  ##   policy: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603448 = newJObject()
  var query_603449 = newJObject()
  add(query_603449, "policy", newJBool(policy))
  add(path_603448, "Bucket", newJString(Bucket))
  result = call_603447.call(path_603448, query_603449, nil, nil, nil)

var deleteBucketPolicy* = Call_DeleteBucketPolicy_603440(
    name: "deleteBucketPolicy", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_DeleteBucketPolicy_603441, base: "/",
    url: url_DeleteBucketPolicy_603442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketReplication_603460 = ref object of OpenApiRestCall_602433
proc url_PutBucketReplication_603462(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketReplication_603461(path: JsonNode; query: JsonNode;
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
  var valid_603463 = path.getOrDefault("Bucket")
  valid_603463 = validateParameter(valid_603463, JString, required = true,
                                 default = nil)
  if valid_603463 != nil:
    section.add "Bucket", valid_603463
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_603464 = query.getOrDefault("replication")
  valid_603464 = validateParameter(valid_603464, JBool, required = true, default = nil)
  if valid_603464 != nil:
    section.add "replication", valid_603464
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit.
  ##   x-amz-bucket-object-lock-token: JString
  ##                                 : A token that allows Amazon S3 object lock to be enabled for an existing bucket.
  section = newJObject()
  var valid_603465 = header.getOrDefault("x-amz-security-token")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "x-amz-security-token", valid_603465
  var valid_603466 = header.getOrDefault("Content-MD5")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "Content-MD5", valid_603466
  var valid_603467 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_603467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603469: Call_PutBucketReplication_603460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_603469.validator(path, query, header, formData, body)
  let scheme = call_603469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603469.url(scheme.get, call_603469.host, call_603469.base,
                         call_603469.route, valid.getOrDefault("path"))
  result = hook(call_603469, url, valid)

proc call*(call_603470: Call_PutBucketReplication_603460; replication: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketReplication
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603471 = newJObject()
  var query_603472 = newJObject()
  var body_603473 = newJObject()
  add(query_603472, "replication", newJBool(replication))
  add(path_603471, "Bucket", newJString(Bucket))
  if body != nil:
    body_603473 = body
  result = call_603470.call(path_603471, query_603472, nil, nil, body_603473)

var putBucketReplication* = Call_PutBucketReplication_603460(
    name: "putBucketReplication", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_PutBucketReplication_603461, base: "/",
    url: url_PutBucketReplication_603462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketReplication_603450 = ref object of OpenApiRestCall_602433
proc url_GetBucketReplication_603452(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketReplication_603451(path: JsonNode; query: JsonNode;
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
  var valid_603453 = path.getOrDefault("Bucket")
  valid_603453 = validateParameter(valid_603453, JString, required = true,
                                 default = nil)
  if valid_603453 != nil:
    section.add "Bucket", valid_603453
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_603454 = query.getOrDefault("replication")
  valid_603454 = validateParameter(valid_603454, JBool, required = true, default = nil)
  if valid_603454 != nil:
    section.add "replication", valid_603454
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603455 = header.getOrDefault("x-amz-security-token")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "x-amz-security-token", valid_603455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603456: Call_GetBucketReplication_603450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ## 
  let valid = call_603456.validator(path, query, header, formData, body)
  let scheme = call_603456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603456.url(scheme.get, call_603456.host, call_603456.base,
                         call_603456.route, valid.getOrDefault("path"))
  result = hook(call_603456, url, valid)

proc call*(call_603457: Call_GetBucketReplication_603450; replication: bool;
          Bucket: string): Recallable =
  ## getBucketReplication
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603458 = newJObject()
  var query_603459 = newJObject()
  add(query_603459, "replication", newJBool(replication))
  add(path_603458, "Bucket", newJString(Bucket))
  result = call_603457.call(path_603458, query_603459, nil, nil, nil)

var getBucketReplication* = Call_GetBucketReplication_603450(
    name: "getBucketReplication", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_GetBucketReplication_603451, base: "/",
    url: url_GetBucketReplication_603452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketReplication_603474 = ref object of OpenApiRestCall_602433
proc url_DeleteBucketReplication_603476(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBucketReplication_603475(path: JsonNode; query: JsonNode;
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
  var valid_603477 = path.getOrDefault("Bucket")
  valid_603477 = validateParameter(valid_603477, JString, required = true,
                                 default = nil)
  if valid_603477 != nil:
    section.add "Bucket", valid_603477
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_603478 = query.getOrDefault("replication")
  valid_603478 = validateParameter(valid_603478, JBool, required = true, default = nil)
  if valid_603478 != nil:
    section.add "replication", valid_603478
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603479 = header.getOrDefault("x-amz-security-token")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "x-amz-security-token", valid_603479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603480: Call_DeleteBucketReplication_603474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_603480.validator(path, query, header, formData, body)
  let scheme = call_603480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603480.url(scheme.get, call_603480.host, call_603480.base,
                         call_603480.route, valid.getOrDefault("path"))
  result = hook(call_603480, url, valid)

proc call*(call_603481: Call_DeleteBucketReplication_603474; replication: bool;
          Bucket: string): Recallable =
  ## deleteBucketReplication
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   replication: bool (required)
  ##   Bucket: string (required)
  ##         : <p> The bucket name. </p> <note> <p>It can take a while to propagate the deletion of a replication configuration to all Amazon S3 systems.</p> </note>
  var path_603482 = newJObject()
  var query_603483 = newJObject()
  add(query_603483, "replication", newJBool(replication))
  add(path_603482, "Bucket", newJString(Bucket))
  result = call_603481.call(path_603482, query_603483, nil, nil, nil)

var deleteBucketReplication* = Call_DeleteBucketReplication_603474(
    name: "deleteBucketReplication", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_DeleteBucketReplication_603475, base: "/",
    url: url_DeleteBucketReplication_603476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketTagging_603494 = ref object of OpenApiRestCall_602433
proc url_PutBucketTagging_603496(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketTagging_603495(path: JsonNode; query: JsonNode;
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
  var valid_603497 = path.getOrDefault("Bucket")
  valid_603497 = validateParameter(valid_603497, JString, required = true,
                                 default = nil)
  if valid_603497 != nil:
    section.add "Bucket", valid_603497
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603498 = query.getOrDefault("tagging")
  valid_603498 = validateParameter(valid_603498, JBool, required = true, default = nil)
  if valid_603498 != nil:
    section.add "tagging", valid_603498
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603499 = header.getOrDefault("x-amz-security-token")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "x-amz-security-token", valid_603499
  var valid_603500 = header.getOrDefault("Content-MD5")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "Content-MD5", valid_603500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603502: Call_PutBucketTagging_603494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the tags for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  let valid = call_603502.validator(path, query, header, formData, body)
  let scheme = call_603502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603502.url(scheme.get, call_603502.host, call_603502.base,
                         call_603502.route, valid.getOrDefault("path"))
  result = hook(call_603502, url, valid)

proc call*(call_603503: Call_PutBucketTagging_603494; tagging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketTagging
  ## Sets the tags for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603504 = newJObject()
  var query_603505 = newJObject()
  var body_603506 = newJObject()
  add(query_603505, "tagging", newJBool(tagging))
  add(path_603504, "Bucket", newJString(Bucket))
  if body != nil:
    body_603506 = body
  result = call_603503.call(path_603504, query_603505, nil, nil, body_603506)

var putBucketTagging* = Call_PutBucketTagging_603494(name: "putBucketTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_PutBucketTagging_603495, base: "/",
    url: url_PutBucketTagging_603496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketTagging_603484 = ref object of OpenApiRestCall_602433
proc url_GetBucketTagging_603486(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketTagging_603485(path: JsonNode; query: JsonNode;
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
  var valid_603487 = path.getOrDefault("Bucket")
  valid_603487 = validateParameter(valid_603487, JString, required = true,
                                 default = nil)
  if valid_603487 != nil:
    section.add "Bucket", valid_603487
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603488 = query.getOrDefault("tagging")
  valid_603488 = validateParameter(valid_603488, JBool, required = true, default = nil)
  if valid_603488 != nil:
    section.add "tagging", valid_603488
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603489 = header.getOrDefault("x-amz-security-token")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "x-amz-security-token", valid_603489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603490: Call_GetBucketTagging_603484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag set associated with the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  let valid = call_603490.validator(path, query, header, formData, body)
  let scheme = call_603490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603490.url(scheme.get, call_603490.host, call_603490.base,
                         call_603490.route, valid.getOrDefault("path"))
  result = hook(call_603490, url, valid)

proc call*(call_603491: Call_GetBucketTagging_603484; tagging: bool; Bucket: string): Recallable =
  ## getBucketTagging
  ## Returns the tag set associated with the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603492 = newJObject()
  var query_603493 = newJObject()
  add(query_603493, "tagging", newJBool(tagging))
  add(path_603492, "Bucket", newJString(Bucket))
  result = call_603491.call(path_603492, query_603493, nil, nil, nil)

var getBucketTagging* = Call_GetBucketTagging_603484(name: "getBucketTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_GetBucketTagging_603485, base: "/",
    url: url_GetBucketTagging_603486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketTagging_603507 = ref object of OpenApiRestCall_602433
proc url_DeleteBucketTagging_603509(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBucketTagging_603508(path: JsonNode; query: JsonNode;
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
  var valid_603510 = path.getOrDefault("Bucket")
  valid_603510 = validateParameter(valid_603510, JString, required = true,
                                 default = nil)
  if valid_603510 != nil:
    section.add "Bucket", valid_603510
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603511 = query.getOrDefault("tagging")
  valid_603511 = validateParameter(valid_603511, JBool, required = true, default = nil)
  if valid_603511 != nil:
    section.add "tagging", valid_603511
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

proc call*(call_603513: Call_DeleteBucketTagging_603507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the tags from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  let valid = call_603513.validator(path, query, header, formData, body)
  let scheme = call_603513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603513.url(scheme.get, call_603513.host, call_603513.base,
                         call_603513.route, valid.getOrDefault("path"))
  result = hook(call_603513, url, valid)

proc call*(call_603514: Call_DeleteBucketTagging_603507; tagging: bool;
          Bucket: string): Recallable =
  ## deleteBucketTagging
  ## Deletes the tags from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603515 = newJObject()
  var query_603516 = newJObject()
  add(query_603516, "tagging", newJBool(tagging))
  add(path_603515, "Bucket", newJString(Bucket))
  result = call_603514.call(path_603515, query_603516, nil, nil, nil)

var deleteBucketTagging* = Call_DeleteBucketTagging_603507(
    name: "deleteBucketTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_DeleteBucketTagging_603508, base: "/",
    url: url_DeleteBucketTagging_603509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketWebsite_603527 = ref object of OpenApiRestCall_602433
proc url_PutBucketWebsite_603529(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketWebsite_603528(path: JsonNode; query: JsonNode;
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
  var valid_603530 = path.getOrDefault("Bucket")
  valid_603530 = validateParameter(valid_603530, JString, required = true,
                                 default = nil)
  if valid_603530 != nil:
    section.add "Bucket", valid_603530
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_603531 = query.getOrDefault("website")
  valid_603531 = validateParameter(valid_603531, JBool, required = true, default = nil)
  if valid_603531 != nil:
    section.add "website", valid_603531
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

proc call*(call_603535: Call_PutBucketWebsite_603527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  let valid = call_603535.validator(path, query, header, formData, body)
  let scheme = call_603535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603535.url(scheme.get, call_603535.host, call_603535.base,
                         call_603535.route, valid.getOrDefault("path"))
  result = hook(call_603535, url, valid)

proc call*(call_603536: Call_PutBucketWebsite_603527; website: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketWebsite
  ## Set the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603537 = newJObject()
  var query_603538 = newJObject()
  var body_603539 = newJObject()
  add(query_603538, "website", newJBool(website))
  add(path_603537, "Bucket", newJString(Bucket))
  if body != nil:
    body_603539 = body
  result = call_603536.call(path_603537, query_603538, nil, nil, body_603539)

var putBucketWebsite* = Call_PutBucketWebsite_603527(name: "putBucketWebsite",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_PutBucketWebsite_603528, base: "/",
    url: url_PutBucketWebsite_603529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketWebsite_603517 = ref object of OpenApiRestCall_602433
proc url_GetBucketWebsite_603519(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketWebsite_603518(path: JsonNode; query: JsonNode;
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
  var valid_603520 = path.getOrDefault("Bucket")
  valid_603520 = validateParameter(valid_603520, JString, required = true,
                                 default = nil)
  if valid_603520 != nil:
    section.add "Bucket", valid_603520
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_603521 = query.getOrDefault("website")
  valid_603521 = validateParameter(valid_603521, JBool, required = true, default = nil)
  if valid_603521 != nil:
    section.add "website", valid_603521
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

proc call*(call_603523: Call_GetBucketWebsite_603517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  let valid = call_603523.validator(path, query, header, formData, body)
  let scheme = call_603523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603523.url(scheme.get, call_603523.host, call_603523.base,
                         call_603523.route, valid.getOrDefault("path"))
  result = hook(call_603523, url, valid)

proc call*(call_603524: Call_GetBucketWebsite_603517; website: bool; Bucket: string): Recallable =
  ## getBucketWebsite
  ## Returns the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603525 = newJObject()
  var query_603526 = newJObject()
  add(query_603526, "website", newJBool(website))
  add(path_603525, "Bucket", newJString(Bucket))
  result = call_603524.call(path_603525, query_603526, nil, nil, nil)

var getBucketWebsite* = Call_GetBucketWebsite_603517(name: "getBucketWebsite",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_GetBucketWebsite_603518, base: "/",
    url: url_GetBucketWebsite_603519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketWebsite_603540 = ref object of OpenApiRestCall_602433
proc url_DeleteBucketWebsite_603542(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteBucketWebsite_603541(path: JsonNode; query: JsonNode;
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
  var valid_603543 = path.getOrDefault("Bucket")
  valid_603543 = validateParameter(valid_603543, JString, required = true,
                                 default = nil)
  if valid_603543 != nil:
    section.add "Bucket", valid_603543
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_603544 = query.getOrDefault("website")
  valid_603544 = validateParameter(valid_603544, JBool, required = true, default = nil)
  if valid_603544 != nil:
    section.add "website", valid_603544
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

proc call*(call_603546: Call_DeleteBucketWebsite_603540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes the website configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  let valid = call_603546.validator(path, query, header, formData, body)
  let scheme = call_603546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603546.url(scheme.get, call_603546.host, call_603546.base,
                         call_603546.route, valid.getOrDefault("path"))
  result = hook(call_603546, url, valid)

proc call*(call_603547: Call_DeleteBucketWebsite_603540; website: bool;
          Bucket: string): Recallable =
  ## deleteBucketWebsite
  ## This operation removes the website configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  ##   website: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603548 = newJObject()
  var query_603549 = newJObject()
  add(query_603549, "website", newJBool(website))
  add(path_603548, "Bucket", newJString(Bucket))
  result = call_603547.call(path_603548, query_603549, nil, nil, nil)

var deleteBucketWebsite* = Call_DeleteBucketWebsite_603540(
    name: "deleteBucketWebsite", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_DeleteBucketWebsite_603541, base: "/",
    url: url_DeleteBucketWebsite_603542, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObject_603577 = ref object of OpenApiRestCall_602433
proc url_PutObject_603579(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutObject_603578(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603580 = path.getOrDefault("Key")
  valid_603580 = validateParameter(valid_603580, JString, required = true,
                                 default = nil)
  if valid_603580 != nil:
    section.add "Key", valid_603580
  var valid_603581 = path.getOrDefault("Bucket")
  valid_603581 = validateParameter(valid_603581, JString, required = true,
                                 default = nil)
  if valid_603581 != nil:
    section.add "Bucket", valid_603581
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
  var valid_603582 = header.getOrDefault("Content-Disposition")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "Content-Disposition", valid_603582
  var valid_603583 = header.getOrDefault("x-amz-grant-full-control")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "x-amz-grant-full-control", valid_603583
  var valid_603584 = header.getOrDefault("x-amz-security-token")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "x-amz-security-token", valid_603584
  var valid_603585 = header.getOrDefault("Content-MD5")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "Content-MD5", valid_603585
  var valid_603586 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_603586
  var valid_603587 = header.getOrDefault("x-amz-object-lock-mode")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_603587 != nil:
    section.add "x-amz-object-lock-mode", valid_603587
  var valid_603588 = header.getOrDefault("Cache-Control")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "Cache-Control", valid_603588
  var valid_603589 = header.getOrDefault("Content-Language")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "Content-Language", valid_603589
  var valid_603590 = header.getOrDefault("Content-Type")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "Content-Type", valid_603590
  var valid_603591 = header.getOrDefault("Expires")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "Expires", valid_603591
  var valid_603592 = header.getOrDefault("x-amz-website-redirect-location")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "x-amz-website-redirect-location", valid_603592
  var valid_603593 = header.getOrDefault("x-amz-acl")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = newJString("private"))
  if valid_603593 != nil:
    section.add "x-amz-acl", valid_603593
  var valid_603594 = header.getOrDefault("x-amz-grant-read")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "x-amz-grant-read", valid_603594
  var valid_603595 = header.getOrDefault("x-amz-storage-class")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_603595 != nil:
    section.add "x-amz-storage-class", valid_603595
  var valid_603596 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = newJString("ON"))
  if valid_603596 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_603596
  var valid_603597 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_603597
  var valid_603598 = header.getOrDefault("x-amz-tagging")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "x-amz-tagging", valid_603598
  var valid_603599 = header.getOrDefault("x-amz-grant-read-acp")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "x-amz-grant-read-acp", valid_603599
  var valid_603600 = header.getOrDefault("Content-Length")
  valid_603600 = validateParameter(valid_603600, JInt, required = false, default = nil)
  if valid_603600 != nil:
    section.add "Content-Length", valid_603600
  var valid_603601 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "x-amz-server-side-encryption-context", valid_603601
  var valid_603602 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_603602
  var valid_603603 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_603603
  var valid_603604 = header.getOrDefault("x-amz-grant-write-acp")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "x-amz-grant-write-acp", valid_603604
  var valid_603605 = header.getOrDefault("Content-Encoding")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "Content-Encoding", valid_603605
  var valid_603606 = header.getOrDefault("x-amz-request-payer")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = newJString("requester"))
  if valid_603606 != nil:
    section.add "x-amz-request-payer", valid_603606
  var valid_603607 = header.getOrDefault("x-amz-server-side-encryption")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = newJString("AES256"))
  if valid_603607 != nil:
    section.add "x-amz-server-side-encryption", valid_603607
  var valid_603608 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_603608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603610: Call_PutObject_603577; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an object to a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  let valid = call_603610.validator(path, query, header, formData, body)
  let scheme = call_603610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603610.url(scheme.get, call_603610.host, call_603610.base,
                         call_603610.route, valid.getOrDefault("path"))
  result = hook(call_603610, url, valid)

proc call*(call_603611: Call_PutObject_603577; Key: string; Bucket: string;
          body: JsonNode): Recallable =
  ## putObject
  ## Adds an object to a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  ##   Key: string (required)
  ##      : Object key for which the PUT operation was initiated.
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the PUT operation was initiated.
  ##   body: JObject (required)
  var path_603612 = newJObject()
  var body_603613 = newJObject()
  add(path_603612, "Key", newJString(Key))
  add(path_603612, "Bucket", newJString(Bucket))
  if body != nil:
    body_603613 = body
  result = call_603611.call(path_603612, nil, nil, nil, body_603613)

var putObject* = Call_PutObject_603577(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_PutObject_603578,
                                    base: "/", url: url_PutObject_603579,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadObject_603628 = ref object of OpenApiRestCall_602433
proc url_HeadObject_603630(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_HeadObject_603629(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603631 = path.getOrDefault("Key")
  valid_603631 = validateParameter(valid_603631, JString, required = true,
                                 default = nil)
  if valid_603631 != nil:
    section.add "Key", valid_603631
  var valid_603632 = path.getOrDefault("Bucket")
  valid_603632 = validateParameter(valid_603632, JString, required = true,
                                 default = nil)
  if valid_603632 != nil:
    section.add "Bucket", valid_603632
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   partNumber: JInt
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
  section = newJObject()
  var valid_603633 = query.getOrDefault("versionId")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "versionId", valid_603633
  var valid_603634 = query.getOrDefault("partNumber")
  valid_603634 = validateParameter(valid_603634, JInt, required = false, default = nil)
  if valid_603634 != nil:
    section.add "partNumber", valid_603634
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
  var valid_603635 = header.getOrDefault("x-amz-security-token")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "x-amz-security-token", valid_603635
  var valid_603636 = header.getOrDefault("If-Match")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "If-Match", valid_603636
  var valid_603637 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_603637
  var valid_603638 = header.getOrDefault("If-Unmodified-Since")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "If-Unmodified-Since", valid_603638
  var valid_603639 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_603639
  var valid_603640 = header.getOrDefault("If-Modified-Since")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "If-Modified-Since", valid_603640
  var valid_603641 = header.getOrDefault("If-None-Match")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "If-None-Match", valid_603641
  var valid_603642 = header.getOrDefault("x-amz-request-payer")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = newJString("requester"))
  if valid_603642 != nil:
    section.add "x-amz-request-payer", valid_603642
  var valid_603643 = header.getOrDefault("Range")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "Range", valid_603643
  var valid_603644 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_603644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603645: Call_HeadObject_603628; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  let valid = call_603645.validator(path, query, header, formData, body)
  let scheme = call_603645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603645.url(scheme.get, call_603645.host, call_603645.base,
                         call_603645.route, valid.getOrDefault("path"))
  result = hook(call_603645, url, valid)

proc call*(call_603646: Call_HeadObject_603628; Key: string; Bucket: string;
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
  var path_603647 = newJObject()
  var query_603648 = newJObject()
  add(query_603648, "versionId", newJString(versionId))
  add(query_603648, "partNumber", newJInt(partNumber))
  add(path_603647, "Key", newJString(Key))
  add(path_603647, "Bucket", newJString(Bucket))
  result = call_603646.call(path_603647, query_603648, nil, nil, nil)

var headObject* = Call_HeadObject_603628(name: "headObject",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}/{Key}",
                                      validator: validate_HeadObject_603629,
                                      base: "/", url: url_HeadObject_603630,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_603550 = ref object of OpenApiRestCall_602433
proc url_GetObject_603552(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetObject_603551(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603553 = path.getOrDefault("Key")
  valid_603553 = validateParameter(valid_603553, JString, required = true,
                                 default = nil)
  if valid_603553 != nil:
    section.add "Key", valid_603553
  var valid_603554 = path.getOrDefault("Bucket")
  valid_603554 = validateParameter(valid_603554, JString, required = true,
                                 default = nil)
  if valid_603554 != nil:
    section.add "Bucket", valid_603554
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
  var valid_603555 = query.getOrDefault("versionId")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "versionId", valid_603555
  var valid_603556 = query.getOrDefault("partNumber")
  valid_603556 = validateParameter(valid_603556, JInt, required = false, default = nil)
  if valid_603556 != nil:
    section.add "partNumber", valid_603556
  var valid_603557 = query.getOrDefault("response-expires")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "response-expires", valid_603557
  var valid_603558 = query.getOrDefault("response-content-language")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "response-content-language", valid_603558
  var valid_603559 = query.getOrDefault("response-content-encoding")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "response-content-encoding", valid_603559
  var valid_603560 = query.getOrDefault("response-cache-control")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "response-cache-control", valid_603560
  var valid_603561 = query.getOrDefault("response-content-disposition")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "response-content-disposition", valid_603561
  var valid_603562 = query.getOrDefault("response-content-type")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "response-content-type", valid_603562
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
  var valid_603563 = header.getOrDefault("x-amz-security-token")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "x-amz-security-token", valid_603563
  var valid_603564 = header.getOrDefault("If-Match")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "If-Match", valid_603564
  var valid_603565 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_603565
  var valid_603566 = header.getOrDefault("If-Unmodified-Since")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "If-Unmodified-Since", valid_603566
  var valid_603567 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_603567
  var valid_603568 = header.getOrDefault("If-Modified-Since")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "If-Modified-Since", valid_603568
  var valid_603569 = header.getOrDefault("If-None-Match")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "If-None-Match", valid_603569
  var valid_603570 = header.getOrDefault("x-amz-request-payer")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = newJString("requester"))
  if valid_603570 != nil:
    section.add "x-amz-request-payer", valid_603570
  var valid_603571 = header.getOrDefault("Range")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "Range", valid_603571
  var valid_603572 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_603572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603573: Call_GetObject_603550; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves objects from Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  let valid = call_603573.validator(path, query, header, formData, body)
  let scheme = call_603573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603573.url(scheme.get, call_603573.host, call_603573.base,
                         call_603573.route, valid.getOrDefault("path"))
  result = hook(call_603573, url, valid)

proc call*(call_603574: Call_GetObject_603550; Key: string; Bucket: string;
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
  var path_603575 = newJObject()
  var query_603576 = newJObject()
  add(query_603576, "versionId", newJString(versionId))
  add(query_603576, "partNumber", newJInt(partNumber))
  add(query_603576, "response-expires", newJString(responseExpires))
  add(query_603576, "response-content-language",
      newJString(responseContentLanguage))
  add(path_603575, "Key", newJString(Key))
  add(query_603576, "response-content-encoding",
      newJString(responseContentEncoding))
  add(query_603576, "response-cache-control", newJString(responseCacheControl))
  add(path_603575, "Bucket", newJString(Bucket))
  add(query_603576, "response-content-disposition",
      newJString(responseContentDisposition))
  add(query_603576, "response-content-type", newJString(responseContentType))
  result = call_603574.call(path_603575, query_603576, nil, nil, nil)

var getObject* = Call_GetObject_603550(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_GetObject_603551,
                                    base: "/", url: url_GetObject_603552,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_603614 = ref object of OpenApiRestCall_602433
proc url_DeleteObject_603616(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteObject_603615(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603617 = path.getOrDefault("Key")
  valid_603617 = validateParameter(valid_603617, JString, required = true,
                                 default = nil)
  if valid_603617 != nil:
    section.add "Key", valid_603617
  var valid_603618 = path.getOrDefault("Bucket")
  valid_603618 = validateParameter(valid_603618, JString, required = true,
                                 default = nil)
  if valid_603618 != nil:
    section.add "Bucket", valid_603618
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  var valid_603619 = query.getOrDefault("versionId")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "versionId", valid_603619
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
  var valid_603620 = header.getOrDefault("x-amz-security-token")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "x-amz-security-token", valid_603620
  var valid_603621 = header.getOrDefault("x-amz-mfa")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "x-amz-mfa", valid_603621
  var valid_603622 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_603622 = validateParameter(valid_603622, JBool, required = false, default = nil)
  if valid_603622 != nil:
    section.add "x-amz-bypass-governance-retention", valid_603622
  var valid_603623 = header.getOrDefault("x-amz-request-payer")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = newJString("requester"))
  if valid_603623 != nil:
    section.add "x-amz-request-payer", valid_603623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603624: Call_DeleteObject_603614; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  let valid = call_603624.validator(path, query, header, formData, body)
  let scheme = call_603624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603624.url(scheme.get, call_603624.host, call_603624.base,
                         call_603624.route, valid.getOrDefault("path"))
  result = hook(call_603624, url, valid)

proc call*(call_603625: Call_DeleteObject_603614; Key: string; Bucket: string;
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
  var path_603626 = newJObject()
  var query_603627 = newJObject()
  add(query_603627, "versionId", newJString(versionId))
  add(path_603626, "Key", newJString(Key))
  add(path_603626, "Bucket", newJString(Bucket))
  result = call_603625.call(path_603626, query_603627, nil, nil, nil)

var deleteObject* = Call_DeleteObject_603614(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}/{Key}",
    validator: validate_DeleteObject_603615, base: "/", url: url_DeleteObject_603616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectTagging_603661 = ref object of OpenApiRestCall_602433
proc url_PutObjectTagging_603663(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutObjectTagging_603662(path: JsonNode; query: JsonNode;
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
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_603666 = query.getOrDefault("versionId")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "versionId", valid_603666
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603667 = query.getOrDefault("tagging")
  valid_603667 = validateParameter(valid_603667, JBool, required = true, default = nil)
  if valid_603667 != nil:
    section.add "tagging", valid_603667
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603668 = header.getOrDefault("x-amz-security-token")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "x-amz-security-token", valid_603668
  var valid_603669 = header.getOrDefault("Content-MD5")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "Content-MD5", valid_603669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603671: Call_PutObjectTagging_603661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ## 
  let valid = call_603671.validator(path, query, header, formData, body)
  let scheme = call_603671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603671.url(scheme.get, call_603671.host, call_603671.base,
                         call_603671.route, valid.getOrDefault("path"))
  result = hook(call_603671, url, valid)

proc call*(call_603672: Call_PutObjectTagging_603661; tagging: bool; Key: string;
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
  var path_603673 = newJObject()
  var query_603674 = newJObject()
  var body_603675 = newJObject()
  add(query_603674, "versionId", newJString(versionId))
  add(query_603674, "tagging", newJBool(tagging))
  add(path_603673, "Key", newJString(Key))
  add(path_603673, "Bucket", newJString(Bucket))
  if body != nil:
    body_603675 = body
  result = call_603672.call(path_603673, query_603674, nil, nil, body_603675)

var putObjectTagging* = Call_PutObjectTagging_603661(name: "putObjectTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_PutObjectTagging_603662,
    base: "/", url: url_PutObjectTagging_603663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTagging_603649 = ref object of OpenApiRestCall_602433
proc url_GetObjectTagging_603651(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetObjectTagging_603650(path: JsonNode; query: JsonNode;
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
  var valid_603652 = path.getOrDefault("Key")
  valid_603652 = validateParameter(valid_603652, JString, required = true,
                                 default = nil)
  if valid_603652 != nil:
    section.add "Key", valid_603652
  var valid_603653 = path.getOrDefault("Bucket")
  valid_603653 = validateParameter(valid_603653, JString, required = true,
                                 default = nil)
  if valid_603653 != nil:
    section.add "Bucket", valid_603653
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_603654 = query.getOrDefault("versionId")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "versionId", valid_603654
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603655 = query.getOrDefault("tagging")
  valid_603655 = validateParameter(valid_603655, JBool, required = true, default = nil)
  if valid_603655 != nil:
    section.add "tagging", valid_603655
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603656 = header.getOrDefault("x-amz-security-token")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "x-amz-security-token", valid_603656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603657: Call_GetObjectTagging_603649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag-set of an object.
  ## 
  let valid = call_603657.validator(path, query, header, formData, body)
  let scheme = call_603657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603657.url(scheme.get, call_603657.host, call_603657.base,
                         call_603657.route, valid.getOrDefault("path"))
  result = hook(call_603657, url, valid)

proc call*(call_603658: Call_GetObjectTagging_603649; tagging: bool; Key: string;
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
  var path_603659 = newJObject()
  var query_603660 = newJObject()
  add(query_603660, "versionId", newJString(versionId))
  add(query_603660, "tagging", newJBool(tagging))
  add(path_603659, "Key", newJString(Key))
  add(path_603659, "Bucket", newJString(Bucket))
  result = call_603658.call(path_603659, query_603660, nil, nil, nil)

var getObjectTagging* = Call_GetObjectTagging_603649(name: "getObjectTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_GetObjectTagging_603650,
    base: "/", url: url_GetObjectTagging_603651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjectTagging_603676 = ref object of OpenApiRestCall_602433
proc url_DeleteObjectTagging_603678(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteObjectTagging_603677(path: JsonNode; query: JsonNode;
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
  var valid_603679 = path.getOrDefault("Key")
  valid_603679 = validateParameter(valid_603679, JString, required = true,
                                 default = nil)
  if valid_603679 != nil:
    section.add "Key", valid_603679
  var valid_603680 = path.getOrDefault("Bucket")
  valid_603680 = validateParameter(valid_603680, JString, required = true,
                                 default = nil)
  if valid_603680 != nil:
    section.add "Bucket", valid_603680
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The versionId of the object that the tag-set will be removed from.
  ##   tagging: JBool (required)
  section = newJObject()
  var valid_603681 = query.getOrDefault("versionId")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "versionId", valid_603681
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_603682 = query.getOrDefault("tagging")
  valid_603682 = validateParameter(valid_603682, JBool, required = true, default = nil)
  if valid_603682 != nil:
    section.add "tagging", valid_603682
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603683 = header.getOrDefault("x-amz-security-token")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "x-amz-security-token", valid_603683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603684: Call_DeleteObjectTagging_603676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the tag-set from an existing object.
  ## 
  let valid = call_603684.validator(path, query, header, formData, body)
  let scheme = call_603684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603684.url(scheme.get, call_603684.host, call_603684.base,
                         call_603684.route, valid.getOrDefault("path"))
  result = hook(call_603684, url, valid)

proc call*(call_603685: Call_DeleteObjectTagging_603676; tagging: bool; Key: string;
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
  var path_603686 = newJObject()
  var query_603687 = newJObject()
  add(query_603687, "versionId", newJString(versionId))
  add(query_603687, "tagging", newJBool(tagging))
  add(path_603686, "Key", newJString(Key))
  add(path_603686, "Bucket", newJString(Bucket))
  result = call_603685.call(path_603686, query_603687, nil, nil, nil)

var deleteObjectTagging* = Call_DeleteObjectTagging_603676(
    name: "deleteObjectTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#tagging",
    validator: validate_DeleteObjectTagging_603677, base: "/",
    url: url_DeleteObjectTagging_603678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjects_603688 = ref object of OpenApiRestCall_602433
proc url_DeleteObjects_603690(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteObjects_603689(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603691 = path.getOrDefault("Bucket")
  valid_603691 = validateParameter(valid_603691, JString, required = true,
                                 default = nil)
  if valid_603691 != nil:
    section.add "Bucket", valid_603691
  result.add "path", section
  ## parameters in `query` object:
  ##   delete: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `delete` field"
  var valid_603692 = query.getOrDefault("delete")
  valid_603692 = validateParameter(valid_603692, JBool, required = true, default = nil)
  if valid_603692 != nil:
    section.add "delete", valid_603692
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
  var valid_603693 = header.getOrDefault("x-amz-security-token")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "x-amz-security-token", valid_603693
  var valid_603694 = header.getOrDefault("x-amz-mfa")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "x-amz-mfa", valid_603694
  var valid_603695 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_603695 = validateParameter(valid_603695, JBool, required = false, default = nil)
  if valid_603695 != nil:
    section.add "x-amz-bypass-governance-retention", valid_603695
  var valid_603696 = header.getOrDefault("x-amz-request-payer")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = newJString("requester"))
  if valid_603696 != nil:
    section.add "x-amz-request-payer", valid_603696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603698: Call_DeleteObjects_603688; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  let valid = call_603698.validator(path, query, header, formData, body)
  let scheme = call_603698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603698.url(scheme.get, call_603698.host, call_603698.base,
                         call_603698.route, valid.getOrDefault("path"))
  result = hook(call_603698, url, valid)

proc call*(call_603699: Call_DeleteObjects_603688; Bucket: string; body: JsonNode;
          delete: bool): Recallable =
  ## deleteObjects
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   delete: bool (required)
  var path_603700 = newJObject()
  var query_603701 = newJObject()
  var body_603702 = newJObject()
  add(path_603700, "Bucket", newJString(Bucket))
  if body != nil:
    body_603702 = body
  add(query_603701, "delete", newJBool(delete))
  result = call_603699.call(path_603700, query_603701, nil, nil, body_603702)

var deleteObjects* = Call_DeleteObjects_603688(name: "deleteObjects",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com", route: "/{Bucket}#delete",
    validator: validate_DeleteObjects_603689, base: "/", url: url_DeleteObjects_603690,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_603713 = ref object of OpenApiRestCall_602433
proc url_PutPublicAccessBlock_603715(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutPublicAccessBlock_603714(path: JsonNode; query: JsonNode;
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
  var valid_603716 = path.getOrDefault("Bucket")
  valid_603716 = validateParameter(valid_603716, JString, required = true,
                                 default = nil)
  if valid_603716 != nil:
    section.add "Bucket", valid_603716
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_603717 = query.getOrDefault("publicAccessBlock")
  valid_603717 = validateParameter(valid_603717, JBool, required = true, default = nil)
  if valid_603717 != nil:
    section.add "publicAccessBlock", valid_603717
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash of the <code>PutPublicAccessBlock</code> request body. 
  section = newJObject()
  var valid_603718 = header.getOrDefault("x-amz-security-token")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "x-amz-security-token", valid_603718
  var valid_603719 = header.getOrDefault("Content-MD5")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "Content-MD5", valid_603719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603721: Call_PutPublicAccessBlock_603713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_603721.validator(path, query, header, formData, body)
  let scheme = call_603721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603721.url(scheme.get, call_603721.host, call_603721.base,
                         call_603721.route, valid.getOrDefault("path"))
  result = hook(call_603721, url, valid)

proc call*(call_603722: Call_PutPublicAccessBlock_603713; publicAccessBlock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to set.
  ##   body: JObject (required)
  var path_603723 = newJObject()
  var query_603724 = newJObject()
  var body_603725 = newJObject()
  add(query_603724, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_603723, "Bucket", newJString(Bucket))
  if body != nil:
    body_603725 = body
  result = call_603722.call(path_603723, query_603724, nil, nil, body_603725)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_603713(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_PutPublicAccessBlock_603714, base: "/",
    url: url_PutPublicAccessBlock_603715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_603703 = ref object of OpenApiRestCall_602433
proc url_GetPublicAccessBlock_603705(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetPublicAccessBlock_603704(path: JsonNode; query: JsonNode;
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
  var valid_603706 = path.getOrDefault("Bucket")
  valid_603706 = validateParameter(valid_603706, JString, required = true,
                                 default = nil)
  if valid_603706 != nil:
    section.add "Bucket", valid_603706
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_603707 = query.getOrDefault("publicAccessBlock")
  valid_603707 = validateParameter(valid_603707, JBool, required = true, default = nil)
  if valid_603707 != nil:
    section.add "publicAccessBlock", valid_603707
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603708 = header.getOrDefault("x-amz-security-token")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "x-amz-security-token", valid_603708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603709: Call_GetPublicAccessBlock_603703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_603709.validator(path, query, header, formData, body)
  let scheme = call_603709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603709.url(scheme.get, call_603709.host, call_603709.base,
                         call_603709.route, valid.getOrDefault("path"))
  result = hook(call_603709, url, valid)

proc call*(call_603710: Call_GetPublicAccessBlock_603703; publicAccessBlock: bool;
          Bucket: string): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to retrieve. 
  var path_603711 = newJObject()
  var query_603712 = newJObject()
  add(query_603712, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_603711, "Bucket", newJString(Bucket))
  result = call_603710.call(path_603711, query_603712, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_603703(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_GetPublicAccessBlock_603704, base: "/",
    url: url_GetPublicAccessBlock_603705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_603726 = ref object of OpenApiRestCall_602433
proc url_DeletePublicAccessBlock_603728(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeletePublicAccessBlock_603727(path: JsonNode; query: JsonNode;
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
  var valid_603729 = path.getOrDefault("Bucket")
  valid_603729 = validateParameter(valid_603729, JString, required = true,
                                 default = nil)
  if valid_603729 != nil:
    section.add "Bucket", valid_603729
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_603730 = query.getOrDefault("publicAccessBlock")
  valid_603730 = validateParameter(valid_603730, JBool, required = true, default = nil)
  if valid_603730 != nil:
    section.add "publicAccessBlock", valid_603730
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603731 = header.getOrDefault("x-amz-security-token")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "x-amz-security-token", valid_603731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603732: Call_DeletePublicAccessBlock_603726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ## 
  let valid = call_603732.validator(path, query, header, formData, body)
  let scheme = call_603732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603732.url(scheme.get, call_603732.host, call_603732.base,
                         call_603732.route, valid.getOrDefault("path"))
  result = hook(call_603732, url, valid)

proc call*(call_603733: Call_DeletePublicAccessBlock_603726;
          publicAccessBlock: bool; Bucket: string): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to delete. 
  var path_603734 = newJObject()
  var query_603735 = newJObject()
  add(query_603735, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_603734, "Bucket", newJString(Bucket))
  result = call_603733.call(path_603734, query_603735, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_603726(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_DeletePublicAccessBlock_603727, base: "/",
    url: url_DeletePublicAccessBlock_603728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAccelerateConfiguration_603746 = ref object of OpenApiRestCall_602433
proc url_PutBucketAccelerateConfiguration_603748(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketAccelerateConfiguration_603747(path: JsonNode;
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
  var valid_603749 = path.getOrDefault("Bucket")
  valid_603749 = validateParameter(valid_603749, JString, required = true,
                                 default = nil)
  if valid_603749 != nil:
    section.add "Bucket", valid_603749
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_603750 = query.getOrDefault("accelerate")
  valid_603750 = validateParameter(valid_603750, JBool, required = true, default = nil)
  if valid_603750 != nil:
    section.add "accelerate", valid_603750
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603751 = header.getOrDefault("x-amz-security-token")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "x-amz-security-token", valid_603751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603753: Call_PutBucketAccelerateConfiguration_603746;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the accelerate configuration of an existing bucket.
  ## 
  let valid = call_603753.validator(path, query, header, formData, body)
  let scheme = call_603753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603753.url(scheme.get, call_603753.host, call_603753.base,
                         call_603753.route, valid.getOrDefault("path"))
  result = hook(call_603753, url, valid)

proc call*(call_603754: Call_PutBucketAccelerateConfiguration_603746;
          accelerate: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketAccelerateConfiguration
  ## Sets the accelerate configuration of an existing bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is set.
  ##   body: JObject (required)
  var path_603755 = newJObject()
  var query_603756 = newJObject()
  var body_603757 = newJObject()
  add(query_603756, "accelerate", newJBool(accelerate))
  add(path_603755, "Bucket", newJString(Bucket))
  if body != nil:
    body_603757 = body
  result = call_603754.call(path_603755, query_603756, nil, nil, body_603757)

var putBucketAccelerateConfiguration* = Call_PutBucketAccelerateConfiguration_603746(
    name: "putBucketAccelerateConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_PutBucketAccelerateConfiguration_603747, base: "/",
    url: url_PutBucketAccelerateConfiguration_603748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAccelerateConfiguration_603736 = ref object of OpenApiRestCall_602433
proc url_GetBucketAccelerateConfiguration_603738(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketAccelerateConfiguration_603737(path: JsonNode;
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
  var valid_603739 = path.getOrDefault("Bucket")
  valid_603739 = validateParameter(valid_603739, JString, required = true,
                                 default = nil)
  if valid_603739 != nil:
    section.add "Bucket", valid_603739
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_603740 = query.getOrDefault("accelerate")
  valid_603740 = validateParameter(valid_603740, JBool, required = true, default = nil)
  if valid_603740 != nil:
    section.add "accelerate", valid_603740
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

proc call*(call_603742: Call_GetBucketAccelerateConfiguration_603736;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the accelerate configuration of a bucket.
  ## 
  let valid = call_603742.validator(path, query, header, formData, body)
  let scheme = call_603742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603742.url(scheme.get, call_603742.host, call_603742.base,
                         call_603742.route, valid.getOrDefault("path"))
  result = hook(call_603742, url, valid)

proc call*(call_603743: Call_GetBucketAccelerateConfiguration_603736;
          accelerate: bool; Bucket: string): Recallable =
  ## getBucketAccelerateConfiguration
  ## Returns the accelerate configuration of a bucket.
  ##   accelerate: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is retrieved.
  var path_603744 = newJObject()
  var query_603745 = newJObject()
  add(query_603745, "accelerate", newJBool(accelerate))
  add(path_603744, "Bucket", newJString(Bucket))
  result = call_603743.call(path_603744, query_603745, nil, nil, nil)

var getBucketAccelerateConfiguration* = Call_GetBucketAccelerateConfiguration_603736(
    name: "getBucketAccelerateConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_GetBucketAccelerateConfiguration_603737, base: "/",
    url: url_GetBucketAccelerateConfiguration_603738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAcl_603768 = ref object of OpenApiRestCall_602433
proc url_PutBucketAcl_603770(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketAcl_603769(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603771 = path.getOrDefault("Bucket")
  valid_603771 = validateParameter(valid_603771, JString, required = true,
                                 default = nil)
  if valid_603771 != nil:
    section.add "Bucket", valid_603771
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_603772 = query.getOrDefault("acl")
  valid_603772 = validateParameter(valid_603772, JBool, required = true, default = nil)
  if valid_603772 != nil:
    section.add "acl", valid_603772
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
  var valid_603773 = header.getOrDefault("x-amz-security-token")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "x-amz-security-token", valid_603773
  var valid_603774 = header.getOrDefault("Content-MD5")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "Content-MD5", valid_603774
  var valid_603775 = header.getOrDefault("x-amz-acl")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = newJString("private"))
  if valid_603775 != nil:
    section.add "x-amz-acl", valid_603775
  var valid_603776 = header.getOrDefault("x-amz-grant-read")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "x-amz-grant-read", valid_603776
  var valid_603777 = header.getOrDefault("x-amz-grant-read-acp")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "x-amz-grant-read-acp", valid_603777
  var valid_603778 = header.getOrDefault("x-amz-grant-write")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "x-amz-grant-write", valid_603778
  var valid_603779 = header.getOrDefault("x-amz-grant-write-acp")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "x-amz-grant-write-acp", valid_603779
  var valid_603780 = header.getOrDefault("x-amz-grant-full-control")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "x-amz-grant-full-control", valid_603780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603782: Call_PutBucketAcl_603768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  let valid = call_603782.validator(path, query, header, formData, body)
  let scheme = call_603782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603782.url(scheme.get, call_603782.host, call_603782.base,
                         call_603782.route, valid.getOrDefault("path"))
  result = hook(call_603782, url, valid)

proc call*(call_603783: Call_PutBucketAcl_603768; acl: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketAcl
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603784 = newJObject()
  var query_603785 = newJObject()
  var body_603786 = newJObject()
  add(query_603785, "acl", newJBool(acl))
  add(path_603784, "Bucket", newJString(Bucket))
  if body != nil:
    body_603786 = body
  result = call_603783.call(path_603784, query_603785, nil, nil, body_603786)

var putBucketAcl* = Call_PutBucketAcl_603768(name: "putBucketAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_PutBucketAcl_603769, base: "/", url: url_PutBucketAcl_603770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAcl_603758 = ref object of OpenApiRestCall_602433
proc url_GetBucketAcl_603760(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketAcl_603759(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603761 = path.getOrDefault("Bucket")
  valid_603761 = validateParameter(valid_603761, JString, required = true,
                                 default = nil)
  if valid_603761 != nil:
    section.add "Bucket", valid_603761
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_603762 = query.getOrDefault("acl")
  valid_603762 = validateParameter(valid_603762, JBool, required = true, default = nil)
  if valid_603762 != nil:
    section.add "acl", valid_603762
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603763 = header.getOrDefault("x-amz-security-token")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "x-amz-security-token", valid_603763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603764: Call_GetBucketAcl_603758; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the access control policy for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  let valid = call_603764.validator(path, query, header, formData, body)
  let scheme = call_603764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603764.url(scheme.get, call_603764.host, call_603764.base,
                         call_603764.route, valid.getOrDefault("path"))
  result = hook(call_603764, url, valid)

proc call*(call_603765: Call_GetBucketAcl_603758; acl: bool; Bucket: string): Recallable =
  ## getBucketAcl
  ## Gets the access control policy for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  ##   acl: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603766 = newJObject()
  var query_603767 = newJObject()
  add(query_603767, "acl", newJBool(acl))
  add(path_603766, "Bucket", newJString(Bucket))
  result = call_603765.call(path_603766, query_603767, nil, nil, nil)

var getBucketAcl* = Call_GetBucketAcl_603758(name: "getBucketAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_GetBucketAcl_603759, base: "/", url: url_GetBucketAcl_603760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycle_603797 = ref object of OpenApiRestCall_602433
proc url_PutBucketLifecycle_603799(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketLifecycle_603798(path: JsonNode; query: JsonNode;
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
  var valid_603800 = path.getOrDefault("Bucket")
  valid_603800 = validateParameter(valid_603800, JString, required = true,
                                 default = nil)
  if valid_603800 != nil:
    section.add "Bucket", valid_603800
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_603801 = query.getOrDefault("lifecycle")
  valid_603801 = validateParameter(valid_603801, JBool, required = true, default = nil)
  if valid_603801 != nil:
    section.add "lifecycle", valid_603801
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603802 = header.getOrDefault("x-amz-security-token")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "x-amz-security-token", valid_603802
  var valid_603803 = header.getOrDefault("Content-MD5")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "Content-MD5", valid_603803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603805: Call_PutBucketLifecycle_603797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  let valid = call_603805.validator(path, query, header, formData, body)
  let scheme = call_603805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603805.url(scheme.get, call_603805.host, call_603805.base,
                         call_603805.route, valid.getOrDefault("path"))
  result = hook(call_603805, url, valid)

proc call*(call_603806: Call_PutBucketLifecycle_603797; Bucket: string;
          lifecycle: bool; body: JsonNode): Recallable =
  ## putBucketLifecycle
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  ##   body: JObject (required)
  var path_603807 = newJObject()
  var query_603808 = newJObject()
  var body_603809 = newJObject()
  add(path_603807, "Bucket", newJString(Bucket))
  add(query_603808, "lifecycle", newJBool(lifecycle))
  if body != nil:
    body_603809 = body
  result = call_603806.call(path_603807, query_603808, nil, nil, body_603809)

var putBucketLifecycle* = Call_PutBucketLifecycle_603797(
    name: "putBucketLifecycle", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_PutBucketLifecycle_603798, base: "/",
    url: url_PutBucketLifecycle_603799, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycle_603787 = ref object of OpenApiRestCall_602433
proc url_GetBucketLifecycle_603789(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketLifecycle_603788(path: JsonNode; query: JsonNode;
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
  var valid_603790 = path.getOrDefault("Bucket")
  valid_603790 = validateParameter(valid_603790, JString, required = true,
                                 default = nil)
  if valid_603790 != nil:
    section.add "Bucket", valid_603790
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_603791 = query.getOrDefault("lifecycle")
  valid_603791 = validateParameter(valid_603791, JBool, required = true, default = nil)
  if valid_603791 != nil:
    section.add "lifecycle", valid_603791
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603792 = header.getOrDefault("x-amz-security-token")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "x-amz-security-token", valid_603792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603793: Call_GetBucketLifecycle_603787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  let valid = call_603793.validator(path, query, header, formData, body)
  let scheme = call_603793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603793.url(scheme.get, call_603793.host, call_603793.base,
                         call_603793.route, valid.getOrDefault("path"))
  result = hook(call_603793, url, valid)

proc call*(call_603794: Call_GetBucketLifecycle_603787; Bucket: string;
          lifecycle: bool): Recallable =
  ## getBucketLifecycle
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_603795 = newJObject()
  var query_603796 = newJObject()
  add(path_603795, "Bucket", newJString(Bucket))
  add(query_603796, "lifecycle", newJBool(lifecycle))
  result = call_603794.call(path_603795, query_603796, nil, nil, nil)

var getBucketLifecycle* = Call_GetBucketLifecycle_603787(
    name: "getBucketLifecycle", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_GetBucketLifecycle_603788, base: "/",
    url: url_GetBucketLifecycle_603789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLocation_603810 = ref object of OpenApiRestCall_602433
proc url_GetBucketLocation_603812(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketLocation_603811(path: JsonNode; query: JsonNode;
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
  var valid_603813 = path.getOrDefault("Bucket")
  valid_603813 = validateParameter(valid_603813, JString, required = true,
                                 default = nil)
  if valid_603813 != nil:
    section.add "Bucket", valid_603813
  result.add "path", section
  ## parameters in `query` object:
  ##   location: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `location` field"
  var valid_603814 = query.getOrDefault("location")
  valid_603814 = validateParameter(valid_603814, JBool, required = true, default = nil)
  if valid_603814 != nil:
    section.add "location", valid_603814
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603815 = header.getOrDefault("x-amz-security-token")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "x-amz-security-token", valid_603815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603816: Call_GetBucketLocation_603810; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the region the bucket resides in.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  let valid = call_603816.validator(path, query, header, formData, body)
  let scheme = call_603816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603816.url(scheme.get, call_603816.host, call_603816.base,
                         call_603816.route, valid.getOrDefault("path"))
  result = hook(call_603816, url, valid)

proc call*(call_603817: Call_GetBucketLocation_603810; location: bool; Bucket: string): Recallable =
  ## getBucketLocation
  ## Returns the region the bucket resides in.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  ##   location: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603818 = newJObject()
  var query_603819 = newJObject()
  add(query_603819, "location", newJBool(location))
  add(path_603818, "Bucket", newJString(Bucket))
  result = call_603817.call(path_603818, query_603819, nil, nil, nil)

var getBucketLocation* = Call_GetBucketLocation_603810(name: "getBucketLocation",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#location",
    validator: validate_GetBucketLocation_603811, base: "/",
    url: url_GetBucketLocation_603812, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLogging_603830 = ref object of OpenApiRestCall_602433
proc url_PutBucketLogging_603832(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketLogging_603831(path: JsonNode; query: JsonNode;
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
  var valid_603833 = path.getOrDefault("Bucket")
  valid_603833 = validateParameter(valid_603833, JString, required = true,
                                 default = nil)
  if valid_603833 != nil:
    section.add "Bucket", valid_603833
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_603834 = query.getOrDefault("logging")
  valid_603834 = validateParameter(valid_603834, JBool, required = true, default = nil)
  if valid_603834 != nil:
    section.add "logging", valid_603834
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

proc call*(call_603838: Call_PutBucketLogging_603830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  let valid = call_603838.validator(path, query, header, formData, body)
  let scheme = call_603838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603838.url(scheme.get, call_603838.host, call_603838.base,
                         call_603838.route, valid.getOrDefault("path"))
  result = hook(call_603838, url, valid)

proc call*(call_603839: Call_PutBucketLogging_603830; logging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketLogging
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603840 = newJObject()
  var query_603841 = newJObject()
  var body_603842 = newJObject()
  add(query_603841, "logging", newJBool(logging))
  add(path_603840, "Bucket", newJString(Bucket))
  if body != nil:
    body_603842 = body
  result = call_603839.call(path_603840, query_603841, nil, nil, body_603842)

var putBucketLogging* = Call_PutBucketLogging_603830(name: "putBucketLogging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_PutBucketLogging_603831, base: "/",
    url: url_PutBucketLogging_603832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLogging_603820 = ref object of OpenApiRestCall_602433
proc url_GetBucketLogging_603822(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketLogging_603821(path: JsonNode; query: JsonNode;
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
  var valid_603823 = path.getOrDefault("Bucket")
  valid_603823 = validateParameter(valid_603823, JString, required = true,
                                 default = nil)
  if valid_603823 != nil:
    section.add "Bucket", valid_603823
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_603824 = query.getOrDefault("logging")
  valid_603824 = validateParameter(valid_603824, JBool, required = true, default = nil)
  if valid_603824 != nil:
    section.add "logging", valid_603824
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

proc call*(call_603826: Call_GetBucketLogging_603820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  let valid = call_603826.validator(path, query, header, formData, body)
  let scheme = call_603826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603826.url(scheme.get, call_603826.host, call_603826.base,
                         call_603826.route, valid.getOrDefault("path"))
  result = hook(call_603826, url, valid)

proc call*(call_603827: Call_GetBucketLogging_603820; logging: bool; Bucket: string): Recallable =
  ## getBucketLogging
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  ##   logging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603828 = newJObject()
  var query_603829 = newJObject()
  add(query_603829, "logging", newJBool(logging))
  add(path_603828, "Bucket", newJString(Bucket))
  result = call_603827.call(path_603828, query_603829, nil, nil, nil)

var getBucketLogging* = Call_GetBucketLogging_603820(name: "getBucketLogging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_GetBucketLogging_603821, base: "/",
    url: url_GetBucketLogging_603822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotificationConfiguration_603853 = ref object of OpenApiRestCall_602433
proc url_PutBucketNotificationConfiguration_603855(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketNotificationConfiguration_603854(path: JsonNode;
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
  var valid_603856 = path.getOrDefault("Bucket")
  valid_603856 = validateParameter(valid_603856, JString, required = true,
                                 default = nil)
  if valid_603856 != nil:
    section.add "Bucket", valid_603856
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_603857 = query.getOrDefault("notification")
  valid_603857 = validateParameter(valid_603857, JBool, required = true, default = nil)
  if valid_603857 != nil:
    section.add "notification", valid_603857
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603860: Call_PutBucketNotificationConfiguration_603853;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enables notifications of specified events for a bucket.
  ## 
  let valid = call_603860.validator(path, query, header, formData, body)
  let scheme = call_603860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603860.url(scheme.get, call_603860.host, call_603860.base,
                         call_603860.route, valid.getOrDefault("path"))
  result = hook(call_603860, url, valid)

proc call*(call_603861: Call_PutBucketNotificationConfiguration_603853;
          notification: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotificationConfiguration
  ## Enables notifications of specified events for a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603862 = newJObject()
  var query_603863 = newJObject()
  var body_603864 = newJObject()
  add(query_603863, "notification", newJBool(notification))
  add(path_603862, "Bucket", newJString(Bucket))
  if body != nil:
    body_603864 = body
  result = call_603861.call(path_603862, query_603863, nil, nil, body_603864)

var putBucketNotificationConfiguration* = Call_PutBucketNotificationConfiguration_603853(
    name: "putBucketNotificationConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_PutBucketNotificationConfiguration_603854, base: "/",
    url: url_PutBucketNotificationConfiguration_603855,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotificationConfiguration_603843 = ref object of OpenApiRestCall_602433
proc url_GetBucketNotificationConfiguration_603845(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketNotificationConfiguration_603844(path: JsonNode;
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
  var valid_603846 = path.getOrDefault("Bucket")
  valid_603846 = validateParameter(valid_603846, JString, required = true,
                                 default = nil)
  if valid_603846 != nil:
    section.add "Bucket", valid_603846
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_603847 = query.getOrDefault("notification")
  valid_603847 = validateParameter(valid_603847, JBool, required = true, default = nil)
  if valid_603847 != nil:
    section.add "notification", valid_603847
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

proc call*(call_603849: Call_GetBucketNotificationConfiguration_603843;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the notification configuration of a bucket.
  ## 
  let valid = call_603849.validator(path, query, header, formData, body)
  let scheme = call_603849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603849.url(scheme.get, call_603849.host, call_603849.base,
                         call_603849.route, valid.getOrDefault("path"))
  result = hook(call_603849, url, valid)

proc call*(call_603850: Call_GetBucketNotificationConfiguration_603843;
          notification: bool; Bucket: string): Recallable =
  ## getBucketNotificationConfiguration
  ## Returns the notification configuration of a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_603851 = newJObject()
  var query_603852 = newJObject()
  add(query_603852, "notification", newJBool(notification))
  add(path_603851, "Bucket", newJString(Bucket))
  result = call_603850.call(path_603851, query_603852, nil, nil, nil)

var getBucketNotificationConfiguration* = Call_GetBucketNotificationConfiguration_603843(
    name: "getBucketNotificationConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_GetBucketNotificationConfiguration_603844, base: "/",
    url: url_GetBucketNotificationConfiguration_603845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotification_603875 = ref object of OpenApiRestCall_602433
proc url_PutBucketNotification_603877(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketNotification_603876(path: JsonNode; query: JsonNode;
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
  var valid_603878 = path.getOrDefault("Bucket")
  valid_603878 = validateParameter(valid_603878, JString, required = true,
                                 default = nil)
  if valid_603878 != nil:
    section.add "Bucket", valid_603878
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_603879 = query.getOrDefault("notification")
  valid_603879 = validateParameter(valid_603879, JBool, required = true, default = nil)
  if valid_603879 != nil:
    section.add "notification", valid_603879
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_603880 = header.getOrDefault("x-amz-security-token")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "x-amz-security-token", valid_603880
  var valid_603881 = header.getOrDefault("Content-MD5")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "Content-MD5", valid_603881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603883: Call_PutBucketNotification_603875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  let valid = call_603883.validator(path, query, header, formData, body)
  let scheme = call_603883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603883.url(scheme.get, call_603883.host, call_603883.base,
                         call_603883.route, valid.getOrDefault("path"))
  result = hook(call_603883, url, valid)

proc call*(call_603884: Call_PutBucketNotification_603875; notification: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotification
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603885 = newJObject()
  var query_603886 = newJObject()
  var body_603887 = newJObject()
  add(query_603886, "notification", newJBool(notification))
  add(path_603885, "Bucket", newJString(Bucket))
  if body != nil:
    body_603887 = body
  result = call_603884.call(path_603885, query_603886, nil, nil, body_603887)

var putBucketNotification* = Call_PutBucketNotification_603875(
    name: "putBucketNotification", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_PutBucketNotification_603876, base: "/",
    url: url_PutBucketNotification_603877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotification_603865 = ref object of OpenApiRestCall_602433
proc url_GetBucketNotification_603867(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketNotification_603866(path: JsonNode; query: JsonNode;
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
  var valid_603868 = path.getOrDefault("Bucket")
  valid_603868 = validateParameter(valid_603868, JString, required = true,
                                 default = nil)
  if valid_603868 != nil:
    section.add "Bucket", valid_603868
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_603869 = query.getOrDefault("notification")
  valid_603869 = validateParameter(valid_603869, JBool, required = true, default = nil)
  if valid_603869 != nil:
    section.add "notification", valid_603869
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603870 = header.getOrDefault("x-amz-security-token")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "x-amz-security-token", valid_603870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603871: Call_GetBucketNotification_603865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  let valid = call_603871.validator(path, query, header, formData, body)
  let scheme = call_603871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603871.url(scheme.get, call_603871.host, call_603871.base,
                         call_603871.route, valid.getOrDefault("path"))
  result = hook(call_603871, url, valid)

proc call*(call_603872: Call_GetBucketNotification_603865; notification: bool;
          Bucket: string): Recallable =
  ## getBucketNotification
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_603873 = newJObject()
  var query_603874 = newJObject()
  add(query_603874, "notification", newJBool(notification))
  add(path_603873, "Bucket", newJString(Bucket))
  result = call_603872.call(path_603873, query_603874, nil, nil, nil)

var getBucketNotification* = Call_GetBucketNotification_603865(
    name: "getBucketNotification", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_GetBucketNotification_603866, base: "/",
    url: url_GetBucketNotification_603867, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicyStatus_603888 = ref object of OpenApiRestCall_602433
proc url_GetBucketPolicyStatus_603890(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketPolicyStatus_603889(path: JsonNode; query: JsonNode;
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
  var valid_603891 = path.getOrDefault("Bucket")
  valid_603891 = validateParameter(valid_603891, JString, required = true,
                                 default = nil)
  if valid_603891 != nil:
    section.add "Bucket", valid_603891
  result.add "path", section
  ## parameters in `query` object:
  ##   policyStatus: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `policyStatus` field"
  var valid_603892 = query.getOrDefault("policyStatus")
  valid_603892 = validateParameter(valid_603892, JBool, required = true, default = nil)
  if valid_603892 != nil:
    section.add "policyStatus", valid_603892
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_603893 = header.getOrDefault("x-amz-security-token")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "x-amz-security-token", valid_603893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603894: Call_GetBucketPolicyStatus_603888; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ## 
  let valid = call_603894.validator(path, query, header, formData, body)
  let scheme = call_603894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603894.url(scheme.get, call_603894.host, call_603894.base,
                         call_603894.route, valid.getOrDefault("path"))
  result = hook(call_603894, url, valid)

proc call*(call_603895: Call_GetBucketPolicyStatus_603888; policyStatus: bool;
          Bucket: string): Recallable =
  ## getBucketPolicyStatus
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ##   policyStatus: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose policy status you want to retrieve.
  var path_603896 = newJObject()
  var query_603897 = newJObject()
  add(query_603897, "policyStatus", newJBool(policyStatus))
  add(path_603896, "Bucket", newJString(Bucket))
  result = call_603895.call(path_603896, query_603897, nil, nil, nil)

var getBucketPolicyStatus* = Call_GetBucketPolicyStatus_603888(
    name: "getBucketPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#policyStatus",
    validator: validate_GetBucketPolicyStatus_603889, base: "/",
    url: url_GetBucketPolicyStatus_603890, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketRequestPayment_603908 = ref object of OpenApiRestCall_602433
proc url_PutBucketRequestPayment_603910(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketRequestPayment_603909(path: JsonNode; query: JsonNode;
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
  var valid_603911 = path.getOrDefault("Bucket")
  valid_603911 = validateParameter(valid_603911, JString, required = true,
                                 default = nil)
  if valid_603911 != nil:
    section.add "Bucket", valid_603911
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_603912 = query.getOrDefault("requestPayment")
  valid_603912 = validateParameter(valid_603912, JBool, required = true, default = nil)
  if valid_603912 != nil:
    section.add "requestPayment", valid_603912
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

proc call*(call_603916: Call_PutBucketRequestPayment_603908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  let valid = call_603916.validator(path, query, header, formData, body)
  let scheme = call_603916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603916.url(scheme.get, call_603916.host, call_603916.base,
                         call_603916.route, valid.getOrDefault("path"))
  result = hook(call_603916, url, valid)

proc call*(call_603917: Call_PutBucketRequestPayment_603908; requestPayment: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketRequestPayment
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_603918 = newJObject()
  var query_603919 = newJObject()
  var body_603920 = newJObject()
  add(query_603919, "requestPayment", newJBool(requestPayment))
  add(path_603918, "Bucket", newJString(Bucket))
  if body != nil:
    body_603920 = body
  result = call_603917.call(path_603918, query_603919, nil, nil, body_603920)

var putBucketRequestPayment* = Call_PutBucketRequestPayment_603908(
    name: "putBucketRequestPayment", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_PutBucketRequestPayment_603909, base: "/",
    url: url_PutBucketRequestPayment_603910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketRequestPayment_603898 = ref object of OpenApiRestCall_602433
proc url_GetBucketRequestPayment_603900(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketRequestPayment_603899(path: JsonNode; query: JsonNode;
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
  var valid_603901 = path.getOrDefault("Bucket")
  valid_603901 = validateParameter(valid_603901, JString, required = true,
                                 default = nil)
  if valid_603901 != nil:
    section.add "Bucket", valid_603901
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_603902 = query.getOrDefault("requestPayment")
  valid_603902 = validateParameter(valid_603902, JBool, required = true, default = nil)
  if valid_603902 != nil:
    section.add "requestPayment", valid_603902
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

proc call*(call_603904: Call_GetBucketRequestPayment_603898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the request payment configuration of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  let valid = call_603904.validator(path, query, header, formData, body)
  let scheme = call_603904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603904.url(scheme.get, call_603904.host, call_603904.base,
                         call_603904.route, valid.getOrDefault("path"))
  result = hook(call_603904, url, valid)

proc call*(call_603905: Call_GetBucketRequestPayment_603898; requestPayment: bool;
          Bucket: string): Recallable =
  ## getBucketRequestPayment
  ## Returns the request payment configuration of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_603906 = newJObject()
  var query_603907 = newJObject()
  add(query_603907, "requestPayment", newJBool(requestPayment))
  add(path_603906, "Bucket", newJString(Bucket))
  result = call_603905.call(path_603906, query_603907, nil, nil, nil)

var getBucketRequestPayment* = Call_GetBucketRequestPayment_603898(
    name: "getBucketRequestPayment", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_GetBucketRequestPayment_603899, base: "/",
    url: url_GetBucketRequestPayment_603900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketVersioning_603931 = ref object of OpenApiRestCall_602433
proc url_PutBucketVersioning_603933(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutBucketVersioning_603932(path: JsonNode; query: JsonNode;
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
  var valid_603934 = path.getOrDefault("Bucket")
  valid_603934 = validateParameter(valid_603934, JString, required = true,
                                 default = nil)
  if valid_603934 != nil:
    section.add "Bucket", valid_603934
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_603935 = query.getOrDefault("versioning")
  valid_603935 = validateParameter(valid_603935, JBool, required = true, default = nil)
  if valid_603935 != nil:
    section.add "versioning", valid_603935
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  section = newJObject()
  var valid_603936 = header.getOrDefault("x-amz-security-token")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "x-amz-security-token", valid_603936
  var valid_603937 = header.getOrDefault("Content-MD5")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "Content-MD5", valid_603937
  var valid_603938 = header.getOrDefault("x-amz-mfa")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "x-amz-mfa", valid_603938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603940: Call_PutBucketVersioning_603931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  let valid = call_603940.validator(path, query, header, formData, body)
  let scheme = call_603940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603940.url(scheme.get, call_603940.host, call_603940.base,
                         call_603940.route, valid.getOrDefault("path"))
  result = hook(call_603940, url, valid)

proc call*(call_603941: Call_PutBucketVersioning_603931; Bucket: string;
          body: JsonNode; versioning: bool): Recallable =
  ## putBucketVersioning
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   versioning: bool (required)
  var path_603942 = newJObject()
  var query_603943 = newJObject()
  var body_603944 = newJObject()
  add(path_603942, "Bucket", newJString(Bucket))
  if body != nil:
    body_603944 = body
  add(query_603943, "versioning", newJBool(versioning))
  result = call_603941.call(path_603942, query_603943, nil, nil, body_603944)

var putBucketVersioning* = Call_PutBucketVersioning_603931(
    name: "putBucketVersioning", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_PutBucketVersioning_603932,
    base: "/", url: url_PutBucketVersioning_603933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketVersioning_603921 = ref object of OpenApiRestCall_602433
proc url_GetBucketVersioning_603923(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetBucketVersioning_603922(path: JsonNode; query: JsonNode;
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
  var valid_603924 = path.getOrDefault("Bucket")
  valid_603924 = validateParameter(valid_603924, JString, required = true,
                                 default = nil)
  if valid_603924 != nil:
    section.add "Bucket", valid_603924
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_603925 = query.getOrDefault("versioning")
  valid_603925 = validateParameter(valid_603925, JBool, required = true, default = nil)
  if valid_603925 != nil:
    section.add "versioning", valid_603925
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

proc call*(call_603927: Call_GetBucketVersioning_603921; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the versioning state of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  let valid = call_603927.validator(path, query, header, formData, body)
  let scheme = call_603927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603927.url(scheme.get, call_603927.host, call_603927.base,
                         call_603927.route, valid.getOrDefault("path"))
  result = hook(call_603927, url, valid)

proc call*(call_603928: Call_GetBucketVersioning_603921; Bucket: string;
          versioning: bool): Recallable =
  ## getBucketVersioning
  ## Returns the versioning state of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versioning: bool (required)
  var path_603929 = newJObject()
  var query_603930 = newJObject()
  add(path_603929, "Bucket", newJString(Bucket))
  add(query_603930, "versioning", newJBool(versioning))
  result = call_603928.call(path_603929, query_603930, nil, nil, nil)

var getBucketVersioning* = Call_GetBucketVersioning_603921(
    name: "getBucketVersioning", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_GetBucketVersioning_603922,
    base: "/", url: url_GetBucketVersioning_603923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectAcl_603958 = ref object of OpenApiRestCall_602433
proc url_PutObjectAcl_603960(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutObjectAcl_603959(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603961 = path.getOrDefault("Key")
  valid_603961 = validateParameter(valid_603961, JString, required = true,
                                 default = nil)
  if valid_603961 != nil:
    section.add "Key", valid_603961
  var valid_603962 = path.getOrDefault("Bucket")
  valid_603962 = validateParameter(valid_603962, JString, required = true,
                                 default = nil)
  if valid_603962 != nil:
    section.add "Bucket", valid_603962
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_603963 = query.getOrDefault("versionId")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "versionId", valid_603963
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_603964 = query.getOrDefault("acl")
  valid_603964 = validateParameter(valid_603964, JBool, required = true, default = nil)
  if valid_603964 != nil:
    section.add "acl", valid_603964
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
  var valid_603965 = header.getOrDefault("x-amz-security-token")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "x-amz-security-token", valid_603965
  var valid_603966 = header.getOrDefault("Content-MD5")
  valid_603966 = validateParameter(valid_603966, JString, required = false,
                                 default = nil)
  if valid_603966 != nil:
    section.add "Content-MD5", valid_603966
  var valid_603967 = header.getOrDefault("x-amz-acl")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = newJString("private"))
  if valid_603967 != nil:
    section.add "x-amz-acl", valid_603967
  var valid_603968 = header.getOrDefault("x-amz-grant-read")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "x-amz-grant-read", valid_603968
  var valid_603969 = header.getOrDefault("x-amz-grant-read-acp")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "x-amz-grant-read-acp", valid_603969
  var valid_603970 = header.getOrDefault("x-amz-grant-write")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "x-amz-grant-write", valid_603970
  var valid_603971 = header.getOrDefault("x-amz-grant-write-acp")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "x-amz-grant-write-acp", valid_603971
  var valid_603972 = header.getOrDefault("x-amz-request-payer")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = newJString("requester"))
  if valid_603972 != nil:
    section.add "x-amz-request-payer", valid_603972
  var valid_603973 = header.getOrDefault("x-amz-grant-full-control")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "x-amz-grant-full-control", valid_603973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603975: Call_PutObjectAcl_603958; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  let valid = call_603975.validator(path, query, header, formData, body)
  let scheme = call_603975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603975.url(scheme.get, call_603975.host, call_603975.base,
                         call_603975.route, valid.getOrDefault("path"))
  result = hook(call_603975, url, valid)

proc call*(call_603976: Call_PutObjectAcl_603958; Key: string; acl: bool;
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
  var path_603977 = newJObject()
  var query_603978 = newJObject()
  var body_603979 = newJObject()
  add(query_603978, "versionId", newJString(versionId))
  add(path_603977, "Key", newJString(Key))
  add(query_603978, "acl", newJBool(acl))
  add(path_603977, "Bucket", newJString(Bucket))
  if body != nil:
    body_603979 = body
  result = call_603976.call(path_603977, query_603978, nil, nil, body_603979)

var putObjectAcl* = Call_PutObjectAcl_603958(name: "putObjectAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_PutObjectAcl_603959,
    base: "/", url: url_PutObjectAcl_603960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAcl_603945 = ref object of OpenApiRestCall_602433
proc url_GetObjectAcl_603947(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetObjectAcl_603946(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603948 = path.getOrDefault("Key")
  valid_603948 = validateParameter(valid_603948, JString, required = true,
                                 default = nil)
  if valid_603948 != nil:
    section.add "Key", valid_603948
  var valid_603949 = path.getOrDefault("Bucket")
  valid_603949 = validateParameter(valid_603949, JString, required = true,
                                 default = nil)
  if valid_603949 != nil:
    section.add "Bucket", valid_603949
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   acl: JBool (required)
  section = newJObject()
  var valid_603950 = query.getOrDefault("versionId")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "versionId", valid_603950
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_603951 = query.getOrDefault("acl")
  valid_603951 = validateParameter(valid_603951, JBool, required = true, default = nil)
  if valid_603951 != nil:
    section.add "acl", valid_603951
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_603952 = header.getOrDefault("x-amz-security-token")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "x-amz-security-token", valid_603952
  var valid_603953 = header.getOrDefault("x-amz-request-payer")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = newJString("requester"))
  if valid_603953 != nil:
    section.add "x-amz-request-payer", valid_603953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603954: Call_GetObjectAcl_603945; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access control list (ACL) of an object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  let valid = call_603954.validator(path, query, header, formData, body)
  let scheme = call_603954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603954.url(scheme.get, call_603954.host, call_603954.base,
                         call_603954.route, valid.getOrDefault("path"))
  result = hook(call_603954, url, valid)

proc call*(call_603955: Call_GetObjectAcl_603945; Key: string; acl: bool;
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
  var path_603956 = newJObject()
  var query_603957 = newJObject()
  add(query_603957, "versionId", newJString(versionId))
  add(path_603956, "Key", newJString(Key))
  add(query_603957, "acl", newJBool(acl))
  add(path_603956, "Bucket", newJString(Bucket))
  result = call_603955.call(path_603956, query_603957, nil, nil, nil)

var getObjectAcl* = Call_GetObjectAcl_603945(name: "getObjectAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_GetObjectAcl_603946,
    base: "/", url: url_GetObjectAcl_603947, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLegalHold_603993 = ref object of OpenApiRestCall_602433
proc url_PutObjectLegalHold_603995(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutObjectLegalHold_603994(path: JsonNode; query: JsonNode;
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
  var valid_603996 = path.getOrDefault("Key")
  valid_603996 = validateParameter(valid_603996, JString, required = true,
                                 default = nil)
  if valid_603996 != nil:
    section.add "Key", valid_603996
  var valid_603997 = path.getOrDefault("Bucket")
  valid_603997 = validateParameter(valid_603997, JString, required = true,
                                 default = nil)
  if valid_603997 != nil:
    section.add "Bucket", valid_603997
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object that you want to place a Legal Hold on.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_603998 = query.getOrDefault("versionId")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "versionId", valid_603998
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_603999 = query.getOrDefault("legal-hold")
  valid_603999 = validateParameter(valid_603999, JBool, required = true, default = nil)
  if valid_603999 != nil:
    section.add "legal-hold", valid_603999
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_604000 = header.getOrDefault("x-amz-security-token")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "x-amz-security-token", valid_604000
  var valid_604001 = header.getOrDefault("Content-MD5")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "Content-MD5", valid_604001
  var valid_604002 = header.getOrDefault("x-amz-request-payer")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = newJString("requester"))
  if valid_604002 != nil:
    section.add "x-amz-request-payer", valid_604002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604004: Call_PutObjectLegalHold_603993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a Legal Hold configuration to the specified object.
  ## 
  let valid = call_604004.validator(path, query, header, formData, body)
  let scheme = call_604004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604004.url(scheme.get, call_604004.host, call_604004.base,
                         call_604004.route, valid.getOrDefault("path"))
  result = hook(call_604004, url, valid)

proc call*(call_604005: Call_PutObjectLegalHold_603993; Key: string; legalHold: bool;
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
  var path_604006 = newJObject()
  var query_604007 = newJObject()
  var body_604008 = newJObject()
  add(query_604007, "versionId", newJString(versionId))
  add(path_604006, "Key", newJString(Key))
  add(query_604007, "legal-hold", newJBool(legalHold))
  add(path_604006, "Bucket", newJString(Bucket))
  if body != nil:
    body_604008 = body
  result = call_604005.call(path_604006, query_604007, nil, nil, body_604008)

var putObjectLegalHold* = Call_PutObjectLegalHold_603993(
    name: "putObjectLegalHold", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_PutObjectLegalHold_603994,
    base: "/", url: url_PutObjectLegalHold_603995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLegalHold_603980 = ref object of OpenApiRestCall_602433
proc url_GetObjectLegalHold_603982(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetObjectLegalHold_603981(path: JsonNode; query: JsonNode;
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
  var valid_603983 = path.getOrDefault("Key")
  valid_603983 = validateParameter(valid_603983, JString, required = true,
                                 default = nil)
  if valid_603983 != nil:
    section.add "Key", valid_603983
  var valid_603984 = path.getOrDefault("Bucket")
  valid_603984 = validateParameter(valid_603984, JString, required = true,
                                 default = nil)
  if valid_603984 != nil:
    section.add "Bucket", valid_603984
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID of the object whose Legal Hold status you want to retrieve.
  ##   legal-hold: JBool (required)
  section = newJObject()
  var valid_603985 = query.getOrDefault("versionId")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "versionId", valid_603985
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_603986 = query.getOrDefault("legal-hold")
  valid_603986 = validateParameter(valid_603986, JBool, required = true, default = nil)
  if valid_603986 != nil:
    section.add "legal-hold", valid_603986
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_603987 = header.getOrDefault("x-amz-security-token")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "x-amz-security-token", valid_603987
  var valid_603988 = header.getOrDefault("x-amz-request-payer")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = newJString("requester"))
  if valid_603988 != nil:
    section.add "x-amz-request-payer", valid_603988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603989: Call_GetObjectLegalHold_603980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an object's current Legal Hold status.
  ## 
  let valid = call_603989.validator(path, query, header, formData, body)
  let scheme = call_603989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603989.url(scheme.get, call_603989.host, call_603989.base,
                         call_603989.route, valid.getOrDefault("path"))
  result = hook(call_603989, url, valid)

proc call*(call_603990: Call_GetObjectLegalHold_603980; Key: string; legalHold: bool;
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
  var path_603991 = newJObject()
  var query_603992 = newJObject()
  add(query_603992, "versionId", newJString(versionId))
  add(path_603991, "Key", newJString(Key))
  add(query_603992, "legal-hold", newJBool(legalHold))
  add(path_603991, "Bucket", newJString(Bucket))
  result = call_603990.call(path_603991, query_603992, nil, nil, nil)

var getObjectLegalHold* = Call_GetObjectLegalHold_603980(
    name: "getObjectLegalHold", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_GetObjectLegalHold_603981,
    base: "/", url: url_GetObjectLegalHold_603982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLockConfiguration_604019 = ref object of OpenApiRestCall_602433
proc url_PutObjectLockConfiguration_604021(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutObjectLockConfiguration_604020(path: JsonNode; query: JsonNode;
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
  var valid_604022 = path.getOrDefault("Bucket")
  valid_604022 = validateParameter(valid_604022, JString, required = true,
                                 default = nil)
  if valid_604022 != nil:
    section.add "Bucket", valid_604022
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_604023 = query.getOrDefault("object-lock")
  valid_604023 = validateParameter(valid_604023, JBool, required = true, default = nil)
  if valid_604023 != nil:
    section.add "object-lock", valid_604023
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
  var valid_604024 = header.getOrDefault("x-amz-security-token")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "x-amz-security-token", valid_604024
  var valid_604025 = header.getOrDefault("Content-MD5")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "Content-MD5", valid_604025
  var valid_604026 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_604026
  var valid_604027 = header.getOrDefault("x-amz-request-payer")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = newJString("requester"))
  if valid_604027 != nil:
    section.add "x-amz-request-payer", valid_604027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604029: Call_PutObjectLockConfiguration_604019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_604029.validator(path, query, header, formData, body)
  let scheme = call_604029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604029.url(scheme.get, call_604029.host, call_604029.base,
                         call_604029.route, valid.getOrDefault("path"))
  result = hook(call_604029, url, valid)

proc call*(call_604030: Call_PutObjectLockConfiguration_604019; objectLock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putObjectLockConfiguration
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to create or replace.
  ##   body: JObject (required)
  var path_604031 = newJObject()
  var query_604032 = newJObject()
  var body_604033 = newJObject()
  add(query_604032, "object-lock", newJBool(objectLock))
  add(path_604031, "Bucket", newJString(Bucket))
  if body != nil:
    body_604033 = body
  result = call_604030.call(path_604031, query_604032, nil, nil, body_604033)

var putObjectLockConfiguration* = Call_PutObjectLockConfiguration_604019(
    name: "putObjectLockConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_PutObjectLockConfiguration_604020, base: "/",
    url: url_PutObjectLockConfiguration_604021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLockConfiguration_604009 = ref object of OpenApiRestCall_602433
proc url_GetObjectLockConfiguration_604011(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetObjectLockConfiguration_604010(path: JsonNode; query: JsonNode;
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
  var valid_604012 = path.getOrDefault("Bucket")
  valid_604012 = validateParameter(valid_604012, JString, required = true,
                                 default = nil)
  if valid_604012 != nil:
    section.add "Bucket", valid_604012
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_604013 = query.getOrDefault("object-lock")
  valid_604013 = validateParameter(valid_604013, JBool, required = true, default = nil)
  if valid_604013 != nil:
    section.add "object-lock", valid_604013
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604014 = header.getOrDefault("x-amz-security-token")
  valid_604014 = validateParameter(valid_604014, JString, required = false,
                                 default = nil)
  if valid_604014 != nil:
    section.add "x-amz-security-token", valid_604014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604015: Call_GetObjectLockConfiguration_604009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_604015.validator(path, query, header, formData, body)
  let scheme = call_604015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604015.url(scheme.get, call_604015.host, call_604015.base,
                         call_604015.route, valid.getOrDefault("path"))
  result = hook(call_604015, url, valid)

proc call*(call_604016: Call_GetObjectLockConfiguration_604009; objectLock: bool;
          Bucket: string): Recallable =
  ## getObjectLockConfiguration
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to retrieve.
  var path_604017 = newJObject()
  var query_604018 = newJObject()
  add(query_604018, "object-lock", newJBool(objectLock))
  add(path_604017, "Bucket", newJString(Bucket))
  result = call_604016.call(path_604017, query_604018, nil, nil, nil)

var getObjectLockConfiguration* = Call_GetObjectLockConfiguration_604009(
    name: "getObjectLockConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_GetObjectLockConfiguration_604010, base: "/",
    url: url_GetObjectLockConfiguration_604011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectRetention_604047 = ref object of OpenApiRestCall_602433
proc url_PutObjectRetention_604049(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_PutObjectRetention_604048(path: JsonNode; query: JsonNode;
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
  var valid_604050 = path.getOrDefault("Key")
  valid_604050 = validateParameter(valid_604050, JString, required = true,
                                 default = nil)
  if valid_604050 != nil:
    section.add "Key", valid_604050
  var valid_604051 = path.getOrDefault("Bucket")
  valid_604051 = validateParameter(valid_604051, JString, required = true,
                                 default = nil)
  if valid_604051 != nil:
    section.add "Bucket", valid_604051
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object that you want to apply this Object Retention configuration to.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_604052 = query.getOrDefault("versionId")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "versionId", valid_604052
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_604053 = query.getOrDefault("retention")
  valid_604053 = validateParameter(valid_604053, JBool, required = true, default = nil)
  if valid_604053 != nil:
    section.add "retention", valid_604053
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
  var valid_604054 = header.getOrDefault("x-amz-security-token")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "x-amz-security-token", valid_604054
  var valid_604055 = header.getOrDefault("Content-MD5")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "Content-MD5", valid_604055
  var valid_604056 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_604056 = validateParameter(valid_604056, JBool, required = false, default = nil)
  if valid_604056 != nil:
    section.add "x-amz-bypass-governance-retention", valid_604056
  var valid_604057 = header.getOrDefault("x-amz-request-payer")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = newJString("requester"))
  if valid_604057 != nil:
    section.add "x-amz-request-payer", valid_604057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604059: Call_PutObjectRetention_604047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an Object Retention configuration on an object.
  ## 
  let valid = call_604059.validator(path, query, header, formData, body)
  let scheme = call_604059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604059.url(scheme.get, call_604059.host, call_604059.base,
                         call_604059.route, valid.getOrDefault("path"))
  result = hook(call_604059, url, valid)

proc call*(call_604060: Call_PutObjectRetention_604047; retention: bool; Key: string;
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
  var path_604061 = newJObject()
  var query_604062 = newJObject()
  var body_604063 = newJObject()
  add(query_604062, "versionId", newJString(versionId))
  add(query_604062, "retention", newJBool(retention))
  add(path_604061, "Key", newJString(Key))
  add(path_604061, "Bucket", newJString(Bucket))
  if body != nil:
    body_604063 = body
  result = call_604060.call(path_604061, query_604062, nil, nil, body_604063)

var putObjectRetention* = Call_PutObjectRetention_604047(
    name: "putObjectRetention", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_PutObjectRetention_604048,
    base: "/", url: url_PutObjectRetention_604049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectRetention_604034 = ref object of OpenApiRestCall_602433
proc url_GetObjectRetention_604036(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetObjectRetention_604035(path: JsonNode; query: JsonNode;
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
  var valid_604037 = path.getOrDefault("Key")
  valid_604037 = validateParameter(valid_604037, JString, required = true,
                                 default = nil)
  if valid_604037 != nil:
    section.add "Key", valid_604037
  var valid_604038 = path.getOrDefault("Bucket")
  valid_604038 = validateParameter(valid_604038, JString, required = true,
                                 default = nil)
  if valid_604038 != nil:
    section.add "Bucket", valid_604038
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object whose retention settings you want to retrieve.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_604039 = query.getOrDefault("versionId")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "versionId", valid_604039
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_604040 = query.getOrDefault("retention")
  valid_604040 = validateParameter(valid_604040, JBool, required = true, default = nil)
  if valid_604040 != nil:
    section.add "retention", valid_604040
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_604041 = header.getOrDefault("x-amz-security-token")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "x-amz-security-token", valid_604041
  var valid_604042 = header.getOrDefault("x-amz-request-payer")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = newJString("requester"))
  if valid_604042 != nil:
    section.add "x-amz-request-payer", valid_604042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604043: Call_GetObjectRetention_604034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an object's retention settings.
  ## 
  let valid = call_604043.validator(path, query, header, formData, body)
  let scheme = call_604043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604043.url(scheme.get, call_604043.host, call_604043.base,
                         call_604043.route, valid.getOrDefault("path"))
  result = hook(call_604043, url, valid)

proc call*(call_604044: Call_GetObjectRetention_604034; retention: bool; Key: string;
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
  var path_604045 = newJObject()
  var query_604046 = newJObject()
  add(query_604046, "versionId", newJString(versionId))
  add(query_604046, "retention", newJBool(retention))
  add(path_604045, "Key", newJString(Key))
  add(path_604045, "Bucket", newJString(Bucket))
  result = call_604044.call(path_604045, query_604046, nil, nil, nil)

var getObjectRetention* = Call_GetObjectRetention_604034(
    name: "getObjectRetention", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_GetObjectRetention_604035,
    base: "/", url: url_GetObjectRetention_604036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTorrent_604064 = ref object of OpenApiRestCall_602433
proc url_GetObjectTorrent_604066(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetObjectTorrent_604065(path: JsonNode; query: JsonNode;
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
  var valid_604067 = path.getOrDefault("Key")
  valid_604067 = validateParameter(valid_604067, JString, required = true,
                                 default = nil)
  if valid_604067 != nil:
    section.add "Key", valid_604067
  var valid_604068 = path.getOrDefault("Bucket")
  valid_604068 = validateParameter(valid_604068, JString, required = true,
                                 default = nil)
  if valid_604068 != nil:
    section.add "Bucket", valid_604068
  result.add "path", section
  ## parameters in `query` object:
  ##   torrent: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `torrent` field"
  var valid_604069 = query.getOrDefault("torrent")
  valid_604069 = validateParameter(valid_604069, JBool, required = true, default = nil)
  if valid_604069 != nil:
    section.add "torrent", valid_604069
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_604070 = header.getOrDefault("x-amz-security-token")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "x-amz-security-token", valid_604070
  var valid_604071 = header.getOrDefault("x-amz-request-payer")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = newJString("requester"))
  if valid_604071 != nil:
    section.add "x-amz-request-payer", valid_604071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604072: Call_GetObjectTorrent_604064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return torrent files from a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  let valid = call_604072.validator(path, query, header, formData, body)
  let scheme = call_604072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604072.url(scheme.get, call_604072.host, call_604072.base,
                         call_604072.route, valid.getOrDefault("path"))
  result = hook(call_604072, url, valid)

proc call*(call_604073: Call_GetObjectTorrent_604064; torrent: bool; Key: string;
          Bucket: string): Recallable =
  ## getObjectTorrent
  ## Return torrent files from a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  ##   torrent: bool (required)
  ##   Key: string (required)
  ##      : <p/>
  ##   Bucket: string (required)
  ##         : <p/>
  var path_604074 = newJObject()
  var query_604075 = newJObject()
  add(query_604075, "torrent", newJBool(torrent))
  add(path_604074, "Key", newJString(Key))
  add(path_604074, "Bucket", newJString(Bucket))
  result = call_604073.call(path_604074, query_604075, nil, nil, nil)

var getObjectTorrent* = Call_GetObjectTorrent_604064(name: "getObjectTorrent",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#torrent", validator: validate_GetObjectTorrent_604065,
    base: "/", url: url_GetObjectTorrent_604066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketAnalyticsConfigurations_604076 = ref object of OpenApiRestCall_602433
proc url_ListBucketAnalyticsConfigurations_604078(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListBucketAnalyticsConfigurations_604077(path: JsonNode;
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
  var valid_604079 = path.getOrDefault("Bucket")
  valid_604079 = validateParameter(valid_604079, JString, required = true,
                                 default = nil)
  if valid_604079 != nil:
    section.add "Bucket", valid_604079
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   continuation-token: JString
  ##                     : The ContinuationToken that represents a placeholder from where this request should begin.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_604080 = query.getOrDefault("analytics")
  valid_604080 = validateParameter(valid_604080, JBool, required = true, default = nil)
  if valid_604080 != nil:
    section.add "analytics", valid_604080
  var valid_604081 = query.getOrDefault("continuation-token")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "continuation-token", valid_604081
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604082 = header.getOrDefault("x-amz-security-token")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "x-amz-security-token", valid_604082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604083: Call_ListBucketAnalyticsConfigurations_604076;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the analytics configurations for the bucket.
  ## 
  let valid = call_604083.validator(path, query, header, formData, body)
  let scheme = call_604083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604083.url(scheme.get, call_604083.host, call_604083.base,
                         call_604083.route, valid.getOrDefault("path"))
  result = hook(call_604083, url, valid)

proc call*(call_604084: Call_ListBucketAnalyticsConfigurations_604076;
          analytics: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketAnalyticsConfigurations
  ## Lists the analytics configurations for the bucket.
  ##   analytics: bool (required)
  ##   continuationToken: string
  ##                    : The ContinuationToken that represents a placeholder from where this request should begin.
  ##   Bucket: string (required)
  ##         : The name of the bucket from which analytics configurations are retrieved.
  var path_604085 = newJObject()
  var query_604086 = newJObject()
  add(query_604086, "analytics", newJBool(analytics))
  add(query_604086, "continuation-token", newJString(continuationToken))
  add(path_604085, "Bucket", newJString(Bucket))
  result = call_604084.call(path_604085, query_604086, nil, nil, nil)

var listBucketAnalyticsConfigurations* = Call_ListBucketAnalyticsConfigurations_604076(
    name: "listBucketAnalyticsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics",
    validator: validate_ListBucketAnalyticsConfigurations_604077, base: "/",
    url: url_ListBucketAnalyticsConfigurations_604078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketInventoryConfigurations_604087 = ref object of OpenApiRestCall_602433
proc url_ListBucketInventoryConfigurations_604089(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListBucketInventoryConfigurations_604088(path: JsonNode;
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
  var valid_604090 = path.getOrDefault("Bucket")
  valid_604090 = validateParameter(valid_604090, JString, required = true,
                                 default = nil)
  if valid_604090 != nil:
    section.add "Bucket", valid_604090
  result.add "path", section
  ## parameters in `query` object:
  ##   inventory: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_604091 = query.getOrDefault("inventory")
  valid_604091 = validateParameter(valid_604091, JBool, required = true, default = nil)
  if valid_604091 != nil:
    section.add "inventory", valid_604091
  var valid_604092 = query.getOrDefault("continuation-token")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "continuation-token", valid_604092
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604093 = header.getOrDefault("x-amz-security-token")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "x-amz-security-token", valid_604093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604094: Call_ListBucketInventoryConfigurations_604087;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of inventory configurations for the bucket.
  ## 
  let valid = call_604094.validator(path, query, header, formData, body)
  let scheme = call_604094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604094.url(scheme.get, call_604094.host, call_604094.base,
                         call_604094.route, valid.getOrDefault("path"))
  result = hook(call_604094, url, valid)

proc call*(call_604095: Call_ListBucketInventoryConfigurations_604087;
          inventory: bool; Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketInventoryConfigurations
  ## Returns a list of inventory configurations for the bucket.
  ##   inventory: bool (required)
  ##   continuationToken: string
  ##                    : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configurations to retrieve.
  var path_604096 = newJObject()
  var query_604097 = newJObject()
  add(query_604097, "inventory", newJBool(inventory))
  add(query_604097, "continuation-token", newJString(continuationToken))
  add(path_604096, "Bucket", newJString(Bucket))
  result = call_604095.call(path_604096, query_604097, nil, nil, nil)

var listBucketInventoryConfigurations* = Call_ListBucketInventoryConfigurations_604087(
    name: "listBucketInventoryConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory",
    validator: validate_ListBucketInventoryConfigurations_604088, base: "/",
    url: url_ListBucketInventoryConfigurations_604089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketMetricsConfigurations_604098 = ref object of OpenApiRestCall_602433
proc url_ListBucketMetricsConfigurations_604100(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListBucketMetricsConfigurations_604099(path: JsonNode;
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
  var valid_604101 = path.getOrDefault("Bucket")
  valid_604101 = validateParameter(valid_604101, JString, required = true,
                                 default = nil)
  if valid_604101 != nil:
    section.add "Bucket", valid_604101
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   continuation-token: JString
  ##                     : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_604102 = query.getOrDefault("metrics")
  valid_604102 = validateParameter(valid_604102, JBool, required = true, default = nil)
  if valid_604102 != nil:
    section.add "metrics", valid_604102
  var valid_604103 = query.getOrDefault("continuation-token")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "continuation-token", valid_604103
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604104 = header.getOrDefault("x-amz-security-token")
  valid_604104 = validateParameter(valid_604104, JString, required = false,
                                 default = nil)
  if valid_604104 != nil:
    section.add "x-amz-security-token", valid_604104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604105: Call_ListBucketMetricsConfigurations_604098;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the metrics configurations for the bucket.
  ## 
  let valid = call_604105.validator(path, query, header, formData, body)
  let scheme = call_604105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604105.url(scheme.get, call_604105.host, call_604105.base,
                         call_604105.route, valid.getOrDefault("path"))
  result = hook(call_604105, url, valid)

proc call*(call_604106: Call_ListBucketMetricsConfigurations_604098; metrics: bool;
          Bucket: string; continuationToken: string = ""): Recallable =
  ## listBucketMetricsConfigurations
  ## Lists the metrics configurations for the bucket.
  ##   metrics: bool (required)
  ##   continuationToken: string
  ##                    : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configurations to retrieve.
  var path_604107 = newJObject()
  var query_604108 = newJObject()
  add(query_604108, "metrics", newJBool(metrics))
  add(query_604108, "continuation-token", newJString(continuationToken))
  add(path_604107, "Bucket", newJString(Bucket))
  result = call_604106.call(path_604107, query_604108, nil, nil, nil)

var listBucketMetricsConfigurations* = Call_ListBucketMetricsConfigurations_604098(
    name: "listBucketMetricsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics",
    validator: validate_ListBucketMetricsConfigurations_604099, base: "/",
    url: url_ListBucketMetricsConfigurations_604100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuckets_604109 = ref object of OpenApiRestCall_602433
proc url_ListBuckets_604111(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBuckets_604110(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604112 = header.getOrDefault("x-amz-security-token")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "x-amz-security-token", valid_604112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604113: Call_ListBuckets_604109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  let valid = call_604113.validator(path, query, header, formData, body)
  let scheme = call_604113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604113.url(scheme.get, call_604113.host, call_604113.base,
                         call_604113.route, valid.getOrDefault("path"))
  result = hook(call_604113, url, valid)

proc call*(call_604114: Call_ListBuckets_604109): Recallable =
  ## listBuckets
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  result = call_604114.call(nil, nil, nil, nil, nil)

var listBuckets* = Call_ListBuckets_604109(name: "listBuckets",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com", route: "/",
                                        validator: validate_ListBuckets_604110,
                                        base: "/", url: url_ListBuckets_604111,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultipartUploads_604115 = ref object of OpenApiRestCall_602433
proc url_ListMultipartUploads_604117(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListMultipartUploads_604116(path: JsonNode; query: JsonNode;
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
  var valid_604118 = path.getOrDefault("Bucket")
  valid_604118 = validateParameter(valid_604118, JString, required = true,
                                 default = nil)
  if valid_604118 != nil:
    section.add "Bucket", valid_604118
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
  var valid_604119 = query.getOrDefault("max-uploads")
  valid_604119 = validateParameter(valid_604119, JInt, required = false, default = nil)
  if valid_604119 != nil:
    section.add "max-uploads", valid_604119
  var valid_604120 = query.getOrDefault("key-marker")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "key-marker", valid_604120
  var valid_604121 = query.getOrDefault("encoding-type")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = newJString("url"))
  if valid_604121 != nil:
    section.add "encoding-type", valid_604121
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_604122 = query.getOrDefault("uploads")
  valid_604122 = validateParameter(valid_604122, JBool, required = true, default = nil)
  if valid_604122 != nil:
    section.add "uploads", valid_604122
  var valid_604123 = query.getOrDefault("MaxUploads")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "MaxUploads", valid_604123
  var valid_604124 = query.getOrDefault("delimiter")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "delimiter", valid_604124
  var valid_604125 = query.getOrDefault("prefix")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "prefix", valid_604125
  var valid_604126 = query.getOrDefault("upload-id-marker")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "upload-id-marker", valid_604126
  var valid_604127 = query.getOrDefault("KeyMarker")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "KeyMarker", valid_604127
  var valid_604128 = query.getOrDefault("UploadIdMarker")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "UploadIdMarker", valid_604128
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604129 = header.getOrDefault("x-amz-security-token")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "x-amz-security-token", valid_604129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604130: Call_ListMultipartUploads_604115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists in-progress multipart uploads.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
  let valid = call_604130.validator(path, query, header, formData, body)
  let scheme = call_604130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604130.url(scheme.get, call_604130.host, call_604130.base,
                         call_604130.route, valid.getOrDefault("path"))
  result = hook(call_604130, url, valid)

proc call*(call_604131: Call_ListMultipartUploads_604115; uploads: bool;
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
  var path_604132 = newJObject()
  var query_604133 = newJObject()
  add(query_604133, "max-uploads", newJInt(maxUploads))
  add(query_604133, "key-marker", newJString(keyMarker))
  add(query_604133, "encoding-type", newJString(encodingType))
  add(query_604133, "uploads", newJBool(uploads))
  add(query_604133, "MaxUploads", newJString(MaxUploads))
  add(query_604133, "delimiter", newJString(delimiter))
  add(path_604132, "Bucket", newJString(Bucket))
  add(query_604133, "prefix", newJString(prefix))
  add(query_604133, "upload-id-marker", newJString(uploadIdMarker))
  add(query_604133, "KeyMarker", newJString(KeyMarker))
  add(query_604133, "UploadIdMarker", newJString(UploadIdMarker))
  result = call_604131.call(path_604132, query_604133, nil, nil, nil)

var listMultipartUploads* = Call_ListMultipartUploads_604115(
    name: "listMultipartUploads", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#uploads",
    validator: validate_ListMultipartUploads_604116, base: "/",
    url: url_ListMultipartUploads_604117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectVersions_604134 = ref object of OpenApiRestCall_602433
proc url_ListObjectVersions_604136(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListObjectVersions_604135(path: JsonNode; query: JsonNode;
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
  var valid_604137 = path.getOrDefault("Bucket")
  valid_604137 = validateParameter(valid_604137, JString, required = true,
                                 default = nil)
  if valid_604137 != nil:
    section.add "Bucket", valid_604137
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
  var valid_604138 = query.getOrDefault("key-marker")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "key-marker", valid_604138
  var valid_604139 = query.getOrDefault("max-keys")
  valid_604139 = validateParameter(valid_604139, JInt, required = false, default = nil)
  if valid_604139 != nil:
    section.add "max-keys", valid_604139
  var valid_604140 = query.getOrDefault("VersionIdMarker")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "VersionIdMarker", valid_604140
  assert query != nil,
        "query argument is necessary due to required `versions` field"
  var valid_604141 = query.getOrDefault("versions")
  valid_604141 = validateParameter(valid_604141, JBool, required = true, default = nil)
  if valid_604141 != nil:
    section.add "versions", valid_604141
  var valid_604142 = query.getOrDefault("encoding-type")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = newJString("url"))
  if valid_604142 != nil:
    section.add "encoding-type", valid_604142
  var valid_604143 = query.getOrDefault("version-id-marker")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "version-id-marker", valid_604143
  var valid_604144 = query.getOrDefault("delimiter")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "delimiter", valid_604144
  var valid_604145 = query.getOrDefault("prefix")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "prefix", valid_604145
  var valid_604146 = query.getOrDefault("MaxKeys")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "MaxKeys", valid_604146
  var valid_604147 = query.getOrDefault("KeyMarker")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "KeyMarker", valid_604147
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_604148 = header.getOrDefault("x-amz-security-token")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "x-amz-security-token", valid_604148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604149: Call_ListObjectVersions_604134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about all of the versions of objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
  let valid = call_604149.validator(path, query, header, formData, body)
  let scheme = call_604149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604149.url(scheme.get, call_604149.host, call_604149.base,
                         call_604149.route, valid.getOrDefault("path"))
  result = hook(call_604149, url, valid)

proc call*(call_604150: Call_ListObjectVersions_604134; versions: bool;
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
  var path_604151 = newJObject()
  var query_604152 = newJObject()
  add(query_604152, "key-marker", newJString(keyMarker))
  add(query_604152, "max-keys", newJInt(maxKeys))
  add(query_604152, "VersionIdMarker", newJString(VersionIdMarker))
  add(query_604152, "versions", newJBool(versions))
  add(query_604152, "encoding-type", newJString(encodingType))
  add(query_604152, "version-id-marker", newJString(versionIdMarker))
  add(query_604152, "delimiter", newJString(delimiter))
  add(path_604151, "Bucket", newJString(Bucket))
  add(query_604152, "prefix", newJString(prefix))
  add(query_604152, "MaxKeys", newJString(MaxKeys))
  add(query_604152, "KeyMarker", newJString(KeyMarker))
  result = call_604150.call(path_604151, query_604152, nil, nil, nil)

var listObjectVersions* = Call_ListObjectVersions_604134(
    name: "listObjectVersions", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versions", validator: validate_ListObjectVersions_604135,
    base: "/", url: url_ListObjectVersions_604136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectsV2_604153 = ref object of OpenApiRestCall_602433
proc url_ListObjectsV2_604155(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListObjectsV2_604154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604156 = path.getOrDefault("Bucket")
  valid_604156 = validateParameter(valid_604156, JString, required = true,
                                 default = nil)
  if valid_604156 != nil:
    section.add "Bucket", valid_604156
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
  var valid_604157 = query.getOrDefault("list-type")
  valid_604157 = validateParameter(valid_604157, JString, required = true,
                                 default = newJString("2"))
  if valid_604157 != nil:
    section.add "list-type", valid_604157
  var valid_604158 = query.getOrDefault("max-keys")
  valid_604158 = validateParameter(valid_604158, JInt, required = false, default = nil)
  if valid_604158 != nil:
    section.add "max-keys", valid_604158
  var valid_604159 = query.getOrDefault("encoding-type")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = newJString("url"))
  if valid_604159 != nil:
    section.add "encoding-type", valid_604159
  var valid_604160 = query.getOrDefault("continuation-token")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "continuation-token", valid_604160
  var valid_604161 = query.getOrDefault("fetch-owner")
  valid_604161 = validateParameter(valid_604161, JBool, required = false, default = nil)
  if valid_604161 != nil:
    section.add "fetch-owner", valid_604161
  var valid_604162 = query.getOrDefault("delimiter")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "delimiter", valid_604162
  var valid_604163 = query.getOrDefault("start-after")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "start-after", valid_604163
  var valid_604164 = query.getOrDefault("ContinuationToken")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "ContinuationToken", valid_604164
  var valid_604165 = query.getOrDefault("prefix")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "prefix", valid_604165
  var valid_604166 = query.getOrDefault("MaxKeys")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "MaxKeys", valid_604166
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_604167 = header.getOrDefault("x-amz-security-token")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "x-amz-security-token", valid_604167
  var valid_604168 = header.getOrDefault("x-amz-request-payer")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = newJString("requester"))
  if valid_604168 != nil:
    section.add "x-amz-request-payer", valid_604168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604169: Call_ListObjectsV2_604153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. Note: ListObjectsV2 is the revised List Objects API and we recommend you use this revised API for new application development.
  ## 
  let valid = call_604169.validator(path, query, header, formData, body)
  let scheme = call_604169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604169.url(scheme.get, call_604169.host, call_604169.base,
                         call_604169.route, valid.getOrDefault("path"))
  result = hook(call_604169, url, valid)

proc call*(call_604170: Call_ListObjectsV2_604153; Bucket: string;
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
  var path_604171 = newJObject()
  var query_604172 = newJObject()
  add(query_604172, "list-type", newJString(listType))
  add(query_604172, "max-keys", newJInt(maxKeys))
  add(query_604172, "encoding-type", newJString(encodingType))
  add(query_604172, "continuation-token", newJString(continuationToken))
  add(query_604172, "fetch-owner", newJBool(fetchOwner))
  add(query_604172, "delimiter", newJString(delimiter))
  add(path_604171, "Bucket", newJString(Bucket))
  add(query_604172, "start-after", newJString(startAfter))
  add(query_604172, "ContinuationToken", newJString(ContinuationToken))
  add(query_604172, "prefix", newJString(prefix))
  add(query_604172, "MaxKeys", newJString(MaxKeys))
  result = call_604170.call(path_604171, query_604172, nil, nil, nil)

var listObjectsV2* = Call_ListObjectsV2_604153(name: "listObjectsV2",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#list-type=2", validator: validate_ListObjectsV2_604154,
    base: "/", url: url_ListObjectsV2_604155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreObject_604173 = ref object of OpenApiRestCall_602433
proc url_RestoreObject_604175(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_RestoreObject_604174(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604176 = path.getOrDefault("Key")
  valid_604176 = validateParameter(valid_604176, JString, required = true,
                                 default = nil)
  if valid_604176 != nil:
    section.add "Key", valid_604176
  var valid_604177 = path.getOrDefault("Bucket")
  valid_604177 = validateParameter(valid_604177, JString, required = true,
                                 default = nil)
  if valid_604177 != nil:
    section.add "Bucket", valid_604177
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : <p/>
  ##   restore: JBool (required)
  section = newJObject()
  var valid_604178 = query.getOrDefault("versionId")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "versionId", valid_604178
  assert query != nil, "query argument is necessary due to required `restore` field"
  var valid_604179 = query.getOrDefault("restore")
  valid_604179 = validateParameter(valid_604179, JBool, required = true, default = nil)
  if valid_604179 != nil:
    section.add "restore", valid_604179
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_604180 = header.getOrDefault("x-amz-security-token")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "x-amz-security-token", valid_604180
  var valid_604181 = header.getOrDefault("x-amz-request-payer")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = newJString("requester"))
  if valid_604181 != nil:
    section.add "x-amz-request-payer", valid_604181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604183: Call_RestoreObject_604173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restores an archived copy of an object back into Amazon S3
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  let valid = call_604183.validator(path, query, header, formData, body)
  let scheme = call_604183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604183.url(scheme.get, call_604183.host, call_604183.base,
                         call_604183.route, valid.getOrDefault("path"))
  result = hook(call_604183, url, valid)

proc call*(call_604184: Call_RestoreObject_604173; Key: string; restore: bool;
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
  var path_604185 = newJObject()
  var query_604186 = newJObject()
  var body_604187 = newJObject()
  add(query_604186, "versionId", newJString(versionId))
  add(path_604185, "Key", newJString(Key))
  add(query_604186, "restore", newJBool(restore))
  add(path_604185, "Bucket", newJString(Bucket))
  if body != nil:
    body_604187 = body
  result = call_604184.call(path_604185, query_604186, nil, nil, body_604187)

var restoreObject* = Call_RestoreObject_604173(name: "restoreObject",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#restore", validator: validate_RestoreObject_604174,
    base: "/", url: url_RestoreObject_604175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SelectObjectContent_604188 = ref object of OpenApiRestCall_602433
proc url_SelectObjectContent_604190(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_SelectObjectContent_604189(path: JsonNode; query: JsonNode;
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
  var valid_604191 = path.getOrDefault("Key")
  valid_604191 = validateParameter(valid_604191, JString, required = true,
                                 default = nil)
  if valid_604191 != nil:
    section.add "Key", valid_604191
  var valid_604192 = path.getOrDefault("Bucket")
  valid_604192 = validateParameter(valid_604192, JString, required = true,
                                 default = nil)
  if valid_604192 != nil:
    section.add "Bucket", valid_604192
  result.add "path", section
  ## parameters in `query` object:
  ##   select: JBool (required)
  ##   select-type: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `select` field"
  var valid_604193 = query.getOrDefault("select")
  valid_604193 = validateParameter(valid_604193, JBool, required = true, default = nil)
  if valid_604193 != nil:
    section.add "select", valid_604193
  var valid_604194 = query.getOrDefault("select-type")
  valid_604194 = validateParameter(valid_604194, JString, required = true,
                                 default = newJString("2"))
  if valid_604194 != nil:
    section.add "select-type", valid_604194
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
  var valid_604195 = header.getOrDefault("x-amz-security-token")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "x-amz-security-token", valid_604195
  var valid_604196 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_604196
  var valid_604197 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_604197
  var valid_604198 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_604198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604200: Call_SelectObjectContent_604188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ## 
  let valid = call_604200.validator(path, query, header, formData, body)
  let scheme = call_604200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604200.url(scheme.get, call_604200.host, call_604200.base,
                         call_604200.route, valid.getOrDefault("path"))
  result = hook(call_604200, url, valid)

proc call*(call_604201: Call_SelectObjectContent_604188; select: bool; Key: string;
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
  var path_604202 = newJObject()
  var query_604203 = newJObject()
  var body_604204 = newJObject()
  add(query_604203, "select", newJBool(select))
  add(path_604202, "Key", newJString(Key))
  add(path_604202, "Bucket", newJString(Bucket))
  if body != nil:
    body_604204 = body
  add(query_604203, "select-type", newJString(selectType))
  result = call_604201.call(path_604202, query_604203, nil, nil, body_604204)

var selectObjectContent* = Call_SelectObjectContent_604188(
    name: "selectObjectContent", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#select&select-type=2",
    validator: validate_SelectObjectContent_604189, base: "/",
    url: url_SelectObjectContent_604190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPart_604205 = ref object of OpenApiRestCall_602433
proc url_UploadPart_604207(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UploadPart_604206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604208 = path.getOrDefault("Key")
  valid_604208 = validateParameter(valid_604208, JString, required = true,
                                 default = nil)
  if valid_604208 != nil:
    section.add "Key", valid_604208
  var valid_604209 = path.getOrDefault("Bucket")
  valid_604209 = validateParameter(valid_604209, JString, required = true,
                                 default = nil)
  if valid_604209 != nil:
    section.add "Bucket", valid_604209
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being uploaded.
  ##   partNumber: JInt (required)
  ##             : Part number of part being uploaded. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_604210 = query.getOrDefault("uploadId")
  valid_604210 = validateParameter(valid_604210, JString, required = true,
                                 default = nil)
  if valid_604210 != nil:
    section.add "uploadId", valid_604210
  var valid_604211 = query.getOrDefault("partNumber")
  valid_604211 = validateParameter(valid_604211, JInt, required = true, default = nil)
  if valid_604211 != nil:
    section.add "partNumber", valid_604211
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
  var valid_604212 = header.getOrDefault("x-amz-security-token")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "x-amz-security-token", valid_604212
  var valid_604213 = header.getOrDefault("Content-MD5")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "Content-MD5", valid_604213
  var valid_604214 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_604214
  var valid_604215 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_604215
  var valid_604216 = header.getOrDefault("Content-Length")
  valid_604216 = validateParameter(valid_604216, JInt, required = false, default = nil)
  if valid_604216 != nil:
    section.add "Content-Length", valid_604216
  var valid_604217 = header.getOrDefault("x-amz-request-payer")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = newJString("requester"))
  if valid_604217 != nil:
    section.add "x-amz-request-payer", valid_604217
  var valid_604218 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_604218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604220: Call_UploadPart_604205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  let valid = call_604220.validator(path, query, header, formData, body)
  let scheme = call_604220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604220.url(scheme.get, call_604220.host, call_604220.base,
                         call_604220.route, valid.getOrDefault("path"))
  result = hook(call_604220, url, valid)

proc call*(call_604221: Call_UploadPart_604205; uploadId: string; partNumber: int;
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
  var path_604222 = newJObject()
  var query_604223 = newJObject()
  var body_604224 = newJObject()
  add(query_604223, "uploadId", newJString(uploadId))
  add(query_604223, "partNumber", newJInt(partNumber))
  add(path_604222, "Key", newJString(Key))
  add(path_604222, "Bucket", newJString(Bucket))
  if body != nil:
    body_604224 = body
  result = call_604221.call(path_604222, query_604223, nil, nil, body_604224)

var uploadPart* = Call_UploadPart_604205(name: "uploadPart",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#partNumber&uploadId",
                                      validator: validate_UploadPart_604206,
                                      base: "/", url: url_UploadPart_604207,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPartCopy_604225 = ref object of OpenApiRestCall_602433
proc url_UploadPartCopy_604227(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UploadPartCopy_604226(path: JsonNode; query: JsonNode;
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
  var valid_604228 = path.getOrDefault("Key")
  valid_604228 = validateParameter(valid_604228, JString, required = true,
                                 default = nil)
  if valid_604228 != nil:
    section.add "Key", valid_604228
  var valid_604229 = path.getOrDefault("Bucket")
  valid_604229 = validateParameter(valid_604229, JString, required = true,
                                 default = nil)
  if valid_604229 != nil:
    section.add "Bucket", valid_604229
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being copied.
  ##   partNumber: JInt (required)
  ##             : Part number of part being copied. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_604230 = query.getOrDefault("uploadId")
  valid_604230 = validateParameter(valid_604230, JString, required = true,
                                 default = nil)
  if valid_604230 != nil:
    section.add "uploadId", valid_604230
  var valid_604231 = query.getOrDefault("partNumber")
  valid_604231 = validateParameter(valid_604231, JInt, required = true, default = nil)
  if valid_604231 != nil:
    section.add "partNumber", valid_604231
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
  var valid_604232 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_604232
  var valid_604233 = header.getOrDefault("x-amz-security-token")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "x-amz-security-token", valid_604233
  var valid_604234 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_604234
  var valid_604235 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_604235
  var valid_604236 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_604236 = validateParameter(valid_604236, JString, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_604236
  var valid_604237 = header.getOrDefault("x-amz-copy-source-range")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "x-amz-copy-source-range", valid_604237
  var valid_604238 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_604238 = validateParameter(valid_604238, JString, required = false,
                                 default = nil)
  if valid_604238 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_604238
  var valid_604239 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_604239 = validateParameter(valid_604239, JString, required = false,
                                 default = nil)
  if valid_604239 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_604239
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_604240 = header.getOrDefault("x-amz-copy-source")
  valid_604240 = validateParameter(valid_604240, JString, required = true,
                                 default = nil)
  if valid_604240 != nil:
    section.add "x-amz-copy-source", valid_604240
  var valid_604241 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_604241 = validateParameter(valid_604241, JString, required = false,
                                 default = nil)
  if valid_604241 != nil:
    section.add "x-amz-copy-source-if-match", valid_604241
  var valid_604242 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_604242 = validateParameter(valid_604242, JString, required = false,
                                 default = nil)
  if valid_604242 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_604242
  var valid_604243 = header.getOrDefault("x-amz-request-payer")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = newJString("requester"))
  if valid_604243 != nil:
    section.add "x-amz-request-payer", valid_604243
  var valid_604244 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_604244
  var valid_604245 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_604245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604246: Call_UploadPartCopy_604225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads a part by copying data from an existing object as data source.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  let valid = call_604246.validator(path, query, header, formData, body)
  let scheme = call_604246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604246.url(scheme.get, call_604246.host, call_604246.base,
                         call_604246.route, valid.getOrDefault("path"))
  result = hook(call_604246, url, valid)

proc call*(call_604247: Call_UploadPartCopy_604225; uploadId: string;
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
  var path_604248 = newJObject()
  var query_604249 = newJObject()
  add(query_604249, "uploadId", newJString(uploadId))
  add(query_604249, "partNumber", newJInt(partNumber))
  add(path_604248, "Key", newJString(Key))
  add(path_604248, "Bucket", newJString(Bucket))
  result = call_604247.call(path_604248, query_604249, nil, nil, nil)

var uploadPartCopy* = Call_UploadPartCopy_604225(name: "uploadPartCopy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#x-amz-copy-source&partNumber&uploadId",
    validator: validate_UploadPartCopy_604226, base: "/", url: url_UploadPartCopy_604227,
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
