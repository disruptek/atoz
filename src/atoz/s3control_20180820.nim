
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS S3 Control
## version: 2018-08-20
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
##  AWS S3 Control provides access to Amazon S3 control plane operations. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/s3-control/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "s3-control.ap-northeast-1.amazonaws.com", "ap-southeast-1": "s3-control.ap-southeast-1.amazonaws.com",
                           "us-west-2": "s3-control.us-west-2.amazonaws.com",
                           "eu-west-2": "s3-control.eu-west-2.amazonaws.com", "ap-northeast-3": "s3-control.ap-northeast-3.amazonaws.com", "eu-central-1": "s3-control.eu-central-1.amazonaws.com",
                           "us-east-2": "s3-control.us-east-2.amazonaws.com",
                           "us-east-1": "s3-control.us-east-1.amazonaws.com", "cn-northwest-1": "s3-control.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "s3-control.ap-south-1.amazonaws.com",
                           "eu-north-1": "s3-control.eu-north-1.amazonaws.com", "ap-northeast-2": "s3-control.ap-northeast-2.amazonaws.com",
                           "us-west-1": "s3-control.us-west-1.amazonaws.com", "us-gov-east-1": "s3-control.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "s3-control.eu-west-3.amazonaws.com", "cn-north-1": "s3-control.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "s3-control.sa-east-1.amazonaws.com",
                           "eu-west-1": "s3-control.eu-west-1.amazonaws.com", "us-gov-west-1": "s3-control.us-gov-west-1.amazonaws.com", "ap-southeast-2": "s3-control.ap-southeast-2.amazonaws.com", "ca-central-1": "s3-control.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "s3-control.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "s3-control.ap-southeast-1.amazonaws.com",
      "us-west-2": "s3-control.us-west-2.amazonaws.com",
      "eu-west-2": "s3-control.eu-west-2.amazonaws.com",
      "ap-northeast-3": "s3-control.ap-northeast-3.amazonaws.com",
      "eu-central-1": "s3-control.eu-central-1.amazonaws.com",
      "us-east-2": "s3-control.us-east-2.amazonaws.com",
      "us-east-1": "s3-control.us-east-1.amazonaws.com",
      "cn-northwest-1": "s3-control.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "s3-control.ap-south-1.amazonaws.com",
      "eu-north-1": "s3-control.eu-north-1.amazonaws.com",
      "ap-northeast-2": "s3-control.ap-northeast-2.amazonaws.com",
      "us-west-1": "s3-control.us-west-1.amazonaws.com",
      "us-gov-east-1": "s3-control.us-gov-east-1.amazonaws.com",
      "eu-west-3": "s3-control.eu-west-3.amazonaws.com",
      "cn-north-1": "s3-control.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "s3-control.sa-east-1.amazonaws.com",
      "eu-west-1": "s3-control.eu-west-1.amazonaws.com",
      "us-gov-west-1": "s3-control.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "s3-control.ap-southeast-2.amazonaws.com",
      "ca-central-1": "s3-control.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "s3control"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateAccessPoint_611267 = ref object of OpenApiRestCall_610658
