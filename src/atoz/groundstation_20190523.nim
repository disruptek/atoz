
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_DescribeContact_612996 = ref object of OpenApiRestCall_612658
proc url_DescribeContact_612998(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeContact_612997(path: JsonNode; query: JsonNode;
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
  var valid_613124 = path.getOrDefault("contactId")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "contactId", valid_613124
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
  var valid_613125 = header.getOrDefault("X-Amz-Signature")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Signature", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Content-Sha256", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Date")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Date", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Credential")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Credential", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Security-Token")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Security-Token", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Algorithm")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Algorithm", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-SignedHeaders", valid_613131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_DescribeContact_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing contact.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_DescribeContact_612996; contactId: string): Recallable =
  ## describeContact
  ## Describes an existing contact.
  ##   contactId: string (required)
  ##            : UUID of a contact.
  var path_613226 = newJObject()
  add(path_613226, "contactId", newJString(contactId))
  result = call_613225.call(path_613226, nil, nil, nil, nil)

var describeContact* = Call_DescribeContact_612996(name: "describeContact",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_DescribeContact_612997,
    base: "/", url: url_DescribeContact_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelContact_613266 = ref object of OpenApiRestCall_612658
proc url_CancelContact_613268(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelContact_613267(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613269 = path.getOrDefault("contactId")
  valid_613269 = validateParameter(valid_613269, JString, required = true,
                                 default = nil)
  if valid_613269 != nil:
    section.add "contactId", valid_613269
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
  var valid_613270 = header.getOrDefault("X-Amz-Signature")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Signature", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Content-Sha256", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Date")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Date", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Credential")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Credential", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Security-Token")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Security-Token", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Algorithm")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Algorithm", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-SignedHeaders", valid_613276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_CancelContact_613266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a contact with a specified contact ID.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_CancelContact_613266; contactId: string): Recallable =
  ## cancelContact
  ## Cancels a contact with a specified contact ID.
  ##   contactId: string (required)
  ##            : UUID of a contact.
  var path_613279 = newJObject()
  add(path_613279, "contactId", newJString(contactId))
  result = call_613278.call(path_613279, nil, nil, nil, nil)

var cancelContact* = Call_CancelContact_613266(name: "cancelContact",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_CancelContact_613267,
    base: "/", url: url_CancelContact_613268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfig_613295 = ref object of OpenApiRestCall_612658
proc url_CreateConfig_613297(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConfig_613296(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613298 = header.getOrDefault("X-Amz-Signature")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Signature", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Content-Sha256", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Date")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Date", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Credential")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Credential", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Security-Token")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Security-Token", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Algorithm")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Algorithm", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-SignedHeaders", valid_613304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613306: Call_CreateConfig_613295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p> <p>Only one type of <code>configData</code> can be specified.</p>
  ## 
  let valid = call_613306.validator(path, query, header, formData, body)
  let scheme = call_613306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613306.url(scheme.get, call_613306.host, call_613306.base,
                         call_613306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613306, url, valid)

proc call*(call_613307: Call_CreateConfig_613295; body: JsonNode): Recallable =
  ## createConfig
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p> <p>Only one type of <code>configData</code> can be specified.</p>
  ##   body: JObject (required)
  var body_613308 = newJObject()
  if body != nil:
    body_613308 = body
  result = call_613307.call(nil, nil, nil, nil, body_613308)

var createConfig* = Call_CreateConfig_613295(name: "createConfig",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/config", validator: validate_CreateConfig_613296, base: "/",
    url: url_CreateConfig_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigs_613280 = ref object of OpenApiRestCall_612658
proc url_ListConfigs_613282(protocol: Scheme; host: string; base: string;
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

proc validate_ListConfigs_613281(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613283 = query.getOrDefault("nextToken")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "nextToken", valid_613283
  var valid_613284 = query.getOrDefault("maxResults")
  valid_613284 = validateParameter(valid_613284, JInt, required = false, default = nil)
  if valid_613284 != nil:
    section.add "maxResults", valid_613284
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
  var valid_613285 = header.getOrDefault("X-Amz-Signature")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Signature", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Content-Sha256", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Date")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Date", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Credential")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Credential", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Security-Token")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Security-Token", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Algorithm")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Algorithm", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-SignedHeaders", valid_613291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_ListConfigs_613280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>Config</code> objects.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_ListConfigs_613280; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listConfigs
  ## Returns a list of <code>Config</code> objects.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListConfigs</code> call. Used to get the next page of results.
  ##   maxResults: int
  ##             : Maximum number of <code>Configs</code> returned.
  var query_613294 = newJObject()
  add(query_613294, "nextToken", newJString(nextToken))
  add(query_613294, "maxResults", newJInt(maxResults))
  result = call_613293.call(nil, query_613294, nil, nil, nil)

var listConfigs* = Call_ListConfigs_613280(name: "listConfigs",
                                        meth: HttpMethod.HttpGet,
                                        host: "groundstation.amazonaws.com",
                                        route: "/config",
                                        validator: validate_ListConfigs_613281,
                                        base: "/", url: url_ListConfigs_613282,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataflowEndpointGroup_613324 = ref object of OpenApiRestCall_612658
proc url_CreateDataflowEndpointGroup_613326(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataflowEndpointGroup_613325(path: JsonNode; query: JsonNode;
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
  var valid_613327 = header.getOrDefault("X-Amz-Signature")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Signature", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Content-Sha256", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Date")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Date", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Credential")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Credential", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Security-Token")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Security-Token", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Algorithm")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Algorithm", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-SignedHeaders", valid_613333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613335: Call_CreateDataflowEndpointGroup_613324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p> <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> to specify which endpoints to use during a contact.</p> <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> must match a <code>DataflowEndpoint</code> in the same group.</p>
  ## 
  let valid = call_613335.validator(path, query, header, formData, body)
  let scheme = call_613335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613335.url(scheme.get, call_613335.host, call_613335.base,
                         call_613335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613335, url, valid)

proc call*(call_613336: Call_CreateDataflowEndpointGroup_613324; body: JsonNode): Recallable =
  ## createDataflowEndpointGroup
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p> <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> to specify which endpoints to use during a contact.</p> <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> must match a <code>DataflowEndpoint</code> in the same group.</p>
  ##   body: JObject (required)
  var body_613337 = newJObject()
  if body != nil:
    body_613337 = body
  result = call_613336.call(nil, nil, nil, nil, body_613337)

var createDataflowEndpointGroup* = Call_CreateDataflowEndpointGroup_613324(
    name: "createDataflowEndpointGroup", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_CreateDataflowEndpointGroup_613325, base: "/",
    url: url_CreateDataflowEndpointGroup_613326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataflowEndpointGroups_613309 = ref object of OpenApiRestCall_612658
proc url_ListDataflowEndpointGroups_613311(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDataflowEndpointGroups_613310(path: JsonNode; query: JsonNode;
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
  var valid_613312 = query.getOrDefault("nextToken")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "nextToken", valid_613312
  var valid_613313 = query.getOrDefault("maxResults")
  valid_613313 = validateParameter(valid_613313, JInt, required = false, default = nil)
  if valid_613313 != nil:
    section.add "maxResults", valid_613313
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
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613321: Call_ListDataflowEndpointGroups_613309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ## 
  let valid = call_613321.validator(path, query, header, formData, body)
  let scheme = call_613321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613321.url(scheme.get, call_613321.host, call_613321.base,
                         call_613321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613321, url, valid)

proc call*(call_613322: Call_ListDataflowEndpointGroups_613309;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDataflowEndpointGroups
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListDataflowEndpointGroups</code> call. Used to get the next page of results.
  ##   maxResults: int
  ##             : Maximum number of dataflow endpoint groups returned.
  var query_613323 = newJObject()
  add(query_613323, "nextToken", newJString(nextToken))
  add(query_613323, "maxResults", newJInt(maxResults))
  result = call_613322.call(nil, query_613323, nil, nil, nil)

var listDataflowEndpointGroups* = Call_ListDataflowEndpointGroups_613309(
    name: "listDataflowEndpointGroups", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_ListDataflowEndpointGroups_613310, base: "/",
    url: url_ListDataflowEndpointGroups_613311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMissionProfile_613353 = ref object of OpenApiRestCall_612658
proc url_CreateMissionProfile_613355(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMissionProfile_613354(path: JsonNode; query: JsonNode;
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
  var valid_613356 = header.getOrDefault("X-Amz-Signature")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Signature", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Content-Sha256", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Date")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Date", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Credential")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Credential", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Security-Token")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Security-Token", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Algorithm")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Algorithm", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-SignedHeaders", valid_613362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613364: Call_CreateMissionProfile_613353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mission profile.</p> <p> <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings has two elements: a <i>from</i> ARN and a <i>to</i> ARN.</p>
  ## 
  let valid = call_613364.validator(path, query, header, formData, body)
  let scheme = call_613364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613364.url(scheme.get, call_613364.host, call_613364.base,
                         call_613364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613364, url, valid)

proc call*(call_613365: Call_CreateMissionProfile_613353; body: JsonNode): Recallable =
  ## createMissionProfile
  ## <p>Creates a mission profile.</p> <p> <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings has two elements: a <i>from</i> ARN and a <i>to</i> ARN.</p>
  ##   body: JObject (required)
  var body_613366 = newJObject()
  if body != nil:
    body_613366 = body
  result = call_613365.call(nil, nil, nil, nil, body_613366)

var createMissionProfile* = Call_CreateMissionProfile_613353(
    name: "createMissionProfile", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_CreateMissionProfile_613354, base: "/",
    url: url_CreateMissionProfile_613355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMissionProfiles_613338 = ref object of OpenApiRestCall_612658
proc url_ListMissionProfiles_613340(protocol: Scheme; host: string; base: string;
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

proc validate_ListMissionProfiles_613339(path: JsonNode; query: JsonNode;
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
  var valid_613341 = query.getOrDefault("nextToken")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "nextToken", valid_613341
  var valid_613342 = query.getOrDefault("maxResults")
  valid_613342 = validateParameter(valid_613342, JInt, required = false, default = nil)
  if valid_613342 != nil:
    section.add "maxResults", valid_613342
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
  var valid_613343 = header.getOrDefault("X-Amz-Signature")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Signature", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Content-Sha256", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Date")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Date", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Credential")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Credential", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Security-Token")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Security-Token", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Algorithm")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Algorithm", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-SignedHeaders", valid_613349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613350: Call_ListMissionProfiles_613338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of mission profiles.
  ## 
  let valid = call_613350.validator(path, query, header, formData, body)
  let scheme = call_613350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613350.url(scheme.get, call_613350.host, call_613350.base,
                         call_613350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613350, url, valid)

proc call*(call_613351: Call_ListMissionProfiles_613338; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listMissionProfiles
  ## Returns a list of mission profiles.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListMissionProfiles</code> call. Used to get the next page of results.
  ##   maxResults: int
  ##             : Maximum number of mission profiles returned.
  var query_613352 = newJObject()
  add(query_613352, "nextToken", newJString(nextToken))
  add(query_613352, "maxResults", newJInt(maxResults))
  result = call_613351.call(nil, query_613352, nil, nil, nil)

var listMissionProfiles* = Call_ListMissionProfiles_613338(
    name: "listMissionProfiles", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_ListMissionProfiles_613339, base: "/",
    url: url_ListMissionProfiles_613340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfig_613395 = ref object of OpenApiRestCall_612658
proc url_UpdateConfig_613397(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfig_613396(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613398 = path.getOrDefault("configId")
  valid_613398 = validateParameter(valid_613398, JString, required = true,
                                 default = nil)
  if valid_613398 != nil:
    section.add "configId", valid_613398
  var valid_613399 = path.getOrDefault("configType")
  valid_613399 = validateParameter(valid_613399, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_613399 != nil:
    section.add "configType", valid_613399
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
  var valid_613400 = header.getOrDefault("X-Amz-Signature")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Signature", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Content-Sha256", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Date")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Date", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Credential")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Credential", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Security-Token")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Security-Token", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Algorithm")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Algorithm", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-SignedHeaders", valid_613406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613408: Call_UpdateConfig_613395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p> <p>Updating a <code>Config</code> will not update the execution parameters for existing future contacts scheduled with this <code>Config</code>.</p>
  ## 
  let valid = call_613408.validator(path, query, header, formData, body)
  let scheme = call_613408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613408.url(scheme.get, call_613408.host, call_613408.base,
                         call_613408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613408, url, valid)

proc call*(call_613409: Call_UpdateConfig_613395; configId: string; body: JsonNode;
          configType: string = "antenna-downlink"): Recallable =
  ## updateConfig
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p> <p>Updating a <code>Config</code> will not update the execution parameters for existing future contacts scheduled with this <code>Config</code>.</p>
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   body: JObject (required)
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_613410 = newJObject()
  var body_613411 = newJObject()
  add(path_613410, "configId", newJString(configId))
  if body != nil:
    body_613411 = body
  add(path_613410, "configType", newJString(configType))
  result = call_613409.call(path_613410, nil, nil, nil, body_613411)

var updateConfig* = Call_UpdateConfig_613395(name: "updateConfig",
    meth: HttpMethod.HttpPut, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_UpdateConfig_613396,
    base: "/", url: url_UpdateConfig_613397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfig_613367 = ref object of OpenApiRestCall_612658
proc url_GetConfig_613369(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfig_613368(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613370 = path.getOrDefault("configId")
  valid_613370 = validateParameter(valid_613370, JString, required = true,
                                 default = nil)
  if valid_613370 != nil:
    section.add "configId", valid_613370
  var valid_613384 = path.getOrDefault("configType")
  valid_613384 = validateParameter(valid_613384, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_613384 != nil:
    section.add "configType", valid_613384
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
  var valid_613385 = header.getOrDefault("X-Amz-Signature")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Signature", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Content-Sha256", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Date")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Date", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Credential")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Credential", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Security-Token")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Security-Token", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Algorithm")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Algorithm", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-SignedHeaders", valid_613391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613392: Call_GetConfig_613367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns <code>Config</code> information.</p> <p>Only one <code>Config</code> response can be returned.</p>
  ## 
  let valid = call_613392.validator(path, query, header, formData, body)
  let scheme = call_613392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613392.url(scheme.get, call_613392.host, call_613392.base,
                         call_613392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613392, url, valid)

proc call*(call_613393: Call_GetConfig_613367; configId: string;
          configType: string = "antenna-downlink"): Recallable =
  ## getConfig
  ## <p>Returns <code>Config</code> information.</p> <p>Only one <code>Config</code> response can be returned.</p>
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_613394 = newJObject()
  add(path_613394, "configId", newJString(configId))
  add(path_613394, "configType", newJString(configType))
  result = call_613393.call(path_613394, nil, nil, nil, nil)

var getConfig* = Call_GetConfig_613367(name: "getConfig", meth: HttpMethod.HttpGet,
                                    host: "groundstation.amazonaws.com",
                                    route: "/config/{configType}/{configId}",
                                    validator: validate_GetConfig_613368,
                                    base: "/", url: url_GetConfig_613369,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfig_613412 = ref object of OpenApiRestCall_612658
proc url_DeleteConfig_613414(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfig_613413(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613415 = path.getOrDefault("configId")
  valid_613415 = validateParameter(valid_613415, JString, required = true,
                                 default = nil)
  if valid_613415 != nil:
    section.add "configId", valid_613415
  var valid_613416 = path.getOrDefault("configType")
  valid_613416 = validateParameter(valid_613416, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_613416 != nil:
    section.add "configType", valid_613416
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
  var valid_613417 = header.getOrDefault("X-Amz-Signature")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Signature", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Content-Sha256", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Date")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Date", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Credential")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Credential", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Security-Token")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Security-Token", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Algorithm")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Algorithm", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-SignedHeaders", valid_613423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613424: Call_DeleteConfig_613412; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Config</code>.
  ## 
  let valid = call_613424.validator(path, query, header, formData, body)
  let scheme = call_613424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613424.url(scheme.get, call_613424.host, call_613424.base,
                         call_613424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613424, url, valid)

proc call*(call_613425: Call_DeleteConfig_613412; configId: string;
          configType: string = "antenna-downlink"): Recallable =
  ## deleteConfig
  ## Deletes a <code>Config</code>.
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_613426 = newJObject()
  add(path_613426, "configId", newJString(configId))
  add(path_613426, "configType", newJString(configType))
  result = call_613425.call(path_613426, nil, nil, nil, nil)

var deleteConfig* = Call_DeleteConfig_613412(name: "deleteConfig",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_DeleteConfig_613413,
    base: "/", url: url_DeleteConfig_613414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowEndpointGroup_613427 = ref object of OpenApiRestCall_612658
proc url_GetDataflowEndpointGroup_613429(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataflowEndpointGroup_613428(path: JsonNode; query: JsonNode;
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
  var valid_613430 = path.getOrDefault("dataflowEndpointGroupId")
  valid_613430 = validateParameter(valid_613430, JString, required = true,
                                 default = nil)
  if valid_613430 != nil:
    section.add "dataflowEndpointGroupId", valid_613430
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
  var valid_613431 = header.getOrDefault("X-Amz-Signature")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Signature", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Content-Sha256", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Date")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Date", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Credential")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Credential", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Security-Token")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Security-Token", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Algorithm")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Algorithm", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-SignedHeaders", valid_613437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613438: Call_GetDataflowEndpointGroup_613427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the dataflow endpoint group.
  ## 
  let valid = call_613438.validator(path, query, header, formData, body)
  let scheme = call_613438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613438.url(scheme.get, call_613438.host, call_613438.base,
                         call_613438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613438, url, valid)

proc call*(call_613439: Call_GetDataflowEndpointGroup_613427;
          dataflowEndpointGroupId: string): Recallable =
  ## getDataflowEndpointGroup
  ## Returns the dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
  ##                          : UUID of a dataflow endpoint group.
  var path_613440 = newJObject()
  add(path_613440, "dataflowEndpointGroupId", newJString(dataflowEndpointGroupId))
  result = call_613439.call(path_613440, nil, nil, nil, nil)

var getDataflowEndpointGroup* = Call_GetDataflowEndpointGroup_613427(
    name: "getDataflowEndpointGroup", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_GetDataflowEndpointGroup_613428, base: "/",
    url: url_GetDataflowEndpointGroup_613429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataflowEndpointGroup_613441 = ref object of OpenApiRestCall_612658
proc url_DeleteDataflowEndpointGroup_613443(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataflowEndpointGroup_613442(path: JsonNode; query: JsonNode;
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
  var valid_613444 = path.getOrDefault("dataflowEndpointGroupId")
  valid_613444 = validateParameter(valid_613444, JString, required = true,
                                 default = nil)
  if valid_613444 != nil:
    section.add "dataflowEndpointGroupId", valid_613444
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
  var valid_613445 = header.getOrDefault("X-Amz-Signature")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Signature", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Content-Sha256", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Date")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Date", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Credential")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Credential", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Security-Token")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Security-Token", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Algorithm")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Algorithm", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-SignedHeaders", valid_613451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613452: Call_DeleteDataflowEndpointGroup_613441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataflow endpoint group.
  ## 
  let valid = call_613452.validator(path, query, header, formData, body)
  let scheme = call_613452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613452.url(scheme.get, call_613452.host, call_613452.base,
                         call_613452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613452, url, valid)

proc call*(call_613453: Call_DeleteDataflowEndpointGroup_613441;
          dataflowEndpointGroupId: string): Recallable =
  ## deleteDataflowEndpointGroup
  ## Deletes a dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
  ##                          : UUID of a dataflow endpoint group.
  var path_613454 = newJObject()
  add(path_613454, "dataflowEndpointGroupId", newJString(dataflowEndpointGroupId))
  result = call_613453.call(path_613454, nil, nil, nil, nil)

var deleteDataflowEndpointGroup* = Call_DeleteDataflowEndpointGroup_613441(
    name: "deleteDataflowEndpointGroup", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_DeleteDataflowEndpointGroup_613442, base: "/",
    url: url_DeleteDataflowEndpointGroup_613443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMissionProfile_613469 = ref object of OpenApiRestCall_612658
proc url_UpdateMissionProfile_613471(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMissionProfile_613470(path: JsonNode; query: JsonNode;
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
  var valid_613472 = path.getOrDefault("missionProfileId")
  valid_613472 = validateParameter(valid_613472, JString, required = true,
                                 default = nil)
  if valid_613472 != nil:
    section.add "missionProfileId", valid_613472
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
  var valid_613473 = header.getOrDefault("X-Amz-Signature")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Signature", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Content-Sha256", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Date")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Date", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Credential")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Credential", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Security-Token")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Security-Token", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Algorithm")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Algorithm", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-SignedHeaders", valid_613479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613481: Call_UpdateMissionProfile_613469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a mission profile.</p> <p>Updating a mission profile will not update the execution parameters for existing future contacts.</p>
  ## 
  let valid = call_613481.validator(path, query, header, formData, body)
  let scheme = call_613481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613481.url(scheme.get, call_613481.host, call_613481.base,
                         call_613481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613481, url, valid)

proc call*(call_613482: Call_UpdateMissionProfile_613469; missionProfileId: string;
          body: JsonNode): Recallable =
  ## updateMissionProfile
  ## <p>Updates a mission profile.</p> <p>Updating a mission profile will not update the execution parameters for existing future contacts.</p>
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  ##   body: JObject (required)
  var path_613483 = newJObject()
  var body_613484 = newJObject()
  add(path_613483, "missionProfileId", newJString(missionProfileId))
  if body != nil:
    body_613484 = body
  result = call_613482.call(path_613483, nil, nil, nil, body_613484)

var updateMissionProfile* = Call_UpdateMissionProfile_613469(
    name: "updateMissionProfile", meth: HttpMethod.HttpPut,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_UpdateMissionProfile_613470, base: "/",
    url: url_UpdateMissionProfile_613471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMissionProfile_613455 = ref object of OpenApiRestCall_612658
proc url_GetMissionProfile_613457(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMissionProfile_613456(path: JsonNode; query: JsonNode;
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
  var valid_613458 = path.getOrDefault("missionProfileId")
  valid_613458 = validateParameter(valid_613458, JString, required = true,
                                 default = nil)
  if valid_613458 != nil:
    section.add "missionProfileId", valid_613458
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
  var valid_613459 = header.getOrDefault("X-Amz-Signature")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Signature", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Content-Sha256", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Date")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Date", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Credential")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Credential", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Security-Token")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Security-Token", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Algorithm")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Algorithm", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-SignedHeaders", valid_613465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613466: Call_GetMissionProfile_613455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a mission profile.
  ## 
  let valid = call_613466.validator(path, query, header, formData, body)
  let scheme = call_613466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613466.url(scheme.get, call_613466.host, call_613466.base,
                         call_613466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613466, url, valid)

proc call*(call_613467: Call_GetMissionProfile_613455; missionProfileId: string): Recallable =
  ## getMissionProfile
  ## Returns a mission profile.
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  var path_613468 = newJObject()
  add(path_613468, "missionProfileId", newJString(missionProfileId))
  result = call_613467.call(path_613468, nil, nil, nil, nil)

var getMissionProfile* = Call_GetMissionProfile_613455(name: "getMissionProfile",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_GetMissionProfile_613456, base: "/",
    url: url_GetMissionProfile_613457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMissionProfile_613485 = ref object of OpenApiRestCall_612658
proc url_DeleteMissionProfile_613487(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMissionProfile_613486(path: JsonNode; query: JsonNode;
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
  var valid_613488 = path.getOrDefault("missionProfileId")
  valid_613488 = validateParameter(valid_613488, JString, required = true,
                                 default = nil)
  if valid_613488 != nil:
    section.add "missionProfileId", valid_613488
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
  var valid_613489 = header.getOrDefault("X-Amz-Signature")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Signature", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Content-Sha256", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Date")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Date", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Credential")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Credential", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Security-Token")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Security-Token", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Algorithm")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Algorithm", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-SignedHeaders", valid_613495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613496: Call_DeleteMissionProfile_613485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a mission profile.
  ## 
  let valid = call_613496.validator(path, query, header, formData, body)
  let scheme = call_613496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613496.url(scheme.get, call_613496.host, call_613496.base,
                         call_613496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613496, url, valid)

proc call*(call_613497: Call_DeleteMissionProfile_613485; missionProfileId: string): Recallable =
  ## deleteMissionProfile
  ## Deletes a mission profile.
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  var path_613498 = newJObject()
  add(path_613498, "missionProfileId", newJString(missionProfileId))
  result = call_613497.call(path_613498, nil, nil, nil, nil)

var deleteMissionProfile* = Call_DeleteMissionProfile_613485(
    name: "deleteMissionProfile", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_DeleteMissionProfile_613486, base: "/",
    url: url_DeleteMissionProfile_613487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMinuteUsage_613499 = ref object of OpenApiRestCall_612658
proc url_GetMinuteUsage_613501(protocol: Scheme; host: string; base: string;
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

proc validate_GetMinuteUsage_613500(path: JsonNode; query: JsonNode;
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
  var valid_613502 = header.getOrDefault("X-Amz-Signature")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Signature", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Content-Sha256", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Date")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Date", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Credential")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Credential", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Security-Token")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Security-Token", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Algorithm")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Algorithm", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-SignedHeaders", valid_613508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613510: Call_GetMinuteUsage_613499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of minutes used by account.
  ## 
  let valid = call_613510.validator(path, query, header, formData, body)
  let scheme = call_613510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613510.url(scheme.get, call_613510.host, call_613510.base,
                         call_613510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613510, url, valid)

proc call*(call_613511: Call_GetMinuteUsage_613499; body: JsonNode): Recallable =
  ## getMinuteUsage
  ## Returns the number of minutes used by account.
  ##   body: JObject (required)
  var body_613512 = newJObject()
  if body != nil:
    body_613512 = body
  result = call_613511.call(nil, nil, nil, nil, body_613512)

var getMinuteUsage* = Call_GetMinuteUsage_613499(name: "getMinuteUsage",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/minute-usage", validator: validate_GetMinuteUsage_613500, base: "/",
    url: url_GetMinuteUsage_613501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSatellite_613513 = ref object of OpenApiRestCall_612658
proc url_GetSatellite_613515(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSatellite_613514(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613516 = path.getOrDefault("satelliteId")
  valid_613516 = validateParameter(valid_613516, JString, required = true,
                                 default = nil)
  if valid_613516 != nil:
    section.add "satelliteId", valid_613516
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
  var valid_613517 = header.getOrDefault("X-Amz-Signature")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Signature", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Content-Sha256", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Date")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Date", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Credential")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Credential", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Security-Token")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Security-Token", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Algorithm")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Algorithm", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-SignedHeaders", valid_613523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613524: Call_GetSatellite_613513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a satellite.
  ## 
  let valid = call_613524.validator(path, query, header, formData, body)
  let scheme = call_613524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613524.url(scheme.get, call_613524.host, call_613524.base,
                         call_613524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613524, url, valid)

proc call*(call_613525: Call_GetSatellite_613513; satelliteId: string): Recallable =
  ## getSatellite
  ## Returns a satellite.
  ##   satelliteId: string (required)
  ##              : UUID of a satellite.
  var path_613526 = newJObject()
  add(path_613526, "satelliteId", newJString(satelliteId))
  result = call_613525.call(path_613526, nil, nil, nil, nil)

var getSatellite* = Call_GetSatellite_613513(name: "getSatellite",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite/{satelliteId}", validator: validate_GetSatellite_613514,
    base: "/", url: url_GetSatellite_613515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContacts_613527 = ref object of OpenApiRestCall_612658
proc url_ListContacts_613529(protocol: Scheme; host: string; base: string;
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

proc validate_ListContacts_613528(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613530 = query.getOrDefault("nextToken")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "nextToken", valid_613530
  var valid_613531 = query.getOrDefault("maxResults")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "maxResults", valid_613531
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
  var valid_613532 = header.getOrDefault("X-Amz-Signature")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Signature", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Content-Sha256", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Date")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Date", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Credential")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Credential", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Security-Token")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Security-Token", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Algorithm")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Algorithm", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-SignedHeaders", valid_613538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613540: Call_ListContacts_613527; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of contacts.</p> <p>If <code>statusList</code> contains AVAILABLE, the request must include <code>groundStation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>. </p>
  ## 
  let valid = call_613540.validator(path, query, header, formData, body)
  let scheme = call_613540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613540.url(scheme.get, call_613540.host, call_613540.base,
                         call_613540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613540, url, valid)

proc call*(call_613541: Call_ListContacts_613527; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listContacts
  ## <p>Returns a list of contacts.</p> <p>If <code>statusList</code> contains AVAILABLE, the request must include <code>groundStation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613542 = newJObject()
  var body_613543 = newJObject()
  add(query_613542, "nextToken", newJString(nextToken))
  if body != nil:
    body_613543 = body
  add(query_613542, "maxResults", newJString(maxResults))
  result = call_613541.call(nil, query_613542, nil, nil, body_613543)

var listContacts* = Call_ListContacts_613527(name: "listContacts",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contacts", validator: validate_ListContacts_613528, base: "/",
    url: url_ListContacts_613529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroundStations_613544 = ref object of OpenApiRestCall_612658
proc url_ListGroundStations_613546(protocol: Scheme; host: string; base: string;
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

proc validate_ListGroundStations_613545(path: JsonNode; query: JsonNode;
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
  var valid_613547 = query.getOrDefault("nextToken")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "nextToken", valid_613547
  var valid_613548 = query.getOrDefault("satelliteId")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "satelliteId", valid_613548
  var valid_613549 = query.getOrDefault("maxResults")
  valid_613549 = validateParameter(valid_613549, JInt, required = false, default = nil)
  if valid_613549 != nil:
    section.add "maxResults", valid_613549
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
  var valid_613550 = header.getOrDefault("X-Amz-Signature")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Signature", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Content-Sha256", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Date")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Date", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Credential")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Credential", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Security-Token")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Security-Token", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Algorithm")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Algorithm", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-SignedHeaders", valid_613556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613557: Call_ListGroundStations_613544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of ground stations. 
  ## 
  let valid = call_613557.validator(path, query, header, formData, body)
  let scheme = call_613557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613557.url(scheme.get, call_613557.host, call_613557.base,
                         call_613557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613557, url, valid)

proc call*(call_613558: Call_ListGroundStations_613544; nextToken: string = "";
          satelliteId: string = ""; maxResults: int = 0): Recallable =
  ## listGroundStations
  ## Returns a list of ground stations. 
  ##   nextToken: string
  ##            : Next token that can be supplied in the next call to get the next page of ground stations.
  ##   satelliteId: string
  ##              : Satellite ID to retrieve on-boarded ground stations.
  ##   maxResults: int
  ##             : Maximum number of ground stations returned.
  var query_613559 = newJObject()
  add(query_613559, "nextToken", newJString(nextToken))
  add(query_613559, "satelliteId", newJString(satelliteId))
  add(query_613559, "maxResults", newJInt(maxResults))
  result = call_613558.call(nil, query_613559, nil, nil, nil)

var listGroundStations* = Call_ListGroundStations_613544(
    name: "listGroundStations", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/groundstation",
    validator: validate_ListGroundStations_613545, base: "/",
    url: url_ListGroundStations_613546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSatellites_613560 = ref object of OpenApiRestCall_612658
proc url_ListSatellites_613562(protocol: Scheme; host: string; base: string;
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

proc validate_ListSatellites_613561(path: JsonNode; query: JsonNode;
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
  var valid_613563 = query.getOrDefault("nextToken")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "nextToken", valid_613563
  var valid_613564 = query.getOrDefault("maxResults")
  valid_613564 = validateParameter(valid_613564, JInt, required = false, default = nil)
  if valid_613564 != nil:
    section.add "maxResults", valid_613564
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
  var valid_613565 = header.getOrDefault("X-Amz-Signature")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Signature", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Content-Sha256", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Date")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Date", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Credential")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Credential", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Security-Token")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Security-Token", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Algorithm")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Algorithm", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-SignedHeaders", valid_613571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613572: Call_ListSatellites_613560; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of satellites.
  ## 
  let valid = call_613572.validator(path, query, header, formData, body)
  let scheme = call_613572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613572.url(scheme.get, call_613572.host, call_613572.base,
                         call_613572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613572, url, valid)

proc call*(call_613573: Call_ListSatellites_613560; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listSatellites
  ## Returns a list of satellites.
  ##   nextToken: string
  ##            : Next token that can be supplied in the next call to get the next page of satellites.
  ##   maxResults: int
  ##             : Maximum number of satellites returned.
  var query_613574 = newJObject()
  add(query_613574, "nextToken", newJString(nextToken))
  add(query_613574, "maxResults", newJInt(maxResults))
  result = call_613573.call(nil, query_613574, nil, nil, nil)

var listSatellites* = Call_ListSatellites_613560(name: "listSatellites",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite", validator: validate_ListSatellites_613561, base: "/",
    url: url_ListSatellites_613562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613589 = ref object of OpenApiRestCall_612658
proc url_TagResource_613591(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613590(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613592 = path.getOrDefault("resourceArn")
  valid_613592 = validateParameter(valid_613592, JString, required = true,
                                 default = nil)
  if valid_613592 != nil:
    section.add "resourceArn", valid_613592
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
  var valid_613593 = header.getOrDefault("X-Amz-Signature")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Signature", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Content-Sha256", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Date")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Date", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-Credential")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Credential", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-Security-Token")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-Security-Token", valid_613597
  var valid_613598 = header.getOrDefault("X-Amz-Algorithm")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-Algorithm", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-SignedHeaders", valid_613599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613601: Call_TagResource_613589; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns a tag to a resource.
  ## 
  let valid = call_613601.validator(path, query, header, formData, body)
  let scheme = call_613601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613601.url(scheme.get, call_613601.host, call_613601.base,
                         call_613601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613601, url, valid)

proc call*(call_613602: Call_TagResource_613589; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Assigns a tag to a resource.
  ##   resourceArn: string (required)
  ##              : ARN of a resource tag.
  ##   body: JObject (required)
  var path_613603 = newJObject()
  var body_613604 = newJObject()
  add(path_613603, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_613604 = body
  result = call_613602.call(path_613603, nil, nil, nil, body_613604)

var tagResource* = Call_TagResource_613589(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "groundstation.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_613590,
                                        base: "/", url: url_TagResource_613591,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613575 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613577(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_613576(path: JsonNode; query: JsonNode;
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
  var valid_613578 = path.getOrDefault("resourceArn")
  valid_613578 = validateParameter(valid_613578, JString, required = true,
                                 default = nil)
  if valid_613578 != nil:
    section.add "resourceArn", valid_613578
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
  var valid_613579 = header.getOrDefault("X-Amz-Signature")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Signature", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Content-Sha256", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Date")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Date", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Credential")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Credential", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-Security-Token")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Security-Token", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Algorithm")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Algorithm", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-SignedHeaders", valid_613585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613586: Call_ListTagsForResource_613575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags for a specified resource.
  ## 
  let valid = call_613586.validator(path, query, header, formData, body)
  let scheme = call_613586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613586.url(scheme.get, call_613586.host, call_613586.base,
                         call_613586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613586, url, valid)

proc call*(call_613587: Call_ListTagsForResource_613575; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags for a specified resource.
  ##   resourceArn: string (required)
  ##              : ARN of a resource.
  var path_613588 = newJObject()
  add(path_613588, "resourceArn", newJString(resourceArn))
  result = call_613587.call(path_613588, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613575(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_613576, base: "/",
    url: url_ListTagsForResource_613577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReserveContact_613605 = ref object of OpenApiRestCall_612658
proc url_ReserveContact_613607(protocol: Scheme; host: string; base: string;
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

proc validate_ReserveContact_613606(path: JsonNode; query: JsonNode;
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
  var valid_613608 = header.getOrDefault("X-Amz-Signature")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Signature", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Content-Sha256", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Date")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Date", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-Credential")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Credential", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-Security-Token")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-Security-Token", valid_613612
  var valid_613613 = header.getOrDefault("X-Amz-Algorithm")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Algorithm", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-SignedHeaders", valid_613614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613616: Call_ReserveContact_613605; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reserves a contact using specified parameters.
  ## 
  let valid = call_613616.validator(path, query, header, formData, body)
  let scheme = call_613616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613616.url(scheme.get, call_613616.host, call_613616.base,
                         call_613616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613616, url, valid)

proc call*(call_613617: Call_ReserveContact_613605; body: JsonNode): Recallable =
  ## reserveContact
  ## Reserves a contact using specified parameters.
  ##   body: JObject (required)
  var body_613618 = newJObject()
  if body != nil:
    body_613618 = body
  result = call_613617.call(nil, nil, nil, nil, body_613618)

var reserveContact* = Call_ReserveContact_613605(name: "reserveContact",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contact", validator: validate_ReserveContact_613606, base: "/",
    url: url_ReserveContact_613607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613619 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613621(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_613620(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613622 = path.getOrDefault("resourceArn")
  valid_613622 = validateParameter(valid_613622, JString, required = true,
                                 default = nil)
  if valid_613622 != nil:
    section.add "resourceArn", valid_613622
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Keys of a resource tag.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613623 = query.getOrDefault("tagKeys")
  valid_613623 = validateParameter(valid_613623, JArray, required = true, default = nil)
  if valid_613623 != nil:
    section.add "tagKeys", valid_613623
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
  var valid_613624 = header.getOrDefault("X-Amz-Signature")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Signature", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Content-Sha256", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Date")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Date", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Credential")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Credential", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Security-Token")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Security-Token", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Algorithm")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Algorithm", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-SignedHeaders", valid_613630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613631: Call_UntagResource_613619; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deassigns a resource tag.
  ## 
  let valid = call_613631.validator(path, query, header, formData, body)
  let scheme = call_613631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613631.url(scheme.get, call_613631.host, call_613631.base,
                         call_613631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613631, url, valid)

proc call*(call_613632: Call_UntagResource_613619; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deassigns a resource tag.
  ##   resourceArn: string (required)
  ##              : ARN of a resource.
  ##   tagKeys: JArray (required)
  ##          : Keys of a resource tag.
  var path_613633 = newJObject()
  var query_613634 = newJObject()
  add(path_613633, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_613634.add "tagKeys", tagKeys
  result = call_613632.call(path_613633, query_613634, nil, nil, nil)

var untagResource* = Call_UntagResource_613619(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_613620,
    base: "/", url: url_UntagResource_613621, schemes: {Scheme.Https, Scheme.Http})
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
