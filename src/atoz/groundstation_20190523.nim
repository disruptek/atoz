
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Ground Station
## version: 2019-05-23
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Welcome to the AWS Ground Station API Reference. AWS Ground Station is a fully managed service that enables you to control satellite communications, downlink and process satellite data, and scale your satellite operations efficiently and cost-effectively without having to build or manage your own ground station infrastructure.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/groundstation/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "groundstation.ap-northeast-1.amazonaws.com", "ap-southeast-1": "groundstation.ap-southeast-1.amazonaws.com", "us-west-2": "groundstation.us-west-2.amazonaws.com", "eu-west-2": "groundstation.eu-west-2.amazonaws.com", "ap-northeast-3": "groundstation.ap-northeast-3.amazonaws.com", "eu-central-1": "groundstation.eu-central-1.amazonaws.com", "us-east-2": "groundstation.us-east-2.amazonaws.com", "us-east-1": "groundstation.us-east-1.amazonaws.com", "cn-northwest-1": "groundstation.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "groundstation.ap-south-1.amazonaws.com", "eu-north-1": "groundstation.eu-north-1.amazonaws.com", "ap-northeast-2": "groundstation.ap-northeast-2.amazonaws.com", "us-west-1": "groundstation.us-west-1.amazonaws.com", "us-gov-east-1": "groundstation.us-gov-east-1.amazonaws.com", "eu-west-3": "groundstation.eu-west-3.amazonaws.com", "cn-north-1": "groundstation.cn-north-1.amazonaws.com.cn", "sa-east-1": "groundstation.sa-east-1.amazonaws.com", "eu-west-1": "groundstation.eu-west-1.amazonaws.com", "us-gov-west-1": "groundstation.us-gov-west-1.amazonaws.com", "ap-southeast-2": "groundstation.ap-southeast-2.amazonaws.com", "ca-central-1": "groundstation.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "groundstation.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "groundstation.ap-southeast-1.amazonaws.com",
      "us-west-2": "groundstation.us-west-2.amazonaws.com",
      "eu-west-2": "groundstation.eu-west-2.amazonaws.com",
      "ap-northeast-3": "groundstation.ap-northeast-3.amazonaws.com",
      "eu-central-1": "groundstation.eu-central-1.amazonaws.com",
      "us-east-2": "groundstation.us-east-2.amazonaws.com",
      "us-east-1": "groundstation.us-east-1.amazonaws.com",
      "cn-northwest-1": "groundstation.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "groundstation.ap-south-1.amazonaws.com",
      "eu-north-1": "groundstation.eu-north-1.amazonaws.com",
      "ap-northeast-2": "groundstation.ap-northeast-2.amazonaws.com",
      "us-west-1": "groundstation.us-west-1.amazonaws.com",
      "us-gov-east-1": "groundstation.us-gov-east-1.amazonaws.com",
      "eu-west-3": "groundstation.eu-west-3.amazonaws.com",
      "cn-north-1": "groundstation.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "groundstation.sa-east-1.amazonaws.com",
      "eu-west-1": "groundstation.eu-west-1.amazonaws.com",
      "us-gov-west-1": "groundstation.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "groundstation.ap-southeast-2.amazonaws.com",
      "ca-central-1": "groundstation.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "groundstation"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DescribeContact_610996 = ref object of OpenApiRestCall_610658
proc url_DescribeContact_610998(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "contactId" in path, "`contactId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/contact/"),
               (kind: VariableSegment, value: "contactId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeContact_610997(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Describes an existing contact.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   contactId: JString (required)
  ##            : UUID of a contact.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `contactId` field"
  var valid_611124 = path.getOrDefault("contactId")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "contactId", valid_611124
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
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
  var valid_611127 = header.getOrDefault("X-Amz-Date")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Date", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Credential")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Credential", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Security-Token")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Security-Token", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Algorithm")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Algorithm", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-SignedHeaders", valid_611131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_DescribeContact_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing contact.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_DescribeContact_610996; contactId: string): Recallable =
  ## describeContact
  ## Describes an existing contact.
  ##   contactId: string (required)
  ##            : UUID of a contact.
  var path_611226 = newJObject()
  add(path_611226, "contactId", newJString(contactId))
  result = call_611225.call(path_611226, nil, nil, nil, nil)

