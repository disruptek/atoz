
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

  OpenApiRestCall_591364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_591364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_591364): Option[Scheme] {.used.} =
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
  Call_CompleteMultipartUpload_591988 = ref object of OpenApiRestCall_591364
proc url_CompleteMultipartUpload_591990(protocol: Scheme; host: string; base: string;
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

proc validate_CompleteMultipartUpload_591989(path: JsonNode; query: JsonNode;
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
  var valid_591991 = path.getOrDefault("Bucket")
  valid_591991 = validateParameter(valid_591991, JString, required = true,
                                 default = nil)
  if valid_591991 != nil:
    section.add "Bucket", valid_591991
  var valid_591992 = path.getOrDefault("Key")
  valid_591992 = validateParameter(valid_591992, JString, required = true,
                                 default = nil)
  if valid_591992 != nil:
    section.add "Key", valid_591992
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : <p/>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_591993 = query.getOrDefault("uploadId")
  valid_591993 = validateParameter(valid_591993, JString, required = true,
                                 default = nil)
  if valid_591993 != nil:
    section.add "uploadId", valid_591993
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_591994 = header.getOrDefault("x-amz-security-token")
  valid_591994 = validateParameter(valid_591994, JString, required = false,
                                 default = nil)
  if valid_591994 != nil:
    section.add "x-amz-security-token", valid_591994
  var valid_591995 = header.getOrDefault("x-amz-request-payer")
  valid_591995 = validateParameter(valid_591995, JString, required = false,
                                 default = newJString("requester"))
  if valid_591995 != nil:
    section.add "x-amz-request-payer", valid_591995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591997: Call_CompleteMultipartUpload_591988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Completes a multipart upload by assembling previously uploaded parts.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
  let valid = call_591997.validator(path, query, header, formData, body)
  let scheme = call_591997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591997.url(scheme.get, call_591997.host, call_591997.base,
                         call_591997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591997, url, valid)

proc call*(call_591998: Call_CompleteMultipartUpload_591988; Bucket: string;
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
  var path_591999 = newJObject()
  var query_592000 = newJObject()
  var body_592001 = newJObject()
  add(path_591999, "Bucket", newJString(Bucket))
  add(query_592000, "uploadId", newJString(uploadId))
  add(path_591999, "Key", newJString(Key))
  if body != nil:
    body_592001 = body
  result = call_591998.call(path_591999, query_592000, nil, nil, body_592001)

var completeMultipartUpload* = Call_CompleteMultipartUpload_591988(
    name: "completeMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_CompleteMultipartUpload_591989, base: "/",
    url: url_CompleteMultipartUpload_591990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParts_591703 = ref object of OpenApiRestCall_591364
proc url_ListParts_591705(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListParts_591704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591831 = path.getOrDefault("Bucket")
  valid_591831 = validateParameter(valid_591831, JString, required = true,
                                 default = nil)
  if valid_591831 != nil:
    section.add "Bucket", valid_591831
  var valid_591832 = path.getOrDefault("Key")
  valid_591832 = validateParameter(valid_591832, JString, required = true,
                                 default = nil)
  if valid_591832 != nil:
    section.add "Key", valid_591832
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
  var valid_591833 = query.getOrDefault("part-number-marker")
  valid_591833 = validateParameter(valid_591833, JInt, required = false, default = nil)
  if valid_591833 != nil:
    section.add "part-number-marker", valid_591833
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_591834 = query.getOrDefault("uploadId")
  valid_591834 = validateParameter(valid_591834, JString, required = true,
                                 default = nil)
  if valid_591834 != nil:
    section.add "uploadId", valid_591834
  var valid_591835 = query.getOrDefault("PartNumberMarker")
  valid_591835 = validateParameter(valid_591835, JString, required = false,
                                 default = nil)
  if valid_591835 != nil:
    section.add "PartNumberMarker", valid_591835
  var valid_591836 = query.getOrDefault("MaxParts")
  valid_591836 = validateParameter(valid_591836, JString, required = false,
                                 default = nil)
  if valid_591836 != nil:
    section.add "MaxParts", valid_591836
  var valid_591837 = query.getOrDefault("max-parts")
  valid_591837 = validateParameter(valid_591837, JInt, required = false, default = nil)
  if valid_591837 != nil:
    section.add "max-parts", valid_591837
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_591838 = header.getOrDefault("x-amz-security-token")
  valid_591838 = validateParameter(valid_591838, JString, required = false,
                                 default = nil)
  if valid_591838 != nil:
    section.add "x-amz-security-token", valid_591838
  var valid_591852 = header.getOrDefault("x-amz-request-payer")
  valid_591852 = validateParameter(valid_591852, JString, required = false,
                                 default = newJString("requester"))
  if valid_591852 != nil:
    section.add "x-amz-request-payer", valid_591852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591875: Call_ListParts_591703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the parts that have been uploaded for a specific multipart upload.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
  let valid = call_591875.validator(path, query, header, formData, body)
  let scheme = call_591875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591875.url(scheme.get, call_591875.host, call_591875.base,
                         call_591875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591875, url, valid)

proc call*(call_591946: Call_ListParts_591703; Bucket: string; uploadId: string;
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
  var path_591947 = newJObject()
  var query_591949 = newJObject()
  add(path_591947, "Bucket", newJString(Bucket))
  add(query_591949, "part-number-marker", newJInt(partNumberMarker))
  add(query_591949, "uploadId", newJString(uploadId))
  add(path_591947, "Key", newJString(Key))
  add(query_591949, "PartNumberMarker", newJString(PartNumberMarker))
  add(query_591949, "MaxParts", newJString(MaxParts))
  add(query_591949, "max-parts", newJInt(maxParts))
  result = call_591946.call(path_591947, query_591949, nil, nil, nil)

var listParts* = Call_ListParts_591703(name: "listParts", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}#uploadId",
                                    validator: validate_ListParts_591704,
                                    base: "/", url: url_ListParts_591705,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortMultipartUpload_592002 = ref object of OpenApiRestCall_591364
proc url_AbortMultipartUpload_592004(protocol: Scheme; host: string; base: string;
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

proc validate_AbortMultipartUpload_592003(path: JsonNode; query: JsonNode;
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
  var valid_592005 = path.getOrDefault("Bucket")
  valid_592005 = validateParameter(valid_592005, JString, required = true,
                                 default = nil)
  if valid_592005 != nil:
    section.add "Bucket", valid_592005
  var valid_592006 = path.getOrDefault("Key")
  valid_592006 = validateParameter(valid_592006, JString, required = true,
                                 default = nil)
  if valid_592006 != nil:
    section.add "Key", valid_592006
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID that identifies the multipart upload.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_592007 = query.getOrDefault("uploadId")
  valid_592007 = validateParameter(valid_592007, JString, required = true,
                                 default = nil)
  if valid_592007 != nil:
    section.add "uploadId", valid_592007
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_592008 = header.getOrDefault("x-amz-security-token")
  valid_592008 = validateParameter(valid_592008, JString, required = false,
                                 default = nil)
  if valid_592008 != nil:
    section.add "x-amz-security-token", valid_592008
  var valid_592009 = header.getOrDefault("x-amz-request-payer")
  valid_592009 = validateParameter(valid_592009, JString, required = false,
                                 default = newJString("requester"))
  if valid_592009 != nil:
    section.add "x-amz-request-payer", valid_592009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592010: Call_AbortMultipartUpload_592002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Aborts a multipart upload.</p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the List Parts operation and ensure the parts list is empty.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
  let valid = call_592010.validator(path, query, header, formData, body)
  let scheme = call_592010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592010.url(scheme.get, call_592010.host, call_592010.base,
                         call_592010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592010, url, valid)

proc call*(call_592011: Call_AbortMultipartUpload_592002; Bucket: string;
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
  var path_592012 = newJObject()
  var query_592013 = newJObject()
  add(path_592012, "Bucket", newJString(Bucket))
  add(query_592013, "uploadId", newJString(uploadId))
  add(path_592012, "Key", newJString(Key))
  result = call_592011.call(path_592012, query_592013, nil, nil, nil)

var abortMultipartUpload* = Call_AbortMultipartUpload_592002(
    name: "abortMultipartUpload", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploadId",
    validator: validate_AbortMultipartUpload_592003, base: "/",
    url: url_AbortMultipartUpload_592004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyObject_592014 = ref object of OpenApiRestCall_591364
proc url_CopyObject_592016(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CopyObject_592015(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592017 = path.getOrDefault("Bucket")
  valid_592017 = validateParameter(valid_592017, JString, required = true,
                                 default = nil)
  if valid_592017 != nil:
    section.add "Bucket", valid_592017
  var valid_592018 = path.getOrDefault("Key")
  valid_592018 = validateParameter(valid_592018, JString, required = true,
                                 default = nil)
  if valid_592018 != nil:
    section.add "Key", valid_592018
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
  var valid_592019 = header.getOrDefault("Cache-Control")
  valid_592019 = validateParameter(valid_592019, JString, required = false,
                                 default = nil)
  if valid_592019 != nil:
    section.add "Cache-Control", valid_592019
  var valid_592020 = header.getOrDefault("x-amz-metadata-directive")
  valid_592020 = validateParameter(valid_592020, JString, required = false,
                                 default = newJString("COPY"))
  if valid_592020 != nil:
    section.add "x-amz-metadata-directive", valid_592020
  var valid_592021 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_592021 = validateParameter(valid_592021, JString, required = false,
                                 default = nil)
  if valid_592021 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_592021
  var valid_592022 = header.getOrDefault("x-amz-storage-class")
  valid_592022 = validateParameter(valid_592022, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_592022 != nil:
    section.add "x-amz-storage-class", valid_592022
  var valid_592023 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_592023 = validateParameter(valid_592023, JString, required = false,
                                 default = nil)
  if valid_592023 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_592023
  var valid_592024 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_592024 = validateParameter(valid_592024, JString, required = false,
                                 default = nil)
  if valid_592024 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_592024
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_592025 = header.getOrDefault("x-amz-copy-source")
  valid_592025 = validateParameter(valid_592025, JString, required = true,
                                 default = nil)
  if valid_592025 != nil:
    section.add "x-amz-copy-source", valid_592025
  var valid_592026 = header.getOrDefault("x-amz-tagging-directive")
  valid_592026 = validateParameter(valid_592026, JString, required = false,
                                 default = newJString("COPY"))
  if valid_592026 != nil:
    section.add "x-amz-tagging-directive", valid_592026
  var valid_592027 = header.getOrDefault("x-amz-server-side-encryption")
  valid_592027 = validateParameter(valid_592027, JString, required = false,
                                 default = newJString("AES256"))
  if valid_592027 != nil:
    section.add "x-amz-server-side-encryption", valid_592027
  var valid_592028 = header.getOrDefault("x-amz-tagging")
  valid_592028 = validateParameter(valid_592028, JString, required = false,
                                 default = nil)
  if valid_592028 != nil:
    section.add "x-amz-tagging", valid_592028
  var valid_592029 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_592029 = validateParameter(valid_592029, JString, required = false,
                                 default = nil)
  if valid_592029 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_592029
  var valid_592030 = header.getOrDefault("x-amz-object-lock-mode")
  valid_592030 = validateParameter(valid_592030, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_592030 != nil:
    section.add "x-amz-object-lock-mode", valid_592030
  var valid_592031 = header.getOrDefault("x-amz-security-token")
  valid_592031 = validateParameter(valid_592031, JString, required = false,
                                 default = nil)
  if valid_592031 != nil:
    section.add "x-amz-security-token", valid_592031
  var valid_592032 = header.getOrDefault("x-amz-grant-read-acp")
  valid_592032 = validateParameter(valid_592032, JString, required = false,
                                 default = nil)
  if valid_592032 != nil:
    section.add "x-amz-grant-read-acp", valid_592032
  var valid_592033 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_592033 = validateParameter(valid_592033, JString, required = false,
                                 default = nil)
  if valid_592033 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_592033
  var valid_592034 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_592034 = validateParameter(valid_592034, JString, required = false,
                                 default = newJString("ON"))
  if valid_592034 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_592034
  var valid_592035 = header.getOrDefault("x-amz-acl")
  valid_592035 = validateParameter(valid_592035, JString, required = false,
                                 default = newJString("private"))
  if valid_592035 != nil:
    section.add "x-amz-acl", valid_592035
  var valid_592036 = header.getOrDefault("x-amz-grant-write-acp")
  valid_592036 = validateParameter(valid_592036, JString, required = false,
                                 default = nil)
  if valid_592036 != nil:
    section.add "x-amz-grant-write-acp", valid_592036
  var valid_592037 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_592037 = validateParameter(valid_592037, JString, required = false,
                                 default = nil)
  if valid_592037 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_592037
  var valid_592038 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_592038 = validateParameter(valid_592038, JString, required = false,
                                 default = nil)
  if valid_592038 != nil:
    section.add "x-amz-server-side-encryption-context", valid_592038
  var valid_592039 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_592039 = validateParameter(valid_592039, JString, required = false,
                                 default = nil)
  if valid_592039 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_592039
  var valid_592040 = header.getOrDefault("Content-Disposition")
  valid_592040 = validateParameter(valid_592040, JString, required = false,
                                 default = nil)
  if valid_592040 != nil:
    section.add "Content-Disposition", valid_592040
  var valid_592041 = header.getOrDefault("Content-Encoding")
  valid_592041 = validateParameter(valid_592041, JString, required = false,
                                 default = nil)
  if valid_592041 != nil:
    section.add "Content-Encoding", valid_592041
  var valid_592042 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_592042 = validateParameter(valid_592042, JString, required = false,
                                 default = nil)
  if valid_592042 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_592042
  var valid_592043 = header.getOrDefault("x-amz-request-payer")
  valid_592043 = validateParameter(valid_592043, JString, required = false,
                                 default = newJString("requester"))
  if valid_592043 != nil:
    section.add "x-amz-request-payer", valid_592043
  var valid_592044 = header.getOrDefault("x-amz-grant-full-control")
  valid_592044 = validateParameter(valid_592044, JString, required = false,
                                 default = nil)
  if valid_592044 != nil:
    section.add "x-amz-grant-full-control", valid_592044
  var valid_592045 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_592045 = validateParameter(valid_592045, JString, required = false,
                                 default = nil)
  if valid_592045 != nil:
    section.add "x-amz-copy-source-if-match", valid_592045
  var valid_592046 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_592046 = validateParameter(valid_592046, JString, required = false,
                                 default = nil)
  if valid_592046 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_592046
  var valid_592047 = header.getOrDefault("x-amz-website-redirect-location")
  valid_592047 = validateParameter(valid_592047, JString, required = false,
                                 default = nil)
  if valid_592047 != nil:
    section.add "x-amz-website-redirect-location", valid_592047
  var valid_592048 = header.getOrDefault("Content-Language")
  valid_592048 = validateParameter(valid_592048, JString, required = false,
                                 default = nil)
  if valid_592048 != nil:
    section.add "Content-Language", valid_592048
  var valid_592049 = header.getOrDefault("Content-Type")
  valid_592049 = validateParameter(valid_592049, JString, required = false,
                                 default = nil)
  if valid_592049 != nil:
    section.add "Content-Type", valid_592049
  var valid_592050 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_592050 = validateParameter(valid_592050, JString, required = false,
                                 default = nil)
  if valid_592050 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_592050
  var valid_592051 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_592051 = validateParameter(valid_592051, JString, required = false,
                                 default = nil)
  if valid_592051 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_592051
  var valid_592052 = header.getOrDefault("Expires")
  valid_592052 = validateParameter(valid_592052, JString, required = false,
                                 default = nil)
  if valid_592052 != nil:
    section.add "Expires", valid_592052
  var valid_592053 = header.getOrDefault("x-amz-grant-read")
  valid_592053 = validateParameter(valid_592053, JString, required = false,
                                 default = nil)
  if valid_592053 != nil:
    section.add "x-amz-grant-read", valid_592053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592055: Call_CopyObject_592014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  let valid = call_592055.validator(path, query, header, formData, body)
  let scheme = call_592055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592055.url(scheme.get, call_592055.host, call_592055.base,
                         call_592055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592055, url, valid)

proc call*(call_592056: Call_CopyObject_592014; Bucket: string; Key: string;
          body: JsonNode): Recallable =
  ## copyObject
  ## Creates a copy of an object that is already stored in Amazon S3.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   Key: string (required)
  ##      : <p/>
  ##   body: JObject (required)
  var path_592057 = newJObject()
  var body_592058 = newJObject()
  add(path_592057, "Bucket", newJString(Bucket))
  add(path_592057, "Key", newJString(Key))
  if body != nil:
    body_592058 = body
  result = call_592056.call(path_592057, nil, nil, nil, body_592058)

var copyObject* = Call_CopyObject_592014(name: "copyObject",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#x-amz-copy-source",
                                      validator: validate_CopyObject_592015,
                                      base: "/", url: url_CopyObject_592016,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBucket_592076 = ref object of OpenApiRestCall_591364
proc url_CreateBucket_592078(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBucket_592077(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592079 = path.getOrDefault("Bucket")
  valid_592079 = validateParameter(valid_592079, JString, required = true,
                                 default = nil)
  if valid_592079 != nil:
    section.add "Bucket", valid_592079
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
  var valid_592080 = header.getOrDefault("x-amz-grant-write")
  valid_592080 = validateParameter(valid_592080, JString, required = false,
                                 default = nil)
  if valid_592080 != nil:
    section.add "x-amz-grant-write", valid_592080
  var valid_592081 = header.getOrDefault("x-amz-security-token")
  valid_592081 = validateParameter(valid_592081, JString, required = false,
                                 default = nil)
  if valid_592081 != nil:
    section.add "x-amz-security-token", valid_592081
  var valid_592082 = header.getOrDefault("x-amz-grant-read-acp")
  valid_592082 = validateParameter(valid_592082, JString, required = false,
                                 default = nil)
  if valid_592082 != nil:
    section.add "x-amz-grant-read-acp", valid_592082
  var valid_592083 = header.getOrDefault("x-amz-bucket-object-lock-enabled")
  valid_592083 = validateParameter(valid_592083, JBool, required = false, default = nil)
  if valid_592083 != nil:
    section.add "x-amz-bucket-object-lock-enabled", valid_592083
  var valid_592084 = header.getOrDefault("x-amz-acl")
  valid_592084 = validateParameter(valid_592084, JString, required = false,
                                 default = newJString("private"))
  if valid_592084 != nil:
    section.add "x-amz-acl", valid_592084
  var valid_592085 = header.getOrDefault("x-amz-grant-write-acp")
  valid_592085 = validateParameter(valid_592085, JString, required = false,
                                 default = nil)
  if valid_592085 != nil:
    section.add "x-amz-grant-write-acp", valid_592085
  var valid_592086 = header.getOrDefault("x-amz-grant-full-control")
  valid_592086 = validateParameter(valid_592086, JString, required = false,
                                 default = nil)
  if valid_592086 != nil:
    section.add "x-amz-grant-full-control", valid_592086
  var valid_592087 = header.getOrDefault("x-amz-grant-read")
  valid_592087 = validateParameter(valid_592087, JString, required = false,
                                 default = nil)
  if valid_592087 != nil:
    section.add "x-amz-grant-read", valid_592087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592089: Call_CreateBucket_592076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  let valid = call_592089.validator(path, query, header, formData, body)
  let scheme = call_592089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592089.url(scheme.get, call_592089.host, call_592089.base,
                         call_592089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592089, url, valid)

proc call*(call_592090: Call_CreateBucket_592076; Bucket: string; body: JsonNode): Recallable =
  ## createBucket
  ## Creates a new bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_592091 = newJObject()
  var body_592092 = newJObject()
  add(path_592091, "Bucket", newJString(Bucket))
  if body != nil:
    body_592092 = body
  result = call_592090.call(path_592091, nil, nil, nil, body_592092)

var createBucket* = Call_CreateBucket_592076(name: "createBucket",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_CreateBucket_592077, base: "/", url: url_CreateBucket_592078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadBucket_592101 = ref object of OpenApiRestCall_591364
proc url_HeadBucket_592103(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_HeadBucket_592102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592104 = path.getOrDefault("Bucket")
  valid_592104 = validateParameter(valid_592104, JString, required = true,
                                 default = nil)
  if valid_592104 != nil:
    section.add "Bucket", valid_592104
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592105 = header.getOrDefault("x-amz-security-token")
  valid_592105 = validateParameter(valid_592105, JString, required = false,
                                 default = nil)
  if valid_592105 != nil:
    section.add "x-amz-security-token", valid_592105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592106: Call_HeadBucket_592101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  let valid = call_592106.validator(path, query, header, formData, body)
  let scheme = call_592106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592106.url(scheme.get, call_592106.host, call_592106.base,
                         call_592106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592106, url, valid)

proc call*(call_592107: Call_HeadBucket_592101; Bucket: string): Recallable =
  ## headBucket
  ## This operation is useful to determine if a bucket exists and you have permission to access it.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_592108 = newJObject()
  add(path_592108, "Bucket", newJString(Bucket))
  result = call_592107.call(path_592108, nil, nil, nil, nil)

var headBucket* = Call_HeadBucket_592101(name: "headBucket",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}",
                                      validator: validate_HeadBucket_592102,
                                      base: "/", url: url_HeadBucket_592103,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjects_592059 = ref object of OpenApiRestCall_591364
proc url_ListObjects_592061(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjects_592060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592062 = path.getOrDefault("Bucket")
  valid_592062 = validateParameter(valid_592062, JString, required = true,
                                 default = nil)
  if valid_592062 != nil:
    section.add "Bucket", valid_592062
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
  var valid_592063 = query.getOrDefault("Marker")
  valid_592063 = validateParameter(valid_592063, JString, required = false,
                                 default = nil)
  if valid_592063 != nil:
    section.add "Marker", valid_592063
  var valid_592064 = query.getOrDefault("prefix")
  valid_592064 = validateParameter(valid_592064, JString, required = false,
                                 default = nil)
  if valid_592064 != nil:
    section.add "prefix", valid_592064
  var valid_592065 = query.getOrDefault("MaxKeys")
  valid_592065 = validateParameter(valid_592065, JString, required = false,
                                 default = nil)
  if valid_592065 != nil:
    section.add "MaxKeys", valid_592065
  var valid_592066 = query.getOrDefault("max-keys")
  valid_592066 = validateParameter(valid_592066, JInt, required = false, default = nil)
  if valid_592066 != nil:
    section.add "max-keys", valid_592066
  var valid_592067 = query.getOrDefault("encoding-type")
  valid_592067 = validateParameter(valid_592067, JString, required = false,
                                 default = newJString("url"))
  if valid_592067 != nil:
    section.add "encoding-type", valid_592067
  var valid_592068 = query.getOrDefault("delimiter")
  valid_592068 = validateParameter(valid_592068, JString, required = false,
                                 default = nil)
  if valid_592068 != nil:
    section.add "delimiter", valid_592068
  var valid_592069 = query.getOrDefault("marker")
  valid_592069 = validateParameter(valid_592069, JString, required = false,
                                 default = nil)
  if valid_592069 != nil:
    section.add "marker", valid_592069
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_592070 = header.getOrDefault("x-amz-security-token")
  valid_592070 = validateParameter(valid_592070, JString, required = false,
                                 default = nil)
  if valid_592070 != nil:
    section.add "x-amz-security-token", valid_592070
  var valid_592071 = header.getOrDefault("x-amz-request-payer")
  valid_592071 = validateParameter(valid_592071, JString, required = false,
                                 default = newJString("requester"))
  if valid_592071 != nil:
    section.add "x-amz-request-payer", valid_592071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592072: Call_ListObjects_592059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
  let valid = call_592072.validator(path, query, header, formData, body)
  let scheme = call_592072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592072.url(scheme.get, call_592072.host, call_592072.base,
                         call_592072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592072, url, valid)

proc call*(call_592073: Call_ListObjects_592059; Bucket: string; Marker: string = "";
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
  var path_592074 = newJObject()
  var query_592075 = newJObject()
  add(query_592075, "Marker", newJString(Marker))
  add(query_592075, "prefix", newJString(prefix))
  add(path_592074, "Bucket", newJString(Bucket))
  add(query_592075, "MaxKeys", newJString(MaxKeys))
  add(query_592075, "max-keys", newJInt(maxKeys))
  add(query_592075, "encoding-type", newJString(encodingType))
  add(query_592075, "delimiter", newJString(delimiter))
  add(query_592075, "marker", newJString(marker))
  result = call_592073.call(path_592074, query_592075, nil, nil, nil)

var listObjects* = Call_ListObjects_592059(name: "listObjects",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com",
                                        route: "/{Bucket}",
                                        validator: validate_ListObjects_592060,
                                        base: "/", url: url_ListObjects_592061,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucket_592093 = ref object of OpenApiRestCall_591364
proc url_DeleteBucket_592095(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucket_592094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592096 = path.getOrDefault("Bucket")
  valid_592096 = validateParameter(valid_592096, JString, required = true,
                                 default = nil)
  if valid_592096 != nil:
    section.add "Bucket", valid_592096
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592097 = header.getOrDefault("x-amz-security-token")
  valid_592097 = validateParameter(valid_592097, JString, required = false,
                                 default = nil)
  if valid_592097 != nil:
    section.add "x-amz-security-token", valid_592097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592098: Call_DeleteBucket_592093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  let valid = call_592098.validator(path, query, header, formData, body)
  let scheme = call_592098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592098.url(scheme.get, call_592098.host, call_592098.base,
                         call_592098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592098, url, valid)

proc call*(call_592099: Call_DeleteBucket_592093; Bucket: string): Recallable =
  ## deleteBucket
  ## Deletes the bucket. All objects (including all object versions and Delete Markers) in the bucket must be deleted before the bucket itself can be deleted.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
  ##   Bucket: string (required)
  ##         : <p/>
  var path_592100 = newJObject()
  add(path_592100, "Bucket", newJString(Bucket))
  result = call_592099.call(path_592100, nil, nil, nil, nil)

var deleteBucket* = Call_DeleteBucket_592093(name: "deleteBucket",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}",
    validator: validate_DeleteBucket_592094, base: "/", url: url_DeleteBucket_592095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultipartUpload_592109 = ref object of OpenApiRestCall_591364
proc url_CreateMultipartUpload_592111(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMultipartUpload_592110(path: JsonNode; query: JsonNode;
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
  var valid_592112 = path.getOrDefault("Bucket")
  valid_592112 = validateParameter(valid_592112, JString, required = true,
                                 default = nil)
  if valid_592112 != nil:
    section.add "Bucket", valid_592112
  var valid_592113 = path.getOrDefault("Key")
  valid_592113 = validateParameter(valid_592113, JString, required = true,
                                 default = nil)
  if valid_592113 != nil:
    section.add "Key", valid_592113
  result.add "path", section
  ## parameters in `query` object:
  ##   uploads: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_592114 = query.getOrDefault("uploads")
  valid_592114 = validateParameter(valid_592114, JBool, required = true, default = nil)
  if valid_592114 != nil:
    section.add "uploads", valid_592114
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
  var valid_592115 = header.getOrDefault("Cache-Control")
  valid_592115 = validateParameter(valid_592115, JString, required = false,
                                 default = nil)
  if valid_592115 != nil:
    section.add "Cache-Control", valid_592115
  var valid_592116 = header.getOrDefault("x-amz-storage-class")
  valid_592116 = validateParameter(valid_592116, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_592116 != nil:
    section.add "x-amz-storage-class", valid_592116
  var valid_592117 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_592117 = validateParameter(valid_592117, JString, required = false,
                                 default = nil)
  if valid_592117 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_592117
  var valid_592118 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_592118 = validateParameter(valid_592118, JString, required = false,
                                 default = nil)
  if valid_592118 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_592118
  var valid_592119 = header.getOrDefault("x-amz-server-side-encryption")
  valid_592119 = validateParameter(valid_592119, JString, required = false,
                                 default = newJString("AES256"))
  if valid_592119 != nil:
    section.add "x-amz-server-side-encryption", valid_592119
  var valid_592120 = header.getOrDefault("x-amz-tagging")
  valid_592120 = validateParameter(valid_592120, JString, required = false,
                                 default = nil)
  if valid_592120 != nil:
    section.add "x-amz-tagging", valid_592120
  var valid_592121 = header.getOrDefault("x-amz-object-lock-mode")
  valid_592121 = validateParameter(valid_592121, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_592121 != nil:
    section.add "x-amz-object-lock-mode", valid_592121
  var valid_592122 = header.getOrDefault("x-amz-security-token")
  valid_592122 = validateParameter(valid_592122, JString, required = false,
                                 default = nil)
  if valid_592122 != nil:
    section.add "x-amz-security-token", valid_592122
  var valid_592123 = header.getOrDefault("x-amz-grant-read-acp")
  valid_592123 = validateParameter(valid_592123, JString, required = false,
                                 default = nil)
  if valid_592123 != nil:
    section.add "x-amz-grant-read-acp", valid_592123
  var valid_592124 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_592124 = validateParameter(valid_592124, JString, required = false,
                                 default = newJString("ON"))
  if valid_592124 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_592124
  var valid_592125 = header.getOrDefault("x-amz-acl")
  valid_592125 = validateParameter(valid_592125, JString, required = false,
                                 default = newJString("private"))
  if valid_592125 != nil:
    section.add "x-amz-acl", valid_592125
  var valid_592126 = header.getOrDefault("x-amz-grant-write-acp")
  valid_592126 = validateParameter(valid_592126, JString, required = false,
                                 default = nil)
  if valid_592126 != nil:
    section.add "x-amz-grant-write-acp", valid_592126
  var valid_592127 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_592127 = validateParameter(valid_592127, JString, required = false,
                                 default = nil)
  if valid_592127 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_592127
  var valid_592128 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_592128 = validateParameter(valid_592128, JString, required = false,
                                 default = nil)
  if valid_592128 != nil:
    section.add "x-amz-server-side-encryption-context", valid_592128
  var valid_592129 = header.getOrDefault("Content-Disposition")
  valid_592129 = validateParameter(valid_592129, JString, required = false,
                                 default = nil)
  if valid_592129 != nil:
    section.add "Content-Disposition", valid_592129
  var valid_592130 = header.getOrDefault("Content-Encoding")
  valid_592130 = validateParameter(valid_592130, JString, required = false,
                                 default = nil)
  if valid_592130 != nil:
    section.add "Content-Encoding", valid_592130
  var valid_592131 = header.getOrDefault("x-amz-request-payer")
  valid_592131 = validateParameter(valid_592131, JString, required = false,
                                 default = newJString("requester"))
  if valid_592131 != nil:
    section.add "x-amz-request-payer", valid_592131
  var valid_592132 = header.getOrDefault("x-amz-grant-full-control")
  valid_592132 = validateParameter(valid_592132, JString, required = false,
                                 default = nil)
  if valid_592132 != nil:
    section.add "x-amz-grant-full-control", valid_592132
  var valid_592133 = header.getOrDefault("x-amz-website-redirect-location")
  valid_592133 = validateParameter(valid_592133, JString, required = false,
                                 default = nil)
  if valid_592133 != nil:
    section.add "x-amz-website-redirect-location", valid_592133
  var valid_592134 = header.getOrDefault("Content-Language")
  valid_592134 = validateParameter(valid_592134, JString, required = false,
                                 default = nil)
  if valid_592134 != nil:
    section.add "Content-Language", valid_592134
  var valid_592135 = header.getOrDefault("Content-Type")
  valid_592135 = validateParameter(valid_592135, JString, required = false,
                                 default = nil)
  if valid_592135 != nil:
    section.add "Content-Type", valid_592135
  var valid_592136 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_592136 = validateParameter(valid_592136, JString, required = false,
                                 default = nil)
  if valid_592136 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_592136
  var valid_592137 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_592137 = validateParameter(valid_592137, JString, required = false,
                                 default = nil)
  if valid_592137 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_592137
  var valid_592138 = header.getOrDefault("Expires")
  valid_592138 = validateParameter(valid_592138, JString, required = false,
                                 default = nil)
  if valid_592138 != nil:
    section.add "Expires", valid_592138
  var valid_592139 = header.getOrDefault("x-amz-grant-read")
  valid_592139 = validateParameter(valid_592139, JString, required = false,
                                 default = nil)
  if valid_592139 != nil:
    section.add "x-amz-grant-read", valid_592139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592141: Call_CreateMultipartUpload_592109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a multipart upload and returns an upload ID.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
  let valid = call_592141.validator(path, query, header, formData, body)
  let scheme = call_592141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592141.url(scheme.get, call_592141.host, call_592141.base,
                         call_592141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592141, url, valid)

proc call*(call_592142: Call_CreateMultipartUpload_592109; Bucket: string;
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
  var path_592143 = newJObject()
  var query_592144 = newJObject()
  var body_592145 = newJObject()
  add(path_592143, "Bucket", newJString(Bucket))
  add(path_592143, "Key", newJString(Key))
  if body != nil:
    body_592145 = body
  add(query_592144, "uploads", newJBool(uploads))
  result = call_592142.call(path_592143, query_592144, nil, nil, body_592145)

var createMultipartUpload* = Call_CreateMultipartUpload_592109(
    name: "createMultipartUpload", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#uploads",
    validator: validate_CreateMultipartUpload_592110, base: "/",
    url: url_CreateMultipartUpload_592111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAnalyticsConfiguration_592157 = ref object of OpenApiRestCall_591364
proc url_PutBucketAnalyticsConfiguration_592159(protocol: Scheme; host: string;
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

proc validate_PutBucketAnalyticsConfiguration_592158(path: JsonNode;
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
  var valid_592160 = path.getOrDefault("Bucket")
  valid_592160 = validateParameter(valid_592160, JString, required = true,
                                 default = nil)
  if valid_592160 != nil:
    section.add "Bucket", valid_592160
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_592161 = query.getOrDefault("analytics")
  valid_592161 = validateParameter(valid_592161, JBool, required = true, default = nil)
  if valid_592161 != nil:
    section.add "analytics", valid_592161
  var valid_592162 = query.getOrDefault("id")
  valid_592162 = validateParameter(valid_592162, JString, required = true,
                                 default = nil)
  if valid_592162 != nil:
    section.add "id", valid_592162
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592163 = header.getOrDefault("x-amz-security-token")
  valid_592163 = validateParameter(valid_592163, JString, required = false,
                                 default = nil)
  if valid_592163 != nil:
    section.add "x-amz-security-token", valid_592163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592165: Call_PutBucketAnalyticsConfiguration_592157;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_592165.validator(path, query, header, formData, body)
  let scheme = call_592165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592165.url(scheme.get, call_592165.host, call_592165.base,
                         call_592165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592165, url, valid)

proc call*(call_592166: Call_PutBucketAnalyticsConfiguration_592157;
          Bucket: string; analytics: bool; id: string; body: JsonNode): Recallable =
  ## putBucketAnalyticsConfiguration
  ## Sets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   Bucket: string (required)
  ##         : The name of the bucket to which an analytics configuration is stored.
  ##   analytics: bool (required)
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  ##   body: JObject (required)
  var path_592167 = newJObject()
  var query_592168 = newJObject()
  var body_592169 = newJObject()
  add(path_592167, "Bucket", newJString(Bucket))
  add(query_592168, "analytics", newJBool(analytics))
  add(query_592168, "id", newJString(id))
  if body != nil:
    body_592169 = body
  result = call_592166.call(path_592167, query_592168, nil, nil, body_592169)

var putBucketAnalyticsConfiguration* = Call_PutBucketAnalyticsConfiguration_592157(
    name: "putBucketAnalyticsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_PutBucketAnalyticsConfiguration_592158, base: "/",
    url: url_PutBucketAnalyticsConfiguration_592159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAnalyticsConfiguration_592146 = ref object of OpenApiRestCall_591364
proc url_GetBucketAnalyticsConfiguration_592148(protocol: Scheme; host: string;
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

proc validate_GetBucketAnalyticsConfiguration_592147(path: JsonNode;
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
  var valid_592149 = path.getOrDefault("Bucket")
  valid_592149 = validateParameter(valid_592149, JString, required = true,
                                 default = nil)
  if valid_592149 != nil:
    section.add "Bucket", valid_592149
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_592150 = query.getOrDefault("analytics")
  valid_592150 = validateParameter(valid_592150, JBool, required = true, default = nil)
  if valid_592150 != nil:
    section.add "analytics", valid_592150
  var valid_592151 = query.getOrDefault("id")
  valid_592151 = validateParameter(valid_592151, JString, required = true,
                                 default = nil)
  if valid_592151 != nil:
    section.add "id", valid_592151
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592152 = header.getOrDefault("x-amz-security-token")
  valid_592152 = validateParameter(valid_592152, JString, required = false,
                                 default = nil)
  if valid_592152 != nil:
    section.add "x-amz-security-token", valid_592152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592153: Call_GetBucketAnalyticsConfiguration_592146;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ## 
  let valid = call_592153.validator(path, query, header, formData, body)
  let scheme = call_592153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592153.url(scheme.get, call_592153.host, call_592153.base,
                         call_592153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592153, url, valid)

proc call*(call_592154: Call_GetBucketAnalyticsConfiguration_592146;
          Bucket: string; analytics: bool; id: string): Recallable =
  ## getBucketAnalyticsConfiguration
  ## Gets an analytics configuration for the bucket (specified by the analytics configuration ID).
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is retrieved.
  ##   analytics: bool (required)
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  var path_592155 = newJObject()
  var query_592156 = newJObject()
  add(path_592155, "Bucket", newJString(Bucket))
  add(query_592156, "analytics", newJBool(analytics))
  add(query_592156, "id", newJString(id))
  result = call_592154.call(path_592155, query_592156, nil, nil, nil)

var getBucketAnalyticsConfiguration* = Call_GetBucketAnalyticsConfiguration_592146(
    name: "getBucketAnalyticsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_GetBucketAnalyticsConfiguration_592147, base: "/",
    url: url_GetBucketAnalyticsConfiguration_592148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketAnalyticsConfiguration_592170 = ref object of OpenApiRestCall_591364
proc url_DeleteBucketAnalyticsConfiguration_592172(protocol: Scheme; host: string;
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

proc validate_DeleteBucketAnalyticsConfiguration_592171(path: JsonNode;
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
  var valid_592173 = path.getOrDefault("Bucket")
  valid_592173 = validateParameter(valid_592173, JString, required = true,
                                 default = nil)
  if valid_592173 != nil:
    section.add "Bucket", valid_592173
  result.add "path", section
  ## parameters in `query` object:
  ##   analytics: JBool (required)
  ##   id: JString (required)
  ##     : The ID that identifies the analytics configuration.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_592174 = query.getOrDefault("analytics")
  valid_592174 = validateParameter(valid_592174, JBool, required = true, default = nil)
  if valid_592174 != nil:
    section.add "analytics", valid_592174
  var valid_592175 = query.getOrDefault("id")
  valid_592175 = validateParameter(valid_592175, JString, required = true,
                                 default = nil)
  if valid_592175 != nil:
    section.add "id", valid_592175
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592176 = header.getOrDefault("x-amz-security-token")
  valid_592176 = validateParameter(valid_592176, JString, required = false,
                                 default = nil)
  if valid_592176 != nil:
    section.add "x-amz-security-token", valid_592176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592177: Call_DeleteBucketAnalyticsConfiguration_592170;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ## 
  let valid = call_592177.validator(path, query, header, formData, body)
  let scheme = call_592177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592177.url(scheme.get, call_592177.host, call_592177.base,
                         call_592177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592177, url, valid)

proc call*(call_592178: Call_DeleteBucketAnalyticsConfiguration_592170;
          Bucket: string; analytics: bool; id: string): Recallable =
  ## deleteBucketAnalyticsConfiguration
  ## <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the s3:PutAnalyticsConfiguration action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. </p>
  ##   Bucket: string (required)
  ##         : The name of the bucket from which an analytics configuration is deleted.
  ##   analytics: bool (required)
  ##   id: string (required)
  ##     : The ID that identifies the analytics configuration.
  var path_592179 = newJObject()
  var query_592180 = newJObject()
  add(path_592179, "Bucket", newJString(Bucket))
  add(query_592180, "analytics", newJBool(analytics))
  add(query_592180, "id", newJString(id))
  result = call_592178.call(path_592179, query_592180, nil, nil, nil)

var deleteBucketAnalyticsConfiguration* = Call_DeleteBucketAnalyticsConfiguration_592170(
    name: "deleteBucketAnalyticsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics&id",
    validator: validate_DeleteBucketAnalyticsConfiguration_592171, base: "/",
    url: url_DeleteBucketAnalyticsConfiguration_592172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketCors_592191 = ref object of OpenApiRestCall_591364
proc url_PutBucketCors_592193(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketCors_592192(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592194 = path.getOrDefault("Bucket")
  valid_592194 = validateParameter(valid_592194, JString, required = true,
                                 default = nil)
  if valid_592194 != nil:
    section.add "Bucket", valid_592194
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_592195 = query.getOrDefault("cors")
  valid_592195 = validateParameter(valid_592195, JBool, required = true, default = nil)
  if valid_592195 != nil:
    section.add "cors", valid_592195
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_592196 = header.getOrDefault("x-amz-security-token")
  valid_592196 = validateParameter(valid_592196, JString, required = false,
                                 default = nil)
  if valid_592196 != nil:
    section.add "x-amz-security-token", valid_592196
  var valid_592197 = header.getOrDefault("Content-MD5")
  valid_592197 = validateParameter(valid_592197, JString, required = false,
                                 default = nil)
  if valid_592197 != nil:
    section.add "Content-MD5", valid_592197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592199: Call_PutBucketCors_592191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the CORS configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  let valid = call_592199.validator(path, query, header, formData, body)
  let scheme = call_592199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592199.url(scheme.get, call_592199.host, call_592199.base,
                         call_592199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592199, url, valid)

proc call*(call_592200: Call_PutBucketCors_592191; Bucket: string; body: JsonNode;
          cors: bool): Recallable =
  ## putBucketCors
  ## Sets the CORS configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   cors: bool (required)
  var path_592201 = newJObject()
  var query_592202 = newJObject()
  var body_592203 = newJObject()
  add(path_592201, "Bucket", newJString(Bucket))
  if body != nil:
    body_592203 = body
  add(query_592202, "cors", newJBool(cors))
  result = call_592200.call(path_592201, query_592202, nil, nil, body_592203)

var putBucketCors* = Call_PutBucketCors_592191(name: "putBucketCors",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_PutBucketCors_592192, base: "/", url: url_PutBucketCors_592193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketCors_592181 = ref object of OpenApiRestCall_591364
proc url_GetBucketCors_592183(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketCors_592182(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592184 = path.getOrDefault("Bucket")
  valid_592184 = validateParameter(valid_592184, JString, required = true,
                                 default = nil)
  if valid_592184 != nil:
    section.add "Bucket", valid_592184
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_592185 = query.getOrDefault("cors")
  valid_592185 = validateParameter(valid_592185, JBool, required = true, default = nil)
  if valid_592185 != nil:
    section.add "cors", valid_592185
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592186 = header.getOrDefault("x-amz-security-token")
  valid_592186 = validateParameter(valid_592186, JString, required = false,
                                 default = nil)
  if valid_592186 != nil:
    section.add "x-amz-security-token", valid_592186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592187: Call_GetBucketCors_592181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the CORS configuration for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  let valid = call_592187.validator(path, query, header, formData, body)
  let scheme = call_592187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592187.url(scheme.get, call_592187.host, call_592187.base,
                         call_592187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592187, url, valid)

proc call*(call_592188: Call_GetBucketCors_592181; Bucket: string; cors: bool): Recallable =
  ## getBucketCors
  ## Returns the CORS configuration for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   cors: bool (required)
  var path_592189 = newJObject()
  var query_592190 = newJObject()
  add(path_592189, "Bucket", newJString(Bucket))
  add(query_592190, "cors", newJBool(cors))
  result = call_592188.call(path_592189, query_592190, nil, nil, nil)

var getBucketCors* = Call_GetBucketCors_592181(name: "getBucketCors",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_GetBucketCors_592182, base: "/", url: url_GetBucketCors_592183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketCors_592204 = ref object of OpenApiRestCall_591364
proc url_DeleteBucketCors_592206(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketCors_592205(path: JsonNode; query: JsonNode;
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
  var valid_592207 = path.getOrDefault("Bucket")
  valid_592207 = validateParameter(valid_592207, JString, required = true,
                                 default = nil)
  if valid_592207 != nil:
    section.add "Bucket", valid_592207
  result.add "path", section
  ## parameters in `query` object:
  ##   cors: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `cors` field"
  var valid_592208 = query.getOrDefault("cors")
  valid_592208 = validateParameter(valid_592208, JBool, required = true, default = nil)
  if valid_592208 != nil:
    section.add "cors", valid_592208
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592209 = header.getOrDefault("x-amz-security-token")
  valid_592209 = validateParameter(valid_592209, JString, required = false,
                                 default = nil)
  if valid_592209 != nil:
    section.add "x-amz-security-token", valid_592209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592210: Call_DeleteBucketCors_592204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the CORS configuration information set for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  let valid = call_592210.validator(path, query, header, formData, body)
  let scheme = call_592210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592210.url(scheme.get, call_592210.host, call_592210.base,
                         call_592210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592210, url, valid)

proc call*(call_592211: Call_DeleteBucketCors_592204; Bucket: string; cors: bool): Recallable =
  ## deleteBucketCors
  ## Deletes the CORS configuration information set for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   cors: bool (required)
  var path_592212 = newJObject()
  var query_592213 = newJObject()
  add(path_592212, "Bucket", newJString(Bucket))
  add(query_592213, "cors", newJBool(cors))
  result = call_592211.call(path_592212, query_592213, nil, nil, nil)

var deleteBucketCors* = Call_DeleteBucketCors_592204(name: "deleteBucketCors",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}#cors",
    validator: validate_DeleteBucketCors_592205, base: "/",
    url: url_DeleteBucketCors_592206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketEncryption_592224 = ref object of OpenApiRestCall_591364
proc url_PutBucketEncryption_592226(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketEncryption_592225(path: JsonNode; query: JsonNode;
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
  var valid_592227 = path.getOrDefault("Bucket")
  valid_592227 = validateParameter(valid_592227, JString, required = true,
                                 default = nil)
  if valid_592227 != nil:
    section.add "Bucket", valid_592227
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_592228 = query.getOrDefault("encryption")
  valid_592228 = validateParameter(valid_592228, JBool, required = true, default = nil)
  if valid_592228 != nil:
    section.add "encryption", valid_592228
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the server-side encryption configuration. This parameter is auto-populated when using the command from the CLI.
  section = newJObject()
  var valid_592229 = header.getOrDefault("x-amz-security-token")
  valid_592229 = validateParameter(valid_592229, JString, required = false,
                                 default = nil)
  if valid_592229 != nil:
    section.add "x-amz-security-token", valid_592229
  var valid_592230 = header.getOrDefault("Content-MD5")
  valid_592230 = validateParameter(valid_592230, JString, required = false,
                                 default = nil)
  if valid_592230 != nil:
    section.add "Content-MD5", valid_592230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592232: Call_PutBucketEncryption_592224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ## 
  let valid = call_592232.validator(path, query, header, formData, body)
  let scheme = call_592232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592232.url(scheme.get, call_592232.host, call_592232.base,
                         call_592232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592232, url, valid)

proc call*(call_592233: Call_PutBucketEncryption_592224; Bucket: string;
          encryption: bool; body: JsonNode): Recallable =
  ## putBucketEncryption
  ## Creates a new server-side encryption configuration (or replaces an existing one, if present).
  ##   Bucket: string (required)
  ##         : Specifies default encryption for a bucket using server-side encryption with Amazon S3-managed keys (SSE-S3) or AWS KMS-managed keys (SSE-KMS). For information about the Amazon S3 default encryption feature, see <a 
  ## href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 Default Bucket Encryption</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   encryption: bool (required)
  ##   body: JObject (required)
  var path_592234 = newJObject()
  var query_592235 = newJObject()
  var body_592236 = newJObject()
  add(path_592234, "Bucket", newJString(Bucket))
  add(query_592235, "encryption", newJBool(encryption))
  if body != nil:
    body_592236 = body
  result = call_592233.call(path_592234, query_592235, nil, nil, body_592236)

var putBucketEncryption* = Call_PutBucketEncryption_592224(
    name: "putBucketEncryption", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_PutBucketEncryption_592225,
    base: "/", url: url_PutBucketEncryption_592226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketEncryption_592214 = ref object of OpenApiRestCall_591364
proc url_GetBucketEncryption_592216(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketEncryption_592215(path: JsonNode; query: JsonNode;
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
  var valid_592217 = path.getOrDefault("Bucket")
  valid_592217 = validateParameter(valid_592217, JString, required = true,
                                 default = nil)
  if valid_592217 != nil:
    section.add "Bucket", valid_592217
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_592218 = query.getOrDefault("encryption")
  valid_592218 = validateParameter(valid_592218, JBool, required = true, default = nil)
  if valid_592218 != nil:
    section.add "encryption", valid_592218
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592219 = header.getOrDefault("x-amz-security-token")
  valid_592219 = validateParameter(valid_592219, JString, required = false,
                                 default = nil)
  if valid_592219 != nil:
    section.add "x-amz-security-token", valid_592219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592220: Call_GetBucketEncryption_592214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the server-side encryption configuration of a bucket.
  ## 
  let valid = call_592220.validator(path, query, header, formData, body)
  let scheme = call_592220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592220.url(scheme.get, call_592220.host, call_592220.base,
                         call_592220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592220, url, valid)

proc call*(call_592221: Call_GetBucketEncryption_592214; Bucket: string;
          encryption: bool): Recallable =
  ## getBucketEncryption
  ## Returns the server-side encryption configuration of a bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket from which the server-side encryption configuration is retrieved.
  ##   encryption: bool (required)
  var path_592222 = newJObject()
  var query_592223 = newJObject()
  add(path_592222, "Bucket", newJString(Bucket))
  add(query_592223, "encryption", newJBool(encryption))
  result = call_592221.call(path_592222, query_592223, nil, nil, nil)

var getBucketEncryption* = Call_GetBucketEncryption_592214(
    name: "getBucketEncryption", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#encryption", validator: validate_GetBucketEncryption_592215,
    base: "/", url: url_GetBucketEncryption_592216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketEncryption_592237 = ref object of OpenApiRestCall_591364
proc url_DeleteBucketEncryption_592239(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketEncryption_592238(path: JsonNode; query: JsonNode;
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
  var valid_592240 = path.getOrDefault("Bucket")
  valid_592240 = validateParameter(valid_592240, JString, required = true,
                                 default = nil)
  if valid_592240 != nil:
    section.add "Bucket", valid_592240
  result.add "path", section
  ## parameters in `query` object:
  ##   encryption: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `encryption` field"
  var valid_592241 = query.getOrDefault("encryption")
  valid_592241 = validateParameter(valid_592241, JBool, required = true, default = nil)
  if valid_592241 != nil:
    section.add "encryption", valid_592241
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592242 = header.getOrDefault("x-amz-security-token")
  valid_592242 = validateParameter(valid_592242, JString, required = false,
                                 default = nil)
  if valid_592242 != nil:
    section.add "x-amz-security-token", valid_592242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592243: Call_DeleteBucketEncryption_592237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the server-side encryption configuration from the bucket.
  ## 
  let valid = call_592243.validator(path, query, header, formData, body)
  let scheme = call_592243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592243.url(scheme.get, call_592243.host, call_592243.base,
                         call_592243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592243, url, valid)

proc call*(call_592244: Call_DeleteBucketEncryption_592237; Bucket: string;
          encryption: bool): Recallable =
  ## deleteBucketEncryption
  ## Deletes the server-side encryption configuration from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the server-side encryption configuration to delete.
  ##   encryption: bool (required)
  var path_592245 = newJObject()
  var query_592246 = newJObject()
  add(path_592245, "Bucket", newJString(Bucket))
  add(query_592246, "encryption", newJBool(encryption))
  result = call_592244.call(path_592245, query_592246, nil, nil, nil)

var deleteBucketEncryption* = Call_DeleteBucketEncryption_592237(
    name: "deleteBucketEncryption", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#encryption",
    validator: validate_DeleteBucketEncryption_592238, base: "/",
    url: url_DeleteBucketEncryption_592239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketInventoryConfiguration_592258 = ref object of OpenApiRestCall_591364
proc url_PutBucketInventoryConfiguration_592260(protocol: Scheme; host: string;
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

proc validate_PutBucketInventoryConfiguration_592259(path: JsonNode;
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
  var valid_592261 = path.getOrDefault("Bucket")
  valid_592261 = validateParameter(valid_592261, JString, required = true,
                                 default = nil)
  if valid_592261 != nil:
    section.add "Bucket", valid_592261
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  ##   inventory: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_592262 = query.getOrDefault("id")
  valid_592262 = validateParameter(valid_592262, JString, required = true,
                                 default = nil)
  if valid_592262 != nil:
    section.add "id", valid_592262
  var valid_592263 = query.getOrDefault("inventory")
  valid_592263 = validateParameter(valid_592263, JBool, required = true, default = nil)
  if valid_592263 != nil:
    section.add "inventory", valid_592263
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592264 = header.getOrDefault("x-amz-security-token")
  valid_592264 = validateParameter(valid_592264, JString, required = false,
                                 default = nil)
  if valid_592264 != nil:
    section.add "x-amz-security-token", valid_592264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592266: Call_PutBucketInventoryConfiguration_592258;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_592266.validator(path, query, header, formData, body)
  let scheme = call_592266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592266.url(scheme.get, call_592266.host, call_592266.base,
                         call_592266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592266, url, valid)

proc call*(call_592267: Call_PutBucketInventoryConfiguration_592258;
          Bucket: string; id: string; body: JsonNode; inventory: bool): Recallable =
  ## putBucketInventoryConfiguration
  ## Adds an inventory configuration (identified by the inventory ID) from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket where the inventory configuration will be stored.
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   body: JObject (required)
  ##   inventory: bool (required)
  var path_592268 = newJObject()
  var query_592269 = newJObject()
  var body_592270 = newJObject()
  add(path_592268, "Bucket", newJString(Bucket))
  add(query_592269, "id", newJString(id))
  if body != nil:
    body_592270 = body
  add(query_592269, "inventory", newJBool(inventory))
  result = call_592267.call(path_592268, query_592269, nil, nil, body_592270)

var putBucketInventoryConfiguration* = Call_PutBucketInventoryConfiguration_592258(
    name: "putBucketInventoryConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_PutBucketInventoryConfiguration_592259, base: "/",
    url: url_PutBucketInventoryConfiguration_592260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketInventoryConfiguration_592247 = ref object of OpenApiRestCall_591364
proc url_GetBucketInventoryConfiguration_592249(protocol: Scheme; host: string;
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

proc validate_GetBucketInventoryConfiguration_592248(path: JsonNode;
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
  var valid_592250 = path.getOrDefault("Bucket")
  valid_592250 = validateParameter(valid_592250, JString, required = true,
                                 default = nil)
  if valid_592250 != nil:
    section.add "Bucket", valid_592250
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  ##   inventory: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_592251 = query.getOrDefault("id")
  valid_592251 = validateParameter(valid_592251, JString, required = true,
                                 default = nil)
  if valid_592251 != nil:
    section.add "id", valid_592251
  var valid_592252 = query.getOrDefault("inventory")
  valid_592252 = validateParameter(valid_592252, JBool, required = true, default = nil)
  if valid_592252 != nil:
    section.add "inventory", valid_592252
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592253 = header.getOrDefault("x-amz-security-token")
  valid_592253 = validateParameter(valid_592253, JString, required = false,
                                 default = nil)
  if valid_592253 != nil:
    section.add "x-amz-security-token", valid_592253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592254: Call_GetBucketInventoryConfiguration_592247;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_592254.validator(path, query, header, formData, body)
  let scheme = call_592254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592254.url(scheme.get, call_592254.host, call_592254.base,
                         call_592254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592254, url, valid)

proc call*(call_592255: Call_GetBucketInventoryConfiguration_592247;
          Bucket: string; id: string; inventory: bool): Recallable =
  ## getBucketInventoryConfiguration
  ## Returns an inventory configuration (identified by the inventory ID) from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to retrieve.
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   inventory: bool (required)
  var path_592256 = newJObject()
  var query_592257 = newJObject()
  add(path_592256, "Bucket", newJString(Bucket))
  add(query_592257, "id", newJString(id))
  add(query_592257, "inventory", newJBool(inventory))
  result = call_592255.call(path_592256, query_592257, nil, nil, nil)

var getBucketInventoryConfiguration* = Call_GetBucketInventoryConfiguration_592247(
    name: "getBucketInventoryConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_GetBucketInventoryConfiguration_592248, base: "/",
    url: url_GetBucketInventoryConfiguration_592249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketInventoryConfiguration_592271 = ref object of OpenApiRestCall_591364
proc url_DeleteBucketInventoryConfiguration_592273(protocol: Scheme; host: string;
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

proc validate_DeleteBucketInventoryConfiguration_592272(path: JsonNode;
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
  var valid_592274 = path.getOrDefault("Bucket")
  valid_592274 = validateParameter(valid_592274, JString, required = true,
                                 default = nil)
  if valid_592274 != nil:
    section.add "Bucket", valid_592274
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID used to identify the inventory configuration.
  ##   inventory: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_592275 = query.getOrDefault("id")
  valid_592275 = validateParameter(valid_592275, JString, required = true,
                                 default = nil)
  if valid_592275 != nil:
    section.add "id", valid_592275
  var valid_592276 = query.getOrDefault("inventory")
  valid_592276 = validateParameter(valid_592276, JBool, required = true, default = nil)
  if valid_592276 != nil:
    section.add "inventory", valid_592276
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592277 = header.getOrDefault("x-amz-security-token")
  valid_592277 = validateParameter(valid_592277, JString, required = false,
                                 default = nil)
  if valid_592277 != nil:
    section.add "x-amz-security-token", valid_592277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592278: Call_DeleteBucketInventoryConfiguration_592271;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ## 
  let valid = call_592278.validator(path, query, header, formData, body)
  let scheme = call_592278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592278.url(scheme.get, call_592278.host, call_592278.base,
                         call_592278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592278, url, valid)

proc call*(call_592279: Call_DeleteBucketInventoryConfiguration_592271;
          Bucket: string; id: string; inventory: bool): Recallable =
  ## deleteBucketInventoryConfiguration
  ## Deletes an inventory configuration (identified by the inventory ID) from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configuration to delete.
  ##   id: string (required)
  ##     : The ID used to identify the inventory configuration.
  ##   inventory: bool (required)
  var path_592280 = newJObject()
  var query_592281 = newJObject()
  add(path_592280, "Bucket", newJString(Bucket))
  add(query_592281, "id", newJString(id))
  add(query_592281, "inventory", newJBool(inventory))
  result = call_592279.call(path_592280, query_592281, nil, nil, nil)

var deleteBucketInventoryConfiguration* = Call_DeleteBucketInventoryConfiguration_592271(
    name: "deleteBucketInventoryConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory&id",
    validator: validate_DeleteBucketInventoryConfiguration_592272, base: "/",
    url: url_DeleteBucketInventoryConfiguration_592273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycleConfiguration_592292 = ref object of OpenApiRestCall_591364
proc url_PutBucketLifecycleConfiguration_592294(protocol: Scheme; host: string;
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

proc validate_PutBucketLifecycleConfiguration_592293(path: JsonNode;
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
  var valid_592295 = path.getOrDefault("Bucket")
  valid_592295 = validateParameter(valid_592295, JString, required = true,
                                 default = nil)
  if valid_592295 != nil:
    section.add "Bucket", valid_592295
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_592296 = query.getOrDefault("lifecycle")
  valid_592296 = validateParameter(valid_592296, JBool, required = true, default = nil)
  if valid_592296 != nil:
    section.add "lifecycle", valid_592296
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592297 = header.getOrDefault("x-amz-security-token")
  valid_592297 = validateParameter(valid_592297, JString, required = false,
                                 default = nil)
  if valid_592297 != nil:
    section.add "x-amz-security-token", valid_592297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592299: Call_PutBucketLifecycleConfiguration_592292;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ## 
  let valid = call_592299.validator(path, query, header, formData, body)
  let scheme = call_592299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592299.url(scheme.get, call_592299.host, call_592299.base,
                         call_592299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592299, url, valid)

proc call*(call_592300: Call_PutBucketLifecycleConfiguration_592292;
          Bucket: string; body: JsonNode; lifecycle: bool): Recallable =
  ## putBucketLifecycleConfiguration
  ## Sets lifecycle configuration for your bucket. If a lifecycle configuration exists, it replaces it.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   lifecycle: bool (required)
  var path_592301 = newJObject()
  var query_592302 = newJObject()
  var body_592303 = newJObject()
  add(path_592301, "Bucket", newJString(Bucket))
  if body != nil:
    body_592303 = body
  add(query_592302, "lifecycle", newJBool(lifecycle))
  result = call_592300.call(path_592301, query_592302, nil, nil, body_592303)

var putBucketLifecycleConfiguration* = Call_PutBucketLifecycleConfiguration_592292(
    name: "putBucketLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_PutBucketLifecycleConfiguration_592293, base: "/",
    url: url_PutBucketLifecycleConfiguration_592294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycleConfiguration_592282 = ref object of OpenApiRestCall_591364
proc url_GetBucketLifecycleConfiguration_592284(protocol: Scheme; host: string;
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

proc validate_GetBucketLifecycleConfiguration_592283(path: JsonNode;
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
  var valid_592285 = path.getOrDefault("Bucket")
  valid_592285 = validateParameter(valid_592285, JString, required = true,
                                 default = nil)
  if valid_592285 != nil:
    section.add "Bucket", valid_592285
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_592286 = query.getOrDefault("lifecycle")
  valid_592286 = validateParameter(valid_592286, JBool, required = true, default = nil)
  if valid_592286 != nil:
    section.add "lifecycle", valid_592286
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592287 = header.getOrDefault("x-amz-security-token")
  valid_592287 = validateParameter(valid_592287, JString, required = false,
                                 default = nil)
  if valid_592287 != nil:
    section.add "x-amz-security-token", valid_592287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592288: Call_GetBucketLifecycleConfiguration_592282;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the lifecycle configuration information set on the bucket.
  ## 
  let valid = call_592288.validator(path, query, header, formData, body)
  let scheme = call_592288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592288.url(scheme.get, call_592288.host, call_592288.base,
                         call_592288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592288, url, valid)

proc call*(call_592289: Call_GetBucketLifecycleConfiguration_592282;
          Bucket: string; lifecycle: bool): Recallable =
  ## getBucketLifecycleConfiguration
  ## Returns the lifecycle configuration information set on the bucket.
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_592290 = newJObject()
  var query_592291 = newJObject()
  add(path_592290, "Bucket", newJString(Bucket))
  add(query_592291, "lifecycle", newJBool(lifecycle))
  result = call_592289.call(path_592290, query_592291, nil, nil, nil)

var getBucketLifecycleConfiguration* = Call_GetBucketLifecycleConfiguration_592282(
    name: "getBucketLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_GetBucketLifecycleConfiguration_592283, base: "/",
    url: url_GetBucketLifecycleConfiguration_592284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketLifecycle_592304 = ref object of OpenApiRestCall_591364
proc url_DeleteBucketLifecycle_592306(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketLifecycle_592305(path: JsonNode; query: JsonNode;
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
  var valid_592307 = path.getOrDefault("Bucket")
  valid_592307 = validateParameter(valid_592307, JString, required = true,
                                 default = nil)
  if valid_592307 != nil:
    section.add "Bucket", valid_592307
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_592308 = query.getOrDefault("lifecycle")
  valid_592308 = validateParameter(valid_592308, JBool, required = true, default = nil)
  if valid_592308 != nil:
    section.add "lifecycle", valid_592308
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592309 = header.getOrDefault("x-amz-security-token")
  valid_592309 = validateParameter(valid_592309, JString, required = false,
                                 default = nil)
  if valid_592309 != nil:
    section.add "x-amz-security-token", valid_592309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592310: Call_DeleteBucketLifecycle_592304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the lifecycle configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  let valid = call_592310.validator(path, query, header, formData, body)
  let scheme = call_592310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592310.url(scheme.get, call_592310.host, call_592310.base,
                         call_592310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592310, url, valid)

proc call*(call_592311: Call_DeleteBucketLifecycle_592304; Bucket: string;
          lifecycle: bool): Recallable =
  ## deleteBucketLifecycle
  ## Deletes the lifecycle configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_592312 = newJObject()
  var query_592313 = newJObject()
  add(path_592312, "Bucket", newJString(Bucket))
  add(query_592313, "lifecycle", newJBool(lifecycle))
  result = call_592311.call(path_592312, query_592313, nil, nil, nil)

var deleteBucketLifecycle* = Call_DeleteBucketLifecycle_592304(
    name: "deleteBucketLifecycle", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#lifecycle",
    validator: validate_DeleteBucketLifecycle_592305, base: "/",
    url: url_DeleteBucketLifecycle_592306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketMetricsConfiguration_592325 = ref object of OpenApiRestCall_591364
proc url_PutBucketMetricsConfiguration_592327(protocol: Scheme; host: string;
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

proc validate_PutBucketMetricsConfiguration_592326(path: JsonNode; query: JsonNode;
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
  var valid_592328 = path.getOrDefault("Bucket")
  valid_592328 = validateParameter(valid_592328, JString, required = true,
                                 default = nil)
  if valid_592328 != nil:
    section.add "Bucket", valid_592328
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_592329 = query.getOrDefault("metrics")
  valid_592329 = validateParameter(valid_592329, JBool, required = true, default = nil)
  if valid_592329 != nil:
    section.add "metrics", valid_592329
  var valid_592330 = query.getOrDefault("id")
  valid_592330 = validateParameter(valid_592330, JString, required = true,
                                 default = nil)
  if valid_592330 != nil:
    section.add "id", valid_592330
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592331 = header.getOrDefault("x-amz-security-token")
  valid_592331 = validateParameter(valid_592331, JString, required = false,
                                 default = nil)
  if valid_592331 != nil:
    section.add "x-amz-security-token", valid_592331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592333: Call_PutBucketMetricsConfiguration_592325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ## 
  let valid = call_592333.validator(path, query, header, formData, body)
  let scheme = call_592333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592333.url(scheme.get, call_592333.host, call_592333.base,
                         call_592333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592333, url, valid)

proc call*(call_592334: Call_PutBucketMetricsConfiguration_592325; Bucket: string;
          metrics: bool; id: string; body: JsonNode): Recallable =
  ## putBucketMetricsConfiguration
  ## Sets a metrics configuration (specified by the metrics configuration ID) for the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket for which the metrics configuration is set.
  ##   metrics: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  ##   body: JObject (required)
  var path_592335 = newJObject()
  var query_592336 = newJObject()
  var body_592337 = newJObject()
  add(path_592335, "Bucket", newJString(Bucket))
  add(query_592336, "metrics", newJBool(metrics))
  add(query_592336, "id", newJString(id))
  if body != nil:
    body_592337 = body
  result = call_592334.call(path_592335, query_592336, nil, nil, body_592337)

var putBucketMetricsConfiguration* = Call_PutBucketMetricsConfiguration_592325(
    name: "putBucketMetricsConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_PutBucketMetricsConfiguration_592326, base: "/",
    url: url_PutBucketMetricsConfiguration_592327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketMetricsConfiguration_592314 = ref object of OpenApiRestCall_591364
proc url_GetBucketMetricsConfiguration_592316(protocol: Scheme; host: string;
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

proc validate_GetBucketMetricsConfiguration_592315(path: JsonNode; query: JsonNode;
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
  var valid_592317 = path.getOrDefault("Bucket")
  valid_592317 = validateParameter(valid_592317, JString, required = true,
                                 default = nil)
  if valid_592317 != nil:
    section.add "Bucket", valid_592317
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_592318 = query.getOrDefault("metrics")
  valid_592318 = validateParameter(valid_592318, JBool, required = true, default = nil)
  if valid_592318 != nil:
    section.add "metrics", valid_592318
  var valid_592319 = query.getOrDefault("id")
  valid_592319 = validateParameter(valid_592319, JString, required = true,
                                 default = nil)
  if valid_592319 != nil:
    section.add "id", valid_592319
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592320 = header.getOrDefault("x-amz-security-token")
  valid_592320 = validateParameter(valid_592320, JString, required = false,
                                 default = nil)
  if valid_592320 != nil:
    section.add "x-amz-security-token", valid_592320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592321: Call_GetBucketMetricsConfiguration_592314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_592321.validator(path, query, header, formData, body)
  let scheme = call_592321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592321.url(scheme.get, call_592321.host, call_592321.base,
                         call_592321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592321, url, valid)

proc call*(call_592322: Call_GetBucketMetricsConfiguration_592314; Bucket: string;
          metrics: bool; id: string): Recallable =
  ## getBucketMetricsConfiguration
  ## Gets a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to retrieve.
  ##   metrics: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  var path_592323 = newJObject()
  var query_592324 = newJObject()
  add(path_592323, "Bucket", newJString(Bucket))
  add(query_592324, "metrics", newJBool(metrics))
  add(query_592324, "id", newJString(id))
  result = call_592322.call(path_592323, query_592324, nil, nil, nil)

var getBucketMetricsConfiguration* = Call_GetBucketMetricsConfiguration_592314(
    name: "getBucketMetricsConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_GetBucketMetricsConfiguration_592315, base: "/",
    url: url_GetBucketMetricsConfiguration_592316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketMetricsConfiguration_592338 = ref object of OpenApiRestCall_591364
proc url_DeleteBucketMetricsConfiguration_592340(protocol: Scheme; host: string;
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

proc validate_DeleteBucketMetricsConfiguration_592339(path: JsonNode;
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
  var valid_592341 = path.getOrDefault("Bucket")
  valid_592341 = validateParameter(valid_592341, JString, required = true,
                                 default = nil)
  if valid_592341 != nil:
    section.add "Bucket", valid_592341
  result.add "path", section
  ## parameters in `query` object:
  ##   metrics: JBool (required)
  ##   id: JString (required)
  ##     : The ID used to identify the metrics configuration.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_592342 = query.getOrDefault("metrics")
  valid_592342 = validateParameter(valid_592342, JBool, required = true, default = nil)
  if valid_592342 != nil:
    section.add "metrics", valid_592342
  var valid_592343 = query.getOrDefault("id")
  valid_592343 = validateParameter(valid_592343, JString, required = true,
                                 default = nil)
  if valid_592343 != nil:
    section.add "id", valid_592343
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592344 = header.getOrDefault("x-amz-security-token")
  valid_592344 = validateParameter(valid_592344, JString, required = false,
                                 default = nil)
  if valid_592344 != nil:
    section.add "x-amz-security-token", valid_592344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592345: Call_DeleteBucketMetricsConfiguration_592338;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ## 
  let valid = call_592345.validator(path, query, header, formData, body)
  let scheme = call_592345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592345.url(scheme.get, call_592345.host, call_592345.base,
                         call_592345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592345, url, valid)

proc call*(call_592346: Call_DeleteBucketMetricsConfiguration_592338;
          Bucket: string; metrics: bool; id: string): Recallable =
  ## deleteBucketMetricsConfiguration
  ## Deletes a metrics configuration (specified by the metrics configuration ID) from the bucket.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configuration to delete.
  ##   metrics: bool (required)
  ##   id: string (required)
  ##     : The ID used to identify the metrics configuration.
  var path_592347 = newJObject()
  var query_592348 = newJObject()
  add(path_592347, "Bucket", newJString(Bucket))
  add(query_592348, "metrics", newJBool(metrics))
  add(query_592348, "id", newJString(id))
  result = call_592346.call(path_592347, query_592348, nil, nil, nil)

var deleteBucketMetricsConfiguration* = Call_DeleteBucketMetricsConfiguration_592338(
    name: "deleteBucketMetricsConfiguration", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics&id",
    validator: validate_DeleteBucketMetricsConfiguration_592339, base: "/",
    url: url_DeleteBucketMetricsConfiguration_592340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketPolicy_592359 = ref object of OpenApiRestCall_591364
proc url_PutBucketPolicy_592361(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketPolicy_592360(path: JsonNode; query: JsonNode;
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
  var valid_592362 = path.getOrDefault("Bucket")
  valid_592362 = validateParameter(valid_592362, JString, required = true,
                                 default = nil)
  if valid_592362 != nil:
    section.add "Bucket", valid_592362
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_592363 = query.getOrDefault("policy")
  valid_592363 = validateParameter(valid_592363, JBool, required = true, default = nil)
  if valid_592363 != nil:
    section.add "policy", valid_592363
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-confirm-remove-self-bucket-access: JBool
  ##                                          : Set this parameter to true to confirm that you want to remove your permissions to change this bucket policy in the future.
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_592364 = header.getOrDefault("x-amz-confirm-remove-self-bucket-access")
  valid_592364 = validateParameter(valid_592364, JBool, required = false, default = nil)
  if valid_592364 != nil:
    section.add "x-amz-confirm-remove-self-bucket-access", valid_592364
  var valid_592365 = header.getOrDefault("x-amz-security-token")
  valid_592365 = validateParameter(valid_592365, JString, required = false,
                                 default = nil)
  if valid_592365 != nil:
    section.add "x-amz-security-token", valid_592365
  var valid_592366 = header.getOrDefault("Content-MD5")
  valid_592366 = validateParameter(valid_592366, JString, required = false,
                                 default = nil)
  if valid_592366 != nil:
    section.add "Content-MD5", valid_592366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592368: Call_PutBucketPolicy_592359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  let valid = call_592368.validator(path, query, header, formData, body)
  let scheme = call_592368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592368.url(scheme.get, call_592368.host, call_592368.base,
                         call_592368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592368, url, valid)

proc call*(call_592369: Call_PutBucketPolicy_592359; Bucket: string; body: JsonNode;
          policy: bool): Recallable =
  ## putBucketPolicy
  ## Applies an Amazon S3 bucket policy to an Amazon S3 bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   policy: bool (required)
  var path_592370 = newJObject()
  var query_592371 = newJObject()
  var body_592372 = newJObject()
  add(path_592370, "Bucket", newJString(Bucket))
  if body != nil:
    body_592372 = body
  add(query_592371, "policy", newJBool(policy))
  result = call_592369.call(path_592370, query_592371, nil, nil, body_592372)

var putBucketPolicy* = Call_PutBucketPolicy_592359(name: "putBucketPolicy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_PutBucketPolicy_592360, base: "/", url: url_PutBucketPolicy_592361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicy_592349 = ref object of OpenApiRestCall_591364
proc url_GetBucketPolicy_592351(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketPolicy_592350(path: JsonNode; query: JsonNode;
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
  var valid_592352 = path.getOrDefault("Bucket")
  valid_592352 = validateParameter(valid_592352, JString, required = true,
                                 default = nil)
  if valid_592352 != nil:
    section.add "Bucket", valid_592352
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_592353 = query.getOrDefault("policy")
  valid_592353 = validateParameter(valid_592353, JBool, required = true, default = nil)
  if valid_592353 != nil:
    section.add "policy", valid_592353
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592354 = header.getOrDefault("x-amz-security-token")
  valid_592354 = validateParameter(valid_592354, JString, required = false,
                                 default = nil)
  if valid_592354 != nil:
    section.add "x-amz-security-token", valid_592354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592355: Call_GetBucketPolicy_592349; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the policy of a specified bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  let valid = call_592355.validator(path, query, header, formData, body)
  let scheme = call_592355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592355.url(scheme.get, call_592355.host, call_592355.base,
                         call_592355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592355, url, valid)

proc call*(call_592356: Call_GetBucketPolicy_592349; Bucket: string; policy: bool): Recallable =
  ## getBucketPolicy
  ## Returns the policy of a specified bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   policy: bool (required)
  var path_592357 = newJObject()
  var query_592358 = newJObject()
  add(path_592357, "Bucket", newJString(Bucket))
  add(query_592358, "policy", newJBool(policy))
  result = call_592356.call(path_592357, query_592358, nil, nil, nil)

var getBucketPolicy* = Call_GetBucketPolicy_592349(name: "getBucketPolicy",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_GetBucketPolicy_592350, base: "/", url: url_GetBucketPolicy_592351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketPolicy_592373 = ref object of OpenApiRestCall_591364
proc url_DeleteBucketPolicy_592375(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketPolicy_592374(path: JsonNode; query: JsonNode;
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
  var valid_592376 = path.getOrDefault("Bucket")
  valid_592376 = validateParameter(valid_592376, JString, required = true,
                                 default = nil)
  if valid_592376 != nil:
    section.add "Bucket", valid_592376
  result.add "path", section
  ## parameters in `query` object:
  ##   policy: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `policy` field"
  var valid_592377 = query.getOrDefault("policy")
  valid_592377 = validateParameter(valid_592377, JBool, required = true, default = nil)
  if valid_592377 != nil:
    section.add "policy", valid_592377
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592378 = header.getOrDefault("x-amz-security-token")
  valid_592378 = validateParameter(valid_592378, JString, required = false,
                                 default = nil)
  if valid_592378 != nil:
    section.add "x-amz-security-token", valid_592378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592379: Call_DeleteBucketPolicy_592373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  let valid = call_592379.validator(path, query, header, formData, body)
  let scheme = call_592379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592379.url(scheme.get, call_592379.host, call_592379.base,
                         call_592379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592379, url, valid)

proc call*(call_592380: Call_DeleteBucketPolicy_592373; Bucket: string; policy: bool): Recallable =
  ## deleteBucketPolicy
  ## Deletes the policy from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   policy: bool (required)
  var path_592381 = newJObject()
  var query_592382 = newJObject()
  add(path_592381, "Bucket", newJString(Bucket))
  add(query_592382, "policy", newJBool(policy))
  result = call_592380.call(path_592381, query_592382, nil, nil, nil)

var deleteBucketPolicy* = Call_DeleteBucketPolicy_592373(
    name: "deleteBucketPolicy", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#policy",
    validator: validate_DeleteBucketPolicy_592374, base: "/",
    url: url_DeleteBucketPolicy_592375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketReplication_592393 = ref object of OpenApiRestCall_591364
proc url_PutBucketReplication_592395(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketReplication_592394(path: JsonNode; query: JsonNode;
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
  var valid_592396 = path.getOrDefault("Bucket")
  valid_592396 = validateParameter(valid_592396, JString, required = true,
                                 default = nil)
  if valid_592396 != nil:
    section.add "Bucket", valid_592396
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_592397 = query.getOrDefault("replication")
  valid_592397 = validateParameter(valid_592397, JBool, required = true, default = nil)
  if valid_592397 != nil:
    section.add "replication", valid_592397
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-bucket-object-lock-token: JString
  ##                                 : A token that allows Amazon S3 object lock to be enabled for an existing bucket.
  ##   Content-MD5: JString
  ##              : The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit.
  section = newJObject()
  var valid_592398 = header.getOrDefault("x-amz-security-token")
  valid_592398 = validateParameter(valid_592398, JString, required = false,
                                 default = nil)
  if valid_592398 != nil:
    section.add "x-amz-security-token", valid_592398
  var valid_592399 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_592399 = validateParameter(valid_592399, JString, required = false,
                                 default = nil)
  if valid_592399 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_592399
  var valid_592400 = header.getOrDefault("Content-MD5")
  valid_592400 = validateParameter(valid_592400, JString, required = false,
                                 default = nil)
  if valid_592400 != nil:
    section.add "Content-MD5", valid_592400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592402: Call_PutBucketReplication_592393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_592402.validator(path, query, header, formData, body)
  let scheme = call_592402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592402.url(scheme.get, call_592402.host, call_592402.base,
                         call_592402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592402, url, valid)

proc call*(call_592403: Call_PutBucketReplication_592393; Bucket: string;
          replication: bool; body: JsonNode): Recallable =
  ## putBucketReplication
  ##  Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   Bucket: string (required)
  ##         : <p/>
  ##   replication: bool (required)
  ##   body: JObject (required)
  var path_592404 = newJObject()
  var query_592405 = newJObject()
  var body_592406 = newJObject()
  add(path_592404, "Bucket", newJString(Bucket))
  add(query_592405, "replication", newJBool(replication))
  if body != nil:
    body_592406 = body
  result = call_592403.call(path_592404, query_592405, nil, nil, body_592406)

var putBucketReplication* = Call_PutBucketReplication_592393(
    name: "putBucketReplication", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_PutBucketReplication_592394, base: "/",
    url: url_PutBucketReplication_592395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketReplication_592383 = ref object of OpenApiRestCall_591364
proc url_GetBucketReplication_592385(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketReplication_592384(path: JsonNode; query: JsonNode;
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
  var valid_592386 = path.getOrDefault("Bucket")
  valid_592386 = validateParameter(valid_592386, JString, required = true,
                                 default = nil)
  if valid_592386 != nil:
    section.add "Bucket", valid_592386
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_592387 = query.getOrDefault("replication")
  valid_592387 = validateParameter(valid_592387, JBool, required = true, default = nil)
  if valid_592387 != nil:
    section.add "replication", valid_592387
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592388 = header.getOrDefault("x-amz-security-token")
  valid_592388 = validateParameter(valid_592388, JString, required = false,
                                 default = nil)
  if valid_592388 != nil:
    section.add "x-amz-security-token", valid_592388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592389: Call_GetBucketReplication_592383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ## 
  let valid = call_592389.validator(path, query, header, formData, body)
  let scheme = call_592389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592389.url(scheme.get, call_592389.host, call_592389.base,
                         call_592389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592389, url, valid)

proc call*(call_592390: Call_GetBucketReplication_592383; Bucket: string;
          replication: bool): Recallable =
  ## getBucketReplication
  ## <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note>
  ##   Bucket: string (required)
  ##         : <p/>
  ##   replication: bool (required)
  var path_592391 = newJObject()
  var query_592392 = newJObject()
  add(path_592391, "Bucket", newJString(Bucket))
  add(query_592392, "replication", newJBool(replication))
  result = call_592390.call(path_592391, query_592392, nil, nil, nil)

var getBucketReplication* = Call_GetBucketReplication_592383(
    name: "getBucketReplication", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_GetBucketReplication_592384, base: "/",
    url: url_GetBucketReplication_592385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketReplication_592407 = ref object of OpenApiRestCall_591364
proc url_DeleteBucketReplication_592409(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketReplication_592408(path: JsonNode; query: JsonNode;
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
  var valid_592410 = path.getOrDefault("Bucket")
  valid_592410 = validateParameter(valid_592410, JString, required = true,
                                 default = nil)
  if valid_592410 != nil:
    section.add "Bucket", valid_592410
  result.add "path", section
  ## parameters in `query` object:
  ##   replication: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `replication` field"
  var valid_592411 = query.getOrDefault("replication")
  valid_592411 = validateParameter(valid_592411, JBool, required = true, default = nil)
  if valid_592411 != nil:
    section.add "replication", valid_592411
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592412 = header.getOrDefault("x-amz-security-token")
  valid_592412 = validateParameter(valid_592412, JString, required = false,
                                 default = nil)
  if valid_592412 != nil:
    section.add "x-amz-security-token", valid_592412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592413: Call_DeleteBucketReplication_592407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ## 
  let valid = call_592413.validator(path, query, header, formData, body)
  let scheme = call_592413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592413.url(scheme.get, call_592413.host, call_592413.base,
                         call_592413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592413, url, valid)

proc call*(call_592414: Call_DeleteBucketReplication_592407; Bucket: string;
          replication: bool): Recallable =
  ## deleteBucketReplication
  ##  Deletes the replication configuration from the bucket. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html">Cross-Region Replication (CRR)</a> in the <i>Amazon S3 Developer Guide</i>. 
  ##   Bucket: string (required)
  ##         : <p> The bucket name. </p> <note> <p>It can take a while to propagate the deletion of a replication configuration to all Amazon S3 systems.</p> </note>
  ##   replication: bool (required)
  var path_592415 = newJObject()
  var query_592416 = newJObject()
  add(path_592415, "Bucket", newJString(Bucket))
  add(query_592416, "replication", newJBool(replication))
  result = call_592414.call(path_592415, query_592416, nil, nil, nil)

var deleteBucketReplication* = Call_DeleteBucketReplication_592407(
    name: "deleteBucketReplication", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#replication",
    validator: validate_DeleteBucketReplication_592408, base: "/",
    url: url_DeleteBucketReplication_592409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketTagging_592427 = ref object of OpenApiRestCall_591364
proc url_PutBucketTagging_592429(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketTagging_592428(path: JsonNode; query: JsonNode;
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
  var valid_592430 = path.getOrDefault("Bucket")
  valid_592430 = validateParameter(valid_592430, JString, required = true,
                                 default = nil)
  if valid_592430 != nil:
    section.add "Bucket", valid_592430
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_592431 = query.getOrDefault("tagging")
  valid_592431 = validateParameter(valid_592431, JBool, required = true, default = nil)
  if valid_592431 != nil:
    section.add "tagging", valid_592431
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_592432 = header.getOrDefault("x-amz-security-token")
  valid_592432 = validateParameter(valid_592432, JString, required = false,
                                 default = nil)
  if valid_592432 != nil:
    section.add "x-amz-security-token", valid_592432
  var valid_592433 = header.getOrDefault("Content-MD5")
  valid_592433 = validateParameter(valid_592433, JString, required = false,
                                 default = nil)
  if valid_592433 != nil:
    section.add "Content-MD5", valid_592433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592435: Call_PutBucketTagging_592427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the tags for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  let valid = call_592435.validator(path, query, header, formData, body)
  let scheme = call_592435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592435.url(scheme.get, call_592435.host, call_592435.base,
                         call_592435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592435, url, valid)

proc call*(call_592436: Call_PutBucketTagging_592427; tagging: bool; Bucket: string;
          body: JsonNode): Recallable =
  ## putBucketTagging
  ## Sets the tags for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_592437 = newJObject()
  var query_592438 = newJObject()
  var body_592439 = newJObject()
  add(query_592438, "tagging", newJBool(tagging))
  add(path_592437, "Bucket", newJString(Bucket))
  if body != nil:
    body_592439 = body
  result = call_592436.call(path_592437, query_592438, nil, nil, body_592439)

var putBucketTagging* = Call_PutBucketTagging_592427(name: "putBucketTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_PutBucketTagging_592428, base: "/",
    url: url_PutBucketTagging_592429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketTagging_592417 = ref object of OpenApiRestCall_591364
proc url_GetBucketTagging_592419(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketTagging_592418(path: JsonNode; query: JsonNode;
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
  var valid_592420 = path.getOrDefault("Bucket")
  valid_592420 = validateParameter(valid_592420, JString, required = true,
                                 default = nil)
  if valid_592420 != nil:
    section.add "Bucket", valid_592420
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_592421 = query.getOrDefault("tagging")
  valid_592421 = validateParameter(valid_592421, JBool, required = true, default = nil)
  if valid_592421 != nil:
    section.add "tagging", valid_592421
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592422 = header.getOrDefault("x-amz-security-token")
  valid_592422 = validateParameter(valid_592422, JString, required = false,
                                 default = nil)
  if valid_592422 != nil:
    section.add "x-amz-security-token", valid_592422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592423: Call_GetBucketTagging_592417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag set associated with the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  let valid = call_592423.validator(path, query, header, formData, body)
  let scheme = call_592423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592423.url(scheme.get, call_592423.host, call_592423.base,
                         call_592423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592423, url, valid)

proc call*(call_592424: Call_GetBucketTagging_592417; tagging: bool; Bucket: string): Recallable =
  ## getBucketTagging
  ## Returns the tag set associated with the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_592425 = newJObject()
  var query_592426 = newJObject()
  add(query_592426, "tagging", newJBool(tagging))
  add(path_592425, "Bucket", newJString(Bucket))
  result = call_592424.call(path_592425, query_592426, nil, nil, nil)

var getBucketTagging* = Call_GetBucketTagging_592417(name: "getBucketTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_GetBucketTagging_592418, base: "/",
    url: url_GetBucketTagging_592419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketTagging_592440 = ref object of OpenApiRestCall_591364
proc url_DeleteBucketTagging_592442(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketTagging_592441(path: JsonNode; query: JsonNode;
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
  var valid_592443 = path.getOrDefault("Bucket")
  valid_592443 = validateParameter(valid_592443, JString, required = true,
                                 default = nil)
  if valid_592443 != nil:
    section.add "Bucket", valid_592443
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_592444 = query.getOrDefault("tagging")
  valid_592444 = validateParameter(valid_592444, JBool, required = true, default = nil)
  if valid_592444 != nil:
    section.add "tagging", valid_592444
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592445 = header.getOrDefault("x-amz-security-token")
  valid_592445 = validateParameter(valid_592445, JString, required = false,
                                 default = nil)
  if valid_592445 != nil:
    section.add "x-amz-security-token", valid_592445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592446: Call_DeleteBucketTagging_592440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the tags from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  let valid = call_592446.validator(path, query, header, formData, body)
  let scheme = call_592446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592446.url(scheme.get, call_592446.host, call_592446.base,
                         call_592446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592446, url, valid)

proc call*(call_592447: Call_DeleteBucketTagging_592440; tagging: bool;
          Bucket: string): Recallable =
  ## deleteBucketTagging
  ## Deletes the tags from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
  ##   tagging: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_592448 = newJObject()
  var query_592449 = newJObject()
  add(query_592449, "tagging", newJBool(tagging))
  add(path_592448, "Bucket", newJString(Bucket))
  result = call_592447.call(path_592448, query_592449, nil, nil, nil)

var deleteBucketTagging* = Call_DeleteBucketTagging_592440(
    name: "deleteBucketTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#tagging",
    validator: validate_DeleteBucketTagging_592441, base: "/",
    url: url_DeleteBucketTagging_592442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketWebsite_592460 = ref object of OpenApiRestCall_591364
proc url_PutBucketWebsite_592462(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketWebsite_592461(path: JsonNode; query: JsonNode;
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
  var valid_592463 = path.getOrDefault("Bucket")
  valid_592463 = validateParameter(valid_592463, JString, required = true,
                                 default = nil)
  if valid_592463 != nil:
    section.add "Bucket", valid_592463
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_592464 = query.getOrDefault("website")
  valid_592464 = validateParameter(valid_592464, JBool, required = true, default = nil)
  if valid_592464 != nil:
    section.add "website", valid_592464
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_592465 = header.getOrDefault("x-amz-security-token")
  valid_592465 = validateParameter(valid_592465, JString, required = false,
                                 default = nil)
  if valid_592465 != nil:
    section.add "x-amz-security-token", valid_592465
  var valid_592466 = header.getOrDefault("Content-MD5")
  valid_592466 = validateParameter(valid_592466, JString, required = false,
                                 default = nil)
  if valid_592466 != nil:
    section.add "Content-MD5", valid_592466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592468: Call_PutBucketWebsite_592460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  let valid = call_592468.validator(path, query, header, formData, body)
  let scheme = call_592468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592468.url(scheme.get, call_592468.host, call_592468.base,
                         call_592468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592468, url, valid)

proc call*(call_592469: Call_PutBucketWebsite_592460; Bucket: string; website: bool;
          body: JsonNode): Recallable =
  ## putBucketWebsite
  ## Set the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   website: bool (required)
  ##   body: JObject (required)
  var path_592470 = newJObject()
  var query_592471 = newJObject()
  var body_592472 = newJObject()
  add(path_592470, "Bucket", newJString(Bucket))
  add(query_592471, "website", newJBool(website))
  if body != nil:
    body_592472 = body
  result = call_592469.call(path_592470, query_592471, nil, nil, body_592472)

var putBucketWebsite* = Call_PutBucketWebsite_592460(name: "putBucketWebsite",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_PutBucketWebsite_592461, base: "/",
    url: url_PutBucketWebsite_592462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketWebsite_592450 = ref object of OpenApiRestCall_591364
proc url_GetBucketWebsite_592452(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketWebsite_592451(path: JsonNode; query: JsonNode;
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
  var valid_592453 = path.getOrDefault("Bucket")
  valid_592453 = validateParameter(valid_592453, JString, required = true,
                                 default = nil)
  if valid_592453 != nil:
    section.add "Bucket", valid_592453
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_592454 = query.getOrDefault("website")
  valid_592454 = validateParameter(valid_592454, JBool, required = true, default = nil)
  if valid_592454 != nil:
    section.add "website", valid_592454
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592455 = header.getOrDefault("x-amz-security-token")
  valid_592455 = validateParameter(valid_592455, JString, required = false,
                                 default = nil)
  if valid_592455 != nil:
    section.add "x-amz-security-token", valid_592455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592456: Call_GetBucketWebsite_592450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the website configuration for a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  let valid = call_592456.validator(path, query, header, formData, body)
  let scheme = call_592456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592456.url(scheme.get, call_592456.host, call_592456.base,
                         call_592456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592456, url, valid)

proc call*(call_592457: Call_GetBucketWebsite_592450; Bucket: string; website: bool): Recallable =
  ## getBucketWebsite
  ## Returns the website configuration for a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   website: bool (required)
  var path_592458 = newJObject()
  var query_592459 = newJObject()
  add(path_592458, "Bucket", newJString(Bucket))
  add(query_592459, "website", newJBool(website))
  result = call_592457.call(path_592458, query_592459, nil, nil, nil)

var getBucketWebsite* = Call_GetBucketWebsite_592450(name: "getBucketWebsite",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_GetBucketWebsite_592451, base: "/",
    url: url_GetBucketWebsite_592452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBucketWebsite_592473 = ref object of OpenApiRestCall_591364
proc url_DeleteBucketWebsite_592475(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBucketWebsite_592474(path: JsonNode; query: JsonNode;
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
  var valid_592476 = path.getOrDefault("Bucket")
  valid_592476 = validateParameter(valid_592476, JString, required = true,
                                 default = nil)
  if valid_592476 != nil:
    section.add "Bucket", valid_592476
  result.add "path", section
  ## parameters in `query` object:
  ##   website: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `website` field"
  var valid_592477 = query.getOrDefault("website")
  valid_592477 = validateParameter(valid_592477, JBool, required = true, default = nil)
  if valid_592477 != nil:
    section.add "website", valid_592477
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592478 = header.getOrDefault("x-amz-security-token")
  valid_592478 = validateParameter(valid_592478, JString, required = false,
                                 default = nil)
  if valid_592478 != nil:
    section.add "x-amz-security-token", valid_592478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592479: Call_DeleteBucketWebsite_592473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes the website configuration from the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  let valid = call_592479.validator(path, query, header, formData, body)
  let scheme = call_592479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592479.url(scheme.get, call_592479.host, call_592479.base,
                         call_592479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592479, url, valid)

proc call*(call_592480: Call_DeleteBucketWebsite_592473; Bucket: string;
          website: bool): Recallable =
  ## deleteBucketWebsite
  ## This operation removes the website configuration from the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   website: bool (required)
  var path_592481 = newJObject()
  var query_592482 = newJObject()
  add(path_592481, "Bucket", newJString(Bucket))
  add(query_592482, "website", newJBool(website))
  result = call_592480.call(path_592481, query_592482, nil, nil, nil)

var deleteBucketWebsite* = Call_DeleteBucketWebsite_592473(
    name: "deleteBucketWebsite", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#website",
    validator: validate_DeleteBucketWebsite_592474, base: "/",
    url: url_DeleteBucketWebsite_592475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObject_592510 = ref object of OpenApiRestCall_591364
proc url_PutObject_592512(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutObject_592511(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592513 = path.getOrDefault("Bucket")
  valid_592513 = validateParameter(valid_592513, JString, required = true,
                                 default = nil)
  if valid_592513 != nil:
    section.add "Bucket", valid_592513
  var valid_592514 = path.getOrDefault("Key")
  valid_592514 = validateParameter(valid_592514, JString, required = true,
                                 default = nil)
  if valid_592514 != nil:
    section.add "Key", valid_592514
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
  var valid_592515 = header.getOrDefault("Cache-Control")
  valid_592515 = validateParameter(valid_592515, JString, required = false,
                                 default = nil)
  if valid_592515 != nil:
    section.add "Cache-Control", valid_592515
  var valid_592516 = header.getOrDefault("x-amz-storage-class")
  valid_592516 = validateParameter(valid_592516, JString, required = false,
                                 default = newJString("STANDARD"))
  if valid_592516 != nil:
    section.add "x-amz-storage-class", valid_592516
  var valid_592517 = header.getOrDefault("x-amz-object-lock-retain-until-date")
  valid_592517 = validateParameter(valid_592517, JString, required = false,
                                 default = nil)
  if valid_592517 != nil:
    section.add "x-amz-object-lock-retain-until-date", valid_592517
  var valid_592518 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_592518 = validateParameter(valid_592518, JString, required = false,
                                 default = nil)
  if valid_592518 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_592518
  var valid_592519 = header.getOrDefault("x-amz-server-side-encryption")
  valid_592519 = validateParameter(valid_592519, JString, required = false,
                                 default = newJString("AES256"))
  if valid_592519 != nil:
    section.add "x-amz-server-side-encryption", valid_592519
  var valid_592520 = header.getOrDefault("x-amz-tagging")
  valid_592520 = validateParameter(valid_592520, JString, required = false,
                                 default = nil)
  if valid_592520 != nil:
    section.add "x-amz-tagging", valid_592520
  var valid_592521 = header.getOrDefault("Content-Length")
  valid_592521 = validateParameter(valid_592521, JInt, required = false, default = nil)
  if valid_592521 != nil:
    section.add "Content-Length", valid_592521
  var valid_592522 = header.getOrDefault("x-amz-object-lock-mode")
  valid_592522 = validateParameter(valid_592522, JString, required = false,
                                 default = newJString("GOVERNANCE"))
  if valid_592522 != nil:
    section.add "x-amz-object-lock-mode", valid_592522
  var valid_592523 = header.getOrDefault("x-amz-security-token")
  valid_592523 = validateParameter(valid_592523, JString, required = false,
                                 default = nil)
  if valid_592523 != nil:
    section.add "x-amz-security-token", valid_592523
  var valid_592524 = header.getOrDefault("x-amz-grant-read-acp")
  valid_592524 = validateParameter(valid_592524, JString, required = false,
                                 default = nil)
  if valid_592524 != nil:
    section.add "x-amz-grant-read-acp", valid_592524
  var valid_592525 = header.getOrDefault("x-amz-object-lock-legal-hold")
  valid_592525 = validateParameter(valid_592525, JString, required = false,
                                 default = newJString("ON"))
  if valid_592525 != nil:
    section.add "x-amz-object-lock-legal-hold", valid_592525
  var valid_592526 = header.getOrDefault("x-amz-acl")
  valid_592526 = validateParameter(valid_592526, JString, required = false,
                                 default = newJString("private"))
  if valid_592526 != nil:
    section.add "x-amz-acl", valid_592526
  var valid_592527 = header.getOrDefault("x-amz-grant-write-acp")
  valid_592527 = validateParameter(valid_592527, JString, required = false,
                                 default = nil)
  if valid_592527 != nil:
    section.add "x-amz-grant-write-acp", valid_592527
  var valid_592528 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_592528 = validateParameter(valid_592528, JString, required = false,
                                 default = nil)
  if valid_592528 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_592528
  var valid_592529 = header.getOrDefault("x-amz-server-side-encryption-context")
  valid_592529 = validateParameter(valid_592529, JString, required = false,
                                 default = nil)
  if valid_592529 != nil:
    section.add "x-amz-server-side-encryption-context", valid_592529
  var valid_592530 = header.getOrDefault("Content-Disposition")
  valid_592530 = validateParameter(valid_592530, JString, required = false,
                                 default = nil)
  if valid_592530 != nil:
    section.add "Content-Disposition", valid_592530
  var valid_592531 = header.getOrDefault("Content-Encoding")
  valid_592531 = validateParameter(valid_592531, JString, required = false,
                                 default = nil)
  if valid_592531 != nil:
    section.add "Content-Encoding", valid_592531
  var valid_592532 = header.getOrDefault("x-amz-request-payer")
  valid_592532 = validateParameter(valid_592532, JString, required = false,
                                 default = newJString("requester"))
  if valid_592532 != nil:
    section.add "x-amz-request-payer", valid_592532
  var valid_592533 = header.getOrDefault("Content-MD5")
  valid_592533 = validateParameter(valid_592533, JString, required = false,
                                 default = nil)
  if valid_592533 != nil:
    section.add "Content-MD5", valid_592533
  var valid_592534 = header.getOrDefault("x-amz-grant-full-control")
  valid_592534 = validateParameter(valid_592534, JString, required = false,
                                 default = nil)
  if valid_592534 != nil:
    section.add "x-amz-grant-full-control", valid_592534
  var valid_592535 = header.getOrDefault("x-amz-website-redirect-location")
  valid_592535 = validateParameter(valid_592535, JString, required = false,
                                 default = nil)
  if valid_592535 != nil:
    section.add "x-amz-website-redirect-location", valid_592535
  var valid_592536 = header.getOrDefault("Content-Language")
  valid_592536 = validateParameter(valid_592536, JString, required = false,
                                 default = nil)
  if valid_592536 != nil:
    section.add "Content-Language", valid_592536
  var valid_592537 = header.getOrDefault("Content-Type")
  valid_592537 = validateParameter(valid_592537, JString, required = false,
                                 default = nil)
  if valid_592537 != nil:
    section.add "Content-Type", valid_592537
  var valid_592538 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_592538 = validateParameter(valid_592538, JString, required = false,
                                 default = nil)
  if valid_592538 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_592538
  var valid_592539 = header.getOrDefault("x-amz-server-side-encryption-aws-kms-key-id")
  valid_592539 = validateParameter(valid_592539, JString, required = false,
                                 default = nil)
  if valid_592539 != nil:
    section.add "x-amz-server-side-encryption-aws-kms-key-id", valid_592539
  var valid_592540 = header.getOrDefault("Expires")
  valid_592540 = validateParameter(valid_592540, JString, required = false,
                                 default = nil)
  if valid_592540 != nil:
    section.add "Expires", valid_592540
  var valid_592541 = header.getOrDefault("x-amz-grant-read")
  valid_592541 = validateParameter(valid_592541, JString, required = false,
                                 default = nil)
  if valid_592541 != nil:
    section.add "x-amz-grant-read", valid_592541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592543: Call_PutObject_592510; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an object to a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  let valid = call_592543.validator(path, query, header, formData, body)
  let scheme = call_592543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592543.url(scheme.get, call_592543.host, call_592543.base,
                         call_592543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592543, url, valid)

proc call*(call_592544: Call_PutObject_592510; Bucket: string; Key: string;
          body: JsonNode): Recallable =
  ## putObject
  ## Adds an object to a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
  ##   Bucket: string (required)
  ##         : Name of the bucket to which the PUT operation was initiated.
  ##   Key: string (required)
  ##      : Object key for which the PUT operation was initiated.
  ##   body: JObject (required)
  var path_592545 = newJObject()
  var body_592546 = newJObject()
  add(path_592545, "Bucket", newJString(Bucket))
  add(path_592545, "Key", newJString(Key))
  if body != nil:
    body_592546 = body
  result = call_592544.call(path_592545, nil, nil, nil, body_592546)

var putObject* = Call_PutObject_592510(name: "putObject", meth: HttpMethod.HttpPut,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_PutObject_592511,
                                    base: "/", url: url_PutObject_592512,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_HeadObject_592561 = ref object of OpenApiRestCall_591364
proc url_HeadObject_592563(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_HeadObject_592562(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592564 = path.getOrDefault("Bucket")
  valid_592564 = validateParameter(valid_592564, JString, required = true,
                                 default = nil)
  if valid_592564 != nil:
    section.add "Bucket", valid_592564
  var valid_592565 = path.getOrDefault("Key")
  valid_592565 = validateParameter(valid_592565, JString, required = true,
                                 default = nil)
  if valid_592565 != nil:
    section.add "Key", valid_592565
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  ##   partNumber: JInt
  ##             : Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
  section = newJObject()
  var valid_592566 = query.getOrDefault("versionId")
  valid_592566 = validateParameter(valid_592566, JString, required = false,
                                 default = nil)
  if valid_592566 != nil:
    section.add "versionId", valid_592566
  var valid_592567 = query.getOrDefault("partNumber")
  valid_592567 = validateParameter(valid_592567, JInt, required = false, default = nil)
  if valid_592567 != nil:
    section.add "partNumber", valid_592567
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
  var valid_592568 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_592568 = validateParameter(valid_592568, JString, required = false,
                                 default = nil)
  if valid_592568 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_592568
  var valid_592569 = header.getOrDefault("x-amz-security-token")
  valid_592569 = validateParameter(valid_592569, JString, required = false,
                                 default = nil)
  if valid_592569 != nil:
    section.add "x-amz-security-token", valid_592569
  var valid_592570 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_592570 = validateParameter(valid_592570, JString, required = false,
                                 default = nil)
  if valid_592570 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_592570
  var valid_592571 = header.getOrDefault("If-Unmodified-Since")
  valid_592571 = validateParameter(valid_592571, JString, required = false,
                                 default = nil)
  if valid_592571 != nil:
    section.add "If-Unmodified-Since", valid_592571
  var valid_592572 = header.getOrDefault("x-amz-request-payer")
  valid_592572 = validateParameter(valid_592572, JString, required = false,
                                 default = newJString("requester"))
  if valid_592572 != nil:
    section.add "x-amz-request-payer", valid_592572
  var valid_592573 = header.getOrDefault("If-Modified-Since")
  valid_592573 = validateParameter(valid_592573, JString, required = false,
                                 default = nil)
  if valid_592573 != nil:
    section.add "If-Modified-Since", valid_592573
  var valid_592574 = header.getOrDefault("Range")
  valid_592574 = validateParameter(valid_592574, JString, required = false,
                                 default = nil)
  if valid_592574 != nil:
    section.add "Range", valid_592574
  var valid_592575 = header.getOrDefault("If-None-Match")
  valid_592575 = validateParameter(valid_592575, JString, required = false,
                                 default = nil)
  if valid_592575 != nil:
    section.add "If-None-Match", valid_592575
  var valid_592576 = header.getOrDefault("If-Match")
  valid_592576 = validateParameter(valid_592576, JString, required = false,
                                 default = nil)
  if valid_592576 != nil:
    section.add "If-Match", valid_592576
  var valid_592577 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_592577 = validateParameter(valid_592577, JString, required = false,
                                 default = nil)
  if valid_592577 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_592577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592578: Call_HeadObject_592561; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The HEAD operation retrieves metadata from an object without returning the object itself. This operation is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
  let valid = call_592578.validator(path, query, header, formData, body)
  let scheme = call_592578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592578.url(scheme.get, call_592578.host, call_592578.base,
                         call_592578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592578, url, valid)

proc call*(call_592579: Call_HeadObject_592561; Bucket: string; Key: string;
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
  var path_592580 = newJObject()
  var query_592581 = newJObject()
  add(path_592580, "Bucket", newJString(Bucket))
  add(query_592581, "versionId", newJString(versionId))
  add(path_592580, "Key", newJString(Key))
  add(query_592581, "partNumber", newJInt(partNumber))
  result = call_592579.call(path_592580, query_592581, nil, nil, nil)

var headObject* = Call_HeadObject_592561(name: "headObject",
                                      meth: HttpMethod.HttpHead,
                                      host: "s3.amazonaws.com",
                                      route: "/{Bucket}/{Key}",
                                      validator: validate_HeadObject_592562,
                                      base: "/", url: url_HeadObject_592563,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObject_592483 = ref object of OpenApiRestCall_591364
proc url_GetObject_592485(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetObject_592484(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592486 = path.getOrDefault("Bucket")
  valid_592486 = validateParameter(valid_592486, JString, required = true,
                                 default = nil)
  if valid_592486 != nil:
    section.add "Bucket", valid_592486
  var valid_592487 = path.getOrDefault("Key")
  valid_592487 = validateParameter(valid_592487, JString, required = true,
                                 default = nil)
  if valid_592487 != nil:
    section.add "Key", valid_592487
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
  var valid_592488 = query.getOrDefault("response-expires")
  valid_592488 = validateParameter(valid_592488, JString, required = false,
                                 default = nil)
  if valid_592488 != nil:
    section.add "response-expires", valid_592488
  var valid_592489 = query.getOrDefault("response-content-type")
  valid_592489 = validateParameter(valid_592489, JString, required = false,
                                 default = nil)
  if valid_592489 != nil:
    section.add "response-content-type", valid_592489
  var valid_592490 = query.getOrDefault("versionId")
  valid_592490 = validateParameter(valid_592490, JString, required = false,
                                 default = nil)
  if valid_592490 != nil:
    section.add "versionId", valid_592490
  var valid_592491 = query.getOrDefault("response-content-encoding")
  valid_592491 = validateParameter(valid_592491, JString, required = false,
                                 default = nil)
  if valid_592491 != nil:
    section.add "response-content-encoding", valid_592491
  var valid_592492 = query.getOrDefault("response-content-language")
  valid_592492 = validateParameter(valid_592492, JString, required = false,
                                 default = nil)
  if valid_592492 != nil:
    section.add "response-content-language", valid_592492
  var valid_592493 = query.getOrDefault("response-cache-control")
  valid_592493 = validateParameter(valid_592493, JString, required = false,
                                 default = nil)
  if valid_592493 != nil:
    section.add "response-cache-control", valid_592493
  var valid_592494 = query.getOrDefault("partNumber")
  valid_592494 = validateParameter(valid_592494, JInt, required = false, default = nil)
  if valid_592494 != nil:
    section.add "partNumber", valid_592494
  var valid_592495 = query.getOrDefault("response-content-disposition")
  valid_592495 = validateParameter(valid_592495, JString, required = false,
                                 default = nil)
  if valid_592495 != nil:
    section.add "response-content-disposition", valid_592495
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
  var valid_592496 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_592496 = validateParameter(valid_592496, JString, required = false,
                                 default = nil)
  if valid_592496 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_592496
  var valid_592497 = header.getOrDefault("x-amz-security-token")
  valid_592497 = validateParameter(valid_592497, JString, required = false,
                                 default = nil)
  if valid_592497 != nil:
    section.add "x-amz-security-token", valid_592497
  var valid_592498 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_592498 = validateParameter(valid_592498, JString, required = false,
                                 default = nil)
  if valid_592498 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_592498
  var valid_592499 = header.getOrDefault("If-Unmodified-Since")
  valid_592499 = validateParameter(valid_592499, JString, required = false,
                                 default = nil)
  if valid_592499 != nil:
    section.add "If-Unmodified-Since", valid_592499
  var valid_592500 = header.getOrDefault("x-amz-request-payer")
  valid_592500 = validateParameter(valid_592500, JString, required = false,
                                 default = newJString("requester"))
  if valid_592500 != nil:
    section.add "x-amz-request-payer", valid_592500
  var valid_592501 = header.getOrDefault("If-Modified-Since")
  valid_592501 = validateParameter(valid_592501, JString, required = false,
                                 default = nil)
  if valid_592501 != nil:
    section.add "If-Modified-Since", valid_592501
  var valid_592502 = header.getOrDefault("Range")
  valid_592502 = validateParameter(valid_592502, JString, required = false,
                                 default = nil)
  if valid_592502 != nil:
    section.add "Range", valid_592502
  var valid_592503 = header.getOrDefault("If-None-Match")
  valid_592503 = validateParameter(valid_592503, JString, required = false,
                                 default = nil)
  if valid_592503 != nil:
    section.add "If-None-Match", valid_592503
  var valid_592504 = header.getOrDefault("If-Match")
  valid_592504 = validateParameter(valid_592504, JString, required = false,
                                 default = nil)
  if valid_592504 != nil:
    section.add "If-Match", valid_592504
  var valid_592505 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_592505 = validateParameter(valid_592505, JString, required = false,
                                 default = nil)
  if valid_592505 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_592505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592506: Call_GetObject_592483; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves objects from Amazon S3.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
  let valid = call_592506.validator(path, query, header, formData, body)
  let scheme = call_592506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592506.url(scheme.get, call_592506.host, call_592506.base,
                         call_592506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592506, url, valid)

proc call*(call_592507: Call_GetObject_592483; Bucket: string; Key: string;
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
  var path_592508 = newJObject()
  var query_592509 = newJObject()
  add(path_592508, "Bucket", newJString(Bucket))
  add(query_592509, "response-expires", newJString(responseExpires))
  add(query_592509, "response-content-type", newJString(responseContentType))
  add(query_592509, "versionId", newJString(versionId))
  add(query_592509, "response-content-encoding",
      newJString(responseContentEncoding))
  add(query_592509, "response-content-language",
      newJString(responseContentLanguage))
  add(query_592509, "response-cache-control", newJString(responseCacheControl))
  add(path_592508, "Key", newJString(Key))
  add(query_592509, "partNumber", newJInt(partNumber))
  add(query_592509, "response-content-disposition",
      newJString(responseContentDisposition))
  result = call_592507.call(path_592508, query_592509, nil, nil, nil)

var getObject* = Call_GetObject_592483(name: "getObject", meth: HttpMethod.HttpGet,
                                    host: "s3.amazonaws.com",
                                    route: "/{Bucket}/{Key}",
                                    validator: validate_GetObject_592484,
                                    base: "/", url: url_GetObject_592485,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_592547 = ref object of OpenApiRestCall_591364
proc url_DeleteObject_592549(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObject_592548(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592550 = path.getOrDefault("Bucket")
  valid_592550 = validateParameter(valid_592550, JString, required = true,
                                 default = nil)
  if valid_592550 != nil:
    section.add "Bucket", valid_592550
  var valid_592551 = path.getOrDefault("Key")
  valid_592551 = validateParameter(valid_592551, JString, required = true,
                                 default = nil)
  if valid_592551 != nil:
    section.add "Key", valid_592551
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  var valid_592552 = query.getOrDefault("versionId")
  valid_592552 = validateParameter(valid_592552, JString, required = false,
                                 default = nil)
  if valid_592552 != nil:
    section.add "versionId", valid_592552
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
  var valid_592553 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_592553 = validateParameter(valid_592553, JBool, required = false, default = nil)
  if valid_592553 != nil:
    section.add "x-amz-bypass-governance-retention", valid_592553
  var valid_592554 = header.getOrDefault("x-amz-security-token")
  valid_592554 = validateParameter(valid_592554, JString, required = false,
                                 default = nil)
  if valid_592554 != nil:
    section.add "x-amz-security-token", valid_592554
  var valid_592555 = header.getOrDefault("x-amz-mfa")
  valid_592555 = validateParameter(valid_592555, JString, required = false,
                                 default = nil)
  if valid_592555 != nil:
    section.add "x-amz-mfa", valid_592555
  var valid_592556 = header.getOrDefault("x-amz-request-payer")
  valid_592556 = validateParameter(valid_592556, JString, required = false,
                                 default = newJString("requester"))
  if valid_592556 != nil:
    section.add "x-amz-request-payer", valid_592556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592557: Call_DeleteObject_592547; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
  let valid = call_592557.validator(path, query, header, formData, body)
  let scheme = call_592557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592557.url(scheme.get, call_592557.host, call_592557.base,
                         call_592557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592557, url, valid)

proc call*(call_592558: Call_DeleteObject_592547; Bucket: string; Key: string;
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
  var path_592559 = newJObject()
  var query_592560 = newJObject()
  add(path_592559, "Bucket", newJString(Bucket))
  add(query_592560, "versionId", newJString(versionId))
  add(path_592559, "Key", newJString(Key))
  result = call_592558.call(path_592559, query_592560, nil, nil, nil)

var deleteObject* = Call_DeleteObject_592547(name: "deleteObject",
    meth: HttpMethod.HttpDelete, host: "s3.amazonaws.com", route: "/{Bucket}/{Key}",
    validator: validate_DeleteObject_592548, base: "/", url: url_DeleteObject_592549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectTagging_592594 = ref object of OpenApiRestCall_591364
proc url_PutObjectTagging_592596(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectTagging_592595(path: JsonNode; query: JsonNode;
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
  var valid_592597 = path.getOrDefault("Bucket")
  valid_592597 = validateParameter(valid_592597, JString, required = true,
                                 default = nil)
  if valid_592597 != nil:
    section.add "Bucket", valid_592597
  var valid_592598 = path.getOrDefault("Key")
  valid_592598 = validateParameter(valid_592598, JString, required = true,
                                 default = nil)
  if valid_592598 != nil:
    section.add "Key", valid_592598
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  ##   versionId: JString
  ##            : <p/>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_592599 = query.getOrDefault("tagging")
  valid_592599 = validateParameter(valid_592599, JBool, required = true, default = nil)
  if valid_592599 != nil:
    section.add "tagging", valid_592599
  var valid_592600 = query.getOrDefault("versionId")
  valid_592600 = validateParameter(valid_592600, JString, required = false,
                                 default = nil)
  if valid_592600 != nil:
    section.add "versionId", valid_592600
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_592601 = header.getOrDefault("x-amz-security-token")
  valid_592601 = validateParameter(valid_592601, JString, required = false,
                                 default = nil)
  if valid_592601 != nil:
    section.add "x-amz-security-token", valid_592601
  var valid_592602 = header.getOrDefault("Content-MD5")
  valid_592602 = validateParameter(valid_592602, JString, required = false,
                                 default = nil)
  if valid_592602 != nil:
    section.add "Content-MD5", valid_592602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592604: Call_PutObjectTagging_592594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the supplied tag-set to an object that already exists in a bucket
  ## 
  let valid = call_592604.validator(path, query, header, formData, body)
  let scheme = call_592604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592604.url(scheme.get, call_592604.host, call_592604.base,
                         call_592604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592604, url, valid)

proc call*(call_592605: Call_PutObjectTagging_592594; tagging: bool; Bucket: string;
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
  var path_592606 = newJObject()
  var query_592607 = newJObject()
  var body_592608 = newJObject()
  add(query_592607, "tagging", newJBool(tagging))
  add(path_592606, "Bucket", newJString(Bucket))
  add(query_592607, "versionId", newJString(versionId))
  add(path_592606, "Key", newJString(Key))
  if body != nil:
    body_592608 = body
  result = call_592605.call(path_592606, query_592607, nil, nil, body_592608)

var putObjectTagging* = Call_PutObjectTagging_592594(name: "putObjectTagging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_PutObjectTagging_592595,
    base: "/", url: url_PutObjectTagging_592596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTagging_592582 = ref object of OpenApiRestCall_591364
proc url_GetObjectTagging_592584(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectTagging_592583(path: JsonNode; query: JsonNode;
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
  var valid_592585 = path.getOrDefault("Bucket")
  valid_592585 = validateParameter(valid_592585, JString, required = true,
                                 default = nil)
  if valid_592585 != nil:
    section.add "Bucket", valid_592585
  var valid_592586 = path.getOrDefault("Key")
  valid_592586 = validateParameter(valid_592586, JString, required = true,
                                 default = nil)
  if valid_592586 != nil:
    section.add "Key", valid_592586
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  ##   versionId: JString
  ##            : <p/>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_592587 = query.getOrDefault("tagging")
  valid_592587 = validateParameter(valid_592587, JBool, required = true, default = nil)
  if valid_592587 != nil:
    section.add "tagging", valid_592587
  var valid_592588 = query.getOrDefault("versionId")
  valid_592588 = validateParameter(valid_592588, JString, required = false,
                                 default = nil)
  if valid_592588 != nil:
    section.add "versionId", valid_592588
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592589 = header.getOrDefault("x-amz-security-token")
  valid_592589 = validateParameter(valid_592589, JString, required = false,
                                 default = nil)
  if valid_592589 != nil:
    section.add "x-amz-security-token", valid_592589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592590: Call_GetObjectTagging_592582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tag-set of an object.
  ## 
  let valid = call_592590.validator(path, query, header, formData, body)
  let scheme = call_592590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592590.url(scheme.get, call_592590.host, call_592590.base,
                         call_592590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592590, url, valid)

proc call*(call_592591: Call_GetObjectTagging_592582; tagging: bool; Bucket: string;
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
  var path_592592 = newJObject()
  var query_592593 = newJObject()
  add(query_592593, "tagging", newJBool(tagging))
  add(path_592592, "Bucket", newJString(Bucket))
  add(query_592593, "versionId", newJString(versionId))
  add(path_592592, "Key", newJString(Key))
  result = call_592591.call(path_592592, query_592593, nil, nil, nil)

var getObjectTagging* = Call_GetObjectTagging_592582(name: "getObjectTagging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#tagging", validator: validate_GetObjectTagging_592583,
    base: "/", url: url_GetObjectTagging_592584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjectTagging_592609 = ref object of OpenApiRestCall_591364
proc url_DeleteObjectTagging_592611(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObjectTagging_592610(path: JsonNode; query: JsonNode;
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
  var valid_592612 = path.getOrDefault("Bucket")
  valid_592612 = validateParameter(valid_592612, JString, required = true,
                                 default = nil)
  if valid_592612 != nil:
    section.add "Bucket", valid_592612
  var valid_592613 = path.getOrDefault("Key")
  valid_592613 = validateParameter(valid_592613, JString, required = true,
                                 default = nil)
  if valid_592613 != nil:
    section.add "Key", valid_592613
  result.add "path", section
  ## parameters in `query` object:
  ##   tagging: JBool (required)
  ##   versionId: JString
  ##            : The versionId of the object that the tag-set will be removed from.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagging` field"
  var valid_592614 = query.getOrDefault("tagging")
  valid_592614 = validateParameter(valid_592614, JBool, required = true, default = nil)
  if valid_592614 != nil:
    section.add "tagging", valid_592614
  var valid_592615 = query.getOrDefault("versionId")
  valid_592615 = validateParameter(valid_592615, JString, required = false,
                                 default = nil)
  if valid_592615 != nil:
    section.add "versionId", valid_592615
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592616 = header.getOrDefault("x-amz-security-token")
  valid_592616 = validateParameter(valid_592616, JString, required = false,
                                 default = nil)
  if valid_592616 != nil:
    section.add "x-amz-security-token", valid_592616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592617: Call_DeleteObjectTagging_592609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the tag-set from an existing object.
  ## 
  let valid = call_592617.validator(path, query, header, formData, body)
  let scheme = call_592617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592617.url(scheme.get, call_592617.host, call_592617.base,
                         call_592617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592617, url, valid)

proc call*(call_592618: Call_DeleteObjectTagging_592609; tagging: bool;
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
  var path_592619 = newJObject()
  var query_592620 = newJObject()
  add(query_592620, "tagging", newJBool(tagging))
  add(path_592619, "Bucket", newJString(Bucket))
  add(query_592620, "versionId", newJString(versionId))
  add(path_592619, "Key", newJString(Key))
  result = call_592618.call(path_592619, query_592620, nil, nil, nil)

var deleteObjectTagging* = Call_DeleteObjectTagging_592609(
    name: "deleteObjectTagging", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#tagging",
    validator: validate_DeleteObjectTagging_592610, base: "/",
    url: url_DeleteObjectTagging_592611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObjects_592621 = ref object of OpenApiRestCall_591364
proc url_DeleteObjects_592623(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObjects_592622(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592624 = path.getOrDefault("Bucket")
  valid_592624 = validateParameter(valid_592624, JString, required = true,
                                 default = nil)
  if valid_592624 != nil:
    section.add "Bucket", valid_592624
  result.add "path", section
  ## parameters in `query` object:
  ##   delete: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `delete` field"
  var valid_592625 = query.getOrDefault("delete")
  valid_592625 = validateParameter(valid_592625, JBool, required = true, default = nil)
  if valid_592625 != nil:
    section.add "delete", valid_592625
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
  var valid_592626 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_592626 = validateParameter(valid_592626, JBool, required = false, default = nil)
  if valid_592626 != nil:
    section.add "x-amz-bypass-governance-retention", valid_592626
  var valid_592627 = header.getOrDefault("x-amz-security-token")
  valid_592627 = validateParameter(valid_592627, JString, required = false,
                                 default = nil)
  if valid_592627 != nil:
    section.add "x-amz-security-token", valid_592627
  var valid_592628 = header.getOrDefault("x-amz-mfa")
  valid_592628 = validateParameter(valid_592628, JString, required = false,
                                 default = nil)
  if valid_592628 != nil:
    section.add "x-amz-mfa", valid_592628
  var valid_592629 = header.getOrDefault("x-amz-request-payer")
  valid_592629 = validateParameter(valid_592629, JString, required = false,
                                 default = newJString("requester"))
  if valid_592629 != nil:
    section.add "x-amz-request-payer", valid_592629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592631: Call_DeleteObjects_592621; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  let valid = call_592631.validator(path, query, header, formData, body)
  let scheme = call_592631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592631.url(scheme.get, call_592631.host, call_592631.base,
                         call_592631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592631, url, valid)

proc call*(call_592632: Call_DeleteObjects_592621; Bucket: string; delete: bool;
          body: JsonNode): Recallable =
  ## deleteObjects
  ## This operation enables you to delete multiple objects from a bucket using a single HTTP request. You may specify up to 1000 keys.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   delete: bool (required)
  ##   body: JObject (required)
  var path_592633 = newJObject()
  var query_592634 = newJObject()
  var body_592635 = newJObject()
  add(path_592633, "Bucket", newJString(Bucket))
  add(query_592634, "delete", newJBool(delete))
  if body != nil:
    body_592635 = body
  result = call_592632.call(path_592633, query_592634, nil, nil, body_592635)

var deleteObjects* = Call_DeleteObjects_592621(name: "deleteObjects",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com", route: "/{Bucket}#delete",
    validator: validate_DeleteObjects_592622, base: "/", url: url_DeleteObjects_592623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_592646 = ref object of OpenApiRestCall_591364
proc url_PutPublicAccessBlock_592648(protocol: Scheme; host: string; base: string;
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

proc validate_PutPublicAccessBlock_592647(path: JsonNode; query: JsonNode;
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
  var valid_592649 = path.getOrDefault("Bucket")
  valid_592649 = validateParameter(valid_592649, JString, required = true,
                                 default = nil)
  if valid_592649 != nil:
    section.add "Bucket", valid_592649
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_592650 = query.getOrDefault("publicAccessBlock")
  valid_592650 = validateParameter(valid_592650, JBool, required = true, default = nil)
  if valid_592650 != nil:
    section.add "publicAccessBlock", valid_592650
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : The MD5 hash of the <code>PutPublicAccessBlock</code> request body. 
  section = newJObject()
  var valid_592651 = header.getOrDefault("x-amz-security-token")
  valid_592651 = validateParameter(valid_592651, JString, required = false,
                                 default = nil)
  if valid_592651 != nil:
    section.add "x-amz-security-token", valid_592651
  var valid_592652 = header.getOrDefault("Content-MD5")
  valid_592652 = validateParameter(valid_592652, JString, required = false,
                                 default = nil)
  if valid_592652 != nil:
    section.add "Content-MD5", valid_592652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592654: Call_PutPublicAccessBlock_592646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_592654.validator(path, query, header, formData, body)
  let scheme = call_592654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592654.url(scheme.get, call_592654.host, call_592654.base,
                         call_592654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592654, url, valid)

proc call*(call_592655: Call_PutPublicAccessBlock_592646; publicAccessBlock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to set.
  ##   body: JObject (required)
  var path_592656 = newJObject()
  var query_592657 = newJObject()
  var body_592658 = newJObject()
  add(query_592657, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_592656, "Bucket", newJString(Bucket))
  if body != nil:
    body_592658 = body
  result = call_592655.call(path_592656, query_592657, nil, nil, body_592658)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_592646(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_PutPublicAccessBlock_592647, base: "/",
    url: url_PutPublicAccessBlock_592648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_592636 = ref object of OpenApiRestCall_591364
proc url_GetPublicAccessBlock_592638(protocol: Scheme; host: string; base: string;
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

proc validate_GetPublicAccessBlock_592637(path: JsonNode; query: JsonNode;
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
  var valid_592639 = path.getOrDefault("Bucket")
  valid_592639 = validateParameter(valid_592639, JString, required = true,
                                 default = nil)
  if valid_592639 != nil:
    section.add "Bucket", valid_592639
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_592640 = query.getOrDefault("publicAccessBlock")
  valid_592640 = validateParameter(valid_592640, JBool, required = true, default = nil)
  if valid_592640 != nil:
    section.add "publicAccessBlock", valid_592640
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592641 = header.getOrDefault("x-amz-security-token")
  valid_592641 = validateParameter(valid_592641, JString, required = false,
                                 default = nil)
  if valid_592641 != nil:
    section.add "x-amz-security-token", valid_592641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592642: Call_GetPublicAccessBlock_592636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ## 
  let valid = call_592642.validator(path, query, header, formData, body)
  let scheme = call_592642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592642.url(scheme.get, call_592642.host, call_592642.base,
                         call_592642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592642, url, valid)

proc call*(call_592643: Call_GetPublicAccessBlock_592636; publicAccessBlock: bool;
          Bucket: string): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to retrieve. 
  var path_592644 = newJObject()
  var query_592645 = newJObject()
  add(query_592645, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_592644, "Bucket", newJString(Bucket))
  result = call_592643.call(path_592644, query_592645, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_592636(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_GetPublicAccessBlock_592637, base: "/",
    url: url_GetPublicAccessBlock_592638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_592659 = ref object of OpenApiRestCall_591364
proc url_DeletePublicAccessBlock_592661(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePublicAccessBlock_592660(path: JsonNode; query: JsonNode;
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
  var valid_592662 = path.getOrDefault("Bucket")
  valid_592662 = validateParameter(valid_592662, JString, required = true,
                                 default = nil)
  if valid_592662 != nil:
    section.add "Bucket", valid_592662
  result.add "path", section
  ## parameters in `query` object:
  ##   publicAccessBlock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `publicAccessBlock` field"
  var valid_592663 = query.getOrDefault("publicAccessBlock")
  valid_592663 = validateParameter(valid_592663, JBool, required = true, default = nil)
  if valid_592663 != nil:
    section.add "publicAccessBlock", valid_592663
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592664 = header.getOrDefault("x-amz-security-token")
  valid_592664 = validateParameter(valid_592664, JString, required = false,
                                 default = nil)
  if valid_592664 != nil:
    section.add "x-amz-security-token", valid_592664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592665: Call_DeletePublicAccessBlock_592659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ## 
  let valid = call_592665.validator(path, query, header, formData, body)
  let scheme = call_592665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592665.url(scheme.get, call_592665.host, call_592665.base,
                         call_592665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592665, url, valid)

proc call*(call_592666: Call_DeletePublicAccessBlock_592659;
          publicAccessBlock: bool; Bucket: string): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration from an Amazon S3 bucket.
  ##   publicAccessBlock: bool (required)
  ##   Bucket: string (required)
  ##         : The Amazon S3 bucket whose <code>PublicAccessBlock</code> configuration you want to delete. 
  var path_592667 = newJObject()
  var query_592668 = newJObject()
  add(query_592668, "publicAccessBlock", newJBool(publicAccessBlock))
  add(path_592667, "Bucket", newJString(Bucket))
  result = call_592666.call(path_592667, query_592668, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_592659(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3.amazonaws.com", route: "/{Bucket}#publicAccessBlock",
    validator: validate_DeletePublicAccessBlock_592660, base: "/",
    url: url_DeletePublicAccessBlock_592661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAccelerateConfiguration_592679 = ref object of OpenApiRestCall_591364
proc url_PutBucketAccelerateConfiguration_592681(protocol: Scheme; host: string;
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

proc validate_PutBucketAccelerateConfiguration_592680(path: JsonNode;
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
  var valid_592682 = path.getOrDefault("Bucket")
  valid_592682 = validateParameter(valid_592682, JString, required = true,
                                 default = nil)
  if valid_592682 != nil:
    section.add "Bucket", valid_592682
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_592683 = query.getOrDefault("accelerate")
  valid_592683 = validateParameter(valid_592683, JBool, required = true, default = nil)
  if valid_592683 != nil:
    section.add "accelerate", valid_592683
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592684 = header.getOrDefault("x-amz-security-token")
  valid_592684 = validateParameter(valid_592684, JString, required = false,
                                 default = nil)
  if valid_592684 != nil:
    section.add "x-amz-security-token", valid_592684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592686: Call_PutBucketAccelerateConfiguration_592679;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the accelerate configuration of an existing bucket.
  ## 
  let valid = call_592686.validator(path, query, header, formData, body)
  let scheme = call_592686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592686.url(scheme.get, call_592686.host, call_592686.base,
                         call_592686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592686, url, valid)

proc call*(call_592687: Call_PutBucketAccelerateConfiguration_592679;
          Bucket: string; accelerate: bool; body: JsonNode): Recallable =
  ## putBucketAccelerateConfiguration
  ## Sets the accelerate configuration of an existing bucket.
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is set.
  ##   accelerate: bool (required)
  ##   body: JObject (required)
  var path_592688 = newJObject()
  var query_592689 = newJObject()
  var body_592690 = newJObject()
  add(path_592688, "Bucket", newJString(Bucket))
  add(query_592689, "accelerate", newJBool(accelerate))
  if body != nil:
    body_592690 = body
  result = call_592687.call(path_592688, query_592689, nil, nil, body_592690)

var putBucketAccelerateConfiguration* = Call_PutBucketAccelerateConfiguration_592679(
    name: "putBucketAccelerateConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_PutBucketAccelerateConfiguration_592680, base: "/",
    url: url_PutBucketAccelerateConfiguration_592681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAccelerateConfiguration_592669 = ref object of OpenApiRestCall_591364
proc url_GetBucketAccelerateConfiguration_592671(protocol: Scheme; host: string;
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

proc validate_GetBucketAccelerateConfiguration_592670(path: JsonNode;
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
  var valid_592672 = path.getOrDefault("Bucket")
  valid_592672 = validateParameter(valid_592672, JString, required = true,
                                 default = nil)
  if valid_592672 != nil:
    section.add "Bucket", valid_592672
  result.add "path", section
  ## parameters in `query` object:
  ##   accelerate: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `accelerate` field"
  var valid_592673 = query.getOrDefault("accelerate")
  valid_592673 = validateParameter(valid_592673, JBool, required = true, default = nil)
  if valid_592673 != nil:
    section.add "accelerate", valid_592673
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592674 = header.getOrDefault("x-amz-security-token")
  valid_592674 = validateParameter(valid_592674, JString, required = false,
                                 default = nil)
  if valid_592674 != nil:
    section.add "x-amz-security-token", valid_592674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592675: Call_GetBucketAccelerateConfiguration_592669;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the accelerate configuration of a bucket.
  ## 
  let valid = call_592675.validator(path, query, header, formData, body)
  let scheme = call_592675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592675.url(scheme.get, call_592675.host, call_592675.base,
                         call_592675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592675, url, valid)

proc call*(call_592676: Call_GetBucketAccelerateConfiguration_592669;
          Bucket: string; accelerate: bool): Recallable =
  ## getBucketAccelerateConfiguration
  ## Returns the accelerate configuration of a bucket.
  ##   Bucket: string (required)
  ##         : Name of the bucket for which the accelerate configuration is retrieved.
  ##   accelerate: bool (required)
  var path_592677 = newJObject()
  var query_592678 = newJObject()
  add(path_592677, "Bucket", newJString(Bucket))
  add(query_592678, "accelerate", newJBool(accelerate))
  result = call_592676.call(path_592677, query_592678, nil, nil, nil)

var getBucketAccelerateConfiguration* = Call_GetBucketAccelerateConfiguration_592669(
    name: "getBucketAccelerateConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#accelerate",
    validator: validate_GetBucketAccelerateConfiguration_592670, base: "/",
    url: url_GetBucketAccelerateConfiguration_592671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketAcl_592701 = ref object of OpenApiRestCall_591364
proc url_PutBucketAcl_592703(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketAcl_592702(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592704 = path.getOrDefault("Bucket")
  valid_592704 = validateParameter(valid_592704, JString, required = true,
                                 default = nil)
  if valid_592704 != nil:
    section.add "Bucket", valid_592704
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_592705 = query.getOrDefault("acl")
  valid_592705 = validateParameter(valid_592705, JBool, required = true, default = nil)
  if valid_592705 != nil:
    section.add "acl", valid_592705
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
  var valid_592706 = header.getOrDefault("x-amz-grant-write")
  valid_592706 = validateParameter(valid_592706, JString, required = false,
                                 default = nil)
  if valid_592706 != nil:
    section.add "x-amz-grant-write", valid_592706
  var valid_592707 = header.getOrDefault("x-amz-security-token")
  valid_592707 = validateParameter(valid_592707, JString, required = false,
                                 default = nil)
  if valid_592707 != nil:
    section.add "x-amz-security-token", valid_592707
  var valid_592708 = header.getOrDefault("x-amz-grant-read-acp")
  valid_592708 = validateParameter(valid_592708, JString, required = false,
                                 default = nil)
  if valid_592708 != nil:
    section.add "x-amz-grant-read-acp", valid_592708
  var valid_592709 = header.getOrDefault("x-amz-acl")
  valid_592709 = validateParameter(valid_592709, JString, required = false,
                                 default = newJString("private"))
  if valid_592709 != nil:
    section.add "x-amz-acl", valid_592709
  var valid_592710 = header.getOrDefault("x-amz-grant-write-acp")
  valid_592710 = validateParameter(valid_592710, JString, required = false,
                                 default = nil)
  if valid_592710 != nil:
    section.add "x-amz-grant-write-acp", valid_592710
  var valid_592711 = header.getOrDefault("Content-MD5")
  valid_592711 = validateParameter(valid_592711, JString, required = false,
                                 default = nil)
  if valid_592711 != nil:
    section.add "Content-MD5", valid_592711
  var valid_592712 = header.getOrDefault("x-amz-grant-full-control")
  valid_592712 = validateParameter(valid_592712, JString, required = false,
                                 default = nil)
  if valid_592712 != nil:
    section.add "x-amz-grant-full-control", valid_592712
  var valid_592713 = header.getOrDefault("x-amz-grant-read")
  valid_592713 = validateParameter(valid_592713, JString, required = false,
                                 default = nil)
  if valid_592713 != nil:
    section.add "x-amz-grant-read", valid_592713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592715: Call_PutBucketAcl_592701; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  let valid = call_592715.validator(path, query, header, formData, body)
  let scheme = call_592715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592715.url(scheme.get, call_592715.host, call_592715.base,
                         call_592715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592715, url, valid)

proc call*(call_592716: Call_PutBucketAcl_592701; Bucket: string; acl: bool;
          body: JsonNode): Recallable =
  ## putBucketAcl
  ## Sets the permissions on a bucket using access control lists (ACL).
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   acl: bool (required)
  ##   body: JObject (required)
  var path_592717 = newJObject()
  var query_592718 = newJObject()
  var body_592719 = newJObject()
  add(path_592717, "Bucket", newJString(Bucket))
  add(query_592718, "acl", newJBool(acl))
  if body != nil:
    body_592719 = body
  result = call_592716.call(path_592717, query_592718, nil, nil, body_592719)

var putBucketAcl* = Call_PutBucketAcl_592701(name: "putBucketAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_PutBucketAcl_592702, base: "/", url: url_PutBucketAcl_592703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketAcl_592691 = ref object of OpenApiRestCall_591364
proc url_GetBucketAcl_592693(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketAcl_592692(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592694 = path.getOrDefault("Bucket")
  valid_592694 = validateParameter(valid_592694, JString, required = true,
                                 default = nil)
  if valid_592694 != nil:
    section.add "Bucket", valid_592694
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_592695 = query.getOrDefault("acl")
  valid_592695 = validateParameter(valid_592695, JBool, required = true, default = nil)
  if valid_592695 != nil:
    section.add "acl", valid_592695
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592696 = header.getOrDefault("x-amz-security-token")
  valid_592696 = validateParameter(valid_592696, JString, required = false,
                                 default = nil)
  if valid_592696 != nil:
    section.add "x-amz-security-token", valid_592696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592697: Call_GetBucketAcl_592691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the access control policy for the bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  let valid = call_592697.validator(path, query, header, formData, body)
  let scheme = call_592697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592697.url(scheme.get, call_592697.host, call_592697.base,
                         call_592697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592697, url, valid)

proc call*(call_592698: Call_GetBucketAcl_592691; Bucket: string; acl: bool): Recallable =
  ## getBucketAcl
  ## Gets the access control policy for the bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   acl: bool (required)
  var path_592699 = newJObject()
  var query_592700 = newJObject()
  add(path_592699, "Bucket", newJString(Bucket))
  add(query_592700, "acl", newJBool(acl))
  result = call_592698.call(path_592699, query_592700, nil, nil, nil)

var getBucketAcl* = Call_GetBucketAcl_592691(name: "getBucketAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#acl",
    validator: validate_GetBucketAcl_592692, base: "/", url: url_GetBucketAcl_592693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLifecycle_592730 = ref object of OpenApiRestCall_591364
proc url_PutBucketLifecycle_592732(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketLifecycle_592731(path: JsonNode; query: JsonNode;
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
  var valid_592733 = path.getOrDefault("Bucket")
  valid_592733 = validateParameter(valid_592733, JString, required = true,
                                 default = nil)
  if valid_592733 != nil:
    section.add "Bucket", valid_592733
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_592734 = query.getOrDefault("lifecycle")
  valid_592734 = validateParameter(valid_592734, JBool, required = true, default = nil)
  if valid_592734 != nil:
    section.add "lifecycle", valid_592734
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_592735 = header.getOrDefault("x-amz-security-token")
  valid_592735 = validateParameter(valid_592735, JString, required = false,
                                 default = nil)
  if valid_592735 != nil:
    section.add "x-amz-security-token", valid_592735
  var valid_592736 = header.getOrDefault("Content-MD5")
  valid_592736 = validateParameter(valid_592736, JString, required = false,
                                 default = nil)
  if valid_592736 != nil:
    section.add "Content-MD5", valid_592736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592738: Call_PutBucketLifecycle_592730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  let valid = call_592738.validator(path, query, header, formData, body)
  let scheme = call_592738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592738.url(scheme.get, call_592738.host, call_592738.base,
                         call_592738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592738, url, valid)

proc call*(call_592739: Call_PutBucketLifecycle_592730; Bucket: string;
          body: JsonNode; lifecycle: bool): Recallable =
  ## putBucketLifecycle
  ##  No longer used, see the PutBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   lifecycle: bool (required)
  var path_592740 = newJObject()
  var query_592741 = newJObject()
  var body_592742 = newJObject()
  add(path_592740, "Bucket", newJString(Bucket))
  if body != nil:
    body_592742 = body
  add(query_592741, "lifecycle", newJBool(lifecycle))
  result = call_592739.call(path_592740, query_592741, nil, nil, body_592742)

var putBucketLifecycle* = Call_PutBucketLifecycle_592730(
    name: "putBucketLifecycle", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_PutBucketLifecycle_592731, base: "/",
    url: url_PutBucketLifecycle_592732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLifecycle_592720 = ref object of OpenApiRestCall_591364
proc url_GetBucketLifecycle_592722(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLifecycle_592721(path: JsonNode; query: JsonNode;
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
  var valid_592723 = path.getOrDefault("Bucket")
  valid_592723 = validateParameter(valid_592723, JString, required = true,
                                 default = nil)
  if valid_592723 != nil:
    section.add "Bucket", valid_592723
  result.add "path", section
  ## parameters in `query` object:
  ##   lifecycle: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `lifecycle` field"
  var valid_592724 = query.getOrDefault("lifecycle")
  valid_592724 = validateParameter(valid_592724, JBool, required = true, default = nil)
  if valid_592724 != nil:
    section.add "lifecycle", valid_592724
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592725 = header.getOrDefault("x-amz-security-token")
  valid_592725 = validateParameter(valid_592725, JString, required = false,
                                 default = nil)
  if valid_592725 != nil:
    section.add "x-amz-security-token", valid_592725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592726: Call_GetBucketLifecycle_592720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  let valid = call_592726.validator(path, query, header, formData, body)
  let scheme = call_592726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592726.url(scheme.get, call_592726.host, call_592726.base,
                         call_592726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592726, url, valid)

proc call*(call_592727: Call_GetBucketLifecycle_592720; Bucket: string;
          lifecycle: bool): Recallable =
  ## getBucketLifecycle
  ##  No longer used, see the GetBucketLifecycleConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   lifecycle: bool (required)
  var path_592728 = newJObject()
  var query_592729 = newJObject()
  add(path_592728, "Bucket", newJString(Bucket))
  add(query_592729, "lifecycle", newJBool(lifecycle))
  result = call_592727.call(path_592728, query_592729, nil, nil, nil)

var getBucketLifecycle* = Call_GetBucketLifecycle_592720(
    name: "getBucketLifecycle", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#lifecycle&deprecated!",
    validator: validate_GetBucketLifecycle_592721, base: "/",
    url: url_GetBucketLifecycle_592722, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLocation_592743 = ref object of OpenApiRestCall_591364
proc url_GetBucketLocation_592745(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLocation_592744(path: JsonNode; query: JsonNode;
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
  var valid_592746 = path.getOrDefault("Bucket")
  valid_592746 = validateParameter(valid_592746, JString, required = true,
                                 default = nil)
  if valid_592746 != nil:
    section.add "Bucket", valid_592746
  result.add "path", section
  ## parameters in `query` object:
  ##   location: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `location` field"
  var valid_592747 = query.getOrDefault("location")
  valid_592747 = validateParameter(valid_592747, JBool, required = true, default = nil)
  if valid_592747 != nil:
    section.add "location", valid_592747
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592748 = header.getOrDefault("x-amz-security-token")
  valid_592748 = validateParameter(valid_592748, JString, required = false,
                                 default = nil)
  if valid_592748 != nil:
    section.add "x-amz-security-token", valid_592748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592749: Call_GetBucketLocation_592743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the region the bucket resides in.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  let valid = call_592749.validator(path, query, header, formData, body)
  let scheme = call_592749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592749.url(scheme.get, call_592749.host, call_592749.base,
                         call_592749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592749, url, valid)

proc call*(call_592750: Call_GetBucketLocation_592743; Bucket: string; location: bool): Recallable =
  ## getBucketLocation
  ## Returns the region the bucket resides in.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   location: bool (required)
  var path_592751 = newJObject()
  var query_592752 = newJObject()
  add(path_592751, "Bucket", newJString(Bucket))
  add(query_592752, "location", newJBool(location))
  result = call_592750.call(path_592751, query_592752, nil, nil, nil)

var getBucketLocation* = Call_GetBucketLocation_592743(name: "getBucketLocation",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#location",
    validator: validate_GetBucketLocation_592744, base: "/",
    url: url_GetBucketLocation_592745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketLogging_592763 = ref object of OpenApiRestCall_591364
proc url_PutBucketLogging_592765(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketLogging_592764(path: JsonNode; query: JsonNode;
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
  var valid_592766 = path.getOrDefault("Bucket")
  valid_592766 = validateParameter(valid_592766, JString, required = true,
                                 default = nil)
  if valid_592766 != nil:
    section.add "Bucket", valid_592766
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_592767 = query.getOrDefault("logging")
  valid_592767 = validateParameter(valid_592767, JBool, required = true, default = nil)
  if valid_592767 != nil:
    section.add "logging", valid_592767
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_592768 = header.getOrDefault("x-amz-security-token")
  valid_592768 = validateParameter(valid_592768, JString, required = false,
                                 default = nil)
  if valid_592768 != nil:
    section.add "x-amz-security-token", valid_592768
  var valid_592769 = header.getOrDefault("Content-MD5")
  valid_592769 = validateParameter(valid_592769, JString, required = false,
                                 default = nil)
  if valid_592769 != nil:
    section.add "Content-MD5", valid_592769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592771: Call_PutBucketLogging_592763; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  let valid = call_592771.validator(path, query, header, formData, body)
  let scheme = call_592771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592771.url(scheme.get, call_592771.host, call_592771.base,
                         call_592771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592771, url, valid)

proc call*(call_592772: Call_PutBucketLogging_592763; Bucket: string; logging: bool;
          body: JsonNode): Recallable =
  ## putBucketLogging
  ## Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. To set the logging status of a bucket, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   logging: bool (required)
  ##   body: JObject (required)
  var path_592773 = newJObject()
  var query_592774 = newJObject()
  var body_592775 = newJObject()
  add(path_592773, "Bucket", newJString(Bucket))
  add(query_592774, "logging", newJBool(logging))
  if body != nil:
    body_592775 = body
  result = call_592772.call(path_592773, query_592774, nil, nil, body_592775)

var putBucketLogging* = Call_PutBucketLogging_592763(name: "putBucketLogging",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_PutBucketLogging_592764, base: "/",
    url: url_PutBucketLogging_592765, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketLogging_592753 = ref object of OpenApiRestCall_591364
proc url_GetBucketLogging_592755(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketLogging_592754(path: JsonNode; query: JsonNode;
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
  var valid_592756 = path.getOrDefault("Bucket")
  valid_592756 = validateParameter(valid_592756, JString, required = true,
                                 default = nil)
  if valid_592756 != nil:
    section.add "Bucket", valid_592756
  result.add "path", section
  ## parameters in `query` object:
  ##   logging: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `logging` field"
  var valid_592757 = query.getOrDefault("logging")
  valid_592757 = validateParameter(valid_592757, JBool, required = true, default = nil)
  if valid_592757 != nil:
    section.add "logging", valid_592757
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592758 = header.getOrDefault("x-amz-security-token")
  valid_592758 = validateParameter(valid_592758, JString, required = false,
                                 default = nil)
  if valid_592758 != nil:
    section.add "x-amz-security-token", valid_592758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592759: Call_GetBucketLogging_592753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  let valid = call_592759.validator(path, query, header, formData, body)
  let scheme = call_592759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592759.url(scheme.get, call_592759.host, call_592759.base,
                         call_592759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592759, url, valid)

proc call*(call_592760: Call_GetBucketLogging_592753; Bucket: string; logging: bool): Recallable =
  ## getBucketLogging
  ## Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   logging: bool (required)
  var path_592761 = newJObject()
  var query_592762 = newJObject()
  add(path_592761, "Bucket", newJString(Bucket))
  add(query_592762, "logging", newJBool(logging))
  result = call_592760.call(path_592761, query_592762, nil, nil, nil)

var getBucketLogging* = Call_GetBucketLogging_592753(name: "getBucketLogging",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com", route: "/{Bucket}#logging",
    validator: validate_GetBucketLogging_592754, base: "/",
    url: url_GetBucketLogging_592755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotificationConfiguration_592786 = ref object of OpenApiRestCall_591364
proc url_PutBucketNotificationConfiguration_592788(protocol: Scheme; host: string;
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

proc validate_PutBucketNotificationConfiguration_592787(path: JsonNode;
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
  var valid_592789 = path.getOrDefault("Bucket")
  valid_592789 = validateParameter(valid_592789, JString, required = true,
                                 default = nil)
  if valid_592789 != nil:
    section.add "Bucket", valid_592789
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_592790 = query.getOrDefault("notification")
  valid_592790 = validateParameter(valid_592790, JBool, required = true, default = nil)
  if valid_592790 != nil:
    section.add "notification", valid_592790
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592791 = header.getOrDefault("x-amz-security-token")
  valid_592791 = validateParameter(valid_592791, JString, required = false,
                                 default = nil)
  if valid_592791 != nil:
    section.add "x-amz-security-token", valid_592791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592793: Call_PutBucketNotificationConfiguration_592786;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enables notifications of specified events for a bucket.
  ## 
  let valid = call_592793.validator(path, query, header, formData, body)
  let scheme = call_592793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592793.url(scheme.get, call_592793.host, call_592793.base,
                         call_592793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592793, url, valid)

proc call*(call_592794: Call_PutBucketNotificationConfiguration_592786;
          notification: bool; Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotificationConfiguration
  ## Enables notifications of specified events for a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_592795 = newJObject()
  var query_592796 = newJObject()
  var body_592797 = newJObject()
  add(query_592796, "notification", newJBool(notification))
  add(path_592795, "Bucket", newJString(Bucket))
  if body != nil:
    body_592797 = body
  result = call_592794.call(path_592795, query_592796, nil, nil, body_592797)

var putBucketNotificationConfiguration* = Call_PutBucketNotificationConfiguration_592786(
    name: "putBucketNotificationConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_PutBucketNotificationConfiguration_592787, base: "/",
    url: url_PutBucketNotificationConfiguration_592788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotificationConfiguration_592776 = ref object of OpenApiRestCall_591364
proc url_GetBucketNotificationConfiguration_592778(protocol: Scheme; host: string;
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

proc validate_GetBucketNotificationConfiguration_592777(path: JsonNode;
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
  var valid_592779 = path.getOrDefault("Bucket")
  valid_592779 = validateParameter(valid_592779, JString, required = true,
                                 default = nil)
  if valid_592779 != nil:
    section.add "Bucket", valid_592779
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_592780 = query.getOrDefault("notification")
  valid_592780 = validateParameter(valid_592780, JBool, required = true, default = nil)
  if valid_592780 != nil:
    section.add "notification", valid_592780
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592781 = header.getOrDefault("x-amz-security-token")
  valid_592781 = validateParameter(valid_592781, JString, required = false,
                                 default = nil)
  if valid_592781 != nil:
    section.add "x-amz-security-token", valid_592781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592782: Call_GetBucketNotificationConfiguration_592776;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the notification configuration of a bucket.
  ## 
  let valid = call_592782.validator(path, query, header, formData, body)
  let scheme = call_592782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592782.url(scheme.get, call_592782.host, call_592782.base,
                         call_592782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592782, url, valid)

proc call*(call_592783: Call_GetBucketNotificationConfiguration_592776;
          notification: bool; Bucket: string): Recallable =
  ## getBucketNotificationConfiguration
  ## Returns the notification configuration of a bucket.
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_592784 = newJObject()
  var query_592785 = newJObject()
  add(query_592785, "notification", newJBool(notification))
  add(path_592784, "Bucket", newJString(Bucket))
  result = call_592783.call(path_592784, query_592785, nil, nil, nil)

var getBucketNotificationConfiguration* = Call_GetBucketNotificationConfiguration_592776(
    name: "getBucketNotificationConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification",
    validator: validate_GetBucketNotificationConfiguration_592777, base: "/",
    url: url_GetBucketNotificationConfiguration_592778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketNotification_592808 = ref object of OpenApiRestCall_591364
proc url_PutBucketNotification_592810(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketNotification_592809(path: JsonNode; query: JsonNode;
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
  var valid_592811 = path.getOrDefault("Bucket")
  valid_592811 = validateParameter(valid_592811, JString, required = true,
                                 default = nil)
  if valid_592811 != nil:
    section.add "Bucket", valid_592811
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_592812 = query.getOrDefault("notification")
  valid_592812 = validateParameter(valid_592812, JBool, required = true, default = nil)
  if valid_592812 != nil:
    section.add "notification", valid_592812
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_592813 = header.getOrDefault("x-amz-security-token")
  valid_592813 = validateParameter(valid_592813, JString, required = false,
                                 default = nil)
  if valid_592813 != nil:
    section.add "x-amz-security-token", valid_592813
  var valid_592814 = header.getOrDefault("Content-MD5")
  valid_592814 = validateParameter(valid_592814, JString, required = false,
                                 default = nil)
  if valid_592814 != nil:
    section.add "Content-MD5", valid_592814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592816: Call_PutBucketNotification_592808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  let valid = call_592816.validator(path, query, header, formData, body)
  let scheme = call_592816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592816.url(scheme.get, call_592816.host, call_592816.base,
                         call_592816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592816, url, valid)

proc call*(call_592817: Call_PutBucketNotification_592808; notification: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketNotification
  ##  No longer used, see the PutBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_592818 = newJObject()
  var query_592819 = newJObject()
  var body_592820 = newJObject()
  add(query_592819, "notification", newJBool(notification))
  add(path_592818, "Bucket", newJString(Bucket))
  if body != nil:
    body_592820 = body
  result = call_592817.call(path_592818, query_592819, nil, nil, body_592820)

var putBucketNotification* = Call_PutBucketNotification_592808(
    name: "putBucketNotification", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_PutBucketNotification_592809, base: "/",
    url: url_PutBucketNotification_592810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketNotification_592798 = ref object of OpenApiRestCall_591364
proc url_GetBucketNotification_592800(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketNotification_592799(path: JsonNode; query: JsonNode;
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
  var valid_592801 = path.getOrDefault("Bucket")
  valid_592801 = validateParameter(valid_592801, JString, required = true,
                                 default = nil)
  if valid_592801 != nil:
    section.add "Bucket", valid_592801
  result.add "path", section
  ## parameters in `query` object:
  ##   notification: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `notification` field"
  var valid_592802 = query.getOrDefault("notification")
  valid_592802 = validateParameter(valid_592802, JBool, required = true, default = nil)
  if valid_592802 != nil:
    section.add "notification", valid_592802
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592803 = header.getOrDefault("x-amz-security-token")
  valid_592803 = validateParameter(valid_592803, JString, required = false,
                                 default = nil)
  if valid_592803 != nil:
    section.add "x-amz-security-token", valid_592803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592804: Call_GetBucketNotification_592798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  let valid = call_592804.validator(path, query, header, formData, body)
  let scheme = call_592804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592804.url(scheme.get, call_592804.host, call_592804.base,
                         call_592804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592804, url, valid)

proc call*(call_592805: Call_GetBucketNotification_592798; notification: bool;
          Bucket: string): Recallable =
  ## getBucketNotification
  ##  No longer used, see the GetBucketNotificationConfiguration operation.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
  ##   notification: bool (required)
  ##   Bucket: string (required)
  ##         : Name of the bucket to get the notification configuration for.
  var path_592806 = newJObject()
  var query_592807 = newJObject()
  add(query_592807, "notification", newJBool(notification))
  add(path_592806, "Bucket", newJString(Bucket))
  result = call_592805.call(path_592806, query_592807, nil, nil, nil)

var getBucketNotification* = Call_GetBucketNotification_592798(
    name: "getBucketNotification", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#notification&deprecated!",
    validator: validate_GetBucketNotification_592799, base: "/",
    url: url_GetBucketNotification_592800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketPolicyStatus_592821 = ref object of OpenApiRestCall_591364
proc url_GetBucketPolicyStatus_592823(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketPolicyStatus_592822(path: JsonNode; query: JsonNode;
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
  var valid_592824 = path.getOrDefault("Bucket")
  valid_592824 = validateParameter(valid_592824, JString, required = true,
                                 default = nil)
  if valid_592824 != nil:
    section.add "Bucket", valid_592824
  result.add "path", section
  ## parameters in `query` object:
  ##   policyStatus: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `policyStatus` field"
  var valid_592825 = query.getOrDefault("policyStatus")
  valid_592825 = validateParameter(valid_592825, JBool, required = true, default = nil)
  if valid_592825 != nil:
    section.add "policyStatus", valid_592825
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592826 = header.getOrDefault("x-amz-security-token")
  valid_592826 = validateParameter(valid_592826, JString, required = false,
                                 default = nil)
  if valid_592826 != nil:
    section.add "x-amz-security-token", valid_592826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592827: Call_GetBucketPolicyStatus_592821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ## 
  let valid = call_592827.validator(path, query, header, formData, body)
  let scheme = call_592827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592827.url(scheme.get, call_592827.host, call_592827.base,
                         call_592827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592827, url, valid)

proc call*(call_592828: Call_GetBucketPolicyStatus_592821; Bucket: string;
          policyStatus: bool): Recallable =
  ## getBucketPolicyStatus
  ## Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public.
  ##   Bucket: string (required)
  ##         : The name of the Amazon S3 bucket whose policy status you want to retrieve.
  ##   policyStatus: bool (required)
  var path_592829 = newJObject()
  var query_592830 = newJObject()
  add(path_592829, "Bucket", newJString(Bucket))
  add(query_592830, "policyStatus", newJBool(policyStatus))
  result = call_592828.call(path_592829, query_592830, nil, nil, nil)

var getBucketPolicyStatus* = Call_GetBucketPolicyStatus_592821(
    name: "getBucketPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#policyStatus",
    validator: validate_GetBucketPolicyStatus_592822, base: "/",
    url: url_GetBucketPolicyStatus_592823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketRequestPayment_592841 = ref object of OpenApiRestCall_591364
proc url_PutBucketRequestPayment_592843(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketRequestPayment_592842(path: JsonNode; query: JsonNode;
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
  var valid_592844 = path.getOrDefault("Bucket")
  valid_592844 = validateParameter(valid_592844, JString, required = true,
                                 default = nil)
  if valid_592844 != nil:
    section.add "Bucket", valid_592844
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_592845 = query.getOrDefault("requestPayment")
  valid_592845 = validateParameter(valid_592845, JBool, required = true, default = nil)
  if valid_592845 != nil:
    section.add "requestPayment", valid_592845
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_592846 = header.getOrDefault("x-amz-security-token")
  valid_592846 = validateParameter(valid_592846, JString, required = false,
                                 default = nil)
  if valid_592846 != nil:
    section.add "x-amz-security-token", valid_592846
  var valid_592847 = header.getOrDefault("Content-MD5")
  valid_592847 = validateParameter(valid_592847, JString, required = false,
                                 default = nil)
  if valid_592847 != nil:
    section.add "Content-MD5", valid_592847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592849: Call_PutBucketRequestPayment_592841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  let valid = call_592849.validator(path, query, header, formData, body)
  let scheme = call_592849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592849.url(scheme.get, call_592849.host, call_592849.base,
                         call_592849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592849, url, valid)

proc call*(call_592850: Call_PutBucketRequestPayment_592841; requestPayment: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putBucketRequestPayment
  ## Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. Documentation on requester pays buckets can be found at http://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  var path_592851 = newJObject()
  var query_592852 = newJObject()
  var body_592853 = newJObject()
  add(query_592852, "requestPayment", newJBool(requestPayment))
  add(path_592851, "Bucket", newJString(Bucket))
  if body != nil:
    body_592853 = body
  result = call_592850.call(path_592851, query_592852, nil, nil, body_592853)

var putBucketRequestPayment* = Call_PutBucketRequestPayment_592841(
    name: "putBucketRequestPayment", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_PutBucketRequestPayment_592842, base: "/",
    url: url_PutBucketRequestPayment_592843, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketRequestPayment_592831 = ref object of OpenApiRestCall_591364
proc url_GetBucketRequestPayment_592833(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketRequestPayment_592832(path: JsonNode; query: JsonNode;
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
  var valid_592834 = path.getOrDefault("Bucket")
  valid_592834 = validateParameter(valid_592834, JString, required = true,
                                 default = nil)
  if valid_592834 != nil:
    section.add "Bucket", valid_592834
  result.add "path", section
  ## parameters in `query` object:
  ##   requestPayment: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `requestPayment` field"
  var valid_592835 = query.getOrDefault("requestPayment")
  valid_592835 = validateParameter(valid_592835, JBool, required = true, default = nil)
  if valid_592835 != nil:
    section.add "requestPayment", valid_592835
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592836 = header.getOrDefault("x-amz-security-token")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "x-amz-security-token", valid_592836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592837: Call_GetBucketRequestPayment_592831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the request payment configuration of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  let valid = call_592837.validator(path, query, header, formData, body)
  let scheme = call_592837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592837.url(scheme.get, call_592837.host, call_592837.base,
                         call_592837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592837, url, valid)

proc call*(call_592838: Call_GetBucketRequestPayment_592831; requestPayment: bool;
          Bucket: string): Recallable =
  ## getBucketRequestPayment
  ## Returns the request payment configuration of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
  ##   requestPayment: bool (required)
  ##   Bucket: string (required)
  ##         : <p/>
  var path_592839 = newJObject()
  var query_592840 = newJObject()
  add(query_592840, "requestPayment", newJBool(requestPayment))
  add(path_592839, "Bucket", newJString(Bucket))
  result = call_592838.call(path_592839, query_592840, nil, nil, nil)

var getBucketRequestPayment* = Call_GetBucketRequestPayment_592831(
    name: "getBucketRequestPayment", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#requestPayment",
    validator: validate_GetBucketRequestPayment_592832, base: "/",
    url: url_GetBucketRequestPayment_592833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBucketVersioning_592864 = ref object of OpenApiRestCall_591364
proc url_PutBucketVersioning_592866(protocol: Scheme; host: string; base: string;
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

proc validate_PutBucketVersioning_592865(path: JsonNode; query: JsonNode;
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
  var valid_592867 = path.getOrDefault("Bucket")
  valid_592867 = validateParameter(valid_592867, JString, required = true,
                                 default = nil)
  if valid_592867 != nil:
    section.add "Bucket", valid_592867
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_592868 = query.getOrDefault("versioning")
  valid_592868 = validateParameter(valid_592868, JBool, required = true, default = nil)
  if valid_592868 != nil:
    section.add "versioning", valid_592868
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-mfa: JString
  ##            : The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  ##   Content-MD5: JString
  ##              : <p/>
  section = newJObject()
  var valid_592869 = header.getOrDefault("x-amz-security-token")
  valid_592869 = validateParameter(valid_592869, JString, required = false,
                                 default = nil)
  if valid_592869 != nil:
    section.add "x-amz-security-token", valid_592869
  var valid_592870 = header.getOrDefault("x-amz-mfa")
  valid_592870 = validateParameter(valid_592870, JString, required = false,
                                 default = nil)
  if valid_592870 != nil:
    section.add "x-amz-mfa", valid_592870
  var valid_592871 = header.getOrDefault("Content-MD5")
  valid_592871 = validateParameter(valid_592871, JString, required = false,
                                 default = nil)
  if valid_592871 != nil:
    section.add "Content-MD5", valid_592871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592873: Call_PutBucketVersioning_592864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  let valid = call_592873.validator(path, query, header, formData, body)
  let scheme = call_592873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592873.url(scheme.get, call_592873.host, call_592873.base,
                         call_592873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592873, url, valid)

proc call*(call_592874: Call_PutBucketVersioning_592864; Bucket: string;
          body: JsonNode; versioning: bool): Recallable =
  ## putBucketVersioning
  ## Sets the versioning state of an existing bucket. To set the versioning state, you must be the bucket owner.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   body: JObject (required)
  ##   versioning: bool (required)
  var path_592875 = newJObject()
  var query_592876 = newJObject()
  var body_592877 = newJObject()
  add(path_592875, "Bucket", newJString(Bucket))
  if body != nil:
    body_592877 = body
  add(query_592876, "versioning", newJBool(versioning))
  result = call_592874.call(path_592875, query_592876, nil, nil, body_592877)

var putBucketVersioning* = Call_PutBucketVersioning_592864(
    name: "putBucketVersioning", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_PutBucketVersioning_592865,
    base: "/", url: url_PutBucketVersioning_592866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBucketVersioning_592854 = ref object of OpenApiRestCall_591364
proc url_GetBucketVersioning_592856(protocol: Scheme; host: string; base: string;
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

proc validate_GetBucketVersioning_592855(path: JsonNode; query: JsonNode;
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
  var valid_592857 = path.getOrDefault("Bucket")
  valid_592857 = validateParameter(valid_592857, JString, required = true,
                                 default = nil)
  if valid_592857 != nil:
    section.add "Bucket", valid_592857
  result.add "path", section
  ## parameters in `query` object:
  ##   versioning: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `versioning` field"
  var valid_592858 = query.getOrDefault("versioning")
  valid_592858 = validateParameter(valid_592858, JBool, required = true, default = nil)
  if valid_592858 != nil:
    section.add "versioning", valid_592858
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592859 = header.getOrDefault("x-amz-security-token")
  valid_592859 = validateParameter(valid_592859, JString, required = false,
                                 default = nil)
  if valid_592859 != nil:
    section.add "x-amz-security-token", valid_592859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592860: Call_GetBucketVersioning_592854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the versioning state of a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  let valid = call_592860.validator(path, query, header, formData, body)
  let scheme = call_592860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592860.url(scheme.get, call_592860.host, call_592860.base,
                         call_592860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592860, url, valid)

proc call*(call_592861: Call_GetBucketVersioning_592854; Bucket: string;
          versioning: bool): Recallable =
  ## getBucketVersioning
  ## Returns the versioning state of a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   versioning: bool (required)
  var path_592862 = newJObject()
  var query_592863 = newJObject()
  add(path_592862, "Bucket", newJString(Bucket))
  add(query_592863, "versioning", newJBool(versioning))
  result = call_592861.call(path_592862, query_592863, nil, nil, nil)

var getBucketVersioning* = Call_GetBucketVersioning_592854(
    name: "getBucketVersioning", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versioning", validator: validate_GetBucketVersioning_592855,
    base: "/", url: url_GetBucketVersioning_592856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectAcl_592891 = ref object of OpenApiRestCall_591364
proc url_PutObjectAcl_592893(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectAcl_592892(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592894 = path.getOrDefault("Bucket")
  valid_592894 = validateParameter(valid_592894, JString, required = true,
                                 default = nil)
  if valid_592894 != nil:
    section.add "Bucket", valid_592894
  var valid_592895 = path.getOrDefault("Key")
  valid_592895 = validateParameter(valid_592895, JString, required = true,
                                 default = nil)
  if valid_592895 != nil:
    section.add "Key", valid_592895
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_592896 = query.getOrDefault("acl")
  valid_592896 = validateParameter(valid_592896, JBool, required = true, default = nil)
  if valid_592896 != nil:
    section.add "acl", valid_592896
  var valid_592897 = query.getOrDefault("versionId")
  valid_592897 = validateParameter(valid_592897, JString, required = false,
                                 default = nil)
  if valid_592897 != nil:
    section.add "versionId", valid_592897
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
  var valid_592898 = header.getOrDefault("x-amz-grant-write")
  valid_592898 = validateParameter(valid_592898, JString, required = false,
                                 default = nil)
  if valid_592898 != nil:
    section.add "x-amz-grant-write", valid_592898
  var valid_592899 = header.getOrDefault("x-amz-security-token")
  valid_592899 = validateParameter(valid_592899, JString, required = false,
                                 default = nil)
  if valid_592899 != nil:
    section.add "x-amz-security-token", valid_592899
  var valid_592900 = header.getOrDefault("x-amz-grant-read-acp")
  valid_592900 = validateParameter(valid_592900, JString, required = false,
                                 default = nil)
  if valid_592900 != nil:
    section.add "x-amz-grant-read-acp", valid_592900
  var valid_592901 = header.getOrDefault("x-amz-acl")
  valid_592901 = validateParameter(valid_592901, JString, required = false,
                                 default = newJString("private"))
  if valid_592901 != nil:
    section.add "x-amz-acl", valid_592901
  var valid_592902 = header.getOrDefault("x-amz-grant-write-acp")
  valid_592902 = validateParameter(valid_592902, JString, required = false,
                                 default = nil)
  if valid_592902 != nil:
    section.add "x-amz-grant-write-acp", valid_592902
  var valid_592903 = header.getOrDefault("x-amz-request-payer")
  valid_592903 = validateParameter(valid_592903, JString, required = false,
                                 default = newJString("requester"))
  if valid_592903 != nil:
    section.add "x-amz-request-payer", valid_592903
  var valid_592904 = header.getOrDefault("Content-MD5")
  valid_592904 = validateParameter(valid_592904, JString, required = false,
                                 default = nil)
  if valid_592904 != nil:
    section.add "Content-MD5", valid_592904
  var valid_592905 = header.getOrDefault("x-amz-grant-full-control")
  valid_592905 = validateParameter(valid_592905, JString, required = false,
                                 default = nil)
  if valid_592905 != nil:
    section.add "x-amz-grant-full-control", valid_592905
  var valid_592906 = header.getOrDefault("x-amz-grant-read")
  valid_592906 = validateParameter(valid_592906, JString, required = false,
                                 default = nil)
  if valid_592906 != nil:
    section.add "x-amz-grant-read", valid_592906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592908: Call_PutObjectAcl_592891; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## uses the acl subresource to set the access control list (ACL) permissions for an object that already exists in a bucket
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
  let valid = call_592908.validator(path, query, header, formData, body)
  let scheme = call_592908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592908.url(scheme.get, call_592908.host, call_592908.base,
                         call_592908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592908, url, valid)

proc call*(call_592909: Call_PutObjectAcl_592891; Bucket: string; acl: bool;
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
  var path_592910 = newJObject()
  var query_592911 = newJObject()
  var body_592912 = newJObject()
  add(path_592910, "Bucket", newJString(Bucket))
  add(query_592911, "acl", newJBool(acl))
  add(query_592911, "versionId", newJString(versionId))
  add(path_592910, "Key", newJString(Key))
  if body != nil:
    body_592912 = body
  result = call_592909.call(path_592910, query_592911, nil, nil, body_592912)

var putObjectAcl* = Call_PutObjectAcl_592891(name: "putObjectAcl",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_PutObjectAcl_592892,
    base: "/", url: url_PutObjectAcl_592893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAcl_592878 = ref object of OpenApiRestCall_591364
proc url_GetObjectAcl_592880(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectAcl_592879(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592881 = path.getOrDefault("Bucket")
  valid_592881 = validateParameter(valid_592881, JString, required = true,
                                 default = nil)
  if valid_592881 != nil:
    section.add "Bucket", valid_592881
  var valid_592882 = path.getOrDefault("Key")
  valid_592882 = validateParameter(valid_592882, JString, required = true,
                                 default = nil)
  if valid_592882 != nil:
    section.add "Key", valid_592882
  result.add "path", section
  ## parameters in `query` object:
  ##   acl: JBool (required)
  ##   versionId: JString
  ##            : VersionId used to reference a specific version of the object.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `acl` field"
  var valid_592883 = query.getOrDefault("acl")
  valid_592883 = validateParameter(valid_592883, JBool, required = true, default = nil)
  if valid_592883 != nil:
    section.add "acl", valid_592883
  var valid_592884 = query.getOrDefault("versionId")
  valid_592884 = validateParameter(valid_592884, JString, required = false,
                                 default = nil)
  if valid_592884 != nil:
    section.add "versionId", valid_592884
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_592885 = header.getOrDefault("x-amz-security-token")
  valid_592885 = validateParameter(valid_592885, JString, required = false,
                                 default = nil)
  if valid_592885 != nil:
    section.add "x-amz-security-token", valid_592885
  var valid_592886 = header.getOrDefault("x-amz-request-payer")
  valid_592886 = validateParameter(valid_592886, JString, required = false,
                                 default = newJString("requester"))
  if valid_592886 != nil:
    section.add "x-amz-request-payer", valid_592886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592887: Call_GetObjectAcl_592878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access control list (ACL) of an object.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
  let valid = call_592887.validator(path, query, header, formData, body)
  let scheme = call_592887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592887.url(scheme.get, call_592887.host, call_592887.base,
                         call_592887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592887, url, valid)

proc call*(call_592888: Call_GetObjectAcl_592878; Bucket: string; acl: bool;
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
  var path_592889 = newJObject()
  var query_592890 = newJObject()
  add(path_592889, "Bucket", newJString(Bucket))
  add(query_592890, "acl", newJBool(acl))
  add(query_592890, "versionId", newJString(versionId))
  add(path_592889, "Key", newJString(Key))
  result = call_592888.call(path_592889, query_592890, nil, nil, nil)

var getObjectAcl* = Call_GetObjectAcl_592878(name: "getObjectAcl",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#acl", validator: validate_GetObjectAcl_592879,
    base: "/", url: url_GetObjectAcl_592880, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLegalHold_592926 = ref object of OpenApiRestCall_591364
proc url_PutObjectLegalHold_592928(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectLegalHold_592927(path: JsonNode; query: JsonNode;
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
  var valid_592929 = path.getOrDefault("Bucket")
  valid_592929 = validateParameter(valid_592929, JString, required = true,
                                 default = nil)
  if valid_592929 != nil:
    section.add "Bucket", valid_592929
  var valid_592930 = path.getOrDefault("Key")
  valid_592930 = validateParameter(valid_592930, JString, required = true,
                                 default = nil)
  if valid_592930 != nil:
    section.add "Key", valid_592930
  result.add "path", section
  ## parameters in `query` object:
  ##   legal-hold: JBool (required)
  ##   versionId: JString
  ##            : The version ID of the object that you want to place a Legal Hold on.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_592931 = query.getOrDefault("legal-hold")
  valid_592931 = validateParameter(valid_592931, JBool, required = true, default = nil)
  if valid_592931 != nil:
    section.add "legal-hold", valid_592931
  var valid_592932 = query.getOrDefault("versionId")
  valid_592932 = validateParameter(valid_592932, JString, required = false,
                                 default = nil)
  if valid_592932 != nil:
    section.add "versionId", valid_592932
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  ##   Content-MD5: JString
  ##              : The MD5 hash for the request body.
  section = newJObject()
  var valid_592933 = header.getOrDefault("x-amz-security-token")
  valid_592933 = validateParameter(valid_592933, JString, required = false,
                                 default = nil)
  if valid_592933 != nil:
    section.add "x-amz-security-token", valid_592933
  var valid_592934 = header.getOrDefault("x-amz-request-payer")
  valid_592934 = validateParameter(valid_592934, JString, required = false,
                                 default = newJString("requester"))
  if valid_592934 != nil:
    section.add "x-amz-request-payer", valid_592934
  var valid_592935 = header.getOrDefault("Content-MD5")
  valid_592935 = validateParameter(valid_592935, JString, required = false,
                                 default = nil)
  if valid_592935 != nil:
    section.add "Content-MD5", valid_592935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592937: Call_PutObjectLegalHold_592926; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a Legal Hold configuration to the specified object.
  ## 
  let valid = call_592937.validator(path, query, header, formData, body)
  let scheme = call_592937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592937.url(scheme.get, call_592937.host, call_592937.base,
                         call_592937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592937, url, valid)

proc call*(call_592938: Call_PutObjectLegalHold_592926; Bucket: string;
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
  var path_592939 = newJObject()
  var query_592940 = newJObject()
  var body_592941 = newJObject()
  add(path_592939, "Bucket", newJString(Bucket))
  add(query_592940, "legal-hold", newJBool(legalHold))
  add(query_592940, "versionId", newJString(versionId))
  add(path_592939, "Key", newJString(Key))
  if body != nil:
    body_592941 = body
  result = call_592938.call(path_592939, query_592940, nil, nil, body_592941)

var putObjectLegalHold* = Call_PutObjectLegalHold_592926(
    name: "putObjectLegalHold", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_PutObjectLegalHold_592927,
    base: "/", url: url_PutObjectLegalHold_592928,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLegalHold_592913 = ref object of OpenApiRestCall_591364
proc url_GetObjectLegalHold_592915(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectLegalHold_592914(path: JsonNode; query: JsonNode;
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
  var valid_592916 = path.getOrDefault("Bucket")
  valid_592916 = validateParameter(valid_592916, JString, required = true,
                                 default = nil)
  if valid_592916 != nil:
    section.add "Bucket", valid_592916
  var valid_592917 = path.getOrDefault("Key")
  valid_592917 = validateParameter(valid_592917, JString, required = true,
                                 default = nil)
  if valid_592917 != nil:
    section.add "Key", valid_592917
  result.add "path", section
  ## parameters in `query` object:
  ##   legal-hold: JBool (required)
  ##   versionId: JString
  ##            : The version ID of the object whose Legal Hold status you want to retrieve.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `legal-hold` field"
  var valid_592918 = query.getOrDefault("legal-hold")
  valid_592918 = validateParameter(valid_592918, JBool, required = true, default = nil)
  if valid_592918 != nil:
    section.add "legal-hold", valid_592918
  var valid_592919 = query.getOrDefault("versionId")
  valid_592919 = validateParameter(valid_592919, JString, required = false,
                                 default = nil)
  if valid_592919 != nil:
    section.add "versionId", valid_592919
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_592920 = header.getOrDefault("x-amz-security-token")
  valid_592920 = validateParameter(valid_592920, JString, required = false,
                                 default = nil)
  if valid_592920 != nil:
    section.add "x-amz-security-token", valid_592920
  var valid_592921 = header.getOrDefault("x-amz-request-payer")
  valid_592921 = validateParameter(valid_592921, JString, required = false,
                                 default = newJString("requester"))
  if valid_592921 != nil:
    section.add "x-amz-request-payer", valid_592921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592922: Call_GetObjectLegalHold_592913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an object's current Legal Hold status.
  ## 
  let valid = call_592922.validator(path, query, header, formData, body)
  let scheme = call_592922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592922.url(scheme.get, call_592922.host, call_592922.base,
                         call_592922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592922, url, valid)

proc call*(call_592923: Call_GetObjectLegalHold_592913; Bucket: string;
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
  var path_592924 = newJObject()
  var query_592925 = newJObject()
  add(path_592924, "Bucket", newJString(Bucket))
  add(query_592925, "legal-hold", newJBool(legalHold))
  add(query_592925, "versionId", newJString(versionId))
  add(path_592924, "Key", newJString(Key))
  result = call_592923.call(path_592924, query_592925, nil, nil, nil)

var getObjectLegalHold* = Call_GetObjectLegalHold_592913(
    name: "getObjectLegalHold", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#legal-hold", validator: validate_GetObjectLegalHold_592914,
    base: "/", url: url_GetObjectLegalHold_592915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectLockConfiguration_592952 = ref object of OpenApiRestCall_591364
proc url_PutObjectLockConfiguration_592954(protocol: Scheme; host: string;
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

proc validate_PutObjectLockConfiguration_592953(path: JsonNode; query: JsonNode;
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
  var valid_592955 = path.getOrDefault("Bucket")
  valid_592955 = validateParameter(valid_592955, JString, required = true,
                                 default = nil)
  if valid_592955 != nil:
    section.add "Bucket", valid_592955
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_592956 = query.getOrDefault("object-lock")
  valid_592956 = validateParameter(valid_592956, JBool, required = true, default = nil)
  if valid_592956 != nil:
    section.add "object-lock", valid_592956
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
  var valid_592957 = header.getOrDefault("x-amz-security-token")
  valid_592957 = validateParameter(valid_592957, JString, required = false,
                                 default = nil)
  if valid_592957 != nil:
    section.add "x-amz-security-token", valid_592957
  var valid_592958 = header.getOrDefault("x-amz-bucket-object-lock-token")
  valid_592958 = validateParameter(valid_592958, JString, required = false,
                                 default = nil)
  if valid_592958 != nil:
    section.add "x-amz-bucket-object-lock-token", valid_592958
  var valid_592959 = header.getOrDefault("x-amz-request-payer")
  valid_592959 = validateParameter(valid_592959, JString, required = false,
                                 default = newJString("requester"))
  if valid_592959 != nil:
    section.add "x-amz-request-payer", valid_592959
  var valid_592960 = header.getOrDefault("Content-MD5")
  valid_592960 = validateParameter(valid_592960, JString, required = false,
                                 default = nil)
  if valid_592960 != nil:
    section.add "Content-MD5", valid_592960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592962: Call_PutObjectLockConfiguration_592952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_592962.validator(path, query, header, formData, body)
  let scheme = call_592962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592962.url(scheme.get, call_592962.host, call_592962.base,
                         call_592962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592962, url, valid)

proc call*(call_592963: Call_PutObjectLockConfiguration_592952; objectLock: bool;
          Bucket: string; body: JsonNode): Recallable =
  ## putObjectLockConfiguration
  ## Places an object lock configuration on the specified bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to create or replace.
  ##   body: JObject (required)
  var path_592964 = newJObject()
  var query_592965 = newJObject()
  var body_592966 = newJObject()
  add(query_592965, "object-lock", newJBool(objectLock))
  add(path_592964, "Bucket", newJString(Bucket))
  if body != nil:
    body_592966 = body
  result = call_592963.call(path_592964, query_592965, nil, nil, body_592966)

var putObjectLockConfiguration* = Call_PutObjectLockConfiguration_592952(
    name: "putObjectLockConfiguration", meth: HttpMethod.HttpPut,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_PutObjectLockConfiguration_592953, base: "/",
    url: url_PutObjectLockConfiguration_592954,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectLockConfiguration_592942 = ref object of OpenApiRestCall_591364
proc url_GetObjectLockConfiguration_592944(protocol: Scheme; host: string;
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

proc validate_GetObjectLockConfiguration_592943(path: JsonNode; query: JsonNode;
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
  var valid_592945 = path.getOrDefault("Bucket")
  valid_592945 = validateParameter(valid_592945, JString, required = true,
                                 default = nil)
  if valid_592945 != nil:
    section.add "Bucket", valid_592945
  result.add "path", section
  ## parameters in `query` object:
  ##   object-lock: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `object-lock` field"
  var valid_592946 = query.getOrDefault("object-lock")
  valid_592946 = validateParameter(valid_592946, JBool, required = true, default = nil)
  if valid_592946 != nil:
    section.add "object-lock", valid_592946
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_592947 = header.getOrDefault("x-amz-security-token")
  valid_592947 = validateParameter(valid_592947, JString, required = false,
                                 default = nil)
  if valid_592947 != nil:
    section.add "x-amz-security-token", valid_592947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592948: Call_GetObjectLockConfiguration_592942; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ## 
  let valid = call_592948.validator(path, query, header, formData, body)
  let scheme = call_592948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592948.url(scheme.get, call_592948.host, call_592948.base,
                         call_592948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592948, url, valid)

proc call*(call_592949: Call_GetObjectLockConfiguration_592942; objectLock: bool;
          Bucket: string): Recallable =
  ## getObjectLockConfiguration
  ## Gets the object lock configuration for a bucket. The rule specified in the object lock configuration will be applied by default to every new object placed in the specified bucket.
  ##   objectLock: bool (required)
  ##   Bucket: string (required)
  ##         : The bucket whose object lock configuration you want to retrieve.
  var path_592950 = newJObject()
  var query_592951 = newJObject()
  add(query_592951, "object-lock", newJBool(objectLock))
  add(path_592950, "Bucket", newJString(Bucket))
  result = call_592949.call(path_592950, query_592951, nil, nil, nil)

var getObjectLockConfiguration* = Call_GetObjectLockConfiguration_592942(
    name: "getObjectLockConfiguration", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#object-lock",
    validator: validate_GetObjectLockConfiguration_592943, base: "/",
    url: url_GetObjectLockConfiguration_592944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutObjectRetention_592980 = ref object of OpenApiRestCall_591364
proc url_PutObjectRetention_592982(protocol: Scheme; host: string; base: string;
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

proc validate_PutObjectRetention_592981(path: JsonNode; query: JsonNode;
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
  var valid_592983 = path.getOrDefault("Bucket")
  valid_592983 = validateParameter(valid_592983, JString, required = true,
                                 default = nil)
  if valid_592983 != nil:
    section.add "Bucket", valid_592983
  var valid_592984 = path.getOrDefault("Key")
  valid_592984 = validateParameter(valid_592984, JString, required = true,
                                 default = nil)
  if valid_592984 != nil:
    section.add "Key", valid_592984
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object that you want to apply this Object Retention configuration to.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_592985 = query.getOrDefault("versionId")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "versionId", valid_592985
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_592986 = query.getOrDefault("retention")
  valid_592986 = validateParameter(valid_592986, JBool, required = true, default = nil)
  if valid_592986 != nil:
    section.add "retention", valid_592986
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
  var valid_592987 = header.getOrDefault("x-amz-bypass-governance-retention")
  valid_592987 = validateParameter(valid_592987, JBool, required = false, default = nil)
  if valid_592987 != nil:
    section.add "x-amz-bypass-governance-retention", valid_592987
  var valid_592988 = header.getOrDefault("x-amz-security-token")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "x-amz-security-token", valid_592988
  var valid_592989 = header.getOrDefault("x-amz-request-payer")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = newJString("requester"))
  if valid_592989 != nil:
    section.add "x-amz-request-payer", valid_592989
  var valid_592990 = header.getOrDefault("Content-MD5")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "Content-MD5", valid_592990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592992: Call_PutObjectRetention_592980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Places an Object Retention configuration on an object.
  ## 
  let valid = call_592992.validator(path, query, header, formData, body)
  let scheme = call_592992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592992.url(scheme.get, call_592992.host, call_592992.base,
                         call_592992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592992, url, valid)

proc call*(call_592993: Call_PutObjectRetention_592980; Bucket: string; Key: string;
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
  var path_592994 = newJObject()
  var query_592995 = newJObject()
  var body_592996 = newJObject()
  add(path_592994, "Bucket", newJString(Bucket))
  add(query_592995, "versionId", newJString(versionId))
  add(path_592994, "Key", newJString(Key))
  add(query_592995, "retention", newJBool(retention))
  if body != nil:
    body_592996 = body
  result = call_592993.call(path_592994, query_592995, nil, nil, body_592996)

var putObjectRetention* = Call_PutObjectRetention_592980(
    name: "putObjectRetention", meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_PutObjectRetention_592981,
    base: "/", url: url_PutObjectRetention_592982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectRetention_592967 = ref object of OpenApiRestCall_591364
proc url_GetObjectRetention_592969(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectRetention_592968(path: JsonNode; query: JsonNode;
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
  var valid_592970 = path.getOrDefault("Bucket")
  valid_592970 = validateParameter(valid_592970, JString, required = true,
                                 default = nil)
  if valid_592970 != nil:
    section.add "Bucket", valid_592970
  var valid_592971 = path.getOrDefault("Key")
  valid_592971 = validateParameter(valid_592971, JString, required = true,
                                 default = nil)
  if valid_592971 != nil:
    section.add "Key", valid_592971
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The version ID for the object whose retention settings you want to retrieve.
  ##   retention: JBool (required)
  section = newJObject()
  var valid_592972 = query.getOrDefault("versionId")
  valid_592972 = validateParameter(valid_592972, JString, required = false,
                                 default = nil)
  if valid_592972 != nil:
    section.add "versionId", valid_592972
  assert query != nil,
        "query argument is necessary due to required `retention` field"
  var valid_592973 = query.getOrDefault("retention")
  valid_592973 = validateParameter(valid_592973, JBool, required = true, default = nil)
  if valid_592973 != nil:
    section.add "retention", valid_592973
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_592974 = header.getOrDefault("x-amz-security-token")
  valid_592974 = validateParameter(valid_592974, JString, required = false,
                                 default = nil)
  if valid_592974 != nil:
    section.add "x-amz-security-token", valid_592974
  var valid_592975 = header.getOrDefault("x-amz-request-payer")
  valid_592975 = validateParameter(valid_592975, JString, required = false,
                                 default = newJString("requester"))
  if valid_592975 != nil:
    section.add "x-amz-request-payer", valid_592975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592976: Call_GetObjectRetention_592967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an object's retention settings.
  ## 
  let valid = call_592976.validator(path, query, header, formData, body)
  let scheme = call_592976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592976.url(scheme.get, call_592976.host, call_592976.base,
                         call_592976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592976, url, valid)

proc call*(call_592977: Call_GetObjectRetention_592967; Bucket: string; Key: string;
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
  var path_592978 = newJObject()
  var query_592979 = newJObject()
  add(path_592978, "Bucket", newJString(Bucket))
  add(query_592979, "versionId", newJString(versionId))
  add(path_592978, "Key", newJString(Key))
  add(query_592979, "retention", newJBool(retention))
  result = call_592977.call(path_592978, query_592979, nil, nil, nil)

var getObjectRetention* = Call_GetObjectRetention_592967(
    name: "getObjectRetention", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#retention", validator: validate_GetObjectRetention_592968,
    base: "/", url: url_GetObjectRetention_592969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectTorrent_592997 = ref object of OpenApiRestCall_591364
proc url_GetObjectTorrent_592999(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectTorrent_592998(path: JsonNode; query: JsonNode;
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
  var valid_593000 = path.getOrDefault("Bucket")
  valid_593000 = validateParameter(valid_593000, JString, required = true,
                                 default = nil)
  if valid_593000 != nil:
    section.add "Bucket", valid_593000
  var valid_593001 = path.getOrDefault("Key")
  valid_593001 = validateParameter(valid_593001, JString, required = true,
                                 default = nil)
  if valid_593001 != nil:
    section.add "Key", valid_593001
  result.add "path", section
  ## parameters in `query` object:
  ##   torrent: JBool (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `torrent` field"
  var valid_593002 = query.getOrDefault("torrent")
  valid_593002 = validateParameter(valid_593002, JBool, required = true, default = nil)
  if valid_593002 != nil:
    section.add "torrent", valid_593002
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_593003 = header.getOrDefault("x-amz-security-token")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "x-amz-security-token", valid_593003
  var valid_593004 = header.getOrDefault("x-amz-request-payer")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = newJString("requester"))
  if valid_593004 != nil:
    section.add "x-amz-request-payer", valid_593004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593005: Call_GetObjectTorrent_592997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return torrent files from a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  let valid = call_593005.validator(path, query, header, formData, body)
  let scheme = call_593005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593005.url(scheme.get, call_593005.host, call_593005.base,
                         call_593005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593005, url, valid)

proc call*(call_593006: Call_GetObjectTorrent_592997; Bucket: string; Key: string;
          torrent: bool): Recallable =
  ## getObjectTorrent
  ## Return torrent files from a bucket.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
  ##   Bucket: string (required)
  ##         : <p/>
  ##   Key: string (required)
  ##      : <p/>
  ##   torrent: bool (required)
  var path_593007 = newJObject()
  var query_593008 = newJObject()
  add(path_593007, "Bucket", newJString(Bucket))
  add(path_593007, "Key", newJString(Key))
  add(query_593008, "torrent", newJBool(torrent))
  result = call_593006.call(path_593007, query_593008, nil, nil, nil)

var getObjectTorrent* = Call_GetObjectTorrent_592997(name: "getObjectTorrent",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#torrent", validator: validate_GetObjectTorrent_592998,
    base: "/", url: url_GetObjectTorrent_592999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketAnalyticsConfigurations_593009 = ref object of OpenApiRestCall_591364
proc url_ListBucketAnalyticsConfigurations_593011(protocol: Scheme; host: string;
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

proc validate_ListBucketAnalyticsConfigurations_593010(path: JsonNode;
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
  var valid_593012 = path.getOrDefault("Bucket")
  valid_593012 = validateParameter(valid_593012, JString, required = true,
                                 default = nil)
  if valid_593012 != nil:
    section.add "Bucket", valid_593012
  result.add "path", section
  ## parameters in `query` object:
  ##   continuation-token: JString
  ##                     : The ContinuationToken that represents a placeholder from where this request should begin.
  ##   analytics: JBool (required)
  section = newJObject()
  var valid_593013 = query.getOrDefault("continuation-token")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "continuation-token", valid_593013
  assert query != nil,
        "query argument is necessary due to required `analytics` field"
  var valid_593014 = query.getOrDefault("analytics")
  valid_593014 = validateParameter(valid_593014, JBool, required = true, default = nil)
  if valid_593014 != nil:
    section.add "analytics", valid_593014
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593015 = header.getOrDefault("x-amz-security-token")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "x-amz-security-token", valid_593015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593016: Call_ListBucketAnalyticsConfigurations_593009;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the analytics configurations for the bucket.
  ## 
  let valid = call_593016.validator(path, query, header, formData, body)
  let scheme = call_593016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593016.url(scheme.get, call_593016.host, call_593016.base,
                         call_593016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593016, url, valid)

proc call*(call_593017: Call_ListBucketAnalyticsConfigurations_593009;
          Bucket: string; analytics: bool; continuationToken: string = ""): Recallable =
  ## listBucketAnalyticsConfigurations
  ## Lists the analytics configurations for the bucket.
  ##   continuationToken: string
  ##                    : The ContinuationToken that represents a placeholder from where this request should begin.
  ##   Bucket: string (required)
  ##         : The name of the bucket from which analytics configurations are retrieved.
  ##   analytics: bool (required)
  var path_593018 = newJObject()
  var query_593019 = newJObject()
  add(query_593019, "continuation-token", newJString(continuationToken))
  add(path_593018, "Bucket", newJString(Bucket))
  add(query_593019, "analytics", newJBool(analytics))
  result = call_593017.call(path_593018, query_593019, nil, nil, nil)

var listBucketAnalyticsConfigurations* = Call_ListBucketAnalyticsConfigurations_593009(
    name: "listBucketAnalyticsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#analytics",
    validator: validate_ListBucketAnalyticsConfigurations_593010, base: "/",
    url: url_ListBucketAnalyticsConfigurations_593011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketInventoryConfigurations_593020 = ref object of OpenApiRestCall_591364
proc url_ListBucketInventoryConfigurations_593022(protocol: Scheme; host: string;
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

proc validate_ListBucketInventoryConfigurations_593021(path: JsonNode;
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
  var valid_593023 = path.getOrDefault("Bucket")
  valid_593023 = validateParameter(valid_593023, JString, required = true,
                                 default = nil)
  if valid_593023 != nil:
    section.add "Bucket", valid_593023
  result.add "path", section
  ## parameters in `query` object:
  ##   continuation-token: JString
  ##                     : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   inventory: JBool (required)
  section = newJObject()
  var valid_593024 = query.getOrDefault("continuation-token")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "continuation-token", valid_593024
  assert query != nil,
        "query argument is necessary due to required `inventory` field"
  var valid_593025 = query.getOrDefault("inventory")
  valid_593025 = validateParameter(valid_593025, JBool, required = true, default = nil)
  if valid_593025 != nil:
    section.add "inventory", valid_593025
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593026 = header.getOrDefault("x-amz-security-token")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "x-amz-security-token", valid_593026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593027: Call_ListBucketInventoryConfigurations_593020;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of inventory configurations for the bucket.
  ## 
  let valid = call_593027.validator(path, query, header, formData, body)
  let scheme = call_593027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593027.url(scheme.get, call_593027.host, call_593027.base,
                         call_593027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593027, url, valid)

proc call*(call_593028: Call_ListBucketInventoryConfigurations_593020;
          Bucket: string; inventory: bool; continuationToken: string = ""): Recallable =
  ## listBucketInventoryConfigurations
  ## Returns a list of inventory configurations for the bucket.
  ##   continuationToken: string
  ##                    : The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the inventory configurations to retrieve.
  ##   inventory: bool (required)
  var path_593029 = newJObject()
  var query_593030 = newJObject()
  add(query_593030, "continuation-token", newJString(continuationToken))
  add(path_593029, "Bucket", newJString(Bucket))
  add(query_593030, "inventory", newJBool(inventory))
  result = call_593028.call(path_593029, query_593030, nil, nil, nil)

var listBucketInventoryConfigurations* = Call_ListBucketInventoryConfigurations_593020(
    name: "listBucketInventoryConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#inventory",
    validator: validate_ListBucketInventoryConfigurations_593021, base: "/",
    url: url_ListBucketInventoryConfigurations_593022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBucketMetricsConfigurations_593031 = ref object of OpenApiRestCall_591364
proc url_ListBucketMetricsConfigurations_593033(protocol: Scheme; host: string;
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

proc validate_ListBucketMetricsConfigurations_593032(path: JsonNode;
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
  var valid_593034 = path.getOrDefault("Bucket")
  valid_593034 = validateParameter(valid_593034, JString, required = true,
                                 default = nil)
  if valid_593034 != nil:
    section.add "Bucket", valid_593034
  result.add "path", section
  ## parameters in `query` object:
  ##   continuation-token: JString
  ##                     : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   metrics: JBool (required)
  section = newJObject()
  var valid_593035 = query.getOrDefault("continuation-token")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "continuation-token", valid_593035
  assert query != nil, "query argument is necessary due to required `metrics` field"
  var valid_593036 = query.getOrDefault("metrics")
  valid_593036 = validateParameter(valid_593036, JBool, required = true, default = nil)
  if valid_593036 != nil:
    section.add "metrics", valid_593036
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593037 = header.getOrDefault("x-amz-security-token")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "x-amz-security-token", valid_593037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593038: Call_ListBucketMetricsConfigurations_593031;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the metrics configurations for the bucket.
  ## 
  let valid = call_593038.validator(path, query, header, formData, body)
  let scheme = call_593038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593038.url(scheme.get, call_593038.host, call_593038.base,
                         call_593038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593038, url, valid)

proc call*(call_593039: Call_ListBucketMetricsConfigurations_593031;
          Bucket: string; metrics: bool; continuationToken: string = ""): Recallable =
  ## listBucketMetricsConfigurations
  ## Lists the metrics configurations for the bucket.
  ##   continuationToken: string
  ##                    : The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  ##   Bucket: string (required)
  ##         : The name of the bucket containing the metrics configurations to retrieve.
  ##   metrics: bool (required)
  var path_593040 = newJObject()
  var query_593041 = newJObject()
  add(query_593041, "continuation-token", newJString(continuationToken))
  add(path_593040, "Bucket", newJString(Bucket))
  add(query_593041, "metrics", newJBool(metrics))
  result = call_593039.call(path_593040, query_593041, nil, nil, nil)

var listBucketMetricsConfigurations* = Call_ListBucketMetricsConfigurations_593031(
    name: "listBucketMetricsConfigurations", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#metrics",
    validator: validate_ListBucketMetricsConfigurations_593032, base: "/",
    url: url_ListBucketMetricsConfigurations_593033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuckets_593042 = ref object of OpenApiRestCall_591364
proc url_ListBuckets_593044(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuckets_593043(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593045 = header.getOrDefault("x-amz-security-token")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "x-amz-security-token", valid_593045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593046: Call_ListBuckets_593042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  let valid = call_593046.validator(path, query, header, formData, body)
  let scheme = call_593046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593046.url(scheme.get, call_593046.host, call_593046.base,
                         call_593046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593046, url, valid)

proc call*(call_593047: Call_ListBuckets_593042): Recallable =
  ## listBuckets
  ## Returns a list of all buckets owned by the authenticated sender of the request.
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
  result = call_593047.call(nil, nil, nil, nil, nil)

var listBuckets* = Call_ListBuckets_593042(name: "listBuckets",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3.amazonaws.com", route: "/",
                                        validator: validate_ListBuckets_593043,
                                        base: "/", url: url_ListBuckets_593044,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultipartUploads_593048 = ref object of OpenApiRestCall_591364
proc url_ListMultipartUploads_593050(protocol: Scheme; host: string; base: string;
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

proc validate_ListMultipartUploads_593049(path: JsonNode; query: JsonNode;
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
  var valid_593051 = path.getOrDefault("Bucket")
  valid_593051 = validateParameter(valid_593051, JString, required = true,
                                 default = nil)
  if valid_593051 != nil:
    section.add "Bucket", valid_593051
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
  var valid_593052 = query.getOrDefault("MaxUploads")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "MaxUploads", valid_593052
  var valid_593053 = query.getOrDefault("KeyMarker")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "KeyMarker", valid_593053
  var valid_593054 = query.getOrDefault("prefix")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "prefix", valid_593054
  var valid_593055 = query.getOrDefault("max-uploads")
  valid_593055 = validateParameter(valid_593055, JInt, required = false, default = nil)
  if valid_593055 != nil:
    section.add "max-uploads", valid_593055
  var valid_593056 = query.getOrDefault("UploadIdMarker")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "UploadIdMarker", valid_593056
  var valid_593057 = query.getOrDefault("key-marker")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "key-marker", valid_593057
  var valid_593058 = query.getOrDefault("upload-id-marker")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "upload-id-marker", valid_593058
  assert query != nil, "query argument is necessary due to required `uploads` field"
  var valid_593059 = query.getOrDefault("uploads")
  valid_593059 = validateParameter(valid_593059, JBool, required = true, default = nil)
  if valid_593059 != nil:
    section.add "uploads", valid_593059
  var valid_593060 = query.getOrDefault("encoding-type")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = newJString("url"))
  if valid_593060 != nil:
    section.add "encoding-type", valid_593060
  var valid_593061 = query.getOrDefault("delimiter")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "delimiter", valid_593061
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593062 = header.getOrDefault("x-amz-security-token")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "x-amz-security-token", valid_593062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593063: Call_ListMultipartUploads_593048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists in-progress multipart uploads.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
  let valid = call_593063.validator(path, query, header, formData, body)
  let scheme = call_593063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593063.url(scheme.get, call_593063.host, call_593063.base,
                         call_593063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593063, url, valid)

proc call*(call_593064: Call_ListMultipartUploads_593048; Bucket: string;
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
  var path_593065 = newJObject()
  var query_593066 = newJObject()
  add(query_593066, "MaxUploads", newJString(MaxUploads))
  add(query_593066, "KeyMarker", newJString(KeyMarker))
  add(query_593066, "prefix", newJString(prefix))
  add(path_593065, "Bucket", newJString(Bucket))
  add(query_593066, "max-uploads", newJInt(maxUploads))
  add(query_593066, "UploadIdMarker", newJString(UploadIdMarker))
  add(query_593066, "key-marker", newJString(keyMarker))
  add(query_593066, "upload-id-marker", newJString(uploadIdMarker))
  add(query_593066, "uploads", newJBool(uploads))
  add(query_593066, "encoding-type", newJString(encodingType))
  add(query_593066, "delimiter", newJString(delimiter))
  result = call_593064.call(path_593065, query_593066, nil, nil, nil)

var listMultipartUploads* = Call_ListMultipartUploads_593048(
    name: "listMultipartUploads", meth: HttpMethod.HttpGet,
    host: "s3.amazonaws.com", route: "/{Bucket}#uploads",
    validator: validate_ListMultipartUploads_593049, base: "/",
    url: url_ListMultipartUploads_593050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectVersions_593067 = ref object of OpenApiRestCall_591364
proc url_ListObjectVersions_593069(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectVersions_593068(path: JsonNode; query: JsonNode;
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
  var valid_593070 = path.getOrDefault("Bucket")
  valid_593070 = validateParameter(valid_593070, JString, required = true,
                                 default = nil)
  if valid_593070 != nil:
    section.add "Bucket", valid_593070
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
  var valid_593071 = query.getOrDefault("KeyMarker")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "KeyMarker", valid_593071
  var valid_593072 = query.getOrDefault("prefix")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "prefix", valid_593072
  var valid_593073 = query.getOrDefault("version-id-marker")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "version-id-marker", valid_593073
  var valid_593074 = query.getOrDefault("MaxKeys")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "MaxKeys", valid_593074
  var valid_593075 = query.getOrDefault("VersionIdMarker")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "VersionIdMarker", valid_593075
  var valid_593076 = query.getOrDefault("key-marker")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "key-marker", valid_593076
  var valid_593077 = query.getOrDefault("max-keys")
  valid_593077 = validateParameter(valid_593077, JInt, required = false, default = nil)
  if valid_593077 != nil:
    section.add "max-keys", valid_593077
  var valid_593078 = query.getOrDefault("encoding-type")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = newJString("url"))
  if valid_593078 != nil:
    section.add "encoding-type", valid_593078
  var valid_593079 = query.getOrDefault("delimiter")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "delimiter", valid_593079
  assert query != nil,
        "query argument is necessary due to required `versions` field"
  var valid_593080 = query.getOrDefault("versions")
  valid_593080 = validateParameter(valid_593080, JBool, required = true, default = nil)
  if valid_593080 != nil:
    section.add "versions", valid_593080
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  section = newJObject()
  var valid_593081 = header.getOrDefault("x-amz-security-token")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "x-amz-security-token", valid_593081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593082: Call_ListObjectVersions_593067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about all of the versions of objects in a bucket.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
  let valid = call_593082.validator(path, query, header, formData, body)
  let scheme = call_593082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593082.url(scheme.get, call_593082.host, call_593082.base,
                         call_593082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593082, url, valid)

proc call*(call_593083: Call_ListObjectVersions_593067; Bucket: string;
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
  var path_593084 = newJObject()
  var query_593085 = newJObject()
  add(query_593085, "KeyMarker", newJString(KeyMarker))
  add(query_593085, "prefix", newJString(prefix))
  add(path_593084, "Bucket", newJString(Bucket))
  add(query_593085, "version-id-marker", newJString(versionIdMarker))
  add(query_593085, "MaxKeys", newJString(MaxKeys))
  add(query_593085, "VersionIdMarker", newJString(VersionIdMarker))
  add(query_593085, "key-marker", newJString(keyMarker))
  add(query_593085, "max-keys", newJInt(maxKeys))
  add(query_593085, "encoding-type", newJString(encodingType))
  add(query_593085, "delimiter", newJString(delimiter))
  add(query_593085, "versions", newJBool(versions))
  result = call_593083.call(path_593084, query_593085, nil, nil, nil)

var listObjectVersions* = Call_ListObjectVersions_593067(
    name: "listObjectVersions", meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#versions", validator: validate_ListObjectVersions_593068,
    base: "/", url: url_ListObjectVersions_593069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectsV2_593086 = ref object of OpenApiRestCall_591364
proc url_ListObjectsV2_593088(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectsV2_593087(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593089 = path.getOrDefault("Bucket")
  valid_593089 = validateParameter(valid_593089, JString, required = true,
                                 default = nil)
  if valid_593089 != nil:
    section.add "Bucket", valid_593089
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
  var valid_593090 = query.getOrDefault("ContinuationToken")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "ContinuationToken", valid_593090
  var valid_593091 = query.getOrDefault("continuation-token")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "continuation-token", valid_593091
  var valid_593092 = query.getOrDefault("fetch-owner")
  valid_593092 = validateParameter(valid_593092, JBool, required = false, default = nil)
  if valid_593092 != nil:
    section.add "fetch-owner", valid_593092
  var valid_593093 = query.getOrDefault("prefix")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "prefix", valid_593093
  assert query != nil,
        "query argument is necessary due to required `list-type` field"
  var valid_593094 = query.getOrDefault("list-type")
  valid_593094 = validateParameter(valid_593094, JString, required = true,
                                 default = newJString("2"))
  if valid_593094 != nil:
    section.add "list-type", valid_593094
  var valid_593095 = query.getOrDefault("MaxKeys")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "MaxKeys", valid_593095
  var valid_593096 = query.getOrDefault("start-after")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "start-after", valid_593096
  var valid_593097 = query.getOrDefault("max-keys")
  valid_593097 = validateParameter(valid_593097, JInt, required = false, default = nil)
  if valid_593097 != nil:
    section.add "max-keys", valid_593097
  var valid_593098 = query.getOrDefault("encoding-type")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = newJString("url"))
  if valid_593098 != nil:
    section.add "encoding-type", valid_593098
  var valid_593099 = query.getOrDefault("delimiter")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "delimiter", valid_593099
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_593100 = header.getOrDefault("x-amz-security-token")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "x-amz-security-token", valid_593100
  var valid_593101 = header.getOrDefault("x-amz-request-payer")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = newJString("requester"))
  if valid_593101 != nil:
    section.add "x-amz-request-payer", valid_593101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593102: Call_ListObjectsV2_593086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns some or all (up to 1000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. Note: ListObjectsV2 is the revised List Objects API and we recommend you use this revised API for new application development.
  ## 
  let valid = call_593102.validator(path, query, header, formData, body)
  let scheme = call_593102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593102.url(scheme.get, call_593102.host, call_593102.base,
                         call_593102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593102, url, valid)

proc call*(call_593103: Call_ListObjectsV2_593086; Bucket: string;
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
  var path_593104 = newJObject()
  var query_593105 = newJObject()
  add(query_593105, "ContinuationToken", newJString(ContinuationToken))
  add(query_593105, "continuation-token", newJString(continuationToken))
  add(query_593105, "fetch-owner", newJBool(fetchOwner))
  add(query_593105, "prefix", newJString(prefix))
  add(path_593104, "Bucket", newJString(Bucket))
  add(query_593105, "list-type", newJString(listType))
  add(query_593105, "MaxKeys", newJString(MaxKeys))
  add(query_593105, "start-after", newJString(startAfter))
  add(query_593105, "max-keys", newJInt(maxKeys))
  add(query_593105, "encoding-type", newJString(encodingType))
  add(query_593105, "delimiter", newJString(delimiter))
  result = call_593103.call(path_593104, query_593105, nil, nil, nil)

var listObjectsV2* = Call_ListObjectsV2_593086(name: "listObjectsV2",
    meth: HttpMethod.HttpGet, host: "s3.amazonaws.com",
    route: "/{Bucket}#list-type=2", validator: validate_ListObjectsV2_593087,
    base: "/", url: url_ListObjectsV2_593088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreObject_593106 = ref object of OpenApiRestCall_591364
proc url_RestoreObject_593108(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreObject_593107(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593109 = path.getOrDefault("Bucket")
  valid_593109 = validateParameter(valid_593109, JString, required = true,
                                 default = nil)
  if valid_593109 != nil:
    section.add "Bucket", valid_593109
  var valid_593110 = path.getOrDefault("Key")
  valid_593110 = validateParameter(valid_593110, JString, required = true,
                                 default = nil)
  if valid_593110 != nil:
    section.add "Key", valid_593110
  result.add "path", section
  ## parameters in `query` object:
  ##   restore: JBool (required)
  ##   versionId: JString
  ##            : <p/>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `restore` field"
  var valid_593111 = query.getOrDefault("restore")
  valid_593111 = validateParameter(valid_593111, JBool, required = true, default = nil)
  if valid_593111 != nil:
    section.add "restore", valid_593111
  var valid_593112 = query.getOrDefault("versionId")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "versionId", valid_593112
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-security-token: JString
  ##   x-amz-request-payer: JString
  ##                      : Confirms that the requester knows that she or he will be charged for the request. Bucket owners need not specify this parameter in their requests. Documentation on downloading objects from requester pays buckets can be found at 
  ## http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
  section = newJObject()
  var valid_593113 = header.getOrDefault("x-amz-security-token")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "x-amz-security-token", valid_593113
  var valid_593114 = header.getOrDefault("x-amz-request-payer")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = newJString("requester"))
  if valid_593114 != nil:
    section.add "x-amz-request-payer", valid_593114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593116: Call_RestoreObject_593106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restores an archived copy of an object back into Amazon S3
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
  let valid = call_593116.validator(path, query, header, formData, body)
  let scheme = call_593116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593116.url(scheme.get, call_593116.host, call_593116.base,
                         call_593116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593116, url, valid)

proc call*(call_593117: Call_RestoreObject_593106; restore: bool; Bucket: string;
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
  var path_593118 = newJObject()
  var query_593119 = newJObject()
  var body_593120 = newJObject()
  add(query_593119, "restore", newJBool(restore))
  add(path_593118, "Bucket", newJString(Bucket))
  add(query_593119, "versionId", newJString(versionId))
  add(path_593118, "Key", newJString(Key))
  if body != nil:
    body_593120 = body
  result = call_593117.call(path_593118, query_593119, nil, nil, body_593120)

var restoreObject* = Call_RestoreObject_593106(name: "restoreObject",
    meth: HttpMethod.HttpPost, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#restore", validator: validate_RestoreObject_593107,
    base: "/", url: url_RestoreObject_593108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SelectObjectContent_593121 = ref object of OpenApiRestCall_591364
proc url_SelectObjectContent_593123(protocol: Scheme; host: string; base: string;
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

proc validate_SelectObjectContent_593122(path: JsonNode; query: JsonNode;
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
  var valid_593124 = path.getOrDefault("Bucket")
  valid_593124 = validateParameter(valid_593124, JString, required = true,
                                 default = nil)
  if valid_593124 != nil:
    section.add "Bucket", valid_593124
  var valid_593125 = path.getOrDefault("Key")
  valid_593125 = validateParameter(valid_593125, JString, required = true,
                                 default = nil)
  if valid_593125 != nil:
    section.add "Key", valid_593125
  result.add "path", section
  ## parameters in `query` object:
  ##   select: JBool (required)
  ##   select-type: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `select` field"
  var valid_593126 = query.getOrDefault("select")
  valid_593126 = validateParameter(valid_593126, JBool, required = true, default = nil)
  if valid_593126 != nil:
    section.add "select", valid_593126
  var valid_593127 = query.getOrDefault("select-type")
  valid_593127 = validateParameter(valid_593127, JString, required = true,
                                 default = newJString("2"))
  if valid_593127 != nil:
    section.add "select-type", valid_593127
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
  var valid_593128 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_593128
  var valid_593129 = header.getOrDefault("x-amz-security-token")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "x-amz-security-token", valid_593129
  var valid_593130 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_593130
  var valid_593131 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_593131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593133: Call_SelectObjectContent_593121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation filters the contents of an Amazon S3 object based on a simple Structured Query Language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON or CSV) of the object. Amazon S3 uses this to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.
  ## 
  let valid = call_593133.validator(path, query, header, formData, body)
  let scheme = call_593133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593133.url(scheme.get, call_593133.host, call_593133.base,
                         call_593133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593133, url, valid)

proc call*(call_593134: Call_SelectObjectContent_593121; Bucket: string;
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
  var path_593135 = newJObject()
  var query_593136 = newJObject()
  var body_593137 = newJObject()
  add(path_593135, "Bucket", newJString(Bucket))
  add(query_593136, "select", newJBool(select))
  add(path_593135, "Key", newJString(Key))
  add(query_593136, "select-type", newJString(selectType))
  if body != nil:
    body_593137 = body
  result = call_593134.call(path_593135, query_593136, nil, nil, body_593137)

var selectObjectContent* = Call_SelectObjectContent_593121(
    name: "selectObjectContent", meth: HttpMethod.HttpPost,
    host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#select&select-type=2",
    validator: validate_SelectObjectContent_593122, base: "/",
    url: url_SelectObjectContent_593123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPart_593138 = ref object of OpenApiRestCall_591364
proc url_UploadPart_593140(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UploadPart_593139(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593141 = path.getOrDefault("Bucket")
  valid_593141 = validateParameter(valid_593141, JString, required = true,
                                 default = nil)
  if valid_593141 != nil:
    section.add "Bucket", valid_593141
  var valid_593142 = path.getOrDefault("Key")
  valid_593142 = validateParameter(valid_593142, JString, required = true,
                                 default = nil)
  if valid_593142 != nil:
    section.add "Key", valid_593142
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being uploaded.
  ##   partNumber: JInt (required)
  ##             : Part number of part being uploaded. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_593143 = query.getOrDefault("uploadId")
  valid_593143 = validateParameter(valid_593143, JString, required = true,
                                 default = nil)
  if valid_593143 != nil:
    section.add "uploadId", valid_593143
  var valid_593144 = query.getOrDefault("partNumber")
  valid_593144 = validateParameter(valid_593144, JInt, required = true, default = nil)
  if valid_593144 != nil:
    section.add "partNumber", valid_593144
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
  var valid_593145 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_593145
  var valid_593146 = header.getOrDefault("Content-Length")
  valid_593146 = validateParameter(valid_593146, JInt, required = false, default = nil)
  if valid_593146 != nil:
    section.add "Content-Length", valid_593146
  var valid_593147 = header.getOrDefault("x-amz-security-token")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "x-amz-security-token", valid_593147
  var valid_593148 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_593148
  var valid_593149 = header.getOrDefault("x-amz-request-payer")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = newJString("requester"))
  if valid_593149 != nil:
    section.add "x-amz-request-payer", valid_593149
  var valid_593150 = header.getOrDefault("Content-MD5")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "Content-MD5", valid_593150
  var valid_593151 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_593151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593153: Call_UploadPart_593138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads a part in a multipart upload.</p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p>
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
  let valid = call_593153.validator(path, query, header, formData, body)
  let scheme = call_593153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593153.url(scheme.get, call_593153.host, call_593153.base,
                         call_593153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593153, url, valid)

proc call*(call_593154: Call_UploadPart_593138; Bucket: string; uploadId: string;
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
  var path_593155 = newJObject()
  var query_593156 = newJObject()
  var body_593157 = newJObject()
  add(path_593155, "Bucket", newJString(Bucket))
  add(query_593156, "uploadId", newJString(uploadId))
  add(path_593155, "Key", newJString(Key))
  add(query_593156, "partNumber", newJInt(partNumber))
  if body != nil:
    body_593157 = body
  result = call_593154.call(path_593155, query_593156, nil, nil, body_593157)

var uploadPart* = Call_UploadPart_593138(name: "uploadPart",
                                      meth: HttpMethod.HttpPut,
                                      host: "s3.amazonaws.com", route: "/{Bucket}/{Key}#partNumber&uploadId",
                                      validator: validate_UploadPart_593139,
                                      base: "/", url: url_UploadPart_593140,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadPartCopy_593158 = ref object of OpenApiRestCall_591364
proc url_UploadPartCopy_593160(protocol: Scheme; host: string; base: string;
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

proc validate_UploadPartCopy_593159(path: JsonNode; query: JsonNode;
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
  var valid_593161 = path.getOrDefault("Bucket")
  valid_593161 = validateParameter(valid_593161, JString, required = true,
                                 default = nil)
  if valid_593161 != nil:
    section.add "Bucket", valid_593161
  var valid_593162 = path.getOrDefault("Key")
  valid_593162 = validateParameter(valid_593162, JString, required = true,
                                 default = nil)
  if valid_593162 != nil:
    section.add "Key", valid_593162
  result.add "path", section
  ## parameters in `query` object:
  ##   uploadId: JString (required)
  ##           : Upload ID identifying the multipart upload whose part is being copied.
  ##   partNumber: JInt (required)
  ##             : Part number of part being copied. This is a positive integer between 1 and 10,000.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `uploadId` field"
  var valid_593163 = query.getOrDefault("uploadId")
  valid_593163 = validateParameter(valid_593163, JString, required = true,
                                 default = nil)
  if valid_593163 != nil:
    section.add "uploadId", valid_593163
  var valid_593164 = query.getOrDefault("partNumber")
  valid_593164 = validateParameter(valid_593164, JInt, required = true, default = nil)
  if valid_593164 != nil:
    section.add "partNumber", valid_593164
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
  var valid_593165 = header.getOrDefault("x-amz-copy-source-if-none-match")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "x-amz-copy-source-if-none-match", valid_593165
  var valid_593166 = header.getOrDefault("x-amz-server-side-encryption-customer-key-MD5")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "x-amz-server-side-encryption-customer-key-MD5", valid_593166
  assert header != nil, "header argument is necessary due to required `x-amz-copy-source` field"
  var valid_593167 = header.getOrDefault("x-amz-copy-source")
  valid_593167 = validateParameter(valid_593167, JString, required = true,
                                 default = nil)
  if valid_593167 != nil:
    section.add "x-amz-copy-source", valid_593167
  var valid_593168 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-algorithm")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-algorithm",
               valid_593168
  var valid_593169 = header.getOrDefault("x-amz-security-token")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "x-amz-security-token", valid_593169
  var valid_593170 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key-MD5")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key-MD5", valid_593170
  var valid_593171 = header.getOrDefault("x-amz-server-side-encryption-customer-key")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "x-amz-server-side-encryption-customer-key", valid_593171
  var valid_593172 = header.getOrDefault("x-amz-copy-source-if-unmodified-since")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "x-amz-copy-source-if-unmodified-since", valid_593172
  var valid_593173 = header.getOrDefault("x-amz-copy-source-if-modified-since")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "x-amz-copy-source-if-modified-since", valid_593173
  var valid_593174 = header.getOrDefault("x-amz-request-payer")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = newJString("requester"))
  if valid_593174 != nil:
    section.add "x-amz-request-payer", valid_593174
  var valid_593175 = header.getOrDefault("x-amz-copy-source-if-match")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "x-amz-copy-source-if-match", valid_593175
  var valid_593176 = header.getOrDefault("x-amz-copy-source-server-side-encryption-customer-key")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "x-amz-copy-source-server-side-encryption-customer-key", valid_593176
  var valid_593177 = header.getOrDefault("x-amz-server-side-encryption-customer-algorithm")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "x-amz-server-side-encryption-customer-algorithm", valid_593177
  var valid_593178 = header.getOrDefault("x-amz-copy-source-range")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "x-amz-copy-source-range", valid_593178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593179: Call_UploadPartCopy_593158; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads a part by copying data from an existing object as data source.
  ## 
  ## http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
  let valid = call_593179.validator(path, query, header, formData, body)
  let scheme = call_593179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593179.url(scheme.get, call_593179.host, call_593179.base,
                         call_593179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593179, url, valid)

proc call*(call_593180: Call_UploadPartCopy_593158; Bucket: string; uploadId: string;
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
  var path_593181 = newJObject()
  var query_593182 = newJObject()
  add(path_593181, "Bucket", newJString(Bucket))
  add(query_593182, "uploadId", newJString(uploadId))
  add(path_593181, "Key", newJString(Key))
  add(query_593182, "partNumber", newJInt(partNumber))
  result = call_593180.call(path_593181, query_593182, nil, nil, nil)

var uploadPartCopy* = Call_UploadPartCopy_593158(name: "uploadPartCopy",
    meth: HttpMethod.HttpPut, host: "s3.amazonaws.com",
    route: "/{Bucket}/{Key}#x-amz-copy-source&partNumber&uploadId",
    validator: validate_UploadPartCopy_593159, base: "/", url: url_UploadPartCopy_593160,
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
