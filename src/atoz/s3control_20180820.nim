
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_CreateAccessPoint_597998 = ref object of OpenApiRestCall_597389
proc url_CreateAccessPoint_598000(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAccessPoint_597999(path: JsonNode; query: JsonNode;
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
  var valid_598001 = path.getOrDefault("name")
  valid_598001 = validateParameter(valid_598001, JString, required = true,
                                 default = nil)
  if valid_598001 != nil:
    section.add "name", valid_598001
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
  var valid_598002 = header.getOrDefault("X-Amz-Signature")
  valid_598002 = validateParameter(valid_598002, JString, required = false,
                                 default = nil)
  if valid_598002 != nil:
    section.add "X-Amz-Signature", valid_598002
  var valid_598003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Content-Sha256", valid_598003
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598004 = header.getOrDefault("x-amz-account-id")
  valid_598004 = validateParameter(valid_598004, JString, required = true,
                                 default = nil)
  if valid_598004 != nil:
    section.add "x-amz-account-id", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-Date")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Date", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-Credential")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-Credential", valid_598006
  var valid_598007 = header.getOrDefault("X-Amz-Security-Token")
  valid_598007 = validateParameter(valid_598007, JString, required = false,
                                 default = nil)
  if valid_598007 != nil:
    section.add "X-Amz-Security-Token", valid_598007
  var valid_598008 = header.getOrDefault("X-Amz-Algorithm")
  valid_598008 = validateParameter(valid_598008, JString, required = false,
                                 default = nil)
  if valid_598008 != nil:
    section.add "X-Amz-Algorithm", valid_598008
  var valid_598009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598009 = validateParameter(valid_598009, JString, required = false,
                                 default = nil)
  if valid_598009 != nil:
    section.add "X-Amz-SignedHeaders", valid_598009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598011: Call_CreateAccessPoint_597998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an access point and associates it with the specified bucket.
  ## 
  let valid = call_598011.validator(path, query, header, formData, body)
  let scheme = call_598011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598011.url(scheme.get, call_598011.host, call_598011.base,
                         call_598011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598011, url, valid)

proc call*(call_598012: Call_CreateAccessPoint_597998; name: string; body: JsonNode): Recallable =
  ## createAccessPoint
  ## Creates an access point and associates it with the specified bucket.
  ##   name: string (required)
  ##       : The name you want to assign to this access point.
  ##   body: JObject (required)
  var path_598013 = newJObject()
  var body_598014 = newJObject()
  add(path_598013, "name", newJString(name))
  if body != nil:
    body_598014 = body
  result = call_598012.call(path_598013, nil, nil, nil, body_598014)

var createAccessPoint* = Call_CreateAccessPoint_597998(name: "createAccessPoint",
    meth: HttpMethod.HttpPut, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_CreateAccessPoint_597999, base: "/",
    url: url_CreateAccessPoint_598000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPoint_597727 = ref object of OpenApiRestCall_597389
proc url_GetAccessPoint_597729(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPoint_597728(path: JsonNode; query: JsonNode;
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
  var valid_597855 = path.getOrDefault("name")
  valid_597855 = validateParameter(valid_597855, JString, required = true,
                                 default = nil)
  if valid_597855 != nil:
    section.add "name", valid_597855
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
  var valid_597856 = header.getOrDefault("X-Amz-Signature")
  valid_597856 = validateParameter(valid_597856, JString, required = false,
                                 default = nil)
  if valid_597856 != nil:
    section.add "X-Amz-Signature", valid_597856
  var valid_597857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597857 = validateParameter(valid_597857, JString, required = false,
                                 default = nil)
  if valid_597857 != nil:
    section.add "X-Amz-Content-Sha256", valid_597857
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_597858 = header.getOrDefault("x-amz-account-id")
  valid_597858 = validateParameter(valid_597858, JString, required = true,
                                 default = nil)
  if valid_597858 != nil:
    section.add "x-amz-account-id", valid_597858
  var valid_597859 = header.getOrDefault("X-Amz-Date")
  valid_597859 = validateParameter(valid_597859, JString, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "X-Amz-Date", valid_597859
  var valid_597860 = header.getOrDefault("X-Amz-Credential")
  valid_597860 = validateParameter(valid_597860, JString, required = false,
                                 default = nil)
  if valid_597860 != nil:
    section.add "X-Amz-Credential", valid_597860
  var valid_597861 = header.getOrDefault("X-Amz-Security-Token")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-Security-Token", valid_597861
  var valid_597862 = header.getOrDefault("X-Amz-Algorithm")
  valid_597862 = validateParameter(valid_597862, JString, required = false,
                                 default = nil)
  if valid_597862 != nil:
    section.add "X-Amz-Algorithm", valid_597862
  var valid_597863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597863 = validateParameter(valid_597863, JString, required = false,
                                 default = nil)
  if valid_597863 != nil:
    section.add "X-Amz-SignedHeaders", valid_597863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597886: Call_GetAccessPoint_597727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns configuration information about the specified access point.
  ## 
  let valid = call_597886.validator(path, query, header, formData, body)
  let scheme = call_597886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597886.url(scheme.get, call_597886.host, call_597886.base,
                         call_597886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597886, url, valid)

proc call*(call_597957: Call_GetAccessPoint_597727; name: string): Recallable =
  ## getAccessPoint
  ## Returns configuration information about the specified access point.
  ##   name: string (required)
  ##       : The name of the access point whose configuration information you want to retrieve.
  var path_597958 = newJObject()
  add(path_597958, "name", newJString(name))
  result = call_597957.call(path_597958, nil, nil, nil, nil)

var getAccessPoint* = Call_GetAccessPoint_597727(name: "getAccessPoint",
    meth: HttpMethod.HttpGet, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_GetAccessPoint_597728, base: "/", url: url_GetAccessPoint_597729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccessPoint_598015 = ref object of OpenApiRestCall_597389
proc url_DeleteAccessPoint_598017(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccessPoint_598016(path: JsonNode; query: JsonNode;
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
  var valid_598018 = path.getOrDefault("name")
  valid_598018 = validateParameter(valid_598018, JString, required = true,
                                 default = nil)
  if valid_598018 != nil:
    section.add "name", valid_598018
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
  var valid_598019 = header.getOrDefault("X-Amz-Signature")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-Signature", valid_598019
  var valid_598020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598020 = validateParameter(valid_598020, JString, required = false,
                                 default = nil)
  if valid_598020 != nil:
    section.add "X-Amz-Content-Sha256", valid_598020
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598021 = header.getOrDefault("x-amz-account-id")
  valid_598021 = validateParameter(valid_598021, JString, required = true,
                                 default = nil)
  if valid_598021 != nil:
    section.add "x-amz-account-id", valid_598021
  var valid_598022 = header.getOrDefault("X-Amz-Date")
  valid_598022 = validateParameter(valid_598022, JString, required = false,
                                 default = nil)
  if valid_598022 != nil:
    section.add "X-Amz-Date", valid_598022
  var valid_598023 = header.getOrDefault("X-Amz-Credential")
  valid_598023 = validateParameter(valid_598023, JString, required = false,
                                 default = nil)
  if valid_598023 != nil:
    section.add "X-Amz-Credential", valid_598023
  var valid_598024 = header.getOrDefault("X-Amz-Security-Token")
  valid_598024 = validateParameter(valid_598024, JString, required = false,
                                 default = nil)
  if valid_598024 != nil:
    section.add "X-Amz-Security-Token", valid_598024
  var valid_598025 = header.getOrDefault("X-Amz-Algorithm")
  valid_598025 = validateParameter(valid_598025, JString, required = false,
                                 default = nil)
  if valid_598025 != nil:
    section.add "X-Amz-Algorithm", valid_598025
  var valid_598026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598026 = validateParameter(valid_598026, JString, required = false,
                                 default = nil)
  if valid_598026 != nil:
    section.add "X-Amz-SignedHeaders", valid_598026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598027: Call_DeleteAccessPoint_598015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified access point.
  ## 
  let valid = call_598027.validator(path, query, header, formData, body)
  let scheme = call_598027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598027.url(scheme.get, call_598027.host, call_598027.base,
                         call_598027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598027, url, valid)

proc call*(call_598028: Call_DeleteAccessPoint_598015; name: string): Recallable =
  ## deleteAccessPoint
  ## Deletes the specified access point.
  ##   name: string (required)
  ##       : The name of the access point you want to delete.
  var path_598029 = newJObject()
  add(path_598029, "name", newJString(name))
  result = call_598028.call(path_598029, nil, nil, nil, nil)

var deleteAccessPoint* = Call_DeleteAccessPoint_598015(name: "deleteAccessPoint",
    meth: HttpMethod.HttpDelete, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_DeleteAccessPoint_598016, base: "/",
    url: url_DeleteAccessPoint_598017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_598049 = ref object of OpenApiRestCall_597389
proc url_CreateJob_598051(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_598050(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598052 = header.getOrDefault("X-Amz-Signature")
  valid_598052 = validateParameter(valid_598052, JString, required = false,
                                 default = nil)
  if valid_598052 != nil:
    section.add "X-Amz-Signature", valid_598052
  var valid_598053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598053 = validateParameter(valid_598053, JString, required = false,
                                 default = nil)
  if valid_598053 != nil:
    section.add "X-Amz-Content-Sha256", valid_598053
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598054 = header.getOrDefault("x-amz-account-id")
  valid_598054 = validateParameter(valid_598054, JString, required = true,
                                 default = nil)
  if valid_598054 != nil:
    section.add "x-amz-account-id", valid_598054
  var valid_598055 = header.getOrDefault("X-Amz-Date")
  valid_598055 = validateParameter(valid_598055, JString, required = false,
                                 default = nil)
  if valid_598055 != nil:
    section.add "X-Amz-Date", valid_598055
  var valid_598056 = header.getOrDefault("X-Amz-Credential")
  valid_598056 = validateParameter(valid_598056, JString, required = false,
                                 default = nil)
  if valid_598056 != nil:
    section.add "X-Amz-Credential", valid_598056
  var valid_598057 = header.getOrDefault("X-Amz-Security-Token")
  valid_598057 = validateParameter(valid_598057, JString, required = false,
                                 default = nil)
  if valid_598057 != nil:
    section.add "X-Amz-Security-Token", valid_598057
  var valid_598058 = header.getOrDefault("X-Amz-Algorithm")
  valid_598058 = validateParameter(valid_598058, JString, required = false,
                                 default = nil)
  if valid_598058 != nil:
    section.add "X-Amz-Algorithm", valid_598058
  var valid_598059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598059 = validateParameter(valid_598059, JString, required = false,
                                 default = nil)
  if valid_598059 != nil:
    section.add "X-Amz-SignedHeaders", valid_598059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598061: Call_CreateJob_598049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon S3 batch operations job.
  ## 
  let valid = call_598061.validator(path, query, header, formData, body)
  let scheme = call_598061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598061.url(scheme.get, call_598061.host, call_598061.base,
                         call_598061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598061, url, valid)

proc call*(call_598062: Call_CreateJob_598049; body: JsonNode): Recallable =
  ## createJob
  ## Creates an Amazon S3 batch operations job.
  ##   body: JObject (required)
  var body_598063 = newJObject()
  if body != nil:
    body_598063 = body
  result = call_598062.call(nil, nil, nil, nil, body_598063)

var createJob* = Call_CreateJob_598049(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "s3-control.amazonaws.com",
                                    route: "/v20180820/jobs#x-amz-account-id",
                                    validator: validate_CreateJob_598050,
                                    base: "/", url: url_CreateJob_598051,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_598030 = ref object of OpenApiRestCall_597389
proc url_ListJobs_598032(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_598031(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598033 = query.getOrDefault("nextToken")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "nextToken", valid_598033
  var valid_598034 = query.getOrDefault("MaxResults")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "MaxResults", valid_598034
  var valid_598035 = query.getOrDefault("NextToken")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "NextToken", valid_598035
  var valid_598036 = query.getOrDefault("jobStatuses")
  valid_598036 = validateParameter(valid_598036, JArray, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "jobStatuses", valid_598036
  var valid_598037 = query.getOrDefault("maxResults")
  valid_598037 = validateParameter(valid_598037, JInt, required = false, default = nil)
  if valid_598037 != nil:
    section.add "maxResults", valid_598037
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
  var valid_598038 = header.getOrDefault("X-Amz-Signature")
  valid_598038 = validateParameter(valid_598038, JString, required = false,
                                 default = nil)
  if valid_598038 != nil:
    section.add "X-Amz-Signature", valid_598038
  var valid_598039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598039 = validateParameter(valid_598039, JString, required = false,
                                 default = nil)
  if valid_598039 != nil:
    section.add "X-Amz-Content-Sha256", valid_598039
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598040 = header.getOrDefault("x-amz-account-id")
  valid_598040 = validateParameter(valid_598040, JString, required = true,
                                 default = nil)
  if valid_598040 != nil:
    section.add "x-amz-account-id", valid_598040
  var valid_598041 = header.getOrDefault("X-Amz-Date")
  valid_598041 = validateParameter(valid_598041, JString, required = false,
                                 default = nil)
  if valid_598041 != nil:
    section.add "X-Amz-Date", valid_598041
  var valid_598042 = header.getOrDefault("X-Amz-Credential")
  valid_598042 = validateParameter(valid_598042, JString, required = false,
                                 default = nil)
  if valid_598042 != nil:
    section.add "X-Amz-Credential", valid_598042
  var valid_598043 = header.getOrDefault("X-Amz-Security-Token")
  valid_598043 = validateParameter(valid_598043, JString, required = false,
                                 default = nil)
  if valid_598043 != nil:
    section.add "X-Amz-Security-Token", valid_598043
  var valid_598044 = header.getOrDefault("X-Amz-Algorithm")
  valid_598044 = validateParameter(valid_598044, JString, required = false,
                                 default = nil)
  if valid_598044 != nil:
    section.add "X-Amz-Algorithm", valid_598044
  var valid_598045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598045 = validateParameter(valid_598045, JString, required = false,
                                 default = nil)
  if valid_598045 != nil:
    section.add "X-Amz-SignedHeaders", valid_598045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598046: Call_ListJobs_598030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ## 
  let valid = call_598046.validator(path, query, header, formData, body)
  let scheme = call_598046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598046.url(scheme.get, call_598046.host, call_598046.base,
                         call_598046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598046, url, valid)

proc call*(call_598047: Call_ListJobs_598030; nextToken: string = "";
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
  var query_598048 = newJObject()
  add(query_598048, "nextToken", newJString(nextToken))
  add(query_598048, "MaxResults", newJString(MaxResults))
  add(query_598048, "NextToken", newJString(NextToken))
  if jobStatuses != nil:
    query_598048.add "jobStatuses", jobStatuses
  add(query_598048, "maxResults", newJInt(maxResults))
  result = call_598047.call(nil, query_598048, nil, nil, nil)

var listJobs* = Call_ListJobs_598030(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "s3-control.amazonaws.com",
                                  route: "/v20180820/jobs#x-amz-account-id",
                                  validator: validate_ListJobs_598031, base: "/",
                                  url: url_ListJobs_598032,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccessPointPolicy_598079 = ref object of OpenApiRestCall_597389
proc url_PutAccessPointPolicy_598081(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutAccessPointPolicy_598080(path: JsonNode; query: JsonNode;
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
  var valid_598082 = path.getOrDefault("name")
  valid_598082 = validateParameter(valid_598082, JString, required = true,
                                 default = nil)
  if valid_598082 != nil:
    section.add "name", valid_598082
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
  var valid_598083 = header.getOrDefault("X-Amz-Signature")
  valid_598083 = validateParameter(valid_598083, JString, required = false,
                                 default = nil)
  if valid_598083 != nil:
    section.add "X-Amz-Signature", valid_598083
  var valid_598084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598084 = validateParameter(valid_598084, JString, required = false,
                                 default = nil)
  if valid_598084 != nil:
    section.add "X-Amz-Content-Sha256", valid_598084
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598085 = header.getOrDefault("x-amz-account-id")
  valid_598085 = validateParameter(valid_598085, JString, required = true,
                                 default = nil)
  if valid_598085 != nil:
    section.add "x-amz-account-id", valid_598085
  var valid_598086 = header.getOrDefault("X-Amz-Date")
  valid_598086 = validateParameter(valid_598086, JString, required = false,
                                 default = nil)
  if valid_598086 != nil:
    section.add "X-Amz-Date", valid_598086
  var valid_598087 = header.getOrDefault("X-Amz-Credential")
  valid_598087 = validateParameter(valid_598087, JString, required = false,
                                 default = nil)
  if valid_598087 != nil:
    section.add "X-Amz-Credential", valid_598087
  var valid_598088 = header.getOrDefault("X-Amz-Security-Token")
  valid_598088 = validateParameter(valid_598088, JString, required = false,
                                 default = nil)
  if valid_598088 != nil:
    section.add "X-Amz-Security-Token", valid_598088
  var valid_598089 = header.getOrDefault("X-Amz-Algorithm")
  valid_598089 = validateParameter(valid_598089, JString, required = false,
                                 default = nil)
  if valid_598089 != nil:
    section.add "X-Amz-Algorithm", valid_598089
  var valid_598090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598090 = validateParameter(valid_598090, JString, required = false,
                                 default = nil)
  if valid_598090 != nil:
    section.add "X-Amz-SignedHeaders", valid_598090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598092: Call_PutAccessPointPolicy_598079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point.
  ## 
  let valid = call_598092.validator(path, query, header, formData, body)
  let scheme = call_598092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598092.url(scheme.get, call_598092.host, call_598092.base,
                         call_598092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598092, url, valid)

proc call*(call_598093: Call_PutAccessPointPolicy_598079; name: string;
          body: JsonNode): Recallable =
  ## putAccessPointPolicy
  ## Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point.
  ##   name: string (required)
  ##       : The name of the access point that you want to associate with the specified policy.
  ##   body: JObject (required)
  var path_598094 = newJObject()
  var body_598095 = newJObject()
  add(path_598094, "name", newJString(name))
  if body != nil:
    body_598095 = body
  result = call_598093.call(path_598094, nil, nil, nil, body_598095)

var putAccessPointPolicy* = Call_PutAccessPointPolicy_598079(
    name: "putAccessPointPolicy", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_PutAccessPointPolicy_598080, base: "/",
    url: url_PutAccessPointPolicy_598081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPointPolicy_598064 = ref object of OpenApiRestCall_597389
proc url_GetAccessPointPolicy_598066(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPointPolicy_598065(path: JsonNode; query: JsonNode;
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
  var valid_598067 = path.getOrDefault("name")
  valid_598067 = validateParameter(valid_598067, JString, required = true,
                                 default = nil)
  if valid_598067 != nil:
    section.add "name", valid_598067
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
  var valid_598068 = header.getOrDefault("X-Amz-Signature")
  valid_598068 = validateParameter(valid_598068, JString, required = false,
                                 default = nil)
  if valid_598068 != nil:
    section.add "X-Amz-Signature", valid_598068
  var valid_598069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598069 = validateParameter(valid_598069, JString, required = false,
                                 default = nil)
  if valid_598069 != nil:
    section.add "X-Amz-Content-Sha256", valid_598069
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598070 = header.getOrDefault("x-amz-account-id")
  valid_598070 = validateParameter(valid_598070, JString, required = true,
                                 default = nil)
  if valid_598070 != nil:
    section.add "x-amz-account-id", valid_598070
  var valid_598071 = header.getOrDefault("X-Amz-Date")
  valid_598071 = validateParameter(valid_598071, JString, required = false,
                                 default = nil)
  if valid_598071 != nil:
    section.add "X-Amz-Date", valid_598071
  var valid_598072 = header.getOrDefault("X-Amz-Credential")
  valid_598072 = validateParameter(valid_598072, JString, required = false,
                                 default = nil)
  if valid_598072 != nil:
    section.add "X-Amz-Credential", valid_598072
  var valid_598073 = header.getOrDefault("X-Amz-Security-Token")
  valid_598073 = validateParameter(valid_598073, JString, required = false,
                                 default = nil)
  if valid_598073 != nil:
    section.add "X-Amz-Security-Token", valid_598073
  var valid_598074 = header.getOrDefault("X-Amz-Algorithm")
  valid_598074 = validateParameter(valid_598074, JString, required = false,
                                 default = nil)
  if valid_598074 != nil:
    section.add "X-Amz-Algorithm", valid_598074
  var valid_598075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598075 = validateParameter(valid_598075, JString, required = false,
                                 default = nil)
  if valid_598075 != nil:
    section.add "X-Amz-SignedHeaders", valid_598075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598076: Call_GetAccessPointPolicy_598064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access point policy associated with the specified access point.
  ## 
  let valid = call_598076.validator(path, query, header, formData, body)
  let scheme = call_598076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598076.url(scheme.get, call_598076.host, call_598076.base,
                         call_598076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598076, url, valid)

proc call*(call_598077: Call_GetAccessPointPolicy_598064; name: string): Recallable =
  ## getAccessPointPolicy
  ## Returns the access point policy associated with the specified access point.
  ##   name: string (required)
  ##       : The name of the access point whose policy you want to retrieve.
  var path_598078 = newJObject()
  add(path_598078, "name", newJString(name))
  result = call_598077.call(path_598078, nil, nil, nil, nil)

var getAccessPointPolicy* = Call_GetAccessPointPolicy_598064(
    name: "getAccessPointPolicy", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_GetAccessPointPolicy_598065, base: "/",
    url: url_GetAccessPointPolicy_598066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccessPointPolicy_598096 = ref object of OpenApiRestCall_597389
proc url_DeleteAccessPointPolicy_598098(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccessPointPolicy_598097(path: JsonNode; query: JsonNode;
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
  var valid_598099 = path.getOrDefault("name")
  valid_598099 = validateParameter(valid_598099, JString, required = true,
                                 default = nil)
  if valid_598099 != nil:
    section.add "name", valid_598099
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
  var valid_598100 = header.getOrDefault("X-Amz-Signature")
  valid_598100 = validateParameter(valid_598100, JString, required = false,
                                 default = nil)
  if valid_598100 != nil:
    section.add "X-Amz-Signature", valid_598100
  var valid_598101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598101 = validateParameter(valid_598101, JString, required = false,
                                 default = nil)
  if valid_598101 != nil:
    section.add "X-Amz-Content-Sha256", valid_598101
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598102 = header.getOrDefault("x-amz-account-id")
  valid_598102 = validateParameter(valid_598102, JString, required = true,
                                 default = nil)
  if valid_598102 != nil:
    section.add "x-amz-account-id", valid_598102
  var valid_598103 = header.getOrDefault("X-Amz-Date")
  valid_598103 = validateParameter(valid_598103, JString, required = false,
                                 default = nil)
  if valid_598103 != nil:
    section.add "X-Amz-Date", valid_598103
  var valid_598104 = header.getOrDefault("X-Amz-Credential")
  valid_598104 = validateParameter(valid_598104, JString, required = false,
                                 default = nil)
  if valid_598104 != nil:
    section.add "X-Amz-Credential", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-Security-Token")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Security-Token", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Algorithm")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Algorithm", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-SignedHeaders", valid_598107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598108: Call_DeleteAccessPointPolicy_598096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the access point policy for the specified access point.
  ## 
  let valid = call_598108.validator(path, query, header, formData, body)
  let scheme = call_598108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598108.url(scheme.get, call_598108.host, call_598108.base,
                         call_598108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598108, url, valid)

proc call*(call_598109: Call_DeleteAccessPointPolicy_598096; name: string): Recallable =
  ## deleteAccessPointPolicy
  ## Deletes the access point policy for the specified access point.
  ##   name: string (required)
  ##       : The name of the access point whose policy you want to delete.
  var path_598110 = newJObject()
  add(path_598110, "name", newJString(name))
  result = call_598109.call(path_598110, nil, nil, nil, nil)

var deleteAccessPointPolicy* = Call_DeleteAccessPointPolicy_598096(
    name: "deleteAccessPointPolicy", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_DeleteAccessPointPolicy_598097, base: "/",
    url: url_DeleteAccessPointPolicy_598098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_598124 = ref object of OpenApiRestCall_597389
proc url_PutPublicAccessBlock_598126(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutPublicAccessBlock_598125(path: JsonNode; query: JsonNode;
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
  var valid_598127 = header.getOrDefault("X-Amz-Signature")
  valid_598127 = validateParameter(valid_598127, JString, required = false,
                                 default = nil)
  if valid_598127 != nil:
    section.add "X-Amz-Signature", valid_598127
  var valid_598128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598128 = validateParameter(valid_598128, JString, required = false,
                                 default = nil)
  if valid_598128 != nil:
    section.add "X-Amz-Content-Sha256", valid_598128
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598129 = header.getOrDefault("x-amz-account-id")
  valid_598129 = validateParameter(valid_598129, JString, required = true,
                                 default = nil)
  if valid_598129 != nil:
    section.add "x-amz-account-id", valid_598129
  var valid_598130 = header.getOrDefault("X-Amz-Date")
  valid_598130 = validateParameter(valid_598130, JString, required = false,
                                 default = nil)
  if valid_598130 != nil:
    section.add "X-Amz-Date", valid_598130
  var valid_598131 = header.getOrDefault("X-Amz-Credential")
  valid_598131 = validateParameter(valid_598131, JString, required = false,
                                 default = nil)
  if valid_598131 != nil:
    section.add "X-Amz-Credential", valid_598131
  var valid_598132 = header.getOrDefault("X-Amz-Security-Token")
  valid_598132 = validateParameter(valid_598132, JString, required = false,
                                 default = nil)
  if valid_598132 != nil:
    section.add "X-Amz-Security-Token", valid_598132
  var valid_598133 = header.getOrDefault("X-Amz-Algorithm")
  valid_598133 = validateParameter(valid_598133, JString, required = false,
                                 default = nil)
  if valid_598133 != nil:
    section.add "X-Amz-Algorithm", valid_598133
  var valid_598134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598134 = validateParameter(valid_598134, JString, required = false,
                                 default = nil)
  if valid_598134 != nil:
    section.add "X-Amz-SignedHeaders", valid_598134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598136: Call_PutPublicAccessBlock_598124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  let valid = call_598136.validator(path, query, header, formData, body)
  let scheme = call_598136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598136.url(scheme.get, call_598136.host, call_598136.base,
                         call_598136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598136, url, valid)

proc call*(call_598137: Call_PutPublicAccessBlock_598124; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ##   body: JObject (required)
  var body_598138 = newJObject()
  if body != nil:
    body_598138 = body
  result = call_598137.call(nil, nil, nil, nil, body_598138)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_598124(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_PutPublicAccessBlock_598125, base: "/",
    url: url_PutPublicAccessBlock_598126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_598111 = ref object of OpenApiRestCall_597389
proc url_GetPublicAccessBlock_598113(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPublicAccessBlock_598112(path: JsonNode; query: JsonNode;
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
  var valid_598114 = header.getOrDefault("X-Amz-Signature")
  valid_598114 = validateParameter(valid_598114, JString, required = false,
                                 default = nil)
  if valid_598114 != nil:
    section.add "X-Amz-Signature", valid_598114
  var valid_598115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598115 = validateParameter(valid_598115, JString, required = false,
                                 default = nil)
  if valid_598115 != nil:
    section.add "X-Amz-Content-Sha256", valid_598115
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598116 = header.getOrDefault("x-amz-account-id")
  valid_598116 = validateParameter(valid_598116, JString, required = true,
                                 default = nil)
  if valid_598116 != nil:
    section.add "x-amz-account-id", valid_598116
  var valid_598117 = header.getOrDefault("X-Amz-Date")
  valid_598117 = validateParameter(valid_598117, JString, required = false,
                                 default = nil)
  if valid_598117 != nil:
    section.add "X-Amz-Date", valid_598117
  var valid_598118 = header.getOrDefault("X-Amz-Credential")
  valid_598118 = validateParameter(valid_598118, JString, required = false,
                                 default = nil)
  if valid_598118 != nil:
    section.add "X-Amz-Credential", valid_598118
  var valid_598119 = header.getOrDefault("X-Amz-Security-Token")
  valid_598119 = validateParameter(valid_598119, JString, required = false,
                                 default = nil)
  if valid_598119 != nil:
    section.add "X-Amz-Security-Token", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-Algorithm")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-Algorithm", valid_598120
  var valid_598121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "X-Amz-SignedHeaders", valid_598121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598122: Call_GetPublicAccessBlock_598111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  let valid = call_598122.validator(path, query, header, formData, body)
  let scheme = call_598122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598122.url(scheme.get, call_598122.host, call_598122.base,
                         call_598122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598122, url, valid)

proc call*(call_598123: Call_GetPublicAccessBlock_598111): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  result = call_598123.call(nil, nil, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_598111(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_GetPublicAccessBlock_598112, base: "/",
    url: url_GetPublicAccessBlock_598113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_598139 = ref object of OpenApiRestCall_597389
proc url_DeletePublicAccessBlock_598141(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePublicAccessBlock_598140(path: JsonNode; query: JsonNode;
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
  var valid_598142 = header.getOrDefault("X-Amz-Signature")
  valid_598142 = validateParameter(valid_598142, JString, required = false,
                                 default = nil)
  if valid_598142 != nil:
    section.add "X-Amz-Signature", valid_598142
  var valid_598143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598143 = validateParameter(valid_598143, JString, required = false,
                                 default = nil)
  if valid_598143 != nil:
    section.add "X-Amz-Content-Sha256", valid_598143
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598144 = header.getOrDefault("x-amz-account-id")
  valid_598144 = validateParameter(valid_598144, JString, required = true,
                                 default = nil)
  if valid_598144 != nil:
    section.add "x-amz-account-id", valid_598144
  var valid_598145 = header.getOrDefault("X-Amz-Date")
  valid_598145 = validateParameter(valid_598145, JString, required = false,
                                 default = nil)
  if valid_598145 != nil:
    section.add "X-Amz-Date", valid_598145
  var valid_598146 = header.getOrDefault("X-Amz-Credential")
  valid_598146 = validateParameter(valid_598146, JString, required = false,
                                 default = nil)
  if valid_598146 != nil:
    section.add "X-Amz-Credential", valid_598146
  var valid_598147 = header.getOrDefault("X-Amz-Security-Token")
  valid_598147 = validateParameter(valid_598147, JString, required = false,
                                 default = nil)
  if valid_598147 != nil:
    section.add "X-Amz-Security-Token", valid_598147
  var valid_598148 = header.getOrDefault("X-Amz-Algorithm")
  valid_598148 = validateParameter(valid_598148, JString, required = false,
                                 default = nil)
  if valid_598148 != nil:
    section.add "X-Amz-Algorithm", valid_598148
  var valid_598149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598149 = validateParameter(valid_598149, JString, required = false,
                                 default = nil)
  if valid_598149 != nil:
    section.add "X-Amz-SignedHeaders", valid_598149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598150: Call_DeletePublicAccessBlock_598139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  let valid = call_598150.validator(path, query, header, formData, body)
  let scheme = call_598150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598150.url(scheme.get, call_598150.host, call_598150.base,
                         call_598150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598150, url, valid)

proc call*(call_598151: Call_DeletePublicAccessBlock_598139): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  result = call_598151.call(nil, nil, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_598139(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_DeletePublicAccessBlock_598140, base: "/",
    url: url_DeletePublicAccessBlock_598141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_598152 = ref object of OpenApiRestCall_597389
proc url_DescribeJob_598154(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeJob_598153(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598155 = path.getOrDefault("id")
  valid_598155 = validateParameter(valid_598155, JString, required = true,
                                 default = nil)
  if valid_598155 != nil:
    section.add "id", valid_598155
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
  var valid_598156 = header.getOrDefault("X-Amz-Signature")
  valid_598156 = validateParameter(valid_598156, JString, required = false,
                                 default = nil)
  if valid_598156 != nil:
    section.add "X-Amz-Signature", valid_598156
  var valid_598157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598157 = validateParameter(valid_598157, JString, required = false,
                                 default = nil)
  if valid_598157 != nil:
    section.add "X-Amz-Content-Sha256", valid_598157
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598158 = header.getOrDefault("x-amz-account-id")
  valid_598158 = validateParameter(valid_598158, JString, required = true,
                                 default = nil)
  if valid_598158 != nil:
    section.add "x-amz-account-id", valid_598158
  var valid_598159 = header.getOrDefault("X-Amz-Date")
  valid_598159 = validateParameter(valid_598159, JString, required = false,
                                 default = nil)
  if valid_598159 != nil:
    section.add "X-Amz-Date", valid_598159
  var valid_598160 = header.getOrDefault("X-Amz-Credential")
  valid_598160 = validateParameter(valid_598160, JString, required = false,
                                 default = nil)
  if valid_598160 != nil:
    section.add "X-Amz-Credential", valid_598160
  var valid_598161 = header.getOrDefault("X-Amz-Security-Token")
  valid_598161 = validateParameter(valid_598161, JString, required = false,
                                 default = nil)
  if valid_598161 != nil:
    section.add "X-Amz-Security-Token", valid_598161
  var valid_598162 = header.getOrDefault("X-Amz-Algorithm")
  valid_598162 = validateParameter(valid_598162, JString, required = false,
                                 default = nil)
  if valid_598162 != nil:
    section.add "X-Amz-Algorithm", valid_598162
  var valid_598163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598163 = validateParameter(valid_598163, JString, required = false,
                                 default = nil)
  if valid_598163 != nil:
    section.add "X-Amz-SignedHeaders", valid_598163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598164: Call_DescribeJob_598152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the configuration parameters and status for a batch operations job.
  ## 
  let valid = call_598164.validator(path, query, header, formData, body)
  let scheme = call_598164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598164.url(scheme.get, call_598164.host, call_598164.base,
                         call_598164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598164, url, valid)

proc call*(call_598165: Call_DescribeJob_598152; id: string): Recallable =
  ## describeJob
  ## Retrieves the configuration parameters and status for a batch operations job.
  ##   id: string (required)
  ##     : The ID for the job whose information you want to retrieve.
  var path_598166 = newJObject()
  add(path_598166, "id", newJString(id))
  result = call_598165.call(path_598166, nil, nil, nil, nil)

var describeJob* = Call_DescribeJob_598152(name: "describeJob",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3-control.amazonaws.com", route: "/v20180820/jobs/{id}#x-amz-account-id",
                                        validator: validate_DescribeJob_598153,
                                        base: "/", url: url_DescribeJob_598154,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPointPolicyStatus_598167 = ref object of OpenApiRestCall_597389
proc url_GetAccessPointPolicyStatus_598169(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPointPolicyStatus_598168(path: JsonNode; query: JsonNode;
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
  var valid_598170 = path.getOrDefault("name")
  valid_598170 = validateParameter(valid_598170, JString, required = true,
                                 default = nil)
  if valid_598170 != nil:
    section.add "name", valid_598170
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
  var valid_598171 = header.getOrDefault("X-Amz-Signature")
  valid_598171 = validateParameter(valid_598171, JString, required = false,
                                 default = nil)
  if valid_598171 != nil:
    section.add "X-Amz-Signature", valid_598171
  var valid_598172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598172 = validateParameter(valid_598172, JString, required = false,
                                 default = nil)
  if valid_598172 != nil:
    section.add "X-Amz-Content-Sha256", valid_598172
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598173 = header.getOrDefault("x-amz-account-id")
  valid_598173 = validateParameter(valid_598173, JString, required = true,
                                 default = nil)
  if valid_598173 != nil:
    section.add "x-amz-account-id", valid_598173
  var valid_598174 = header.getOrDefault("X-Amz-Date")
  valid_598174 = validateParameter(valid_598174, JString, required = false,
                                 default = nil)
  if valid_598174 != nil:
    section.add "X-Amz-Date", valid_598174
  var valid_598175 = header.getOrDefault("X-Amz-Credential")
  valid_598175 = validateParameter(valid_598175, JString, required = false,
                                 default = nil)
  if valid_598175 != nil:
    section.add "X-Amz-Credential", valid_598175
  var valid_598176 = header.getOrDefault("X-Amz-Security-Token")
  valid_598176 = validateParameter(valid_598176, JString, required = false,
                                 default = nil)
  if valid_598176 != nil:
    section.add "X-Amz-Security-Token", valid_598176
  var valid_598177 = header.getOrDefault("X-Amz-Algorithm")
  valid_598177 = validateParameter(valid_598177, JString, required = false,
                                 default = nil)
  if valid_598177 != nil:
    section.add "X-Amz-Algorithm", valid_598177
  var valid_598178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598178 = validateParameter(valid_598178, JString, required = false,
                                 default = nil)
  if valid_598178 != nil:
    section.add "X-Amz-SignedHeaders", valid_598178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598179: Call_GetAccessPointPolicyStatus_598167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html">Managing Data Access with Amazon S3 Access Points</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ## 
  let valid = call_598179.validator(path, query, header, formData, body)
  let scheme = call_598179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598179.url(scheme.get, call_598179.host, call_598179.base,
                         call_598179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598179, url, valid)

proc call*(call_598180: Call_GetAccessPointPolicyStatus_598167; name: string): Recallable =
  ## getAccessPointPolicyStatus
  ## Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html">Managing Data Access with Amazon S3 Access Points</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   name: string (required)
  ##       : The name of the access point whose policy status you want to retrieve.
  var path_598181 = newJObject()
  add(path_598181, "name", newJString(name))
  result = call_598180.call(path_598181, nil, nil, nil, nil)

var getAccessPointPolicyStatus* = Call_GetAccessPointPolicyStatus_598167(
    name: "getAccessPointPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policyStatus#x-amz-account-id",
    validator: validate_GetAccessPointPolicyStatus_598168, base: "/",
    url: url_GetAccessPointPolicyStatus_598169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccessPoints_598182 = ref object of OpenApiRestCall_597389
proc url_ListAccessPoints_598184(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccessPoints_598183(path: JsonNode; query: JsonNode;
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
  var valid_598185 = query.getOrDefault("bucket")
  valid_598185 = validateParameter(valid_598185, JString, required = false,
                                 default = nil)
  if valid_598185 != nil:
    section.add "bucket", valid_598185
  var valid_598186 = query.getOrDefault("nextToken")
  valid_598186 = validateParameter(valid_598186, JString, required = false,
                                 default = nil)
  if valid_598186 != nil:
    section.add "nextToken", valid_598186
  var valid_598187 = query.getOrDefault("MaxResults")
  valid_598187 = validateParameter(valid_598187, JString, required = false,
                                 default = nil)
  if valid_598187 != nil:
    section.add "MaxResults", valid_598187
  var valid_598188 = query.getOrDefault("NextToken")
  valid_598188 = validateParameter(valid_598188, JString, required = false,
                                 default = nil)
  if valid_598188 != nil:
    section.add "NextToken", valid_598188
  var valid_598189 = query.getOrDefault("maxResults")
  valid_598189 = validateParameter(valid_598189, JInt, required = false, default = nil)
  if valid_598189 != nil:
    section.add "maxResults", valid_598189
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
  var valid_598190 = header.getOrDefault("X-Amz-Signature")
  valid_598190 = validateParameter(valid_598190, JString, required = false,
                                 default = nil)
  if valid_598190 != nil:
    section.add "X-Amz-Signature", valid_598190
  var valid_598191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598191 = validateParameter(valid_598191, JString, required = false,
                                 default = nil)
  if valid_598191 != nil:
    section.add "X-Amz-Content-Sha256", valid_598191
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598192 = header.getOrDefault("x-amz-account-id")
  valid_598192 = validateParameter(valid_598192, JString, required = true,
                                 default = nil)
  if valid_598192 != nil:
    section.add "x-amz-account-id", valid_598192
  var valid_598193 = header.getOrDefault("X-Amz-Date")
  valid_598193 = validateParameter(valid_598193, JString, required = false,
                                 default = nil)
  if valid_598193 != nil:
    section.add "X-Amz-Date", valid_598193
  var valid_598194 = header.getOrDefault("X-Amz-Credential")
  valid_598194 = validateParameter(valid_598194, JString, required = false,
                                 default = nil)
  if valid_598194 != nil:
    section.add "X-Amz-Credential", valid_598194
  var valid_598195 = header.getOrDefault("X-Amz-Security-Token")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "X-Amz-Security-Token", valid_598195
  var valid_598196 = header.getOrDefault("X-Amz-Algorithm")
  valid_598196 = validateParameter(valid_598196, JString, required = false,
                                 default = nil)
  if valid_598196 != nil:
    section.add "X-Amz-Algorithm", valid_598196
  var valid_598197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598197 = validateParameter(valid_598197, JString, required = false,
                                 default = nil)
  if valid_598197 != nil:
    section.add "X-Amz-SignedHeaders", valid_598197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598198: Call_ListAccessPoints_598182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the access points currently associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1000 access points (or the number specified in <code>maxResults</code>, whichever is less), then the response will include a continuation token that you can use to list the additional access points.
  ## 
  let valid = call_598198.validator(path, query, header, formData, body)
  let scheme = call_598198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598198.url(scheme.get, call_598198.host, call_598198.base,
                         call_598198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598198, url, valid)

proc call*(call_598199: Call_ListAccessPoints_598182; bucket: string = "";
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
  var query_598200 = newJObject()
  add(query_598200, "bucket", newJString(bucket))
  add(query_598200, "nextToken", newJString(nextToken))
  add(query_598200, "MaxResults", newJString(MaxResults))
  add(query_598200, "NextToken", newJString(NextToken))
  add(query_598200, "maxResults", newJInt(maxResults))
  result = call_598199.call(nil, query_598200, nil, nil, nil)

var listAccessPoints* = Call_ListAccessPoints_598182(name: "listAccessPoints",
    meth: HttpMethod.HttpGet, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint#x-amz-account-id",
    validator: validate_ListAccessPoints_598183, base: "/",
    url: url_ListAccessPoints_598184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobPriority_598201 = ref object of OpenApiRestCall_597389
proc url_UpdateJobPriority_598203(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobPriority_598202(path: JsonNode; query: JsonNode;
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
  var valid_598204 = path.getOrDefault("id")
  valid_598204 = validateParameter(valid_598204, JString, required = true,
                                 default = nil)
  if valid_598204 != nil:
    section.add "id", valid_598204
  result.add "path", section
  ## parameters in `query` object:
  ##   priority: JInt (required)
  ##           : The priority you want to assign to this job.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `priority` field"
  var valid_598205 = query.getOrDefault("priority")
  valid_598205 = validateParameter(valid_598205, JInt, required = true, default = nil)
  if valid_598205 != nil:
    section.add "priority", valid_598205
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
  var valid_598206 = header.getOrDefault("X-Amz-Signature")
  valid_598206 = validateParameter(valid_598206, JString, required = false,
                                 default = nil)
  if valid_598206 != nil:
    section.add "X-Amz-Signature", valid_598206
  var valid_598207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598207 = validateParameter(valid_598207, JString, required = false,
                                 default = nil)
  if valid_598207 != nil:
    section.add "X-Amz-Content-Sha256", valid_598207
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598208 = header.getOrDefault("x-amz-account-id")
  valid_598208 = validateParameter(valid_598208, JString, required = true,
                                 default = nil)
  if valid_598208 != nil:
    section.add "x-amz-account-id", valid_598208
  var valid_598209 = header.getOrDefault("X-Amz-Date")
  valid_598209 = validateParameter(valid_598209, JString, required = false,
                                 default = nil)
  if valid_598209 != nil:
    section.add "X-Amz-Date", valid_598209
  var valid_598210 = header.getOrDefault("X-Amz-Credential")
  valid_598210 = validateParameter(valid_598210, JString, required = false,
                                 default = nil)
  if valid_598210 != nil:
    section.add "X-Amz-Credential", valid_598210
  var valid_598211 = header.getOrDefault("X-Amz-Security-Token")
  valid_598211 = validateParameter(valid_598211, JString, required = false,
                                 default = nil)
  if valid_598211 != nil:
    section.add "X-Amz-Security-Token", valid_598211
  var valid_598212 = header.getOrDefault("X-Amz-Algorithm")
  valid_598212 = validateParameter(valid_598212, JString, required = false,
                                 default = nil)
  if valid_598212 != nil:
    section.add "X-Amz-Algorithm", valid_598212
  var valid_598213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598213 = validateParameter(valid_598213, JString, required = false,
                                 default = nil)
  if valid_598213 != nil:
    section.add "X-Amz-SignedHeaders", valid_598213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598214: Call_UpdateJobPriority_598201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job's priority.
  ## 
  let valid = call_598214.validator(path, query, header, formData, body)
  let scheme = call_598214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598214.url(scheme.get, call_598214.host, call_598214.base,
                         call_598214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598214, url, valid)

proc call*(call_598215: Call_UpdateJobPriority_598201; id: string; priority: int): Recallable =
  ## updateJobPriority
  ## Updates an existing job's priority.
  ##   id: string (required)
  ##     : The ID for the job whose priority you want to update.
  ##   priority: int (required)
  ##           : The priority you want to assign to this job.
  var path_598216 = newJObject()
  var query_598217 = newJObject()
  add(path_598216, "id", newJString(id))
  add(query_598217, "priority", newJInt(priority))
  result = call_598215.call(path_598216, query_598217, nil, nil, nil)

var updateJobPriority* = Call_UpdateJobPriority_598201(name: "updateJobPriority",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/priority#x-amz-account-id&priority",
    validator: validate_UpdateJobPriority_598202, base: "/",
    url: url_UpdateJobPriority_598203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobStatus_598218 = ref object of OpenApiRestCall_597389
proc url_UpdateJobStatus_598220(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobStatus_598219(path: JsonNode; query: JsonNode;
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
  var valid_598221 = path.getOrDefault("id")
  valid_598221 = validateParameter(valid_598221, JString, required = true,
                                 default = nil)
  if valid_598221 != nil:
    section.add "id", valid_598221
  result.add "path", section
  ## parameters in `query` object:
  ##   statusUpdateReason: JString
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  ##   requestedJobStatus: JString (required)
  ##                     : The status that you want to move the specified job to.
  section = newJObject()
  var valid_598222 = query.getOrDefault("statusUpdateReason")
  valid_598222 = validateParameter(valid_598222, JString, required = false,
                                 default = nil)
  if valid_598222 != nil:
    section.add "statusUpdateReason", valid_598222
  assert query != nil, "query argument is necessary due to required `requestedJobStatus` field"
  var valid_598236 = query.getOrDefault("requestedJobStatus")
  valid_598236 = validateParameter(valid_598236, JString, required = true,
                                 default = newJString("Cancelled"))
  if valid_598236 != nil:
    section.add "requestedJobStatus", valid_598236
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
  var valid_598237 = header.getOrDefault("X-Amz-Signature")
  valid_598237 = validateParameter(valid_598237, JString, required = false,
                                 default = nil)
  if valid_598237 != nil:
    section.add "X-Amz-Signature", valid_598237
  var valid_598238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598238 = validateParameter(valid_598238, JString, required = false,
                                 default = nil)
  if valid_598238 != nil:
    section.add "X-Amz-Content-Sha256", valid_598238
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_598239 = header.getOrDefault("x-amz-account-id")
  valid_598239 = validateParameter(valid_598239, JString, required = true,
                                 default = nil)
  if valid_598239 != nil:
    section.add "x-amz-account-id", valid_598239
  var valid_598240 = header.getOrDefault("X-Amz-Date")
  valid_598240 = validateParameter(valid_598240, JString, required = false,
                                 default = nil)
  if valid_598240 != nil:
    section.add "X-Amz-Date", valid_598240
  var valid_598241 = header.getOrDefault("X-Amz-Credential")
  valid_598241 = validateParameter(valid_598241, JString, required = false,
                                 default = nil)
  if valid_598241 != nil:
    section.add "X-Amz-Credential", valid_598241
  var valid_598242 = header.getOrDefault("X-Amz-Security-Token")
  valid_598242 = validateParameter(valid_598242, JString, required = false,
                                 default = nil)
  if valid_598242 != nil:
    section.add "X-Amz-Security-Token", valid_598242
  var valid_598243 = header.getOrDefault("X-Amz-Algorithm")
  valid_598243 = validateParameter(valid_598243, JString, required = false,
                                 default = nil)
  if valid_598243 != nil:
    section.add "X-Amz-Algorithm", valid_598243
  var valid_598244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598244 = validateParameter(valid_598244, JString, required = false,
                                 default = nil)
  if valid_598244 != nil:
    section.add "X-Amz-SignedHeaders", valid_598244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598245: Call_UpdateJobStatus_598218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ## 
  let valid = call_598245.validator(path, query, header, formData, body)
  let scheme = call_598245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598245.url(scheme.get, call_598245.host, call_598245.base,
                         call_598245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598245, url, valid)

proc call*(call_598246: Call_UpdateJobStatus_598218; id: string;
          statusUpdateReason: string = ""; requestedJobStatus: string = "Cancelled"): Recallable =
  ## updateJobStatus
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ##   statusUpdateReason: string
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  ##   id: string (required)
  ##     : The ID of the job whose status you want to update.
  ##   requestedJobStatus: string (required)
  ##                     : The status that you want to move the specified job to.
  var path_598247 = newJObject()
  var query_598248 = newJObject()
  add(query_598248, "statusUpdateReason", newJString(statusUpdateReason))
  add(path_598247, "id", newJString(id))
  add(query_598248, "requestedJobStatus", newJString(requestedJobStatus))
  result = call_598246.call(path_598247, query_598248, nil, nil, nil)

var updateJobStatus* = Call_UpdateJobStatus_598218(name: "updateJobStatus",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/status#x-amz-account-id&requestedJobStatus",
    validator: validate_UpdateJobStatus_598219, base: "/", url: url_UpdateJobStatus_598220,
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
