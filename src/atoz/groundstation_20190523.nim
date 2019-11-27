
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_DescribeContact_599705 = ref object of OpenApiRestCall_599368
proc url_DescribeContact_599707(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeContact_599706(path: JsonNode; query: JsonNode;
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
  var valid_599833 = path.getOrDefault("contactId")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "contactId", valid_599833
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599834 = header.getOrDefault("X-Amz-Date")
  valid_599834 = validateParameter(valid_599834, JString, required = false,
                                 default = nil)
  if valid_599834 != nil:
    section.add "X-Amz-Date", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Security-Token")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Security-Token", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Content-Sha256", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Algorithm")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Algorithm", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Signature")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Signature", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-SignedHeaders", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Credential")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Credential", valid_599840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_DescribeContact_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing contact.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_DescribeContact_599705; contactId: string): Recallable =
  ## describeContact
  ## Describes an existing contact.
  ##   contactId: string (required)
  ##            : UUID of a contact.
  var path_599935 = newJObject()
  add(path_599935, "contactId", newJString(contactId))
  result = call_599934.call(path_599935, nil, nil, nil, nil)

var describeContact* = Call_DescribeContact_599705(name: "describeContact",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_DescribeContact_599706,
    base: "/", url: url_DescribeContact_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelContact_599975 = ref object of OpenApiRestCall_599368
proc url_CancelContact_599977(protocol: Scheme; host: string; base: string;
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

proc validate_CancelContact_599976(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599978 = path.getOrDefault("contactId")
  valid_599978 = validateParameter(valid_599978, JString, required = true,
                                 default = nil)
  if valid_599978 != nil:
    section.add "contactId", valid_599978
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599979 = header.getOrDefault("X-Amz-Date")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Date", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Security-Token")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Security-Token", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Content-Sha256", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Algorithm")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Algorithm", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Signature", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-SignedHeaders", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Credential")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Credential", valid_599985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_CancelContact_599975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a contact with a specified contact ID.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_CancelContact_599975; contactId: string): Recallable =
  ## cancelContact
  ## Cancels a contact with a specified contact ID.
  ##   contactId: string (required)
  ##            : UUID of a contact.
  var path_599988 = newJObject()
  add(path_599988, "contactId", newJString(contactId))
  result = call_599987.call(path_599988, nil, nil, nil, nil)

var cancelContact* = Call_CancelContact_599975(name: "cancelContact",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_CancelContact_599976,
    base: "/", url: url_CancelContact_599977, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfig_600004 = ref object of OpenApiRestCall_599368
proc url_CreateConfig_600006(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfig_600005(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Content-Sha256", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Algorithm")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Algorithm", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Signature")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Signature", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-SignedHeaders", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Credential")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Credential", valid_600013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600015: Call_CreateConfig_600004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p>
  ##          <p>Only one type of <code>configData</code> can be specified.</p>
  ## 
  let valid = call_600015.validator(path, query, header, formData, body)
  let scheme = call_600015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600015.url(scheme.get, call_600015.host, call_600015.base,
                         call_600015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600015, url, valid)

proc call*(call_600016: Call_CreateConfig_600004; body: JsonNode): Recallable =
  ## createConfig
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p>
  ##          <p>Only one type of <code>configData</code> can be specified.</p>
  ##   body: JObject (required)
  var body_600017 = newJObject()
  if body != nil:
    body_600017 = body
  result = call_600016.call(nil, nil, nil, nil, body_600017)

var createConfig* = Call_CreateConfig_600004(name: "createConfig",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/config", validator: validate_CreateConfig_600005, base: "/",
    url: url_CreateConfig_600006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigs_599989 = ref object of OpenApiRestCall_599368
proc url_ListConfigs_599991(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigs_599990(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>Config</code> objects.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : Maximum number of <code>Configs</code> returned.
  ##   nextToken: JString
  ##            : Next token returned in the request of a previous <code>ListConfigs</code> call. Used to get the next page of results.
  section = newJObject()
  var valid_599992 = query.getOrDefault("maxResults")
  valid_599992 = validateParameter(valid_599992, JInt, required = false, default = nil)
  if valid_599992 != nil:
    section.add "maxResults", valid_599992
  var valid_599993 = query.getOrDefault("nextToken")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "nextToken", valid_599993
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599994 = header.getOrDefault("X-Amz-Date")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Date", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Security-Token")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Security-Token", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Content-Sha256", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Algorithm")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Algorithm", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Signature")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Signature", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-SignedHeaders", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Credential")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Credential", valid_600000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_ListConfigs_599989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>Config</code> objects.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_ListConfigs_599989; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listConfigs
  ## Returns a list of <code>Config</code> objects.
  ##   maxResults: int
  ##             : Maximum number of <code>Configs</code> returned.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListConfigs</code> call. Used to get the next page of results.
  var query_600003 = newJObject()
  add(query_600003, "maxResults", newJInt(maxResults))
  add(query_600003, "nextToken", newJString(nextToken))
  result = call_600002.call(nil, query_600003, nil, nil, nil)

var listConfigs* = Call_ListConfigs_599989(name: "listConfigs",
                                        meth: HttpMethod.HttpGet,
                                        host: "groundstation.amazonaws.com",
                                        route: "/config",
                                        validator: validate_ListConfigs_599990,
                                        base: "/", url: url_ListConfigs_599991,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataflowEndpointGroup_600033 = ref object of OpenApiRestCall_599368
proc url_CreateDataflowEndpointGroup_600035(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataflowEndpointGroup_600034(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600036 = header.getOrDefault("X-Amz-Date")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Date", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Security-Token")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Security-Token", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Content-Sha256", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Algorithm")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Algorithm", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Signature")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Signature", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-SignedHeaders", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Credential")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Credential", valid_600042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600044: Call_CreateDataflowEndpointGroup_600033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p>
  ##          <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> 
  ##          to specify which endpoints to use during a contact.</p> 
  ##          <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> 
  ##          must match a <code>DataflowEndpoint</code> in the same group.</p>
  ## 
  let valid = call_600044.validator(path, query, header, formData, body)
  let scheme = call_600044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600044.url(scheme.get, call_600044.host, call_600044.base,
                         call_600044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600044, url, valid)

proc call*(call_600045: Call_CreateDataflowEndpointGroup_600033; body: JsonNode): Recallable =
  ## createDataflowEndpointGroup
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p>
  ##          <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> 
  ##          to specify which endpoints to use during a contact.</p> 
  ##          <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> 
  ##          must match a <code>DataflowEndpoint</code> in the same group.</p>
  ##   body: JObject (required)
  var body_600046 = newJObject()
  if body != nil:
    body_600046 = body
  result = call_600045.call(nil, nil, nil, nil, body_600046)

var createDataflowEndpointGroup* = Call_CreateDataflowEndpointGroup_600033(
    name: "createDataflowEndpointGroup", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_CreateDataflowEndpointGroup_600034, base: "/",
    url: url_CreateDataflowEndpointGroup_600035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataflowEndpointGroups_600018 = ref object of OpenApiRestCall_599368
proc url_ListDataflowEndpointGroups_600020(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDataflowEndpointGroups_600019(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : Maximum number of dataflow endpoint groups returned.
  ##   nextToken: JString
  ##            : Next token returned in the request of a previous <code>ListDataflowEndpointGroups</code> call. Used to get the next page of results.
  section = newJObject()
  var valid_600021 = query.getOrDefault("maxResults")
  valid_600021 = validateParameter(valid_600021, JInt, required = false, default = nil)
  if valid_600021 != nil:
    section.add "maxResults", valid_600021
  var valid_600022 = query.getOrDefault("nextToken")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "nextToken", valid_600022
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600023 = header.getOrDefault("X-Amz-Date")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Date", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Security-Token")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Security-Token", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600030: Call_ListDataflowEndpointGroups_600018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ## 
  let valid = call_600030.validator(path, query, header, formData, body)
  let scheme = call_600030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600030.url(scheme.get, call_600030.host, call_600030.base,
                         call_600030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600030, url, valid)

proc call*(call_600031: Call_ListDataflowEndpointGroups_600018;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDataflowEndpointGroups
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ##   maxResults: int
  ##             : Maximum number of dataflow endpoint groups returned.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListDataflowEndpointGroups</code> call. Used to get the next page of results.
  var query_600032 = newJObject()
  add(query_600032, "maxResults", newJInt(maxResults))
  add(query_600032, "nextToken", newJString(nextToken))
  result = call_600031.call(nil, query_600032, nil, nil, nil)

var listDataflowEndpointGroups* = Call_ListDataflowEndpointGroups_600018(
    name: "listDataflowEndpointGroups", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_ListDataflowEndpointGroups_600019, base: "/",
    url: url_ListDataflowEndpointGroups_600020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMissionProfile_600062 = ref object of OpenApiRestCall_599368
proc url_CreateMissionProfile_600064(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMissionProfile_600063(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600065 = header.getOrDefault("X-Amz-Date")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Date", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Security-Token")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Security-Token", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Content-Sha256", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Algorithm")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Algorithm", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Signature")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Signature", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-SignedHeaders", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Credential")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Credential", valid_600071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600073: Call_CreateMissionProfile_600062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mission profile.</p>
  ##          <p>
  ##             <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings
  ##          has two elements: a <i>from ARN</i> and a <i>to ARN</i>.</p>
  ## 
  let valid = call_600073.validator(path, query, header, formData, body)
  let scheme = call_600073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600073.url(scheme.get, call_600073.host, call_600073.base,
                         call_600073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600073, url, valid)

proc call*(call_600074: Call_CreateMissionProfile_600062; body: JsonNode): Recallable =
  ## createMissionProfile
  ## <p>Creates a mission profile.</p>
  ##          <p>
  ##             <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings
  ##          has two elements: a <i>from ARN</i> and a <i>to ARN</i>.</p>
  ##   body: JObject (required)
  var body_600075 = newJObject()
  if body != nil:
    body_600075 = body
  result = call_600074.call(nil, nil, nil, nil, body_600075)

var createMissionProfile* = Call_CreateMissionProfile_600062(
    name: "createMissionProfile", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_CreateMissionProfile_600063, base: "/",
    url: url_CreateMissionProfile_600064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMissionProfiles_600047 = ref object of OpenApiRestCall_599368
proc url_ListMissionProfiles_600049(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMissionProfiles_600048(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of mission profiles.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : Maximum number of mission profiles returned.
  ##   nextToken: JString
  ##            : Next token returned in the request of a previous <code>ListMissionProfiles</code> call. Used to get the next page of results.
  section = newJObject()
  var valid_600050 = query.getOrDefault("maxResults")
  valid_600050 = validateParameter(valid_600050, JInt, required = false, default = nil)
  if valid_600050 != nil:
    section.add "maxResults", valid_600050
  var valid_600051 = query.getOrDefault("nextToken")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "nextToken", valid_600051
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Content-Sha256", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Algorithm")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Algorithm", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Signature")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Signature", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-SignedHeaders", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Credential")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Credential", valid_600058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600059: Call_ListMissionProfiles_600047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of mission profiles.
  ## 
  let valid = call_600059.validator(path, query, header, formData, body)
  let scheme = call_600059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600059.url(scheme.get, call_600059.host, call_600059.base,
                         call_600059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600059, url, valid)

proc call*(call_600060: Call_ListMissionProfiles_600047; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listMissionProfiles
  ## Returns a list of mission profiles.
  ##   maxResults: int
  ##             : Maximum number of mission profiles returned.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListMissionProfiles</code> call. Used to get the next page of results.
  var query_600061 = newJObject()
  add(query_600061, "maxResults", newJInt(maxResults))
  add(query_600061, "nextToken", newJString(nextToken))
  result = call_600060.call(nil, query_600061, nil, nil, nil)

var listMissionProfiles* = Call_ListMissionProfiles_600047(
    name: "listMissionProfiles", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_ListMissionProfiles_600048, base: "/",
    url: url_ListMissionProfiles_600049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfig_600104 = ref object of OpenApiRestCall_599368
proc url_UpdateConfig_600106(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConfig_600105(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600107 = path.getOrDefault("configId")
  valid_600107 = validateParameter(valid_600107, JString, required = true,
                                 default = nil)
  if valid_600107 != nil:
    section.add "configId", valid_600107
  var valid_600108 = path.getOrDefault("configType")
  valid_600108 = validateParameter(valid_600108, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_600108 != nil:
    section.add "configType", valid_600108
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600109 = header.getOrDefault("X-Amz-Date")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Date", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-Security-Token")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-Security-Token", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Content-Sha256", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Algorithm")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Algorithm", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Signature")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Signature", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-SignedHeaders", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Credential")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Credential", valid_600115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600117: Call_UpdateConfig_600104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p>
  ##          <p>Updating a <code>Config</code> will not update the execution parameters
  ##          for existing future contacts scheduled with this <code>Config</code>.</p>
  ## 
  let valid = call_600117.validator(path, query, header, formData, body)
  let scheme = call_600117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600117.url(scheme.get, call_600117.host, call_600117.base,
                         call_600117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600117, url, valid)

proc call*(call_600118: Call_UpdateConfig_600104; configId: string; body: JsonNode;
          configType: string = "antenna-downlink"): Recallable =
  ## updateConfig
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p>
  ##          <p>Updating a <code>Config</code> will not update the execution parameters
  ##          for existing future contacts scheduled with this <code>Config</code>.</p>
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  ##   body: JObject (required)
  var path_600119 = newJObject()
  var body_600120 = newJObject()
  add(path_600119, "configId", newJString(configId))
  add(path_600119, "configType", newJString(configType))
  if body != nil:
    body_600120 = body
  result = call_600118.call(path_600119, nil, nil, nil, body_600120)

var updateConfig* = Call_UpdateConfig_600104(name: "updateConfig",
    meth: HttpMethod.HttpPut, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_UpdateConfig_600105,
    base: "/", url: url_UpdateConfig_600106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfig_600076 = ref object of OpenApiRestCall_599368
proc url_GetConfig_600078(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetConfig_600077(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600079 = path.getOrDefault("configId")
  valid_600079 = validateParameter(valid_600079, JString, required = true,
                                 default = nil)
  if valid_600079 != nil:
    section.add "configId", valid_600079
  var valid_600093 = path.getOrDefault("configType")
  valid_600093 = validateParameter(valid_600093, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_600093 != nil:
    section.add "configType", valid_600093
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600094 = header.getOrDefault("X-Amz-Date")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Date", valid_600094
  var valid_600095 = header.getOrDefault("X-Amz-Security-Token")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "X-Amz-Security-Token", valid_600095
  var valid_600096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Content-Sha256", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Algorithm")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Algorithm", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Signature")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Signature", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-SignedHeaders", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Credential")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Credential", valid_600100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600101: Call_GetConfig_600076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns <code>Config</code> information.</p>
  ##          <p>Only one <code>Config</code> response can be returned.</p>
  ## 
  let valid = call_600101.validator(path, query, header, formData, body)
  let scheme = call_600101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600101.url(scheme.get, call_600101.host, call_600101.base,
                         call_600101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600101, url, valid)

proc call*(call_600102: Call_GetConfig_600076; configId: string;
          configType: string = "antenna-downlink"): Recallable =
  ## getConfig
  ## <p>Returns <code>Config</code> information.</p>
  ##          <p>Only one <code>Config</code> response can be returned.</p>
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_600103 = newJObject()
  add(path_600103, "configId", newJString(configId))
  add(path_600103, "configType", newJString(configType))
  result = call_600102.call(path_600103, nil, nil, nil, nil)

var getConfig* = Call_GetConfig_600076(name: "getConfig", meth: HttpMethod.HttpGet,
                                    host: "groundstation.amazonaws.com",
                                    route: "/config/{configType}/{configId}",
                                    validator: validate_GetConfig_600077,
                                    base: "/", url: url_GetConfig_600078,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfig_600121 = ref object of OpenApiRestCall_599368
proc url_DeleteConfig_600123(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConfig_600122(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600124 = path.getOrDefault("configId")
  valid_600124 = validateParameter(valid_600124, JString, required = true,
                                 default = nil)
  if valid_600124 != nil:
    section.add "configId", valid_600124
  var valid_600125 = path.getOrDefault("configType")
  valid_600125 = validateParameter(valid_600125, JString, required = true,
                                 default = newJString("antenna-downlink"))
  if valid_600125 != nil:
    section.add "configType", valid_600125
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600126 = header.getOrDefault("X-Amz-Date")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Date", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Security-Token")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Security-Token", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Content-Sha256", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Algorithm")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Algorithm", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Signature")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Signature", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-SignedHeaders", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Credential")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Credential", valid_600132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600133: Call_DeleteConfig_600121; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Config</code>.
  ## 
  let valid = call_600133.validator(path, query, header, formData, body)
  let scheme = call_600133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600133.url(scheme.get, call_600133.host, call_600133.base,
                         call_600133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600133, url, valid)

proc call*(call_600134: Call_DeleteConfig_600121; configId: string;
          configType: string = "antenna-downlink"): Recallable =
  ## deleteConfig
  ## Deletes a <code>Config</code>.
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_600135 = newJObject()
  add(path_600135, "configId", newJString(configId))
  add(path_600135, "configType", newJString(configType))
  result = call_600134.call(path_600135, nil, nil, nil, nil)

var deleteConfig* = Call_DeleteConfig_600121(name: "deleteConfig",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_DeleteConfig_600122,
    base: "/", url: url_DeleteConfig_600123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowEndpointGroup_600136 = ref object of OpenApiRestCall_599368
proc url_GetDataflowEndpointGroup_600138(protocol: Scheme; host: string;
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

proc validate_GetDataflowEndpointGroup_600137(path: JsonNode; query: JsonNode;
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
  var valid_600139 = path.getOrDefault("dataflowEndpointGroupId")
  valid_600139 = validateParameter(valid_600139, JString, required = true,
                                 default = nil)
  if valid_600139 != nil:
    section.add "dataflowEndpointGroupId", valid_600139
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600140 = header.getOrDefault("X-Amz-Date")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Date", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Security-Token")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Security-Token", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Content-Sha256", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Algorithm")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Algorithm", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Signature")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Signature", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-SignedHeaders", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Credential")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Credential", valid_600146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600147: Call_GetDataflowEndpointGroup_600136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the dataflow endpoint group.
  ## 
  let valid = call_600147.validator(path, query, header, formData, body)
  let scheme = call_600147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600147.url(scheme.get, call_600147.host, call_600147.base,
                         call_600147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600147, url, valid)

proc call*(call_600148: Call_GetDataflowEndpointGroup_600136;
          dataflowEndpointGroupId: string): Recallable =
  ## getDataflowEndpointGroup
  ## Returns the dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
  ##                          : UUID of a dataflow endpoint group.
  var path_600149 = newJObject()
  add(path_600149, "dataflowEndpointGroupId", newJString(dataflowEndpointGroupId))
  result = call_600148.call(path_600149, nil, nil, nil, nil)

var getDataflowEndpointGroup* = Call_GetDataflowEndpointGroup_600136(
    name: "getDataflowEndpointGroup", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_GetDataflowEndpointGroup_600137, base: "/",
    url: url_GetDataflowEndpointGroup_600138, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataflowEndpointGroup_600150 = ref object of OpenApiRestCall_599368
proc url_DeleteDataflowEndpointGroup_600152(protocol: Scheme; host: string;
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

proc validate_DeleteDataflowEndpointGroup_600151(path: JsonNode; query: JsonNode;
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
  var valid_600153 = path.getOrDefault("dataflowEndpointGroupId")
  valid_600153 = validateParameter(valid_600153, JString, required = true,
                                 default = nil)
  if valid_600153 != nil:
    section.add "dataflowEndpointGroupId", valid_600153
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600154 = header.getOrDefault("X-Amz-Date")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Date", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Security-Token")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Security-Token", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Content-Sha256", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Algorithm")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Algorithm", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Signature")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Signature", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-SignedHeaders", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Credential")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Credential", valid_600160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600161: Call_DeleteDataflowEndpointGroup_600150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataflow endpoint group.
  ## 
  let valid = call_600161.validator(path, query, header, formData, body)
  let scheme = call_600161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600161.url(scheme.get, call_600161.host, call_600161.base,
                         call_600161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600161, url, valid)

proc call*(call_600162: Call_DeleteDataflowEndpointGroup_600150;
          dataflowEndpointGroupId: string): Recallable =
  ## deleteDataflowEndpointGroup
  ## Deletes a dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
  ##                          : ID of a dataflow endpoint group.
  var path_600163 = newJObject()
  add(path_600163, "dataflowEndpointGroupId", newJString(dataflowEndpointGroupId))
  result = call_600162.call(path_600163, nil, nil, nil, nil)

var deleteDataflowEndpointGroup* = Call_DeleteDataflowEndpointGroup_600150(
    name: "deleteDataflowEndpointGroup", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_DeleteDataflowEndpointGroup_600151, base: "/",
    url: url_DeleteDataflowEndpointGroup_600152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMissionProfile_600178 = ref object of OpenApiRestCall_599368
proc url_UpdateMissionProfile_600180(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMissionProfile_600179(path: JsonNode; query: JsonNode;
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
  var valid_600181 = path.getOrDefault("missionProfileId")
  valid_600181 = validateParameter(valid_600181, JString, required = true,
                                 default = nil)
  if valid_600181 != nil:
    section.add "missionProfileId", valid_600181
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600182 = header.getOrDefault("X-Amz-Date")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Date", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-Security-Token")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Security-Token", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Content-Sha256", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Algorithm")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Algorithm", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Signature")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Signature", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-SignedHeaders", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Credential")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Credential", valid_600188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600190: Call_UpdateMissionProfile_600178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a mission profile.</p>
  ##          <p>Updating a mission profile will not update the execution parameters
  ##          for existing future contacts.</p>
  ## 
  let valid = call_600190.validator(path, query, header, formData, body)
  let scheme = call_600190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600190.url(scheme.get, call_600190.host, call_600190.base,
                         call_600190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600190, url, valid)

proc call*(call_600191: Call_UpdateMissionProfile_600178; missionProfileId: string;
          body: JsonNode): Recallable =
  ## updateMissionProfile
  ## <p>Updates a mission profile.</p>
  ##          <p>Updating a mission profile will not update the execution parameters
  ##          for existing future contacts.</p>
  ##   missionProfileId: string (required)
  ##                   : ID of a mission profile.
  ##   body: JObject (required)
  var path_600192 = newJObject()
  var body_600193 = newJObject()
  add(path_600192, "missionProfileId", newJString(missionProfileId))
  if body != nil:
    body_600193 = body
  result = call_600191.call(path_600192, nil, nil, nil, body_600193)

var updateMissionProfile* = Call_UpdateMissionProfile_600178(
    name: "updateMissionProfile", meth: HttpMethod.HttpPut,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_UpdateMissionProfile_600179, base: "/",
    url: url_UpdateMissionProfile_600180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMissionProfile_600164 = ref object of OpenApiRestCall_599368
proc url_GetMissionProfile_600166(protocol: Scheme; host: string; base: string;
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

proc validate_GetMissionProfile_600165(path: JsonNode; query: JsonNode;
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
  var valid_600167 = path.getOrDefault("missionProfileId")
  valid_600167 = validateParameter(valid_600167, JString, required = true,
                                 default = nil)
  if valid_600167 != nil:
    section.add "missionProfileId", valid_600167
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600168 = header.getOrDefault("X-Amz-Date")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Date", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Security-Token")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Security-Token", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Content-Sha256", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Algorithm")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Algorithm", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Signature")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Signature", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-SignedHeaders", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Credential")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Credential", valid_600174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600175: Call_GetMissionProfile_600164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a mission profile.
  ## 
  let valid = call_600175.validator(path, query, header, formData, body)
  let scheme = call_600175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600175.url(scheme.get, call_600175.host, call_600175.base,
                         call_600175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600175, url, valid)

proc call*(call_600176: Call_GetMissionProfile_600164; missionProfileId: string): Recallable =
  ## getMissionProfile
  ## Returns a mission profile.
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  var path_600177 = newJObject()
  add(path_600177, "missionProfileId", newJString(missionProfileId))
  result = call_600176.call(path_600177, nil, nil, nil, nil)

var getMissionProfile* = Call_GetMissionProfile_600164(name: "getMissionProfile",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_GetMissionProfile_600165, base: "/",
    url: url_GetMissionProfile_600166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMissionProfile_600194 = ref object of OpenApiRestCall_599368
proc url_DeleteMissionProfile_600196(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMissionProfile_600195(path: JsonNode; query: JsonNode;
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
  var valid_600197 = path.getOrDefault("missionProfileId")
  valid_600197 = validateParameter(valid_600197, JString, required = true,
                                 default = nil)
  if valid_600197 != nil:
    section.add "missionProfileId", valid_600197
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600198 = header.getOrDefault("X-Amz-Date")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Date", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-Security-Token")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Security-Token", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Content-Sha256", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Algorithm")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Algorithm", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Signature")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Signature", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-SignedHeaders", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Credential")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Credential", valid_600204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600205: Call_DeleteMissionProfile_600194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a mission profile.
  ## 
  let valid = call_600205.validator(path, query, header, formData, body)
  let scheme = call_600205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600205.url(scheme.get, call_600205.host, call_600205.base,
                         call_600205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600205, url, valid)

proc call*(call_600206: Call_DeleteMissionProfile_600194; missionProfileId: string): Recallable =
  ## deleteMissionProfile
  ## Deletes a mission profile.
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  var path_600207 = newJObject()
  add(path_600207, "missionProfileId", newJString(missionProfileId))
  result = call_600206.call(path_600207, nil, nil, nil, nil)

var deleteMissionProfile* = Call_DeleteMissionProfile_600194(
    name: "deleteMissionProfile", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_DeleteMissionProfile_600195, base: "/",
    url: url_DeleteMissionProfile_600196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContacts_600208 = ref object of OpenApiRestCall_599368
proc url_ListContacts_600210(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListContacts_600209(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600211 = query.getOrDefault("maxResults")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "maxResults", valid_600211
  var valid_600212 = query.getOrDefault("nextToken")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "nextToken", valid_600212
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600213 = header.getOrDefault("X-Amz-Date")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Date", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Security-Token")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Security-Token", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Content-Sha256", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Algorithm")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Algorithm", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Signature")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Signature", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-SignedHeaders", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Credential")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Credential", valid_600219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600221: Call_ListContacts_600208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of contacts.</p>
  ##          <p>If <code>statusList</code> contains AVAILABLE, the request must include
  ##       <code>groundstation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>.
  ##       </p>
  ## 
  let valid = call_600221.validator(path, query, header, formData, body)
  let scheme = call_600221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600221.url(scheme.get, call_600221.host, call_600221.base,
                         call_600221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600221, url, valid)

proc call*(call_600222: Call_ListContacts_600208; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listContacts
  ## <p>Returns a list of contacts.</p>
  ##          <p>If <code>statusList</code> contains AVAILABLE, the request must include
  ##       <code>groundstation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>.
  ##       </p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600223 = newJObject()
  var body_600224 = newJObject()
  add(query_600223, "maxResults", newJString(maxResults))
  add(query_600223, "nextToken", newJString(nextToken))
  if body != nil:
    body_600224 = body
  result = call_600222.call(nil, query_600223, nil, nil, body_600224)

var listContacts* = Call_ListContacts_600208(name: "listContacts",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contacts", validator: validate_ListContacts_600209, base: "/",
    url: url_ListContacts_600210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReserveContact_600225 = ref object of OpenApiRestCall_599368
proc url_ReserveContact_600227(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ReserveContact_600226(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600228 = header.getOrDefault("X-Amz-Date")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Date", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Security-Token")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Security-Token", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Content-Sha256", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Algorithm")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Algorithm", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Signature")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Signature", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-SignedHeaders", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Credential")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Credential", valid_600234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600236: Call_ReserveContact_600225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reserves a contact using specified parameters.
  ## 
  let valid = call_600236.validator(path, query, header, formData, body)
  let scheme = call_600236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600236.url(scheme.get, call_600236.host, call_600236.base,
                         call_600236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600236, url, valid)

proc call*(call_600237: Call_ReserveContact_600225; body: JsonNode): Recallable =
  ## reserveContact
  ## Reserves a contact using specified parameters.
  ##   body: JObject (required)
  var body_600238 = newJObject()
  if body != nil:
    body_600238 = body
  result = call_600237.call(nil, nil, nil, nil, body_600238)

var reserveContact* = Call_ReserveContact_600225(name: "reserveContact",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contact", validator: validate_ReserveContact_600226, base: "/",
    url: url_ReserveContact_600227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMinuteUsage_600239 = ref object of OpenApiRestCall_599368
proc url_GetMinuteUsage_600241(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMinuteUsage_600240(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600242 = header.getOrDefault("X-Amz-Date")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Date", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Security-Token")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Security-Token", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Content-Sha256", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Algorithm")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Algorithm", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Signature")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Signature", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-SignedHeaders", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Credential")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Credential", valid_600248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600250: Call_GetMinuteUsage_600239; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of minutes used by account.
  ## 
  let valid = call_600250.validator(path, query, header, formData, body)
  let scheme = call_600250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600250.url(scheme.get, call_600250.host, call_600250.base,
                         call_600250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600250, url, valid)

proc call*(call_600251: Call_GetMinuteUsage_600239; body: JsonNode): Recallable =
  ## getMinuteUsage
  ## Returns the number of minutes used by account.
  ##   body: JObject (required)
  var body_600252 = newJObject()
  if body != nil:
    body_600252 = body
  result = call_600251.call(nil, nil, nil, nil, body_600252)

var getMinuteUsage* = Call_GetMinuteUsage_600239(name: "getMinuteUsage",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/minute-usage", validator: validate_GetMinuteUsage_600240, base: "/",
    url: url_GetMinuteUsage_600241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSatellite_600253 = ref object of OpenApiRestCall_599368
proc url_GetSatellite_600255(protocol: Scheme; host: string; base: string;
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

proc validate_GetSatellite_600254(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600256 = path.getOrDefault("satelliteId")
  valid_600256 = validateParameter(valid_600256, JString, required = true,
                                 default = nil)
  if valid_600256 != nil:
    section.add "satelliteId", valid_600256
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600257 = header.getOrDefault("X-Amz-Date")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Date", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Security-Token")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Security-Token", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Content-Sha256", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Algorithm")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Algorithm", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Signature")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Signature", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-SignedHeaders", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Credential")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Credential", valid_600263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600264: Call_GetSatellite_600253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a satellite.
  ## 
  let valid = call_600264.validator(path, query, header, formData, body)
  let scheme = call_600264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600264.url(scheme.get, call_600264.host, call_600264.base,
                         call_600264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600264, url, valid)

proc call*(call_600265: Call_GetSatellite_600253; satelliteId: string): Recallable =
  ## getSatellite
  ## Returns a satellite.
  ##   satelliteId: string (required)
  ##              : UUID of a satellite.
  var path_600266 = newJObject()
  add(path_600266, "satelliteId", newJString(satelliteId))
  result = call_600265.call(path_600266, nil, nil, nil, nil)

var getSatellite* = Call_GetSatellite_600253(name: "getSatellite",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite/{satelliteId}", validator: validate_GetSatellite_600254,
    base: "/", url: url_GetSatellite_600255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroundStations_600267 = ref object of OpenApiRestCall_599368
proc url_ListGroundStations_600269(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroundStations_600268(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of ground stations. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : Maximum number of ground stations returned.
  ##   nextToken: JString
  ##            : Next token that can be supplied in the next call to get the next page of ground stations.
  section = newJObject()
  var valid_600270 = query.getOrDefault("maxResults")
  valid_600270 = validateParameter(valid_600270, JInt, required = false, default = nil)
  if valid_600270 != nil:
    section.add "maxResults", valid_600270
  var valid_600271 = query.getOrDefault("nextToken")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "nextToken", valid_600271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600272 = header.getOrDefault("X-Amz-Date")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Date", valid_600272
  var valid_600273 = header.getOrDefault("X-Amz-Security-Token")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Security-Token", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Content-Sha256", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Algorithm")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Algorithm", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Signature")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Signature", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-SignedHeaders", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Credential")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Credential", valid_600278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600279: Call_ListGroundStations_600267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of ground stations. 
  ## 
  let valid = call_600279.validator(path, query, header, formData, body)
  let scheme = call_600279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600279.url(scheme.get, call_600279.host, call_600279.base,
                         call_600279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600279, url, valid)

proc call*(call_600280: Call_ListGroundStations_600267; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listGroundStations
  ## Returns a list of ground stations. 
  ##   maxResults: int
  ##             : Maximum number of ground stations returned.
  ##   nextToken: string
  ##            : Next token that can be supplied in the next call to get the next page of ground stations.
  var query_600281 = newJObject()
  add(query_600281, "maxResults", newJInt(maxResults))
  add(query_600281, "nextToken", newJString(nextToken))
  result = call_600280.call(nil, query_600281, nil, nil, nil)

var listGroundStations* = Call_ListGroundStations_600267(
    name: "listGroundStations", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/groundstation",
    validator: validate_ListGroundStations_600268, base: "/",
    url: url_ListGroundStations_600269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSatellites_600282 = ref object of OpenApiRestCall_599368
proc url_ListSatellites_600284(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSatellites_600283(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns a list of satellites.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : Maximum number of satellites returned.
  ##   nextToken: JString
  ##            : Next token that can be supplied in the next call to get the next page of satellites.
  section = newJObject()
  var valid_600285 = query.getOrDefault("maxResults")
  valid_600285 = validateParameter(valid_600285, JInt, required = false, default = nil)
  if valid_600285 != nil:
    section.add "maxResults", valid_600285
  var valid_600286 = query.getOrDefault("nextToken")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "nextToken", valid_600286
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600287 = header.getOrDefault("X-Amz-Date")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "X-Amz-Date", valid_600287
  var valid_600288 = header.getOrDefault("X-Amz-Security-Token")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Security-Token", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Content-Sha256", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Algorithm")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Algorithm", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Signature")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Signature", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-SignedHeaders", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Credential")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Credential", valid_600293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600294: Call_ListSatellites_600282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of satellites.
  ## 
  let valid = call_600294.validator(path, query, header, formData, body)
  let scheme = call_600294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600294.url(scheme.get, call_600294.host, call_600294.base,
                         call_600294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600294, url, valid)

proc call*(call_600295: Call_ListSatellites_600282; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listSatellites
  ## Returns a list of satellites.
  ##   maxResults: int
  ##             : Maximum number of satellites returned.
  ##   nextToken: string
  ##            : Next token that can be supplied in the next call to get the next page of satellites.
  var query_600296 = newJObject()
  add(query_600296, "maxResults", newJInt(maxResults))
  add(query_600296, "nextToken", newJString(nextToken))
  result = call_600295.call(nil, query_600296, nil, nil, nil)

var listSatellites* = Call_ListSatellites_600282(name: "listSatellites",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite", validator: validate_ListSatellites_600283, base: "/",
    url: url_ListSatellites_600284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600311 = ref object of OpenApiRestCall_599368
proc url_TagResource_600313(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_600312(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600314 = path.getOrDefault("resourceArn")
  valid_600314 = validateParameter(valid_600314, JString, required = true,
                                 default = nil)
  if valid_600314 != nil:
    section.add "resourceArn", valid_600314
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600315 = header.getOrDefault("X-Amz-Date")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Date", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Security-Token")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Security-Token", valid_600316
  var valid_600317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Content-Sha256", valid_600317
  var valid_600318 = header.getOrDefault("X-Amz-Algorithm")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-Algorithm", valid_600318
  var valid_600319 = header.getOrDefault("X-Amz-Signature")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Signature", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-SignedHeaders", valid_600320
  var valid_600321 = header.getOrDefault("X-Amz-Credential")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-Credential", valid_600321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600323: Call_TagResource_600311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns a tag to a resource.
  ## 
  let valid = call_600323.validator(path, query, header, formData, body)
  let scheme = call_600323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600323.url(scheme.get, call_600323.host, call_600323.base,
                         call_600323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600323, url, valid)

proc call*(call_600324: Call_TagResource_600311; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Assigns a tag to a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : ARN of a resource tag.
  var path_600325 = newJObject()
  var body_600326 = newJObject()
  if body != nil:
    body_600326 = body
  add(path_600325, "resourceArn", newJString(resourceArn))
  result = call_600324.call(path_600325, nil, nil, nil, body_600326)

var tagResource* = Call_TagResource_600311(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "groundstation.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_600312,
                                        base: "/", url: url_TagResource_600313,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600297 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600299(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_600298(path: JsonNode; query: JsonNode;
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
  var valid_600300 = path.getOrDefault("resourceArn")
  valid_600300 = validateParameter(valid_600300, JString, required = true,
                                 default = nil)
  if valid_600300 != nil:
    section.add "resourceArn", valid_600300
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600301 = header.getOrDefault("X-Amz-Date")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Date", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-Security-Token")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Security-Token", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Content-Sha256", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-Algorithm")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-Algorithm", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Signature")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Signature", valid_600305
  var valid_600306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-SignedHeaders", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Credential")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Credential", valid_600307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600308: Call_ListTagsForResource_600297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags or a specified resource.
  ## 
  let valid = call_600308.validator(path, query, header, formData, body)
  let scheme = call_600308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600308.url(scheme.get, call_600308.host, call_600308.base,
                         call_600308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600308, url, valid)

proc call*(call_600309: Call_ListTagsForResource_600297; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags or a specified resource.
  ##   resourceArn: string (required)
  ##              : ARN of a resource.
  var path_600310 = newJObject()
  add(path_600310, "resourceArn", newJString(resourceArn))
  result = call_600309.call(path_600310, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600297(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_600298, base: "/",
    url: url_ListTagsForResource_600299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600327 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600329(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_600328(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600330 = path.getOrDefault("resourceArn")
  valid_600330 = validateParameter(valid_600330, JString, required = true,
                                 default = nil)
  if valid_600330 != nil:
    section.add "resourceArn", valid_600330
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Keys of a resource tag.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600331 = query.getOrDefault("tagKeys")
  valid_600331 = validateParameter(valid_600331, JArray, required = true, default = nil)
  if valid_600331 != nil:
    section.add "tagKeys", valid_600331
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600332 = header.getOrDefault("X-Amz-Date")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-Date", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Security-Token")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Security-Token", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Content-Sha256", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Algorithm")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Algorithm", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Signature")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Signature", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-SignedHeaders", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Credential")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Credential", valid_600338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600339: Call_UntagResource_600327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deassigns a resource tag.
  ## 
  let valid = call_600339.validator(path, query, header, formData, body)
  let scheme = call_600339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600339.url(scheme.get, call_600339.host, call_600339.base,
                         call_600339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600339, url, valid)

proc call*(call_600340: Call_UntagResource_600327; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deassigns a resource tag.
  ##   tagKeys: JArray (required)
  ##          : Keys of a resource tag.
  ##   resourceArn: string (required)
  ##              : ARN of a resource.
  var path_600341 = newJObject()
  var query_600342 = newJObject()
  if tagKeys != nil:
    query_600342.add "tagKeys", tagKeys
  add(path_600341, "resourceArn", newJString(resourceArn))
  result = call_600340.call(path_600341, query_600342, nil, nil, nil)

var untagResource* = Call_UntagResource_600327(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_600328,
    base: "/", url: url_UntagResource_600329, schemes: {Scheme.Https, Scheme.Http})
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