var describeContact* = Call_DescribeContact_610996(name: "describeContact",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_DescribeContact_610997,
    base: "/", url: url_DescribeContact_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelContact_611266 = ref object of OpenApiRestCall_610658
proc url_CancelContact_611268(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "contactId" in path, "`contactId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/contact/"),
               (kind: VariableSegment, value: "contactId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelContact_611267(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels a contact with a specified contact ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   contactId: JString (required)
  ##            : UUID of a contact.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `contactId` field"
  var valid_611269 = path.getOrDefault("contactId")
  valid_611269 = validateParameter(valid_611269, JString, required = true,
                                 default = nil)
  if valid_611269 != nil:
    section.add "contactId", valid_611269
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611270 = header.getOrDefault("X-Amz-Signature")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Signature", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Content-Sha256", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Date")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Date", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Credential")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Credential", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Security-Token")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Security-Token", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Algorithm")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Algorithm", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-SignedHeaders", valid_611276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_CancelContact_611266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a contact with a specified contact ID.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_CancelContact_611266; contactId: string): Recallable =
  ## cancelContact
  ## Cancels a contact with a specified contact ID.
  ##   contactId: string (required)
  ##            : UUID of a contact.
  var path_611279 = newJObject()
  add(path_611279, "contactId", newJString(contactId))
  result = call_611278.call(path_611279, nil, nil, nil, nil)

var cancelContact* = Call_CancelContact_611266(name: "cancelContact",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_CancelContact_611267,
    base: "/", url: url_CancelContact_611268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfig_611295 = ref object of OpenApiRestCall_610658
proc url_CreateConfig_611297(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfig_611296(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p> <p>Only one type of <code>configData</code> can be specified.</p>
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611298 = header.getOrDefault("X-Amz-Signature")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Signature", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Content-Sha256", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Date")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Date", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Credential")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Credential", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Security-Token")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Security-Token", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Algorithm")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Algorithm", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-SignedHeaders", valid_611304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611306: Call_CreateConfig_611295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p> <p>Only one type of <code>configData</code> can be specified.</p>
  ## 
  let valid = call_611306.validator(path, query, header, formData, body)
  let scheme = call_611306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611306.url(scheme.get, call_611306.host, call_611306.base,
                         call_611306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611306, url, valid)

proc call*(call_611307: Call_CreateConfig_611295; body: JsonNode): Recallable =
  ## createConfig
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p> <p>Only one type of <code>configData</code> can be specified.</p>
  ##   body: JObject (required)
  var body_611308 = newJObject()
  if body != nil:
    body_611308 = body
  result = call_611307.call(nil, nil, nil, nil, body_611308)

var createConfig* = Call_CreateConfig_611295(name: "createConfig",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/config", validator: validate_CreateConfig_611296, base: "/",
    url: url_CreateConfig_611297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigs_611280 = ref object of OpenApiRestCall_610658
proc url_ListConfigs_611282(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigs_611281(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>Config</code> objects.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Next token returned in the request of a previous <code>ListConfigs</code> call. Used to get the next page of results.
  ##   maxResults: JInt
  ##             : Maximum number of <code>Configs</code> returned.
  section = newJObject()
  var valid_611283 = query.getOrDefault("nextToken")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "nextToken", valid_611283
  var valid_611284 = query.getOrDefault("maxResults")
  valid_611284 = validateParameter(valid_611284, JInt, required = false, default = nil)
  if valid_611284 != nil:
    section.add "maxResults", valid_611284
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611285 = header.getOrDefault("X-Amz-Signature")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Signature", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Content-Sha256", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Date")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Date", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Credential")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Credential", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Security-Token")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Security-Token", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Algorithm")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Algorithm", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-SignedHeaders", valid_611291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_ListConfigs_611280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>Config</code> objects.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_ListConfigs_611280; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listConfigs
  ## Returns a list of <code>Config</code> objects.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListConfigs</code> call. Used to get the next page of results.
  ##   maxResults: int
  ##             : Maximum number of <code>Configs</code> returned.
  var query_611294 = newJObject()
  add(query_611294, "nextToken", newJString(nextToken))
  add(query_611294, "maxResults", newJInt(maxResults))
  result = call_611293.call(nil, query_611294, nil, nil, nil)

var listConfigs* = Call_ListConfigs_611280(name: "listConfigs",
                                        meth: HttpMethod.HttpGet,
                                        host: "groundstation.amazonaws.com",
                                        route: "/config",
                                        validator: validate_ListConfigs_611281,
                                        base: "/", url: url_ListConfigs_611282,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataflowEndpointGroup_611324 = ref object of OpenApiRestCall_610658
proc url_CreateDataflowEndpointGroup_611326(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataflowEndpointGroup_611325(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p> <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> to specify which endpoints to use during a contact.</p> <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> must match a <code>DataflowEndpoint</code> in the same group.</p>
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611327 = header.getOrDefault("X-Amz-Signature")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Signature", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Content-Sha256", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Date")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Date", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Credential")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Credential", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Security-Token")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Security-Token", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Algorithm")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Algorithm", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-SignedHeaders", valid_611333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611335: Call_CreateDataflowEndpointGroup_611324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p> <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> to specify which endpoints to use during a contact.</p> <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> must match a <code>DataflowEndpoint</code> in the same group.</p>
  ## 
  let valid = call_611335.validator(path, query, header, formData, body)
  let scheme = call_611335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611335.url(scheme.get, call_611335.host, call_611335.base,
                         call_611335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611335, url, valid)

proc call*(call_611336: Call_CreateDataflowEndpointGroup_611324; body: JsonNode): Recallable =
  ## createDataflowEndpointGroup
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p> <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> to specify which endpoints to use during a contact.</p> <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> must match a <code>DataflowEndpoint</code> in the same group.</p>
  ##   body: JObject (required)
  var body_611337 = newJObject()
  if body != nil:
    body_611337 = body
  result = call_611336.call(nil, nil, nil, nil, body_611337)

var createDataflowEndpointGroup* = Call_CreateDataflowEndpointGroup_611324(
    name: "createDataflowEndpointGroup", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_CreateDataflowEndpointGroup_611325, base: "/",
    url: url_CreateDataflowEndpointGroup_611326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataflowEndpointGroups_611309 = ref object of OpenApiRestCall_610658
proc url_ListDataflowEndpointGroups_611311(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDataflowEndpointGroups_611310(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Next token returned in the request of a previous <code>ListDataflowEndpointGroups</code> call. Used to get the next page of results.
  ##   maxResults: JInt
  ##             : Maximum number of dataflow endpoint groups returned.
  section = newJObject()
  var valid_611312 = query.getOrDefault("nextToken")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "nextToken", valid_611312
  var valid_611313 = query.getOrDefault("maxResults")
  valid_611313 = validateParameter(valid_611313, JInt, required = false, default = nil)
  if valid_611313 != nil:
    section.add "maxResults", valid_611313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611321: Call_ListDataflowEndpointGroups_611309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ## 
  let valid = call_611321.validator(path, query, header, formData, body)
  let scheme = call_611321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611321.url(scheme.get, call_611321.host, call_611321.base,
                         call_611321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611321, url, valid)

proc call*(call_611322: Call_ListDataflowEndpointGroups_611309;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDataflowEndpointGroups
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListDataflowEndpointGroups</code> call. Used to get the next page of results.
  ##   maxResults: int
  ##             : Maximum number of dataflow endpoint groups returned.
  var query_611323 = newJObject()
  add(query_611323, "nextToken", newJString(nextToken))
  add(query_611323, "maxResults", newJInt(maxResults))
  result = call_611322.call(nil, query_611323, nil, nil, nil)

var listDataflowEndpointGroups* = Call_ListDataflowEndpointGroups_611309(
    name: "listDataflowEndpointGroups", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_ListDataflowEndpointGroups_611310, base: "/",
    url: url_ListDataflowEndpointGroups_611311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMissionProfile_611353 = ref object of OpenApiRestCall_610658
proc url_CreateMissionProfile_611355(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMissionProfile_611354(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a mission profile.</p> <p> <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings has two elements: a <i>from</i> ARN and a <i>to</i> ARN.</p>
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611356 = header.getOrDefault("X-Amz-Signature")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Signature", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Content-Sha256", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Date")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Date", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Credential")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Credential", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Security-Token")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Security-Token", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Algorithm")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Algorithm", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-SignedHeaders", valid_611362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611364: Call_CreateMissionProfile_611353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mission profile.</p> <p> <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings has two elements: a <i>from</i> ARN and a <i>to</i> ARN.</p>
  ## 
  let valid = call_611364.validator(path, query, header, formData, body)
  let scheme = call_611364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611364.url(scheme.get, call_611364.host, call_611364.base,
                         call_611364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611364, url, valid)

proc call*(call_611365: Call_CreateMissionProfile_611353; body: JsonNode): Recallable =
  ## createMissionProfile
  ## <p>Creates a mission profile.</p> <p> <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings has two elements: a <i>from</i> ARN and a <i>to</i> ARN.</p>
  ##   body: JObject (required)
  var body_611366 = newJObject()
  if body != nil:
    body_611366 = body
  result = call_611365.call(nil, nil, nil, nil, body_611366)

var createMissionProfile* = Call_CreateMissionProfile_611353(
    name: "createMissionProfile", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_CreateMissionProfile_611354, base: "/",
    url: url_CreateMissionProfile_611355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMissionProfiles_611338 = ref object of OpenApiRestCall_610658
proc url_ListMissionProfiles_611340(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMissionProfiles_611339(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of mission profiles.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Next token returned in the request of a previous <code>ListMissionProfiles</code> call. Used to get the next page of results.
  ##   maxResults: JInt
  ##             : Maximum number of mission profiles returned.
  section = newJObject()
  var valid_611341 = query.getOrDefault("nextToken")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "nextToken", valid_611341
  var valid_611342 = query.getOrDefault("maxResults")
  valid_611342 = validateParameter(valid_611342, JInt, required = false, default = nil)
  if valid_611342 != nil:
    section.add "maxResults", valid_611342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611343 = header.getOrDefault("X-Amz-Signature")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Signature", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Content-Sha256", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Date")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Date", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Credential")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Credential", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Security-Token")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Security-Token", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Algorithm")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Algorithm", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-SignedHeaders", valid_611349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611350: Call_ListMissionProfiles_611338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of mission profiles.
  ## 
  let valid = call_611350.validator(path, query, header, formData, body)
  let scheme = call_611350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611350.url(scheme.get, call_611350.host, call_611350.base,
                         call_611350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611350, url, valid)

proc call*(call_611351: Call_ListMissionProfiles_611338; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listMissionProfiles
  ## Returns a list of mission profiles.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListMissionProfiles</code> call. Used to get the next page of results.
  ##   maxResults: int
  ##             : Maximum number of mission profiles returned.
  var query_611352 = newJObject()
  add(query_611352, "nextToken", newJString(nextToken))
  add(query_611352, "maxResults", newJInt(maxResults))
  result = call_611351.call(nil, query_611352, nil, nil, nil)

var listMissionProfiles* = Call_ListMissionProfiles_611338(
    name: "listMissionProfiles", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_ListMissionProfiles_611339, base: "/",
    url: url_ListMissionProfiles_611340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfig_611395 = ref object of OpenApiRestCall_610658
proc url_UpdateConfig_611397(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configType" in path, "`configType` is a required path parameter"
  assert "configId" in path, "`configId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/config/"),
               (kind: VariableSegment, value: "configType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "configId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfig_611396(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p> <p>Updating a <code>Config</code> will not update the execution parameters for existing future contacts scheduled with this <code>Config</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configId: JString (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: JString (required)
  ##             : Type of a <code>Config</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `configId` field"
  var valid_611398 = path.getOrDefault("configId")
  valid_611398 = validateParameter(valid_611398, JString, required = true,
                                 default = nil)
  if valid_611398 != nil:
    section.add "configId", valid_611398
  var valid_611399 = path.getOrDefault("configType")
  valid_611399 = validateParameter(valid_611399, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_611399 != nil:
    section.add "configType", valid_611399
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611400 = header.getOrDefault("X-Amz-Signature")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Signature", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Content-Sha256", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Date")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Date", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-Credential")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Credential", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Security-Token")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Security-Token", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Algorithm")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Algorithm", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-SignedHeaders", valid_611406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611408: Call_UpdateConfig_611395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p> <p>Updating a <code>Config</code> will not update the execution parameters for existing future contacts scheduled with this <code>Config</code>.</p>
  ## 
  let valid = call_611408.validator(path, query, header, formData, body)
  let scheme = call_611408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611408.url(scheme.get, call_611408.host, call_611408.base,
                         call_611408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611408, url, valid)

proc call*(call_611409: Call_UpdateConfig_611395; configId: string; body: JsonNode;
          configType: string = "antenna-downlink"): Recallable =
  ## updateConfig
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p> <p>Updating a <code>Config</code> will not update the execution parameters for existing future contacts scheduled with this <code>Config</code>.</p>
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   body: JObject (required)
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_611410 = newJObject()
  var body_611411 = newJObject()
  add(path_611410, "configId", newJString(configId))
  if body != nil:
    body_611411 = body
  add(path_611410, "configType", newJString(configType))
  result = call_611409.call(path_611410, nil, nil, nil, body_611411)

var updateConfig* = Call_UpdateConfig_611395(name: "updateConfig",
    meth: HttpMethod.HttpPut, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_UpdateConfig_611396,
    base: "/", url: url_UpdateConfig_611397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfig_611367 = ref object of OpenApiRestCall_610658
proc url_GetConfig_611369(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configType" in path, "`configType` is a required path parameter"
  assert "configId" in path, "`configId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/config/"),
               (kind: VariableSegment, value: "configType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "configId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfig_611368(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns <code>Config</code> information.</p> <p>Only one <code>Config</code> response can be returned.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configId: JString (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: JString (required)
  ##             : Type of a <code>Config</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `configId` field"
  var valid_611370 = path.getOrDefault("configId")
  valid_611370 = validateParameter(valid_611370, JString, required = true,
                                 default = nil)
  if valid_611370 != nil:
    section.add "configId", valid_611370
  var valid_611384 = path.getOrDefault("configType")
  valid_611384 = validateParameter(valid_611384, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_611384 != nil:
    section.add "configType", valid_611384
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611385 = header.getOrDefault("X-Amz-Signature")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Signature", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Content-Sha256", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Date")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Date", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Credential")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Credential", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Security-Token")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Security-Token", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Algorithm")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Algorithm", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-SignedHeaders", valid_611391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611392: Call_GetConfig_611367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns <code>Config</code> information.</p> <p>Only one <code>Config</code> response can be returned.</p>
  ## 
  let valid = call_611392.validator(path, query, header, formData, body)
  let scheme = call_611392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611392.url(scheme.get, call_611392.host, call_611392.base,
                         call_611392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611392, url, valid)

proc call*(call_611393: Call_GetConfig_611367; configId: string;
          configType: string = "antenna-downlink"): Recallable =
  ## getConfig
  ## <p>Returns <code>Config</code> information.</p> <p>Only one <code>Config</code> response can be returned.</p>
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_611394 = newJObject()
  add(path_611394, "configId", newJString(configId))
  add(path_611394, "configType", newJString(configType))
  result = call_611393.call(path_611394, nil, nil, nil, nil)

var getConfig* = Call_GetConfig_611367(name: "getConfig", meth: HttpMethod.HttpGet,
                                    host: "groundstation.amazonaws.com",
                                    route: "/config/{configType}/{configId}",
                                    validator: validate_GetConfig_611368,
                                    base: "/", url: url_GetConfig_611369,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfig_611412 = ref object of OpenApiRestCall_610658
proc url_DeleteConfig_611414(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configType" in path, "`configType` is a required path parameter"
  assert "configId" in path, "`configId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/config/"),
               (kind: VariableSegment, value: "configType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "configId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfig_611413(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a <code>Config</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configId: JString (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: JString (required)
  ##             : Type of a <code>Config</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `configId` field"
  var valid_611415 = path.getOrDefault("configId")
  valid_611415 = validateParameter(valid_611415, JString, required = true,
                                 default = nil)
  if valid_611415 != nil:
    section.add "configId", valid_611415
  var valid_611416 = path.getOrDefault("configType")
  valid_611416 = validateParameter(valid_611416, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_611416 != nil:
    section.add "configType", valid_611416
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611417 = header.getOrDefault("X-Amz-Signature")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Signature", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Content-Sha256", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Date")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Date", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Credential")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Credential", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Security-Token")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Security-Token", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Algorithm")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Algorithm", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-SignedHeaders", valid_611423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611424: Call_DeleteConfig_611412; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Config</code>.
  ## 
  let valid = call_611424.validator(path, query, header, formData, body)
  let scheme = call_611424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611424.url(scheme.get, call_611424.host, call_611424.base,
                         call_611424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611424, url, valid)

proc call*(call_611425: Call_DeleteConfig_611412; configId: string;
          configType: string = "antenna-downlink"): Recallable =
  ## deleteConfig
  ## Deletes a <code>Config</code>.
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_611426 = newJObject()
  add(path_611426, "configId", newJString(configId))
  add(path_611426, "configType", newJString(configType))
  result = call_611425.call(path_611426, nil, nil, nil, nil)

var deleteConfig* = Call_DeleteConfig_611412(name: "deleteConfig",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_DeleteConfig_611413,
    base: "/", url: url_DeleteConfig_611414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowEndpointGroup_611427 = ref object of OpenApiRestCall_610658
proc url_GetDataflowEndpointGroup_611429(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "dataflowEndpointGroupId" in path,
        "`dataflowEndpointGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/dataflowEndpointGroup/"),
               (kind: VariableSegment, value: "dataflowEndpointGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataflowEndpointGroup_611428(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the dataflow endpoint group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   dataflowEndpointGroupId: JString (required)
  ##                          : UUID of a dataflow endpoint group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `dataflowEndpointGroupId` field"
  var valid_611430 = path.getOrDefault("dataflowEndpointGroupId")
  valid_611430 = validateParameter(valid_611430, JString, required = true,
                                 default = nil)
  if valid_611430 != nil:
    section.add "dataflowEndpointGroupId", valid_611430
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611431 = header.getOrDefault("X-Amz-Signature")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Signature", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Content-Sha256", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Date")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Date", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Credential")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Credential", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Security-Token")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Security-Token", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Algorithm")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Algorithm", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-SignedHeaders", valid_611437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611438: Call_GetDataflowEndpointGroup_611427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the dataflow endpoint group.
  ## 
  let valid = call_611438.validator(path, query, header, formData, body)
  let scheme = call_611438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611438.url(scheme.get, call_611438.host, call_611438.base,
                         call_611438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611438, url, valid)

proc call*(call_611439: Call_GetDataflowEndpointGroup_611427;
          dataflowEndpointGroupId: string): Recallable =
  ## getDataflowEndpointGroup
  ## Returns the dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
  ##                          : UUID of a dataflow endpoint group.
  var path_611440 = newJObject()
  add(path_611440, "dataflowEndpointGroupId", newJString(dataflowEndpointGroupId))
  result = call_611439.call(path_611440, nil, nil, nil, nil)

var getDataflowEndpointGroup* = Call_GetDataflowEndpointGroup_611427(
    name: "getDataflowEndpointGroup", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_GetDataflowEndpointGroup_611428, base: "/",
    url: url_GetDataflowEndpointGroup_611429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataflowEndpointGroup_611441 = ref object of OpenApiRestCall_610658
proc url_DeleteDataflowEndpointGroup_611443(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "dataflowEndpointGroupId" in path,
        "`dataflowEndpointGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/dataflowEndpointGroup/"),
               (kind: VariableSegment, value: "dataflowEndpointGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataflowEndpointGroup_611442(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a dataflow endpoint group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   dataflowEndpointGroupId: JString (required)
  ##                          : UUID of a dataflow endpoint group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `dataflowEndpointGroupId` field"
  var valid_611444 = path.getOrDefault("dataflowEndpointGroupId")
  valid_611444 = validateParameter(valid_611444, JString, required = true,
                                 default = nil)
  if valid_611444 != nil:
    section.add "dataflowEndpointGroupId", valid_611444
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611445 = header.getOrDefault("X-Amz-Signature")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Signature", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Content-Sha256", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Date")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Date", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Credential")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Credential", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Security-Token")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Security-Token", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Algorithm")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Algorithm", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-SignedHeaders", valid_611451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611452: Call_DeleteDataflowEndpointGroup_611441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataflow endpoint group.
  ## 
  let valid = call_611452.validator(path, query, header, formData, body)
  let scheme = call_611452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611452.url(scheme.get, call_611452.host, call_611452.base,
                         call_611452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611452, url, valid)

proc call*(call_611453: Call_DeleteDataflowEndpointGroup_611441;
          dataflowEndpointGroupId: string): Recallable =
  ## deleteDataflowEndpointGroup
  ## Deletes a dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
  ##                          : UUID of a dataflow endpoint group.
  var path_611454 = newJObject()
  add(path_611454, "dataflowEndpointGroupId", newJString(dataflowEndpointGroupId))
  result = call_611453.call(path_611454, nil, nil, nil, nil)

var deleteDataflowEndpointGroup* = Call_DeleteDataflowEndpointGroup_611441(
    name: "deleteDataflowEndpointGroup", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_DeleteDataflowEndpointGroup_611442, base: "/",
    url: url_DeleteDataflowEndpointGroup_611443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMissionProfile_611469 = ref object of OpenApiRestCall_610658
proc url_UpdateMissionProfile_611471(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "missionProfileId" in path,
        "`missionProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/missionprofile/"),
               (kind: VariableSegment, value: "missionProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMissionProfile_611470(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates a mission profile.</p> <p>Updating a mission profile will not update the execution parameters for existing future contacts.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   missionProfileId: JString (required)
  ##                   : UUID of a mission profile.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `missionProfileId` field"
  var valid_611472 = path.getOrDefault("missionProfileId")
  valid_611472 = validateParameter(valid_611472, JString, required = true,
                                 default = nil)
  if valid_611472 != nil:
    section.add "missionProfileId", valid_611472
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611473 = header.getOrDefault("X-Amz-Signature")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Signature", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Content-Sha256", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-Date")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Date", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Credential")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Credential", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Security-Token")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Security-Token", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Algorithm")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Algorithm", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-SignedHeaders", valid_611479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611481: Call_UpdateMissionProfile_611469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a mission profile.</p> <p>Updating a mission profile will not update the execution parameters for existing future contacts.</p>
  ## 
  let valid = call_611481.validator(path, query, header, formData, body)
  let scheme = call_611481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611481.url(scheme.get, call_611481.host, call_611481.base,
                         call_611481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611481, url, valid)

proc call*(call_611482: Call_UpdateMissionProfile_611469; missionProfileId: string;
          body: JsonNode): Recallable =
  ## updateMissionProfile
  ## <p>Updates a mission profile.</p> <p>Updating a mission profile will not update the execution parameters for existing future contacts.</p>
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  ##   body: JObject (required)
  var path_611483 = newJObject()
  var body_611484 = newJObject()
  add(path_611483, "missionProfileId", newJString(missionProfileId))
  if body != nil:
    body_611484 = body
  result = call_611482.call(path_611483, nil, nil, nil, body_611484)

var updateMissionProfile* = Call_UpdateMissionProfile_611469(
    name: "updateMissionProfile", meth: HttpMethod.HttpPut,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_UpdateMissionProfile_611470, base: "/",
    url: url_UpdateMissionProfile_611471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMissionProfile_611455 = ref object of OpenApiRestCall_610658
proc url_GetMissionProfile_611457(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "missionProfileId" in path,
        "`missionProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/missionprofile/"),
               (kind: VariableSegment, value: "missionProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMissionProfile_611456(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns a mission profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   missionProfileId: JString (required)
  ##                   : UUID of a mission profile.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `missionProfileId` field"
  var valid_611458 = path.getOrDefault("missionProfileId")
  valid_611458 = validateParameter(valid_611458, JString, required = true,
                                 default = nil)
  if valid_611458 != nil:
    section.add "missionProfileId", valid_611458
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
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
  var valid_611461 = header.getOrDefault("X-Amz-Date")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Date", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Credential")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Credential", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Security-Token")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Security-Token", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Algorithm")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Algorithm", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-SignedHeaders", valid_611465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611466: Call_GetMissionProfile_611455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a mission profile.
  ## 
  let valid = call_611466.validator(path, query, header, formData, body)
  let scheme = call_611466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611466.url(scheme.get, call_611466.host, call_611466.base,
                         call_611466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611466, url, valid)

proc call*(call_611467: Call_GetMissionProfile_611455; missionProfileId: string): Recallable =
  ## getMissionProfile
  ## Returns a mission profile.
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  var path_611468 = newJObject()
  add(path_611468, "missionProfileId", newJString(missionProfileId))
  result = call_611467.call(path_611468, nil, nil, nil, nil)

var getMissionProfile* = Call_GetMissionProfile_611455(name: "getMissionProfile",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_GetMissionProfile_611456, base: "/",
    url: url_GetMissionProfile_611457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMissionProfile_611485 = ref object of OpenApiRestCall_610658
proc url_DeleteMissionProfile_611487(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "missionProfileId" in path,
        "`missionProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/missionprofile/"),
               (kind: VariableSegment, value: "missionProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMissionProfile_611486(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a mission profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   missionProfileId: JString (required)
  ##                   : UUID of a mission profile.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `missionProfileId` field"
  var valid_611488 = path.getOrDefault("missionProfileId")
  valid_611488 = validateParameter(valid_611488, JString, required = true,
                                 default = nil)
  if valid_611488 != nil:
    section.add "missionProfileId", valid_611488
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611489 = header.getOrDefault("X-Amz-Signature")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Signature", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Content-Sha256", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-Date")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Date", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-Credential")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Credential", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-Security-Token")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-Security-Token", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Algorithm")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Algorithm", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-SignedHeaders", valid_611495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611496: Call_DeleteMissionProfile_611485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a mission profile.
  ## 
  let valid = call_611496.validator(path, query, header, formData, body)
  let scheme = call_611496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611496.url(scheme.get, call_611496.host, call_611496.base,
                         call_611496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611496, url, valid)

proc call*(call_611497: Call_DeleteMissionProfile_611485; missionProfileId: string): Recallable =
  ## deleteMissionProfile
  ## Deletes a mission profile.
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  var path_611498 = newJObject()
  add(path_611498, "missionProfileId", newJString(missionProfileId))
  result = call_611497.call(path_611498, nil, nil, nil, nil)

var deleteMissionProfile* = Call_DeleteMissionProfile_611485(
    name: "deleteMissionProfile", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_DeleteMissionProfile_611486, base: "/",
    url: url_DeleteMissionProfile_611487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMinuteUsage_611499 = ref object of OpenApiRestCall_610658
proc url_GetMinuteUsage_611501(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMinuteUsage_611500(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns the number of minutes used by account.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611502 = header.getOrDefault("X-Amz-Signature")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Signature", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Content-Sha256", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Date")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Date", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Credential")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Credential", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Security-Token")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Security-Token", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Algorithm")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Algorithm", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-SignedHeaders", valid_611508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611510: Call_GetMinuteUsage_611499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of minutes used by account.
  ## 
  let valid = call_611510.validator(path, query, header, formData, body)
  let scheme = call_611510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611510.url(scheme.get, call_611510.host, call_611510.base,
                         call_611510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611510, url, valid)

proc call*(call_611511: Call_GetMinuteUsage_611499; body: JsonNode): Recallable =
  ## getMinuteUsage
  ## Returns the number of minutes used by account.
  ##   body: JObject (required)
  var body_611512 = newJObject()
  if body != nil:
    body_611512 = body
  result = call_611511.call(nil, nil, nil, nil, body_611512)

var getMinuteUsage* = Call_GetMinuteUsage_611499(name: "getMinuteUsage",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/minute-usage", validator: validate_GetMinuteUsage_611500, base: "/",
    url: url_GetMinuteUsage_611501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSatellite_611513 = ref object of OpenApiRestCall_610658
proc url_GetSatellite_611515(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "satelliteId" in path, "`satelliteId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/satellite/"),
               (kind: VariableSegment, value: "satelliteId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSatellite_611514(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a satellite.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   satelliteId: JString (required)
  ##              : UUID of a satellite.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `satelliteId` field"
  var valid_611516 = path.getOrDefault("satelliteId")
  valid_611516 = validateParameter(valid_611516, JString, required = true,
                                 default = nil)
  if valid_611516 != nil:
    section.add "satelliteId", valid_611516
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611517 = header.getOrDefault("X-Amz-Signature")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Signature", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Content-Sha256", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Date")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Date", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Credential")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Credential", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Security-Token")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Security-Token", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Algorithm")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Algorithm", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-SignedHeaders", valid_611523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611524: Call_GetSatellite_611513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a satellite.
  ## 
  let valid = call_611524.validator(path, query, header, formData, body)
  let scheme = call_611524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611524.url(scheme.get, call_611524.host, call_611524.base,
                         call_611524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611524, url, valid)

proc call*(call_611525: Call_GetSatellite_611513; satelliteId: string): Recallable =
  ## getSatellite
  ## Returns a satellite.
  ##   satelliteId: string (required)
  ##              : UUID of a satellite.
  var path_611526 = newJObject()
  add(path_611526, "satelliteId", newJString(satelliteId))
  result = call_611525.call(path_611526, nil, nil, nil, nil)

var getSatellite* = Call_GetSatellite_611513(name: "getSatellite",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite/{satelliteId}", validator: validate_GetSatellite_611514,
    base: "/", url: url_GetSatellite_611515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContacts_611527 = ref object of OpenApiRestCall_610658
proc url_ListContacts_611529(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListContacts_611528(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of contacts.</p> <p>If <code>statusList</code> contains AVAILABLE, the request must include <code>groundStation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_611530 = query.getOrDefault("nextToken")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "nextToken", valid_611530
  var valid_611531 = query.getOrDefault("maxResults")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "maxResults", valid_611531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611532 = header.getOrDefault("X-Amz-Signature")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Signature", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Content-Sha256", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Date")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Date", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Credential")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Credential", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Security-Token")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Security-Token", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Algorithm")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Algorithm", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-SignedHeaders", valid_611538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611540: Call_ListContacts_611527; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of contacts.</p> <p>If <code>statusList</code> contains AVAILABLE, the request must include <code>groundStation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>. </p>
  ## 
  let valid = call_611540.validator(path, query, header, formData, body)
  let scheme = call_611540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611540.url(scheme.get, call_611540.host, call_611540.base,
                         call_611540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611540, url, valid)

proc call*(call_611541: Call_ListContacts_611527; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listContacts
  ## <p>Returns a list of contacts.</p> <p>If <code>statusList</code> contains AVAILABLE, the request must include <code>groundStation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611542 = newJObject()
  var body_611543 = newJObject()
  add(query_611542, "nextToken", newJString(nextToken))
  if body != nil:
    body_611543 = body
  add(query_611542, "maxResults", newJString(maxResults))
  result = call_611541.call(nil, query_611542, nil, nil, body_611543)

var listContacts* = Call_ListContacts_611527(name: "listContacts",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contacts", validator: validate_ListContacts_611528, base: "/",
    url: url_ListContacts_611529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroundStations_611544 = ref object of OpenApiRestCall_610658
proc url_ListGroundStations_611546(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroundStations_611545(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of ground stations. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Next token that can be supplied in the next call to get the next page of ground stations.
  ##   satelliteId: JString
  ##              : Satellite ID to retrieve on-boarded ground stations.
  ##   maxResults: JInt
  ##             : Maximum number of ground stations returned.
  section = newJObject()
  var valid_611547 = query.getOrDefault("nextToken")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "nextToken", valid_611547
  var valid_611548 = query.getOrDefault("satelliteId")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "satelliteId", valid_611548
  var valid_611549 = query.getOrDefault("maxResults")
  valid_611549 = validateParameter(valid_611549, JInt, required = false, default = nil)
  if valid_611549 != nil:
    section.add "maxResults", valid_611549
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611550 = header.getOrDefault("X-Amz-Signature")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Signature", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Content-Sha256", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Date")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Date", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Credential")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Credential", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Security-Token")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Security-Token", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Algorithm")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Algorithm", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-SignedHeaders", valid_611556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611557: Call_ListGroundStations_611544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of ground stations. 
  ## 
  let valid = call_611557.validator(path, query, header, formData, body)
  let scheme = call_611557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611557.url(scheme.get, call_611557.host, call_611557.base,
                         call_611557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611557, url, valid)

proc call*(call_611558: Call_ListGroundStations_611544; nextToken: string = "";
          satelliteId: string = ""; maxResults: int = 0): Recallable =
  ## listGroundStations
  ## Returns a list of ground stations. 
  ##   nextToken: string
  ##            : Next token that can be supplied in the next call to get the next page of ground stations.
  ##   satelliteId: string
  ##              : Satellite ID to retrieve on-boarded ground stations.
  ##   maxResults: int
  ##             : Maximum number of ground stations returned.
  var query_611559 = newJObject()
  add(query_611559, "nextToken", newJString(nextToken))
  add(query_611559, "satelliteId", newJString(satelliteId))
  add(query_611559, "maxResults", newJInt(maxResults))
  result = call_611558.call(nil, query_611559, nil, nil, nil)

var listGroundStations* = Call_ListGroundStations_611544(
    name: "listGroundStations", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/groundstation",
    validator: validate_ListGroundStations_611545, base: "/",
    url: url_ListGroundStations_611546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSatellites_611560 = ref object of OpenApiRestCall_610658
proc url_ListSatellites_611562(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSatellites_611561(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns a list of satellites.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Next token that can be supplied in the next call to get the next page of satellites.
  ##   maxResults: JInt
  ##             : Maximum number of satellites returned.
  section = newJObject()
  var valid_611563 = query.getOrDefault("nextToken")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "nextToken", valid_611563
  var valid_611564 = query.getOrDefault("maxResults")
  valid_611564 = validateParameter(valid_611564, JInt, required = false, default = nil)
  if valid_611564 != nil:
    section.add "maxResults", valid_611564
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611565 = header.getOrDefault("X-Amz-Signature")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Signature", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Content-Sha256", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Date")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Date", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Credential")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Credential", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Security-Token")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Security-Token", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Algorithm")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Algorithm", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-SignedHeaders", valid_611571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611572: Call_ListSatellites_611560; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of satellites.
  ## 
  let valid = call_611572.validator(path, query, header, formData, body)
  let scheme = call_611572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611572.url(scheme.get, call_611572.host, call_611572.base,
                         call_611572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611572, url, valid)

proc call*(call_611573: Call_ListSatellites_611560; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listSatellites
  ## Returns a list of satellites.
  ##   nextToken: string
  ##            : Next token that can be supplied in the next call to get the next page of satellites.
  ##   maxResults: int
  ##             : Maximum number of satellites returned.
  var query_611574 = newJObject()
  add(query_611574, "nextToken", newJString(nextToken))
  add(query_611574, "maxResults", newJInt(maxResults))
  result = call_611573.call(nil, query_611574, nil, nil, nil)

var listSatellites* = Call_ListSatellites_611560(name: "listSatellites",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite", validator: validate_ListSatellites_611561, base: "/",
    url: url_ListSatellites_611562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611589 = ref object of OpenApiRestCall_610658
proc url_TagResource_611591(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_611590(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Assigns a tag to a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : ARN of a resource tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611592 = path.getOrDefault("resourceArn")
  valid_611592 = validateParameter(valid_611592, JString, required = true,
                                 default = nil)
  if valid_611592 != nil:
    section.add "resourceArn", valid_611592
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611593 = header.getOrDefault("X-Amz-Signature")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Signature", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Content-Sha256", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Date")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Date", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-Credential")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Credential", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-Security-Token")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-Security-Token", valid_611597
  var valid_611598 = header.getOrDefault("X-Amz-Algorithm")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "X-Amz-Algorithm", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-SignedHeaders", valid_611599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611601: Call_TagResource_611589; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns a tag to a resource.
  ## 
  let valid = call_611601.validator(path, query, header, formData, body)
  let scheme = call_611601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611601.url(scheme.get, call_611601.host, call_611601.base,
                         call_611601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611601, url, valid)

proc call*(call_611602: Call_TagResource_611589; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Assigns a tag to a resource.
  ##   resourceArn: string (required)
  ##              : ARN of a resource tag.
  ##   body: JObject (required)
  var path_611603 = newJObject()
  var body_611604 = newJObject()
  add(path_611603, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_611604 = body
  result = call_611602.call(path_611603, nil, nil, nil, body_611604)

var tagResource* = Call_TagResource_611589(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "groundstation.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_611590,
                                        base: "/", url: url_TagResource_611591,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611575 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611577(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_611576(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of tags for a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : ARN of a resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611578 = path.getOrDefault("resourceArn")
  valid_611578 = validateParameter(valid_611578, JString, required = true,
                                 default = nil)
  if valid_611578 != nil:
    section.add "resourceArn", valid_611578
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611579 = header.getOrDefault("X-Amz-Signature")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Signature", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Content-Sha256", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Date")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Date", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Credential")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Credential", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Security-Token")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Security-Token", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Algorithm")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Algorithm", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-SignedHeaders", valid_611585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611586: Call_ListTagsForResource_611575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags for a specified resource.
  ## 
  let valid = call_611586.validator(path, query, header, formData, body)
  let scheme = call_611586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611586.url(scheme.get, call_611586.host, call_611586.base,
                         call_611586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611586, url, valid)

proc call*(call_611587: Call_ListTagsForResource_611575; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags for a specified resource.
  ##   resourceArn: string (required)
  ##              : ARN of a resource.
  var path_611588 = newJObject()
  add(path_611588, "resourceArn", newJString(resourceArn))
  result = call_611587.call(path_611588, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611575(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_611576, base: "/",
    url: url_ListTagsForResource_611577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReserveContact_611605 = ref object of OpenApiRestCall_610658
proc url_ReserveContact_611607(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ReserveContact_611606(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Reserves a contact using specified parameters.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611608 = header.getOrDefault("X-Amz-Signature")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Signature", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-Content-Sha256", valid_611609
  var valid_611610 = header.getOrDefault("X-Amz-Date")
  valid_611610 = validateParameter(valid_611610, JString, required = false,
                                 default = nil)
  if valid_611610 != nil:
    section.add "X-Amz-Date", valid_611610
  var valid_611611 = header.getOrDefault("X-Amz-Credential")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-Credential", valid_611611
  var valid_611612 = header.getOrDefault("X-Amz-Security-Token")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-Security-Token", valid_611612
  var valid_611613 = header.getOrDefault("X-Amz-Algorithm")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Algorithm", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-SignedHeaders", valid_611614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611616: Call_ReserveContact_611605; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reserves a contact using specified parameters.
  ## 
  let valid = call_611616.validator(path, query, header, formData, body)
  let scheme = call_611616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611616.url(scheme.get, call_611616.host, call_611616.base,
                         call_611616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611616, url, valid)

proc call*(call_611617: Call_ReserveContact_611605; body: JsonNode): Recallable =
  ## reserveContact
  ## Reserves a contact using specified parameters.
  ##   body: JObject (required)
  var body_611618 = newJObject()
  if body != nil:
    body_611618 = body
  result = call_611617.call(nil, nil, nil, nil, body_611618)

var reserveContact* = Call_ReserveContact_611605(name: "reserveContact",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contact", validator: validate_ReserveContact_611606, base: "/",
    url: url_ReserveContact_611607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611619 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611621(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_611620(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deassigns a resource tag.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : ARN of a resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611622 = path.getOrDefault("resourceArn")
  valid_611622 = validateParameter(valid_611622, JString, required = true,
                                 default = nil)
  if valid_611622 != nil:
    section.add "resourceArn", valid_611622
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Keys of a resource tag.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611623 = query.getOrDefault("tagKeys")
  valid_611623 = validateParameter(valid_611623, JArray, required = true, default = nil)
  if valid_611623 != nil:
    section.add "tagKeys", valid_611623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611624 = header.getOrDefault("X-Amz-Signature")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Signature", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Content-Sha256", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-Date")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Date", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-Credential")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Credential", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-Security-Token")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-Security-Token", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Algorithm")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Algorithm", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-SignedHeaders", valid_611630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611631: Call_UntagResource_611619; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deassigns a resource tag.
  ## 
  let valid = call_611631.validator(path, query, header, formData, body)
  let scheme = call_611631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611631.url(scheme.get, call_611631.host, call_611631.base,
                         call_611631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611631, url, valid)

proc call*(call_611632: Call_UntagResource_611619; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deassigns a resource tag.
  ##   resourceArn: string (required)
  ##              : ARN of a resource.
  ##   tagKeys: JArray (required)
  ##          : Keys of a resource tag.
  var path_611633 = newJObject()
  var query_611634 = newJObject()
  add(path_611633, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_611634.add "tagKeys", tagKeys
  result = call_611632.call(path_611633, query_611634, nil, nil, nil)

var untagResource* = Call_UntagResource_611619(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_611620,
    base: "/", url: url_UntagResource_611621, schemes: {Scheme.Https, Scheme.Http})
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
