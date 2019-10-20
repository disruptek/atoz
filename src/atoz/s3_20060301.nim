
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
  Call_CompleteMultipartUpload_592988 = ref object of OpenApiRestCall_592364
proc url_CompleteMultipartUpload_592990(protocol: Scheme; host: string; base: string;
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

proc validate_CompleteMultipartUpload_592989(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_592991 = path.getOrDefault("Bucket")
  valid_592991 = validateParameter(valid_592991, JString, required = true,
                                 default = nil)
  if valid_592991 != nil:
    section.add "Bucket", valid_592991
  var valid_592992 = path.getOrDefault("Key")
  valid_592992 = validateParameter(valid_592992, JString, required = true,
                                 default = nil)
  if valid_592992 != nil:
    section.add "Key", valid_592992
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : <p/>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_592993 = query.getOrDefault("uploadId")
  valid_592993 = validateParameter(valid_592993, JString, required = true,
                                 default = nil)
  if valid_592993 != nil:
    section.add "uploadId", valid_592993
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_592994 = header.getOrDefault("x-amz-security-token")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "x-amz-security-token", valid_592994
  var valid_592995 = header.getOrDefault("x-amz-request-payer")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = newJString("requester"))
  if valid_592995 != nil:
    section.add "x-amz-request-payer", valid_592995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592997: Call_CompleteMultipartUpload_592988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  let valid = call_592997.validator(path, query, header, formData, body)
  let scheme = call_592997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592997.url(scheme.get, call_592997.host, call_592997.base,
                         call_592997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592997, url, valid)

proc call*(call_592998: Call_CompleteMultipartUpload_592988; Bucket: string;
          uploadId: string; Key: string; body: JsonNode): Recallable =
  ## completeMultipartUpload
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   uploadId: string (required)
  ##           : <p/>
  ##   Key: string (required)
  ##      : <p/>
  ##   body: JObject (required)
  var path_592999 = newJObject()
  var query_593000 = newJObject()
  var body_593001 = newJObject()
  add(path_592999, "Bucket", newJString(Bucket))
  add(query_593000, "uploadId", newJString(uploadId))
  add(path_592999, "Key", newJString(Key))
  if body != nil:
    body_593001 = body
  result = call_592998.call(path_592999, query_593000, nil, nil, body_593001)

var completeMultipartUpload* = Call_CompleteMultipartUpload_592988(
    name: "completeMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_CompleteMultipartUpload_592989, base: "/",
    url: url_CompleteMultipartUpload_592990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParts_592703 = ref object of OpenApiRestCall_592364
proc url_ListParts_592705(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListParts_592704(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_592831 = path.getOrDefault("Bucket")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "Bucket", valid_592831
  var valid_592832 = path.getOrDefault("Key")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = nil)
  if valid_592832 != nil:
    section.add "Key", valid_592832
  result.add "path", section
  ## parameters in `query` object:
  ##   part-number-marker: JInt
  ##                     : Specifies the part after which listing should begin. Only parts with higher part numbers will be listed.
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose parts are being listed.
  ##   PartNumberMarker: JString
  ##                   : Pagination token
  ##   MaxParts: JString
  ##           : Pagination limit
  ##   max-parts: JInt
  ##            : Sets the maximum number of parts to return.
  section = newJObject()
  var valid_592833 = query.getOrDefault("part-number-marker")
  valid_592833 = validateParameter(valid_592833, JInt, required = false, default = nil)
  if valid_592833 != nil:
    section.add "part-number-marker", valid_592833
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_592834 = query.getOrDefault("uploadId")
  valid_592834 = validateParameter(valid_592834, JString, required = true,
                                 default = nil)
  if valid_592834 != nil:
    section.add "uploadId", valid_592834
  var valid_592835 = query.getOrDefault("PartNumberMarker")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "PartNumberMarker", valid_592835
  var valid_592836 = query.getOrDefault("MaxParts")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "MaxParts", valid_592836
  var valid_592837 = query.getOrDefault("max-parts")
  valid_592837 = validateParameter(valid_592837, JInt, required = false, default = nil)
  if valid_592837 != nil:
    section.add "max-parts", valid_592837
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_592838 = header.getOrDefault("x-amz-security-token")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "x-amz-security-token", valid_592838
  var valid_592852 = header.getOrDefault("x-amz-request-payer")
  valid_592852 = validateParameter(valid_592852, JString, required = false,
                                 default = newJString("requester"))
  if valid_592852 != nil:
    section.add "x-amz-request-payer", valid_592852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592875: Call_ListParts_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  let valid = call_592875.validator(path, query, header, formData, body)
  let scheme = call_592875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592875.url(scheme.get, call_592875.host, call_592875.base,
                         call_592875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592875, url, valid)

proc call*(call_592946: Call_ListParts_592703; Bucket: string; uploadId: string;
          Key: string; partNumberMarker: int = 0; PartNumberMarker: string = "";
          MaxParts: string = ""; maxParts: int = 0): Recallable =
  ## listParts
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   partNumberMarker: int
  ##                   : Specifies the part after which listing should begin. Only parts with higher part numbers will be listed.
  ##   uploadId: string (required)
  ##           : Upload ID identifying the multipart upload whose parts are being listed.
  ##   Key: string (required)
  ##      : <p/>
  ##   PartNumberMarker: string
  ##                   : Pagination token
  ##   MaxParts: string
  ##           : Pagination limit
  ##   maxParts: int
  ##           : Sets the maximum number of parts to return.
  var path_592947 = newJObject()
  var query_592949 = newJObject()
  add(path_592947, "Bucket", newJString(Bucket))
  add(query_592949, "part-number-marker", newJInt(partNumberMarker))
  add(query_592949, "uploadId", newJString(uploadId))
  add(path_592947, "Key", newJString(Key))
  add(query_592949, "PartNumberMarker", newJString(PartNumberMarker))
  add(query_592949, "MaxParts", newJString(MaxParts))
  add(query_592949, "max-parts", newJInt(maxParts))
  result = call_592946.call(path_592947, query_592949, nil, nil, nil)

var listParts* = Call_ListParts_592703(name: "listParts", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}#uploadId",
                                    validator: validate_ListParts_592704,
                                    base: "/", url: url_ListParts_592705,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortMultipartUpload_593002 = ref object of OpenApiRestCall_592364
proc url_AbortMultipartUpload_593004(protocol: Scheme; host: string; base: string;
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

proc validate_AbortMultipartUpload_593003(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : Name of the bucket to which the multipart upload was initiated.
  ##   Key: JString (required)
  ##      : Key of the object for which the multipart upload was initiated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593005 = path.getOrDefault("Bucket")
  valid_593005 = validateParameter(valid_593005, JString, required = true,
                                 default = nil)
  if valid_593005 != nil:
    section.add "Bucket", valid_593005
  var valid_593006 = path.getOrDefault("Key")
  valid_593006 = validateParameter(valid_593006, JString, required = true,
                                 default = nil)
  if valid_593006 != nil:
    section.add "Key", valid_593006
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID that identifies the multipart upload.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_593007 = query.getOrDefault("uploadId")
  valid_593007 = validateParameter(valid_593007, JString, required = true,
                                 default = nil)
  if valid_593007 != nil:
    section.add "uploadId", valid_593007
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_593008 = header.getOrDefault("x-amz-security-token")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "x-amz-security-token", valid_593008
  var valid_593009 = header.getOrDefault("x-amz-request-payer")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = newJString("requester"))
  if valid_593009 != nil:
    section.add "x-amz-request-payer", valid_593009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593010: Call_AbortMultipartUpload_593002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  let valid = call_593010.validator(path, query, header, formData, body)
  let scheme = call_593010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593010.url(scheme.get, call_593010.host, call_593010.base,
                         call_593010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593010, url, valid)

proc call*(call_593011: Call_AbortMultipartUpload_593002; Bucket: string;
          uploadId: string; Key: string): Recallable =
  ## abortMultipartUpload
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the multipart upload was initiated.
  ##   uploadId: string (required)
  ##           : Upload ID that identifies the multipart upload.
  ##   Key: string (required)
  ##      : Key of the object for which the multipart upload was initiated.
  var path_593012 = newJObject()
  var query_593013 = newJObject()
  add(path_593012, "Bucket", newJString(Bucket))
  add(query_593013, "uploadId", newJString(uploadId))
  add(path_593012, "Key", newJString(Key))
  result = call_593011.call(path_593012, query_593013, nil, nil, nil)

var abortMultipartUpload* = Call_AbortMultipartUpload_593002(
    name: "abortMultipartUpload", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_AbortMultipartUpload_593003, base: "/",
    url: url_AbortMultipartUpload_593004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyObject_593014 = ref object of OpenApiRestCall_592364
proc url_CopyObject_593016(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CopyObject_593015(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593017 = path.getOrDefault("Bucket")
  valid_593017 = validateParameter(valid_593017, JString, required = true,
                                 default = nil)
  if valid_593017 != nil:
    section.add "Bucket", valid_593017
  var valid_593018 = path.getOrDefault("Key")
  valid_593018 = validateParameter(valid_593018, JString, required = true,
                                 default = nil)
  if valid_593018 != nil:
    section.add "Key", valid_593018
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Cache-Control: JString
  ##                : Specifies caching behavior along the request/reply chain.
  ##   x-amz-metadata-directive: JString
  ##                           : Specifies whether the metadata is copied from the source object or replaced with metadata provided in the request.
  ##   x-amz-copy-source-if-none-match: JString
  ##                                  : Copies the object if its entity tag (ETag) is different than the specified ETag.
  ##   x-amz-storage-class: JString
  ##                      : The type of storage to use for the object. Defaults to 'STANDARD'.
  ##   x-amz-object-lock-retain-until-date: JString
  ##                                      : The date and time when you want the copied object's object lock to expire.
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-copy-source: JString (required)
  ##                    : The name of the source bucket and key name of the source object, separated by a slash (/). Must be URL-encoded.
  ##   x-amz-tagging-directive: JString
  ##                          : Specifies whether the object tag-set are copied from the source object or replaced with tag-set provided in the request.
  ##   x-amz-server-side-encryption: JString
  ##                               : The Server-side encryption algorithm used when storing this object in S3 (e.g., AES256, aws:kms).
  ##   x-amz-tagging: JString
  ##                : The tag-set for the object destination object this value must be used in conjunction with the TaggingDirective. The tag-set must be encoded as URL Query parameters
  ##   x-amz-copy-source-server-side-encryption-customer-algorithm: JString
  ##                                                              : Specifies the algorithm to use when decrypting the source object (e.g., AES256).
  ##   x-amz-object-lock-mode: JString
  ##                         : The object lock mode that you want to apply to the copied object.
  ##   x-amz-security-token: JString
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the object ACL.
  ##   x-amz-copy-source-server-side-encryption-customer-key-MD5: JString
  ##                                                            : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-object-lock-legal-hold: JString
  ##                               : Specifies whether you want to apply a Legal Hold to the copied object.
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the object.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable object.
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header.
  ##   x-amz-server-side-encryption-context: JString
  ##                                       : Specifies the AWS KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs.
  ##   x-amz-copy-source-if-unmodified-since: JString
  ##                                        : Copies the object if it hasn't been modified since the specified time.
  ##   Content-Disposition: JString
  ##                      : Specifies presentational information for the object.
  ##   Content-Encoding: JString
  ##                   : Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field.
  ##   x-amz-copy-source-if-modified-since: JString
  ##                                      : Copies the object if it has been modified since the specified time.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   x-amz-grant-full-control: JString
  ##                           : Gives the grantee READ, READ_ACP, and WRITE_ACP permissions on the object.
  ##   x-amz-copy-source-if-match: JString
  ##                             : Copies the object if its entity tag (ETag) matches the specified tag.
  ##   x-amz-copy-source-server-side-encryption-customer-key: JString
  ##                                                        : Specifies the customer-provided encryption key for Amazon S3 to use to decrypt the source object. The encryption key provided in this header must be one that was used when the source object was created.
  ##   x-amz-website-redirect-location: JString
  ##                                  : If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata.
  ##   Content-Language: JString
  ##                   : The language the content is in.
  ##   Content-Type: JString
  ##               : A standard MIME type describing the format of the object data.
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  ##   x-amz-server-side-encryption-aws-kms-key-id: JString
  ##                                              : Specifies the AWS KMS key ID to use for object encryption. All GET and PUT requests for an object protected by AWS KMS will fail if not made via SSL or using SigV4. Documentation on configuring any of the officially supported AWS SDKs and CLI can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
  ##   Expires: JString
  ##          : The date and time at which the object is no longer cacheable.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to read the object data and its metadata.
  section = newJObject()
  var valid_593019 = header.getOrDefault("Cache-Control")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "Cache-Control", valid_593019
  var valid_593020 = header.getOrDefault("x-amz-metadata-directive")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = newJString("COPY"))
  if valid_593020 != nil:
    section.add "x-amz-metadata-directive", valid_593020
  var valid_593021 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_593021
  var valid_593022 = header.getOrDefault("x-amz-storage-class")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_593022 != nil:
    section.add "x-amz-storage-class", valid_593022
  var valid_593023 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_593023
  var valid_593024 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_593024
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_593025 = header.getOrDefault("x-amz-copy-source")
  valid_593025 = validateParameter(valid_593025, JString, required = true,
                                 default = nil)
  if valid_593025 != nil:
    section.add "x-amz-copy-source", valid_593025
  var valid_593026 = header.getOrDefault("x-amz-tagging-directive")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = newJString("COPY"))
  if valid_593026 != nil:
    section.add "x-amz-tagging-directive", valid_593026
  var valid_593027 = header.getOrDefault("x-amz-server-side-encryption")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = newJString("AES256"))
  if valid_593027 != nil:
    section.add "x-amz-server-side-encryption", valid_593027
  var valid_593028 = header.getOrDefault("x-amz-tagging")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "x-amz-tagging", valid_593028
  var valid_593029 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_593029
  var valid_593030 = header.getOrDefault("x-amz-object-lock-mode")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_593030 != nil:
    section.add "x-amz-object-lock-mode", valid_593030
  var valid_593031 = header.getOrDefault("x-amz-security-token")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "x-amz-security-token", valid_593031
  var valid_593032 = header.getOrDefault("x-amz-grant-read-acp")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "x-amz-grant-read-acp", valid_593032
  var valid_593033 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_593033
  var valid_593034 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = newJString("ON"))
  if valid_593034 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_593034
  var valid_593035 = header.getOrDefault("x-amz-acl")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = newJString("private"))
  if valid_593035 != nil:
    section.add "x-amz-acl", valid_593035
  var valid_593036 = header.getOrDefault("x-amz-grant-write-acp")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "x-amz-grant-write-acp", valid_593036
  var valid_593037 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_593037
  var valid_593038 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "x-amz-server-side-encryption-context", valid_593038
  var valid_593039 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_593039
  var valid_593040 = header.getOrDefault("Content-Disposition")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "Content-Disposition", valid_593040
  var valid_593041 = header.getOrDefault("Content-Encoding")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "Content-Encoding", valid_593041
  var valid_593042 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_593042
  var valid_593043 = header.getOrDefault("x-amz-request-payer")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = newJString("requester"))
  if valid_593043 != nil:
    section.add "x-amz-request-payer", valid_593043
  var valid_593044 = header.getOrDefault("x-amz-grant-full-control")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "x-amz-grant-full-control", valid_593044
  var valid_593045 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "x-amz-copy-source-if-match", valid_593045
  var valid_593046 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_593046
  var valid_593047 = header.getOrDefault("x-amz-website-redirect-location")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "x-amz-website-redirect-location", valid_593047
  var valid_593048 = header.getOrDefault("Content-Language")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "Content-Language", valid_593048
  var valid_593049 = header.getOrDefault("Content-Type")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "Content-Type", valid_593049
  var valid_593050 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_593050
  var valid_593051 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_593051
  var valid_593052 = header.getOrDefault("Expires")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "Expires", valid_593052
  var valid_593053 = header.getOrDefault("x-amz-grant-read")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "x-amz-grant-read", valid_593053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593055: Call_CopyObject_593014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  let valid = call_593055.validator(path, query, header, formData, body)
  let scheme = call_593055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593055.url(scheme.get, call_593055.host, call_593055.base,
                         call_593055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593055, url, valid)

proc call*(call_593056: Call_CopyObject_593014; Bucket: string; Key: string;
          body: JsonNode): Recallable =
  ## copyObject
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   Key: string (required)
  ##      : <p/>
  ##   body: JObject (required)
  var path_593057 = newJObject()
  var body_593058 = newJObject()
  add(path_593057, "Bucket", newJString(Bucket))
  add(path_593057, "Key", newJString(Key))
  if body != nil:
    body_593058 = body
  result = call_593056.call(path_593057, nil, nil, nil, body_593058)

var copyObject* = Call_CopyObject_593014(name: "copyObject",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#x-amz-copy-source",
                                      validator: validate_CopyObject_593015,
                                      base: "/", url: url_CopyObject_593016,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBucket_593076 = ref object of OpenApiRestCall_592364
proc url_CreateBucket_593078(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBucket_593077(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593079 = path.getOrDefault("Bucket")
  valid_593079 = validateParameter(valid_593079, JString, required = true,
                                 default = nil)
  if valid_593079 != nil:
    section.add "Bucket", valid_593079
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-grant-write: JString
  ##                    : Allows grantee to create, overwrite, and delete any object in the bucket.
  ##   x-amz-security-token: JString
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the bucket ACL.
  ##   x-amz-bucket-object-lock-enabled: JBool
  ##                                   : Specifies whether you want Amazon S3 object lock to be enabled for the new bucket.
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the bucket.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable bucket.
  ##   x-amz-grant-full-control: JString
  ##                           : Allows grantee the read, write, read ACP, and write ACP permissions on the bucket.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to list the objects in the bucket.
  section = newJObject()
  var valid_593080 = header.getOrDefault("x-amz-grant-write")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "x-amz-grant-write", valid_593080
  var valid_593081 = header.getOrDefault("x-amz-security-token")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "x-amz-security-token", valid_593081
  var valid_593082 = header.getOrDefault("x-amz-grant-read-acp")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "x-amz-grant-read-acp", valid_593082
  var valid_593083 = header.getOrDefault("x-amz-bucket-object-lock-enabled")
  valid_593083 = validateParameter(valid_593083, JBool, required = false, default = nil)
  if valid_593083 != nil:
    section.add "x-amz-bucket-object-lock-enabled", valid_593083
  var valid_593084 = header.getOrDefault("x-amz-acl")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = newJString("private"))
  if valid_593084 != nil:
    section.add "x-amz-acl", valid_593084
  var valid_593085 = header.getOrDefault("x-amz-grant-write-acp")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "x-amz-grant-write-acp", valid_593085
  var valid_593086 = header.getOrDefault("x-amz-grant-full-control")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "x-amz-grant-full-control", valid_593086
  var valid_593087 = header.getOrDefault("x-amz-grant-read")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "x-amz-grant-read", valid_593087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593089: Call_CreateBucket_593076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  let valid = call_593089.validator(path, query, header, formData, body)
  let scheme = call_593089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593089.url(scheme.get, call_593089.host, call_593089.base,
                         call_593089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593089, url, valid)

proc call*(call_593090: Call_CreateBucket_593076; Bucket: string; body: JsonNode): Recallable =
  ## createBucket
  ## Creates a new bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_593091 = newJObject()
  var body_593092 = newJObject()
  add(path_593091, "Bucket", newJString(Bucket))
  if body != nil:
    body_593092 = body
  result = call_593090.call(path_593091, nil, nil, nil, body_593092)

var createBucket* = Call_CreateBucket_593076(name: "createBucket",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_CreateBucket_593077, base: "/", url: url_CreateBucket_593078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadBucket_593101 = ref object of OpenApiRestCall_592364
proc url_HeadBucket_593103(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_HeadBucket_593102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593104 = path.getOrDefault("Bucket")
  valid_593104 = validateParameter(valid_593104, JString, required = true,
                                 default = nil)
  if valid_593104 != nil:
    section.add "Bucket", valid_593104
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593105 = header.getOrDefault("x-amz-security-token")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "x-amz-security-token", valid_593105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593106: Call_HeadBucket_593101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  let valid = call_593106.validator(path, query, header, formData, body)
  let scheme = call_593106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593106.url(scheme.get, call_593106.host, call_593106.base,
                         call_593106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593106, url, valid)

proc call*(call_593107: Call_HeadBucket_593101; Bucket: string): Recallable =
  ## headBucket
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_593108 = newJObject()
  add(path_593108, "Bucket", newJString(Bucket))
  result = call_593107.call(path_593108, nil, nil, nil, nil)

var headBucket* = Call_HeadBucket_593101(name: "headBucket",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}",
                                      validator: validate_HeadBucket_593102,
                                      base: "/", url: url_HeadBucket_593103,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjects_593059 = ref object of OpenApiRestCall_592364
proc url_ListObjects_593061(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjects_593060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593062 = path.getOrDefault("Bucket")
  valid_593062 = validateParameter(valid_593062, JString, required = true,
                                 default = nil)
  if valid_593062 != nil:
    section.add "Bucket", valid_593062
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   prefix: JString
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   MaxKeys: JString
  ##          : Pagination limit
  ##   max-keys: JInt
  ##           : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   encoding-type: JString
  ##                : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   delimiter: JString
  ##            : A delimiter is a character you use to group keys.
  ##   marker: JString
  ##         : Specifies the key to start with when listing objects in a bucket.
  section = newJObject()
  var valid_593063 = query.getOrDefault("Marker")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "Marker", valid_593063
  var valid_593064 = query.getOrDefault("prefix")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "prefix", valid_593064
  var valid_593065 = query.getOrDefault("MaxKeys")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "MaxKeys", valid_593065
  var valid_593066 = query.getOrDefault("max-keys")
  valid_593066 = validateParameter(valid_593066, JInt, required = false, default = nil)
  if valid_593066 != nil:
    section.add "max-keys", valid_593066
  var valid_593067 = query.getOrDefault("encoding-type")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = newJString("url"))
  if valid_593067 != nil:
    section.add "encoding-type", valid_593067
  var valid_593068 = query.getOrDefault("delimiter")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "delimiter", valid_593068
  var valid_593069 = query.getOrDefault("marker")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "marker", valid_593069
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_593070 = header.getOrDefault("x-amz-security-token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "x-amz-security-token", valid_593070
  var valid_593071 = header.getOrDefault("x-amz-request-payer")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = newJString("requester"))
  if valid_593071 != nil:
    section.add "x-amz-request-payer", valid_593071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593072: Call_ListObjects_593059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
  let valid = call_593072.validator(path, query, header, formData, body)
  let scheme = call_593072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593072.url(scheme.get, call_593072.host, call_593072.base,
                         call_593072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593072, url, valid)

proc call*(call_593073: Call_ListObjects_593059; Bucket: string; Marker: string = "";
          prefix: string = ""; MaxKeys: string = ""; maxKeys: int = 0;
          encodingType: string = "url"; delimiter: string = ""; marker: string = ""): Recallable =
  ## listObjects
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
  ##   Marker: string
  ##         : Pagination token
  ##   prefix: string
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   MaxKeys: string
  ##          : Pagination limit
  ##   maxKeys: int
  ##          : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   encodingType: string
  ##               : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   delimiter: string
  ##            : A delimiter is a character you use to group keys.
  ##   marker: string
  ##         : Specifies the key to start with when listing objects in a bucket.
  var path_593074 = newJObject()
  var query_593075 = newJObject()
  add(query_593075, "Marker", newJString(Marker))
  add(query_593075, "prefix", newJString(prefix))
  add(path_593074, "Bucket", newJString(Bucket))
  add(query_593075, "MaxKeys", newJString(MaxKeys))
  add(query_593075, "max-keys", newJInt(maxKeys))
  add(query_593075, "encoding-type", newJString(encodingType))
  add(query_593075, "delimiter", newJString(delimiter))
  add(query_593075, "marker", newJString(marker))
  result = call_593073.call(path_593074, query_593075, nil, nil, nil)

var listObjects* = Call_ListObjects_593059(name: "listObjects",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com",
                                        route: "/{Bucket}",
                                        validator: validate_ListObjects_593060,
                                        base: "/", url: url_ListObjects_593061,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucket_593093 = ref object of OpenApiRestCall_592364
proc url_DeleteBucket_593095(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucket_593094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593096 = path.getOrDefault("Bucket")
  valid_593096 = validateParameter(valid_593096, JString, required = true,
                                 default = nil)
  if valid_593096 != nil:
    section.add "Bucket", valid_593096
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593097 = header.getOrDefault("x-amz-security-token")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "x-amz-security-token", valid_593097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593098: Call_DeleteBucket_593093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  let valid = call_593098.validator(path, query, header, formData, body)
  let scheme = call_593098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593098.url(scheme.get, call_593098.host, call_593098.base,
                         call_593098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593098, url, valid)

proc call*(call_593099: Call_DeleteBucket_593093; Bucket: string): Recallable =
  ## deleteBucket
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_593100 = newJObject()
  add(path_593100, "Bucket", newJString(Bucket))
  result = call_593099.call(path_593100, nil, nil, nil, nil)

var deleteBucket* = Call_DeleteBucket_593093(name: "deleteBucket",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_DeleteBucket_593094, base: "/", url: url_DeleteBucket_593095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultipartUpload_593109 = ref object of OpenApiRestCall_592364
proc url_CreateMultipartUpload_593111(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMultipartUpload_593110(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593112 = path.getOrDefault("Bucket")
  valid_593112 = validateParameter(valid_593112, JString, required = true,
                                 default = nil)
  if valid_593112 != nil:
    section.add "Bucket", valid_593112
  var valid_593113 = path.getOrDefault("Key")
  valid_593113 = validateParameter(valid_593113, JString, required = true,
                                 default = nil)
  if valid_593113 != nil:
    section.add "Key", valid_593113
  result.add "path", section
  ## parameters in `query` object:
  ##   uploads: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_593114 = query.getOrDefault("uploads")
  valid_593114 = validateParameter(valid_593114, JBool, required = true, default = nil)
  if valid_593114 != nil:
    section.add "uploads", valid_593114
  result.add "query", section
  ## parameters in `header` object:
  ##   Cache-Control: JString
  ##                : Specifies caching behavior along the request/reply chain.
  ##   x-amz-storage-class: JString
  ##                      : The type of storage to use for the object. Defaults to 'STANDARD'.
  ##   x-amz-object-lock-retain-until-date: JString
  ##                                      : Specifies the date and time when you want the object lock to expire.
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-server-side-encryption: JString
  ##                               : The Server-side encryption algorithm used when storing this object in S3 (e.g., AES256, aws:kms).
  ##   x-amz-tagging: JString
  ##                : The tag-set for the object. The tag-set must be encoded as URL Query parameters
  ##   x-amz-object-lock-mode: JString
  ##                         : Specifies the object lock mode that you want to apply to the uploaded object.
  ##   x-amz-security-token: JString
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the object ACL.
  ##   x-amz-object-lock-legal-hold: JString
  ##                               : Specifies whether you want to apply a Legal Hold to the uploaded object.
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the object.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable object.
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header.
  ##   x-amz-server-side-encryption-context: JString
  ##                                       : Specifies the AWS KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs.
  ##   Content-Disposition: JString
  ##                      : Specifies presentational information for the object.
  ##   Content-Encoding: JString
  ##                   : Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   x-amz-grant-full-control: JString
  ##                           : Gives the grantee READ, READ_ACP, and WRITE_ACP permissions on the object.
  ##   x-amz-website-redirect-location: JString
  ##                                  : If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata.
  ##   Content-Language: JString
  ##                   : The language the content is in.
  ##   Content-Type: JString
  ##               : A standard MIME type describing the format of the object data.
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  ##   x-amz-server-side-encryption-aws-kms-key-id: JString
  ##                                              : Specifies the AWS KMS key ID to use for object encryption. All GET and PUT requests for an object protected by AWS KMS will fail if not made via SSL or using SigV4. Documentation on configuring any of the officially supported AWS SDKs and CLI can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
  ##   Expires: JString
  ##          : The date and time at which the object is no longer cacheable.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to read the object data and its metadata.
  section = newJObject()
  var valid_593115 = header.getOrDefault("Cache-Control")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "Cache-Control", valid_593115
  var valid_593116 = header.getOrDefault("x-amz-storage-class")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_593116 != nil:
    section.add "x-amz-storage-class", valid_593116
  var valid_593117 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_593117
  var valid_593118 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_593118
  var valid_593119 = header.getOrDefault("x-amz-server-side-encryption")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = newJString("AES256"))
  if valid_593119 != nil:
    section.add "x-amz-server-side-encryption", valid_593119
  var valid_593120 = header.getOrDefault("x-amz-tagging")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "x-amz-tagging", valid_593120
  var valid_593121 = header.getOrDefault("x-amz-object-lock-mode")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_593121 != nil:
    section.add "x-amz-object-lock-mode", valid_593121
  var valid_593122 = header.getOrDefault("x-amz-security-token")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "x-amz-security-token", valid_593122
  var valid_593123 = header.getOrDefault("x-amz-grant-read-acp")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "x-amz-grant-read-acp", valid_593123
  var valid_593124 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = newJString("ON"))
  if valid_593124 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_593124
  var valid_593125 = header.getOrDefault("x-amz-acl")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = newJString("private"))
  if valid_593125 != nil:
    section.add "x-amz-acl", valid_593125
  var valid_593126 = header.getOrDefault("x-amz-grant-write-acp")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "x-amz-grant-write-acp", valid_593126
  var valid_593127 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_593127
  var valid_593128 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "x-amz-server-side-encryption-context", valid_593128
  var valid_593129 = header.getOrDefault("Content-Disposition")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "Content-Disposition", valid_593129
  var valid_593130 = header.getOrDefault("Content-Encoding")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "Content-Encoding", valid_593130
  var valid_593131 = header.getOrDefault("x-amz-request-payer")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = newJString("requester"))
  if valid_593131 != nil:
    section.add "x-amz-request-payer", valid_593131
  var valid_593132 = header.getOrDefault("x-amz-grant-full-control")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "x-amz-grant-full-control", valid_593132
  var valid_593133 = header.getOrDefault("x-amz-website-redirect-location")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "x-amz-website-redirect-location", valid_593133
  var valid_593134 = header.getOrDefault("Content-Language")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "Content-Language", valid_593134
  var valid_593135 = header.getOrDefault("Content-Type")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "Content-Type", valid_593135
  var valid_593136 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_593136
  var valid_593137 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_593137
  var valid_593138 = header.getOrDefault("Expires")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "Expires", valid_593138
  var valid_593139 = header.getOrDefault("x-amz-grant-read")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "x-amz-grant-read", valid_593139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593141: Call_CreateMultipartUpload_593109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  let valid = call_593141.validator(path, query, header, formData, body)
  let scheme = call_593141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593141.url(scheme.get, call_593141.host, call_593141.base,
                         call_593141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593141, url, valid)

proc call*(call_593142: Call_CreateMultipartUpload_593109; Bucket: string;
          Key: string; body: JsonNode; uploads: bool): Recallable =
  ## createMultipartUpload
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   Key: string (required)
  ##      : <p/>
  ##   body: JObject (required)
  ##   uploads: bool (required)
  var path_593143 = newJObject()
  var query_593144 = newJObject()
  var body_593145 = newJObject()
  add(path_593143, "Bucket", newJString(Bucket))
  add(path_593143, "Key", newJString(Key))
  if body != nil:
    body_593145 = body
  add(query_593144, "uploads", newJBool(uploads))
  result = call_593142.call(path_593143, query_593144, nil, nil, body_593145)

var createMultipartUpload* = Call_CreateMultipartUpload_593109(
    name: "createMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploads",
    validator: validate_CreateMultipartUpload_593110, base: "/",
    url: url_CreateMultipartUpload_593111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAnalyticsConfiguration_593157 = ref object of OpenApiRestCall_592364
proc url_PutBucketAnalyticsConfiguration_593159(protocol: Scheme; host: string;
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

proc validate_PutBucketAnalyticsConfiguration_593158(path: JsonNode;
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
  var valid_593160 = path.getOrDefault("Bucket")
  valid_593160 = validateParameter(valid_593160, JString, required = true,
                                 default = nil)
  if valid_593160 != nil:
    section.add "Bucket", valid_593160
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_593161 = query.getOrDefault("analytics")
  valid_593161 = validateParameter(valid_593161, JBool, required = true, default = nil)
  if valid_593161 != nil:
    section.add "analytics", valid_593161
  var valid_593162 = query.getOrDefault("id")
  valid_593162 = validateParameter(valid_593162, JString, required = true,
                                 default = nil)
  if valid_593162 != nil:
    section.add "id", valid_593162
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593163 = header.getOrDefault("x-amz-security-token")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "x-amz-security-token", valid_593163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593165: Call_PutBucketAnalyticsConfiguration_593157;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_593165.validator(path, query, header, formData, body)
  let scheme = call_593165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593165.url(scheme.get, call_593165.host, call_593165.base,
                         call_593165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593165, url, valid)

proc call*(call_593166: Call_PutBucketAnalyticsConfiguration_593157;
          Bucket: string; analytics: bool; id: string; body: JsonNode): Recallable =
  ## putBucketAnalyticsConfiguration
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   Bucket: string (required)
  ##         : The name of the bucket to which an analytics configuration is stored.
  ##   analytics: bool (required)
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   body: JObject (required)
  var path_593167 = newJObject()
  var query_593168 = newJObject()
  var body_593169 = newJObject()
  add(path_593167, "Bucket", newJString(Bucket))
  add(query_593168, "analytics", newJBool(analytics))
  add(query_593168, "id", newJString(id))
  if body != nil:
    body_593169 = body
  result = call_593166.call(path_593167, query_593168, nil, nil, body_593169)

var putBucketAnalyticsConfiguration* = Call_PutBucketAnalyticsConfiguration_593157(
    name: "putBucketAnalyticsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_PutBucketAnalyticsConfiguration_593158, base: "/",
    url: url_PutBucketAnalyticsConfiguration_593159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAnalyticsConfiguration_593146 = ref object of OpenApiRestCall_592364
proc url_GetBucketAnalyticsConfiguration_593148(protocol: Scheme; host: string;
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

proc validate_GetBucketAnalyticsConfiguration_593147(path: JsonNode;
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
  var valid_593149 = path.getOrDefault("Bucket")
  valid_593149 = validateParameter(valid_593149, JString, required = true,
                                 default = nil)
  if valid_593149 != nil:
    section.add "Bucket", valid_593149
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_593150 = query.getOrDefault("analytics")
  valid_593150 = validateParameter(valid_593150, JBool, required = true, default = nil)
  if valid_593150 != nil:
    section.add "analytics", valid_593150
  var valid_593151 = query.getOrDefault("id")
  valid_593151 = validateParameter(valid_593151, JString, required = true,
                                 default = nil)
  if valid_593151 != nil:
    section.add "id", valid_593151
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593152 = header.getOrDefault("x-amz-security-token")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "x-amz-security-token", valid_593152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593153: Call_GetBucketAnalyticsConfiguration_593146;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_593153.validator(path, query, header, formData, body)
  let scheme = call_593153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593153.url(scheme.get, call_593153.host, call_593153.base,
                         call_593153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593153, url, valid)

proc call*(call_593154: Call_GetBucketAnalyticsConfiguration_593146;
          Bucket: string; analytics: bool; id: string): Recallable =
  ## getBucketAnalyticsConfiguration
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is retrieved.
  ##   analytics: bool (required)
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  var path_593155 = newJObject()
  var query_593156 = newJObject()
  add(path_593155, "Bucket", newJString(Bucket))
  add(query_593156, "analytics", newJBool(analytics))
  add(query_593156, "id", newJString(id))
  result = call_593154.call(path_593155, query_593156, nil, nil, nil)

var getBucketAnalyticsConfiguration* = Call_GetBucketAnalyticsConfiguration_593146(
    name: "getBucketAnalyticsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_GetBucketAnalyticsConfiguration_593147, base: "/",
    url: url_GetBucketAnalyticsConfiguration_593148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketAnalyticsConfiguration_593170 = ref object of OpenApiRestCall_592364
proc url_DeleteBucketAnalyticsConfiguration_593172(protocol: Scheme; host: string;
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

proc validate_DeleteBucketAnalyticsConfiguration_593171(path: JsonNode;
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
  var valid_593173 = path.getOrDefault("Bucket")
  valid_593173 = validateParameter(valid_593173, JString, required = true,
                                 default = nil)
  if valid_593173 != nil:
    section.add "Bucket", valid_593173
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_593174 = query.getOrDefault("analytics")
  valid_593174 = validateParameter(valid_593174, JBool, required = true, default = nil)
  if valid_593174 != nil:
    section.add "analytics", valid_593174
  var valid_593175 = query.getOrDefault("id")
  valid_593175 = validateParameter(valid_593175, JString, required = true,
                                 default = nil)
  if valid_593175 != nil:
    section.add "id", valid_593175
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593176 = header.getOrDefault("x-amz-security-token")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "x-amz-security-token", valid_593176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593177: Call_DeleteBucketAnalyticsConfiguration_593170;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ## 
  let valid = call_593177.validator(path, query, header, formData, body)
  let scheme = call_593177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593177.url(scheme.get, call_593177.host, call_593177.base,
                         call_593177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593177, url, valid)

proc call*(call_593178: Call_DeleteBucketAnalyticsConfiguration_593170;
          Bucket: string; analytics: bool; id: string): Recallable =
  ## deleteBucketAnalyticsConfiguration
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is deleted.
  ##   analytics: bool (required)
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  var path_593179 = newJObject()
  var query_593180 = newJObject()
  add(path_593179, "Bucket", newJString(Bucket))
  add(query_593180, "analytics", newJBool(analytics))
  add(query_593180, "id", newJString(id))
  result = call_593178.call(path_593179, query_593180, nil, nil, nil)

var deleteBucketAnalyticsConfiguration* = Call_DeleteBucketAnalyticsConfiguration_593170(
    name: "deleteBucketAnalyticsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_DeleteBucketAnalyticsConfiguration_593171, base: "/",
    url: url_DeleteBucketAnalyticsConfiguration_593172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketCors_593191 = ref object of OpenApiRestCall_592364
proc url_PutBucketCors_593193(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketCors_593192(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593194 = path.getOrDefault("Bucket")
  valid_593194 = validateParameter(valid_593194, JString, required = true,
                                 default = nil)
  if valid_593194 != nil:
    section.add "Bucket", valid_593194
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_593195 = query.getOrDefault("cors")
  valid_593195 = validateParameter(valid_593195, JBool, required = true, default = nil)
  if valid_593195 != nil:
    section.add "cors", valid_593195
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_593196 = header.getOrDefault("x-amz-security-token")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "x-amz-security-token", valid_593196
  var valid_593197 = header.getOrDefault("Content-MD5")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "Content-MD5", valid_593197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593199: Call_PutBucketCors_593191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the CORS configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  let valid = call_593199.validator(path, query, header, formData, body)
  let scheme = call_593199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593199.url(scheme.get, call_593199.host, call_593199.base,
                         call_593199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593199, url, valid)

proc call*(call_593200: Call_PutBucketCors_593191; Bucket: string; body: JsonNode;
          cors: bool): Recallable =
  ## putBucketCors
  ## Sets the CORS configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   cors: bool (required)
  var path_593201 = newJObject()
  var query_593202 = newJObject()
  var body_593203 = newJObject()
  add(path_593201, "Bucket", newJString(Bucket))
  if body != nil:
    body_593203 = body
  add(query_593202, "cors", newJBool(cors))
  result = call_593200.call(path_593201, query_593202, nil, nil, body_593203)

var putBucketCors* = Call_PutBucketCors_593191(name: "putBucketCors",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_PutBucketCors_593192, base: "/", url: url_PutBucketCors_593193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketCors_593181 = ref object of OpenApiRestCall_592364
proc url_GetBucketCors_593183(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketCors_593182(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593184 = path.getOrDefault("Bucket")
  valid_593184 = validateParameter(valid_593184, JString, required = true,
                                 default = nil)
  if valid_593184 != nil:
    section.add "Bucket", valid_593184
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_593185 = query.getOrDefault("cors")
  valid_593185 = validateParameter(valid_593185, JBool, required = true, default = nil)
  if valid_593185 != nil:
    section.add "cors", valid_593185
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593186 = header.getOrDefault("x-amz-security-token")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "x-amz-security-token", valid_593186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593187: Call_GetBucketCors_593181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the CORS configuration for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  let valid = call_593187.validator(path, query, header, formData, body)
  let scheme = call_593187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593187.url(scheme.get, call_593187.host, call_593187.base,
                         call_593187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593187, url, valid)

proc call*(call_593188: Call_GetBucketCors_593181; Bucket: string; cors: bool): Recallable =
  ## getBucketCors
  ## Returns the CORS configuration for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   cors: bool (required)
  var path_593189 = newJObject()
  var query_593190 = newJObject()
  add(path_593189, "Bucket", newJString(Bucket))
  add(query_593190, "cors", newJBool(cors))
  result = call_593188.call(path_593189, query_593190, nil, nil, nil)

var getBucketCors* = Call_GetBucketCors_593181(name: "getBucketCors",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_GetBucketCors_593182, base: "/", url: url_GetBucketCors_593183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketCors_593204 = ref object of OpenApiRestCall_592364
proc url_DeleteBucketCors_593206(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketCors_593205(path: JsonNode; query: JsonNode;
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
  var valid_593207 = path.getOrDefault("Bucket")
  valid_593207 = validateParameter(valid_593207, JString, required = true,
                                 default = nil)
  if valid_593207 != nil:
    section.add "Bucket", valid_593207
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_593208 = query.getOrDefault("cors")
  valid_593208 = validateParameter(valid_593208, JBool, required = true, default = nil)
  if valid_593208 != nil:
    section.add "cors", valid_593208
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593209 = header.getOrDefault("x-amz-security-token")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "x-amz-security-token", valid_593209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593210: Call_DeleteBucketCors_593204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the CORS configuration information set for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  let valid = call_593210.validator(path, query, header, formData, body)
  let scheme = call_593210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593210.url(scheme.get, call_593210.host, call_593210.base,
                         call_593210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593210, url, valid)

proc call*(call_593211: Call_DeleteBucketCors_593204; Bucket: string; cors: bool): Recallable =
  ## deleteBucketCors
  ## Deletes the CORS configuration information set for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   cors: bool (required)
  var path_593212 = newJObject()
  var query_593213 = newJObject()
  add(path_593212, "Bucket", newJString(Bucket))
  add(query_593213, "cors", newJBool(cors))
  result = call_593211.call(path_593212, query_593213, nil, nil, nil)

var deleteBucketCors* = Call_DeleteBucketCors_593204(name: "deleteBucketCors",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_DeleteBucketCors_593205, base: "/",
    url: url_DeleteBucketCors_593206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketEncryption_593224 = ref object of OpenApiRestCall_592364
proc url_PutBucketEncryption_593226(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketEncryption_593225(path: JsonNode; query: JsonNode;
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
  var valid_593227 = path.getOrDefault("Bucket")
  valid_593227 = validateParameter(valid_593227, JString, required = true,
                                 default = nil)
  if valid_593227 != nil:
    section.add "Bucket", valid_593227
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_593228 = query.getOrDefault("encryption")
  valid_593228 = validateParameter(valid_593228, JBool, required = true, default = nil)
  if valid_593228 != nil:
    section.add "encryption", valid_593228
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the server-side encryption configuration. This parameter is auto-populated when using the command from the CLI.
  section = newJObject()
  var valid_593229 = header.getOrDefault("x-amz-security-token")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "x-amz-security-token", valid_593229
  var valid_593230 = header.getOrDefault("Content-MD5")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "Content-MD5", valid_593230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593232: Call_PutBucketEncryption_593224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ## 
  let valid = call_593232.validator(path, query, header, formData, body)
  let scheme = call_593232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593232.url(scheme.get, call_593232.host, call_593232.base,
                         call_593232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593232, url, valid)

proc call*(call_593233: Call_PutBucketEncryption_593224; Bucket: string;
          encryption: bool; body: JsonNode): Recallable =
  ## putBucketEncryption
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ##   Bucket: string (required)
  ##         : Specifies default encryption for a bucket using server-side encryption with Amazon S3-managed keys (SSE-S3) or AWS KMS-managed keys (SSE-KMS). For information about the Amazon S3 default encryption feature, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 Default Bucket Encryption</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   encryption: bool (required)
  ##   body: JObject (required)
  var path_593234 = newJObject()
  var query_593235 = newJObject()
  var body_593236 = newJObject()
  add(path_593234, "Bucket", newJString(Bucket))
  add(query_593235, "encryption", newJBool(encryption))
  if body != nil:
    body_593236 = body
  result = call_593233.call(path_593234, query_593235, nil, nil, body_593236)

var putBucketEncryption* = Call_PutBucketEncryption_593224(
    name: "putBucketEncryption", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_PutBucketEncryption_593225,
    base: "/", url: url_PutBucketEncryption_593226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketEncryption_593214 = ref object of OpenApiRestCall_592364
proc url_GetBucketEncryption_593216(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketEncryption_593215(path: JsonNode; query: JsonNode;
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
  var valid_593217 = path.getOrDefault("Bucket")
  valid_593217 = validateParameter(valid_593217, JString, required = true,
                                 default = nil)
  if valid_593217 != nil:
    section.add "Bucket", valid_593217
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_593218 = query.getOrDefault("encryption")
  valid_593218 = validateParameter(valid_593218, JBool, required = true, default = nil)
  if valid_593218 != nil:
    section.add "encryption", valid_593218
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593219 = header.getOrDefault("x-amz-security-token")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "x-amz-security-token", valid_593219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593220: Call_GetBucketEncryption_593214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the server-side encryption configuration of a bucket.
  ## 
  let valid = call_593220.validator(path, query, header, formData, body)
  let scheme = call_593220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593220.url(scheme.get, call_593220.host, call_593220.base,
                         call_593220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593220, url, valid)

proc call*(call_593221: Call_GetBucketEncryption_593214; Bucket: string;
          encryption: bool): Recallable =
  ## getBucketEncryption
  ## Returns the server-side encryption configuration of a bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket from which the server-side encryption configuration is retrieved.
  ##   encryption: bool (required)
  var path_593222 = newJObject()
  var query_593223 = newJObject()
  add(path_593222, "Bucket", newJString(Bucket))
  add(query_593223, "encryption", newJBool(encryption))
  result = call_593221.call(path_593222, query_593223, nil, nil, nil)

var getBucketEncryption* = Call_GetBucketEncryption_593214(
    name: "getBucketEncryption", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_GetBucketEncryption_593215,
    base: "/", url: url_GetBucketEncryption_593216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketEncryption_593237 = ref object of OpenApiRestCall_592364
proc url_DeleteBucketEncryption_593239(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketEncryption_593238(path: JsonNode; query: JsonNode;
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
  var valid_593240 = path.getOrDefault("Bucket")
  valid_593240 = validateParameter(valid_593240, JString, required = true,
                                 default = nil)
  if valid_593240 != nil:
    section.add "Bucket", valid_593240
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_593241 = query.getOrDefault("encryption")
  valid_593241 = validateParameter(valid_593241, JBool, required = true, default = nil)
  if valid_593241 != nil:
    section.add "encryption", valid_593241
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593242 = header.getOrDefault("x-amz-security-token")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "x-amz-security-token", valid_593242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593243: Call_DeleteBucketEncryption_593237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the server-side encryption configuration from the bucket.
  ## 
  let valid = call_593243.validator(path, query, header, formData, body)
  let scheme = call_593243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593243.url(scheme.get, call_593243.host, call_593243.base,
                         call_593243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593243, url, valid)

proc call*(call_593244: Call_DeleteBucketEncryption_593237; Bucket: string;
          encryption: bool): Recallable =
  ## deleteBucketEncryption
  ## Deletes the server-side encryption configuration from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the server-side encryption configuration to delete.
  ##   encryption: bool (required)
  var path_593245 = newJObject()
  var query_593246 = newJObject()
  add(path_593245, "Bucket", newJString(Bucket))
  add(query_593246, "encryption", newJBool(encryption))
  result = call_593244.call(path_593245, query_593246, nil, nil, nil)

var deleteBucketEncryption* = Call_DeleteBucketEncryption_593237(
    name: "deleteBucketEncryption", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#encryption",
    validator: validate_DeleteBucketEncryption_593238, base: "/",
    url: url_DeleteBucketEncryption_593239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketInventoryConfiguration_593258 = ref object of OpenApiRestCall_592364
proc url_PutBucketInventoryConfiguration_593260(protocol: Scheme; host: string;
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

proc validate_PutBucketInventoryConfiguration_593259(path: JsonNode;
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
  var valid_593261 = path.getOrDefault("Bucket")
  valid_593261 = validateParameter(valid_593261, JString, required = true,
                                 default = nil)
  if valid_593261 != nil:
    section.add "Bucket", valid_593261
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  ##   inventory: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_593262 = query.getOrDefault("id")
  valid_593262 = validateParameter(valid_593262, JString, required = true,
                                 default = nil)
  if valid_593262 != nil:
    section.add "id", valid_593262
  var valid_593263 = query.getOrDefault("inventory")
  valid_593263 = validateParameter(valid_593263, JBool, required = true, default = nil)
  if valid_593263 != nil:
    section.add "inventory", valid_593263
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593264 = header.getOrDefault("x-amz-security-token")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "x-amz-security-token", valid_593264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593266: Call_PutBucketInventoryConfiguration_593258;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_593266.validator(path, query, header, formData, body)
  let scheme = call_593266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593266.url(scheme.get, call_593266.host, call_593266.base,
                         call_593266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593266, url, valid)

proc call*(call_593267: Call_PutBucketInventoryConfiguration_593258;
          Bucket: string; id: string; body: JsonNode; inventory: bool): Recallable =
  ## putBucketInventoryConfiguration
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket where the inventory configuration will be stored.
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   body: JObject (required)
  ##   inventory: bool (required)
  var path_593268 = newJObject()
  var query_593269 = newJObject()
  var body_593270 = newJObject()
  add(path_593268, "Bucket", newJString(Bucket))
  add(query_593269, "id", newJString(id))
  if body != nil:
    body_593270 = body
  add(query_593269, "inventory", newJBool(inventory))
  result = call_593267.call(path_593268, query_593269, nil, nil, body_593270)

var putBucketInventoryConfiguration* = Call_PutBucketInventoryConfiguration_593258(
    name: "putBucketInventoryConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_PutBucketInventoryConfiguration_593259, base: "/",
    url: url_PutBucketInventoryConfiguration_593260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketInventoryConfiguration_593247 = ref object of OpenApiRestCall_592364
proc url_GetBucketInventoryConfiguration_593249(protocol: Scheme; host: string;
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

proc validate_GetBucketInventoryConfiguration_593248(path: JsonNode;
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
  var valid_593250 = path.getOrDefault("Bucket")
  valid_593250 = validateParameter(valid_593250, JString, required = true,
                                 default = nil)
  if valid_593250 != nil:
    section.add "Bucket", valid_593250
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  ##   inventory: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_593251 = query.getOrDefault("id")
  valid_593251 = validateParameter(valid_593251, JString, required = true,
                                 default = nil)
  if valid_593251 != nil:
    section.add "id", valid_593251
  var valid_593252 = query.getOrDefault("inventory")
  valid_593252 = validateParameter(valid_593252, JBool, required = true, default = nil)
  if valid_593252 != nil:
    section.add "inventory", valid_593252
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593253 = header.getOrDefault("x-amz-security-token")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "x-amz-security-token", valid_593253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593254: Call_GetBucketInventoryConfiguration_593247;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_593254.validator(path, query, header, formData, body)
  let scheme = call_593254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593254.url(scheme.get, call_593254.host, call_593254.base,
                         call_593254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593254, url, valid)

proc call*(call_593255: Call_GetBucketInventoryConfiguration_593247;
          Bucket: string; id: string; inventory: bool): Recallable =
  ## getBucketInventoryConfiguration
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to retrieve.
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   inventory: bool (required)
  var path_593256 = newJObject()
  var query_593257 = newJObject()
  add(path_593256, "Bucket", newJString(Bucket))
  add(query_593257, "id", newJString(id))
  add(query_593257, "inventory", newJBool(inventory))
  result = call_593255.call(path_593256, query_593257, nil, nil, nil)

var getBucketInventoryConfiguration* = Call_GetBucketInventoryConfiguration_593247(
    name: "getBucketInventoryConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_GetBucketInventoryConfiguration_593248, base: "/",
    url: url_GetBucketInventoryConfiguration_593249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketInventoryConfiguration_593271 = ref object of OpenApiRestCall_592364
proc url_DeleteBucketInventoryConfiguration_593273(protocol: Scheme; host: string;
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

proc validate_DeleteBucketInventoryConfiguration_593272(path: JsonNode;
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
  var valid_593274 = path.getOrDefault("Bucket")
  valid_593274 = validateParameter(valid_593274, JString, required = true,
                                 default = nil)
  if valid_593274 != nil:
    section.add "Bucket", valid_593274
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  ##   inventory: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_593275 = query.getOrDefault("id")
  valid_593275 = validateParameter(valid_593275, JString, required = true,
                                 default = nil)
  if valid_593275 != nil:
    section.add "id", valid_593275
  var valid_593276 = query.getOrDefault("inventory")
  valid_593276 = validateParameter(valid_593276, JBool, required = true, default = nil)
  if valid_593276 != nil:
    section.add "inventory", valid_593276
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593277 = header.getOrDefault("x-amz-security-token")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "x-amz-security-token", valid_593277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593278: Call_DeleteBucketInventoryConfiguration_593271;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_593278.validator(path, query, header, formData, body)
  let scheme = call_593278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593278.url(scheme.get, call_593278.host, call_593278.base,
                         call_593278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593278, url, valid)

proc call*(call_593279: Call_DeleteBucketInventoryConfiguration_593271;
          Bucket: string; id: string; inventory: bool): Recallable =
  ## deleteBucketInventoryConfiguration
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to delete.
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   inventory: bool (required)
  var path_593280 = newJObject()
  var query_593281 = newJObject()
  add(path_593280, "Bucket", newJString(Bucket))
  add(query_593281, "id", newJString(id))
  add(query_593281, "inventory", newJBool(inventory))
  result = call_593279.call(path_593280, query_593281, nil, nil, nil)

var deleteBucketInventoryConfiguration* = Call_DeleteBucketInventoryConfiguration_593271(
    name: "deleteBucketInventoryConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_DeleteBucketInventoryConfiguration_593272, base: "/",
    url: url_DeleteBucketInventoryConfiguration_593273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycleConfiguration_593292 = ref object of OpenApiRestCall_592364
proc url_PutBucketLifecycleConfiguration_593294(protocol: Scheme; host: string;
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

proc validate_PutBucketLifecycleConfiguration_593293(path: JsonNode;
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
  var valid_593295 = path.getOrDefault("Bucket")
  valid_593295 = validateParameter(valid_593295, JString, required = true,
                                 default = nil)
  if valid_593295 != nil:
    section.add "Bucket", valid_593295
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_593296 = query.getOrDefault("lifecycle")
  valid_593296 = validateParameter(valid_593296, JBool, required = true, default = nil)
  if valid_593296 != nil:
    section.add "lifecycle", valid_593296
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593297 = header.getOrDefault("x-amz-security-token")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "x-amz-security-token", valid_593297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593299: Call_PutBucketLifecycleConfiguration_593292;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ## 
  let valid = call_593299.validator(path, query, header, formData, body)
  let scheme = call_593299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593299.url(scheme.get, call_593299.host, call_593299.base,
                         call_593299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593299, url, valid)

proc call*(call_593300: Call_PutBucketLifecycleConfiguration_593292;
          Bucket: string; body: JsonNode; lifecycle: bool): Recallable =
  ## putBucketLifecycleConfiguration
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   lifecycle: bool (required)
  var path_593301 = newJObject()
  var query_593302 = newJObject()
  var body_593303 = newJObject()
  add(path_593301, "Bucket", newJString(Bucket))
  if body != nil:
    body_593303 = body
  add(query_593302, "lifecycle", newJBool(lifecycle))
  result = call_593300.call(path_593301, query_593302, nil, nil, body_593303)

var putBucketLifecycleConfiguration* = Call_PutBucketLifecycleConfiguration_593292(
    name: "putBucketLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_PutBucketLifecycleConfiguration_593293, base: "/",
    url: url_PutBucketLifecycleConfiguration_593294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycleConfiguration_593282 = ref object of OpenApiRestCall_592364
proc url_GetBucketLifecycleConfiguration_593284(protocol: Scheme; host: string;
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

proc validate_GetBucketLifecycleConfiguration_593283(path: JsonNode;
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
  var valid_593285 = path.getOrDefault("Bucket")
  valid_593285 = validateParameter(valid_593285, JString, required = true,
                                 default = nil)
  if valid_593285 != nil:
    section.add "Bucket", valid_593285
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_593286 = query.getOrDefault("lifecycle")
  valid_593286 = validateParameter(valid_593286, JBool, required = true, default = nil)
  if valid_593286 != nil:
    section.add "lifecycle", valid_593286
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593287 = header.getOrDefault("x-amz-security-token")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "x-amz-security-token", valid_593287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593288: Call_GetBucketLifecycleConfiguration_593282;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the lifecycle configuration information set on the bucket.
  ## 
  let valid = call_593288.validator(path, query, header, formData, body)
  let scheme = call_593288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593288.url(scheme.get, call_593288.host, call_593288.base,
                         call_593288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593288, url, valid)

proc call*(call_593289: Call_GetBucketLifecycleConfiguration_593282;
          Bucket: string; lifecycle: bool): Recallable =
  ## getBucketLifecycleConfiguration
  ## Returns the lifecycle configuration information set on the bucket.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_593290 = newJObject()
  var query_593291 = newJObject()
  add(path_593290, "Bucket", newJString(Bucket))
  add(query_593291, "lifecycle", newJBool(lifecycle))
  result = call_593289.call(path_593290, query_593291, nil, nil, nil)

var getBucketLifecycleConfiguration* = Call_GetBucketLifecycleConfiguration_593282(
    name: "getBucketLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_GetBucketLifecycleConfiguration_593283, base: "/",
    url: url_GetBucketLifecycleConfiguration_593284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketLifecycle_593304 = ref object of OpenApiRestCall_592364
proc url_DeleteBucketLifecycle_593306(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketLifecycle_593305(path: JsonNode; query: JsonNode;
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
  var valid_593307 = path.getOrDefault("Bucket")
  valid_593307 = validateParameter(valid_593307, JString, required = true,
                                 default = nil)
  if valid_593307 != nil:
    section.add "Bucket", valid_593307
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_593308 = query.getOrDefault("lifecycle")
  valid_593308 = validateParameter(valid_593308, JBool, required = true, default = nil)
  if valid_593308 != nil:
    section.add "lifecycle", valid_593308
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593309 = header.getOrDefault("x-amz-security-token")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "x-amz-security-token", valid_593309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593310: Call_DeleteBucketLifecycle_593304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the lifecycle configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  let valid = call_593310.validator(path, query, header, formData, body)
  let scheme = call_593310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593310.url(scheme.get, call_593310.host, call_593310.base,
                         call_593310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593310, url, valid)

proc call*(call_593311: Call_DeleteBucketLifecycle_593304; Bucket: string;
          lifecycle: bool): Recallable =
  ## deleteBucketLifecycle
  ## Deletes the lifecycle configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_593312 = newJObject()
  var query_593313 = newJObject()
  add(path_593312, "Bucket", newJString(Bucket))
  add(query_593313, "lifecycle", newJBool(lifecycle))
  result = call_593311.call(path_593312, query_593313, nil, nil, nil)

var deleteBucketLifecycle* = Call_DeleteBucketLifecycle_593304(
    name: "deleteBucketLifecycle", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_DeleteBucketLifecycle_593305, base: "/",
    url: url_DeleteBucketLifecycle_593306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketMetricsConfiguration_593325 = ref object of OpenApiRestCall_592364
proc url_PutBucketMetricsConfiguration_593327(protocol: Scheme; host: string;
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

proc validate_PutBucketMetricsConfiguration_593326(path: JsonNode; query: JsonNode;
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
  var valid_593328 = path.getOrDefault("Bucket")
  valid_593328 = validateParameter(valid_593328, JString, required = true,
                                 default = nil)
  if valid_593328 != nil:
    section.add "Bucket", valid_593328
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_593329 = query.getOrDefault("metrics")
  valid_593329 = validateParameter(valid_593329, JBool, required = true, default = nil)
  if valid_593329 != nil:
    section.add "metrics", valid_593329
  var valid_593330 = query.getOrDefault("id")
  valid_593330 = validateParameter(valid_593330, JString, required = true,
                                 default = nil)
  if valid_593330 != nil:
    section.add "id", valid_593330
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593331 = header.getOrDefault("x-amz-security-token")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "x-amz-security-token", valid_593331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593333: Call_PutBucketMetricsConfiguration_593325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ## 
  let valid = call_593333.validator(path, query, header, formData, body)
  let scheme = call_593333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593333.url(scheme.get, call_593333.host, call_593333.base,
                         call_593333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593333, url, valid)

proc call*(call_593334: Call_PutBucketMetricsConfiguration_593325; Bucket: string;
          metrics: bool; id: string; body: JsonNode): Recallable =
  ## putBucketMetricsConfiguration
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket for which the metrics configuration is set.
  ##   metrics: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   body: JObject (required)
  var path_593335 = newJObject()
  var query_593336 = newJObject()
  var body_593337 = newJObject()
  add(path_593335, "Bucket", newJString(Bucket))
  add(query_593336, "metrics", newJBool(metrics))
  add(query_593336, "id", newJString(id))
  if body != nil:
    body_593337 = body
  result = call_593334.call(path_593335, query_593336, nil, nil, body_593337)

var putBucketMetricsConfiguration* = Call_PutBucketMetricsConfiguration_593325(
    name: "putBucketMetricsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_PutBucketMetricsConfiguration_593326, base: "/",
    url: url_PutBucketMetricsConfiguration_593327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketMetricsConfiguration_593314 = ref object of OpenApiRestCall_592364
proc url_GetBucketMetricsConfiguration_593316(protocol: Scheme; host: string;
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

proc validate_GetBucketMetricsConfiguration_593315(path: JsonNode; query: JsonNode;
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
  var valid_593317 = path.getOrDefault("Bucket")
  valid_593317 = validateParameter(valid_593317, JString, required = true,
                                 default = nil)
  if valid_593317 != nil:
    section.add "Bucket", valid_593317
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_593318 = query.getOrDefault("metrics")
  valid_593318 = validateParameter(valid_593318, JBool, required = true, default = nil)
  if valid_593318 != nil:
    section.add "metrics", valid_593318
  var valid_593319 = query.getOrDefault("id")
  valid_593319 = validateParameter(valid_593319, JString, required = true,
                                 default = nil)
  if valid_593319 != nil:
    section.add "id", valid_593319
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593320 = header.getOrDefault("x-amz-security-token")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "x-amz-security-token", valid_593320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593321: Call_GetBucketMetricsConfiguration_593314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_593321.validator(path, query, header, formData, body)
  let scheme = call_593321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593321.url(scheme.get, call_593321.host, call_593321.base,
                         call_593321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593321, url, valid)

proc call*(call_593322: Call_GetBucketMetricsConfiguration_593314; Bucket: string;
          metrics: bool; id: string): Recallable =
  ## getBucketMetricsConfiguration
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to retrieve.
  ##   metrics: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  var path_593323 = newJObject()
  var query_593324 = newJObject()
  add(path_593323, "Bucket", newJString(Bucket))
  add(query_593324, "metrics", newJBool(metrics))
  add(query_593324, "id", newJString(id))
  result = call_593322.call(path_593323, query_593324, nil, nil, nil)

var getBucketMetricsConfiguration* = Call_GetBucketMetricsConfiguration_593314(
    name: "getBucketMetricsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_GetBucketMetricsConfiguration_593315, base: "/",
    url: url_GetBucketMetricsConfiguration_593316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketMetricsConfiguration_593338 = ref object of OpenApiRestCall_592364
proc url_DeleteBucketMetricsConfiguration_593340(protocol: Scheme; host: string;
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

proc validate_DeleteBucketMetricsConfiguration_593339(path: JsonNode;
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
  var valid_593341 = path.getOrDefault("Bucket")
  valid_593341 = validateParameter(valid_593341, JString, required = true,
                                 default = nil)
  if valid_593341 != nil:
    section.add "Bucket", valid_593341
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_593342 = query.getOrDefault("metrics")
  valid_593342 = validateParameter(valid_593342, JBool, required = true, default = nil)
  if valid_593342 != nil:
    section.add "metrics", valid_593342
  var valid_593343 = query.getOrDefault("id")
  valid_593343 = validateParameter(valid_593343, JString, required = true,
                                 default = nil)
  if valid_593343 != nil:
    section.add "id", valid_593343
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593344 = header.getOrDefault("x-amz-security-token")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "x-amz-security-token", valid_593344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593345: Call_DeleteBucketMetricsConfiguration_593338;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_593345.validator(path, query, header, formData, body)
  let scheme = call_593345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593345.url(scheme.get, call_593345.host, call_593345.base,
                         call_593345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593345, url, valid)

proc call*(call_593346: Call_DeleteBucketMetricsConfiguration_593338;
          Bucket: string; metrics: bool; id: string): Recallable =
  ## deleteBucketMetricsConfiguration
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to delete.
  ##   metrics: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  var path_593347 = newJObject()
  var query_593348 = newJObject()
  add(path_593347, "Bucket", newJString(Bucket))
  add(query_593348, "metrics", newJBool(metrics))
  add(query_593348, "id", newJString(id))
  result = call_593346.call(path_593347, query_593348, nil, nil, nil)

var deleteBucketMetricsConfiguration* = Call_DeleteBucketMetricsConfiguration_593338(
    name: "deleteBucketMetricsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_DeleteBucketMetricsConfiguration_593339, base: "/",
    url: url_DeleteBucketMetricsConfiguration_593340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketPolicy_593359 = ref object of OpenApiRestCall_592364
proc url_PutBucketPolicy_593361(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketPolicy_593360(path: JsonNode; query: JsonNode;
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
  var valid_593362 = path.getOrDefault("Bucket")
  valid_593362 = validateParameter(valid_593362, JString, required = true,
                                 default = nil)
  if valid_593362 != nil:
    section.add "Bucket", valid_593362
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_593363 = query.getOrDefault("policy")
  valid_593363 = validateParameter(valid_593363, JBool, required = true, default = nil)
  if valid_593363 != nil:
    section.add "policy", valid_593363
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-confirm-remove-self-bucket-access: JBool
  ##                                          : Set this parameter to true to confirm that you want to remove your permissions to change this bucket policy in the future.
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_593364 = header.getOrDefault("x-amz-confirm-remove-self-bucket-access")
  valid_593364 = validateParameter(valid_593364, JBool, required = false, default = nil)
  if valid_593364 != nil:
    section.add "x-amz-confirm-remove-self-bucket-access", valid_593364
  var valid_593365 = header.getOrDefault("x-amz-security-token")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "x-amz-security-token", valid_593365
  var valid_593366 = header.getOrDefault("Content-MD5")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "Content-MD5", valid_593366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593368: Call_PutBucketPolicy_593359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  let valid = call_593368.validator(path, query, header, formData, body)
  let scheme = call_593368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593368.url(scheme.get, call_593368.host, call_593368.base,
                         call_593368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593368, url, valid)

proc call*(call_593369: Call_PutBucketPolicy_593359; Bucket: string; body: JsonNode;
          policy: bool): Recallable =
  ## putBucketPolicy
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   policy: bool (required)
  var path_593370 = newJObject()
  var query_593371 = newJObject()
  var body_593372 = newJObject()
  add(path_593370, "Bucket", newJString(Bucket))
  if body != nil:
    body_593372 = body
  add(query_593371, "policy", newJBool(policy))
  result = call_593369.call(path_593370, query_593371, nil, nil, body_593372)

var putBucketPolicy* = Call_PutBucketPolicy_593359(name: "putBucketPolicy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_PutBucketPolicy_593360, base: "/", url: url_PutBucketPolicy_593361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicy_593349 = ref object of OpenApiRestCall_592364
proc url_GetBucketPolicy_593351(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketPolicy_593350(path: JsonNode; query: JsonNode;
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
  var valid_593352 = path.getOrDefault("Bucket")
  valid_593352 = validateParameter(valid_593352, JString, required = true,
                                 default = nil)
  if valid_593352 != nil:
    section.add "Bucket", valid_593352
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_593353 = query.getOrDefault("policy")
  valid_593353 = validateParameter(valid_593353, JBool, required = true, default = nil)
  if valid_593353 != nil:
    section.add "policy", valid_593353
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593354 = header.getOrDefault("x-amz-security-token")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "x-amz-security-token", valid_593354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593355: Call_GetBucketPolicy_593349; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the policy of a specified bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  let valid = call_593355.validator(path, query, header, formData, body)
  let scheme = call_593355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593355.url(scheme.get, call_593355.host, call_593355.base,
                         call_593355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593355, url, valid)

proc call*(call_593356: Call_GetBucketPolicy_593349; Bucket: string; policy: bool): Recallable =
  ## getBucketPolicy
  ## Returns the policy of a specified bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   policy: bool (required)
  var path_593357 = newJObject()
  var query_593358 = newJObject()
  add(path_593357, "Bucket", newJString(Bucket))
  add(query_593358, "policy", newJBool(policy))
  result = call_593356.call(path_593357, query_593358, nil, nil, nil)

var getBucketPolicy* = Call_GetBucketPolicy_593349(name: "getBucketPolicy",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_GetBucketPolicy_593350, base: "/", url: url_GetBucketPolicy_593351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketPolicy_593373 = ref object of OpenApiRestCall_592364
proc url_DeleteBucketPolicy_593375(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketPolicy_593374(path: JsonNode; query: JsonNode;
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
  var valid_593376 = path.getOrDefault("Bucket")
  valid_593376 = validateParameter(valid_593376, JString, required = true,
                                 default = nil)
  if valid_593376 != nil:
    section.add "Bucket", valid_593376
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_593377 = query.getOrDefault("policy")
  valid_593377 = validateParameter(valid_593377, JBool, required = true, default = nil)
  if valid_593377 != nil:
    section.add "policy", valid_593377
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593378 = header.getOrDefault("x-amz-security-token")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "x-amz-security-token", valid_593378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593379: Call_DeleteBucketPolicy_593373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  let valid = call_593379.validator(path, query, header, formData, body)
  let scheme = call_593379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593379.url(scheme.get, call_593379.host, call_593379.base,
                         call_593379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593379, url, valid)

proc call*(call_593380: Call_DeleteBucketPolicy_593373; Bucket: string; policy: bool): Recallable =
  ## deleteBucketPolicy
  ## Deletes the policy from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   policy: bool (required)
  var path_593381 = newJObject()
  var query_593382 = newJObject()
  add(path_593381, "Bucket", newJString(Bucket))
  add(query_593382, "policy", newJBool(policy))
  result = call_593380.call(path_593381, query_593382, nil, nil, nil)

var deleteBucketPolicy* = Call_DeleteBucketPolicy_593373(
    name: "deleteBucketPolicy", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_DeleteBucketPolicy_593374, base: "/",
    url: url_DeleteBucketPolicy_593375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketReplication_593393 = ref object of OpenApiRestCall_592364
proc url_PutBucketReplication_593395(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketReplication_593394(path: JsonNode; query: JsonNode;
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
  var valid_593396 = path.getOrDefault("Bucket")
  valid_593396 = validateParameter(valid_593396, JString, required = true,
                                 default = nil)
  if valid_593396 != nil:
    section.add "Bucket", valid_593396
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_593397 = query.getOrDefault("replication")
  valid_593397 = validateParameter(valid_593397, JBool, required = true, default = nil)
  if valid_593397 != nil:
    section.add "replication", valid_593397
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-bucket-object-lock-token: JString
  ##                                 : A token that allows Amazon S3 object lock to be enabled for an existing bucket.
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit.
  section = newJObject()
  var valid_593398 = header.getOrDefault("x-amz-security-token")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "x-amz-security-token", valid_593398
  var valid_593399 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_593399
  var valid_593400 = header.getOrDefault("Content-MD5")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "Content-MD5", valid_593400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593402: Call_PutBucketReplication_593393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_593402.validator(path, query, header, formData, body)
  let scheme = call_593402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593402.url(scheme.get, call_593402.host, call_593402.base,
                         call_593402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593402, url, valid)

proc call*(call_593403: Call_PutBucketReplication_593393; Bucket: string;
          replication: bool; body: JsonNode): Recallable =
  ## putBucketReplication
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   Bucket: string (required)
  ##         : <p/>
  ##   replication: bool (required)
  ##   body: JObject (required)
  var path_593404 = newJObject()
  var query_593405 = newJObject()
  var body_593406 = newJObject()
  add(path_593404, "Bucket", newJString(Bucket))
  add(query_593405, "replication", newJBool(replication))
  if body != nil:
    body_593406 = body
  result = call_593403.call(path_593404, query_593405, nil, nil, body_593406)

var putBucketReplication* = Call_PutBucketReplication_593393(
    name: "putBucketReplication", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_PutBucketReplication_593394, base: "/",
    url: url_PutBucketReplication_593395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketReplication_593383 = ref object of OpenApiRestCall_592364
proc url_GetBucketReplication_593385(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketReplication_593384(path: JsonNode; query: JsonNode;
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
  var valid_593386 = path.getOrDefault("Bucket")
  valid_593386 = validateParameter(valid_593386, JString, required = true,
                                 default = nil)
  if valid_593386 != nil:
    section.add "Bucket", valid_593386
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_593387 = query.getOrDefault("replication")
  valid_593387 = validateParameter(valid_593387, JBool, required = true, default = nil)
  if valid_593387 != nil:
    section.add "replication", valid_593387
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593388 = header.getOrDefault("x-amz-security-token")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "x-amz-security-token", valid_593388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593389: Call_GetBucketReplication_593383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ## 
  let valid = call_593389.validator(path, query, header, formData, body)
  let scheme = call_593389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593389.url(scheme.get, call_593389.host, call_593389.base,
                         call_593389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593389, url, valid)

proc call*(call_593390: Call_GetBucketReplication_593383; Bucket: string;
          replication: bool): Recallable =
  ## getBucketReplication
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ##   Bucket: string (required)
  ##         : <p/>
  ##   replication: bool (required)
  var path_593391 = newJObject()
  var query_593392 = newJObject()
  add(path_593391, "Bucket", newJString(Bucket))
  add(query_593392, "replication", newJBool(replication))
  result = call_593390.call(path_593391, query_593392, nil, nil, nil)

var getBucketReplication* = Call_GetBucketReplication_593383(
    name: "getBucketReplication", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_GetBucketReplication_593384, base: "/",
    url: url_GetBucketReplication_593385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketReplication_593407 = ref object of OpenApiRestCall_592364
proc url_DeleteBucketReplication_593409(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketReplication_593408(path: JsonNode; query: JsonNode;
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
  var valid_593410 = path.getOrDefault("Bucket")
  valid_593410 = validateParameter(valid_593410, JString, required = true,
                                 default = nil)
  if valid_593410 != nil:
    section.add "Bucket", valid_593410
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_593411 = query.getOrDefault("replication")
  valid_593411 = validateParameter(valid_593411, JBool, required = true, default = nil)
  if valid_593411 != nil:
    section.add "replication", valid_593411
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593412 = header.getOrDefault("x-amz-security-token")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "x-amz-security-token", valid_593412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593413: Call_DeleteBucketReplication_593407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_593413.validator(path, query, header, formData, body)
  let scheme = call_593413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593413.url(scheme.get, call_593413.host, call_593413.base,
                         call_593413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593413, url, valid)

proc call*(call_593414: Call_DeleteBucketReplication_593407; Bucket: string;
          replication: bool): Recallable =
  ## deleteBucketReplication
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   Bucket: string (required)
  ##         : <p> The bucket name. </p> <note> <p>It can take a while to propagate the deletion of a replication configuration to all Amazon S3 systems.</p> </note>
  ##   replication: bool (required)
  var path_593415 = newJObject()
  var query_593416 = newJObject()
  add(path_593415, "Bucket", newJString(Bucket))
  add(query_593416, "replication", newJBool(replication))
  result = call_593414.call(path_593415, query_593416, nil, nil, nil)

var deleteBucketReplication* = Call_DeleteBucketReplication_593407(
    name: "deleteBucketReplication", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_DeleteBucketReplication_593408, base: "/",
    url: url_DeleteBucketReplication_593409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketTagging_593427 = ref object of OpenApiRestCall_592364
proc url_PutBucketTagging_593429(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketTagging_593428(path: JsonNode; query: JsonNode;
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
  var valid_593430 = path.getOrDefault("Bucket")
  valid_593430 = validateParameter(valid_593430, JString, required = true,
                                 default = nil)
  if valid_593430 != nil:
    section.add "Bucket", valid_593430
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_593431 = query.getOrDefault("tagging")
  valid_593431 = validateParameter(valid_593431, JBool, required = true, default = nil)
  if valid_593431 != nil:
    section.add "tagging", valid_593431
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_593432 = header.getOrDefault("x-amz-security-token")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "x-amz-security-token", valid_593432
  var valid_593433 = header.getOrDefault("Content-MD5")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "Content-MD5", valid_593433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593435: Call_PutBucketTagging_593427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the tags for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  let valid = call_593435.validator(path, query, header, formData, body)
  let scheme = call_593435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593435.url(scheme.get, call_593435.host, call_593435.base,
                         call_593435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593435, url, valid)

proc call*(call_593436: Call_PutBucketTagging_593427; tagging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketTagging
  ## Sets the tags for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_593437 = newJObject()
  var query_593438 = newJObject()
  var body_593439 = newJObject()
  add(query_593438, "tagging", newJBool(tagging))
  add(path_593437, "Bucket", newJString(Bucket))
  if body != nil:
    body_593439 = body
  result = call_593436.call(path_593437, query_593438, nil, nil, body_593439)

var putBucketTagging* = Call_PutBucketTagging_593427(name: "putBucketTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_PutBucketTagging_593428, base: "/",
    url: url_PutBucketTagging_593429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketTagging_593417 = ref object of OpenApiRestCall_592364
proc url_GetBucketTagging_593419(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketTagging_593418(path: JsonNode; query: JsonNode;
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
  var valid_593420 = path.getOrDefault("Bucket")
  valid_593420 = validateParameter(valid_593420, JString, required = true,
                                 default = nil)
  if valid_593420 != nil:
    section.add "Bucket", valid_593420
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_593421 = query.getOrDefault("tagging")
  valid_593421 = validateParameter(valid_593421, JBool, required = true, default = nil)
  if valid_593421 != nil:
    section.add "tagging", valid_593421
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593422 = header.getOrDefault("x-amz-security-token")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "x-amz-security-token", valid_593422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593423: Call_GetBucketTagging_593417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag set associated with the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  let valid = call_593423.validator(path, query, header, formData, body)
  let scheme = call_593423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593423.url(scheme.get, call_593423.host, call_593423.base,
                         call_593423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593423, url, valid)

proc call*(call_593424: Call_GetBucketTagging_593417; tagging: bool; Bucket: string): Recallable =
  ## getBucketTagging
  ## Returns the tag set associated with the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_593425 = newJObject()
  var query_593426 = newJObject()
  add(query_593426, "tagging", newJBool(tagging))
  add(path_593425, "Bucket", newJString(Bucket))
  result = call_593424.call(path_593425, query_593426, nil, nil, nil)

var getBucketTagging* = Call_GetBucketTagging_593417(name: "getBucketTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_GetBucketTagging_593418, base: "/",
    url: url_GetBucketTagging_593419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketTagging_593440 = ref object of OpenApiRestCall_592364
proc url_DeleteBucketTagging_593442(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketTagging_593441(path: JsonNode; query: JsonNode;
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
  var valid_593443 = path.getOrDefault("Bucket")
  valid_593443 = validateParameter(valid_593443, JString, required = true,
                                 default = nil)
  if valid_593443 != nil:
    section.add "Bucket", valid_593443
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_593444 = query.getOrDefault("tagging")
  valid_593444 = validateParameter(valid_593444, JBool, required = true, default = nil)
  if valid_593444 != nil:
    section.add "tagging", valid_593444
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593445 = header.getOrDefault("x-amz-security-token")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "x-amz-security-token", valid_593445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593446: Call_DeleteBucketTagging_593440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the tags from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  let valid = call_593446.validator(path, query, header, formData, body)
  let scheme = call_593446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593446.url(scheme.get, call_593446.host, call_593446.base,
                         call_593446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593446, url, valid)

proc call*(call_593447: Call_DeleteBucketTagging_593440; tagging: bool;
          Bucket: string): Recallable =
  ## deleteBucketTagging
  ## Deletes the tags from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_593448 = newJObject()
  var query_593449 = newJObject()
  add(query_593449, "tagging", newJBool(tagging))
  add(path_593448, "Bucket", newJString(Bucket))
  result = call_593447.call(path_593448, query_593449, nil, nil, nil)

var deleteBucketTagging* = Call_DeleteBucketTagging_593440(
    name: "deleteBucketTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_DeleteBucketTagging_593441, base: "/",
    url: url_DeleteBucketTagging_593442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketWebsite_593460 = ref object of OpenApiRestCall_592364
proc url_PutBucketWebsite_593462(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketWebsite_593461(path: JsonNode; query: JsonNode;
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
  var valid_593463 = path.getOrDefault("Bucket")
  valid_593463 = validateParameter(valid_593463, JString, required = true,
                                 default = nil)
  if valid_593463 != nil:
    section.add "Bucket", valid_593463
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_593464 = query.getOrDefault("website")
  valid_593464 = validateParameter(valid_593464, JBool, required = true, default = nil)
  if valid_593464 != nil:
    section.add "website", valid_593464
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_593465 = header.getOrDefault("x-amz-security-token")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "x-amz-security-token", valid_593465
  var valid_593466 = header.getOrDefault("Content-MD5")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "Content-MD5", valid_593466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593468: Call_PutBucketWebsite_593460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  let valid = call_593468.validator(path, query, header, formData, body)
  let scheme = call_593468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593468.url(scheme.get, call_593468.host, call_593468.base,
                         call_593468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593468, url, valid)

proc call*(call_593469: Call_PutBucketWebsite_593460; Bucket: string; website: bool;
          body: JsonNode): Recallable =
  ## putBucketWebsite
  ## Set the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   website: bool (required)
  ##   body: JObject (required)
  var path_593470 = newJObject()
  var query_593471 = newJObject()
  var body_593472 = newJObject()
  add(path_593470, "Bucket", newJString(Bucket))
  add(query_593471, "website", newJBool(website))
  if body != nil:
    body_593472 = body
  result = call_593469.call(path_593470, query_593471, nil, nil, body_593472)

var putBucketWebsite* = Call_PutBucketWebsite_593460(name: "putBucketWebsite",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_PutBucketWebsite_593461, base: "/",
    url: url_PutBucketWebsite_593462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketWebsite_593450 = ref object of OpenApiRestCall_592364
proc url_GetBucketWebsite_593452(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketWebsite_593451(path: JsonNode; query: JsonNode;
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
  var valid_593453 = path.getOrDefault("Bucket")
  valid_593453 = validateParameter(valid_593453, JString, required = true,
                                 default = nil)
  if valid_593453 != nil:
    section.add "Bucket", valid_593453
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_593454 = query.getOrDefault("website")
  valid_593454 = validateParameter(valid_593454, JBool, required = true, default = nil)
  if valid_593454 != nil:
    section.add "website", valid_593454
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593455 = header.getOrDefault("x-amz-security-token")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "x-amz-security-token", valid_593455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593456: Call_GetBucketWebsite_593450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  let valid = call_593456.validator(path, query, header, formData, body)
  let scheme = call_593456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593456.url(scheme.get, call_593456.host, call_593456.base,
                         call_593456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593456, url, valid)

proc call*(call_593457: Call_GetBucketWebsite_593450; Bucket: string; website: bool): Recallable =
  ## getBucketWebsite
  ## Returns the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   website: bool (required)
  var path_593458 = newJObject()
  var query_593459 = newJObject()
  add(path_593458, "Bucket", newJString(Bucket))
  add(query_593459, "website", newJBool(website))
  result = call_593457.call(path_593458, query_593459, nil, nil, nil)

var getBucketWebsite* = Call_GetBucketWebsite_593450(name: "getBucketWebsite",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_GetBucketWebsite_593451, base: "/",
    url: url_GetBucketWebsite_593452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketWebsite_593473 = ref object of OpenApiRestCall_592364
proc url_DeleteBucketWebsite_593475(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketWebsite_593474(path: JsonNode; query: JsonNode;
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
  var valid_593476 = path.getOrDefault("Bucket")
  valid_593476 = validateParameter(valid_593476, JString, required = true,
                                 default = nil)
  if valid_593476 != nil:
    section.add "Bucket", valid_593476
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_593477 = query.getOrDefault("website")
  valid_593477 = validateParameter(valid_593477, JBool, required = true, default = nil)
  if valid_593477 != nil:
    section.add "website", valid_593477
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593478 = header.getOrDefault("x-amz-security-token")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "x-amz-security-token", valid_593478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593479: Call_DeleteBucketWebsite_593473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes the website configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  let valid = call_593479.validator(path, query, header, formData, body)
  let scheme = call_593479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593479.url(scheme.get, call_593479.host, call_593479.base,
                         call_593479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593479, url, valid)

proc call*(call_593480: Call_DeleteBucketWebsite_593473; Bucket: string;
          website: bool): Recallable =
  ## deleteBucketWebsite
  ## This operation removes the website configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   website: bool (required)
  var path_593481 = newJObject()
  var query_593482 = newJObject()
  add(path_593481, "Bucket", newJString(Bucket))
  add(query_593482, "website", newJBool(website))
  result = call_593480.call(path_593481, query_593482, nil, nil, nil)

var deleteBucketWebsite* = Call_DeleteBucketWebsite_593473(
    name: "deleteBucketWebsite", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_DeleteBucketWebsite_593474, base: "/",
    url: url_DeleteBucketWebsite_593475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObject_593510 = ref object of OpenApiRestCall_592364
proc url_PutObject_593512(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutObject_593511(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds an object to a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : Name of the bucket to which the PUT operation was initiated.
  ##   Key: JString (required)
  ##      : Object key for which the PUT operation was initiated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593513 = path.getOrDefault("Bucket")
  valid_593513 = validateParameter(valid_593513, JString, required = true,
                                 default = nil)
  if valid_593513 != nil:
    section.add "Bucket", valid_593513
  var valid_593514 = path.getOrDefault("Key")
  valid_593514 = validateParameter(valid_593514, JString, required = true,
                                 default = nil)
  if valid_593514 != nil:
    section.add "Key", valid_593514
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Cache-Control: JString
  ##                : Specifies caching behavior along the request/reply chain.
  ##   x-amz-storage-class: JString
  ##                      : The type of storage to use for the object. Defaults to 'STANDARD'.
  ##   x-amz-object-lock-retain-until-date: JString
  ##                                      : The date and time when you want this object's object lock to expire.
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-server-side-encryption: JString
  ##                               : The Server-side encryption algorithm used when storing this object in S3 (e.g., AES256, aws:kms).
  ##   x-amz-tagging: JString
  ##                : The tag-set for the object. The tag-set must be encoded as URL Query parameters. (For example, "Key1=Value1")
  ##   Content-Length: JInt
  ##                 : Size of the body in bytes. This parameter is useful when the size of the body cannot be determined automatically.
  ##   x-amz-object-lock-mode: JString
  ##                         : The object lock mode that you want to apply to this object.
  ##   x-amz-security-token: JString
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the object ACL.
  ##   x-amz-object-lock-legal-hold: JString
  ##                               : The Legal Hold status that you want to apply to the specified object.
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the object.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable object.
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header.
  ##   x-amz-server-side-encryption-context: JString
  ##                                       : Specifies the AWS KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs.
  ##   Content-Disposition: JString
  ##                      : Specifies presentational information for the object.
  ##   Content-Encoding: JString
  ##                   : Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the part data. This parameter is auto-populated when using the command from the CLI. This parameted is required if object lock parameters are specified.
  ##   x-amz-grant-full-control: JString
  ##                           : Gives the grantee READ, READ_ACP, and WRITE_ACP permissions on the object.
  ##   x-amz-website-redirect-location: JString
  ##                                  : If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata.
  ##   Content-Language: JString
  ##                   : The language the content is in.
  ##   Content-Type: JString
  ##               : A standard MIME type describing the format of the object data.
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  ##   x-amz-server-side-encryption-aws-kms-key-id: JString
  ##                                              : Specifies the AWS KMS key ID to use for object encryption. All GET and PUT requests for an object protected by AWS KMS will fail if not made via SSL or using SigV4. Documentation on configuring any of the officially supported AWS SDKs and CLI can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
  ##   Expires: JString
  ##          : The date and time at which the object is no longer cacheable.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to read the object data and its metadata.
  section = newJObject()
  var valid_593515 = header.getOrDefault("Cache-Control")
  valid_593515 = validateParameter(valid_593515, JString, required = false,
                                 default = nil)
  if valid_593515 != nil:
    section.add "Cache-Control", valid_593515
  var valid_593516 = header.getOrDefault("x-amz-storage-class")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_593516 != nil:
    section.add "x-amz-storage-class", valid_593516
  var valid_593517 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_593517
  var valid_593518 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_593518
  var valid_593519 = header.getOrDefault("x-amz-server-side-encryption")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = newJString("AES256"))
  if valid_593519 != nil:
    section.add "x-amz-server-side-encryption", valid_593519
  var valid_593520 = header.getOrDefault("x-amz-tagging")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "x-amz-tagging", valid_593520
  var valid_593521 = header.getOrDefault("Content-Length")
  valid_593521 = validateParameter(valid_593521, JInt, required = false, default = nil)
  if valid_593521 != nil:
    section.add "Content-Length", valid_593521
  var valid_593522 = header.getOrDefault("x-amz-object-lock-mode")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_593522 != nil:
    section.add "x-amz-object-lock-mode", valid_593522
  var valid_593523 = header.getOrDefault("x-amz-security-token")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "x-amz-security-token", valid_593523
  var valid_593524 = header.getOrDefault("x-amz-grant-read-acp")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "x-amz-grant-read-acp", valid_593524
  var valid_593525 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = newJString("ON"))
  if valid_593525 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_593525
  var valid_593526 = header.getOrDefault("x-amz-acl")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = newJString("private"))
  if valid_593526 != nil:
    section.add "x-amz-acl", valid_593526
  var valid_593527 = header.getOrDefault("x-amz-grant-write-acp")
  valid_593527 = validateParameter(valid_593527, JString, required = false,
                                 default = nil)
  if valid_593527 != nil:
    section.add "x-amz-grant-write-acp", valid_593527
  var valid_593528 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_593528 = validateParameter(valid_593528, JString, required = false,
                                 default = nil)
  if valid_593528 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_593528
  var valid_593529 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_593529 = validateParameter(valid_593529, JString, required = false,
                                 default = nil)
  if valid_593529 != nil:
    section.add "x-amz-server-side-encryption-context", valid_593529
  var valid_593530 = header.getOrDefault("Content-Disposition")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "Content-Disposition", valid_593530
  var valid_593531 = header.getOrDefault("Content-Encoding")
  valid_593531 = validateParameter(valid_593531, JString, required = false,
                                 default = nil)
  if valid_593531 != nil:
    section.add "Content-Encoding", valid_593531
  var valid_593532 = header.getOrDefault("x-amz-request-payer")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = newJString("requester"))
  if valid_593532 != nil:
    section.add "x-amz-request-payer", valid_593532
  var valid_593533 = header.getOrDefault("Content-MD5")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "Content-MD5", valid_593533
  var valid_593534 = header.getOrDefault("x-amz-grant-full-control")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "x-amz-grant-full-control", valid_593534
  var valid_593535 = header.getOrDefault("x-amz-website-redirect-location")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "x-amz-website-redirect-location", valid_593535
  var valid_593536 = header.getOrDefault("Content-Language")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "Content-Language", valid_593536
  var valid_593537 = header.getOrDefault("Content-Type")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "Content-Type", valid_593537
  var valid_593538 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_593538
  var valid_593539 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_593539 = validateParameter(valid_593539, JString, required = false,
                                 default = nil)
  if valid_593539 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_593539
  var valid_593540 = header.getOrDefault("Expires")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "Expires", valid_593540
  var valid_593541 = header.getOrDefault("x-amz-grant-read")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "x-amz-grant-read", valid_593541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593543: Call_PutObject_593510; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an object to a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  let valid = call_593543.validator(path, query, header, formData, body)
  let scheme = call_593543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593543.url(scheme.get, call_593543.host, call_593543.base,
                         call_593543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593543, url, valid)

proc call*(call_593544: Call_PutObject_593510; Bucket: string; Key: string;
          body: JsonNode): Recallable =
  ## putObject
  ## Adds an object to a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the PUT operation was initiated.
  ##   Key: string (required)
  ##      : Object key for which the PUT operation was initiated.
  ##   body: JObject (required)
  var path_593545 = newJObject()
  var body_593546 = newJObject()
  add(path_593545, "Bucket", newJString(Bucket))
  add(path_593545, "Key", newJString(Key))
  if body != nil:
    body_593546 = body
  result = call_593544.call(path_593545, nil, nil, nil, body_593546)

var putObject* = Call_PutObject_593510(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_PutObject_593511,
                                    base: "/", url: url_PutObject_593512,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadObject_593561 = ref object of OpenApiRestCall_592364
proc url_HeadObject_593563(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_HeadObject_593562(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593564 = path.getOrDefault("Bucket")
  valid_593564 = validateParameter(valid_593564, JString, required = true,
                                 default = nil)
  if valid_593564 != nil:
    section.add "Bucket", valid_593564
  var valid_593565 = path.getOrDefault("Key")
  valid_593565 = validateParameter(valid_593565, JString, required = true,
                                 default = nil)
  if valid_593565 != nil:
    section.add "Key", valid_593565
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   partNumber: JInt
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
  section = newJObject()
  var valid_593566 = query.getOrDefault("versionId")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "versionId", valid_593566
  var valid_593567 = query.getOrDefault("partNumber")
  valid_593567 = validateParameter(valid_593567, JInt, required = false, default = nil)
  if valid_593567 != nil:
    section.add "partNumber", valid_593567
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-security-token: JString
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header.
  ##   If-Unmodified-Since: JString
  ##                      : Return the object only if it has not been modified since the specified time, otherwise return a 412 (precondition failed).
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   If-Modified-Since: JString
  ##                    : Return the object only if it has been modified since the specified time, otherwise return a 304 (not modified).
  ##   Range: JString
  ##        : Downloads the specified range bytes of an object. For more information about the HTTP Range header, go to http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.
  ##   If-None-Match: JString
  ##                : Return the object only if its entity tag (ETag) is different from the one specified, otherwise return a 304 (not modified).
  ##   If-Match: JString
  ##           : Return the object only if its entity tag (ETag) is the same as the one specified, otherwise return a 412 (precondition failed).
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  section = newJObject()
  var valid_593568 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_593568
  var valid_593569 = header.getOrDefault("x-amz-security-token")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "x-amz-security-token", valid_593569
  var valid_593570 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_593570
  var valid_593571 = header.getOrDefault("If-Unmodified-Since")
  valid_593571 = validateParameter(valid_593571, JString, required = false,
                                 default = nil)
  if valid_593571 != nil:
    section.add "If-Unmodified-Since", valid_593571
  var valid_593572 = header.getOrDefault("x-amz-request-payer")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = newJString("requester"))
  if valid_593572 != nil:
    section.add "x-amz-request-payer", valid_593572
  var valid_593573 = header.getOrDefault("If-Modified-Since")
  valid_593573 = validateParameter(valid_593573, JString, required = false,
                                 default = nil)
  if valid_593573 != nil:
    section.add "If-Modified-Since", valid_593573
  var valid_593574 = header.getOrDefault("Range")
  valid_593574 = validateParameter(valid_593574, JString, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "Range", valid_593574
  var valid_593575 = header.getOrDefault("If-None-Match")
  valid_593575 = validateParameter(valid_593575, JString, required = false,
                                 default = nil)
  if valid_593575 != nil:
    section.add "If-None-Match", valid_593575
  var valid_593576 = header.getOrDefault("If-Match")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "If-Match", valid_593576
  var valid_593577 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_593577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593578: Call_HeadObject_593561; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  let valid = call_593578.validator(path, query, header, formData, body)
  let scheme = call_593578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593578.url(scheme.get, call_593578.host, call_593578.base,
                         call_593578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593578, url, valid)

proc call*(call_593579: Call_HeadObject_593561; Bucket: string; Key: string;
          versionId: string = ""; partNumber: int = 0): Recallable =
  ## headObject
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versionId: string
  ##            : VersionId used to reference a specific version of the object.
  ##   Key: string (required)
  ##      : <p/>
  ##   partNumber: int
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
  var path_593580 = newJObject()
  var query_593581 = newJObject()
  add(path_593580, "Bucket", newJString(Bucket))
  add(query_593581, "versionId", newJString(versionId))
  add(path_593580, "Key", newJString(Key))
  add(query_593581, "partNumber", newJInt(partNumber))
  result = call_593579.call(path_593580, query_593581, nil, nil, nil)

var headObject* = Call_HeadObject_593561(name: "headObject",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}/{Key}",
                                      validator: validate_HeadObject_593562,
                                      base: "/", url: url_HeadObject_593563,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_593483 = ref object of OpenApiRestCall_592364
proc url_GetObject_593485(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetObject_593484(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves objects from Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593486 = path.getOrDefault("Bucket")
  valid_593486 = validateParameter(valid_593486, JString, required = true,
                                 default = nil)
  if valid_593486 != nil:
    section.add "Bucket", valid_593486
  var valid_593487 = path.getOrDefault("Key")
  valid_593487 = validateParameter(valid_593487, JString, required = true,
                                 default = nil)
  if valid_593487 != nil:
    section.add "Key", valid_593487
  result.add "path", section
  ## parameters in `query` object:
  ##   response-expires: JString
  ##                   : Sets the Expires header of the response.
  ##   response-content-type: JString
  ##                        : Sets the Content-Type header of the response.
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   response-content-encoding: JString
  ##                            : Sets the Content-Encoding header of the response.
  ##   response-content-language: JString
  ##                            : Sets the Content-Language header of the response.
  ##   response-cache-control: JString
  ##                         : Sets the Cache-Control header of the response.
  ##   partNumber: JInt
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' GET request for the part specified. Useful for downloading just a part of an object.
  ##   response-content-disposition: JString
  ##                               : Sets the Content-Disposition header of the response
  section = newJObject()
  var valid_593488 = query.getOrDefault("response-expires")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "response-expires", valid_593488
  var valid_593489 = query.getOrDefault("response-content-type")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "response-content-type", valid_593489
  var valid_593490 = query.getOrDefault("versionId")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "versionId", valid_593490
  var valid_593491 = query.getOrDefault("response-content-encoding")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "response-content-encoding", valid_593491
  var valid_593492 = query.getOrDefault("response-content-language")
  valid_593492 = validateParameter(valid_593492, JString, required = false,
                                 default = nil)
  if valid_593492 != nil:
    section.add "response-content-language", valid_593492
  var valid_593493 = query.getOrDefault("response-cache-control")
  valid_593493 = validateParameter(valid_593493, JString, required = false,
                                 default = nil)
  if valid_593493 != nil:
    section.add "response-cache-control", valid_593493
  var valid_593494 = query.getOrDefault("partNumber")
  valid_593494 = validateParameter(valid_593494, JInt, required = false, default = nil)
  if valid_593494 != nil:
    section.add "partNumber", valid_593494
  var valid_593495 = query.getOrDefault("response-content-disposition")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "response-content-disposition", valid_593495
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-security-token: JString
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header.
  ##   If-Unmodified-Since: JString
  ##                      : Return the object only if it has not been modified since the specified time, otherwise return a 412 (precondition failed).
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   If-Modified-Since: JString
  ##                    : Return the object only if it has been modified since the specified time, otherwise return a 304 (not modified).
  ##   Range: JString
  ##        : Downloads the specified range bytes of an object. For more information about the HTTP Range header, go to http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.
  ##   If-None-Match: JString
  ##                : Return the object only if its entity tag (ETag) is different from the one specified, otherwise return a 304 (not modified).
  ##   If-Match: JString
  ##           : Return the object only if its entity tag (ETag) is the same as the one specified, otherwise return a 412 (precondition failed).
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  section = newJObject()
  var valid_593496 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_593496
  var valid_593497 = header.getOrDefault("x-amz-security-token")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "x-amz-security-token", valid_593497
  var valid_593498 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_593498
  var valid_593499 = header.getOrDefault("If-Unmodified-Since")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "If-Unmodified-Since", valid_593499
  var valid_593500 = header.getOrDefault("x-amz-request-payer")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = newJString("requester"))
  if valid_593500 != nil:
    section.add "x-amz-request-payer", valid_593500
  var valid_593501 = header.getOrDefault("If-Modified-Since")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "If-Modified-Since", valid_593501
  var valid_593502 = header.getOrDefault("Range")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "Range", valid_593502
  var valid_593503 = header.getOrDefault("If-None-Match")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "If-None-Match", valid_593503
  var valid_593504 = header.getOrDefault("If-Match")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "If-Match", valid_593504
  var valid_593505 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_593505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593506: Call_GetObject_593483; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves objects from Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  let valid = call_593506.validator(path, query, header, formData, body)
  let scheme = call_593506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593506.url(scheme.get, call_593506.host, call_593506.base,
                         call_593506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593506, url, valid)

proc call*(call_593507: Call_GetObject_593483; Bucket: string; Key: string;
          responseExpires: string = ""; responseContentType: string = "";
          versionId: string = ""; responseContentEncoding: string = "";
          responseContentLanguage: string = ""; responseCacheControl: string = "";
          partNumber: int = 0; responseContentDisposition: string = ""): Recallable =
  ## getObject
  ## Retrieves objects from Amazon S3.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   responseExpires: string
  ##                  : Sets the Expires header of the response.
  ##   responseContentType: string
  ##                      : Sets the Content-Type header of the response.
  ##   versionId: string
  ##            : VersionId used to reference a specific version of the object.
  ##   responseContentEncoding: string
  ##                          : Sets the Content-Encoding header of the response.
  ##   responseContentLanguage: string
  ##                          : Sets the Content-Language header of the response.
  ##   responseCacheControl: string
  ##                       : Sets the Cache-Control header of the response.
  ##   Key: string (required)
  ##      : <p/>
  ##   partNumber: int
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' GET request for the part specified. Useful for downloading just a part of an object.
  ##   responseContentDisposition: string
  ##                             : Sets the Content-Disposition header of the response
  var path_593508 = newJObject()
  var query_593509 = newJObject()
  add(path_593508, "Bucket", newJString(Bucket))
  add(query_593509, "response-expires", newJString(responseExpires))
  add(query_593509, "response-content-type", newJString(responseContentType))
  add(query_593509, "versionId", newJString(versionId))
  add(query_593509, "response-content-encoding",
      newJString(responseContentEncoding))
  add(query_593509, "response-content-language",
      newJString(responseContentLanguage))
  add(query_593509, "response-cache-control", newJString(responseCacheControl))
  add(path_593508, "Key", newJString(Key))
  add(query_593509, "partNumber", newJInt(partNumber))
  add(query_593509, "response-content-disposition",
      newJString(responseContentDisposition))
  result = call_593507.call(path_593508, query_593509, nil, nil, nil)

var getObject* = Call_GetObject_593483(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_GetObject_593484,
                                    base: "/", url: url_GetObject_593485,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_593547 = ref object of OpenApiRestCall_592364
proc url_DeleteObject_593549(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObject_593548(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593550 = path.getOrDefault("Bucket")
  valid_593550 = validateParameter(valid_593550, JString, required = true,
                                 default = nil)
  if valid_593550 != nil:
    section.add "Bucket", valid_593550
  var valid_593551 = path.getOrDefault("Key")
  valid_593551 = validateParameter(valid_593551, JString, required = true,
                                 default = nil)
  if valid_593551 != nil:
    section.add "Key", valid_593551
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  var valid_593552 = query.getOrDefault("versionId")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "versionId", valid_593552
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-bypass-governance-retention: JBool
  ##                                    : Indicates whether Amazon S3 object lock should bypass governance-mode restrictions to process this operation.
  ##   x-amz-security-token: JString
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_593553 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_593553 = validateParameter(valid_593553, JBool, required = false, default = nil)
  if valid_593553 != nil:
    section.add "x-amz-bypass-governance-retention", valid_593553
  var valid_593554 = header.getOrDefault("x-amz-security-token")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "x-amz-security-token", valid_593554
  var valid_593555 = header.getOrDefault("x-amz-mfa")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "x-amz-mfa", valid_593555
  var valid_593556 = header.getOrDefault("x-amz-request-payer")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = newJString("requester"))
  if valid_593556 != nil:
    section.add "x-amz-request-payer", valid_593556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593557: Call_DeleteObject_593547; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  let valid = call_593557.validator(path, query, header, formData, body)
  let scheme = call_593557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593557.url(scheme.get, call_593557.host, call_593557.base,
                         call_593557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593557, url, valid)

proc call*(call_593558: Call_DeleteObject_593547; Bucket: string; Key: string;
          versionId: string = ""): Recallable =
  ## deleteObject
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versionId: string
  ##            : VersionId used to reference a specific version of the object.
  ##   Key: string (required)
  ##      : <p/>
  var path_593559 = newJObject()
  var query_593560 = newJObject()
  add(path_593559, "Bucket", newJString(Bucket))
  add(query_593560, "versionId", newJString(versionId))
  add(path_593559, "Key", newJString(Key))
  result = call_593558.call(path_593559, query_593560, nil, nil, nil)

var deleteObject* = Call_DeleteObject_593547(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}/{Key}",
    validator: validate_DeleteObject_593548, base: "/", url: url_DeleteObject_593549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectTagging_593594 = ref object of OpenApiRestCall_592364
proc url_PutObjectTagging_593596(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectTagging_593595(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593597 = path.getOrDefault("Bucket")
  valid_593597 = validateParameter(valid_593597, JString, required = true,
                                 default = nil)
  if valid_593597 != nil:
    section.add "Bucket", valid_593597
  var valid_593598 = path.getOrDefault("Key")
  valid_593598 = validateParameter(valid_593598, JString, required = true,
                                 default = nil)
  if valid_593598 != nil:
    section.add "Key", valid_593598
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  ##   versionId: JString
  ##            : <p/>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_593599 = query.getOrDefault("tagging")
  valid_593599 = validateParameter(valid_593599, JBool, required = true, default = nil)
  if valid_593599 != nil:
    section.add "tagging", valid_593599
  var valid_593600 = query.getOrDefault("versionId")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "versionId", valid_593600
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_593601 = header.getOrDefault("x-amz-security-token")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "x-amz-security-token", valid_593601
  var valid_593602 = header.getOrDefault("Content-MD5")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "Content-MD5", valid_593602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593604: Call_PutObjectTagging_593594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ## 
  let valid = call_593604.validator(path, query, header, formData, body)
  let scheme = call_593604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593604.url(scheme.get, call_593604.host, call_593604.base,
                         call_593604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593604, url, valid)

proc call*(call_593605: Call_PutObjectTagging_593594; tagging: bool; Bucket: string;
          Key: string; body: JsonNode; versionId: string = ""): Recallable =
  ## putObjectTagging
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versionId: string
  ##            : <p/>
  ##   Key: string (required)
  ##      : <p/>
  ##   body: JObject (required)
  var path_593606 = newJObject()
  var query_593607 = newJObject()
  var body_593608 = newJObject()
  add(query_593607, "tagging", newJBool(tagging))
  add(path_593606, "Bucket", newJString(Bucket))
  add(query_593607, "versionId", newJString(versionId))
  add(path_593606, "Key", newJString(Key))
  if body != nil:
    body_593608 = body
  result = call_593605.call(path_593606, query_593607, nil, nil, body_593608)

var putObjectTagging* = Call_PutObjectTagging_593594(name: "putObjectTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_PutObjectTagging_593595,
    base: "/", url: url_PutObjectTagging_593596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTagging_593582 = ref object of OpenApiRestCall_592364
proc url_GetObjectTagging_593584(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectTagging_593583(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the tag-set of an object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593585 = path.getOrDefault("Bucket")
  valid_593585 = validateParameter(valid_593585, JString, required = true,
                                 default = nil)
  if valid_593585 != nil:
    section.add "Bucket", valid_593585
  var valid_593586 = path.getOrDefault("Key")
  valid_593586 = validateParameter(valid_593586, JString, required = true,
                                 default = nil)
  if valid_593586 != nil:
    section.add "Key", valid_593586
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  ##   versionId: JString
  ##            : <p/>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_593587 = query.getOrDefault("tagging")
  valid_593587 = validateParameter(valid_593587, JBool, required = true, default = nil)
  if valid_593587 != nil:
    section.add "tagging", valid_593587
  var valid_593588 = query.getOrDefault("versionId")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "versionId", valid_593588
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593589 = header.getOrDefault("x-amz-security-token")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "x-amz-security-token", valid_593589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593590: Call_GetObjectTagging_593582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag-set of an object.
  ## 
  let valid = call_593590.validator(path, query, header, formData, body)
  let scheme = call_593590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593590.url(scheme.get, call_593590.host, call_593590.base,
                         call_593590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593590, url, valid)

proc call*(call_593591: Call_GetObjectTagging_593582; tagging: bool; Bucket: string;
          Key: string; versionId: string = ""): Recallable =
  ## getObjectTagging
  ## Returns the tag-set of an object.
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versionId: string
  ##            : <p/>
  ##   Key: string (required)
  ##      : <p/>
  var path_593592 = newJObject()
  var query_593593 = newJObject()
  add(query_593593, "tagging", newJBool(tagging))
  add(path_593592, "Bucket", newJString(Bucket))
  add(query_593593, "versionId", newJString(versionId))
  add(path_593592, "Key", newJString(Key))
  result = call_593591.call(path_593592, query_593593, nil, nil, nil)

var getObjectTagging* = Call_GetObjectTagging_593582(name: "getObjectTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_GetObjectTagging_593583,
    base: "/", url: url_GetObjectTagging_593584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjectTagging_593609 = ref object of OpenApiRestCall_592364
proc url_DeleteObjectTagging_593611(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObjectTagging_593610(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes the tag-set from an existing object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593612 = path.getOrDefault("Bucket")
  valid_593612 = validateParameter(valid_593612, JString, required = true,
                                 default = nil)
  if valid_593612 != nil:
    section.add "Bucket", valid_593612
  var valid_593613 = path.getOrDefault("Key")
  valid_593613 = validateParameter(valid_593613, JString, required = true,
                                 default = nil)
  if valid_593613 != nil:
    section.add "Key", valid_593613
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  ##   versionId: JString
  ##            : The versionId of the object that the tag-set will be removed from.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_593614 = query.getOrDefault("tagging")
  valid_593614 = validateParameter(valid_593614, JBool, required = true, default = nil)
  if valid_593614 != nil:
    section.add "tagging", valid_593614
  var valid_593615 = query.getOrDefault("versionId")
  valid_593615 = validateParameter(valid_593615, JString, required = false,
                                 default = nil)
  if valid_593615 != nil:
    section.add "versionId", valid_593615
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593616 = header.getOrDefault("x-amz-security-token")
  valid_593616 = validateParameter(valid_593616, JString, required = false,
                                 default = nil)
  if valid_593616 != nil:
    section.add "x-amz-security-token", valid_593616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593617: Call_DeleteObjectTagging_593609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the tag-set from an existing object.
  ## 
  let valid = call_593617.validator(path, query, header, formData, body)
  let scheme = call_593617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593617.url(scheme.get, call_593617.host, call_593617.base,
                         call_593617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593617, url, valid)

proc call*(call_593618: Call_DeleteObjectTagging_593609; tagging: bool;
          Bucket: string; Key: string; versionId: string = ""): Recallable =
  ## deleteObjectTagging
  ## Removes the tag-set from an existing object.
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versionId: string
  ##            : The versionId of the object that the tag-set will be removed from.
  ##   Key: string (required)
  ##      : <p/>
  var path_593619 = newJObject()
  var query_593620 = newJObject()
  add(query_593620, "tagging", newJBool(tagging))
  add(path_593619, "Bucket", newJString(Bucket))
  add(query_593620, "versionId", newJString(versionId))
  add(path_593619, "Key", newJString(Key))
  result = call_593618.call(path_593619, query_593620, nil, nil, nil)

var deleteObjectTagging* = Call_DeleteObjectTagging_593609(
    name: "deleteObjectTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#tagging",
    validator: validate_DeleteObjectTagging_593610, base: "/",
    url: url_DeleteObjectTagging_593611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjects_593621 = ref object of OpenApiRestCall_592364
proc url_DeleteObjects_593623(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObjects_593622(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593624 = path.getOrDefault("Bucket")
  valid_593624 = validateParameter(valid_593624, JString, required = true,
                                 default = nil)
  if valid_593624 != nil:
    section.add "Bucket", valid_593624
  result.add "path", section
  ## parameters in `query` object:
  ##   delete: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `delete` field"
  var valid_593625 = query.getOrDefault("delete")
  valid_593625 = validateParameter(valid_593625, JBool, required = true, default = nil)
  if valid_593625 != nil:
    section.add "delete", valid_593625
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-bypass-governance-retention: JBool
  ##                                    : Specifies whether you want to delete this object even if it has a Governance-type object lock in place. You must have sufficient permissions to perform this operation.
  ##   x-amz-security-token: JString
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_593626 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_593626 = validateParameter(valid_593626, JBool, required = false, default = nil)
  if valid_593626 != nil:
    section.add "x-amz-bypass-governance-retention", valid_593626
  var valid_593627 = header.getOrDefault("x-amz-security-token")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "x-amz-security-token", valid_593627
  var valid_593628 = header.getOrDefault("x-amz-mfa")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "x-amz-mfa", valid_593628
  var valid_593629 = header.getOrDefault("x-amz-request-payer")
  valid_593629 = validateParameter(valid_593629, JString, required = false,
                                 default = newJString("requester"))
  if valid_593629 != nil:
    section.add "x-amz-request-payer", valid_593629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593631: Call_DeleteObjects_593621; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  let valid = call_593631.validator(path, query, header, formData, body)
  let scheme = call_593631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593631.url(scheme.get, call_593631.host, call_593631.base,
                         call_593631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593631, url, valid)

proc call*(call_593632: Call_DeleteObjects_593621; Bucket: string; delete: bool;
          body: JsonNode): Recallable =
  ## deleteObjects
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   delete: bool (required)
  ##   body: JObject (required)
  var path_593633 = newJObject()
  var query_593634 = newJObject()
  var body_593635 = newJObject()
  add(path_593633, "Bucket", newJString(Bucket))
  add(query_593634, "delete", newJBool(delete))
  if body != nil:
    body_593635 = body
  result = call_593632.call(path_593633, query_593634, nil, nil, body_593635)

var deleteObjects* = Call_DeleteObjects_593621(name: "deleteObjects",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com", route: "/{Bucket}#delete",
    validator: validate_DeleteObjects_593622, base: "/", url: url_DeleteObjects_593623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_593646 = ref object of OpenApiRestCall_592364
proc url_PutPublicAccessBlock_593648(protocol: Scheme; host: string; base: string;
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

proc validate_PutPublicAccessBlock_593647(path: JsonNode; query: JsonNode;
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
  var valid_593649 = path.getOrDefault("Bucket")
  valid_593649 = validateParameter(valid_593649, JString, required = true,
                                 default = nil)
  if valid_593649 != nil:
    section.add "Bucket", valid_593649
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_593650 = query.getOrDefault("publicAccessBlock")
  valid_593650 = validateParameter(valid_593650, JBool, required = true, default = nil)
  if valid_593650 != nil:
    section.add "publicAccessBlock", valid_593650
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash of the <code>PutPublicAccessBlock</code> request body. 
  section = newJObject()
  var valid_593651 = header.getOrDefault("x-amz-security-token")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "x-amz-security-token", valid_593651
  var valid_593652 = header.getOrDefault("Content-MD5")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "Content-MD5", valid_593652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593654: Call_PutPublicAccessBlock_593646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_593654.validator(path, query, header, formData, body)
  let scheme = call_593654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593654.url(scheme.get, call_593654.host, call_593654.base,
                         call_593654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593654, url, valid)

proc call*(call_593655: Call_PutPublicAccessBlock_593646; publicAccessBlock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to set.
  ##   body: JObject (required)
  var path_593656 = newJObject()
  var query_593657 = newJObject()
  var body_593658 = newJObject()
  add(query_593657, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_593656, "Bucket", newJString(Bucket))
  if body != nil:
    body_593658 = body
  result = call_593655.call(path_593656, query_593657, nil, nil, body_593658)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_593646(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_PutPublicAccessBlock_593647, base: "/",
    url: url_PutPublicAccessBlock_593648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_593636 = ref object of OpenApiRestCall_592364
proc url_GetPublicAccessBlock_593638(protocol: Scheme; host: string; base: string;
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

proc validate_GetPublicAccessBlock_593637(path: JsonNode; query: JsonNode;
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
  var valid_593639 = path.getOrDefault("Bucket")
  valid_593639 = validateParameter(valid_593639, JString, required = true,
                                 default = nil)
  if valid_593639 != nil:
    section.add "Bucket", valid_593639
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_593640 = query.getOrDefault("publicAccessBlock")
  valid_593640 = validateParameter(valid_593640, JBool, required = true, default = nil)
  if valid_593640 != nil:
    section.add "publicAccessBlock", valid_593640
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593641 = header.getOrDefault("x-amz-security-token")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "x-amz-security-token", valid_593641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593642: Call_GetPublicAccessBlock_593636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_593642.validator(path, query, header, formData, body)
  let scheme = call_593642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593642.url(scheme.get, call_593642.host, call_593642.base,
                         call_593642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593642, url, valid)

proc call*(call_593643: Call_GetPublicAccessBlock_593636; publicAccessBlock: bool;
          Bucket: string): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to retrieve. 
  var path_593644 = newJObject()
  var query_593645 = newJObject()
  add(query_593645, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_593644, "Bucket", newJString(Bucket))
  result = call_593643.call(path_593644, query_593645, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_593636(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_GetPublicAccessBlock_593637, base: "/",
    url: url_GetPublicAccessBlock_593638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_593659 = ref object of OpenApiRestCall_592364
proc url_DeletePublicAccessBlock_593661(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePublicAccessBlock_593660(path: JsonNode; query: JsonNode;
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
  var valid_593662 = path.getOrDefault("Bucket")
  valid_593662 = validateParameter(valid_593662, JString, required = true,
                                 default = nil)
  if valid_593662 != nil:
    section.add "Bucket", valid_593662
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_593663 = query.getOrDefault("publicAccessBlock")
  valid_593663 = validateParameter(valid_593663, JBool, required = true, default = nil)
  if valid_593663 != nil:
    section.add "publicAccessBlock", valid_593663
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593664 = header.getOrDefault("x-amz-security-token")
  valid_593664 = validateParameter(valid_593664, JString, required = false,
                                 default = nil)
  if valid_593664 != nil:
    section.add "x-amz-security-token", valid_593664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593665: Call_DeletePublicAccessBlock_593659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ## 
  let valid = call_593665.validator(path, query, header, formData, body)
  let scheme = call_593665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593665.url(scheme.get, call_593665.host, call_593665.base,
                         call_593665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593665, url, valid)

proc call*(call_593666: Call_DeletePublicAccessBlock_593659;
          publicAccessBlock: bool; Bucket: string): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to delete. 
  var path_593667 = newJObject()
  var query_593668 = newJObject()
  add(query_593668, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_593667, "Bucket", newJString(Bucket))
  result = call_593666.call(path_593667, query_593668, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_593659(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_DeletePublicAccessBlock_593660, base: "/",
    url: url_DeletePublicAccessBlock_593661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAccelerateConfiguration_593679 = ref object of OpenApiRestCall_592364
proc url_PutBucketAccelerateConfiguration_593681(protocol: Scheme; host: string;
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

proc validate_PutBucketAccelerateConfiguration_593680(path: JsonNode;
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
  var valid_593682 = path.getOrDefault("Bucket")
  valid_593682 = validateParameter(valid_593682, JString, required = true,
                                 default = nil)
  if valid_593682 != nil:
    section.add "Bucket", valid_593682
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_593683 = query.getOrDefault("accelerate")
  valid_593683 = validateParameter(valid_593683, JBool, required = true, default = nil)
  if valid_593683 != nil:
    section.add "accelerate", valid_593683
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593684 = header.getOrDefault("x-amz-security-token")
  valid_593684 = validateParameter(valid_593684, JString, required = false,
                                 default = nil)
  if valid_593684 != nil:
    section.add "x-amz-security-token", valid_593684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593686: Call_PutBucketAccelerateConfiguration_593679;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the accelerate configuration of an existing bucket.
  ## 
  let valid = call_593686.validator(path, query, header, formData, body)
  let scheme = call_593686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593686.url(scheme.get, call_593686.host, call_593686.base,
                         call_593686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593686, url, valid)

proc call*(call_593687: Call_PutBucketAccelerateConfiguration_593679;
          Bucket: string; accelerate: bool; body: JsonNode): Recallable =
  ## putBucketAccelerateConfiguration
  ## Sets the accelerate configuration of an existing bucket.
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is set.
  ##   accelerate: bool (required)
  ##   body: JObject (required)
  var path_593688 = newJObject()
  var query_593689 = newJObject()
  var body_593690 = newJObject()
  add(path_593688, "Bucket", newJString(Bucket))
  add(query_593689, "accelerate", newJBool(accelerate))
  if body != nil:
    body_593690 = body
  result = call_593687.call(path_593688, query_593689, nil, nil, body_593690)

var putBucketAccelerateConfiguration* = Call_PutBucketAccelerateConfiguration_593679(
    name: "putBucketAccelerateConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_PutBucketAccelerateConfiguration_593680, base: "/",
    url: url_PutBucketAccelerateConfiguration_593681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAccelerateConfiguration_593669 = ref object of OpenApiRestCall_592364
proc url_GetBucketAccelerateConfiguration_593671(protocol: Scheme; host: string;
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

proc validate_GetBucketAccelerateConfiguration_593670(path: JsonNode;
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
  var valid_593672 = path.getOrDefault("Bucket")
  valid_593672 = validateParameter(valid_593672, JString, required = true,
                                 default = nil)
  if valid_593672 != nil:
    section.add "Bucket", valid_593672
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_593673 = query.getOrDefault("accelerate")
  valid_593673 = validateParameter(valid_593673, JBool, required = true, default = nil)
  if valid_593673 != nil:
    section.add "accelerate", valid_593673
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593674 = header.getOrDefault("x-amz-security-token")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "x-amz-security-token", valid_593674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593675: Call_GetBucketAccelerateConfiguration_593669;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the accelerate configuration of a bucket.
  ## 
  let valid = call_593675.validator(path, query, header, formData, body)
  let scheme = call_593675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593675.url(scheme.get, call_593675.host, call_593675.base,
                         call_593675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593675, url, valid)

proc call*(call_593676: Call_GetBucketAccelerateConfiguration_593669;
          Bucket: string; accelerate: bool): Recallable =
  ## getBucketAccelerateConfiguration
  ## Returns the accelerate configuration of a bucket.
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is retrieved.
  ##   accelerate: bool (required)
  var path_593677 = newJObject()
  var query_593678 = newJObject()
  add(path_593677, "Bucket", newJString(Bucket))
  add(query_593678, "accelerate", newJBool(accelerate))
  result = call_593676.call(path_593677, query_593678, nil, nil, nil)

var getBucketAccelerateConfiguration* = Call_GetBucketAccelerateConfiguration_593669(
    name: "getBucketAccelerateConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_GetBucketAccelerateConfiguration_593670, base: "/",
    url: url_GetBucketAccelerateConfiguration_593671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAcl_593701 = ref object of OpenApiRestCall_592364
proc url_PutBucketAcl_593703(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketAcl_593702(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593704 = path.getOrDefault("Bucket")
  valid_593704 = validateParameter(valid_593704, JString, required = true,
                                 default = nil)
  if valid_593704 != nil:
    section.add "Bucket", valid_593704
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_593705 = query.getOrDefault("acl")
  valid_593705 = validateParameter(valid_593705, JBool, required = true, default = nil)
  if valid_593705 != nil:
    section.add "acl", valid_593705
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-grant-write: JString
  ##                    : Allows grantee to create, overwrite, and delete any object in the bucket.
  ##   x-amz-security-token: JString
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the bucket ACL.
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the bucket.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable bucket.
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-grant-full-control: JString
  ##                           : Allows grantee the read, write, read ACP, and write ACP permissions on the bucket.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to list the objects in the bucket.
  section = newJObject()
  var valid_593706 = header.getOrDefault("x-amz-grant-write")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "x-amz-grant-write", valid_593706
  var valid_593707 = header.getOrDefault("x-amz-security-token")
  valid_593707 = validateParameter(valid_593707, JString, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "x-amz-security-token", valid_593707
  var valid_593708 = header.getOrDefault("x-amz-grant-read-acp")
  valid_593708 = validateParameter(valid_593708, JString, required = false,
                                 default = nil)
  if valid_593708 != nil:
    section.add "x-amz-grant-read-acp", valid_593708
  var valid_593709 = header.getOrDefault("x-amz-acl")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = newJString("private"))
  if valid_593709 != nil:
    section.add "x-amz-acl", valid_593709
  var valid_593710 = header.getOrDefault("x-amz-grant-write-acp")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "x-amz-grant-write-acp", valid_593710
  var valid_593711 = header.getOrDefault("Content-MD5")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "Content-MD5", valid_593711
  var valid_593712 = header.getOrDefault("x-amz-grant-full-control")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "x-amz-grant-full-control", valid_593712
  var valid_593713 = header.getOrDefault("x-amz-grant-read")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "x-amz-grant-read", valid_593713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593715: Call_PutBucketAcl_593701; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  let valid = call_593715.validator(path, query, header, formData, body)
  let scheme = call_593715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593715.url(scheme.get, call_593715.host, call_593715.base,
                         call_593715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593715, url, valid)

proc call*(call_593716: Call_PutBucketAcl_593701; Bucket: string; acl: bool;
          body: JsonNode): Recallable =
  ## putBucketAcl
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   acl: bool (required)
  ##   body: JObject (required)
  var path_593717 = newJObject()
  var query_593718 = newJObject()
  var body_593719 = newJObject()
  add(path_593717, "Bucket", newJString(Bucket))
  add(query_593718, "acl", newJBool(acl))
  if body != nil:
    body_593719 = body
  result = call_593716.call(path_593717, query_593718, nil, nil, body_593719)

var putBucketAcl* = Call_PutBucketAcl_593701(name: "putBucketAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_PutBucketAcl_593702, base: "/", url: url_PutBucketAcl_593703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAcl_593691 = ref object of OpenApiRestCall_592364
proc url_GetBucketAcl_593693(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketAcl_593692(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593694 = path.getOrDefault("Bucket")
  valid_593694 = validateParameter(valid_593694, JString, required = true,
                                 default = nil)
  if valid_593694 != nil:
    section.add "Bucket", valid_593694
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_593695 = query.getOrDefault("acl")
  valid_593695 = validateParameter(valid_593695, JBool, required = true, default = nil)
  if valid_593695 != nil:
    section.add "acl", valid_593695
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593696 = header.getOrDefault("x-amz-security-token")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "x-amz-security-token", valid_593696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593697: Call_GetBucketAcl_593691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the access control policy for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  let valid = call_593697.validator(path, query, header, formData, body)
  let scheme = call_593697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593697.url(scheme.get, call_593697.host, call_593697.base,
                         call_593697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593697, url, valid)

proc call*(call_593698: Call_GetBucketAcl_593691; Bucket: string; acl: bool): Recallable =
  ## getBucketAcl
  ## Gets the access control policy for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   acl: bool (required)
  var path_593699 = newJObject()
  var query_593700 = newJObject()
  add(path_593699, "Bucket", newJString(Bucket))
  add(query_593700, "acl", newJBool(acl))
  result = call_593698.call(path_593699, query_593700, nil, nil, nil)

var getBucketAcl* = Call_GetBucketAcl_593691(name: "getBucketAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_GetBucketAcl_593692, base: "/", url: url_GetBucketAcl_593693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycle_593730 = ref object of OpenApiRestCall_592364
proc url_PutBucketLifecycle_593732(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketLifecycle_593731(path: JsonNode; query: JsonNode;
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
  var valid_593733 = path.getOrDefault("Bucket")
  valid_593733 = validateParameter(valid_593733, JString, required = true,
                                 default = nil)
  if valid_593733 != nil:
    section.add "Bucket", valid_593733
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_593734 = query.getOrDefault("lifecycle")
  valid_593734 = validateParameter(valid_593734, JBool, required = true, default = nil)
  if valid_593734 != nil:
    section.add "lifecycle", valid_593734
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_593735 = header.getOrDefault("x-amz-security-token")
  valid_593735 = validateParameter(valid_593735, JString, required = false,
                                 default = nil)
  if valid_593735 != nil:
    section.add "x-amz-security-token", valid_593735
  var valid_593736 = header.getOrDefault("Content-MD5")
  valid_593736 = validateParameter(valid_593736, JString, required = false,
                                 default = nil)
  if valid_593736 != nil:
    section.add "Content-MD5", valid_593736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593738: Call_PutBucketLifecycle_593730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  let valid = call_593738.validator(path, query, header, formData, body)
  let scheme = call_593738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593738.url(scheme.get, call_593738.host, call_593738.base,
                         call_593738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593738, url, valid)

proc call*(call_593739: Call_PutBucketLifecycle_593730; Bucket: string;
          body: JsonNode; lifecycle: bool): Recallable =
  ## putBucketLifecycle
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   lifecycle: bool (required)
  var path_593740 = newJObject()
  var query_593741 = newJObject()
  var body_593742 = newJObject()
  add(path_593740, "Bucket", newJString(Bucket))
  if body != nil:
    body_593742 = body
  add(query_593741, "lifecycle", newJBool(lifecycle))
  result = call_593739.call(path_593740, query_593741, nil, nil, body_593742)

var putBucketLifecycle* = Call_PutBucketLifecycle_593730(
    name: "putBucketLifecycle", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_PutBucketLifecycle_593731, base: "/",
    url: url_PutBucketLifecycle_593732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycle_593720 = ref object of OpenApiRestCall_592364
proc url_GetBucketLifecycle_593722(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLifecycle_593721(path: JsonNode; query: JsonNode;
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
  var valid_593723 = path.getOrDefault("Bucket")
  valid_593723 = validateParameter(valid_593723, JString, required = true,
                                 default = nil)
  if valid_593723 != nil:
    section.add "Bucket", valid_593723
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_593724 = query.getOrDefault("lifecycle")
  valid_593724 = validateParameter(valid_593724, JBool, required = true, default = nil)
  if valid_593724 != nil:
    section.add "lifecycle", valid_593724
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593725 = header.getOrDefault("x-amz-security-token")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "x-amz-security-token", valid_593725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593726: Call_GetBucketLifecycle_593720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  let valid = call_593726.validator(path, query, header, formData, body)
  let scheme = call_593726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593726.url(scheme.get, call_593726.host, call_593726.base,
                         call_593726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593726, url, valid)

proc call*(call_593727: Call_GetBucketLifecycle_593720; Bucket: string;
          lifecycle: bool): Recallable =
  ## getBucketLifecycle
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_593728 = newJObject()
  var query_593729 = newJObject()
  add(path_593728, "Bucket", newJString(Bucket))
  add(query_593729, "lifecycle", newJBool(lifecycle))
  result = call_593727.call(path_593728, query_593729, nil, nil, nil)

var getBucketLifecycle* = Call_GetBucketLifecycle_593720(
    name: "getBucketLifecycle", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_GetBucketLifecycle_593721, base: "/",
    url: url_GetBucketLifecycle_593722, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLocation_593743 = ref object of OpenApiRestCall_592364
proc url_GetBucketLocation_593745(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLocation_593744(path: JsonNode; query: JsonNode;
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
  var valid_593746 = path.getOrDefault("Bucket")
  valid_593746 = validateParameter(valid_593746, JString, required = true,
                                 default = nil)
  if valid_593746 != nil:
    section.add "Bucket", valid_593746
  result.add "path", section
  ## parameters in `query` object:
  ##   location: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `location` field"
  var valid_593747 = query.getOrDefault("location")
  valid_593747 = validateParameter(valid_593747, JBool, required = true, default = nil)
  if valid_593747 != nil:
    section.add "location", valid_593747
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593748 = header.getOrDefault("x-amz-security-token")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "x-amz-security-token", valid_593748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593749: Call_GetBucketLocation_593743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the region the bucket resides in.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  let valid = call_593749.validator(path, query, header, formData, body)
  let scheme = call_593749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593749.url(scheme.get, call_593749.host, call_593749.base,
                         call_593749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593749, url, valid)

proc call*(call_593750: Call_GetBucketLocation_593743; Bucket: string; location: bool): Recallable =
  ## getBucketLocation
  ## Returns the region the bucket resides in.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   location: bool (required)
  var path_593751 = newJObject()
  var query_593752 = newJObject()
  add(path_593751, "Bucket", newJString(Bucket))
  add(query_593752, "location", newJBool(location))
  result = call_593750.call(path_593751, query_593752, nil, nil, nil)

var getBucketLocation* = Call_GetBucketLocation_593743(name: "getBucketLocation",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#location",
    validator: validate_GetBucketLocation_593744, base: "/",
    url: url_GetBucketLocation_593745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLogging_593763 = ref object of OpenApiRestCall_592364
proc url_PutBucketLogging_593765(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketLogging_593764(path: JsonNode; query: JsonNode;
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
  var valid_593766 = path.getOrDefault("Bucket")
  valid_593766 = validateParameter(valid_593766, JString, required = true,
                                 default = nil)
  if valid_593766 != nil:
    section.add "Bucket", valid_593766
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_593767 = query.getOrDefault("logging")
  valid_593767 = validateParameter(valid_593767, JBool, required = true, default = nil)
  if valid_593767 != nil:
    section.add "logging", valid_593767
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_593768 = header.getOrDefault("x-amz-security-token")
  valid_593768 = validateParameter(valid_593768, JString, required = false,
                                 default = nil)
  if valid_593768 != nil:
    section.add "x-amz-security-token", valid_593768
  var valid_593769 = header.getOrDefault("Content-MD5")
  valid_593769 = validateParameter(valid_593769, JString, required = false,
                                 default = nil)
  if valid_593769 != nil:
    section.add "Content-MD5", valid_593769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593771: Call_PutBucketLogging_593763; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  let valid = call_593771.validator(path, query, header, formData, body)
  let scheme = call_593771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593771.url(scheme.get, call_593771.host, call_593771.base,
                         call_593771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593771, url, valid)

proc call*(call_593772: Call_PutBucketLogging_593763; Bucket: string; logging: bool;
          body: JsonNode): Recallable =
  ## putBucketLogging
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   logging: bool (required)
  ##   body: JObject (required)
  var path_593773 = newJObject()
  var query_593774 = newJObject()
  var body_593775 = newJObject()
  add(path_593773, "Bucket", newJString(Bucket))
  add(query_593774, "logging", newJBool(logging))
  if body != nil:
    body_593775 = body
  result = call_593772.call(path_593773, query_593774, nil, nil, body_593775)

var putBucketLogging* = Call_PutBucketLogging_593763(name: "putBucketLogging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_PutBucketLogging_593764, base: "/",
    url: url_PutBucketLogging_593765, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLogging_593753 = ref object of OpenApiRestCall_592364
proc url_GetBucketLogging_593755(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLogging_593754(path: JsonNode; query: JsonNode;
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
  var valid_593756 = path.getOrDefault("Bucket")
  valid_593756 = validateParameter(valid_593756, JString, required = true,
                                 default = nil)
  if valid_593756 != nil:
    section.add "Bucket", valid_593756
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_593757 = query.getOrDefault("logging")
  valid_593757 = validateParameter(valid_593757, JBool, required = true, default = nil)
  if valid_593757 != nil:
    section.add "logging", valid_593757
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593758 = header.getOrDefault("x-amz-security-token")
  valid_593758 = validateParameter(valid_593758, JString, required = false,
                                 default = nil)
  if valid_593758 != nil:
    section.add "x-amz-security-token", valid_593758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593759: Call_GetBucketLogging_593753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  let valid = call_593759.validator(path, query, header, formData, body)
  let scheme = call_593759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593759.url(scheme.get, call_593759.host, call_593759.base,
                         call_593759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593759, url, valid)

proc call*(call_593760: Call_GetBucketLogging_593753; Bucket: string; logging: bool): Recallable =
  ## getBucketLogging
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   logging: bool (required)
  var path_593761 = newJObject()
  var query_593762 = newJObject()
  add(path_593761, "Bucket", newJString(Bucket))
  add(query_593762, "logging", newJBool(logging))
  result = call_593760.call(path_593761, query_593762, nil, nil, nil)

var getBucketLogging* = Call_GetBucketLogging_593753(name: "getBucketLogging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_GetBucketLogging_593754, base: "/",
    url: url_GetBucketLogging_593755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotificationConfiguration_593786 = ref object of OpenApiRestCall_592364
proc url_PutBucketNotificationConfiguration_593788(protocol: Scheme; host: string;
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

proc validate_PutBucketNotificationConfiguration_593787(path: JsonNode;
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
  var valid_593789 = path.getOrDefault("Bucket")
  valid_593789 = validateParameter(valid_593789, JString, required = true,
                                 default = nil)
  if valid_593789 != nil:
    section.add "Bucket", valid_593789
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_593790 = query.getOrDefault("notification")
  valid_593790 = validateParameter(valid_593790, JBool, required = true, default = nil)
  if valid_593790 != nil:
    section.add "notification", valid_593790
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593791 = header.getOrDefault("x-amz-security-token")
  valid_593791 = validateParameter(valid_593791, JString, required = false,
                                 default = nil)
  if valid_593791 != nil:
    section.add "x-amz-security-token", valid_593791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593793: Call_PutBucketNotificationConfiguration_593786;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enables notifications of specified events for a bucket.
  ## 
  let valid = call_593793.validator(path, query, header, formData, body)
  let scheme = call_593793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593793.url(scheme.get, call_593793.host, call_593793.base,
                         call_593793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593793, url, valid)

proc call*(call_593794: Call_PutBucketNotificationConfiguration_593786;
          notification: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotificationConfiguration
  ## Enables notifications of specified events for a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_593795 = newJObject()
  var query_593796 = newJObject()
  var body_593797 = newJObject()
  add(query_593796, "notification", newJBool(notification))
  add(path_593795, "Bucket", newJString(Bucket))
  if body != nil:
    body_593797 = body
  result = call_593794.call(path_593795, query_593796, nil, nil, body_593797)

var putBucketNotificationConfiguration* = Call_PutBucketNotificationConfiguration_593786(
    name: "putBucketNotificationConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_PutBucketNotificationConfiguration_593787, base: "/",
    url: url_PutBucketNotificationConfiguration_593788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotificationConfiguration_593776 = ref object of OpenApiRestCall_592364
proc url_GetBucketNotificationConfiguration_593778(protocol: Scheme; host: string;
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

proc validate_GetBucketNotificationConfiguration_593777(path: JsonNode;
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
  var valid_593779 = path.getOrDefault("Bucket")
  valid_593779 = validateParameter(valid_593779, JString, required = true,
                                 default = nil)
  if valid_593779 != nil:
    section.add "Bucket", valid_593779
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_593780 = query.getOrDefault("notification")
  valid_593780 = validateParameter(valid_593780, JBool, required = true, default = nil)
  if valid_593780 != nil:
    section.add "notification", valid_593780
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593781 = header.getOrDefault("x-amz-security-token")
  valid_593781 = validateParameter(valid_593781, JString, required = false,
                                 default = nil)
  if valid_593781 != nil:
    section.add "x-amz-security-token", valid_593781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593782: Call_GetBucketNotificationConfiguration_593776;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the notification configuration of a bucket.
  ## 
  let valid = call_593782.validator(path, query, header, formData, body)
  let scheme = call_593782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593782.url(scheme.get, call_593782.host, call_593782.base,
                         call_593782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593782, url, valid)

proc call*(call_593783: Call_GetBucketNotificationConfiguration_593776;
          notification: bool; Bucket: string): Recallable =
  ## getBucketNotificationConfiguration
  ## Returns the notification configuration of a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_593784 = newJObject()
  var query_593785 = newJObject()
  add(query_593785, "notification", newJBool(notification))
  add(path_593784, "Bucket", newJString(Bucket))
  result = call_593783.call(path_593784, query_593785, nil, nil, nil)

var getBucketNotificationConfiguration* = Call_GetBucketNotificationConfiguration_593776(
    name: "getBucketNotificationConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_GetBucketNotificationConfiguration_593777, base: "/",
    url: url_GetBucketNotificationConfiguration_593778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotification_593808 = ref object of OpenApiRestCall_592364
proc url_PutBucketNotification_593810(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketNotification_593809(path: JsonNode; query: JsonNode;
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
  var valid_593811 = path.getOrDefault("Bucket")
  valid_593811 = validateParameter(valid_593811, JString, required = true,
                                 default = nil)
  if valid_593811 != nil:
    section.add "Bucket", valid_593811
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_593812 = query.getOrDefault("notification")
  valid_593812 = validateParameter(valid_593812, JBool, required = true, default = nil)
  if valid_593812 != nil:
    section.add "notification", valid_593812
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_593813 = header.getOrDefault("x-amz-security-token")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "x-amz-security-token", valid_593813
  var valid_593814 = header.getOrDefault("Content-MD5")
  valid_593814 = validateParameter(valid_593814, JString, required = false,
                                 default = nil)
  if valid_593814 != nil:
    section.add "Content-MD5", valid_593814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593816: Call_PutBucketNotification_593808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  let valid = call_593816.validator(path, query, header, formData, body)
  let scheme = call_593816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593816.url(scheme.get, call_593816.host, call_593816.base,
                         call_593816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593816, url, valid)

proc call*(call_593817: Call_PutBucketNotification_593808; notification: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotification
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_593818 = newJObject()
  var query_593819 = newJObject()
  var body_593820 = newJObject()
  add(query_593819, "notification", newJBool(notification))
  add(path_593818, "Bucket", newJString(Bucket))
  if body != nil:
    body_593820 = body
  result = call_593817.call(path_593818, query_593819, nil, nil, body_593820)

var putBucketNotification* = Call_PutBucketNotification_593808(
    name: "putBucketNotification", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_PutBucketNotification_593809, base: "/",
    url: url_PutBucketNotification_593810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotification_593798 = ref object of OpenApiRestCall_592364
proc url_GetBucketNotification_593800(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketNotification_593799(path: JsonNode; query: JsonNode;
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
  var valid_593801 = path.getOrDefault("Bucket")
  valid_593801 = validateParameter(valid_593801, JString, required = true,
                                 default = nil)
  if valid_593801 != nil:
    section.add "Bucket", valid_593801
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_593802 = query.getOrDefault("notification")
  valid_593802 = validateParameter(valid_593802, JBool, required = true, default = nil)
  if valid_593802 != nil:
    section.add "notification", valid_593802
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593803 = header.getOrDefault("x-amz-security-token")
  valid_593803 = validateParameter(valid_593803, JString, required = false,
                                 default = nil)
  if valid_593803 != nil:
    section.add "x-amz-security-token", valid_593803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593804: Call_GetBucketNotification_593798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  let valid = call_593804.validator(path, query, header, formData, body)
  let scheme = call_593804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593804.url(scheme.get, call_593804.host, call_593804.base,
                         call_593804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593804, url, valid)

proc call*(call_593805: Call_GetBucketNotification_593798; notification: bool;
          Bucket: string): Recallable =
  ## getBucketNotification
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_593806 = newJObject()
  var query_593807 = newJObject()
  add(query_593807, "notification", newJBool(notification))
  add(path_593806, "Bucket", newJString(Bucket))
  result = call_593805.call(path_593806, query_593807, nil, nil, nil)

var getBucketNotification* = Call_GetBucketNotification_593798(
    name: "getBucketNotification", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_GetBucketNotification_593799, base: "/",
    url: url_GetBucketNotification_593800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicyStatus_593821 = ref object of OpenApiRestCall_592364
proc url_GetBucketPolicyStatus_593823(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketPolicyStatus_593822(path: JsonNode; query: JsonNode;
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
  var valid_593824 = path.getOrDefault("Bucket")
  valid_593824 = validateParameter(valid_593824, JString, required = true,
                                 default = nil)
  if valid_593824 != nil:
    section.add "Bucket", valid_593824
  result.add "path", section
  ## parameters in `query` object:
  ##   policyStatus: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `policyStatus` field"
  var valid_593825 = query.getOrDefault("policyStatus")
  valid_593825 = validateParameter(valid_593825, JBool, required = true, default = nil)
  if valid_593825 != nil:
    section.add "policyStatus", valid_593825
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593826 = header.getOrDefault("x-amz-security-token")
  valid_593826 = validateParameter(valid_593826, JString, required = false,
                                 default = nil)
  if valid_593826 != nil:
    section.add "x-amz-security-token", valid_593826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593827: Call_GetBucketPolicyStatus_593821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ## 
  let valid = call_593827.validator(path, query, header, formData, body)
  let scheme = call_593827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593827.url(scheme.get, call_593827.host, call_593827.base,
                         call_593827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593827, url, valid)

proc call*(call_593828: Call_GetBucketPolicyStatus_593821; Bucket: string;
          policyStatus: bool): Recallable =
  ## getBucketPolicyStatus
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose policy status you want to retrieve.
  ##   policyStatus: bool (required)
  var path_593829 = newJObject()
  var query_593830 = newJObject()
  add(path_593829, "Bucket", newJString(Bucket))
  add(query_593830, "policyStatus", newJBool(policyStatus))
  result = call_593828.call(path_593829, query_593830, nil, nil, nil)

var getBucketPolicyStatus* = Call_GetBucketPolicyStatus_593821(
    name: "getBucketPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#policyStatus",
    validator: validate_GetBucketPolicyStatus_593822, base: "/",
    url: url_GetBucketPolicyStatus_593823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketRequestPayment_593841 = ref object of OpenApiRestCall_592364
proc url_PutBucketRequestPayment_593843(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketRequestPayment_593842(path: JsonNode; query: JsonNode;
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
  var valid_593844 = path.getOrDefault("Bucket")
  valid_593844 = validateParameter(valid_593844, JString, required = true,
                                 default = nil)
  if valid_593844 != nil:
    section.add "Bucket", valid_593844
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_593845 = query.getOrDefault("requestPayment")
  valid_593845 = validateParameter(valid_593845, JBool, required = true, default = nil)
  if valid_593845 != nil:
    section.add "requestPayment", valid_593845
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_593846 = header.getOrDefault("x-amz-security-token")
  valid_593846 = validateParameter(valid_593846, JString, required = false,
                                 default = nil)
  if valid_593846 != nil:
    section.add "x-amz-security-token", valid_593846
  var valid_593847 = header.getOrDefault("Content-MD5")
  valid_593847 = validateParameter(valid_593847, JString, required = false,
                                 default = nil)
  if valid_593847 != nil:
    section.add "Content-MD5", valid_593847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593849: Call_PutBucketRequestPayment_593841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  let valid = call_593849.validator(path, query, header, formData, body)
  let scheme = call_593849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593849.url(scheme.get, call_593849.host, call_593849.base,
                         call_593849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593849, url, valid)

proc call*(call_593850: Call_PutBucketRequestPayment_593841; requestPayment: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketRequestPayment
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_593851 = newJObject()
  var query_593852 = newJObject()
  var body_593853 = newJObject()
  add(query_593852, "requestPayment", newJBool(requestPayment))
  add(path_593851, "Bucket", newJString(Bucket))
  if body != nil:
    body_593853 = body
  result = call_593850.call(path_593851, query_593852, nil, nil, body_593853)

var putBucketRequestPayment* = Call_PutBucketRequestPayment_593841(
    name: "putBucketRequestPayment", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_PutBucketRequestPayment_593842, base: "/",
    url: url_PutBucketRequestPayment_593843, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketRequestPayment_593831 = ref object of OpenApiRestCall_592364
proc url_GetBucketRequestPayment_593833(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketRequestPayment_593832(path: JsonNode; query: JsonNode;
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
  var valid_593834 = path.getOrDefault("Bucket")
  valid_593834 = validateParameter(valid_593834, JString, required = true,
                                 default = nil)
  if valid_593834 != nil:
    section.add "Bucket", valid_593834
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_593835 = query.getOrDefault("requestPayment")
  valid_593835 = validateParameter(valid_593835, JBool, required = true, default = nil)
  if valid_593835 != nil:
    section.add "requestPayment", valid_593835
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593836 = header.getOrDefault("x-amz-security-token")
  valid_593836 = validateParameter(valid_593836, JString, required = false,
                                 default = nil)
  if valid_593836 != nil:
    section.add "x-amz-security-token", valid_593836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593837: Call_GetBucketRequestPayment_593831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the request payment configuration of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  let valid = call_593837.validator(path, query, header, formData, body)
  let scheme = call_593837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593837.url(scheme.get, call_593837.host, call_593837.base,
                         call_593837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593837, url, valid)

proc call*(call_593838: Call_GetBucketRequestPayment_593831; requestPayment: bool;
          Bucket: string): Recallable =
  ## getBucketRequestPayment
  ## Returns the request payment configuration of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_593839 = newJObject()
  var query_593840 = newJObject()
  add(query_593840, "requestPayment", newJBool(requestPayment))
  add(path_593839, "Bucket", newJString(Bucket))
  result = call_593838.call(path_593839, query_593840, nil, nil, nil)

var getBucketRequestPayment* = Call_GetBucketRequestPayment_593831(
    name: "getBucketRequestPayment", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_GetBucketRequestPayment_593832, base: "/",
    url: url_GetBucketRequestPayment_593833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketVersioning_593864 = ref object of OpenApiRestCall_592364
proc url_PutBucketVersioning_593866(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketVersioning_593865(path: JsonNode; query: JsonNode;
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
  var valid_593867 = path.getOrDefault("Bucket")
  valid_593867 = validateParameter(valid_593867, JString, required = true,
                                 default = nil)
  if valid_593867 != nil:
    section.add "Bucket", valid_593867
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_593868 = query.getOrDefault("versioning")
  valid_593868 = validateParameter(valid_593868, JBool, required = true, default = nil)
  if valid_593868 != nil:
    section.add "versioning", valid_593868
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_593869 = header.getOrDefault("x-amz-security-token")
  valid_593869 = validateParameter(valid_593869, JString, required = false,
                                 default = nil)
  if valid_593869 != nil:
    section.add "x-amz-security-token", valid_593869
  var valid_593870 = header.getOrDefault("x-amz-mfa")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "x-amz-mfa", valid_593870
  var valid_593871 = header.getOrDefault("Content-MD5")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "Content-MD5", valid_593871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593873: Call_PutBucketVersioning_593864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  let valid = call_593873.validator(path, query, header, formData, body)
  let scheme = call_593873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593873.url(scheme.get, call_593873.host, call_593873.base,
                         call_593873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593873, url, valid)

proc call*(call_593874: Call_PutBucketVersioning_593864; Bucket: string;
          body: JsonNode; versioning: bool): Recallable =
  ## putBucketVersioning
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   versioning: bool (required)
  var path_593875 = newJObject()
  var query_593876 = newJObject()
  var body_593877 = newJObject()
  add(path_593875, "Bucket", newJString(Bucket))
  if body != nil:
    body_593877 = body
  add(query_593876, "versioning", newJBool(versioning))
  result = call_593874.call(path_593875, query_593876, nil, nil, body_593877)

var putBucketVersioning* = Call_PutBucketVersioning_593864(
    name: "putBucketVersioning", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_PutBucketVersioning_593865,
    base: "/", url: url_PutBucketVersioning_593866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketVersioning_593854 = ref object of OpenApiRestCall_592364
proc url_GetBucketVersioning_593856(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketVersioning_593855(path: JsonNode; query: JsonNode;
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
  var valid_593857 = path.getOrDefault("Bucket")
  valid_593857 = validateParameter(valid_593857, JString, required = true,
                                 default = nil)
  if valid_593857 != nil:
    section.add "Bucket", valid_593857
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_593858 = query.getOrDefault("versioning")
  valid_593858 = validateParameter(valid_593858, JBool, required = true, default = nil)
  if valid_593858 != nil:
    section.add "versioning", valid_593858
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593859 = header.getOrDefault("x-amz-security-token")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "x-amz-security-token", valid_593859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593860: Call_GetBucketVersioning_593854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the versioning state of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  let valid = call_593860.validator(path, query, header, formData, body)
  let scheme = call_593860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593860.url(scheme.get, call_593860.host, call_593860.base,
                         call_593860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593860, url, valid)

proc call*(call_593861: Call_GetBucketVersioning_593854; Bucket: string;
          versioning: bool): Recallable =
  ## getBucketVersioning
  ## Returns the versioning state of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versioning: bool (required)
  var path_593862 = newJObject()
  var query_593863 = newJObject()
  add(path_593862, "Bucket", newJString(Bucket))
  add(query_593863, "versioning", newJBool(versioning))
  result = call_593861.call(path_593862, query_593863, nil, nil, nil)

var getBucketVersioning* = Call_GetBucketVersioning_593854(
    name: "getBucketVersioning", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_GetBucketVersioning_593855,
    base: "/", url: url_GetBucketVersioning_593856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectAcl_593891 = ref object of OpenApiRestCall_592364
proc url_PutObjectAcl_593893(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectAcl_593892(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593894 = path.getOrDefault("Bucket")
  valid_593894 = validateParameter(valid_593894, JString, required = true,
                                 default = nil)
  if valid_593894 != nil:
    section.add "Bucket", valid_593894
  var valid_593895 = path.getOrDefault("Key")
  valid_593895 = validateParameter(valid_593895, JString, required = true,
                                 default = nil)
  if valid_593895 != nil:
    section.add "Key", valid_593895
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_593896 = query.getOrDefault("acl")
  valid_593896 = validateParameter(valid_593896, JBool, required = true, default = nil)
  if valid_593896 != nil:
    section.add "acl", valid_593896
  var valid_593897 = query.getOrDefault("versionId")
  valid_593897 = validateParameter(valid_593897, JString, required = false,
                                 default = nil)
  if valid_593897 != nil:
    section.add "versionId", valid_593897
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-grant-write: JString
  ##                    : Allows grantee to create, overwrite, and delete any object in the bucket.
  ##   x-amz-security-token: JString
  ##   x-amz-grant-read-acp: JString
  ##                       : Allows grantee to read the bucket ACL.
  ##   x-amz-acl: JString
  ##            : The canned ACL to apply to the object.
  ##   x-amz-grant-write-acp: JString
  ##                        : Allows grantee to write the ACL for the applicable bucket.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   Content-MD5: JString
  ##              : <p/>
  ##   x-amz-grant-full-control: JString
  ##                           : Allows grantee the read, write, read ACP, and write ACP permissions on the bucket.
  ##   x-amz-grant-read: JString
  ##                   : Allows grantee to list the objects in the bucket.
  section = newJObject()
  var valid_593898 = header.getOrDefault("x-amz-grant-write")
  valid_593898 = validateParameter(valid_593898, JString, required = false,
                                 default = nil)
  if valid_593898 != nil:
    section.add "x-amz-grant-write", valid_593898
  var valid_593899 = header.getOrDefault("x-amz-security-token")
  valid_593899 = validateParameter(valid_593899, JString, required = false,
                                 default = nil)
  if valid_593899 != nil:
    section.add "x-amz-security-token", valid_593899
  var valid_593900 = header.getOrDefault("x-amz-grant-read-acp")
  valid_593900 = validateParameter(valid_593900, JString, required = false,
                                 default = nil)
  if valid_593900 != nil:
    section.add "x-amz-grant-read-acp", valid_593900
  var valid_593901 = header.getOrDefault("x-amz-acl")
  valid_593901 = validateParameter(valid_593901, JString, required = false,
                                 default = newJString("private"))
  if valid_593901 != nil:
    section.add "x-amz-acl", valid_593901
  var valid_593902 = header.getOrDefault("x-amz-grant-write-acp")
  valid_593902 = validateParameter(valid_593902, JString, required = false,
                                 default = nil)
  if valid_593902 != nil:
    section.add "x-amz-grant-write-acp", valid_593902
  var valid_593903 = header.getOrDefault("x-amz-request-payer")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = newJString("requester"))
  if valid_593903 != nil:
    section.add "x-amz-request-payer", valid_593903
  var valid_593904 = header.getOrDefault("Content-MD5")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "Content-MD5", valid_593904
  var valid_593905 = header.getOrDefault("x-amz-grant-full-control")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "x-amz-grant-full-control", valid_593905
  var valid_593906 = header.getOrDefault("x-amz-grant-read")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "x-amz-grant-read", valid_593906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593908: Call_PutObjectAcl_593891; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  let valid = call_593908.validator(path, query, header, formData, body)
  let scheme = call_593908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593908.url(scheme.get, call_593908.host, call_593908.base,
                         call_593908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593908, url, valid)

proc call*(call_593909: Call_PutObjectAcl_593891; Bucket: string; acl: bool;
          Key: string; body: JsonNode; versionId: string = ""): Recallable =
  ## putObjectAcl
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   acl: bool (required)
  ##   versionId: string
  ##            : VersionId used to reference a specific version of the object.
  ##   Key: string (required)
  ##      : <p/>
  ##   body: JObject (required)
  var path_593910 = newJObject()
  var query_593911 = newJObject()
  var body_593912 = newJObject()
  add(path_593910, "Bucket", newJString(Bucket))
  add(query_593911, "acl", newJBool(acl))
  add(query_593911, "versionId", newJString(versionId))
  add(path_593910, "Key", newJString(Key))
  if body != nil:
    body_593912 = body
  result = call_593909.call(path_593910, query_593911, nil, nil, body_593912)

var putObjectAcl* = Call_PutObjectAcl_593891(name: "putObjectAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_PutObjectAcl_593892,
    base: "/", url: url_PutObjectAcl_593893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAcl_593878 = ref object of OpenApiRestCall_592364
proc url_GetObjectAcl_593880(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectAcl_593879(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the access control list (ACL) of an object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593881 = path.getOrDefault("Bucket")
  valid_593881 = validateParameter(valid_593881, JString, required = true,
                                 default = nil)
  if valid_593881 != nil:
    section.add "Bucket", valid_593881
  var valid_593882 = path.getOrDefault("Key")
  valid_593882 = validateParameter(valid_593882, JString, required = true,
                                 default = nil)
  if valid_593882 != nil:
    section.add "Key", valid_593882
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_593883 = query.getOrDefault("acl")
  valid_593883 = validateParameter(valid_593883, JBool, required = true, default = nil)
  if valid_593883 != nil:
    section.add "acl", valid_593883
  var valid_593884 = query.getOrDefault("versionId")
  valid_593884 = validateParameter(valid_593884, JString, required = false,
                                 default = nil)
  if valid_593884 != nil:
    section.add "versionId", valid_593884
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_593885 = header.getOrDefault("x-amz-security-token")
  valid_593885 = validateParameter(valid_593885, JString, required = false,
                                 default = nil)
  if valid_593885 != nil:
    section.add "x-amz-security-token", valid_593885
  var valid_593886 = header.getOrDefault("x-amz-request-payer")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = newJString("requester"))
  if valid_593886 != nil:
    section.add "x-amz-request-payer", valid_593886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593887: Call_GetObjectAcl_593878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access control list (ACL) of an object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  let valid = call_593887.validator(path, query, header, formData, body)
  let scheme = call_593887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593887.url(scheme.get, call_593887.host, call_593887.base,
                         call_593887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593887, url, valid)

proc call*(call_593888: Call_GetObjectAcl_593878; Bucket: string; acl: bool;
          Key: string; versionId: string = ""): Recallable =
  ## getObjectAcl
  ## Returns the access control list (ACL) of an object.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   acl: bool (required)
  ##   versionId: string
  ##            : VersionId used to reference a specific version of the object.
  ##   Key: string (required)
  ##      : <p/>
  var path_593889 = newJObject()
  var query_593890 = newJObject()
  add(path_593889, "Bucket", newJString(Bucket))
  add(query_593890, "acl", newJBool(acl))
  add(query_593890, "versionId", newJString(versionId))
  add(path_593889, "Key", newJString(Key))
  result = call_593888.call(path_593889, query_593890, nil, nil, nil)

var getObjectAcl* = Call_GetObjectAcl_593878(name: "getObjectAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_GetObjectAcl_593879,
    base: "/", url: url_GetObjectAcl_593880, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLegalHold_593926 = ref object of OpenApiRestCall_592364
proc url_PutObjectLegalHold_593928(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectLegalHold_593927(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Applies a Legal Hold configuration to the specified object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The bucket containing the object that you want to place a Legal Hold on.
  ##   Key: JString (required)
  ##      : The key name for the object that you want to place a Legal Hold on.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593929 = path.getOrDefault("Bucket")
  valid_593929 = validateParameter(valid_593929, JString, required = true,
                                 default = nil)
  if valid_593929 != nil:
    section.add "Bucket", valid_593929
  var valid_593930 = path.getOrDefault("Key")
  valid_593930 = validateParameter(valid_593930, JString, required = true,
                                 default = nil)
  if valid_593930 != nil:
    section.add "Key", valid_593930
  result.add "path", section
  ## parameters in `query` object:
  ##   legal-hold: JBool (required)
  ##   versionId: JString
  ##            : The version ID of the object that you want to place a Legal Hold on.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_593931 = query.getOrDefault("legal-hold")
  valid_593931 = validateParameter(valid_593931, JBool, required = true, default = nil)
  if valid_593931 != nil:
    section.add "legal-hold", valid_593931
  var valid_593932 = query.getOrDefault("versionId")
  valid_593932 = validateParameter(valid_593932, JString, required = false,
                                 default = nil)
  if valid_593932 != nil:
    section.add "versionId", valid_593932
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  section = newJObject()
  var valid_593933 = header.getOrDefault("x-amz-security-token")
  valid_593933 = validateParameter(valid_593933, JString, required = false,
                                 default = nil)
  if valid_593933 != nil:
    section.add "x-amz-security-token", valid_593933
  var valid_593934 = header.getOrDefault("x-amz-request-payer")
  valid_593934 = validateParameter(valid_593934, JString, required = false,
                                 default = newJString("requester"))
  if valid_593934 != nil:
    section.add "x-amz-request-payer", valid_593934
  var valid_593935 = header.getOrDefault("Content-MD5")
  valid_593935 = validateParameter(valid_593935, JString, required = false,
                                 default = nil)
  if valid_593935 != nil:
    section.add "Content-MD5", valid_593935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593937: Call_PutObjectLegalHold_593926; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a Legal Hold configuration to the specified object.
  ## 
  let valid = call_593937.validator(path, query, header, formData, body)
  let scheme = call_593937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593937.url(scheme.get, call_593937.host, call_593937.base,
                         call_593937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593937, url, valid)

proc call*(call_593938: Call_PutObjectLegalHold_593926; Bucket: string;
          legalHold: bool; Key: string; body: JsonNode; versionId: string = ""): Recallable =
  ## putObjectLegalHold
  ## Applies a Legal Hold configuration to the specified object.
  ##   Bucket: string (required)
  ##         : The bucket containing the object that you want to place a Legal Hold on.
  ##   legalHold: bool (required)
  ##   versionId: string
  ##            : The version ID of the object that you want to place a Legal Hold on.
  ##   Key: string (required)
  ##      : The key name for the object that you want to place a Legal Hold on.
  ##   body: JObject (required)
  var path_593939 = newJObject()
  var query_593940 = newJObject()
  var body_593941 = newJObject()
  add(path_593939, "Bucket", newJString(Bucket))
  add(query_593940, "legal-hold", newJBool(legalHold))
  add(query_593940, "versionId", newJString(versionId))
  add(path_593939, "Key", newJString(Key))
  if body != nil:
    body_593941 = body
  result = call_593938.call(path_593939, query_593940, nil, nil, body_593941)

var putObjectLegalHold* = Call_PutObjectLegalHold_593926(
    name: "putObjectLegalHold", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_PutObjectLegalHold_593927,
    base: "/", url: url_PutObjectLegalHold_593928,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLegalHold_593913 = ref object of OpenApiRestCall_592364
proc url_GetObjectLegalHold_593915(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectLegalHold_593914(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets an object's current Legal Hold status.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The bucket containing the object whose Legal Hold status you want to retrieve.
  ##   Key: JString (required)
  ##      : The key name for the object whose Legal Hold status you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593916 = path.getOrDefault("Bucket")
  valid_593916 = validateParameter(valid_593916, JString, required = true,
                                 default = nil)
  if valid_593916 != nil:
    section.add "Bucket", valid_593916
  var valid_593917 = path.getOrDefault("Key")
  valid_593917 = validateParameter(valid_593917, JString, required = true,
                                 default = nil)
  if valid_593917 != nil:
    section.add "Key", valid_593917
  result.add "path", section
  ## parameters in `query` object:
  ##   legal-hold: JBool (required)
  ##   versionId: JString
  ##            : The version ID of the object whose Legal Hold status you want to retrieve.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_593918 = query.getOrDefault("legal-hold")
  valid_593918 = validateParameter(valid_593918, JBool, required = true, default = nil)
  if valid_593918 != nil:
    section.add "legal-hold", valid_593918
  var valid_593919 = query.getOrDefault("versionId")
  valid_593919 = validateParameter(valid_593919, JString, required = false,
                                 default = nil)
  if valid_593919 != nil:
    section.add "versionId", valid_593919
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_593920 = header.getOrDefault("x-amz-security-token")
  valid_593920 = validateParameter(valid_593920, JString, required = false,
                                 default = nil)
  if valid_593920 != nil:
    section.add "x-amz-security-token", valid_593920
  var valid_593921 = header.getOrDefault("x-amz-request-payer")
  valid_593921 = validateParameter(valid_593921, JString, required = false,
                                 default = newJString("requester"))
  if valid_593921 != nil:
    section.add "x-amz-request-payer", valid_593921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593922: Call_GetObjectLegalHold_593913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an object's current Legal Hold status.
  ## 
  let valid = call_593922.validator(path, query, header, formData, body)
  let scheme = call_593922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593922.url(scheme.get, call_593922.host, call_593922.base,
                         call_593922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593922, url, valid)

proc call*(call_593923: Call_GetObjectLegalHold_593913; Bucket: string;
          legalHold: bool; Key: string; versionId: string = ""): Recallable =
  ## getObjectLegalHold
  ## Gets an object's current Legal Hold status.
  ##   Bucket: string (required)
  ##         : The bucket containing the object whose Legal Hold status you want to retrieve.
  ##   legalHold: bool (required)
  ##   versionId: string
  ##            : The version ID of the object whose Legal Hold status you want to retrieve.
  ##   Key: string (required)
  ##      : The key name for the object whose Legal Hold status you want to retrieve.
  var path_593924 = newJObject()
  var query_593925 = newJObject()
  add(path_593924, "Bucket", newJString(Bucket))
  add(query_593925, "legal-hold", newJBool(legalHold))
  add(query_593925, "versionId", newJString(versionId))
  add(path_593924, "Key", newJString(Key))
  result = call_593923.call(path_593924, query_593925, nil, nil, nil)

var getObjectLegalHold* = Call_GetObjectLegalHold_593913(
    name: "getObjectLegalHold", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_GetObjectLegalHold_593914,
    base: "/", url: url_GetObjectLegalHold_593915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLockConfiguration_593952 = ref object of OpenApiRestCall_592364
proc url_PutObjectLockConfiguration_593954(protocol: Scheme; host: string;
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

proc validate_PutObjectLockConfiguration_593953(path: JsonNode; query: JsonNode;
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
  var valid_593955 = path.getOrDefault("Bucket")
  valid_593955 = validateParameter(valid_593955, JString, required = true,
                                 default = nil)
  if valid_593955 != nil:
    section.add "Bucket", valid_593955
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_593956 = query.getOrDefault("object-lock")
  valid_593956 = validateParameter(valid_593956, JBool, required = true, default = nil)
  if valid_593956 != nil:
    section.add "object-lock", valid_593956
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-bucket-object-lock-token: JString
  ##                                 : A token to allow Amazon S3 object lock to be enabled for an existing bucket.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  section = newJObject()
  var valid_593957 = header.getOrDefault("x-amz-security-token")
  valid_593957 = validateParameter(valid_593957, JString, required = false,
                                 default = nil)
  if valid_593957 != nil:
    section.add "x-amz-security-token", valid_593957
  var valid_593958 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_593958 = validateParameter(valid_593958, JString, required = false,
                                 default = nil)
  if valid_593958 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_593958
  var valid_593959 = header.getOrDefault("x-amz-request-payer")
  valid_593959 = validateParameter(valid_593959, JString, required = false,
                                 default = newJString("requester"))
  if valid_593959 != nil:
    section.add "x-amz-request-payer", valid_593959
  var valid_593960 = header.getOrDefault("Content-MD5")
  valid_593960 = validateParameter(valid_593960, JString, required = false,
                                 default = nil)
  if valid_593960 != nil:
    section.add "Content-MD5", valid_593960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593962: Call_PutObjectLockConfiguration_593952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_593962.validator(path, query, header, formData, body)
  let scheme = call_593962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593962.url(scheme.get, call_593962.host, call_593962.base,
                         call_593962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593962, url, valid)

proc call*(call_593963: Call_PutObjectLockConfiguration_593952; objectLock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putObjectLockConfiguration
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to create or replace.
  ##   body: JObject (required)
  var path_593964 = newJObject()
  var query_593965 = newJObject()
  var body_593966 = newJObject()
  add(query_593965, "object-lock", newJBool(objectLock))
  add(path_593964, "Bucket", newJString(Bucket))
  if body != nil:
    body_593966 = body
  result = call_593963.call(path_593964, query_593965, nil, nil, body_593966)

var putObjectLockConfiguration* = Call_PutObjectLockConfiguration_593952(
    name: "putObjectLockConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_PutObjectLockConfiguration_593953, base: "/",
    url: url_PutObjectLockConfiguration_593954,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLockConfiguration_593942 = ref object of OpenApiRestCall_592364
proc url_GetObjectLockConfiguration_593944(protocol: Scheme; host: string;
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

proc validate_GetObjectLockConfiguration_593943(path: JsonNode; query: JsonNode;
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
  var valid_593945 = path.getOrDefault("Bucket")
  valid_593945 = validateParameter(valid_593945, JString, required = true,
                                 default = nil)
  if valid_593945 != nil:
    section.add "Bucket", valid_593945
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_593946 = query.getOrDefault("object-lock")
  valid_593946 = validateParameter(valid_593946, JBool, required = true, default = nil)
  if valid_593946 != nil:
    section.add "object-lock", valid_593946
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593947 = header.getOrDefault("x-amz-security-token")
  valid_593947 = validateParameter(valid_593947, JString, required = false,
                                 default = nil)
  if valid_593947 != nil:
    section.add "x-amz-security-token", valid_593947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593948: Call_GetObjectLockConfiguration_593942; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_593948.validator(path, query, header, formData, body)
  let scheme = call_593948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593948.url(scheme.get, call_593948.host, call_593948.base,
                         call_593948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593948, url, valid)

proc call*(call_593949: Call_GetObjectLockConfiguration_593942; objectLock: bool;
          Bucket: string): Recallable =
  ## getObjectLockConfiguration
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to retrieve.
  var path_593950 = newJObject()
  var query_593951 = newJObject()
  add(query_593951, "object-lock", newJBool(objectLock))
  add(path_593950, "Bucket", newJString(Bucket))
  result = call_593949.call(path_593950, query_593951, nil, nil, nil)

var getObjectLockConfiguration* = Call_GetObjectLockConfiguration_593942(
    name: "getObjectLockConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_GetObjectLockConfiguration_593943, base: "/",
    url: url_GetObjectLockConfiguration_593944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectRetention_593980 = ref object of OpenApiRestCall_592364
proc url_PutObjectRetention_593982(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectRetention_593981(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Places an Object Retention configuration on an object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The bucket that contains the object you want to apply this Object Retention configuration to.
  ##   Key: JString (required)
  ##      : The key name for the object that you want to apply this Object Retention configuration to.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593983 = path.getOrDefault("Bucket")
  valid_593983 = validateParameter(valid_593983, JString, required = true,
                                 default = nil)
  if valid_593983 != nil:
    section.add "Bucket", valid_593983
  var valid_593984 = path.getOrDefault("Key")
  valid_593984 = validateParameter(valid_593984, JString, required = true,
                                 default = nil)
  if valid_593984 != nil:
    section.add "Key", valid_593984
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object that you want to apply this Object Retention configuration to.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_593985 = query.getOrDefault("versionId")
  valid_593985 = validateParameter(valid_593985, JString, required = false,
                                 default = nil)
  if valid_593985 != nil:
    section.add "versionId", valid_593985
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_593986 = query.getOrDefault("retention")
  valid_593986 = validateParameter(valid_593986, JBool, required = true, default = nil)
  if valid_593986 != nil:
    section.add "retention", valid_593986
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-bypass-governance-retention: JBool
  ##                                    : Indicates whether this operation should bypass Governance-mode restrictions.j
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  section = newJObject()
  var valid_593987 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_593987 = validateParameter(valid_593987, JBool, required = false, default = nil)
  if valid_593987 != nil:
    section.add "x-amz-bypass-governance-retention", valid_593987
  var valid_593988 = header.getOrDefault("x-amz-security-token")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "x-amz-security-token", valid_593988
  var valid_593989 = header.getOrDefault("x-amz-request-payer")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = newJString("requester"))
  if valid_593989 != nil:
    section.add "x-amz-request-payer", valid_593989
  var valid_593990 = header.getOrDefault("Content-MD5")
  valid_593990 = validateParameter(valid_593990, JString, required = false,
                                 default = nil)
  if valid_593990 != nil:
    section.add "Content-MD5", valid_593990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593992: Call_PutObjectRetention_593980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an Object Retention configuration on an object.
  ## 
  let valid = call_593992.validator(path, query, header, formData, body)
  let scheme = call_593992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593992.url(scheme.get, call_593992.host, call_593992.base,
                         call_593992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593992, url, valid)

proc call*(call_593993: Call_PutObjectRetention_593980; Bucket: string; Key: string;
          retention: bool; body: JsonNode; versionId: string = ""): Recallable =
  ## putObjectRetention
  ## Places an Object Retention configuration on an object.
  ##   Bucket: string (required)
  ##         : The bucket that contains the object you want to apply this Object Retention configuration to.
  ##   versionId: string
  ##            : The version ID for the object that you want to apply this Object Retention configuration to.
  ##   Key: string (required)
  ##      : The key name for the object that you want to apply this Object Retention configuration to.
  ##   retention: bool (required)
  ##   body: JObject (required)
  var path_593994 = newJObject()
  var query_593995 = newJObject()
  var body_593996 = newJObject()
  add(path_593994, "Bucket", newJString(Bucket))
  add(query_593995, "versionId", newJString(versionId))
  add(path_593994, "Key", newJString(Key))
  add(query_593995, "retention", newJBool(retention))
  if body != nil:
    body_593996 = body
  result = call_593993.call(path_593994, query_593995, nil, nil, body_593996)

var putObjectRetention* = Call_PutObjectRetention_593980(
    name: "putObjectRetention", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_PutObjectRetention_593981,
    base: "/", url: url_PutObjectRetention_593982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectRetention_593967 = ref object of OpenApiRestCall_592364
proc url_GetObjectRetention_593969(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectRetention_593968(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves an object's retention settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The bucket containing the object whose retention settings you want to retrieve.
  ##   Key: JString (required)
  ##      : The key name for the object whose retention settings you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_593970 = path.getOrDefault("Bucket")
  valid_593970 = validateParameter(valid_593970, JString, required = true,
                                 default = nil)
  if valid_593970 != nil:
    section.add "Bucket", valid_593970
  var valid_593971 = path.getOrDefault("Key")
  valid_593971 = validateParameter(valid_593971, JString, required = true,
                                 default = nil)
  if valid_593971 != nil:
    section.add "Key", valid_593971
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object whose retention settings you want to retrieve.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_593972 = query.getOrDefault("versionId")
  valid_593972 = validateParameter(valid_593972, JString, required = false,
                                 default = nil)
  if valid_593972 != nil:
    section.add "versionId", valid_593972
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_593973 = query.getOrDefault("retention")
  valid_593973 = validateParameter(valid_593973, JBool, required = true, default = nil)
  if valid_593973 != nil:
    section.add "retention", valid_593973
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_593974 = header.getOrDefault("x-amz-security-token")
  valid_593974 = validateParameter(valid_593974, JString, required = false,
                                 default = nil)
  if valid_593974 != nil:
    section.add "x-amz-security-token", valid_593974
  var valid_593975 = header.getOrDefault("x-amz-request-payer")
  valid_593975 = validateParameter(valid_593975, JString, required = false,
                                 default = newJString("requester"))
  if valid_593975 != nil:
    section.add "x-amz-request-payer", valid_593975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593976: Call_GetObjectRetention_593967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an object's retention settings.
  ## 
  let valid = call_593976.validator(path, query, header, formData, body)
  let scheme = call_593976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593976.url(scheme.get, call_593976.host, call_593976.base,
                         call_593976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593976, url, valid)

proc call*(call_593977: Call_GetObjectRetention_593967; Bucket: string; Key: string;
          retention: bool; versionId: string = ""): Recallable =
  ## getObjectRetention
  ## Retrieves an object's retention settings.
  ##   Bucket: string (required)
  ##         : The bucket containing the object whose retention settings you want to retrieve.
  ##   versionId: string
  ##            : The version ID for the object whose retention settings you want to retrieve.
  ##   Key: string (required)
  ##      : The key name for the object whose retention settings you want to retrieve.
  ##   retention: bool (required)
  var path_593978 = newJObject()
  var query_593979 = newJObject()
  add(path_593978, "Bucket", newJString(Bucket))
  add(query_593979, "versionId", newJString(versionId))
  add(path_593978, "Key", newJString(Key))
  add(query_593979, "retention", newJBool(retention))
  result = call_593977.call(path_593978, query_593979, nil, nil, nil)

var getObjectRetention* = Call_GetObjectRetention_593967(
    name: "getObjectRetention", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_GetObjectRetention_593968,
    base: "/", url: url_GetObjectRetention_593969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTorrent_593997 = ref object of OpenApiRestCall_592364
proc url_GetObjectTorrent_593999(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectTorrent_593998(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Return torrent files from a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_594000 = path.getOrDefault("Bucket")
  valid_594000 = validateParameter(valid_594000, JString, required = true,
                                 default = nil)
  if valid_594000 != nil:
    section.add "Bucket", valid_594000
  var valid_594001 = path.getOrDefault("Key")
  valid_594001 = validateParameter(valid_594001, JString, required = true,
                                 default = nil)
  if valid_594001 != nil:
    section.add "Key", valid_594001
  result.add "path", section
  ## parameters in `query` object:
  ##   torrent: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `torrent` field"
  var valid_594002 = query.getOrDefault("torrent")
  valid_594002 = validateParameter(valid_594002, JBool, required = true, default = nil)
  if valid_594002 != nil:
    section.add "torrent", valid_594002
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_594003 = header.getOrDefault("x-amz-security-token")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "x-amz-security-token", valid_594003
  var valid_594004 = header.getOrDefault("x-amz-request-payer")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = newJString("requester"))
  if valid_594004 != nil:
    section.add "x-amz-request-payer", valid_594004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594005: Call_GetObjectTorrent_593997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return torrent files from a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  let valid = call_594005.validator(path, query, header, formData, body)
  let scheme = call_594005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594005.url(scheme.get, call_594005.host, call_594005.base,
                         call_594005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594005, url, valid)

proc call*(call_594006: Call_GetObjectTorrent_593997; Bucket: string; Key: string;
          torrent: bool): Recallable =
  ## getObjectTorrent
  ## Return torrent files from a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   Key: string (required)
  ##      : <p/>
  ##   torrent: bool (required)
  var path_594007 = newJObject()
  var query_594008 = newJObject()
  add(path_594007, "Bucket", newJString(Bucket))
  add(path_594007, "Key", newJString(Key))
  add(query_594008, "torrent", newJBool(torrent))
  result = call_594006.call(path_594007, query_594008, nil, nil, nil)

var getObjectTorrent* = Call_GetObjectTorrent_593997(name: "getObjectTorrent",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#torrent", validator: validate_GetObjectTorrent_593998,
    base: "/", url: url_GetObjectTorrent_593999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketAnalyticsConfigurations_594009 = ref object of OpenApiRestCall_592364
proc url_ListBucketAnalyticsConfigurations_594011(protocol: Scheme; host: string;
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

proc validate_ListBucketAnalyticsConfigurations_594010(path: JsonNode;
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
  var valid_594012 = path.getOrDefault("Bucket")
  valid_594012 = validateParameter(valid_594012, JString, required = true,
                                 default = nil)
  if valid_594012 != nil:
    section.add "Bucket", valid_594012
  result.add "path", section
  ## parameters in `query` object:
  ##   continuation-token: JString
  ##                     : The ContinuationToken that represents a placeholder from where this request should begin.
  ##   analytics: JBool (required)
  section = newJObject()
  var valid_594013 = query.getOrDefault("continuation-token")
  valid_594013 = validateParameter(valid_594013, JString, required = false,
                                 default = nil)
  if valid_594013 != nil:
    section.add "continuation-token", valid_594013
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_594014 = query.getOrDefault("analytics")
  valid_594014 = validateParameter(valid_594014, JBool, required = true, default = nil)
  if valid_594014 != nil:
    section.add "analytics", valid_594014
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594015 = header.getOrDefault("x-amz-security-token")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "x-amz-security-token", valid_594015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594016: Call_ListBucketAnalyticsConfigurations_594009;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the analytics configurations for the bucket.
  ## 
  let valid = call_594016.validator(path, query, header, formData, body)
  let scheme = call_594016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594016.url(scheme.get, call_594016.host, call_594016.base,
                         call_594016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594016, url, valid)

proc call*(call_594017: Call_ListBucketAnalyticsConfigurations_594009;
          Bucket: string; analytics: bool; continuationToken: string = ""): Recallable =
  ## listBucketAnalyticsConfigurations
  ## Lists the analytics configurations for the bucket.
  ##   continuationToken: string
  ##                    : The ContinuationToken that represents a placeholder from where this request should begin.
  ##   Bucket: string (required)
  ##         : The name of the bucket from which analytics configurations are retrieved.
  ##   analytics: bool (required)
  var path_594018 = newJObject()
  var query_594019 = newJObject()
  add(query_594019, "continuation-token", newJString(continuationToken))
  add(path_594018, "Bucket", newJString(Bucket))
  add(query_594019, "analytics", newJBool(analytics))
  result = call_594017.call(path_594018, query_594019, nil, nil, nil)

var listBucketAnalyticsConfigurations* = Call_ListBucketAnalyticsConfigurations_594009(
    name: "listBucketAnalyticsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics",
    validator: validate_ListBucketAnalyticsConfigurations_594010, base: "/",
    url: url_ListBucketAnalyticsConfigurations_594011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketInventoryConfigurations_594020 = ref object of OpenApiRestCall_592364
proc url_ListBucketInventoryConfigurations_594022(protocol: Scheme; host: string;
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

proc validate_ListBucketInventoryConfigurations_594021(path: JsonNode;
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
  var valid_594023 = path.getOrDefault("Bucket")
  valid_594023 = validateParameter(valid_594023, JString, required = true,
                                 default = nil)
  if valid_594023 != nil:
    section.add "Bucket", valid_594023
  result.add "path", section
  ## parameters in `query` object:
  ##   continuation-token: JString
  ##                     : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   inventory: JBool (required)
  section = newJObject()
  var valid_594024 = query.getOrDefault("continuation-token")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "continuation-token", valid_594024
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_594025 = query.getOrDefault("inventory")
  valid_594025 = validateParameter(valid_594025, JBool, required = true, default = nil)
  if valid_594025 != nil:
    section.add "inventory", valid_594025
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594026 = header.getOrDefault("x-amz-security-token")
  valid_594026 = validateParameter(valid_594026, JString, required = false,
                                 default = nil)
  if valid_594026 != nil:
    section.add "x-amz-security-token", valid_594026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594027: Call_ListBucketInventoryConfigurations_594020;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of inventory configurations for the bucket.
  ## 
  let valid = call_594027.validator(path, query, header, formData, body)
  let scheme = call_594027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594027.url(scheme.get, call_594027.host, call_594027.base,
                         call_594027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594027, url, valid)

proc call*(call_594028: Call_ListBucketInventoryConfigurations_594020;
          Bucket: string; inventory: bool; continuationToken: string = ""): Recallable =
  ## listBucketInventoryConfigurations
  ## Returns a list of inventory configurations for the bucket.
  ##   continuationToken: string
  ##                    : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configurations to retrieve.
  ##   inventory: bool (required)
  var path_594029 = newJObject()
  var query_594030 = newJObject()
  add(query_594030, "continuation-token", newJString(continuationToken))
  add(path_594029, "Bucket", newJString(Bucket))
  add(query_594030, "inventory", newJBool(inventory))
  result = call_594028.call(path_594029, query_594030, nil, nil, nil)

var listBucketInventoryConfigurations* = Call_ListBucketInventoryConfigurations_594020(
    name: "listBucketInventoryConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory",
    validator: validate_ListBucketInventoryConfigurations_594021, base: "/",
    url: url_ListBucketInventoryConfigurations_594022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketMetricsConfigurations_594031 = ref object of OpenApiRestCall_592364
proc url_ListBucketMetricsConfigurations_594033(protocol: Scheme; host: string;
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

proc validate_ListBucketMetricsConfigurations_594032(path: JsonNode;
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
  var valid_594034 = path.getOrDefault("Bucket")
  valid_594034 = validateParameter(valid_594034, JString, required = true,
                                 default = nil)
  if valid_594034 != nil:
    section.add "Bucket", valid_594034
  result.add "path", section
  ## parameters in `query` object:
  ##   continuation-token: JString
  ##                     : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   metrics: JBool (required)
  section = newJObject()
  var valid_594035 = query.getOrDefault("continuation-token")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "continuation-token", valid_594035
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_594036 = query.getOrDefault("metrics")
  valid_594036 = validateParameter(valid_594036, JBool, required = true, default = nil)
  if valid_594036 != nil:
    section.add "metrics", valid_594036
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594037 = header.getOrDefault("x-amz-security-token")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "x-amz-security-token", valid_594037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594038: Call_ListBucketMetricsConfigurations_594031;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the metrics configurations for the bucket.
  ## 
  let valid = call_594038.validator(path, query, header, formData, body)
  let scheme = call_594038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594038.url(scheme.get, call_594038.host, call_594038.base,
                         call_594038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594038, url, valid)

proc call*(call_594039: Call_ListBucketMetricsConfigurations_594031;
          Bucket: string; metrics: bool; continuationToken: string = ""): Recallable =
  ## listBucketMetricsConfigurations
  ## Lists the metrics configurations for the bucket.
  ##   continuationToken: string
  ##                    : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configurations to retrieve.
  ##   metrics: bool (required)
  var path_594040 = newJObject()
  var query_594041 = newJObject()
  add(query_594041, "continuation-token", newJString(continuationToken))
  add(path_594040, "Bucket", newJString(Bucket))
  add(query_594041, "metrics", newJBool(metrics))
  result = call_594039.call(path_594040, query_594041, nil, nil, nil)

var listBucketMetricsConfigurations* = Call_ListBucketMetricsConfigurations_594031(
    name: "listBucketMetricsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics",
    validator: validate_ListBucketMetricsConfigurations_594032, base: "/",
    url: url_ListBucketMetricsConfigurations_594033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuckets_594042 = ref object of OpenApiRestCall_592364
proc url_ListBuckets_594044(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuckets_594043(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594045 = header.getOrDefault("x-amz-security-token")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "x-amz-security-token", valid_594045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594046: Call_ListBuckets_594042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  let valid = call_594046.validator(path, query, header, formData, body)
  let scheme = call_594046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594046.url(scheme.get, call_594046.host, call_594046.base,
                         call_594046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594046, url, valid)

proc call*(call_594047: Call_ListBuckets_594042): Recallable =
  ## listBuckets
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  result = call_594047.call(nil, nil, nil, nil, nil)

var listBuckets* = Call_ListBuckets_594042(name: "listBuckets",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com", route: "/",
                                        validator: validate_ListBuckets_594043,
                                        base: "/", url: url_ListBuckets_594044,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultipartUploads_594048 = ref object of OpenApiRestCall_592364
proc url_ListMultipartUploads_594050(protocol: Scheme; host: string; base: string;
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

proc validate_ListMultipartUploads_594049(path: JsonNode; query: JsonNode;
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
  var valid_594051 = path.getOrDefault("Bucket")
  valid_594051 = validateParameter(valid_594051, JString, required = true,
                                 default = nil)
  if valid_594051 != nil:
    section.add "Bucket", valid_594051
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxUploads: JString
  ##             : Pagination limit
  ##   KeyMarker: JString
  ##            : Pagination token
  ##   prefix: JString
  ##         : Lists in-progress uploads only for those keys that begin with the specified prefix.
  ##   max-uploads: JInt
  ##              : Sets the maximum number of multipart uploads, from 1 to 1,000, to return in the response body. 1,000 is the maximum number of uploads that can be returned in a response.
  ##   UploadIdMarker: JString
  ##                 : Pagination token
  ##   key-marker: JString
  ##             : Together with upload-id-marker, this parameter specifies the multipart upload after which listing should begin.
  ##   upload-id-marker: JString
  ##                   : Together with key-marker, specifies the multipart upload after which listing should begin. If key-marker is not specified, the upload-id-marker parameter is ignored.
  ##   uploads: JBool (required)
  ##   encoding-type: JString
  ##                : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   delimiter: JString
  ##            : Character you use to group keys.
  section = newJObject()
  var valid_594052 = query.getOrDefault("MaxUploads")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "MaxUploads", valid_594052
  var valid_594053 = query.getOrDefault("KeyMarker")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "KeyMarker", valid_594053
  var valid_594054 = query.getOrDefault("prefix")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "prefix", valid_594054
  var valid_594055 = query.getOrDefault("max-uploads")
  valid_594055 = validateParameter(valid_594055, JInt, required = false, default = nil)
  if valid_594055 != nil:
    section.add "max-uploads", valid_594055
  var valid_594056 = query.getOrDefault("UploadIdMarker")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "UploadIdMarker", valid_594056
  var valid_594057 = query.getOrDefault("key-marker")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "key-marker", valid_594057
  var valid_594058 = query.getOrDefault("upload-id-marker")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "upload-id-marker", valid_594058
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_594059 = query.getOrDefault("uploads")
  valid_594059 = validateParameter(valid_594059, JBool, required = true, default = nil)
  if valid_594059 != nil:
    section.add "uploads", valid_594059
  var valid_594060 = query.getOrDefault("encoding-type")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = newJString("url"))
  if valid_594060 != nil:
    section.add "encoding-type", valid_594060
  var valid_594061 = query.getOrDefault("delimiter")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "delimiter", valid_594061
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594062 = header.getOrDefault("x-amz-security-token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "x-amz-security-token", valid_594062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594063: Call_ListMultipartUploads_594048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists in-progress multipart uploads.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
  let valid = call_594063.validator(path, query, header, formData, body)
  let scheme = call_594063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594063.url(scheme.get, call_594063.host, call_594063.base,
                         call_594063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594063, url, valid)

proc call*(call_594064: Call_ListMultipartUploads_594048; Bucket: string;
          uploads: bool; MaxUploads: string = ""; KeyMarker: string = "";
          prefix: string = ""; maxUploads: int = 0; UploadIdMarker: string = "";
          keyMarker: string = ""; uploadIdMarker: string = "";
          encodingType: string = "url"; delimiter: string = ""): Recallable =
  ## listMultipartUploads
  ## This operation lists in-progress multipart uploads.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
  ##   MaxUploads: string
  ##             : Pagination limit
  ##   KeyMarker: string
  ##            : Pagination token
  ##   prefix: string
  ##         : Lists in-progress uploads only for those keys that begin with the specified prefix.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   maxUploads: int
  ##             : Sets the maximum number of multipart uploads, from 1 to 1,000, to return in the response body. 1,000 is the maximum number of uploads that can be returned in a response.
  ##   UploadIdMarker: string
  ##                 : Pagination token
  ##   keyMarker: string
  ##            : Together with upload-id-marker, this parameter specifies the multipart upload after which listing should begin.
  ##   uploadIdMarker: string
  ##                 : Together with key-marker, specifies the multipart upload after which listing should begin. If key-marker is not specified, the upload-id-marker parameter is ignored.
  ##   uploads: bool (required)
  ##   encodingType: string
  ##               : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   delimiter: string
  ##            : Character you use to group keys.
  var path_594065 = newJObject()
  var query_594066 = newJObject()
  add(query_594066, "MaxUploads", newJString(MaxUploads))
  add(query_594066, "KeyMarker", newJString(KeyMarker))
  add(query_594066, "prefix", newJString(prefix))
  add(path_594065, "Bucket", newJString(Bucket))
  add(query_594066, "max-uploads", newJInt(maxUploads))
  add(query_594066, "UploadIdMarker", newJString(UploadIdMarker))
  add(query_594066, "key-marker", newJString(keyMarker))
  add(query_594066, "upload-id-marker", newJString(uploadIdMarker))
  add(query_594066, "uploads", newJBool(uploads))
  add(query_594066, "encoding-type", newJString(encodingType))
  add(query_594066, "delimiter", newJString(delimiter))
  result = call_594064.call(path_594065, query_594066, nil, nil, nil)

var listMultipartUploads* = Call_ListMultipartUploads_594048(
    name: "listMultipartUploads", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#uploads",
    validator: validate_ListMultipartUploads_594049, base: "/",
    url: url_ListMultipartUploads_594050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectVersions_594067 = ref object of OpenApiRestCall_592364
proc url_ListObjectVersions_594069(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectVersions_594068(path: JsonNode; query: JsonNode;
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
  var valid_594070 = path.getOrDefault("Bucket")
  valid_594070 = validateParameter(valid_594070, JString, required = true,
                                 default = nil)
  if valid_594070 != nil:
    section.add "Bucket", valid_594070
  result.add "path", section
  ## parameters in `query` object:
  ##   KeyMarker: JString
  ##            : Pagination token
  ##   prefix: JString
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   version-id-marker: JString
  ##                    : Specifies the object version you want to start listing from.
  ##   MaxKeys: JString
  ##          : Pagination limit
  ##   VersionIdMarker: JString
  ##                  : Pagination token
  ##   key-marker: JString
  ##             : Specifies the key to start with when listing objects in a bucket.
  ##   max-keys: JInt
  ##           : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   encoding-type: JString
  ##                : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   delimiter: JString
  ##            : A delimiter is a character you use to group keys.
  ##   versions: JBool (required)
  section = newJObject()
  var valid_594071 = query.getOrDefault("KeyMarker")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "KeyMarker", valid_594071
  var valid_594072 = query.getOrDefault("prefix")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "prefix", valid_594072
  var valid_594073 = query.getOrDefault("version-id-marker")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "version-id-marker", valid_594073
  var valid_594074 = query.getOrDefault("MaxKeys")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "MaxKeys", valid_594074
  var valid_594075 = query.getOrDefault("VersionIdMarker")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "VersionIdMarker", valid_594075
  var valid_594076 = query.getOrDefault("key-marker")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "key-marker", valid_594076
  var valid_594077 = query.getOrDefault("max-keys")
  valid_594077 = validateParameter(valid_594077, JInt, required = false, default = nil)
  if valid_594077 != nil:
    section.add "max-keys", valid_594077
  var valid_594078 = query.getOrDefault("encoding-type")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = newJString("url"))
  if valid_594078 != nil:
    section.add "encoding-type", valid_594078
  var valid_594079 = query.getOrDefault("delimiter")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "delimiter", valid_594079
  assert query != nil,
        "query argument is necessary due to required `versions` field"
  var valid_594080 = query.getOrDefault("versions")
  valid_594080 = validateParameter(valid_594080, JBool, required = true, default = nil)
  if valid_594080 != nil:
    section.add "versions", valid_594080
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_594081 = header.getOrDefault("x-amz-security-token")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "x-amz-security-token", valid_594081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594082: Call_ListObjectVersions_594067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about all of the versions of objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
  let valid = call_594082.validator(path, query, header, formData, body)
  let scheme = call_594082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594082.url(scheme.get, call_594082.host, call_594082.base,
                         call_594082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594082, url, valid)

proc call*(call_594083: Call_ListObjectVersions_594067; Bucket: string;
          versions: bool; KeyMarker: string = ""; prefix: string = "";
          versionIdMarker: string = ""; MaxKeys: string = "";
          VersionIdMarker: string = ""; keyMarker: string = ""; maxKeys: int = 0;
          encodingType: string = "url"; delimiter: string = ""): Recallable =
  ## listObjectVersions
  ## Returns metadata about all of the versions of objects in a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
  ##   KeyMarker: string
  ##            : Pagination token
  ##   prefix: string
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versionIdMarker: string
  ##                  : Specifies the object version you want to start listing from.
  ##   MaxKeys: string
  ##          : Pagination limit
  ##   VersionIdMarker: string
  ##                  : Pagination token
  ##   keyMarker: string
  ##            : Specifies the key to start with when listing objects in a bucket.
  ##   maxKeys: int
  ##          : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   encodingType: string
  ##               : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   delimiter: string
  ##            : A delimiter is a character you use to group keys.
  ##   versions: bool (required)
  var path_594084 = newJObject()
  var query_594085 = newJObject()
  add(query_594085, "KeyMarker", newJString(KeyMarker))
  add(query_594085, "prefix", newJString(prefix))
  add(path_594084, "Bucket", newJString(Bucket))
  add(query_594085, "version-id-marker", newJString(versionIdMarker))
  add(query_594085, "MaxKeys", newJString(MaxKeys))
  add(query_594085, "VersionIdMarker", newJString(VersionIdMarker))
  add(query_594085, "key-marker", newJString(keyMarker))
  add(query_594085, "max-keys", newJInt(maxKeys))
  add(query_594085, "encoding-type", newJString(encodingType))
  add(query_594085, "delimiter", newJString(delimiter))
  add(query_594085, "versions", newJBool(versions))
  result = call_594083.call(path_594084, query_594085, nil, nil, nil)

var listObjectVersions* = Call_ListObjectVersions_594067(
    name: "listObjectVersions", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versions", validator: validate_ListObjectVersions_594068,
    base: "/", url: url_ListObjectVersions_594069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectsV2_594086 = ref object of OpenApiRestCall_592364
proc url_ListObjectsV2_594088(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectsV2_594087(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594089 = path.getOrDefault("Bucket")
  valid_594089 = validateParameter(valid_594089, JString, required = true,
                                 default = nil)
  if valid_594089 != nil:
    section.add "Bucket", valid_594089
  result.add "path", section
  ## parameters in `query` object:
  ##   ContinuationToken: JString
  ##                    : Pagination token
  ##   continuation-token: JString
  ##                     : ContinuationToken indicates Amazon S3 that the list is being continued on this bucket with a token. ContinuationToken is obfuscated and is not a real key
  ##   fetch-owner: JBool
  ##              : The owner field is not present in listV2 by default, if you want to return owner field with each key in the result then set the fetch owner field to true
  ##   prefix: JString
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   list-type: JString (required)
  ##   MaxKeys: JString
  ##          : Pagination limit
  ##   start-after: JString
  ##              : StartAfter is where you want Amazon S3 to start listing from. Amazon S3 starts listing after this specified key. StartAfter can be any key in the bucket
  ##   max-keys: JInt
  ##           : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   encoding-type: JString
  ##                : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   delimiter: JString
  ##            : A delimiter is a character you use to group keys.
  section = newJObject()
  var valid_594090 = query.getOrDefault("ContinuationToken")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "ContinuationToken", valid_594090
  var valid_594091 = query.getOrDefault("continuation-token")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "continuation-token", valid_594091
  var valid_594092 = query.getOrDefault("fetch-owner")
  valid_594092 = validateParameter(valid_594092, JBool, required = false, default = nil)
  if valid_594092 != nil:
    section.add "fetch-owner", valid_594092
  var valid_594093 = query.getOrDefault("prefix")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "prefix", valid_594093
  assert query != nil,
        "query argument is necessary due to required `list-type` field"
  var valid_594094 = query.getOrDefault("list-type")
  valid_594094 = validateParameter(valid_594094, JString, required = true,
                                 default = newJString("2"))
  if valid_594094 != nil:
    section.add "list-type", valid_594094
  var valid_594095 = query.getOrDefault("MaxKeys")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "MaxKeys", valid_594095
  var valid_594096 = query.getOrDefault("start-after")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "start-after", valid_594096
  var valid_594097 = query.getOrDefault("max-keys")
  valid_594097 = validateParameter(valid_594097, JInt, required = false, default = nil)
  if valid_594097 != nil:
    section.add "max-keys", valid_594097
  var valid_594098 = query.getOrDefault("encoding-type")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = newJString("url"))
  if valid_594098 != nil:
    section.add "encoding-type", valid_594098
  var valid_594099 = query.getOrDefault("delimiter")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "delimiter", valid_594099
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_594100 = header.getOrDefault("x-amz-security-token")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "x-amz-security-token", valid_594100
  var valid_594101 = header.getOrDefault("x-amz-request-payer")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = newJString("requester"))
  if valid_594101 != nil:
    section.add "x-amz-request-payer", valid_594101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594102: Call_ListObjectsV2_594086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. Note: ListObjectsV2 is the revised List Objects API and we recommend you use this revised API for new application development.
  ## 
  let valid = call_594102.validator(path, query, header, formData, body)
  let scheme = call_594102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594102.url(scheme.get, call_594102.host, call_594102.base,
                         call_594102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594102, url, valid)

proc call*(call_594103: Call_ListObjectsV2_594086; Bucket: string;
          ContinuationToken: string = ""; continuationToken: string = "";
          fetchOwner: bool = false; prefix: string = ""; listType: string = "2";
          MaxKeys: string = ""; startAfter: string = ""; maxKeys: int = 0;
          encodingType: string = "url"; delimiter: string = ""): Recallable =
  ## listObjectsV2
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. Note: ListObjectsV2 is the revised List Objects API and we recommend you use this revised API for new application development.
  ##   ContinuationToken: string
  ##                    : Pagination token
  ##   continuationToken: string
  ##                    : ContinuationToken indicates Amazon S3 that the list is being continued on this bucket with a token. ContinuationToken is obfuscated and is not a real key
  ##   fetchOwner: bool
  ##             : The owner field is not present in listV2 by default, if you want to return owner field with each key in the result then set the fetch owner field to true
  ##   prefix: string
  ##         : Limits the response to keys that begin with the specified prefix.
  ##   Bucket: string (required)
  ##         : Name of the bucket to list.
  ##   listType: string (required)
  ##   MaxKeys: string
  ##          : Pagination limit
  ##   startAfter: string
  ##             : StartAfter is where you want Amazon S3 to start listing from. Amazon S3 starts listing after this specified key. StartAfter can be any key in the bucket
  ##   maxKeys: int
  ##          : Sets the maximum number of keys returned in the response. The response might contain fewer keys but will never contain more.
  ##   encodingType: string
  ##               : Requests Amazon S3 to encode the object keys in the response and specifies the encoding method to use. An object key may contain any Unicode character; however, XML 1.0 parser cannot parse some characters, such as characters with an ASCII value from 0 to 10. For characters that are not supported in XML 1.0, you can add this parameter to request that Amazon S3 encode the keys in the response.
  ##   delimiter: string
  ##            : A delimiter is a character you use to group keys.
  var path_594104 = newJObject()
  var query_594105 = newJObject()
  add(query_594105, "ContinuationToken", newJString(ContinuationToken))
  add(query_594105, "continuation-token", newJString(continuationToken))
  add(query_594105, "fetch-owner", newJBool(fetchOwner))
  add(query_594105, "prefix", newJString(prefix))
  add(path_594104, "Bucket", newJString(Bucket))
  add(query_594105, "list-type", newJString(listType))
  add(query_594105, "MaxKeys", newJString(MaxKeys))
  add(query_594105, "start-after", newJString(startAfter))
  add(query_594105, "max-keys", newJInt(maxKeys))
  add(query_594105, "encoding-type", newJString(encodingType))
  add(query_594105, "delimiter", newJString(delimiter))
  result = call_594103.call(path_594104, query_594105, nil, nil, nil)

var listObjectsV2* = Call_ListObjectsV2_594086(name: "listObjectsV2",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#list-type=2", validator: validate_ListObjectsV2_594087,
    base: "/", url: url_ListObjectsV2_594088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreObject_594106 = ref object of OpenApiRestCall_592364
proc url_RestoreObject_594108(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreObject_594107(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Restores an archived copy of an object back into Amazon S3
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_594109 = path.getOrDefault("Bucket")
  valid_594109 = validateParameter(valid_594109, JString, required = true,
                                 default = nil)
  if valid_594109 != nil:
    section.add "Bucket", valid_594109
  var valid_594110 = path.getOrDefault("Key")
  valid_594110 = validateParameter(valid_594110, JString, required = true,
                                 default = nil)
  if valid_594110 != nil:
    section.add "Key", valid_594110
  result.add "path", section
  ## parameters in `query` object:
  ##   restore: JBool (required)
  ##   versionId: JString
  ##            : <p/>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `restore` field"
  var valid_594111 = query.getOrDefault("restore")
  valid_594111 = validateParameter(valid_594111, JBool, required = true, default = nil)
  if valid_594111 != nil:
    section.add "restore", valid_594111
  var valid_594112 = query.getOrDefault("versionId")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "versionId", valid_594112
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_594113 = header.getOrDefault("x-amz-security-token")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "x-amz-security-token", valid_594113
  var valid_594114 = header.getOrDefault("x-amz-request-payer")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = newJString("requester"))
  if valid_594114 != nil:
    section.add "x-amz-request-payer", valid_594114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594116: Call_RestoreObject_594106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restores an archived copy of an object back into Amazon S3
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  let valid = call_594116.validator(path, query, header, formData, body)
  let scheme = call_594116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594116.url(scheme.get, call_594116.host, call_594116.base,
                         call_594116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594116, url, valid)

proc call*(call_594117: Call_RestoreObject_594106; restore: bool; Bucket: string;
          Key: string; body: JsonNode; versionId: string = ""): Recallable =
  ## restoreObject
  ## Restores an archived copy of an object back into Amazon S3
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  ##   restore: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versionId: string
  ##            : <p/>
  ##   Key: string (required)
  ##      : <p/>
  ##   body: JObject (required)
  var path_594118 = newJObject()
  var query_594119 = newJObject()
  var body_594120 = newJObject()
  add(query_594119, "restore", newJBool(restore))
  add(path_594118, "Bucket", newJString(Bucket))
  add(query_594119, "versionId", newJString(versionId))
  add(path_594118, "Key", newJString(Key))
  if body != nil:
    body_594120 = body
  result = call_594117.call(path_594118, query_594119, nil, nil, body_594120)

var restoreObject* = Call_RestoreObject_594106(name: "restoreObject",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#restore", validator: validate_RestoreObject_594107,
    base: "/", url: url_RestoreObject_594108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SelectObjectContent_594121 = ref object of OpenApiRestCall_592364
proc url_SelectObjectContent_594123(protocol: Scheme; host: string; base: string;
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

proc validate_SelectObjectContent_594122(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : The S3 bucket.
  ##   Key: JString (required)
  ##      : The object key.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_594124 = path.getOrDefault("Bucket")
  valid_594124 = validateParameter(valid_594124, JString, required = true,
                                 default = nil)
  if valid_594124 != nil:
    section.add "Bucket", valid_594124
  var valid_594125 = path.getOrDefault("Key")
  valid_594125 = validateParameter(valid_594125, JString, required = true,
                                 default = nil)
  if valid_594125 != nil:
    section.add "Key", valid_594125
  result.add "path", section
  ## parameters in `query` object:
  ##   select: JBool (required)
  ##   select-type: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `select` field"
  var valid_594126 = query.getOrDefault("select")
  valid_594126 = validateParameter(valid_594126, JBool, required = true, default = nil)
  if valid_594126 != nil:
    section.add "select", valid_594126
  var valid_594127 = query.getOrDefault("select-type")
  valid_594127 = validateParameter(valid_594127, JString, required = true,
                                 default = newJString("2"))
  if valid_594127 != nil:
    section.add "select-type", valid_594127
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : The SSE Customer Key MD5. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html"> Server-Side Encryption (Using Customer-Provided Encryption Keys</a>. 
  ##   x-amz-security-token: JString
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : The SSE Customer Key. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html"> Server-Side Encryption (Using Customer-Provided Encryption Keys</a>. 
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : The SSE Algorithm used to encrypt the object. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html"> Server-Side Encryption (Using Customer-Provided Encryption Keys</a>. 
  section = newJObject()
  var valid_594128 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_594128
  var valid_594129 = header.getOrDefault("x-amz-security-token")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "x-amz-security-token", valid_594129
  var valid_594130 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_594130
  var valid_594131 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_594131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594133: Call_SelectObjectContent_594121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ## 
  let valid = call_594133.validator(path, query, header, formData, body)
  let scheme = call_594133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594133.url(scheme.get, call_594133.host, call_594133.base,
                         call_594133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594133, url, valid)

proc call*(call_594134: Call_SelectObjectContent_594121; Bucket: string;
          select: bool; Key: string; body: JsonNode; selectType: string = "2"): Recallable =
  ## selectObjectContent
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ##   Bucket: string (required)
  ##         : The S3 bucket.
  ##   select: bool (required)
  ##   Key: string (required)
  ##      : The object key.
  ##   selectType: string (required)
  ##   body: JObject (required)
  var path_594135 = newJObject()
  var query_594136 = newJObject()
  var body_594137 = newJObject()
  add(path_594135, "Bucket", newJString(Bucket))
  add(query_594136, "select", newJBool(select))
  add(path_594135, "Key", newJString(Key))
  add(query_594136, "select-type", newJString(selectType))
  if body != nil:
    body_594137 = body
  result = call_594134.call(path_594135, query_594136, nil, nil, body_594137)

var selectObjectContent* = Call_SelectObjectContent_594121(
    name: "selectObjectContent", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#select&select-type=2",
    validator: validate_SelectObjectContent_594122, base: "/",
    url: url_SelectObjectContent_594123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPart_594138 = ref object of OpenApiRestCall_592364
proc url_UploadPart_594140(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UploadPart_594139(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : Name of the bucket to which the multipart upload was initiated.
  ##   Key: JString (required)
  ##      : Object key for which the multipart upload was initiated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_594141 = path.getOrDefault("Bucket")
  valid_594141 = validateParameter(valid_594141, JString, required = true,
                                 default = nil)
  if valid_594141 != nil:
    section.add "Bucket", valid_594141
  var valid_594142 = path.getOrDefault("Key")
  valid_594142 = validateParameter(valid_594142, JString, required = true,
                                 default = nil)
  if valid_594142 != nil:
    section.add "Key", valid_594142
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being uploaded.
  ##   partNumber: JInt (required)
  ##             : Part number of part being uploaded. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_594143 = query.getOrDefault("uploadId")
  valid_594143 = validateParameter(valid_594143, JString, required = true,
                                 default = nil)
  if valid_594143 != nil:
    section.add "uploadId", valid_594143
  var valid_594144 = query.getOrDefault("partNumber")
  valid_594144 = validateParameter(valid_594144, JInt, required = true, default = nil)
  if valid_594144 != nil:
    section.add "partNumber", valid_594144
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   Content-Length: JInt
  ##                 : Size of the body in bytes. This parameter is useful when the size of the body cannot be determined automatically.
  ##   x-amz-security-token: JString
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header. This must be the same encryption key specified in the initiate multipart upload request.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the part data. This parameter is auto-populated when using the command from the CLI. This parameted is required if object lock parameters are specified.
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  section = newJObject()
  var valid_594145 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_594145
  var valid_594146 = header.getOrDefault("Content-Length")
  valid_594146 = validateParameter(valid_594146, JInt, required = false, default = nil)
  if valid_594146 != nil:
    section.add "Content-Length", valid_594146
  var valid_594147 = header.getOrDefault("x-amz-security-token")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "x-amz-security-token", valid_594147
  var valid_594148 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_594148
  var valid_594149 = header.getOrDefault("x-amz-request-payer")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = newJString("requester"))
  if valid_594149 != nil:
    section.add "x-amz-request-payer", valid_594149
  var valid_594150 = header.getOrDefault("Content-MD5")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "Content-MD5", valid_594150
  var valid_594151 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_594151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594153: Call_UploadPart_594138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  let valid = call_594153.validator(path, query, header, formData, body)
  let scheme = call_594153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594153.url(scheme.get, call_594153.host, call_594153.base,
                         call_594153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594153, url, valid)

proc call*(call_594154: Call_UploadPart_594138; Bucket: string; uploadId: string;
          Key: string; partNumber: int; body: JsonNode): Recallable =
  ## uploadPart
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the multipart upload was initiated.
  ##   uploadId: string (required)
  ##           : Upload ID identifying the multipart upload whose part is being uploaded.
  ##   Key: string (required)
  ##      : Object key for which the multipart upload was initiated.
  ##   partNumber: int (required)
  ##             : Part number of part being uploaded. This is a positive integer between 1 and 10,000.
  ##   body: JObject (required)
  var path_594155 = newJObject()
  var query_594156 = newJObject()
  var body_594157 = newJObject()
  add(path_594155, "Bucket", newJString(Bucket))
  add(query_594156, "uploadId", newJString(uploadId))
  add(path_594155, "Key", newJString(Key))
  add(query_594156, "partNumber", newJInt(partNumber))
  if body != nil:
    body_594157 = body
  result = call_594154.call(path_594155, query_594156, nil, nil, body_594157)

var uploadPart* = Call_UploadPart_594138(name: "uploadPart",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#partNumber&uploadId",
                                      validator: validate_UploadPart_594139,
                                      base: "/", url: url_UploadPart_594140,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPartCopy_594158 = ref object of OpenApiRestCall_592364
proc url_UploadPartCopy_594160(protocol: Scheme; host: string; base: string;
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

proc validate_UploadPartCopy_594159(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Uploads a part by copying data from an existing object as data source.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Bucket: JString (required)
  ##         : <p/>
  ##   Key: JString (required)
  ##      : <p/>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Bucket` field"
  var valid_594161 = path.getOrDefault("Bucket")
  valid_594161 = validateParameter(valid_594161, JString, required = true,
                                 default = nil)
  if valid_594161 != nil:
    section.add "Bucket", valid_594161
  var valid_594162 = path.getOrDefault("Key")
  valid_594162 = validateParameter(valid_594162, JString, required = true,
                                 default = nil)
  if valid_594162 != nil:
    section.add "Key", valid_594162
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being copied.
  ##   partNumber: JInt (required)
  ##             : Part number of part being copied. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_594163 = query.getOrDefault("uploadId")
  valid_594163 = validateParameter(valid_594163, JString, required = true,
                                 default = nil)
  if valid_594163 != nil:
    section.add "uploadId", valid_594163
  var valid_594164 = query.getOrDefault("partNumber")
  valid_594164 = validateParameter(valid_594164, JInt, required = true, default = nil)
  if valid_594164 != nil:
    section.add "partNumber", valid_594164
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-copy-source-if-none-match: JString
  ##                                  : Copies the object if its entity tag (ETag) is different than the specified ETag.
  ##   x-amz-server-side-encryption-customer-key-MD5: JString
  ##                                                : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-copy-source: JString (required)
  ##                    : The name of the source bucket and key name of the source object, separated by a slash (/). Must be URL-encoded.
  ##   x-amz-copy-source-server-side-encryption-customer-algorithm: JString
  ##                                                              : Specifies the algorithm to use when decrypting the source object (e.g., AES256).
  ##   x-amz-security-token: JString
  ##   x-amz-copy-source-server-side-encryption-customer-key-MD5: JString
  ##                                                            : Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  ##   x-amz-server-side-encryption-customer-key: JString
  ##                                            : Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side​-encryption​-customer-algorithm header. This must be the same encryption key specified in the initiate multipart upload request.
  ##   x-amz-copy-source-if-unmodified-since: JString
  ##                                        : Copies the object if it hasn't been modified since the specified time.
  ##   x-amz-copy-source-if-modified-since: JString
  ##                                      : Copies the object if it has been modified since the specified time.
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   x-amz-copy-source-if-match: JString
  ##                             : Copies the object if its entity tag (ETag) matches the specified tag.
  ##   x-amz-copy-source-server-side-encryption-customer-key: JString
  ##                                                        : Specifies the customer-provided encryption key for Amazon S3 to use to decrypt the source object. The encryption key provided in this header must be one that was used when the source object was created.
  ##   x-amz-server-side-encryption-customer-algorithm: JString
  ##                                                  : Specifies the algorithm to use to when encrypting the object (e.g., AES256).
  ##   x-amz-copy-source-range: JString
  ##                          : The range of bytes to copy from the source object. The range value must use the form bytes=first-last, where the first and last are the zero-based byte offsets to copy. For example, bytes=0-9 indicates that you want to copy the first ten bytes of the source. You can copy a range only if the source object is greater than 5 MB.
  section = newJObject()
  var valid_594165 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_594165
  var valid_594166 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_594166
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_594167 = header.getOrDefault("x-amz-copy-source")
  valid_594167 = validateParameter(valid_594167, JString, required = true,
                                 default = nil)
  if valid_594167 != nil:
    section.add "x-amz-copy-source", valid_594167
  var valid_594168 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_594168
  var valid_594169 = header.getOrDefault("x-amz-security-token")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "x-amz-security-token", valid_594169
  var valid_594170 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_594170
  var valid_594171 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_594171
  var valid_594172 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_594172
  var valid_594173 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_594173
  var valid_594174 = header.getOrDefault("x-amz-request-payer")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = newJString("requester"))
  if valid_594174 != nil:
    section.add "x-amz-request-payer", valid_594174
  var valid_594175 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "x-amz-copy-source-if-match", valid_594175
  var valid_594176 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_594176
  var valid_594177 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_594177
  var valid_594178 = header.getOrDefault("x-amz-copy-source-range")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "x-amz-copy-source-range", valid_594178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594179: Call_UploadPartCopy_594158; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads a part by copying data from an existing object as data source.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  let valid = call_594179.validator(path, query, header, formData, body)
  let scheme = call_594179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594179.url(scheme.get, call_594179.host, call_594179.base,
                         call_594179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594179, url, valid)

proc call*(call_594180: Call_UploadPartCopy_594158; Bucket: string; uploadId: string;
          Key: string; partNumber: int): Recallable =
  ## uploadPartCopy
  ## Uploads a part by copying data from an existing object as data source.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   uploadId: string (required)
  ##           : Upload ID identifying the multipart upload whose part is being copied.
  ##   Key: string (required)
  ##      : <p/>
  ##   partNumber: int (required)
  ##             : Part number of part being copied. This is a positive integer between 1 and 10,000.
  var path_594181 = newJObject()
  var query_594182 = newJObject()
  add(path_594181, "Bucket", newJString(Bucket))
  add(query_594182, "uploadId", newJString(uploadId))
  add(path_594181, "Key", newJString(Key))
  add(query_594182, "partNumber", newJInt(partNumber))
  result = call_594180.call(path_594181, query_594182, nil, nil, nil)

var uploadPartCopy* = Call_UploadPartCopy_594158(name: "uploadPartCopy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#x-amz-copy-source&partNumber&uploadId",
    validator: validate_UploadPartCopy_594159, base: "/", url: url_UploadPartCopy_594160,
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
