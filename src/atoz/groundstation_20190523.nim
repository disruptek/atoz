
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
## Welcome to the AWS Ground Station API Reference. AWS Ground Station is a fully managed service that
##       enables you to control satellite communications, downlink and process satellite data, and
##       scale your satellite operations efficiently and cost-effectively without having
##       to build or manage your own ground station infrastructure.
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_DescribeContact_601727 = ref object of OpenApiRestCall_601389
proc url_DescribeContact_601729(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeContact_601728(path: JsonNode; query: JsonNode;
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
  var valid_601855 = path.getOrDefault("contactId")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "contactId", valid_601855
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
  var valid_601856 = header.getOrDefault("X-Amz-Signature")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Signature", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Date")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Date", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Credential")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Credential", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Security-Token")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Security-Token", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Algorithm")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Algorithm", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_DescribeContact_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing contact.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_DescribeContact_601727; contactId: string): Recallable =
  ## describeContact
  ## Describes an existing contact.
  ##   contactId: string (required)
  ##            : UUID of a contact.
  var path_601957 = newJObject()
  add(path_601957, "contactId", newJString(contactId))
  result = call_601956.call(path_601957, nil, nil, nil, nil)

var describeContact* = Call_DescribeContact_601727(name: "describeContact",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_DescribeContact_601728,
    base: "/", url: url_DescribeContact_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelContact_601997 = ref object of OpenApiRestCall_601389
proc url_CancelContact_601999(protocol: Scheme; host: string; base: string;
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

proc validate_CancelContact_601998(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602000 = path.getOrDefault("contactId")
  valid_602000 = validateParameter(valid_602000, JString, required = true,
                                 default = nil)
  if valid_602000 != nil:
    section.add "contactId", valid_602000
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
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-SignedHeaders", valid_602007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_CancelContact_601997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a contact with a specified contact ID.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CancelContact_601997; contactId: string): Recallable =
  ## cancelContact
  ## Cancels a contact with a specified contact ID.
  ##   contactId: string (required)
  ##            : UUID of a contact.
  var path_602010 = newJObject()
  add(path_602010, "contactId", newJString(contactId))
  result = call_602009.call(path_602010, nil, nil, nil, nil)

var cancelContact* = Call_CancelContact_601997(name: "cancelContact",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_CancelContact_601998,
    base: "/", url: url_CancelContact_601999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfig_602026 = ref object of OpenApiRestCall_601389
proc url_CreateConfig_602028(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConfig_602027(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p>
  ##          <p>Only one type of <code>configData</code> can be specified.</p>
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
  var valid_602029 = header.getOrDefault("X-Amz-Signature")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Signature", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Content-Sha256", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Date")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Date", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Credential")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Credential", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Security-Token")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Security-Token", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Algorithm")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Algorithm", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-SignedHeaders", valid_602035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602037: Call_CreateConfig_602026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p>
  ##          <p>Only one type of <code>configData</code> can be specified.</p>
  ## 
  let valid = call_602037.validator(path, query, header, formData, body)
  let scheme = call_602037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602037.url(scheme.get, call_602037.host, call_602037.base,
                         call_602037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602037, url, valid)

proc call*(call_602038: Call_CreateConfig_602026; body: JsonNode): Recallable =
  ## createConfig
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p>
  ##          <p>Only one type of <code>configData</code> can be specified.</p>
  ##   body: JObject (required)
  var body_602039 = newJObject()
  if body != nil:
    body_602039 = body
  result = call_602038.call(nil, nil, nil, nil, body_602039)

var createConfig* = Call_CreateConfig_602026(name: "createConfig",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/config", validator: validate_CreateConfig_602027, base: "/",
    url: url_CreateConfig_602028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigs_602011 = ref object of OpenApiRestCall_601389
proc url_ListConfigs_602013(protocol: Scheme; host: string; base: string;
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

proc validate_ListConfigs_602012(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602014 = query.getOrDefault("nextToken")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "nextToken", valid_602014
  var valid_602015 = query.getOrDefault("maxResults")
  valid_602015 = validateParameter(valid_602015, JInt, required = false, default = nil)
  if valid_602015 != nil:
    section.add "maxResults", valid_602015
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
  var valid_602016 = header.getOrDefault("X-Amz-Signature")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Signature", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Content-Sha256", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Date")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Date", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Credential")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Credential", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Security-Token")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Security-Token", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Algorithm")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Algorithm", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-SignedHeaders", valid_602022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_ListConfigs_602011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>Config</code> objects.
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_ListConfigs_602011; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listConfigs
  ## Returns a list of <code>Config</code> objects.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListConfigs</code> call. Used to get the next page of results.
  ##   maxResults: int
  ##             : Maximum number of <code>Configs</code> returned.
  var query_602025 = newJObject()
  add(query_602025, "nextToken", newJString(nextToken))
  add(query_602025, "maxResults", newJInt(maxResults))
  result = call_602024.call(nil, query_602025, nil, nil, nil)

var listConfigs* = Call_ListConfigs_602011(name: "listConfigs",
                                        meth: HttpMethod.HttpGet,
                                        host: "groundstation.amazonaws.com",
                                        route: "/config",
                                        validator: validate_ListConfigs_602012,
                                        base: "/", url: url_ListConfigs_602013,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataflowEndpointGroup_602055 = ref object of OpenApiRestCall_601389
proc url_CreateDataflowEndpointGroup_602057(protocol: Scheme; host: string;
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

proc validate_CreateDataflowEndpointGroup_602056(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p>
  ##          <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> 
  ##          to specify which endpoints to use during a contact.</p> 
  ##          <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> 
  ##          must match a <code>DataflowEndpoint</code> in the same group.</p>
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
  var valid_602058 = header.getOrDefault("X-Amz-Signature")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Signature", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Content-Sha256", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Date")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Date", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Credential")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Credential", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Security-Token")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Security-Token", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Algorithm")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Algorithm", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-SignedHeaders", valid_602064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602066: Call_CreateDataflowEndpointGroup_602055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p>
  ##          <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> 
  ##          to specify which endpoints to use during a contact.</p> 
  ##          <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> 
  ##          must match a <code>DataflowEndpoint</code> in the same group.</p>
  ## 
  let valid = call_602066.validator(path, query, header, formData, body)
  let scheme = call_602066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602066.url(scheme.get, call_602066.host, call_602066.base,
                         call_602066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602066, url, valid)

proc call*(call_602067: Call_CreateDataflowEndpointGroup_602055; body: JsonNode): Recallable =
  ## createDataflowEndpointGroup
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p>
  ##          <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> 
  ##          to specify which endpoints to use during a contact.</p> 
  ##          <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> 
  ##          must match a <code>DataflowEndpoint</code> in the same group.</p>
  ##   body: JObject (required)
  var body_602068 = newJObject()
  if body != nil:
    body_602068 = body
  result = call_602067.call(nil, nil, nil, nil, body_602068)

var createDataflowEndpointGroup* = Call_CreateDataflowEndpointGroup_602055(
    name: "createDataflowEndpointGroup", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_CreateDataflowEndpointGroup_602056, base: "/",
    url: url_CreateDataflowEndpointGroup_602057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataflowEndpointGroups_602040 = ref object of OpenApiRestCall_601389
proc url_ListDataflowEndpointGroups_602042(protocol: Scheme; host: string;
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

proc validate_ListDataflowEndpointGroups_602041(path: JsonNode; query: JsonNode;
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
  var valid_602043 = query.getOrDefault("nextToken")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "nextToken", valid_602043
  var valid_602044 = query.getOrDefault("maxResults")
  valid_602044 = validateParameter(valid_602044, JInt, required = false, default = nil)
  if valid_602044 != nil:
    section.add "maxResults", valid_602044
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
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602052: Call_ListDataflowEndpointGroups_602040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ## 
  let valid = call_602052.validator(path, query, header, formData, body)
  let scheme = call_602052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602052.url(scheme.get, call_602052.host, call_602052.base,
                         call_602052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602052, url, valid)

proc call*(call_602053: Call_ListDataflowEndpointGroups_602040;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDataflowEndpointGroups
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListDataflowEndpointGroups</code> call. Used to get the next page of results.
  ##   maxResults: int
  ##             : Maximum number of dataflow endpoint groups returned.
  var query_602054 = newJObject()
  add(query_602054, "nextToken", newJString(nextToken))
  add(query_602054, "maxResults", newJInt(maxResults))
  result = call_602053.call(nil, query_602054, nil, nil, nil)

var listDataflowEndpointGroups* = Call_ListDataflowEndpointGroups_602040(
    name: "listDataflowEndpointGroups", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_ListDataflowEndpointGroups_602041, base: "/",
    url: url_ListDataflowEndpointGroups_602042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMissionProfile_602084 = ref object of OpenApiRestCall_601389
proc url_CreateMissionProfile_602086(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMissionProfile_602085(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a mission profile.</p>
  ##          <p>
  ##             <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings
  ##          has two elements: a <i>from ARN</i> and a <i>to ARN</i>.</p>
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
  var valid_602087 = header.getOrDefault("X-Amz-Signature")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Signature", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Content-Sha256", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Date")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Date", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Credential")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Credential", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Security-Token")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Security-Token", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Algorithm")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Algorithm", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-SignedHeaders", valid_602093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602095: Call_CreateMissionProfile_602084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mission profile.</p>
  ##          <p>
  ##             <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings
  ##          has two elements: a <i>from ARN</i> and a <i>to ARN</i>.</p>
  ## 
  let valid = call_602095.validator(path, query, header, formData, body)
  let scheme = call_602095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602095.url(scheme.get, call_602095.host, call_602095.base,
                         call_602095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602095, url, valid)

proc call*(call_602096: Call_CreateMissionProfile_602084; body: JsonNode): Recallable =
  ## createMissionProfile
  ## <p>Creates a mission profile.</p>
  ##          <p>
  ##             <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings
  ##          has two elements: a <i>from ARN</i> and a <i>to ARN</i>.</p>
  ##   body: JObject (required)
  var body_602097 = newJObject()
  if body != nil:
    body_602097 = body
  result = call_602096.call(nil, nil, nil, nil, body_602097)

var createMissionProfile* = Call_CreateMissionProfile_602084(
    name: "createMissionProfile", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_CreateMissionProfile_602085, base: "/",
    url: url_CreateMissionProfile_602086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMissionProfiles_602069 = ref object of OpenApiRestCall_601389
proc url_ListMissionProfiles_602071(protocol: Scheme; host: string; base: string;
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

proc validate_ListMissionProfiles_602070(path: JsonNode; query: JsonNode;
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
  var valid_602072 = query.getOrDefault("nextToken")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "nextToken", valid_602072
  var valid_602073 = query.getOrDefault("maxResults")
  valid_602073 = validateParameter(valid_602073, JInt, required = false, default = nil)
  if valid_602073 != nil:
    section.add "maxResults", valid_602073
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
  var valid_602074 = header.getOrDefault("X-Amz-Signature")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Signature", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Content-Sha256", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Date")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Date", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Credential")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Credential", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Security-Token")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Security-Token", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Algorithm")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Algorithm", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-SignedHeaders", valid_602080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602081: Call_ListMissionProfiles_602069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of mission profiles.
  ## 
  let valid = call_602081.validator(path, query, header, formData, body)
  let scheme = call_602081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602081.url(scheme.get, call_602081.host, call_602081.base,
                         call_602081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602081, url, valid)

proc call*(call_602082: Call_ListMissionProfiles_602069; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listMissionProfiles
  ## Returns a list of mission profiles.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListMissionProfiles</code> call. Used to get the next page of results.
  ##   maxResults: int
  ##             : Maximum number of mission profiles returned.
  var query_602083 = newJObject()
  add(query_602083, "nextToken", newJString(nextToken))
  add(query_602083, "maxResults", newJInt(maxResults))
  result = call_602082.call(nil, query_602083, nil, nil, nil)

var listMissionProfiles* = Call_ListMissionProfiles_602069(
    name: "listMissionProfiles", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_ListMissionProfiles_602070, base: "/",
    url: url_ListMissionProfiles_602071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfig_602126 = ref object of OpenApiRestCall_601389
proc url_UpdateConfig_602128(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConfig_602127(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p>
  ##          <p>Updating a <code>Config</code> will not update the execution parameters
  ##          for existing future contacts scheduled with this <code>Config</code>.</p>
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
  var valid_602129 = path.getOrDefault("configId")
  valid_602129 = validateParameter(valid_602129, JString, required = true,
                                 default = nil)
  if valid_602129 != nil:
    section.add "configId", valid_602129
  var valid_602130 = path.getOrDefault("configType")
  valid_602130 = validateParameter(valid_602130, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_602130 != nil:
    section.add "configType", valid_602130
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
  var valid_602131 = header.getOrDefault("X-Amz-Signature")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Signature", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Content-Sha256", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Date")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Date", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Credential")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Credential", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Security-Token")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Security-Token", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Algorithm")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Algorithm", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-SignedHeaders", valid_602137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602139: Call_UpdateConfig_602126; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p>
  ##          <p>Updating a <code>Config</code> will not update the execution parameters
  ##          for existing future contacts scheduled with this <code>Config</code>.</p>
  ## 
  let valid = call_602139.validator(path, query, header, formData, body)
  let scheme = call_602139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602139.url(scheme.get, call_602139.host, call_602139.base,
                         call_602139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602139, url, valid)

proc call*(call_602140: Call_UpdateConfig_602126; configId: string; body: JsonNode;
          configType: string = "antenna-downlink"): Recallable =
  ## updateConfig
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p>
  ##          <p>Updating a <code>Config</code> will not update the execution parameters
  ##          for existing future contacts scheduled with this <code>Config</code>.</p>
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   body: JObject (required)
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_602141 = newJObject()
  var body_602142 = newJObject()
  add(path_602141, "configId", newJString(configId))
  if body != nil:
    body_602142 = body
  add(path_602141, "configType", newJString(configType))
  result = call_602140.call(path_602141, nil, nil, nil, body_602142)

var updateConfig* = Call_UpdateConfig_602126(name: "updateConfig",
    meth: HttpMethod.HttpPut, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_UpdateConfig_602127,
    base: "/", url: url_UpdateConfig_602128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfig_602098 = ref object of OpenApiRestCall_601389
proc url_GetConfig_602100(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetConfig_602099(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns <code>Config</code> information.</p>
  ##          <p>Only one <code>Config</code> response can be returned.</p>
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
  var valid_602101 = path.getOrDefault("configId")
  valid_602101 = validateParameter(valid_602101, JString, required = true,
                                 default = nil)
  if valid_602101 != nil:
    section.add "configId", valid_602101
  var valid_602115 = path.getOrDefault("configType")
  valid_602115 = validateParameter(valid_602115, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_602115 != nil:
    section.add "configType", valid_602115
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
  var valid_602116 = header.getOrDefault("X-Amz-Signature")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Signature", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Content-Sha256", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Date")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Date", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Credential")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Credential", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Security-Token")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Security-Token", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Algorithm")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Algorithm", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-SignedHeaders", valid_602122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602123: Call_GetConfig_602098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns <code>Config</code> information.</p>
  ##          <p>Only one <code>Config</code> response can be returned.</p>
  ## 
  let valid = call_602123.validator(path, query, header, formData, body)
  let scheme = call_602123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602123.url(scheme.get, call_602123.host, call_602123.base,
                         call_602123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602123, url, valid)

proc call*(call_602124: Call_GetConfig_602098; configId: string;
          configType: string = "antenna-downlink"): Recallable =
  ## getConfig
  ## <p>Returns <code>Config</code> information.</p>
  ##          <p>Only one <code>Config</code> response can be returned.</p>
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_602125 = newJObject()
  add(path_602125, "configId", newJString(configId))
  add(path_602125, "configType", newJString(configType))
  result = call_602124.call(path_602125, nil, nil, nil, nil)

var getConfig* = Call_GetConfig_602098(name: "getConfig", meth: HttpMethod.HttpGet,
                                    host: "groundstation.amazonaws.com",
                                    route: "/config/{configType}/{configId}",
                                    validator: validate_GetConfig_602099,
                                    base: "/", url: url_GetConfig_602100,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfig_602143 = ref object of OpenApiRestCall_601389
proc url_DeleteConfig_602145(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConfig_602144(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602146 = path.getOrDefault("configId")
  valid_602146 = validateParameter(valid_602146, JString, required = true,
                                 default = nil)
  if valid_602146 != nil:
    section.add "configId", valid_602146
  var valid_602147 = path.getOrDefault("configType")
  valid_602147 = validateParameter(valid_602147, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_602147 != nil:
    section.add "configType", valid_602147
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
  var valid_602148 = header.getOrDefault("X-Amz-Signature")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Signature", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Content-Sha256", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Date")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Date", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Credential")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Credential", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Security-Token")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Security-Token", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Algorithm")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Algorithm", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-SignedHeaders", valid_602154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602155: Call_DeleteConfig_602143; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Config</code>.
  ## 
  let valid = call_602155.validator(path, query, header, formData, body)
  let scheme = call_602155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602155.url(scheme.get, call_602155.host, call_602155.base,
                         call_602155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602155, url, valid)

proc call*(call_602156: Call_DeleteConfig_602143; configId: string;
          configType: string = "antenna-downlink"): Recallable =
  ## deleteConfig
  ## Deletes a <code>Config</code>.
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_602157 = newJObject()
  add(path_602157, "configId", newJString(configId))
  add(path_602157, "configType", newJString(configType))
  result = call_602156.call(path_602157, nil, nil, nil, nil)

var deleteConfig* = Call_DeleteConfig_602143(name: "deleteConfig",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_DeleteConfig_602144,
    base: "/", url: url_DeleteConfig_602145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowEndpointGroup_602158 = ref object of OpenApiRestCall_601389
proc url_GetDataflowEndpointGroup_602160(protocol: Scheme; host: string;
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

proc validate_GetDataflowEndpointGroup_602159(path: JsonNode; query: JsonNode;
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
  var valid_602161 = path.getOrDefault("dataflowEndpointGroupId")
  valid_602161 = validateParameter(valid_602161, JString, required = true,
                                 default = nil)
  if valid_602161 != nil:
    section.add "dataflowEndpointGroupId", valid_602161
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
  var valid_602162 = header.getOrDefault("X-Amz-Signature")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Signature", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Content-Sha256", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Date")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Date", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Credential")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Credential", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Security-Token")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Security-Token", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Algorithm")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Algorithm", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-SignedHeaders", valid_602168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602169: Call_GetDataflowEndpointGroup_602158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the dataflow endpoint group.
  ## 
  let valid = call_602169.validator(path, query, header, formData, body)
  let scheme = call_602169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602169.url(scheme.get, call_602169.host, call_602169.base,
                         call_602169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602169, url, valid)

proc call*(call_602170: Call_GetDataflowEndpointGroup_602158;
          dataflowEndpointGroupId: string): Recallable =
  ## getDataflowEndpointGroup
  ## Returns the dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
  ##                          : UUID of a dataflow endpoint group.
  var path_602171 = newJObject()
  add(path_602171, "dataflowEndpointGroupId", newJString(dataflowEndpointGroupId))
  result = call_602170.call(path_602171, nil, nil, nil, nil)

var getDataflowEndpointGroup* = Call_GetDataflowEndpointGroup_602158(
    name: "getDataflowEndpointGroup", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_GetDataflowEndpointGroup_602159, base: "/",
    url: url_GetDataflowEndpointGroup_602160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataflowEndpointGroup_602172 = ref object of OpenApiRestCall_601389
proc url_DeleteDataflowEndpointGroup_602174(protocol: Scheme; host: string;
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

proc validate_DeleteDataflowEndpointGroup_602173(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a dataflow endpoint group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   dataflowEndpointGroupId: JString (required)
  ##                          : ID of a dataflow endpoint group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `dataflowEndpointGroupId` field"
  var valid_602175 = path.getOrDefault("dataflowEndpointGroupId")
  valid_602175 = validateParameter(valid_602175, JString, required = true,
                                 default = nil)
  if valid_602175 != nil:
    section.add "dataflowEndpointGroupId", valid_602175
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
  var valid_602176 = header.getOrDefault("X-Amz-Signature")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Signature", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Content-Sha256", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Date")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Date", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Credential")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Credential", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Security-Token")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Security-Token", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Algorithm")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Algorithm", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-SignedHeaders", valid_602182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602183: Call_DeleteDataflowEndpointGroup_602172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataflow endpoint group.
  ## 
  let valid = call_602183.validator(path, query, header, formData, body)
  let scheme = call_602183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602183.url(scheme.get, call_602183.host, call_602183.base,
                         call_602183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602183, url, valid)

proc call*(call_602184: Call_DeleteDataflowEndpointGroup_602172;
          dataflowEndpointGroupId: string): Recallable =
  ## deleteDataflowEndpointGroup
  ## Deletes a dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
  ##                          : ID of a dataflow endpoint group.
  var path_602185 = newJObject()
  add(path_602185, "dataflowEndpointGroupId", newJString(dataflowEndpointGroupId))
  result = call_602184.call(path_602185, nil, nil, nil, nil)

var deleteDataflowEndpointGroup* = Call_DeleteDataflowEndpointGroup_602172(
    name: "deleteDataflowEndpointGroup", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_DeleteDataflowEndpointGroup_602173, base: "/",
    url: url_DeleteDataflowEndpointGroup_602174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMissionProfile_602200 = ref object of OpenApiRestCall_601389
proc url_UpdateMissionProfile_602202(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMissionProfile_602201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates a mission profile.</p>
  ##          <p>Updating a mission profile will not update the execution parameters
  ##          for existing future contacts.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   missionProfileId: JString (required)
  ##                   : ID of a mission profile.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `missionProfileId` field"
  var valid_602203 = path.getOrDefault("missionProfileId")
  valid_602203 = validateParameter(valid_602203, JString, required = true,
                                 default = nil)
  if valid_602203 != nil:
    section.add "missionProfileId", valid_602203
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
  var valid_602204 = header.getOrDefault("X-Amz-Signature")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Signature", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Content-Sha256", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Date")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Date", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Credential")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Credential", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Security-Token")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Security-Token", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Algorithm")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Algorithm", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-SignedHeaders", valid_602210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602212: Call_UpdateMissionProfile_602200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a mission profile.</p>
  ##          <p>Updating a mission profile will not update the execution parameters
  ##          for existing future contacts.</p>
  ## 
  let valid = call_602212.validator(path, query, header, formData, body)
  let scheme = call_602212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602212.url(scheme.get, call_602212.host, call_602212.base,
                         call_602212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602212, url, valid)

proc call*(call_602213: Call_UpdateMissionProfile_602200; missionProfileId: string;
          body: JsonNode): Recallable =
  ## updateMissionProfile
  ## <p>Updates a mission profile.</p>
  ##          <p>Updating a mission profile will not update the execution parameters
  ##          for existing future contacts.</p>
  ##   missionProfileId: string (required)
  ##                   : ID of a mission profile.
  ##   body: JObject (required)
  var path_602214 = newJObject()
  var body_602215 = newJObject()
  add(path_602214, "missionProfileId", newJString(missionProfileId))
  if body != nil:
    body_602215 = body
  result = call_602213.call(path_602214, nil, nil, nil, body_602215)

var updateMissionProfile* = Call_UpdateMissionProfile_602200(
    name: "updateMissionProfile", meth: HttpMethod.HttpPut,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_UpdateMissionProfile_602201, base: "/",
    url: url_UpdateMissionProfile_602202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMissionProfile_602186 = ref object of OpenApiRestCall_601389
proc url_GetMissionProfile_602188(protocol: Scheme; host: string; base: string;
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

proc validate_GetMissionProfile_602187(path: JsonNode; query: JsonNode;
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
  var valid_602189 = path.getOrDefault("missionProfileId")
  valid_602189 = validateParameter(valid_602189, JString, required = true,
                                 default = nil)
  if valid_602189 != nil:
    section.add "missionProfileId", valid_602189
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
  var valid_602190 = header.getOrDefault("X-Amz-Signature")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Signature", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Content-Sha256", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Date")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Date", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Credential")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Credential", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Security-Token")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Security-Token", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Algorithm")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Algorithm", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-SignedHeaders", valid_602196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602197: Call_GetMissionProfile_602186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a mission profile.
  ## 
  let valid = call_602197.validator(path, query, header, formData, body)
  let scheme = call_602197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602197.url(scheme.get, call_602197.host, call_602197.base,
                         call_602197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602197, url, valid)

proc call*(call_602198: Call_GetMissionProfile_602186; missionProfileId: string): Recallable =
  ## getMissionProfile
  ## Returns a mission profile.
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  var path_602199 = newJObject()
  add(path_602199, "missionProfileId", newJString(missionProfileId))
  result = call_602198.call(path_602199, nil, nil, nil, nil)

var getMissionProfile* = Call_GetMissionProfile_602186(name: "getMissionProfile",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_GetMissionProfile_602187, base: "/",
    url: url_GetMissionProfile_602188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMissionProfile_602216 = ref object of OpenApiRestCall_601389
proc url_DeleteMissionProfile_602218(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMissionProfile_602217(path: JsonNode; query: JsonNode;
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
  var valid_602219 = path.getOrDefault("missionProfileId")
  valid_602219 = validateParameter(valid_602219, JString, required = true,
                                 default = nil)
  if valid_602219 != nil:
    section.add "missionProfileId", valid_602219
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
  var valid_602220 = header.getOrDefault("X-Amz-Signature")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Signature", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Content-Sha256", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Date")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Date", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Credential")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Credential", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Security-Token")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Security-Token", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Algorithm")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Algorithm", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-SignedHeaders", valid_602226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602227: Call_DeleteMissionProfile_602216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a mission profile.
  ## 
  let valid = call_602227.validator(path, query, header, formData, body)
  let scheme = call_602227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602227.url(scheme.get, call_602227.host, call_602227.base,
                         call_602227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602227, url, valid)

proc call*(call_602228: Call_DeleteMissionProfile_602216; missionProfileId: string): Recallable =
  ## deleteMissionProfile
  ## Deletes a mission profile.
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  var path_602229 = newJObject()
  add(path_602229, "missionProfileId", newJString(missionProfileId))
  result = call_602228.call(path_602229, nil, nil, nil, nil)

var deleteMissionProfile* = Call_DeleteMissionProfile_602216(
    name: "deleteMissionProfile", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_DeleteMissionProfile_602217, base: "/",
    url: url_DeleteMissionProfile_602218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContacts_602230 = ref object of OpenApiRestCall_601389
proc url_ListContacts_602232(protocol: Scheme; host: string; base: string;
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

proc validate_ListContacts_602231(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of contacts.</p>
  ##          <p>If <code>statusList</code> contains AVAILABLE, the request must include
  ##       <code>groundstation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>.
  ##       </p>
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
  var valid_602233 = query.getOrDefault("nextToken")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "nextToken", valid_602233
  var valid_602234 = query.getOrDefault("maxResults")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "maxResults", valid_602234
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
  var valid_602235 = header.getOrDefault("X-Amz-Signature")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Signature", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Content-Sha256", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Date")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Date", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Credential")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Credential", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Security-Token")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Security-Token", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Algorithm")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Algorithm", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-SignedHeaders", valid_602241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602243: Call_ListContacts_602230; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of contacts.</p>
  ##          <p>If <code>statusList</code> contains AVAILABLE, the request must include
  ##       <code>groundstation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>.
  ##       </p>
  ## 
  let valid = call_602243.validator(path, query, header, formData, body)
  let scheme = call_602243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602243.url(scheme.get, call_602243.host, call_602243.base,
                         call_602243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602243, url, valid)

proc call*(call_602244: Call_ListContacts_602230; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listContacts
  ## <p>Returns a list of contacts.</p>
  ##          <p>If <code>statusList</code> contains AVAILABLE, the request must include
  ##       <code>groundstation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>.
  ##       </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602245 = newJObject()
  var body_602246 = newJObject()
  add(query_602245, "nextToken", newJString(nextToken))
  if body != nil:
    body_602246 = body
  add(query_602245, "maxResults", newJString(maxResults))
  result = call_602244.call(nil, query_602245, nil, nil, body_602246)

var listContacts* = Call_ListContacts_602230(name: "listContacts",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contacts", validator: validate_ListContacts_602231, base: "/",
    url: url_ListContacts_602232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReserveContact_602247 = ref object of OpenApiRestCall_601389
proc url_ReserveContact_602249(protocol: Scheme; host: string; base: string;
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

proc validate_ReserveContact_602248(path: JsonNode; query: JsonNode;
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
  var valid_602250 = header.getOrDefault("X-Amz-Signature")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Signature", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Content-Sha256", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Date")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Date", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Credential")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Credential", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Security-Token")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Security-Token", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Algorithm")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Algorithm", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-SignedHeaders", valid_602256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602258: Call_ReserveContact_602247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reserves a contact using specified parameters.
  ## 
  let valid = call_602258.validator(path, query, header, formData, body)
  let scheme = call_602258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602258.url(scheme.get, call_602258.host, call_602258.base,
                         call_602258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602258, url, valid)

proc call*(call_602259: Call_ReserveContact_602247; body: JsonNode): Recallable =
  ## reserveContact
  ## Reserves a contact using specified parameters.
  ##   body: JObject (required)
  var body_602260 = newJObject()
  if body != nil:
    body_602260 = body
  result = call_602259.call(nil, nil, nil, nil, body_602260)

var reserveContact* = Call_ReserveContact_602247(name: "reserveContact",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contact", validator: validate_ReserveContact_602248, base: "/",
    url: url_ReserveContact_602249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMinuteUsage_602261 = ref object of OpenApiRestCall_601389
proc url_GetMinuteUsage_602263(protocol: Scheme; host: string; base: string;
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

proc validate_GetMinuteUsage_602262(path: JsonNode; query: JsonNode;
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
  var valid_602264 = header.getOrDefault("X-Amz-Signature")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Signature", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Content-Sha256", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Date")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Date", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Credential")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Credential", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Security-Token")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Security-Token", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Algorithm")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Algorithm", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-SignedHeaders", valid_602270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602272: Call_GetMinuteUsage_602261; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of minutes used by account.
  ## 
  let valid = call_602272.validator(path, query, header, formData, body)
  let scheme = call_602272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602272.url(scheme.get, call_602272.host, call_602272.base,
                         call_602272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602272, url, valid)

proc call*(call_602273: Call_GetMinuteUsage_602261; body: JsonNode): Recallable =
  ## getMinuteUsage
  ## Returns the number of minutes used by account.
  ##   body: JObject (required)
  var body_602274 = newJObject()
  if body != nil:
    body_602274 = body
  result = call_602273.call(nil, nil, nil, nil, body_602274)

var getMinuteUsage* = Call_GetMinuteUsage_602261(name: "getMinuteUsage",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/minute-usage", validator: validate_GetMinuteUsage_602262, base: "/",
    url: url_GetMinuteUsage_602263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSatellite_602275 = ref object of OpenApiRestCall_601389
proc url_GetSatellite_602277(protocol: Scheme; host: string; base: string;
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

proc validate_GetSatellite_602276(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602278 = path.getOrDefault("satelliteId")
  valid_602278 = validateParameter(valid_602278, JString, required = true,
                                 default = nil)
  if valid_602278 != nil:
    section.add "satelliteId", valid_602278
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
  var valid_602279 = header.getOrDefault("X-Amz-Signature")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Signature", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Content-Sha256", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Date")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Date", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Credential")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Credential", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Security-Token")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Security-Token", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Algorithm")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Algorithm", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-SignedHeaders", valid_602285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602286: Call_GetSatellite_602275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a satellite.
  ## 
  let valid = call_602286.validator(path, query, header, formData, body)
  let scheme = call_602286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602286.url(scheme.get, call_602286.host, call_602286.base,
                         call_602286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602286, url, valid)

proc call*(call_602287: Call_GetSatellite_602275; satelliteId: string): Recallable =
  ## getSatellite
  ## Returns a satellite.
  ##   satelliteId: string (required)
  ##              : UUID of a satellite.
  var path_602288 = newJObject()
  add(path_602288, "satelliteId", newJString(satelliteId))
  result = call_602287.call(path_602288, nil, nil, nil, nil)

var getSatellite* = Call_GetSatellite_602275(name: "getSatellite",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite/{satelliteId}", validator: validate_GetSatellite_602276,
    base: "/", url: url_GetSatellite_602277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroundStations_602289 = ref object of OpenApiRestCall_601389
proc url_ListGroundStations_602291(protocol: Scheme; host: string; base: string;
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

proc validate_ListGroundStations_602290(path: JsonNode; query: JsonNode;
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
  ##   maxResults: JInt
  ##             : Maximum number of ground stations returned.
  section = newJObject()
  var valid_602292 = query.getOrDefault("nextToken")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "nextToken", valid_602292
  var valid_602293 = query.getOrDefault("maxResults")
  valid_602293 = validateParameter(valid_602293, JInt, required = false, default = nil)
  if valid_602293 != nil:
    section.add "maxResults", valid_602293
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
  var valid_602294 = header.getOrDefault("X-Amz-Signature")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Signature", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Content-Sha256", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Date")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Date", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Credential")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Credential", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Security-Token")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Security-Token", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Algorithm")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Algorithm", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-SignedHeaders", valid_602300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602301: Call_ListGroundStations_602289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of ground stations. 
  ## 
  let valid = call_602301.validator(path, query, header, formData, body)
  let scheme = call_602301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602301.url(scheme.get, call_602301.host, call_602301.base,
                         call_602301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602301, url, valid)

proc call*(call_602302: Call_ListGroundStations_602289; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listGroundStations
  ## Returns a list of ground stations. 
  ##   nextToken: string
  ##            : Next token that can be supplied in the next call to get the next page of ground stations.
  ##   maxResults: int
  ##             : Maximum number of ground stations returned.
  var query_602303 = newJObject()
  add(query_602303, "nextToken", newJString(nextToken))
  add(query_602303, "maxResults", newJInt(maxResults))
  result = call_602302.call(nil, query_602303, nil, nil, nil)

var listGroundStations* = Call_ListGroundStations_602289(
    name: "listGroundStations", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/groundstation",
    validator: validate_ListGroundStations_602290, base: "/",
    url: url_ListGroundStations_602291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSatellites_602304 = ref object of OpenApiRestCall_601389
proc url_ListSatellites_602306(protocol: Scheme; host: string; base: string;
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

proc validate_ListSatellites_602305(path: JsonNode; query: JsonNode;
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
  var valid_602307 = query.getOrDefault("nextToken")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "nextToken", valid_602307
  var valid_602308 = query.getOrDefault("maxResults")
  valid_602308 = validateParameter(valid_602308, JInt, required = false, default = nil)
  if valid_602308 != nil:
    section.add "maxResults", valid_602308
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
  var valid_602309 = header.getOrDefault("X-Amz-Signature")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Signature", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Content-Sha256", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Date")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Date", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Credential")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Credential", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Security-Token")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Security-Token", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Algorithm")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Algorithm", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-SignedHeaders", valid_602315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602316: Call_ListSatellites_602304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of satellites.
  ## 
  let valid = call_602316.validator(path, query, header, formData, body)
  let scheme = call_602316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602316.url(scheme.get, call_602316.host, call_602316.base,
                         call_602316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602316, url, valid)

proc call*(call_602317: Call_ListSatellites_602304; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listSatellites
  ## Returns a list of satellites.
  ##   nextToken: string
  ##            : Next token that can be supplied in the next call to get the next page of satellites.
  ##   maxResults: int
  ##             : Maximum number of satellites returned.
  var query_602318 = newJObject()
  add(query_602318, "nextToken", newJString(nextToken))
  add(query_602318, "maxResults", newJInt(maxResults))
  result = call_602317.call(nil, query_602318, nil, nil, nil)

var listSatellites* = Call_ListSatellites_602304(name: "listSatellites",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite", validator: validate_ListSatellites_602305, base: "/",
    url: url_ListSatellites_602306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602333 = ref object of OpenApiRestCall_601389
proc url_TagResource_602335(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602334(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602336 = path.getOrDefault("resourceArn")
  valid_602336 = validateParameter(valid_602336, JString, required = true,
                                 default = nil)
  if valid_602336 != nil:
    section.add "resourceArn", valid_602336
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
  var valid_602337 = header.getOrDefault("X-Amz-Signature")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Signature", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Content-Sha256", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Date")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Date", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Credential")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Credential", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Security-Token")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Security-Token", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Algorithm")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Algorithm", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-SignedHeaders", valid_602343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602345: Call_TagResource_602333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns a tag to a resource.
  ## 
  let valid = call_602345.validator(path, query, header, formData, body)
  let scheme = call_602345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602345.url(scheme.get, call_602345.host, call_602345.base,
                         call_602345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602345, url, valid)

proc call*(call_602346: Call_TagResource_602333; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Assigns a tag to a resource.
  ##   resourceArn: string (required)
  ##              : ARN of a resource tag.
  ##   body: JObject (required)
  var path_602347 = newJObject()
  var body_602348 = newJObject()
  add(path_602347, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_602348 = body
  result = call_602346.call(path_602347, nil, nil, nil, body_602348)

var tagResource* = Call_TagResource_602333(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "groundstation.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_602334,
                                        base: "/", url: url_TagResource_602335,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602319 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602321(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602320(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of tags or a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : ARN of a resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_602322 = path.getOrDefault("resourceArn")
  valid_602322 = validateParameter(valid_602322, JString, required = true,
                                 default = nil)
  if valid_602322 != nil:
    section.add "resourceArn", valid_602322
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
  var valid_602323 = header.getOrDefault("X-Amz-Signature")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Signature", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Content-Sha256", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Date")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Date", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Credential")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Credential", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Security-Token")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Security-Token", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Algorithm")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Algorithm", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-SignedHeaders", valid_602329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602330: Call_ListTagsForResource_602319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags or a specified resource.
  ## 
  let valid = call_602330.validator(path, query, header, formData, body)
  let scheme = call_602330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602330.url(scheme.get, call_602330.host, call_602330.base,
                         call_602330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602330, url, valid)

proc call*(call_602331: Call_ListTagsForResource_602319; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags or a specified resource.
  ##   resourceArn: string (required)
  ##              : ARN of a resource.
  var path_602332 = newJObject()
  add(path_602332, "resourceArn", newJString(resourceArn))
  result = call_602331.call(path_602332, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602319(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_602320, base: "/",
    url: url_ListTagsForResource_602321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602349 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602351(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602350(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602352 = path.getOrDefault("resourceArn")
  valid_602352 = validateParameter(valid_602352, JString, required = true,
                                 default = nil)
  if valid_602352 != nil:
    section.add "resourceArn", valid_602352
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Keys of a resource tag.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602353 = query.getOrDefault("tagKeys")
  valid_602353 = validateParameter(valid_602353, JArray, required = true, default = nil)
  if valid_602353 != nil:
    section.add "tagKeys", valid_602353
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
  var valid_602354 = header.getOrDefault("X-Amz-Signature")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Signature", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Content-Sha256", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Date")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Date", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Credential")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Credential", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Security-Token")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Security-Token", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Algorithm")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Algorithm", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-SignedHeaders", valid_602360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602361: Call_UntagResource_602349; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deassigns a resource tag.
  ## 
  let valid = call_602361.validator(path, query, header, formData, body)
  let scheme = call_602361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602361.url(scheme.get, call_602361.host, call_602361.base,
                         call_602361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602361, url, valid)

proc call*(call_602362: Call_UntagResource_602349; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deassigns a resource tag.
  ##   resourceArn: string (required)
  ##              : ARN of a resource.
  ##   tagKeys: JArray (required)
  ##          : Keys of a resource tag.
  var path_602363 = newJObject()
  var query_602364 = newJObject()
  add(path_602363, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_602364.add "tagKeys", tagKeys
  result = call_602362.call(path_602363, query_602364, nil, nil, nil)

var untagResource* = Call_UntagResource_602349(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_602350,
    base: "/", url: url_UntagResource_602351, schemes: {Scheme.Https, Scheme.Http})
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