proc url_CreateAccessPoint_611269(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAccessPoint_611268(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an access point and associates it with the specified bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name you want to assign to this access point.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611270 = path.getOrDefault("name")
  valid_611270 = validateParameter(valid_611270, JString, required = true,
                                 default = nil)
  if valid_611270 != nil:
    section.add "name", valid_611270
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The AWS account ID for the owner of the bucket for which you want to create an access point.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611271 = header.getOrDefault("X-Amz-Signature")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Signature", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Content-Sha256", valid_611272
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611273 = header.getOrDefault("x-amz-account-id")
  valid_611273 = validateParameter(valid_611273, JString, required = true,
                                 default = nil)
  if valid_611273 != nil:
    section.add "x-amz-account-id", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Date")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Date", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Credential")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Credential", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Security-Token")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Security-Token", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Algorithm")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Algorithm", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-SignedHeaders", valid_611278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611280: Call_CreateAccessPoint_611267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an access point and associates it with the specified bucket.
  ## 
  let valid = call_611280.validator(path, query, header, formData, body)
  let scheme = call_611280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611280.url(scheme.get, call_611280.host, call_611280.base,
                         call_611280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611280, url, valid)

proc call*(call_611281: Call_CreateAccessPoint_611267; name: string; body: JsonNode): Recallable =
  ## createAccessPoint
  ## Creates an access point and associates it with the specified bucket.
  ##   name: string (required)
  ##       : The name you want to assign to this access point.
  ##   body: JObject (required)
  var path_611282 = newJObject()
  var body_611283 = newJObject()
  add(path_611282, "name", newJString(name))
  if body != nil:
    body_611283 = body
  result = call_611281.call(path_611282, nil, nil, nil, body_611283)

var createAccessPoint* = Call_CreateAccessPoint_611267(name: "createAccessPoint",
    meth: HttpMethod.HttpPut, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_CreateAccessPoint_611268, base: "/",
    url: url_CreateAccessPoint_611269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPoint_610996 = ref object of OpenApiRestCall_610658
proc url_GetAccessPoint_610998(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPoint_610997(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns configuration information about the specified access point.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point whose configuration information you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611124 = path.getOrDefault("name")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "name", valid_611124
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the account that owns the specified access point.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611125 = header.getOrDefault("X-Amz-Signature")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Signature", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Content-Sha256", valid_611126
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611127 = header.getOrDefault("x-amz-account-id")
  valid_611127 = validateParameter(valid_611127, JString, required = true,
                                 default = nil)
  if valid_611127 != nil:
    section.add "x-amz-account-id", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Date")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Date", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Credential")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Credential", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Security-Token")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Security-Token", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Algorithm")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Algorithm", valid_611131
  var valid_611132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "X-Amz-SignedHeaders", valid_611132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611155: Call_GetAccessPoint_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns configuration information about the specified access point.
  ## 
  let valid = call_611155.validator(path, query, header, formData, body)
  let scheme = call_611155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611155.url(scheme.get, call_611155.host, call_611155.base,
                         call_611155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611155, url, valid)

proc call*(call_611226: Call_GetAccessPoint_610996; name: string): Recallable =
  ## getAccessPoint
  ## Returns configuration information about the specified access point.
  ##   name: string (required)
  ##       : The name of the access point whose configuration information you want to retrieve.
  var path_611227 = newJObject()
  add(path_611227, "name", newJString(name))
  result = call_611226.call(path_611227, nil, nil, nil, nil)

var getAccessPoint* = Call_GetAccessPoint_610996(name: "getAccessPoint",
    meth: HttpMethod.HttpGet, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_GetAccessPoint_610997, base: "/", url: url_GetAccessPoint_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccessPoint_611284 = ref object of OpenApiRestCall_610658
proc url_DeleteAccessPoint_611286(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccessPoint_611285(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes the specified access point.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611287 = path.getOrDefault("name")
  valid_611287 = validateParameter(valid_611287, JString, required = true,
                                 default = nil)
  if valid_611287 != nil:
    section.add "name", valid_611287
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the account that owns the specified access point.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611288 = header.getOrDefault("X-Amz-Signature")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Signature", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Content-Sha256", valid_611289
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611290 = header.getOrDefault("x-amz-account-id")
  valid_611290 = validateParameter(valid_611290, JString, required = true,
                                 default = nil)
  if valid_611290 != nil:
    section.add "x-amz-account-id", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Date")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Date", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Credential")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Credential", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Security-Token")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Security-Token", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Algorithm")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Algorithm", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-SignedHeaders", valid_611295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611296: Call_DeleteAccessPoint_611284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified access point.
  ## 
  let valid = call_611296.validator(path, query, header, formData, body)
  let scheme = call_611296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611296.url(scheme.get, call_611296.host, call_611296.base,
                         call_611296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611296, url, valid)

proc call*(call_611297: Call_DeleteAccessPoint_611284; name: string): Recallable =
  ## deleteAccessPoint
  ## Deletes the specified access point.
  ##   name: string (required)
  ##       : The name of the access point you want to delete.
  var path_611298 = newJObject()
  add(path_611298, "name", newJString(name))
  result = call_611297.call(path_611298, nil, nil, nil, nil)

var deleteAccessPoint* = Call_DeleteAccessPoint_611284(name: "deleteAccessPoint",
    meth: HttpMethod.HttpDelete, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_DeleteAccessPoint_611285, base: "/",
    url: url_DeleteAccessPoint_611286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_611318 = ref object of OpenApiRestCall_610658
proc url_CreateJob_611320(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_611319(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an Amazon S3 batch operations job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611321 = header.getOrDefault("X-Amz-Signature")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Signature", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Content-Sha256", valid_611322
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611323 = header.getOrDefault("x-amz-account-id")
  valid_611323 = validateParameter(valid_611323, JString, required = true,
                                 default = nil)
  if valid_611323 != nil:
    section.add "x-amz-account-id", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Date")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Date", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Credential")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Credential", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Security-Token")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Security-Token", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Algorithm")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Algorithm", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-SignedHeaders", valid_611328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611330: Call_CreateJob_611318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon S3 batch operations job.
  ## 
  let valid = call_611330.validator(path, query, header, formData, body)
  let scheme = call_611330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611330.url(scheme.get, call_611330.host, call_611330.base,
                         call_611330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611330, url, valid)

proc call*(call_611331: Call_CreateJob_611318; body: JsonNode): Recallable =
  ## createJob
  ## Creates an Amazon S3 batch operations job.
  ##   body: JObject (required)
  var body_611332 = newJObject()
  if body != nil:
    body_611332 = body
  result = call_611331.call(nil, nil, nil, nil, body_611332)

var createJob* = Call_CreateJob_611318(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "s3-control.amazonaws.com",
                                    route: "/v20180820/jobs#x-amz-account-id",
                                    validator: validate_CreateJob_611319,
                                    base: "/", url: url_CreateJob_611320,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_611299 = ref object of OpenApiRestCall_610658
proc url_ListJobs_611301(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_611300(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token to request the next page of results. Use the token that Amazon S3 returned in the <code>NextToken</code> element of the <code>ListJobsResult</code> from the previous <code>List Jobs</code> request.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   jobStatuses: JArray
  ##              : The <code>List Jobs</code> request returns jobs that match the statuses listed in this element.
  ##   maxResults: JInt
  ##             : The maximum number of jobs that Amazon S3 will include in the <code>List Jobs</code> response. If there are more jobs than this number, the response will include a pagination token in the <code>NextToken</code> field to enable you to retrieve the next page of results.
  section = newJObject()
  var valid_611302 = query.getOrDefault("nextToken")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "nextToken", valid_611302
  var valid_611303 = query.getOrDefault("MaxResults")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "MaxResults", valid_611303
  var valid_611304 = query.getOrDefault("NextToken")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "NextToken", valid_611304
  var valid_611305 = query.getOrDefault("jobStatuses")
  valid_611305 = validateParameter(valid_611305, JArray, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "jobStatuses", valid_611305
  var valid_611306 = query.getOrDefault("maxResults")
  valid_611306 = validateParameter(valid_611306, JInt, required = false, default = nil)
  if valid_611306 != nil:
    section.add "maxResults", valid_611306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611307 = header.getOrDefault("X-Amz-Signature")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Signature", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Content-Sha256", valid_611308
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611309 = header.getOrDefault("x-amz-account-id")
  valid_611309 = validateParameter(valid_611309, JString, required = true,
                                 default = nil)
  if valid_611309 != nil:
    section.add "x-amz-account-id", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Date")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Date", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Credential")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Credential", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Security-Token")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Security-Token", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Algorithm")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Algorithm", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-SignedHeaders", valid_611314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611315: Call_ListJobs_611299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ## 
  let valid = call_611315.validator(path, query, header, formData, body)
  let scheme = call_611315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611315.url(scheme.get, call_611315.host, call_611315.base,
                         call_611315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611315, url, valid)

proc call*(call_611316: Call_ListJobs_611299; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; jobStatuses: JsonNode = nil;
          maxResults: int = 0): Recallable =
  ## listJobs
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ##   nextToken: string
  ##            : A pagination token to request the next page of results. Use the token that Amazon S3 returned in the <code>NextToken</code> element of the <code>ListJobsResult</code> from the previous <code>List Jobs</code> request.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   jobStatuses: JArray
  ##              : The <code>List Jobs</code> request returns jobs that match the statuses listed in this element.
  ##   maxResults: int
  ##             : The maximum number of jobs that Amazon S3 will include in the <code>List Jobs</code> response. If there are more jobs than this number, the response will include a pagination token in the <code>NextToken</code> field to enable you to retrieve the next page of results.
  var query_611317 = newJObject()
  add(query_611317, "nextToken", newJString(nextToken))
  add(query_611317, "MaxResults", newJString(MaxResults))
  add(query_611317, "NextToken", newJString(NextToken))
  if jobStatuses != nil:
    query_611317.add "jobStatuses", jobStatuses
  add(query_611317, "maxResults", newJInt(maxResults))
  result = call_611316.call(nil, query_611317, nil, nil, nil)

var listJobs* = Call_ListJobs_611299(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "s3-control.amazonaws.com",
                                  route: "/v20180820/jobs#x-amz-account-id",
                                  validator: validate_ListJobs_611300, base: "/",
                                  url: url_ListJobs_611301,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccessPointPolicy_611348 = ref object of OpenApiRestCall_610658
proc url_PutAccessPointPolicy_611350(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/policy#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutAccessPointPolicy_611349(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point that you want to associate with the specified policy.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611351 = path.getOrDefault("name")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "name", valid_611351
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The AWS account ID for owner of the bucket associated with the specified access point.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611352 = header.getOrDefault("X-Amz-Signature")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Signature", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Content-Sha256", valid_611353
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611354 = header.getOrDefault("x-amz-account-id")
  valid_611354 = validateParameter(valid_611354, JString, required = true,
                                 default = nil)
  if valid_611354 != nil:
    section.add "x-amz-account-id", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Date")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Date", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Credential")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Credential", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Security-Token")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Security-Token", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Algorithm")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Algorithm", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-SignedHeaders", valid_611359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611361: Call_PutAccessPointPolicy_611348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point.
  ## 
  let valid = call_611361.validator(path, query, header, formData, body)
  let scheme = call_611361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611361.url(scheme.get, call_611361.host, call_611361.base,
                         call_611361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611361, url, valid)

proc call*(call_611362: Call_PutAccessPointPolicy_611348; name: string;
          body: JsonNode): Recallable =
  ## putAccessPointPolicy
  ## Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point.
  ##   name: string (required)
  ##       : The name of the access point that you want to associate with the specified policy.
  ##   body: JObject (required)
  var path_611363 = newJObject()
  var body_611364 = newJObject()
  add(path_611363, "name", newJString(name))
  if body != nil:
    body_611364 = body
  result = call_611362.call(path_611363, nil, nil, nil, body_611364)

var putAccessPointPolicy* = Call_PutAccessPointPolicy_611348(
    name: "putAccessPointPolicy", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_PutAccessPointPolicy_611349, base: "/",
    url: url_PutAccessPointPolicy_611350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPointPolicy_611333 = ref object of OpenApiRestCall_610658
proc url_GetAccessPointPolicy_611335(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/policy#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPointPolicy_611334(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the access point policy associated with the specified access point.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point whose policy you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611336 = path.getOrDefault("name")
  valid_611336 = validateParameter(valid_611336, JString, required = true,
                                 default = nil)
  if valid_611336 != nil:
    section.add "name", valid_611336
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the account that owns the specified access point.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611337 = header.getOrDefault("X-Amz-Signature")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Signature", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Content-Sha256", valid_611338
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611339 = header.getOrDefault("x-amz-account-id")
  valid_611339 = validateParameter(valid_611339, JString, required = true,
                                 default = nil)
  if valid_611339 != nil:
    section.add "x-amz-account-id", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Date")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Date", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Credential")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Credential", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Security-Token")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Security-Token", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Algorithm")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Algorithm", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-SignedHeaders", valid_611344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611345: Call_GetAccessPointPolicy_611333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access point policy associated with the specified access point.
  ## 
  let valid = call_611345.validator(path, query, header, formData, body)
  let scheme = call_611345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611345.url(scheme.get, call_611345.host, call_611345.base,
                         call_611345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611345, url, valid)

proc call*(call_611346: Call_GetAccessPointPolicy_611333; name: string): Recallable =
  ## getAccessPointPolicy
  ## Returns the access point policy associated with the specified access point.
  ##   name: string (required)
  ##       : The name of the access point whose policy you want to retrieve.
  var path_611347 = newJObject()
  add(path_611347, "name", newJString(name))
  result = call_611346.call(path_611347, nil, nil, nil, nil)

var getAccessPointPolicy* = Call_GetAccessPointPolicy_611333(
    name: "getAccessPointPolicy", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_GetAccessPointPolicy_611334, base: "/",
    url: url_GetAccessPointPolicy_611335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccessPointPolicy_611365 = ref object of OpenApiRestCall_610658
proc url_DeleteAccessPointPolicy_611367(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/policy#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccessPointPolicy_611366(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the access point policy for the specified access point.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point whose policy you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611368 = path.getOrDefault("name")
  valid_611368 = validateParameter(valid_611368, JString, required = true,
                                 default = nil)
  if valid_611368 != nil:
    section.add "name", valid_611368
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the account that owns the specified access point.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611369 = header.getOrDefault("X-Amz-Signature")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Signature", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Content-Sha256", valid_611370
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611371 = header.getOrDefault("x-amz-account-id")
  valid_611371 = validateParameter(valid_611371, JString, required = true,
                                 default = nil)
  if valid_611371 != nil:
    section.add "x-amz-account-id", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Date")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Date", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Credential")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Credential", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Security-Token")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Security-Token", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Algorithm")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Algorithm", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-SignedHeaders", valid_611376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611377: Call_DeleteAccessPointPolicy_611365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the access point policy for the specified access point.
  ## 
  let valid = call_611377.validator(path, query, header, formData, body)
  let scheme = call_611377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611377.url(scheme.get, call_611377.host, call_611377.base,
                         call_611377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611377, url, valid)

proc call*(call_611378: Call_DeleteAccessPointPolicy_611365; name: string): Recallable =
  ## deleteAccessPointPolicy
  ## Deletes the access point policy for the specified access point.
  ##   name: string (required)
  ##       : The name of the access point whose policy you want to delete.
  var path_611379 = newJObject()
  add(path_611379, "name", newJString(name))
  result = call_611378.call(path_611379, nil, nil, nil, nil)

var deleteAccessPointPolicy* = Call_DeleteAccessPointPolicy_611365(
    name: "deleteAccessPointPolicy", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_DeleteAccessPointPolicy_611366, base: "/",
    url: url_DeleteAccessPointPolicy_611367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_611393 = ref object of OpenApiRestCall_610658
proc url_PutPublicAccessBlock_611395(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutPublicAccessBlock_611394(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the Amazon Web Services account whose <code>PublicAccessBlock</code> configuration you want to set.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611396 = header.getOrDefault("X-Amz-Signature")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Signature", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Content-Sha256", valid_611397
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611398 = header.getOrDefault("x-amz-account-id")
  valid_611398 = validateParameter(valid_611398, JString, required = true,
                                 default = nil)
  if valid_611398 != nil:
    section.add "x-amz-account-id", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Date")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Date", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-Credential")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Credential", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Security-Token")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Security-Token", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Algorithm")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Algorithm", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-SignedHeaders", valid_611403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611405: Call_PutPublicAccessBlock_611393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  let valid = call_611405.validator(path, query, header, formData, body)
  let scheme = call_611405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611405.url(scheme.get, call_611405.host, call_611405.base,
                         call_611405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611405, url, valid)

proc call*(call_611406: Call_PutPublicAccessBlock_611393; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ##   body: JObject (required)
  var body_611407 = newJObject()
  if body != nil:
    body_611407 = body
  result = call_611406.call(nil, nil, nil, nil, body_611407)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_611393(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_PutPublicAccessBlock_611394, base: "/",
    url: url_PutPublicAccessBlock_611395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_611380 = ref object of OpenApiRestCall_610658
proc url_GetPublicAccessBlock_611382(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPublicAccessBlock_611381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the Amazon Web Services account whose <code>PublicAccessBlock</code> configuration you want to retrieve.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611383 = header.getOrDefault("X-Amz-Signature")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Signature", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Content-Sha256", valid_611384
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611385 = header.getOrDefault("x-amz-account-id")
  valid_611385 = validateParameter(valid_611385, JString, required = true,
                                 default = nil)
  if valid_611385 != nil:
    section.add "x-amz-account-id", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Date")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Date", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Credential")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Credential", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Security-Token")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Security-Token", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Algorithm")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Algorithm", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-SignedHeaders", valid_611390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611391: Call_GetPublicAccessBlock_611380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  let valid = call_611391.validator(path, query, header, formData, body)
  let scheme = call_611391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611391.url(scheme.get, call_611391.host, call_611391.base,
                         call_611391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611391, url, valid)

proc call*(call_611392: Call_GetPublicAccessBlock_611380): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  result = call_611392.call(nil, nil, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_611380(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_GetPublicAccessBlock_611381, base: "/",
    url: url_GetPublicAccessBlock_611382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_611408 = ref object of OpenApiRestCall_610658
proc url_DeletePublicAccessBlock_611410(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePublicAccessBlock_611409(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the Amazon Web Services account whose <code>PublicAccessBlock</code> configuration you want to remove.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611411 = header.getOrDefault("X-Amz-Signature")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Signature", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Content-Sha256", valid_611412
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611413 = header.getOrDefault("x-amz-account-id")
  valid_611413 = validateParameter(valid_611413, JString, required = true,
                                 default = nil)
  if valid_611413 != nil:
    section.add "x-amz-account-id", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Date")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Date", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Credential")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Credential", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Security-Token")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Security-Token", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Algorithm")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Algorithm", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-SignedHeaders", valid_611418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611419: Call_DeletePublicAccessBlock_611408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  let valid = call_611419.validator(path, query, header, formData, body)
  let scheme = call_611419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611419.url(scheme.get, call_611419.host, call_611419.base,
                         call_611419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611419, url, valid)

proc call*(call_611420: Call_DeletePublicAccessBlock_611408): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  result = call_611420.call(nil, nil, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_611408(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_DeletePublicAccessBlock_611409, base: "/",
    url: url_DeletePublicAccessBlock_611410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_611421 = ref object of OpenApiRestCall_610658
proc url_DescribeJob_611423(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"),
               (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeJob_611422(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the configuration parameters and status for a batch operations job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID for the job whose information you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611424 = path.getOrDefault("id")
  valid_611424 = validateParameter(valid_611424, JString, required = true,
                                 default = nil)
  if valid_611424 != nil:
    section.add "id", valid_611424
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611425 = header.getOrDefault("X-Amz-Signature")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Signature", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Content-Sha256", valid_611426
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611427 = header.getOrDefault("x-amz-account-id")
  valid_611427 = validateParameter(valid_611427, JString, required = true,
                                 default = nil)
  if valid_611427 != nil:
    section.add "x-amz-account-id", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Date")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Date", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Credential")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Credential", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Security-Token")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Security-Token", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Algorithm")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Algorithm", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-SignedHeaders", valid_611432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611433: Call_DescribeJob_611421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the configuration parameters and status for a batch operations job.
  ## 
  let valid = call_611433.validator(path, query, header, formData, body)
  let scheme = call_611433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611433.url(scheme.get, call_611433.host, call_611433.base,
                         call_611433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611433, url, valid)

proc call*(call_611434: Call_DescribeJob_611421; id: string): Recallable =
  ## describeJob
  ## Retrieves the configuration parameters and status for a batch operations job.
  ##   id: string (required)
  ##     : The ID for the job whose information you want to retrieve.
  var path_611435 = newJObject()
  add(path_611435, "id", newJString(id))
  result = call_611434.call(path_611435, nil, nil, nil, nil)

var describeJob* = Call_DescribeJob_611421(name: "describeJob",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3-control.amazonaws.com", route: "/v20180820/jobs/{id}#x-amz-account-id",
                                        validator: validate_DescribeJob_611422,
                                        base: "/", url: url_DescribeJob_611423,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPointPolicyStatus_611436 = ref object of OpenApiRestCall_610658
proc url_GetAccessPointPolicyStatus_611438(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/policyStatus#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPointPolicyStatus_611437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html">Managing Data Access with Amazon S3 Access Points</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point whose policy status you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611439 = path.getOrDefault("name")
  valid_611439 = validateParameter(valid_611439, JString, required = true,
                                 default = nil)
  if valid_611439 != nil:
    section.add "name", valid_611439
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the account that owns the specified access point.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611440 = header.getOrDefault("X-Amz-Signature")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Signature", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Content-Sha256", valid_611441
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611442 = header.getOrDefault("x-amz-account-id")
  valid_611442 = validateParameter(valid_611442, JString, required = true,
                                 default = nil)
  if valid_611442 != nil:
    section.add "x-amz-account-id", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-Date")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Date", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Credential")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Credential", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Security-Token")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Security-Token", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Algorithm")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Algorithm", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-SignedHeaders", valid_611447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611448: Call_GetAccessPointPolicyStatus_611436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html">Managing Data Access with Amazon S3 Access Points</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ## 
  let valid = call_611448.validator(path, query, header, formData, body)
  let scheme = call_611448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611448.url(scheme.get, call_611448.host, call_611448.base,
                         call_611448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611448, url, valid)

proc call*(call_611449: Call_GetAccessPointPolicyStatus_611436; name: string): Recallable =
  ## getAccessPointPolicyStatus
  ## Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html">Managing Data Access with Amazon S3 Access Points</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   name: string (required)
  ##       : The name of the access point whose policy status you want to retrieve.
  var path_611450 = newJObject()
  add(path_611450, "name", newJString(name))
  result = call_611449.call(path_611450, nil, nil, nil, nil)

var getAccessPointPolicyStatus* = Call_GetAccessPointPolicyStatus_611436(
    name: "getAccessPointPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policyStatus#x-amz-account-id",
    validator: validate_GetAccessPointPolicyStatus_611437, base: "/",
    url: url_GetAccessPointPolicyStatus_611438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccessPoints_611451 = ref object of OpenApiRestCall_610658
proc url_ListAccessPoints_611453(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccessPoints_611452(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of the access points currently associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1000 access points (or the number specified in <code>maxResults</code>, whichever is less), then the response will include a continuation token that you can use to list the additional access points.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   bucket: JString
  ##         : The name of the bucket whose associated access points you want to list.
  ##   nextToken: JString
  ##            : A continuation token. If a previous call to <code>ListAccessPoints</code> returned a continuation token in the <code>NextToken</code> field, then providing that value here causes Amazon S3 to retrieve the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of access points that you want to include in the list. If the specified bucket has more than this number of access points, then the response will include a continuation token in the <code>NextToken</code> field that you can use to retrieve the next page of access points.
  section = newJObject()
  var valid_611454 = query.getOrDefault("bucket")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "bucket", valid_611454
  var valid_611455 = query.getOrDefault("nextToken")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "nextToken", valid_611455
  var valid_611456 = query.getOrDefault("MaxResults")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "MaxResults", valid_611456
  var valid_611457 = query.getOrDefault("NextToken")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "NextToken", valid_611457
  var valid_611458 = query.getOrDefault("maxResults")
  valid_611458 = validateParameter(valid_611458, JInt, required = false, default = nil)
  if valid_611458 != nil:
    section.add "maxResults", valid_611458
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The AWS account ID for owner of the bucket whose access points you want to list.
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611459 = header.getOrDefault("X-Amz-Signature")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Signature", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Content-Sha256", valid_611460
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611461 = header.getOrDefault("x-amz-account-id")
  valid_611461 = validateParameter(valid_611461, JString, required = true,
                                 default = nil)
  if valid_611461 != nil:
    section.add "x-amz-account-id", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Date")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Date", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Credential")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Credential", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Security-Token")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Security-Token", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Algorithm")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Algorithm", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-SignedHeaders", valid_611466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611467: Call_ListAccessPoints_611451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the access points currently associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1000 access points (or the number specified in <code>maxResults</code>, whichever is less), then the response will include a continuation token that you can use to list the additional access points.
  ## 
  let valid = call_611467.validator(path, query, header, formData, body)
  let scheme = call_611467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611467.url(scheme.get, call_611467.host, call_611467.base,
                         call_611467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611467, url, valid)

proc call*(call_611468: Call_ListAccessPoints_611451; bucket: string = "";
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listAccessPoints
  ## Returns a list of the access points currently associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1000 access points (or the number specified in <code>maxResults</code>, whichever is less), then the response will include a continuation token that you can use to list the additional access points.
  ##   bucket: string
  ##         : The name of the bucket whose associated access points you want to list.
  ##   nextToken: string
  ##            : A continuation token. If a previous call to <code>ListAccessPoints</code> returned a continuation token in the <code>NextToken</code> field, then providing that value here causes Amazon S3 to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of access points that you want to include in the list. If the specified bucket has more than this number of access points, then the response will include a continuation token in the <code>NextToken</code> field that you can use to retrieve the next page of access points.
  var query_611469 = newJObject()
  add(query_611469, "bucket", newJString(bucket))
  add(query_611469, "nextToken", newJString(nextToken))
  add(query_611469, "MaxResults", newJString(MaxResults))
  add(query_611469, "NextToken", newJString(NextToken))
  add(query_611469, "maxResults", newJInt(maxResults))
  result = call_611468.call(nil, query_611469, nil, nil, nil)

var listAccessPoints* = Call_ListAccessPoints_611451(name: "listAccessPoints",
    meth: HttpMethod.HttpGet, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint#x-amz-account-id",
    validator: validate_ListAccessPoints_611452, base: "/",
    url: url_ListAccessPoints_611453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobPriority_611470 = ref object of OpenApiRestCall_610658
proc url_UpdateJobPriority_611472(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"), (kind: ConstantSegment,
        value: "/priority#x-amz-account-id&priority")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobPriority_611471(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an existing job's priority.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID for the job whose priority you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611473 = path.getOrDefault("id")
  valid_611473 = validateParameter(valid_611473, JString, required = true,
                                 default = nil)
  if valid_611473 != nil:
    section.add "id", valid_611473
  result.add "path", section
  ## parameters in `query` object:
  ##   priority: JInt (required)
  ##           : The priority you want to assign to this job.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `priority` field"
  var valid_611474 = query.getOrDefault("priority")
  valid_611474 = validateParameter(valid_611474, JInt, required = true, default = nil)
  if valid_611474 != nil:
    section.add "priority", valid_611474
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611475 = header.getOrDefault("X-Amz-Signature")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Signature", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Content-Sha256", valid_611476
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611477 = header.getOrDefault("x-amz-account-id")
  valid_611477 = validateParameter(valid_611477, JString, required = true,
                                 default = nil)
  if valid_611477 != nil:
    section.add "x-amz-account-id", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Date")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Date", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Credential")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Credential", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Security-Token")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Security-Token", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Algorithm")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Algorithm", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-SignedHeaders", valid_611482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611483: Call_UpdateJobPriority_611470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job's priority.
  ## 
  let valid = call_611483.validator(path, query, header, formData, body)
  let scheme = call_611483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611483.url(scheme.get, call_611483.host, call_611483.base,
                         call_611483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611483, url, valid)

proc call*(call_611484: Call_UpdateJobPriority_611470; id: string; priority: int): Recallable =
  ## updateJobPriority
  ## Updates an existing job's priority.
  ##   id: string (required)
  ##     : The ID for the job whose priority you want to update.
  ##   priority: int (required)
  ##           : The priority you want to assign to this job.
  var path_611485 = newJObject()
  var query_611486 = newJObject()
  add(path_611485, "id", newJString(id))
  add(query_611486, "priority", newJInt(priority))
  result = call_611484.call(path_611485, query_611486, nil, nil, nil)

var updateJobPriority* = Call_UpdateJobPriority_611470(name: "updateJobPriority",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/priority#x-amz-account-id&priority",
    validator: validate_UpdateJobPriority_611471, base: "/",
    url: url_UpdateJobPriority_611472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobStatus_611487 = ref object of OpenApiRestCall_610658
proc url_UpdateJobStatus_611489(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"), (kind: ConstantSegment,
        value: "/status#x-amz-account-id&requestedJobStatus")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobStatus_611488(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the job whose status you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611490 = path.getOrDefault("id")
  valid_611490 = validateParameter(valid_611490, JString, required = true,
                                 default = nil)
  if valid_611490 != nil:
    section.add "id", valid_611490
  result.add "path", section
  ## parameters in `query` object:
  ##   statusUpdateReason: JString
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  ##   requestedJobStatus: JString (required)
  ##                     : The status that you want to move the specified job to.
  section = newJObject()
  var valid_611491 = query.getOrDefault("statusUpdateReason")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "statusUpdateReason", valid_611491
  var valid_611505 = query.getOrDefault("requestedJobStatus")
  valid_611505 = validateParameter(valid_611505, JString, required = true,
                                 default = newJString("Cancelled"))
  if valid_611505 != nil:
    section.add "requestedJobStatus", valid_611505
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611506 = header.getOrDefault("X-Amz-Signature")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Signature", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Content-Sha256", valid_611507
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_611508 = header.getOrDefault("x-amz-account-id")
  valid_611508 = validateParameter(valid_611508, JString, required = true,
                                 default = nil)
  if valid_611508 != nil:
    section.add "x-amz-account-id", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Date")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Date", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Credential")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Credential", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Security-Token")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Security-Token", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Algorithm")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Algorithm", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-SignedHeaders", valid_611513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611514: Call_UpdateJobStatus_611487; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ## 
  let valid = call_611514.validator(path, query, header, formData, body)
  let scheme = call_611514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611514.url(scheme.get, call_611514.host, call_611514.base,
                         call_611514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611514, url, valid)

proc call*(call_611515: Call_UpdateJobStatus_611487; id: string;
          statusUpdateReason: string = ""; requestedJobStatus: string = "Cancelled"): Recallable =
  ## updateJobStatus
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ##   statusUpdateReason: string
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  ##   id: string (required)
  ##     : The ID of the job whose status you want to update.
  ##   requestedJobStatus: string (required)
  ##                     : The status that you want to move the specified job to.
  var path_611516 = newJObject()
  var query_611517 = newJObject()
  add(query_611517, "statusUpdateReason", newJString(statusUpdateReason))
  add(path_611516, "id", newJString(id))
  add(query_611517, "requestedJobStatus", newJString(requestedJobStatus))
  result = call_611515.call(path_611516, query_611517, nil, nil, nil)

var updateJobStatus* = Call_UpdateJobStatus_611487(name: "updateJobStatus",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/status#x-amz-account-id&requestedJobStatus",
    validator: validate_UpdateJobStatus_611488, base: "/", url: url_UpdateJobStatus_611489,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
