
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2013-01-10
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/rds/
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

  OpenApiRestCall_601373 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601373](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601373): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "rds.ap-northeast-1.amazonaws.com", "ap-southeast-1": "rds.ap-southeast-1.amazonaws.com",
                           "us-west-2": "rds.us-west-2.amazonaws.com",
                           "eu-west-2": "rds.eu-west-2.amazonaws.com", "ap-northeast-3": "rds.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "rds.eu-central-1.amazonaws.com",
                           "us-east-2": "rds.us-east-2.amazonaws.com",
                           "us-east-1": "rds.us-east-1.amazonaws.com", "cn-northwest-1": "rds.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "rds.ap-south-1.amazonaws.com",
                           "eu-north-1": "rds.eu-north-1.amazonaws.com", "ap-northeast-2": "rds.ap-northeast-2.amazonaws.com",
                           "us-west-1": "rds.us-west-1.amazonaws.com",
                           "us-gov-east-1": "rds.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "rds.eu-west-3.amazonaws.com",
                           "cn-north-1": "rds.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "rds.sa-east-1.amazonaws.com",
                           "eu-west-1": "rds.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "rds.us-gov-west-1.amazonaws.com", "ap-southeast-2": "rds.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "rds.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "rds.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "rds.ap-southeast-1.amazonaws.com",
      "us-west-2": "rds.us-west-2.amazonaws.com",
      "eu-west-2": "rds.eu-west-2.amazonaws.com",
      "ap-northeast-3": "rds.ap-northeast-3.amazonaws.com",
      "eu-central-1": "rds.eu-central-1.amazonaws.com",
      "us-east-2": "rds.us-east-2.amazonaws.com",
      "us-east-1": "rds.us-east-1.amazonaws.com",
      "cn-northwest-1": "rds.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "rds.ap-south-1.amazonaws.com",
      "eu-north-1": "rds.eu-north-1.amazonaws.com",
      "ap-northeast-2": "rds.ap-northeast-2.amazonaws.com",
      "us-west-1": "rds.us-west-1.amazonaws.com",
      "us-gov-east-1": "rds.us-gov-east-1.amazonaws.com",
      "eu-west-3": "rds.eu-west-3.amazonaws.com",
      "cn-north-1": "rds.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "rds.sa-east-1.amazonaws.com",
      "eu-west-1": "rds.eu-west-1.amazonaws.com",
      "us-gov-west-1": "rds.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "rds.ap-southeast-2.amazonaws.com",
      "ca-central-1": "rds.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "rds"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddSourceIdentifierToSubscription_601983 = ref object of OpenApiRestCall_601373
proc url_PostAddSourceIdentifierToSubscription_601985(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_601984(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601986 = query.getOrDefault("Action")
  valid_601986 = validateParameter(valid_601986, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_601986 != nil:
    section.add "Action", valid_601986
  var valid_601987 = query.getOrDefault("Version")
  valid_601987 = validateParameter(valid_601987, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601987 != nil:
    section.add "Version", valid_601987
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
  var valid_601988 = header.getOrDefault("X-Amz-Signature")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Signature", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Content-Sha256", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Date")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Date", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Credential")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Credential", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Security-Token")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Security-Token", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Algorithm")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Algorithm", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-SignedHeaders", valid_601994
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_601995 = formData.getOrDefault("SubscriptionName")
  valid_601995 = validateParameter(valid_601995, JString, required = true,
                                 default = nil)
  if valid_601995 != nil:
    section.add "SubscriptionName", valid_601995
  var valid_601996 = formData.getOrDefault("SourceIdentifier")
  valid_601996 = validateParameter(valid_601996, JString, required = true,
                                 default = nil)
  if valid_601996 != nil:
    section.add "SourceIdentifier", valid_601996
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601997: Call_PostAddSourceIdentifierToSubscription_601983;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601997.validator(path, query, header, formData, body)
  let scheme = call_601997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601997.url(scheme.get, call_601997.host, call_601997.base,
                         call_601997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601997, url, valid)

proc call*(call_601998: Call_PostAddSourceIdentifierToSubscription_601983;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601999 = newJObject()
  var formData_602000 = newJObject()
  add(formData_602000, "SubscriptionName", newJString(SubscriptionName))
  add(formData_602000, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_601999, "Action", newJString(Action))
  add(query_601999, "Version", newJString(Version))
  result = call_601998.call(nil, query_601999, nil, formData_602000, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_601983(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_601984, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_601985,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_601711 = ref object of OpenApiRestCall_601373
proc url_GetAddSourceIdentifierToSubscription_601713(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_601712(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SourceIdentifier` field"
  var valid_601825 = query.getOrDefault("SourceIdentifier")
  valid_601825 = validateParameter(valid_601825, JString, required = true,
                                 default = nil)
  if valid_601825 != nil:
    section.add "SourceIdentifier", valid_601825
  var valid_601826 = query.getOrDefault("SubscriptionName")
  valid_601826 = validateParameter(valid_601826, JString, required = true,
                                 default = nil)
  if valid_601826 != nil:
    section.add "SubscriptionName", valid_601826
  var valid_601840 = query.getOrDefault("Action")
  valid_601840 = validateParameter(valid_601840, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_601840 != nil:
    section.add "Action", valid_601840
  var valid_601841 = query.getOrDefault("Version")
  valid_601841 = validateParameter(valid_601841, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601841 != nil:
    section.add "Version", valid_601841
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
  var valid_601842 = header.getOrDefault("X-Amz-Signature")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Signature", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Content-Sha256", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Date")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Date", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Credential")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Credential", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Security-Token")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Security-Token", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Algorithm")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Algorithm", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-SignedHeaders", valid_601848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601871: Call_GetAddSourceIdentifierToSubscription_601711;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601871.validator(path, query, header, formData, body)
  let scheme = call_601871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601871.url(scheme.get, call_601871.host, call_601871.base,
                         call_601871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601871, url, valid)

proc call*(call_601942: Call_GetAddSourceIdentifierToSubscription_601711;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601943 = newJObject()
  add(query_601943, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_601943, "SubscriptionName", newJString(SubscriptionName))
  add(query_601943, "Action", newJString(Action))
  add(query_601943, "Version", newJString(Version))
  result = call_601942.call(nil, query_601943, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_601711(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_601712, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_601713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_602018 = ref object of OpenApiRestCall_601373
proc url_PostAddTagsToResource_602020(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTagsToResource_602019(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602021 = query.getOrDefault("Action")
  valid_602021 = validateParameter(valid_602021, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_602021 != nil:
    section.add "Action", valid_602021
  var valid_602022 = query.getOrDefault("Version")
  valid_602022 = validateParameter(valid_602022, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602022 != nil:
    section.add "Version", valid_602022
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
  var valid_602023 = header.getOrDefault("X-Amz-Signature")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Signature", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Content-Sha256", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Date")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Date", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Credential")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Credential", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Security-Token")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Security-Token", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Algorithm")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Algorithm", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-SignedHeaders", valid_602029
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_602030 = formData.getOrDefault("Tags")
  valid_602030 = validateParameter(valid_602030, JArray, required = true, default = nil)
  if valid_602030 != nil:
    section.add "Tags", valid_602030
  var valid_602031 = formData.getOrDefault("ResourceName")
  valid_602031 = validateParameter(valid_602031, JString, required = true,
                                 default = nil)
  if valid_602031 != nil:
    section.add "ResourceName", valid_602031
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602032: Call_PostAddTagsToResource_602018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602032.validator(path, query, header, formData, body)
  let scheme = call_602032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602032.url(scheme.get, call_602032.host, call_602032.base,
                         call_602032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602032, url, valid)

proc call*(call_602033: Call_PostAddTagsToResource_602018; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-01-10"): Recallable =
  ## postAddTagsToResource
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_602034 = newJObject()
  var formData_602035 = newJObject()
  add(query_602034, "Action", newJString(Action))
  if Tags != nil:
    formData_602035.add "Tags", Tags
  add(query_602034, "Version", newJString(Version))
  add(formData_602035, "ResourceName", newJString(ResourceName))
  result = call_602033.call(nil, query_602034, nil, formData_602035, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_602018(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_602019, base: "/",
    url: url_PostAddTagsToResource_602020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_602001 = ref object of OpenApiRestCall_601373
proc url_GetAddTagsToResource_602003(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddTagsToResource_602002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_602004 = query.getOrDefault("Tags")
  valid_602004 = validateParameter(valid_602004, JArray, required = true, default = nil)
  if valid_602004 != nil:
    section.add "Tags", valid_602004
  var valid_602005 = query.getOrDefault("ResourceName")
  valid_602005 = validateParameter(valid_602005, JString, required = true,
                                 default = nil)
  if valid_602005 != nil:
    section.add "ResourceName", valid_602005
  var valid_602006 = query.getOrDefault("Action")
  valid_602006 = validateParameter(valid_602006, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_602006 != nil:
    section.add "Action", valid_602006
  var valid_602007 = query.getOrDefault("Version")
  valid_602007 = validateParameter(valid_602007, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602007 != nil:
    section.add "Version", valid_602007
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
  var valid_602008 = header.getOrDefault("X-Amz-Signature")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Signature", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Content-Sha256", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Date")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Date", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Credential")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Credential", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Security-Token")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Security-Token", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Algorithm")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Algorithm", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-SignedHeaders", valid_602014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602015: Call_GetAddTagsToResource_602001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602015.validator(path, query, header, formData, body)
  let scheme = call_602015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602015.url(scheme.get, call_602015.host, call_602015.base,
                         call_602015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602015, url, valid)

proc call*(call_602016: Call_GetAddTagsToResource_602001; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-01-10"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602017 = newJObject()
  if Tags != nil:
    query_602017.add "Tags", Tags
  add(query_602017, "ResourceName", newJString(ResourceName))
  add(query_602017, "Action", newJString(Action))
  add(query_602017, "Version", newJString(Version))
  result = call_602016.call(nil, query_602017, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_602001(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_602002, base: "/",
    url: url_GetAddTagsToResource_602003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_602056 = ref object of OpenApiRestCall_601373
proc url_PostAuthorizeDBSecurityGroupIngress_602058(protocol: Scheme; host: string;
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

proc validate_PostAuthorizeDBSecurityGroupIngress_602057(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602059 = query.getOrDefault("Action")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_602059 != nil:
    section.add "Action", valid_602059
  var valid_602060 = query.getOrDefault("Version")
  valid_602060 = validateParameter(valid_602060, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602060 != nil:
    section.add "Version", valid_602060
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
  var valid_602061 = header.getOrDefault("X-Amz-Signature")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Signature", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Content-Sha256", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Date")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Date", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Credential")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Credential", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Security-Token")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Security-Token", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Algorithm")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Algorithm", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-SignedHeaders", valid_602067
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602068 = formData.getOrDefault("DBSecurityGroupName")
  valid_602068 = validateParameter(valid_602068, JString, required = true,
                                 default = nil)
  if valid_602068 != nil:
    section.add "DBSecurityGroupName", valid_602068
  var valid_602069 = formData.getOrDefault("EC2SecurityGroupName")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "EC2SecurityGroupName", valid_602069
  var valid_602070 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_602070
  var valid_602071 = formData.getOrDefault("EC2SecurityGroupId")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "EC2SecurityGroupId", valid_602071
  var valid_602072 = formData.getOrDefault("CIDRIP")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "CIDRIP", valid_602072
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602073: Call_PostAuthorizeDBSecurityGroupIngress_602056;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602073.validator(path, query, header, formData, body)
  let scheme = call_602073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602073.url(scheme.get, call_602073.host, call_602073.base,
                         call_602073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602073, url, valid)

proc call*(call_602074: Call_PostAuthorizeDBSecurityGroupIngress_602056;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "AuthorizeDBSecurityGroupIngress";
          Version: string = "2013-01-10"): Recallable =
  ## postAuthorizeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602075 = newJObject()
  var formData_602076 = newJObject()
  add(formData_602076, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_602076, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_602076, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_602076, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_602076, "CIDRIP", newJString(CIDRIP))
  add(query_602075, "Action", newJString(Action))
  add(query_602075, "Version", newJString(Version))
  result = call_602074.call(nil, query_602075, nil, formData_602076, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_602056(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_602057, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_602058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_602036 = ref object of OpenApiRestCall_601373
proc url_GetAuthorizeDBSecurityGroupIngress_602038(protocol: Scheme; host: string;
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

proc validate_GetAuthorizeDBSecurityGroupIngress_602037(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupName: JString
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupId: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   CIDRIP: JString
  section = newJObject()
  var valid_602039 = query.getOrDefault("EC2SecurityGroupName")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "EC2SecurityGroupName", valid_602039
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602040 = query.getOrDefault("DBSecurityGroupName")
  valid_602040 = validateParameter(valid_602040, JString, required = true,
                                 default = nil)
  if valid_602040 != nil:
    section.add "DBSecurityGroupName", valid_602040
  var valid_602041 = query.getOrDefault("EC2SecurityGroupId")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "EC2SecurityGroupId", valid_602041
  var valid_602042 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_602042
  var valid_602043 = query.getOrDefault("Action")
  valid_602043 = validateParameter(valid_602043, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_602043 != nil:
    section.add "Action", valid_602043
  var valid_602044 = query.getOrDefault("Version")
  valid_602044 = validateParameter(valid_602044, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602044 != nil:
    section.add "Version", valid_602044
  var valid_602045 = query.getOrDefault("CIDRIP")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "CIDRIP", valid_602045
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
  var valid_602046 = header.getOrDefault("X-Amz-Signature")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Signature", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Content-Sha256", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Date")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Date", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Credential")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Credential", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Security-Token")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Security-Token", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Algorithm")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Algorithm", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-SignedHeaders", valid_602052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_GetAuthorizeDBSecurityGroupIngress_602036;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_GetAuthorizeDBSecurityGroupIngress_602036;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "AuthorizeDBSecurityGroupIngress";
          Version: string = "2013-01-10"; CIDRIP: string = ""): Recallable =
  ## getAuthorizeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_602055 = newJObject()
  add(query_602055, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_602055, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602055, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_602055, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_602055, "Action", newJString(Action))
  add(query_602055, "Version", newJString(Version))
  add(query_602055, "CIDRIP", newJString(CIDRIP))
  result = call_602054.call(nil, query_602055, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_602036(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_602037, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_602038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_602094 = ref object of OpenApiRestCall_601373
proc url_PostCopyDBSnapshot_602096(protocol: Scheme; host: string; base: string;
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

proc validate_PostCopyDBSnapshot_602095(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602097 = query.getOrDefault("Action")
  valid_602097 = validateParameter(valid_602097, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_602097 != nil:
    section.add "Action", valid_602097
  var valid_602098 = query.getOrDefault("Version")
  valid_602098 = validateParameter(valid_602098, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602098 != nil:
    section.add "Version", valid_602098
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
  var valid_602099 = header.getOrDefault("X-Amz-Signature")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Signature", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Content-Sha256", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Date")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Date", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Credential")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Credential", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Security-Token")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Security-Token", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Algorithm")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Algorithm", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-SignedHeaders", valid_602105
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_602106 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_602106 = validateParameter(valid_602106, JString, required = true,
                                 default = nil)
  if valid_602106 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_602106
  var valid_602107 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_602107 = validateParameter(valid_602107, JString, required = true,
                                 default = nil)
  if valid_602107 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_602107
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602108: Call_PostCopyDBSnapshot_602094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602108.validator(path, query, header, formData, body)
  let scheme = call_602108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602108.url(scheme.get, call_602108.host, call_602108.base,
                         call_602108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602108, url, valid)

proc call*(call_602109: Call_PostCopyDBSnapshot_602094;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_602110 = newJObject()
  var formData_602111 = newJObject()
  add(formData_602111, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_602110, "Action", newJString(Action))
  add(formData_602111, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_602110, "Version", newJString(Version))
  result = call_602109.call(nil, query_602110, nil, formData_602111, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_602094(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_602095, base: "/",
    url: url_PostCopyDBSnapshot_602096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_602077 = ref object of OpenApiRestCall_601373
proc url_GetCopyDBSnapshot_602079(protocol: Scheme; host: string; base: string;
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

proc validate_GetCopyDBSnapshot_602078(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_602080 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = nil)
  if valid_602080 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_602080
  var valid_602081 = query.getOrDefault("Action")
  valid_602081 = validateParameter(valid_602081, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_602081 != nil:
    section.add "Action", valid_602081
  var valid_602082 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = nil)
  if valid_602082 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_602082
  var valid_602083 = query.getOrDefault("Version")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602083 != nil:
    section.add "Version", valid_602083
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
  var valid_602084 = header.getOrDefault("X-Amz-Signature")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Signature", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Content-Sha256", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Date")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Date", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Credential")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Credential", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Security-Token")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Security-Token", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Algorithm")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Algorithm", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-SignedHeaders", valid_602090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602091: Call_GetCopyDBSnapshot_602077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602091.validator(path, query, header, formData, body)
  let scheme = call_602091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602091.url(scheme.get, call_602091.host, call_602091.base,
                         call_602091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602091, url, valid)

proc call*(call_602092: Call_GetCopyDBSnapshot_602077;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_602093 = newJObject()
  add(query_602093, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_602093, "Action", newJString(Action))
  add(query_602093, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_602093, "Version", newJString(Version))
  result = call_602092.call(nil, query_602093, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_602077(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_602078,
    base: "/", url: url_GetCopyDBSnapshot_602079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_602151 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBInstance_602153(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBInstance_602152(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602154 = query.getOrDefault("Action")
  valid_602154 = validateParameter(valid_602154, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_602154 != nil:
    section.add "Action", valid_602154
  var valid_602155 = query.getOrDefault("Version")
  valid_602155 = validateParameter(valid_602155, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602155 != nil:
    section.add "Version", valid_602155
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
  var valid_602156 = header.getOrDefault("X-Amz-Signature")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Signature", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Content-Sha256", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Date")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Date", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Credential")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Credential", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Security-Token")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Security-Token", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Algorithm")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Algorithm", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-SignedHeaders", valid_602162
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredMaintenanceWindow: JString
  ##   DBInstanceClass: JString (required)
  ##   Port: JInt
  ##   PreferredBackupWindow: JString
  ##   MasterUserPassword: JString (required)
  ##   MultiAZ: JBool
  ##   MasterUsername: JString (required)
  ##   DBParameterGroupName: JString
  ##   EngineVersion: JString
  ##   VpcSecurityGroupIds: JArray
  ##   AvailabilityZone: JString
  ##   BackupRetentionPeriod: JInt
  ##   Engine: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   CharacterSetName: JString
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: JInt (required)
  section = newJObject()
  var valid_602163 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "PreferredMaintenanceWindow", valid_602163
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_602164 = formData.getOrDefault("DBInstanceClass")
  valid_602164 = validateParameter(valid_602164, JString, required = true,
                                 default = nil)
  if valid_602164 != nil:
    section.add "DBInstanceClass", valid_602164
  var valid_602165 = formData.getOrDefault("Port")
  valid_602165 = validateParameter(valid_602165, JInt, required = false, default = nil)
  if valid_602165 != nil:
    section.add "Port", valid_602165
  var valid_602166 = formData.getOrDefault("PreferredBackupWindow")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "PreferredBackupWindow", valid_602166
  var valid_602167 = formData.getOrDefault("MasterUserPassword")
  valid_602167 = validateParameter(valid_602167, JString, required = true,
                                 default = nil)
  if valid_602167 != nil:
    section.add "MasterUserPassword", valid_602167
  var valid_602168 = formData.getOrDefault("MultiAZ")
  valid_602168 = validateParameter(valid_602168, JBool, required = false, default = nil)
  if valid_602168 != nil:
    section.add "MultiAZ", valid_602168
  var valid_602169 = formData.getOrDefault("MasterUsername")
  valid_602169 = validateParameter(valid_602169, JString, required = true,
                                 default = nil)
  if valid_602169 != nil:
    section.add "MasterUsername", valid_602169
  var valid_602170 = formData.getOrDefault("DBParameterGroupName")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "DBParameterGroupName", valid_602170
  var valid_602171 = formData.getOrDefault("EngineVersion")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "EngineVersion", valid_602171
  var valid_602172 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602172 = validateParameter(valid_602172, JArray, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "VpcSecurityGroupIds", valid_602172
  var valid_602173 = formData.getOrDefault("AvailabilityZone")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "AvailabilityZone", valid_602173
  var valid_602174 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602174 = validateParameter(valid_602174, JInt, required = false, default = nil)
  if valid_602174 != nil:
    section.add "BackupRetentionPeriod", valid_602174
  var valid_602175 = formData.getOrDefault("Engine")
  valid_602175 = validateParameter(valid_602175, JString, required = true,
                                 default = nil)
  if valid_602175 != nil:
    section.add "Engine", valid_602175
  var valid_602176 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602176 = validateParameter(valid_602176, JBool, required = false, default = nil)
  if valid_602176 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602176
  var valid_602177 = formData.getOrDefault("DBName")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "DBName", valid_602177
  var valid_602178 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602178 = validateParameter(valid_602178, JString, required = true,
                                 default = nil)
  if valid_602178 != nil:
    section.add "DBInstanceIdentifier", valid_602178
  var valid_602179 = formData.getOrDefault("Iops")
  valid_602179 = validateParameter(valid_602179, JInt, required = false, default = nil)
  if valid_602179 != nil:
    section.add "Iops", valid_602179
  var valid_602180 = formData.getOrDefault("PubliclyAccessible")
  valid_602180 = validateParameter(valid_602180, JBool, required = false, default = nil)
  if valid_602180 != nil:
    section.add "PubliclyAccessible", valid_602180
  var valid_602181 = formData.getOrDefault("LicenseModel")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "LicenseModel", valid_602181
  var valid_602182 = formData.getOrDefault("DBSubnetGroupName")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "DBSubnetGroupName", valid_602182
  var valid_602183 = formData.getOrDefault("OptionGroupName")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "OptionGroupName", valid_602183
  var valid_602184 = formData.getOrDefault("CharacterSetName")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "CharacterSetName", valid_602184
  var valid_602185 = formData.getOrDefault("DBSecurityGroups")
  valid_602185 = validateParameter(valid_602185, JArray, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "DBSecurityGroups", valid_602185
  var valid_602186 = formData.getOrDefault("AllocatedStorage")
  valid_602186 = validateParameter(valid_602186, JInt, required = true, default = nil)
  if valid_602186 != nil:
    section.add "AllocatedStorage", valid_602186
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602187: Call_PostCreateDBInstance_602151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602187.validator(path, query, header, formData, body)
  let scheme = call_602187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602187.url(scheme.get, call_602187.host, call_602187.base,
                         call_602187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602187, url, valid)

proc call*(call_602188: Call_PostCreateDBInstance_602151; DBInstanceClass: string;
          MasterUserPassword: string; MasterUsername: string; Engine: string;
          DBInstanceIdentifier: string; AllocatedStorage: int;
          PreferredMaintenanceWindow: string = ""; Port: int = 0;
          PreferredBackupWindow: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          BackupRetentionPeriod: int = 0; AutoMinorVersionUpgrade: bool = false;
          DBName: string = ""; Iops: int = 0; PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstance"; LicenseModel: string = "";
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          CharacterSetName: string = ""; Version: string = "2013-01-10";
          DBSecurityGroups: JsonNode = nil): Recallable =
  ## postCreateDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceClass: string (required)
  ##   Port: int
  ##   PreferredBackupWindow: string
  ##   MasterUserPassword: string (required)
  ##   MultiAZ: bool
  ##   MasterUsername: string (required)
  ##   DBParameterGroupName: string
  ##   EngineVersion: string
  ##   VpcSecurityGroupIds: JArray
  ##   AvailabilityZone: string
  ##   BackupRetentionPeriod: int
  ##   Engine: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   CharacterSetName: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: int (required)
  var query_602189 = newJObject()
  var formData_602190 = newJObject()
  add(formData_602190, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_602190, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602190, "Port", newJInt(Port))
  add(formData_602190, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602190, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602190, "MultiAZ", newJBool(MultiAZ))
  add(formData_602190, "MasterUsername", newJString(MasterUsername))
  add(formData_602190, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602190, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_602190.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602190, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602190, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602190, "Engine", newJString(Engine))
  add(formData_602190, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602190, "DBName", newJString(DBName))
  add(formData_602190, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602190, "Iops", newJInt(Iops))
  add(formData_602190, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602189, "Action", newJString(Action))
  add(formData_602190, "LicenseModel", newJString(LicenseModel))
  add(formData_602190, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602190, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602190, "CharacterSetName", newJString(CharacterSetName))
  add(query_602189, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_602190.add "DBSecurityGroups", DBSecurityGroups
  add(formData_602190, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_602188.call(nil, query_602189, nil, formData_602190, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_602151(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_602152, base: "/",
    url: url_PostCreateDBInstance_602153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_602112 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBInstance_602114(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBInstance_602113(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   DBName: JString
  ##   Engine: JString (required)
  ##   DBParameterGroupName: JString
  ##   CharacterSetName: JString
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   MasterUsername: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   DBSecurityGroups: JArray
  ##   Port: JInt
  ##   VpcSecurityGroupIds: JArray
  ##   MasterUserPassword: JString (required)
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   AllocatedStorage: JInt (required)
  ##   DBInstanceClass: JString (required)
  ##   PreferredMaintenanceWindow: JString
  ##   PreferredBackupWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Version` field"
  var valid_602115 = query.getOrDefault("Version")
  valid_602115 = validateParameter(valid_602115, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602115 != nil:
    section.add "Version", valid_602115
  var valid_602116 = query.getOrDefault("DBName")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "DBName", valid_602116
  var valid_602117 = query.getOrDefault("Engine")
  valid_602117 = validateParameter(valid_602117, JString, required = true,
                                 default = nil)
  if valid_602117 != nil:
    section.add "Engine", valid_602117
  var valid_602118 = query.getOrDefault("DBParameterGroupName")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "DBParameterGroupName", valid_602118
  var valid_602119 = query.getOrDefault("CharacterSetName")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "CharacterSetName", valid_602119
  var valid_602120 = query.getOrDefault("LicenseModel")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "LicenseModel", valid_602120
  var valid_602121 = query.getOrDefault("DBInstanceIdentifier")
  valid_602121 = validateParameter(valid_602121, JString, required = true,
                                 default = nil)
  if valid_602121 != nil:
    section.add "DBInstanceIdentifier", valid_602121
  var valid_602122 = query.getOrDefault("MasterUsername")
  valid_602122 = validateParameter(valid_602122, JString, required = true,
                                 default = nil)
  if valid_602122 != nil:
    section.add "MasterUsername", valid_602122
  var valid_602123 = query.getOrDefault("BackupRetentionPeriod")
  valid_602123 = validateParameter(valid_602123, JInt, required = false, default = nil)
  if valid_602123 != nil:
    section.add "BackupRetentionPeriod", valid_602123
  var valid_602124 = query.getOrDefault("EngineVersion")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "EngineVersion", valid_602124
  var valid_602125 = query.getOrDefault("Action")
  valid_602125 = validateParameter(valid_602125, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_602125 != nil:
    section.add "Action", valid_602125
  var valid_602126 = query.getOrDefault("MultiAZ")
  valid_602126 = validateParameter(valid_602126, JBool, required = false, default = nil)
  if valid_602126 != nil:
    section.add "MultiAZ", valid_602126
  var valid_602127 = query.getOrDefault("DBSecurityGroups")
  valid_602127 = validateParameter(valid_602127, JArray, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "DBSecurityGroups", valid_602127
  var valid_602128 = query.getOrDefault("Port")
  valid_602128 = validateParameter(valid_602128, JInt, required = false, default = nil)
  if valid_602128 != nil:
    section.add "Port", valid_602128
  var valid_602129 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602129 = validateParameter(valid_602129, JArray, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "VpcSecurityGroupIds", valid_602129
  var valid_602130 = query.getOrDefault("MasterUserPassword")
  valid_602130 = validateParameter(valid_602130, JString, required = true,
                                 default = nil)
  if valid_602130 != nil:
    section.add "MasterUserPassword", valid_602130
  var valid_602131 = query.getOrDefault("AvailabilityZone")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "AvailabilityZone", valid_602131
  var valid_602132 = query.getOrDefault("OptionGroupName")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "OptionGroupName", valid_602132
  var valid_602133 = query.getOrDefault("DBSubnetGroupName")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "DBSubnetGroupName", valid_602133
  var valid_602134 = query.getOrDefault("AllocatedStorage")
  valid_602134 = validateParameter(valid_602134, JInt, required = true, default = nil)
  if valid_602134 != nil:
    section.add "AllocatedStorage", valid_602134
  var valid_602135 = query.getOrDefault("DBInstanceClass")
  valid_602135 = validateParameter(valid_602135, JString, required = true,
                                 default = nil)
  if valid_602135 != nil:
    section.add "DBInstanceClass", valid_602135
  var valid_602136 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "PreferredMaintenanceWindow", valid_602136
  var valid_602137 = query.getOrDefault("PreferredBackupWindow")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "PreferredBackupWindow", valid_602137
  var valid_602138 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602138 = validateParameter(valid_602138, JBool, required = false, default = nil)
  if valid_602138 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602138
  var valid_602139 = query.getOrDefault("Iops")
  valid_602139 = validateParameter(valid_602139, JInt, required = false, default = nil)
  if valid_602139 != nil:
    section.add "Iops", valid_602139
  var valid_602140 = query.getOrDefault("PubliclyAccessible")
  valid_602140 = validateParameter(valid_602140, JBool, required = false, default = nil)
  if valid_602140 != nil:
    section.add "PubliclyAccessible", valid_602140
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
  var valid_602141 = header.getOrDefault("X-Amz-Signature")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Signature", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Content-Sha256", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Date")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Date", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Credential")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Credential", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Security-Token")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Security-Token", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Algorithm")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Algorithm", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-SignedHeaders", valid_602147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602148: Call_GetCreateDBInstance_602112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602148.validator(path, query, header, formData, body)
  let scheme = call_602148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602148.url(scheme.get, call_602148.host, call_602148.base,
                         call_602148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602148, url, valid)

proc call*(call_602149: Call_GetCreateDBInstance_602112; Engine: string;
          DBInstanceIdentifier: string; MasterUsername: string;
          MasterUserPassword: string; AllocatedStorage: int;
          DBInstanceClass: string; Version: string = "2013-01-10";
          DBName: string = ""; DBParameterGroupName: string = "";
          CharacterSetName: string = ""; LicenseModel: string = "";
          BackupRetentionPeriod: int = 0; EngineVersion: string = "";
          Action: string = "CreateDBInstance"; MultiAZ: bool = false;
          DBSecurityGroups: JsonNode = nil; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          OptionGroupName: string = ""; DBSubnetGroupName: string = "";
          PreferredMaintenanceWindow: string = "";
          PreferredBackupWindow: string = ""; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0; PubliclyAccessible: bool = false): Recallable =
  ## getCreateDBInstance
  ##   Version: string (required)
  ##   DBName: string
  ##   Engine: string (required)
  ##   DBParameterGroupName: string
  ##   CharacterSetName: string
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   MasterUsername: string (required)
  ##   BackupRetentionPeriod: int
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   DBSecurityGroups: JArray
  ##   Port: int
  ##   VpcSecurityGroupIds: JArray
  ##   MasterUserPassword: string (required)
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   AllocatedStorage: int (required)
  ##   DBInstanceClass: string (required)
  ##   PreferredMaintenanceWindow: string
  ##   PreferredBackupWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  ##   PubliclyAccessible: bool
  var query_602150 = newJObject()
  add(query_602150, "Version", newJString(Version))
  add(query_602150, "DBName", newJString(DBName))
  add(query_602150, "Engine", newJString(Engine))
  add(query_602150, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602150, "CharacterSetName", newJString(CharacterSetName))
  add(query_602150, "LicenseModel", newJString(LicenseModel))
  add(query_602150, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602150, "MasterUsername", newJString(MasterUsername))
  add(query_602150, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602150, "EngineVersion", newJString(EngineVersion))
  add(query_602150, "Action", newJString(Action))
  add(query_602150, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_602150.add "DBSecurityGroups", DBSecurityGroups
  add(query_602150, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_602150.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_602150, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_602150, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602150, "OptionGroupName", newJString(OptionGroupName))
  add(query_602150, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602150, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_602150, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602150, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602150, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602150, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602150, "Iops", newJInt(Iops))
  add(query_602150, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_602149.call(nil, query_602150, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_602112(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_602113, base: "/",
    url: url_GetCreateDBInstance_602114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_602215 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBInstanceReadReplica_602217(protocol: Scheme; host: string;
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

proc validate_PostCreateDBInstanceReadReplica_602216(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602218 = query.getOrDefault("Action")
  valid_602218 = validateParameter(valid_602218, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_602218 != nil:
    section.add "Action", valid_602218
  var valid_602219 = query.getOrDefault("Version")
  valid_602219 = validateParameter(valid_602219, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602219 != nil:
    section.add "Version", valid_602219
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
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_602227 = formData.getOrDefault("Port")
  valid_602227 = validateParameter(valid_602227, JInt, required = false, default = nil)
  if valid_602227 != nil:
    section.add "Port", valid_602227
  var valid_602228 = formData.getOrDefault("DBInstanceClass")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "DBInstanceClass", valid_602228
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_602229 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_602229 = validateParameter(valid_602229, JString, required = true,
                                 default = nil)
  if valid_602229 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602229
  var valid_602230 = formData.getOrDefault("AvailabilityZone")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "AvailabilityZone", valid_602230
  var valid_602231 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602231 = validateParameter(valid_602231, JBool, required = false, default = nil)
  if valid_602231 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602231
  var valid_602232 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602232 = validateParameter(valid_602232, JString, required = true,
                                 default = nil)
  if valid_602232 != nil:
    section.add "DBInstanceIdentifier", valid_602232
  var valid_602233 = formData.getOrDefault("Iops")
  valid_602233 = validateParameter(valid_602233, JInt, required = false, default = nil)
  if valid_602233 != nil:
    section.add "Iops", valid_602233
  var valid_602234 = formData.getOrDefault("PubliclyAccessible")
  valid_602234 = validateParameter(valid_602234, JBool, required = false, default = nil)
  if valid_602234 != nil:
    section.add "PubliclyAccessible", valid_602234
  var valid_602235 = formData.getOrDefault("OptionGroupName")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "OptionGroupName", valid_602235
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602236: Call_PostCreateDBInstanceReadReplica_602215;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602236.validator(path, query, header, formData, body)
  let scheme = call_602236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602236.url(scheme.get, call_602236.host, call_602236.base,
                         call_602236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602236, url, valid)

proc call*(call_602237: Call_PostCreateDBInstanceReadReplica_602215;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; AvailabilityZone: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstanceReadReplica";
          OptionGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBInstanceReadReplica
  ##   Port: int
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   AutoMinorVersionUpgrade: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_602238 = newJObject()
  var formData_602239 = newJObject()
  add(formData_602239, "Port", newJInt(Port))
  add(formData_602239, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602239, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_602239, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602239, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602239, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602239, "Iops", newJInt(Iops))
  add(formData_602239, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602238, "Action", newJString(Action))
  add(formData_602239, "OptionGroupName", newJString(OptionGroupName))
  add(query_602238, "Version", newJString(Version))
  result = call_602237.call(nil, query_602238, nil, formData_602239, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_602215(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_602216, base: "/",
    url: url_PostCreateDBInstanceReadReplica_602217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_602191 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBInstanceReadReplica_602193(protocol: Scheme; host: string;
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

proc validate_GetCreateDBInstanceReadReplica_602192(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   Port: JInt
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602194 = query.getOrDefault("DBInstanceIdentifier")
  valid_602194 = validateParameter(valid_602194, JString, required = true,
                                 default = nil)
  if valid_602194 != nil:
    section.add "DBInstanceIdentifier", valid_602194
  var valid_602195 = query.getOrDefault("Action")
  valid_602195 = validateParameter(valid_602195, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_602195 != nil:
    section.add "Action", valid_602195
  var valid_602196 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_602196 = validateParameter(valid_602196, JString, required = true,
                                 default = nil)
  if valid_602196 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602196
  var valid_602197 = query.getOrDefault("Port")
  valid_602197 = validateParameter(valid_602197, JInt, required = false, default = nil)
  if valid_602197 != nil:
    section.add "Port", valid_602197
  var valid_602198 = query.getOrDefault("AvailabilityZone")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "AvailabilityZone", valid_602198
  var valid_602199 = query.getOrDefault("OptionGroupName")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "OptionGroupName", valid_602199
  var valid_602200 = query.getOrDefault("Version")
  valid_602200 = validateParameter(valid_602200, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602200 != nil:
    section.add "Version", valid_602200
  var valid_602201 = query.getOrDefault("DBInstanceClass")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "DBInstanceClass", valid_602201
  var valid_602202 = query.getOrDefault("PubliclyAccessible")
  valid_602202 = validateParameter(valid_602202, JBool, required = false, default = nil)
  if valid_602202 != nil:
    section.add "PubliclyAccessible", valid_602202
  var valid_602203 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602203 = validateParameter(valid_602203, JBool, required = false, default = nil)
  if valid_602203 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602203
  var valid_602204 = query.getOrDefault("Iops")
  valid_602204 = validateParameter(valid_602204, JInt, required = false, default = nil)
  if valid_602204 != nil:
    section.add "Iops", valid_602204
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
  var valid_602205 = header.getOrDefault("X-Amz-Signature")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Signature", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Content-Sha256", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Date")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Date", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Credential")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Credential", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Security-Token")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Security-Token", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Algorithm")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Algorithm", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-SignedHeaders", valid_602211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602212: Call_GetCreateDBInstanceReadReplica_602191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602212.validator(path, query, header, formData, body)
  let scheme = call_602212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602212.url(scheme.get, call_602212.host, call_602212.base,
                         call_602212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602212, url, valid)

proc call*(call_602213: Call_GetCreateDBInstanceReadReplica_602191;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Action: string = "CreateDBInstanceReadReplica"; Port: int = 0;
          AvailabilityZone: string = ""; OptionGroupName: string = "";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBInstanceIdentifier: string (required)
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_602214 = newJObject()
  add(query_602214, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602214, "Action", newJString(Action))
  add(query_602214, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_602214, "Port", newJInt(Port))
  add(query_602214, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602214, "OptionGroupName", newJString(OptionGroupName))
  add(query_602214, "Version", newJString(Version))
  add(query_602214, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602214, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602214, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602214, "Iops", newJInt(Iops))
  result = call_602213.call(nil, query_602214, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_602191(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_602192, base: "/",
    url: url_GetCreateDBInstanceReadReplica_602193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_602258 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBParameterGroup_602260(protocol: Scheme; host: string;
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

proc validate_PostCreateDBParameterGroup_602259(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602261 = query.getOrDefault("Action")
  valid_602261 = validateParameter(valid_602261, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_602261 != nil:
    section.add "Action", valid_602261
  var valid_602262 = query.getOrDefault("Version")
  valid_602262 = validateParameter(valid_602262, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602262 != nil:
    section.add "Version", valid_602262
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
  var valid_602263 = header.getOrDefault("X-Amz-Signature")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Signature", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Content-Sha256", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Date")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Date", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Credential")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Credential", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Security-Token")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Security-Token", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Algorithm")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Algorithm", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-SignedHeaders", valid_602269
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_602270 = formData.getOrDefault("Description")
  valid_602270 = validateParameter(valid_602270, JString, required = true,
                                 default = nil)
  if valid_602270 != nil:
    section.add "Description", valid_602270
  var valid_602271 = formData.getOrDefault("DBParameterGroupName")
  valid_602271 = validateParameter(valid_602271, JString, required = true,
                                 default = nil)
  if valid_602271 != nil:
    section.add "DBParameterGroupName", valid_602271
  var valid_602272 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602272 = validateParameter(valid_602272, JString, required = true,
                                 default = nil)
  if valid_602272 != nil:
    section.add "DBParameterGroupFamily", valid_602272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602273: Call_PostCreateDBParameterGroup_602258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602273.validator(path, query, header, formData, body)
  let scheme = call_602273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602273.url(scheme.get, call_602273.host, call_602273.base,
                         call_602273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602273, url, valid)

proc call*(call_602274: Call_PostCreateDBParameterGroup_602258;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_602275 = newJObject()
  var formData_602276 = newJObject()
  add(formData_602276, "Description", newJString(Description))
  add(formData_602276, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602275, "Action", newJString(Action))
  add(query_602275, "Version", newJString(Version))
  add(formData_602276, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_602274.call(nil, query_602275, nil, formData_602276, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_602258(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_602259, base: "/",
    url: url_PostCreateDBParameterGroup_602260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_602240 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBParameterGroup_602242(protocol: Scheme; host: string;
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

proc validate_GetCreateDBParameterGroup_602241(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupFamily: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Description: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602243 = query.getOrDefault("DBParameterGroupFamily")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = nil)
  if valid_602243 != nil:
    section.add "DBParameterGroupFamily", valid_602243
  var valid_602244 = query.getOrDefault("DBParameterGroupName")
  valid_602244 = validateParameter(valid_602244, JString, required = true,
                                 default = nil)
  if valid_602244 != nil:
    section.add "DBParameterGroupName", valid_602244
  var valid_602245 = query.getOrDefault("Action")
  valid_602245 = validateParameter(valid_602245, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_602245 != nil:
    section.add "Action", valid_602245
  var valid_602246 = query.getOrDefault("Description")
  valid_602246 = validateParameter(valid_602246, JString, required = true,
                                 default = nil)
  if valid_602246 != nil:
    section.add "Description", valid_602246
  var valid_602247 = query.getOrDefault("Version")
  valid_602247 = validateParameter(valid_602247, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602247 != nil:
    section.add "Version", valid_602247
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
  var valid_602248 = header.getOrDefault("X-Amz-Signature")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Signature", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Content-Sha256", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Date")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Date", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Credential")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Credential", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Security-Token")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Security-Token", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Algorithm")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Algorithm", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-SignedHeaders", valid_602254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602255: Call_GetCreateDBParameterGroup_602240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602255.validator(path, query, header, formData, body)
  let scheme = call_602255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602255.url(scheme.get, call_602255.host, call_602255.base,
                         call_602255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602255, url, valid)

proc call*(call_602256: Call_GetCreateDBParameterGroup_602240;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_602257 = newJObject()
  add(query_602257, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602257, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602257, "Action", newJString(Action))
  add(query_602257, "Description", newJString(Description))
  add(query_602257, "Version", newJString(Version))
  result = call_602256.call(nil, query_602257, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_602240(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_602241, base: "/",
    url: url_GetCreateDBParameterGroup_602242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_602294 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBSecurityGroup_602296(protocol: Scheme; host: string;
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

proc validate_PostCreateDBSecurityGroup_602295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602297 = query.getOrDefault("Action")
  valid_602297 = validateParameter(valid_602297, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_602297 != nil:
    section.add "Action", valid_602297
  var valid_602298 = query.getOrDefault("Version")
  valid_602298 = validateParameter(valid_602298, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602298 != nil:
    section.add "Version", valid_602298
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
  var valid_602299 = header.getOrDefault("X-Amz-Signature")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Signature", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Content-Sha256", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Date")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Date", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Credential")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Credential", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Security-Token")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Security-Token", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Algorithm")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Algorithm", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-SignedHeaders", valid_602305
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_602306 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_602306 = validateParameter(valid_602306, JString, required = true,
                                 default = nil)
  if valid_602306 != nil:
    section.add "DBSecurityGroupDescription", valid_602306
  var valid_602307 = formData.getOrDefault("DBSecurityGroupName")
  valid_602307 = validateParameter(valid_602307, JString, required = true,
                                 default = nil)
  if valid_602307 != nil:
    section.add "DBSecurityGroupName", valid_602307
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602308: Call_PostCreateDBSecurityGroup_602294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602308.validator(path, query, header, formData, body)
  let scheme = call_602308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602308.url(scheme.get, call_602308.host, call_602308.base,
                         call_602308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602308, url, valid)

proc call*(call_602309: Call_PostCreateDBSecurityGroup_602294;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602310 = newJObject()
  var formData_602311 = newJObject()
  add(formData_602311, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_602311, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602310, "Action", newJString(Action))
  add(query_602310, "Version", newJString(Version))
  result = call_602309.call(nil, query_602310, nil, formData_602311, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_602294(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_602295, base: "/",
    url: url_PostCreateDBSecurityGroup_602296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_602277 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBSecurityGroup_602279(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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

proc validate_GetCreateDBSecurityGroup_602278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602280 = query.getOrDefault("DBSecurityGroupName")
  valid_602280 = validateParameter(valid_602280, JString, required = true,
                                 default = nil)
  if valid_602280 != nil:
    section.add "DBSecurityGroupName", valid_602280
  var valid_602281 = query.getOrDefault("DBSecurityGroupDescription")
  valid_602281 = validateParameter(valid_602281, JString, required = true,
                                 default = nil)
  if valid_602281 != nil:
    section.add "DBSecurityGroupDescription", valid_602281
  var valid_602282 = query.getOrDefault("Action")
  valid_602282 = validateParameter(valid_602282, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_602282 != nil:
    section.add "Action", valid_602282
  var valid_602283 = query.getOrDefault("Version")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602283 != nil:
    section.add "Version", valid_602283
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
  var valid_602284 = header.getOrDefault("X-Amz-Signature")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Signature", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Content-Sha256", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Date")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Date", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Credential")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Credential", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Security-Token")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Security-Token", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Algorithm")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Algorithm", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-SignedHeaders", valid_602290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602291: Call_GetCreateDBSecurityGroup_602277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602291.validator(path, query, header, formData, body)
  let scheme = call_602291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602291.url(scheme.get, call_602291.host, call_602291.base,
                         call_602291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602291, url, valid)

proc call*(call_602292: Call_GetCreateDBSecurityGroup_602277;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602293 = newJObject()
  add(query_602293, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602293, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_602293, "Action", newJString(Action))
  add(query_602293, "Version", newJString(Version))
  result = call_602292.call(nil, query_602293, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_602277(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_602278, base: "/",
    url: url_GetCreateDBSecurityGroup_602279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_602329 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBSnapshot_602331(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSnapshot_602330(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602332 = query.getOrDefault("Action")
  valid_602332 = validateParameter(valid_602332, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_602332 != nil:
    section.add "Action", valid_602332
  var valid_602333 = query.getOrDefault("Version")
  valid_602333 = validateParameter(valid_602333, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602333 != nil:
    section.add "Version", valid_602333
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
  var valid_602334 = header.getOrDefault("X-Amz-Signature")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Signature", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Content-Sha256", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Date")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Date", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Credential")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Credential", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Security-Token")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Security-Token", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Algorithm")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Algorithm", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-SignedHeaders", valid_602340
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602341 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602341 = validateParameter(valid_602341, JString, required = true,
                                 default = nil)
  if valid_602341 != nil:
    section.add "DBInstanceIdentifier", valid_602341
  var valid_602342 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602342 = validateParameter(valid_602342, JString, required = true,
                                 default = nil)
  if valid_602342 != nil:
    section.add "DBSnapshotIdentifier", valid_602342
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602343: Call_PostCreateDBSnapshot_602329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602343.validator(path, query, header, formData, body)
  let scheme = call_602343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602343.url(scheme.get, call_602343.host, call_602343.base,
                         call_602343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602343, url, valid)

proc call*(call_602344: Call_PostCreateDBSnapshot_602329;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602345 = newJObject()
  var formData_602346 = newJObject()
  add(formData_602346, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602346, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602345, "Action", newJString(Action))
  add(query_602345, "Version", newJString(Version))
  result = call_602344.call(nil, query_602345, nil, formData_602346, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_602329(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_602330, base: "/",
    url: url_PostCreateDBSnapshot_602331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_602312 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBSnapshot_602314(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSnapshot_602313(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602315 = query.getOrDefault("DBInstanceIdentifier")
  valid_602315 = validateParameter(valid_602315, JString, required = true,
                                 default = nil)
  if valid_602315 != nil:
    section.add "DBInstanceIdentifier", valid_602315
  var valid_602316 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602316 = validateParameter(valid_602316, JString, required = true,
                                 default = nil)
  if valid_602316 != nil:
    section.add "DBSnapshotIdentifier", valid_602316
  var valid_602317 = query.getOrDefault("Action")
  valid_602317 = validateParameter(valid_602317, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_602317 != nil:
    section.add "Action", valid_602317
  var valid_602318 = query.getOrDefault("Version")
  valid_602318 = validateParameter(valid_602318, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602318 != nil:
    section.add "Version", valid_602318
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
  var valid_602319 = header.getOrDefault("X-Amz-Signature")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Signature", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Content-Sha256", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Date")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Date", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Credential")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Credential", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Security-Token")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Security-Token", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Algorithm")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Algorithm", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-SignedHeaders", valid_602325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602326: Call_GetCreateDBSnapshot_602312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602326.validator(path, query, header, formData, body)
  let scheme = call_602326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602326.url(scheme.get, call_602326.host, call_602326.base,
                         call_602326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602326, url, valid)

proc call*(call_602327: Call_GetCreateDBSnapshot_602312;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602328 = newJObject()
  add(query_602328, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602328, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602328, "Action", newJString(Action))
  add(query_602328, "Version", newJString(Version))
  result = call_602327.call(nil, query_602328, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_602312(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_602313, base: "/",
    url: url_GetCreateDBSnapshot_602314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_602365 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBSubnetGroup_602367(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_602366(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602368 = query.getOrDefault("Action")
  valid_602368 = validateParameter(valid_602368, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_602368 != nil:
    section.add "Action", valid_602368
  var valid_602369 = query.getOrDefault("Version")
  valid_602369 = validateParameter(valid_602369, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602369 != nil:
    section.add "Version", valid_602369
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
  var valid_602370 = header.getOrDefault("X-Amz-Signature")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Signature", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Content-Sha256", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Date")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Date", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Credential")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Credential", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Security-Token")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Security-Token", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Algorithm")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Algorithm", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-SignedHeaders", valid_602376
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_602377 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602377 = validateParameter(valid_602377, JString, required = true,
                                 default = nil)
  if valid_602377 != nil:
    section.add "DBSubnetGroupDescription", valid_602377
  var valid_602378 = formData.getOrDefault("DBSubnetGroupName")
  valid_602378 = validateParameter(valid_602378, JString, required = true,
                                 default = nil)
  if valid_602378 != nil:
    section.add "DBSubnetGroupName", valid_602378
  var valid_602379 = formData.getOrDefault("SubnetIds")
  valid_602379 = validateParameter(valid_602379, JArray, required = true, default = nil)
  if valid_602379 != nil:
    section.add "SubnetIds", valid_602379
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602380: Call_PostCreateDBSubnetGroup_602365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602380.validator(path, query, header, formData, body)
  let scheme = call_602380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602380.url(scheme.get, call_602380.host, call_602380.base,
                         call_602380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602380, url, valid)

proc call*(call_602381: Call_PostCreateDBSubnetGroup_602365;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_602382 = newJObject()
  var formData_602383 = newJObject()
  add(formData_602383, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602382, "Action", newJString(Action))
  add(formData_602383, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602382, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_602383.add "SubnetIds", SubnetIds
  result = call_602381.call(nil, query_602382, nil, formData_602383, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_602365(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_602366, base: "/",
    url: url_PostCreateDBSubnetGroup_602367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_602347 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBSubnetGroup_602349(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSubnetGroup_602348(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_602350 = query.getOrDefault("SubnetIds")
  valid_602350 = validateParameter(valid_602350, JArray, required = true, default = nil)
  if valid_602350 != nil:
    section.add "SubnetIds", valid_602350
  var valid_602351 = query.getOrDefault("Action")
  valid_602351 = validateParameter(valid_602351, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_602351 != nil:
    section.add "Action", valid_602351
  var valid_602352 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602352 = validateParameter(valid_602352, JString, required = true,
                                 default = nil)
  if valid_602352 != nil:
    section.add "DBSubnetGroupDescription", valid_602352
  var valid_602353 = query.getOrDefault("DBSubnetGroupName")
  valid_602353 = validateParameter(valid_602353, JString, required = true,
                                 default = nil)
  if valid_602353 != nil:
    section.add "DBSubnetGroupName", valid_602353
  var valid_602354 = query.getOrDefault("Version")
  valid_602354 = validateParameter(valid_602354, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602354 != nil:
    section.add "Version", valid_602354
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
  var valid_602355 = header.getOrDefault("X-Amz-Signature")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Signature", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Content-Sha256", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Date")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Date", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Credential")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Credential", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Security-Token")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Security-Token", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Algorithm")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Algorithm", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-SignedHeaders", valid_602361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602362: Call_GetCreateDBSubnetGroup_602347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602362.validator(path, query, header, formData, body)
  let scheme = call_602362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602362.url(scheme.get, call_602362.host, call_602362.base,
                         call_602362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602362, url, valid)

proc call*(call_602363: Call_GetCreateDBSubnetGroup_602347; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_602364 = newJObject()
  if SubnetIds != nil:
    query_602364.add "SubnetIds", SubnetIds
  add(query_602364, "Action", newJString(Action))
  add(query_602364, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602364, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602364, "Version", newJString(Version))
  result = call_602363.call(nil, query_602364, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_602347(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_602348, base: "/",
    url: url_GetCreateDBSubnetGroup_602349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_602405 = ref object of OpenApiRestCall_601373
proc url_PostCreateEventSubscription_602407(protocol: Scheme; host: string;
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

proc validate_PostCreateEventSubscription_602406(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602408 = query.getOrDefault("Action")
  valid_602408 = validateParameter(valid_602408, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_602408 != nil:
    section.add "Action", valid_602408
  var valid_602409 = query.getOrDefault("Version")
  valid_602409 = validateParameter(valid_602409, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602409 != nil:
    section.add "Version", valid_602409
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
  var valid_602410 = header.getOrDefault("X-Amz-Signature")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Signature", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Content-Sha256", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Date")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Date", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Credential")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Credential", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Security-Token")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Security-Token", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Algorithm")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Algorithm", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-SignedHeaders", valid_602416
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIds: JArray
  ##   SnsTopicArn: JString (required)
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_602417 = formData.getOrDefault("SourceIds")
  valid_602417 = validateParameter(valid_602417, JArray, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "SourceIds", valid_602417
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_602418 = formData.getOrDefault("SnsTopicArn")
  valid_602418 = validateParameter(valid_602418, JString, required = true,
                                 default = nil)
  if valid_602418 != nil:
    section.add "SnsTopicArn", valid_602418
  var valid_602419 = formData.getOrDefault("Enabled")
  valid_602419 = validateParameter(valid_602419, JBool, required = false, default = nil)
  if valid_602419 != nil:
    section.add "Enabled", valid_602419
  var valid_602420 = formData.getOrDefault("SubscriptionName")
  valid_602420 = validateParameter(valid_602420, JString, required = true,
                                 default = nil)
  if valid_602420 != nil:
    section.add "SubscriptionName", valid_602420
  var valid_602421 = formData.getOrDefault("SourceType")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "SourceType", valid_602421
  var valid_602422 = formData.getOrDefault("EventCategories")
  valid_602422 = validateParameter(valid_602422, JArray, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "EventCategories", valid_602422
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602423: Call_PostCreateEventSubscription_602405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602423.validator(path, query, header, formData, body)
  let scheme = call_602423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602423.url(scheme.get, call_602423.host, call_602423.base,
                         call_602423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602423, url, valid)

proc call*(call_602424: Call_PostCreateEventSubscription_602405;
          SnsTopicArn: string; SubscriptionName: string; SourceIds: JsonNode = nil;
          Enabled: bool = false; SourceType: string = "";
          EventCategories: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Version: string = "2013-01-10"): Recallable =
  ## postCreateEventSubscription
  ##   SourceIds: JArray
  ##   SnsTopicArn: string (required)
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602425 = newJObject()
  var formData_602426 = newJObject()
  if SourceIds != nil:
    formData_602426.add "SourceIds", SourceIds
  add(formData_602426, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_602426, "Enabled", newJBool(Enabled))
  add(formData_602426, "SubscriptionName", newJString(SubscriptionName))
  add(formData_602426, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_602426.add "EventCategories", EventCategories
  add(query_602425, "Action", newJString(Action))
  add(query_602425, "Version", newJString(Version))
  result = call_602424.call(nil, query_602425, nil, formData_602426, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_602405(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_602406, base: "/",
    url: url_PostCreateEventSubscription_602407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_602384 = ref object of OpenApiRestCall_601373
proc url_GetCreateEventSubscription_602386(protocol: Scheme; host: string;
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

proc validate_GetCreateEventSubscription_602385(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   EventCategories: JArray
  ##   SourceIds: JArray
  ##   Action: JString (required)
  ##   SnsTopicArn: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_602387 = query.getOrDefault("SourceType")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "SourceType", valid_602387
  var valid_602388 = query.getOrDefault("Enabled")
  valid_602388 = validateParameter(valid_602388, JBool, required = false, default = nil)
  if valid_602388 != nil:
    section.add "Enabled", valid_602388
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_602389 = query.getOrDefault("SubscriptionName")
  valid_602389 = validateParameter(valid_602389, JString, required = true,
                                 default = nil)
  if valid_602389 != nil:
    section.add "SubscriptionName", valid_602389
  var valid_602390 = query.getOrDefault("EventCategories")
  valid_602390 = validateParameter(valid_602390, JArray, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "EventCategories", valid_602390
  var valid_602391 = query.getOrDefault("SourceIds")
  valid_602391 = validateParameter(valid_602391, JArray, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "SourceIds", valid_602391
  var valid_602392 = query.getOrDefault("Action")
  valid_602392 = validateParameter(valid_602392, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_602392 != nil:
    section.add "Action", valid_602392
  var valid_602393 = query.getOrDefault("SnsTopicArn")
  valid_602393 = validateParameter(valid_602393, JString, required = true,
                                 default = nil)
  if valid_602393 != nil:
    section.add "SnsTopicArn", valid_602393
  var valid_602394 = query.getOrDefault("Version")
  valid_602394 = validateParameter(valid_602394, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602394 != nil:
    section.add "Version", valid_602394
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
  var valid_602395 = header.getOrDefault("X-Amz-Signature")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Signature", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Content-Sha256", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Date")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Date", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Credential")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Credential", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Security-Token")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Security-Token", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Algorithm")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Algorithm", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-SignedHeaders", valid_602401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602402: Call_GetCreateEventSubscription_602384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602402.validator(path, query, header, formData, body)
  let scheme = call_602402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602402.url(scheme.get, call_602402.host, call_602402.base,
                         call_602402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602402, url, valid)

proc call*(call_602403: Call_GetCreateEventSubscription_602384;
          SubscriptionName: string; SnsTopicArn: string; SourceType: string = "";
          Enabled: bool = false; EventCategories: JsonNode = nil;
          SourceIds: JsonNode = nil; Action: string = "CreateEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   SourceIds: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   Version: string (required)
  var query_602404 = newJObject()
  add(query_602404, "SourceType", newJString(SourceType))
  add(query_602404, "Enabled", newJBool(Enabled))
  add(query_602404, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_602404.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_602404.add "SourceIds", SourceIds
  add(query_602404, "Action", newJString(Action))
  add(query_602404, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_602404, "Version", newJString(Version))
  result = call_602403.call(nil, query_602404, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_602384(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_602385, base: "/",
    url: url_GetCreateEventSubscription_602386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_602446 = ref object of OpenApiRestCall_601373
proc url_PostCreateOptionGroup_602448(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateOptionGroup_602447(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602449 = query.getOrDefault("Action")
  valid_602449 = validateParameter(valid_602449, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_602449 != nil:
    section.add "Action", valid_602449
  var valid_602450 = query.getOrDefault("Version")
  valid_602450 = validateParameter(valid_602450, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602450 != nil:
    section.add "Version", valid_602450
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
  var valid_602451 = header.getOrDefault("X-Amz-Signature")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Signature", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Content-Sha256", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Date")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Date", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Credential")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Credential", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Security-Token")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Security-Token", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Algorithm")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Algorithm", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-SignedHeaders", valid_602457
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_602458 = formData.getOrDefault("OptionGroupDescription")
  valid_602458 = validateParameter(valid_602458, JString, required = true,
                                 default = nil)
  if valid_602458 != nil:
    section.add "OptionGroupDescription", valid_602458
  var valid_602459 = formData.getOrDefault("EngineName")
  valid_602459 = validateParameter(valid_602459, JString, required = true,
                                 default = nil)
  if valid_602459 != nil:
    section.add "EngineName", valid_602459
  var valid_602460 = formData.getOrDefault("MajorEngineVersion")
  valid_602460 = validateParameter(valid_602460, JString, required = true,
                                 default = nil)
  if valid_602460 != nil:
    section.add "MajorEngineVersion", valid_602460
  var valid_602461 = formData.getOrDefault("OptionGroupName")
  valid_602461 = validateParameter(valid_602461, JString, required = true,
                                 default = nil)
  if valid_602461 != nil:
    section.add "OptionGroupName", valid_602461
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602462: Call_PostCreateOptionGroup_602446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602462.validator(path, query, header, formData, body)
  let scheme = call_602462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602462.url(scheme.get, call_602462.host, call_602462.base,
                         call_602462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602462, url, valid)

proc call*(call_602463: Call_PostCreateOptionGroup_602446;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; OptionGroupName: string;
          Action: string = "CreateOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_602464 = newJObject()
  var formData_602465 = newJObject()
  add(formData_602465, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_602465, "EngineName", newJString(EngineName))
  add(formData_602465, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_602464, "Action", newJString(Action))
  add(formData_602465, "OptionGroupName", newJString(OptionGroupName))
  add(query_602464, "Version", newJString(Version))
  result = call_602463.call(nil, query_602464, nil, formData_602465, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_602446(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_602447, base: "/",
    url: url_PostCreateOptionGroup_602448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_602427 = ref object of OpenApiRestCall_601373
proc url_GetCreateOptionGroup_602429(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateOptionGroup_602428(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_602430 = query.getOrDefault("EngineName")
  valid_602430 = validateParameter(valid_602430, JString, required = true,
                                 default = nil)
  if valid_602430 != nil:
    section.add "EngineName", valid_602430
  var valid_602431 = query.getOrDefault("OptionGroupDescription")
  valid_602431 = validateParameter(valid_602431, JString, required = true,
                                 default = nil)
  if valid_602431 != nil:
    section.add "OptionGroupDescription", valid_602431
  var valid_602432 = query.getOrDefault("Action")
  valid_602432 = validateParameter(valid_602432, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_602432 != nil:
    section.add "Action", valid_602432
  var valid_602433 = query.getOrDefault("OptionGroupName")
  valid_602433 = validateParameter(valid_602433, JString, required = true,
                                 default = nil)
  if valid_602433 != nil:
    section.add "OptionGroupName", valid_602433
  var valid_602434 = query.getOrDefault("Version")
  valid_602434 = validateParameter(valid_602434, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602434 != nil:
    section.add "Version", valid_602434
  var valid_602435 = query.getOrDefault("MajorEngineVersion")
  valid_602435 = validateParameter(valid_602435, JString, required = true,
                                 default = nil)
  if valid_602435 != nil:
    section.add "MajorEngineVersion", valid_602435
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
  var valid_602436 = header.getOrDefault("X-Amz-Signature")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Signature", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Content-Sha256", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Date")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Date", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Credential")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Credential", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Security-Token")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Security-Token", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Algorithm")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Algorithm", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-SignedHeaders", valid_602442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602443: Call_GetCreateOptionGroup_602427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602443.validator(path, query, header, formData, body)
  let scheme = call_602443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602443.url(scheme.get, call_602443.host, call_602443.base,
                         call_602443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602443, url, valid)

proc call*(call_602444: Call_GetCreateOptionGroup_602427; EngineName: string;
          OptionGroupDescription: string; OptionGroupName: string;
          MajorEngineVersion: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateOptionGroup
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   MajorEngineVersion: string (required)
  var query_602445 = newJObject()
  add(query_602445, "EngineName", newJString(EngineName))
  add(query_602445, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_602445, "Action", newJString(Action))
  add(query_602445, "OptionGroupName", newJString(OptionGroupName))
  add(query_602445, "Version", newJString(Version))
  add(query_602445, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602444.call(nil, query_602445, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_602427(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_602428, base: "/",
    url: url_GetCreateOptionGroup_602429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_602484 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBInstance_602486(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBInstance_602485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602487 = query.getOrDefault("Action")
  valid_602487 = validateParameter(valid_602487, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_602487 != nil:
    section.add "Action", valid_602487
  var valid_602488 = query.getOrDefault("Version")
  valid_602488 = validateParameter(valid_602488, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602488 != nil:
    section.add "Version", valid_602488
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
  var valid_602489 = header.getOrDefault("X-Amz-Signature")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Signature", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Content-Sha256", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Date")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Date", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Credential")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Credential", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-Security-Token")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Security-Token", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Algorithm")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Algorithm", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-SignedHeaders", valid_602495
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602496 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602496 = validateParameter(valid_602496, JString, required = true,
                                 default = nil)
  if valid_602496 != nil:
    section.add "DBInstanceIdentifier", valid_602496
  var valid_602497 = formData.getOrDefault("SkipFinalSnapshot")
  valid_602497 = validateParameter(valid_602497, JBool, required = false, default = nil)
  if valid_602497 != nil:
    section.add "SkipFinalSnapshot", valid_602497
  var valid_602498 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_602498
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602499: Call_PostDeleteDBInstance_602484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602499.validator(path, query, header, formData, body)
  let scheme = call_602499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602499.url(scheme.get, call_602499.host, call_602499.base,
                         call_602499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602499, url, valid)

proc call*(call_602500: Call_PostDeleteDBInstance_602484;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_602501 = newJObject()
  var formData_602502 = newJObject()
  add(formData_602502, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602501, "Action", newJString(Action))
  add(formData_602502, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_602502, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_602501, "Version", newJString(Version))
  result = call_602500.call(nil, query_602501, nil, formData_602502, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_602484(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_602485, base: "/",
    url: url_PostDeleteDBInstance_602486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_602466 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBInstance_602468(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBInstance_602467(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602469 = query.getOrDefault("DBInstanceIdentifier")
  valid_602469 = validateParameter(valid_602469, JString, required = true,
                                 default = nil)
  if valid_602469 != nil:
    section.add "DBInstanceIdentifier", valid_602469
  var valid_602470 = query.getOrDefault("SkipFinalSnapshot")
  valid_602470 = validateParameter(valid_602470, JBool, required = false, default = nil)
  if valid_602470 != nil:
    section.add "SkipFinalSnapshot", valid_602470
  var valid_602471 = query.getOrDefault("Action")
  valid_602471 = validateParameter(valid_602471, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_602471 != nil:
    section.add "Action", valid_602471
  var valid_602472 = query.getOrDefault("Version")
  valid_602472 = validateParameter(valid_602472, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602472 != nil:
    section.add "Version", valid_602472
  var valid_602473 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_602473
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
  var valid_602474 = header.getOrDefault("X-Amz-Signature")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Signature", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Content-Sha256", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Date")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Date", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Credential")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Credential", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Security-Token")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Security-Token", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Algorithm")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Algorithm", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-SignedHeaders", valid_602480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602481: Call_GetDeleteDBInstance_602466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602481.validator(path, query, header, formData, body)
  let scheme = call_602481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602481.url(scheme.get, call_602481.host, call_602481.base,
                         call_602481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602481, url, valid)

proc call*(call_602482: Call_GetDeleteDBInstance_602466;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2013-01-10";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_602483 = newJObject()
  add(query_602483, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602483, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_602483, "Action", newJString(Action))
  add(query_602483, "Version", newJString(Version))
  add(query_602483, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_602482.call(nil, query_602483, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_602466(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_602467, base: "/",
    url: url_GetDeleteDBInstance_602468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_602519 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBParameterGroup_602521(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBParameterGroup_602520(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602522 = query.getOrDefault("Action")
  valid_602522 = validateParameter(valid_602522, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_602522 != nil:
    section.add "Action", valid_602522
  var valid_602523 = query.getOrDefault("Version")
  valid_602523 = validateParameter(valid_602523, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602523 != nil:
    section.add "Version", valid_602523
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
  var valid_602524 = header.getOrDefault("X-Amz-Signature")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Signature", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Content-Sha256", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Date")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Date", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-Credential")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-Credential", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-Security-Token")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Security-Token", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-Algorithm")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Algorithm", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-SignedHeaders", valid_602530
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602531 = formData.getOrDefault("DBParameterGroupName")
  valid_602531 = validateParameter(valid_602531, JString, required = true,
                                 default = nil)
  if valid_602531 != nil:
    section.add "DBParameterGroupName", valid_602531
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602532: Call_PostDeleteDBParameterGroup_602519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602532.validator(path, query, header, formData, body)
  let scheme = call_602532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602532.url(scheme.get, call_602532.host, call_602532.base,
                         call_602532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602532, url, valid)

proc call*(call_602533: Call_PostDeleteDBParameterGroup_602519;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602534 = newJObject()
  var formData_602535 = newJObject()
  add(formData_602535, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602534, "Action", newJString(Action))
  add(query_602534, "Version", newJString(Version))
  result = call_602533.call(nil, query_602534, nil, formData_602535, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_602519(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_602520, base: "/",
    url: url_PostDeleteDBParameterGroup_602521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_602503 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBParameterGroup_602505(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBParameterGroup_602504(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_602506 = query.getOrDefault("DBParameterGroupName")
  valid_602506 = validateParameter(valid_602506, JString, required = true,
                                 default = nil)
  if valid_602506 != nil:
    section.add "DBParameterGroupName", valid_602506
  var valid_602507 = query.getOrDefault("Action")
  valid_602507 = validateParameter(valid_602507, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_602507 != nil:
    section.add "Action", valid_602507
  var valid_602508 = query.getOrDefault("Version")
  valid_602508 = validateParameter(valid_602508, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602508 != nil:
    section.add "Version", valid_602508
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
  var valid_602509 = header.getOrDefault("X-Amz-Signature")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Signature", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Content-Sha256", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Date")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Date", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Credential")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Credential", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Security-Token")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Security-Token", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Algorithm")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Algorithm", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-SignedHeaders", valid_602515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602516: Call_GetDeleteDBParameterGroup_602503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602516.validator(path, query, header, formData, body)
  let scheme = call_602516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602516.url(scheme.get, call_602516.host, call_602516.base,
                         call_602516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602516, url, valid)

proc call*(call_602517: Call_GetDeleteDBParameterGroup_602503;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602518 = newJObject()
  add(query_602518, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602518, "Action", newJString(Action))
  add(query_602518, "Version", newJString(Version))
  result = call_602517.call(nil, query_602518, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_602503(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_602504, base: "/",
    url: url_GetDeleteDBParameterGroup_602505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_602552 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBSecurityGroup_602554(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBSecurityGroup_602553(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602555 = query.getOrDefault("Action")
  valid_602555 = validateParameter(valid_602555, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_602555 != nil:
    section.add "Action", valid_602555
  var valid_602556 = query.getOrDefault("Version")
  valid_602556 = validateParameter(valid_602556, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602556 != nil:
    section.add "Version", valid_602556
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
  var valid_602557 = header.getOrDefault("X-Amz-Signature")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Signature", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-Content-Sha256", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Date")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Date", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Credential")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Credential", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Security-Token")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Security-Token", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Algorithm")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Algorithm", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-SignedHeaders", valid_602563
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602564 = formData.getOrDefault("DBSecurityGroupName")
  valid_602564 = validateParameter(valid_602564, JString, required = true,
                                 default = nil)
  if valid_602564 != nil:
    section.add "DBSecurityGroupName", valid_602564
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602565: Call_PostDeleteDBSecurityGroup_602552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602565.validator(path, query, header, formData, body)
  let scheme = call_602565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602565.url(scheme.get, call_602565.host, call_602565.base,
                         call_602565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602565, url, valid)

proc call*(call_602566: Call_PostDeleteDBSecurityGroup_602552;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602567 = newJObject()
  var formData_602568 = newJObject()
  add(formData_602568, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602567, "Action", newJString(Action))
  add(query_602567, "Version", newJString(Version))
  result = call_602566.call(nil, query_602567, nil, formData_602568, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_602552(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_602553, base: "/",
    url: url_PostDeleteDBSecurityGroup_602554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_602536 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBSecurityGroup_602538(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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

proc validate_GetDeleteDBSecurityGroup_602537(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602539 = query.getOrDefault("DBSecurityGroupName")
  valid_602539 = validateParameter(valid_602539, JString, required = true,
                                 default = nil)
  if valid_602539 != nil:
    section.add "DBSecurityGroupName", valid_602539
  var valid_602540 = query.getOrDefault("Action")
  valid_602540 = validateParameter(valid_602540, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_602540 != nil:
    section.add "Action", valid_602540
  var valid_602541 = query.getOrDefault("Version")
  valid_602541 = validateParameter(valid_602541, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602541 != nil:
    section.add "Version", valid_602541
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
  var valid_602542 = header.getOrDefault("X-Amz-Signature")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Signature", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Content-Sha256", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Date")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Date", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Credential")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Credential", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Security-Token")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Security-Token", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Algorithm")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Algorithm", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-SignedHeaders", valid_602548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602549: Call_GetDeleteDBSecurityGroup_602536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602549.validator(path, query, header, formData, body)
  let scheme = call_602549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602549.url(scheme.get, call_602549.host, call_602549.base,
                         call_602549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602549, url, valid)

proc call*(call_602550: Call_GetDeleteDBSecurityGroup_602536;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602551 = newJObject()
  add(query_602551, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602551, "Action", newJString(Action))
  add(query_602551, "Version", newJString(Version))
  result = call_602550.call(nil, query_602551, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_602536(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_602537, base: "/",
    url: url_GetDeleteDBSecurityGroup_602538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_602585 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBSnapshot_602587(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSnapshot_602586(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602588 = query.getOrDefault("Action")
  valid_602588 = validateParameter(valid_602588, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_602588 != nil:
    section.add "Action", valid_602588
  var valid_602589 = query.getOrDefault("Version")
  valid_602589 = validateParameter(valid_602589, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602589 != nil:
    section.add "Version", valid_602589
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
  var valid_602590 = header.getOrDefault("X-Amz-Signature")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Signature", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Content-Sha256", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-Date")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-Date", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-Credential")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Credential", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Security-Token")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Security-Token", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Algorithm")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Algorithm", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-SignedHeaders", valid_602596
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_602597 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602597 = validateParameter(valid_602597, JString, required = true,
                                 default = nil)
  if valid_602597 != nil:
    section.add "DBSnapshotIdentifier", valid_602597
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602598: Call_PostDeleteDBSnapshot_602585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602598.validator(path, query, header, formData, body)
  let scheme = call_602598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602598.url(scheme.get, call_602598.host, call_602598.base,
                         call_602598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602598, url, valid)

proc call*(call_602599: Call_PostDeleteDBSnapshot_602585;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602600 = newJObject()
  var formData_602601 = newJObject()
  add(formData_602601, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602600, "Action", newJString(Action))
  add(query_602600, "Version", newJString(Version))
  result = call_602599.call(nil, query_602600, nil, formData_602601, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_602585(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_602586, base: "/",
    url: url_PostDeleteDBSnapshot_602587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_602569 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBSnapshot_602571(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSnapshot_602570(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_602572 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602572 = validateParameter(valid_602572, JString, required = true,
                                 default = nil)
  if valid_602572 != nil:
    section.add "DBSnapshotIdentifier", valid_602572
  var valid_602573 = query.getOrDefault("Action")
  valid_602573 = validateParameter(valid_602573, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_602573 != nil:
    section.add "Action", valid_602573
  var valid_602574 = query.getOrDefault("Version")
  valid_602574 = validateParameter(valid_602574, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602574 != nil:
    section.add "Version", valid_602574
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
  var valid_602575 = header.getOrDefault("X-Amz-Signature")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Signature", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-Content-Sha256", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-Date")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Date", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Credential")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Credential", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Security-Token")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Security-Token", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Algorithm")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Algorithm", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-SignedHeaders", valid_602581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602582: Call_GetDeleteDBSnapshot_602569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602582.validator(path, query, header, formData, body)
  let scheme = call_602582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602582.url(scheme.get, call_602582.host, call_602582.base,
                         call_602582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602582, url, valid)

proc call*(call_602583: Call_GetDeleteDBSnapshot_602569;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602584 = newJObject()
  add(query_602584, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602584, "Action", newJString(Action))
  add(query_602584, "Version", newJString(Version))
  result = call_602583.call(nil, query_602584, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_602569(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_602570, base: "/",
    url: url_GetDeleteDBSnapshot_602571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_602618 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBSubnetGroup_602620(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_602619(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602621 = query.getOrDefault("Action")
  valid_602621 = validateParameter(valid_602621, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_602621 != nil:
    section.add "Action", valid_602621
  var valid_602622 = query.getOrDefault("Version")
  valid_602622 = validateParameter(valid_602622, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602622 != nil:
    section.add "Version", valid_602622
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
  var valid_602623 = header.getOrDefault("X-Amz-Signature")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Signature", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Content-Sha256", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Date")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Date", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Credential")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Credential", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Security-Token")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Security-Token", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Algorithm")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Algorithm", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-SignedHeaders", valid_602629
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_602630 = formData.getOrDefault("DBSubnetGroupName")
  valid_602630 = validateParameter(valid_602630, JString, required = true,
                                 default = nil)
  if valid_602630 != nil:
    section.add "DBSubnetGroupName", valid_602630
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602631: Call_PostDeleteDBSubnetGroup_602618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602631.validator(path, query, header, formData, body)
  let scheme = call_602631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602631.url(scheme.get, call_602631.host, call_602631.base,
                         call_602631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602631, url, valid)

proc call*(call_602632: Call_PostDeleteDBSubnetGroup_602618;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_602633 = newJObject()
  var formData_602634 = newJObject()
  add(query_602633, "Action", newJString(Action))
  add(formData_602634, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602633, "Version", newJString(Version))
  result = call_602632.call(nil, query_602633, nil, formData_602634, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_602618(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_602619, base: "/",
    url: url_PostDeleteDBSubnetGroup_602620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_602602 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBSubnetGroup_602604(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSubnetGroup_602603(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602605 = query.getOrDefault("Action")
  valid_602605 = validateParameter(valid_602605, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_602605 != nil:
    section.add "Action", valid_602605
  var valid_602606 = query.getOrDefault("DBSubnetGroupName")
  valid_602606 = validateParameter(valid_602606, JString, required = true,
                                 default = nil)
  if valid_602606 != nil:
    section.add "DBSubnetGroupName", valid_602606
  var valid_602607 = query.getOrDefault("Version")
  valid_602607 = validateParameter(valid_602607, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602607 != nil:
    section.add "Version", valid_602607
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
  var valid_602608 = header.getOrDefault("X-Amz-Signature")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Signature", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Content-Sha256", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-Date")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Date", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Credential")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Credential", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Security-Token")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Security-Token", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Algorithm")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Algorithm", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-SignedHeaders", valid_602614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602615: Call_GetDeleteDBSubnetGroup_602602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602615.validator(path, query, header, formData, body)
  let scheme = call_602615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602615.url(scheme.get, call_602615.host, call_602615.base,
                         call_602615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602615, url, valid)

proc call*(call_602616: Call_GetDeleteDBSubnetGroup_602602;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_602617 = newJObject()
  add(query_602617, "Action", newJString(Action))
  add(query_602617, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602617, "Version", newJString(Version))
  result = call_602616.call(nil, query_602617, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_602602(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_602603, base: "/",
    url: url_GetDeleteDBSubnetGroup_602604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_602651 = ref object of OpenApiRestCall_601373
proc url_PostDeleteEventSubscription_602653(protocol: Scheme; host: string;
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

proc validate_PostDeleteEventSubscription_602652(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602654 = query.getOrDefault("Action")
  valid_602654 = validateParameter(valid_602654, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_602654 != nil:
    section.add "Action", valid_602654
  var valid_602655 = query.getOrDefault("Version")
  valid_602655 = validateParameter(valid_602655, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602655 != nil:
    section.add "Version", valid_602655
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
  var valid_602656 = header.getOrDefault("X-Amz-Signature")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Signature", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Content-Sha256", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Date")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Date", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-Credential")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-Credential", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Security-Token")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Security-Token", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-Algorithm")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Algorithm", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-SignedHeaders", valid_602662
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_602663 = formData.getOrDefault("SubscriptionName")
  valid_602663 = validateParameter(valid_602663, JString, required = true,
                                 default = nil)
  if valid_602663 != nil:
    section.add "SubscriptionName", valid_602663
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602664: Call_PostDeleteEventSubscription_602651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602664.validator(path, query, header, formData, body)
  let scheme = call_602664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602664.url(scheme.get, call_602664.host, call_602664.base,
                         call_602664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602664, url, valid)

proc call*(call_602665: Call_PostDeleteEventSubscription_602651;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602666 = newJObject()
  var formData_602667 = newJObject()
  add(formData_602667, "SubscriptionName", newJString(SubscriptionName))
  add(query_602666, "Action", newJString(Action))
  add(query_602666, "Version", newJString(Version))
  result = call_602665.call(nil, query_602666, nil, formData_602667, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_602651(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_602652, base: "/",
    url: url_PostDeleteEventSubscription_602653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_602635 = ref object of OpenApiRestCall_601373
proc url_GetDeleteEventSubscription_602637(protocol: Scheme; host: string;
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

proc validate_GetDeleteEventSubscription_602636(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_602638 = query.getOrDefault("SubscriptionName")
  valid_602638 = validateParameter(valid_602638, JString, required = true,
                                 default = nil)
  if valid_602638 != nil:
    section.add "SubscriptionName", valid_602638
  var valid_602639 = query.getOrDefault("Action")
  valid_602639 = validateParameter(valid_602639, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_602639 != nil:
    section.add "Action", valid_602639
  var valid_602640 = query.getOrDefault("Version")
  valid_602640 = validateParameter(valid_602640, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602640 != nil:
    section.add "Version", valid_602640
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
  var valid_602641 = header.getOrDefault("X-Amz-Signature")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Signature", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Content-Sha256", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Date")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Date", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Credential")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Credential", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Security-Token")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Security-Token", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Algorithm")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Algorithm", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-SignedHeaders", valid_602647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602648: Call_GetDeleteEventSubscription_602635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602648.validator(path, query, header, formData, body)
  let scheme = call_602648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602648.url(scheme.get, call_602648.host, call_602648.base,
                         call_602648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602648, url, valid)

proc call*(call_602649: Call_GetDeleteEventSubscription_602635;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602650 = newJObject()
  add(query_602650, "SubscriptionName", newJString(SubscriptionName))
  add(query_602650, "Action", newJString(Action))
  add(query_602650, "Version", newJString(Version))
  result = call_602649.call(nil, query_602650, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_602635(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_602636, base: "/",
    url: url_GetDeleteEventSubscription_602637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_602684 = ref object of OpenApiRestCall_601373
proc url_PostDeleteOptionGroup_602686(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteOptionGroup_602685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602687 = query.getOrDefault("Action")
  valid_602687 = validateParameter(valid_602687, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_602687 != nil:
    section.add "Action", valid_602687
  var valid_602688 = query.getOrDefault("Version")
  valid_602688 = validateParameter(valid_602688, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602688 != nil:
    section.add "Version", valid_602688
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
  var valid_602689 = header.getOrDefault("X-Amz-Signature")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Signature", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Content-Sha256", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Date")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Date", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Credential")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Credential", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Security-Token")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Security-Token", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-Algorithm")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Algorithm", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-SignedHeaders", valid_602695
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_602696 = formData.getOrDefault("OptionGroupName")
  valid_602696 = validateParameter(valid_602696, JString, required = true,
                                 default = nil)
  if valid_602696 != nil:
    section.add "OptionGroupName", valid_602696
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602697: Call_PostDeleteOptionGroup_602684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602697.validator(path, query, header, formData, body)
  let scheme = call_602697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602697.url(scheme.get, call_602697.host, call_602697.base,
                         call_602697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602697, url, valid)

proc call*(call_602698: Call_PostDeleteOptionGroup_602684; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_602699 = newJObject()
  var formData_602700 = newJObject()
  add(query_602699, "Action", newJString(Action))
  add(formData_602700, "OptionGroupName", newJString(OptionGroupName))
  add(query_602699, "Version", newJString(Version))
  result = call_602698.call(nil, query_602699, nil, formData_602700, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_602684(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_602685, base: "/",
    url: url_PostDeleteOptionGroup_602686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_602668 = ref object of OpenApiRestCall_601373
proc url_GetDeleteOptionGroup_602670(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteOptionGroup_602669(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602671 = query.getOrDefault("Action")
  valid_602671 = validateParameter(valid_602671, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_602671 != nil:
    section.add "Action", valid_602671
  var valid_602672 = query.getOrDefault("OptionGroupName")
  valid_602672 = validateParameter(valid_602672, JString, required = true,
                                 default = nil)
  if valid_602672 != nil:
    section.add "OptionGroupName", valid_602672
  var valid_602673 = query.getOrDefault("Version")
  valid_602673 = validateParameter(valid_602673, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602673 != nil:
    section.add "Version", valid_602673
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
  var valid_602674 = header.getOrDefault("X-Amz-Signature")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Signature", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Content-Sha256", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Date")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Date", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Credential")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Credential", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Security-Token")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Security-Token", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Algorithm")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Algorithm", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-SignedHeaders", valid_602680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602681: Call_GetDeleteOptionGroup_602668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602681.validator(path, query, header, formData, body)
  let scheme = call_602681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602681.url(scheme.get, call_602681.host, call_602681.base,
                         call_602681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602681, url, valid)

proc call*(call_602682: Call_GetDeleteOptionGroup_602668; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_602683 = newJObject()
  add(query_602683, "Action", newJString(Action))
  add(query_602683, "OptionGroupName", newJString(OptionGroupName))
  add(query_602683, "Version", newJString(Version))
  result = call_602682.call(nil, query_602683, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_602668(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_602669, base: "/",
    url: url_GetDeleteOptionGroup_602670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_602723 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBEngineVersions_602725(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBEngineVersions_602724(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602726 = query.getOrDefault("Action")
  valid_602726 = validateParameter(valid_602726, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_602726 != nil:
    section.add "Action", valid_602726
  var valid_602727 = query.getOrDefault("Version")
  valid_602727 = validateParameter(valid_602727, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602727 != nil:
    section.add "Version", valid_602727
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
  var valid_602728 = header.getOrDefault("X-Amz-Signature")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Signature", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Content-Sha256", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-Date")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-Date", valid_602730
  var valid_602731 = header.getOrDefault("X-Amz-Credential")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-Credential", valid_602731
  var valid_602732 = header.getOrDefault("X-Amz-Security-Token")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-Security-Token", valid_602732
  var valid_602733 = header.getOrDefault("X-Amz-Algorithm")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-Algorithm", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-SignedHeaders", valid_602734
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultOnly: JBool
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString
  ##   ListSupportedCharacterSets: JBool
  ##   DBParameterGroupFamily: JString
  section = newJObject()
  var valid_602735 = formData.getOrDefault("DefaultOnly")
  valid_602735 = validateParameter(valid_602735, JBool, required = false, default = nil)
  if valid_602735 != nil:
    section.add "DefaultOnly", valid_602735
  var valid_602736 = formData.getOrDefault("MaxRecords")
  valid_602736 = validateParameter(valid_602736, JInt, required = false, default = nil)
  if valid_602736 != nil:
    section.add "MaxRecords", valid_602736
  var valid_602737 = formData.getOrDefault("EngineVersion")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "EngineVersion", valid_602737
  var valid_602738 = formData.getOrDefault("Marker")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "Marker", valid_602738
  var valid_602739 = formData.getOrDefault("Engine")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "Engine", valid_602739
  var valid_602740 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_602740 = validateParameter(valid_602740, JBool, required = false, default = nil)
  if valid_602740 != nil:
    section.add "ListSupportedCharacterSets", valid_602740
  var valid_602741 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "DBParameterGroupFamily", valid_602741
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602742: Call_PostDescribeDBEngineVersions_602723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602742.validator(path, query, header, formData, body)
  let scheme = call_602742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602742.url(scheme.get, call_602742.host, call_602742.base,
                         call_602742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602742, url, valid)

proc call*(call_602743: Call_PostDescribeDBEngineVersions_602723;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions";
          Version: string = "2013-01-10"; DBParameterGroupFamily: string = ""): Recallable =
  ## postDescribeDBEngineVersions
  ##   DefaultOnly: bool
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string
  ##   ListSupportedCharacterSets: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string
  var query_602744 = newJObject()
  var formData_602745 = newJObject()
  add(formData_602745, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_602745, "MaxRecords", newJInt(MaxRecords))
  add(formData_602745, "EngineVersion", newJString(EngineVersion))
  add(formData_602745, "Marker", newJString(Marker))
  add(formData_602745, "Engine", newJString(Engine))
  add(formData_602745, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_602744, "Action", newJString(Action))
  add(query_602744, "Version", newJString(Version))
  add(formData_602745, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_602743.call(nil, query_602744, nil, formData_602745, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_602723(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_602724, base: "/",
    url: url_PostDescribeDBEngineVersions_602725,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_602701 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBEngineVersions_602703(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBEngineVersions_602702(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString
  ##   Engine: JString
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   ListSupportedCharacterSets: JBool
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  ##   DefaultOnly: JBool
  section = newJObject()
  var valid_602704 = query.getOrDefault("Marker")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "Marker", valid_602704
  var valid_602705 = query.getOrDefault("DBParameterGroupFamily")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "DBParameterGroupFamily", valid_602705
  var valid_602706 = query.getOrDefault("Engine")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "Engine", valid_602706
  var valid_602707 = query.getOrDefault("EngineVersion")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "EngineVersion", valid_602707
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602708 = query.getOrDefault("Action")
  valid_602708 = validateParameter(valid_602708, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_602708 != nil:
    section.add "Action", valid_602708
  var valid_602709 = query.getOrDefault("ListSupportedCharacterSets")
  valid_602709 = validateParameter(valid_602709, JBool, required = false, default = nil)
  if valid_602709 != nil:
    section.add "ListSupportedCharacterSets", valid_602709
  var valid_602710 = query.getOrDefault("Version")
  valid_602710 = validateParameter(valid_602710, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602710 != nil:
    section.add "Version", valid_602710
  var valid_602711 = query.getOrDefault("MaxRecords")
  valid_602711 = validateParameter(valid_602711, JInt, required = false, default = nil)
  if valid_602711 != nil:
    section.add "MaxRecords", valid_602711
  var valid_602712 = query.getOrDefault("DefaultOnly")
  valid_602712 = validateParameter(valid_602712, JBool, required = false, default = nil)
  if valid_602712 != nil:
    section.add "DefaultOnly", valid_602712
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
  var valid_602713 = header.getOrDefault("X-Amz-Signature")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Signature", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Content-Sha256", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-Date")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-Date", valid_602715
  var valid_602716 = header.getOrDefault("X-Amz-Credential")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Credential", valid_602716
  var valid_602717 = header.getOrDefault("X-Amz-Security-Token")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "X-Amz-Security-Token", valid_602717
  var valid_602718 = header.getOrDefault("X-Amz-Algorithm")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "X-Amz-Algorithm", valid_602718
  var valid_602719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602719 = validateParameter(valid_602719, JString, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "X-Amz-SignedHeaders", valid_602719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602720: Call_GetDescribeDBEngineVersions_602701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602720.validator(path, query, header, formData, body)
  let scheme = call_602720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602720.url(scheme.get, call_602720.host, call_602720.base,
                         call_602720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602720, url, valid)

proc call*(call_602721: Call_GetDescribeDBEngineVersions_602701;
          Marker: string = ""; DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2013-01-10";
          MaxRecords: int = 0; DefaultOnly: bool = false): Recallable =
  ## getDescribeDBEngineVersions
  ##   Marker: string
  ##   DBParameterGroupFamily: string
  ##   Engine: string
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   ListSupportedCharacterSets: bool
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   DefaultOnly: bool
  var query_602722 = newJObject()
  add(query_602722, "Marker", newJString(Marker))
  add(query_602722, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602722, "Engine", newJString(Engine))
  add(query_602722, "EngineVersion", newJString(EngineVersion))
  add(query_602722, "Action", newJString(Action))
  add(query_602722, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_602722, "Version", newJString(Version))
  add(query_602722, "MaxRecords", newJInt(MaxRecords))
  add(query_602722, "DefaultOnly", newJBool(DefaultOnly))
  result = call_602721.call(nil, query_602722, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_602701(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_602702, base: "/",
    url: url_GetDescribeDBEngineVersions_602703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_602764 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBInstances_602766(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_602765(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602767 = query.getOrDefault("Action")
  valid_602767 = validateParameter(valid_602767, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_602767 != nil:
    section.add "Action", valid_602767
  var valid_602768 = query.getOrDefault("Version")
  valid_602768 = validateParameter(valid_602768, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602768 != nil:
    section.add "Version", valid_602768
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
  var valid_602769 = header.getOrDefault("X-Amz-Signature")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Signature", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Content-Sha256", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Date")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Date", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Credential")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Credential", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Security-Token")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Security-Token", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-Algorithm")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-Algorithm", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-SignedHeaders", valid_602775
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  section = newJObject()
  var valid_602776 = formData.getOrDefault("MaxRecords")
  valid_602776 = validateParameter(valid_602776, JInt, required = false, default = nil)
  if valid_602776 != nil:
    section.add "MaxRecords", valid_602776
  var valid_602777 = formData.getOrDefault("Marker")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "Marker", valid_602777
  var valid_602778 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602778 = validateParameter(valid_602778, JString, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "DBInstanceIdentifier", valid_602778
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602779: Call_PostDescribeDBInstances_602764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602779.validator(path, query, header, formData, body)
  let scheme = call_602779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602779.url(scheme.get, call_602779.host, call_602779.base,
                         call_602779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602779, url, valid)

proc call*(call_602780: Call_PostDescribeDBInstances_602764; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602781 = newJObject()
  var formData_602782 = newJObject()
  add(formData_602782, "MaxRecords", newJInt(MaxRecords))
  add(formData_602782, "Marker", newJString(Marker))
  add(formData_602782, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602781, "Action", newJString(Action))
  add(query_602781, "Version", newJString(Version))
  result = call_602780.call(nil, query_602781, nil, formData_602782, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_602764(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_602765, base: "/",
    url: url_PostDescribeDBInstances_602766, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_602746 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBInstances_602748(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBInstances_602747(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602749 = query.getOrDefault("Marker")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "Marker", valid_602749
  var valid_602750 = query.getOrDefault("DBInstanceIdentifier")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "DBInstanceIdentifier", valid_602750
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602751 = query.getOrDefault("Action")
  valid_602751 = validateParameter(valid_602751, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_602751 != nil:
    section.add "Action", valid_602751
  var valid_602752 = query.getOrDefault("Version")
  valid_602752 = validateParameter(valid_602752, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602752 != nil:
    section.add "Version", valid_602752
  var valid_602753 = query.getOrDefault("MaxRecords")
  valid_602753 = validateParameter(valid_602753, JInt, required = false, default = nil)
  if valid_602753 != nil:
    section.add "MaxRecords", valid_602753
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
  var valid_602754 = header.getOrDefault("X-Amz-Signature")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Signature", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Content-Sha256", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-Date")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Date", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-Credential")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Credential", valid_602757
  var valid_602758 = header.getOrDefault("X-Amz-Security-Token")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Security-Token", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-Algorithm")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Algorithm", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-SignedHeaders", valid_602760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602761: Call_GetDescribeDBInstances_602746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602761.validator(path, query, header, formData, body)
  let scheme = call_602761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602761.url(scheme.get, call_602761.host, call_602761.base,
                         call_602761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602761, url, valid)

proc call*(call_602762: Call_GetDescribeDBInstances_602746; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602763 = newJObject()
  add(query_602763, "Marker", newJString(Marker))
  add(query_602763, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602763, "Action", newJString(Action))
  add(query_602763, "Version", newJString(Version))
  add(query_602763, "MaxRecords", newJInt(MaxRecords))
  result = call_602762.call(nil, query_602763, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_602746(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_602747, base: "/",
    url: url_GetDescribeDBInstances_602748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_602801 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBParameterGroups_602803(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameterGroups_602802(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602804 = query.getOrDefault("Action")
  valid_602804 = validateParameter(valid_602804, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_602804 != nil:
    section.add "Action", valid_602804
  var valid_602805 = query.getOrDefault("Version")
  valid_602805 = validateParameter(valid_602805, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602805 != nil:
    section.add "Version", valid_602805
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
  var valid_602806 = header.getOrDefault("X-Amz-Signature")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "X-Amz-Signature", valid_602806
  var valid_602807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602807 = validateParameter(valid_602807, JString, required = false,
                                 default = nil)
  if valid_602807 != nil:
    section.add "X-Amz-Content-Sha256", valid_602807
  var valid_602808 = header.getOrDefault("X-Amz-Date")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "X-Amz-Date", valid_602808
  var valid_602809 = header.getOrDefault("X-Amz-Credential")
  valid_602809 = validateParameter(valid_602809, JString, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "X-Amz-Credential", valid_602809
  var valid_602810 = header.getOrDefault("X-Amz-Security-Token")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "X-Amz-Security-Token", valid_602810
  var valid_602811 = header.getOrDefault("X-Amz-Algorithm")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "X-Amz-Algorithm", valid_602811
  var valid_602812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "X-Amz-SignedHeaders", valid_602812
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  section = newJObject()
  var valid_602813 = formData.getOrDefault("MaxRecords")
  valid_602813 = validateParameter(valid_602813, JInt, required = false, default = nil)
  if valid_602813 != nil:
    section.add "MaxRecords", valid_602813
  var valid_602814 = formData.getOrDefault("DBParameterGroupName")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "DBParameterGroupName", valid_602814
  var valid_602815 = formData.getOrDefault("Marker")
  valid_602815 = validateParameter(valid_602815, JString, required = false,
                                 default = nil)
  if valid_602815 != nil:
    section.add "Marker", valid_602815
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602816: Call_PostDescribeDBParameterGroups_602801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602816.validator(path, query, header, formData, body)
  let scheme = call_602816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602816.url(scheme.get, call_602816.host, call_602816.base,
                         call_602816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602816, url, valid)

proc call*(call_602817: Call_PostDescribeDBParameterGroups_602801;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602818 = newJObject()
  var formData_602819 = newJObject()
  add(formData_602819, "MaxRecords", newJInt(MaxRecords))
  add(formData_602819, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602819, "Marker", newJString(Marker))
  add(query_602818, "Action", newJString(Action))
  add(query_602818, "Version", newJString(Version))
  result = call_602817.call(nil, query_602818, nil, formData_602819, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_602801(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_602802, base: "/",
    url: url_PostDescribeDBParameterGroups_602803,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_602783 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBParameterGroups_602785(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBParameterGroups_602784(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602786 = query.getOrDefault("Marker")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "Marker", valid_602786
  var valid_602787 = query.getOrDefault("DBParameterGroupName")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "DBParameterGroupName", valid_602787
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602788 = query.getOrDefault("Action")
  valid_602788 = validateParameter(valid_602788, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_602788 != nil:
    section.add "Action", valid_602788
  var valid_602789 = query.getOrDefault("Version")
  valid_602789 = validateParameter(valid_602789, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602789 != nil:
    section.add "Version", valid_602789
  var valid_602790 = query.getOrDefault("MaxRecords")
  valid_602790 = validateParameter(valid_602790, JInt, required = false, default = nil)
  if valid_602790 != nil:
    section.add "MaxRecords", valid_602790
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
  var valid_602791 = header.getOrDefault("X-Amz-Signature")
  valid_602791 = validateParameter(valid_602791, JString, required = false,
                                 default = nil)
  if valid_602791 != nil:
    section.add "X-Amz-Signature", valid_602791
  var valid_602792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602792 = validateParameter(valid_602792, JString, required = false,
                                 default = nil)
  if valid_602792 != nil:
    section.add "X-Amz-Content-Sha256", valid_602792
  var valid_602793 = header.getOrDefault("X-Amz-Date")
  valid_602793 = validateParameter(valid_602793, JString, required = false,
                                 default = nil)
  if valid_602793 != nil:
    section.add "X-Amz-Date", valid_602793
  var valid_602794 = header.getOrDefault("X-Amz-Credential")
  valid_602794 = validateParameter(valid_602794, JString, required = false,
                                 default = nil)
  if valid_602794 != nil:
    section.add "X-Amz-Credential", valid_602794
  var valid_602795 = header.getOrDefault("X-Amz-Security-Token")
  valid_602795 = validateParameter(valid_602795, JString, required = false,
                                 default = nil)
  if valid_602795 != nil:
    section.add "X-Amz-Security-Token", valid_602795
  var valid_602796 = header.getOrDefault("X-Amz-Algorithm")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Algorithm", valid_602796
  var valid_602797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-SignedHeaders", valid_602797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602798: Call_GetDescribeDBParameterGroups_602783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602798.validator(path, query, header, formData, body)
  let scheme = call_602798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602798.url(scheme.get, call_602798.host, call_602798.base,
                         call_602798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602798, url, valid)

proc call*(call_602799: Call_GetDescribeDBParameterGroups_602783;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602800 = newJObject()
  add(query_602800, "Marker", newJString(Marker))
  add(query_602800, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602800, "Action", newJString(Action))
  add(query_602800, "Version", newJString(Version))
  add(query_602800, "MaxRecords", newJInt(MaxRecords))
  result = call_602799.call(nil, query_602800, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_602783(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_602784, base: "/",
    url: url_GetDescribeDBParameterGroups_602785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_602839 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBParameters_602841(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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

proc validate_PostDescribeDBParameters_602840(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602842 = query.getOrDefault("Action")
  valid_602842 = validateParameter(valid_602842, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_602842 != nil:
    section.add "Action", valid_602842
  var valid_602843 = query.getOrDefault("Version")
  valid_602843 = validateParameter(valid_602843, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602843 != nil:
    section.add "Version", valid_602843
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
  var valid_602844 = header.getOrDefault("X-Amz-Signature")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "X-Amz-Signature", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-Content-Sha256", valid_602845
  var valid_602846 = header.getOrDefault("X-Amz-Date")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-Date", valid_602846
  var valid_602847 = header.getOrDefault("X-Amz-Credential")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-Credential", valid_602847
  var valid_602848 = header.getOrDefault("X-Amz-Security-Token")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-Security-Token", valid_602848
  var valid_602849 = header.getOrDefault("X-Amz-Algorithm")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-Algorithm", valid_602849
  var valid_602850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "X-Amz-SignedHeaders", valid_602850
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  section = newJObject()
  var valid_602851 = formData.getOrDefault("Source")
  valid_602851 = validateParameter(valid_602851, JString, required = false,
                                 default = nil)
  if valid_602851 != nil:
    section.add "Source", valid_602851
  var valid_602852 = formData.getOrDefault("MaxRecords")
  valid_602852 = validateParameter(valid_602852, JInt, required = false, default = nil)
  if valid_602852 != nil:
    section.add "MaxRecords", valid_602852
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602853 = formData.getOrDefault("DBParameterGroupName")
  valid_602853 = validateParameter(valid_602853, JString, required = true,
                                 default = nil)
  if valid_602853 != nil:
    section.add "DBParameterGroupName", valid_602853
  var valid_602854 = formData.getOrDefault("Marker")
  valid_602854 = validateParameter(valid_602854, JString, required = false,
                                 default = nil)
  if valid_602854 != nil:
    section.add "Marker", valid_602854
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602855: Call_PostDescribeDBParameters_602839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602855.validator(path, query, header, formData, body)
  let scheme = call_602855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602855.url(scheme.get, call_602855.host, call_602855.base,
                         call_602855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602855, url, valid)

proc call*(call_602856: Call_PostDescribeDBParameters_602839;
          DBParameterGroupName: string; Source: string = ""; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBParameters";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameters
  ##   Source: string
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602857 = newJObject()
  var formData_602858 = newJObject()
  add(formData_602858, "Source", newJString(Source))
  add(formData_602858, "MaxRecords", newJInt(MaxRecords))
  add(formData_602858, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602858, "Marker", newJString(Marker))
  add(query_602857, "Action", newJString(Action))
  add(query_602857, "Version", newJString(Version))
  result = call_602856.call(nil, query_602857, nil, formData_602858, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_602839(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_602840, base: "/",
    url: url_PostDescribeDBParameters_602841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_602820 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBParameters_602822(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBParameters_602821(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString (required)
  ##   Source: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602823 = query.getOrDefault("Marker")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "Marker", valid_602823
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_602824 = query.getOrDefault("DBParameterGroupName")
  valid_602824 = validateParameter(valid_602824, JString, required = true,
                                 default = nil)
  if valid_602824 != nil:
    section.add "DBParameterGroupName", valid_602824
  var valid_602825 = query.getOrDefault("Source")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "Source", valid_602825
  var valid_602826 = query.getOrDefault("Action")
  valid_602826 = validateParameter(valid_602826, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_602826 != nil:
    section.add "Action", valid_602826
  var valid_602827 = query.getOrDefault("Version")
  valid_602827 = validateParameter(valid_602827, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602827 != nil:
    section.add "Version", valid_602827
  var valid_602828 = query.getOrDefault("MaxRecords")
  valid_602828 = validateParameter(valid_602828, JInt, required = false, default = nil)
  if valid_602828 != nil:
    section.add "MaxRecords", valid_602828
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
  var valid_602829 = header.getOrDefault("X-Amz-Signature")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "X-Amz-Signature", valid_602829
  var valid_602830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "X-Amz-Content-Sha256", valid_602830
  var valid_602831 = header.getOrDefault("X-Amz-Date")
  valid_602831 = validateParameter(valid_602831, JString, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "X-Amz-Date", valid_602831
  var valid_602832 = header.getOrDefault("X-Amz-Credential")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Credential", valid_602832
  var valid_602833 = header.getOrDefault("X-Amz-Security-Token")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Security-Token", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-Algorithm")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Algorithm", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-SignedHeaders", valid_602835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602836: Call_GetDescribeDBParameters_602820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602836.validator(path, query, header, formData, body)
  let scheme = call_602836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602836.url(scheme.get, call_602836.host, call_602836.base,
                         call_602836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602836, url, valid)

proc call*(call_602837: Call_GetDescribeDBParameters_602820;
          DBParameterGroupName: string; Marker: string = ""; Source: string = "";
          Action: string = "DescribeDBParameters"; Version: string = "2013-01-10";
          MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameters
  ##   Marker: string
  ##   DBParameterGroupName: string (required)
  ##   Source: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602838 = newJObject()
  add(query_602838, "Marker", newJString(Marker))
  add(query_602838, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602838, "Source", newJString(Source))
  add(query_602838, "Action", newJString(Action))
  add(query_602838, "Version", newJString(Version))
  add(query_602838, "MaxRecords", newJInt(MaxRecords))
  result = call_602837.call(nil, query_602838, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_602820(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_602821, base: "/",
    url: url_GetDescribeDBParameters_602822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_602877 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSecurityGroups_602879(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSecurityGroups_602878(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602880 = query.getOrDefault("Action")
  valid_602880 = validateParameter(valid_602880, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_602880 != nil:
    section.add "Action", valid_602880
  var valid_602881 = query.getOrDefault("Version")
  valid_602881 = validateParameter(valid_602881, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602881 != nil:
    section.add "Version", valid_602881
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
  var valid_602882 = header.getOrDefault("X-Amz-Signature")
  valid_602882 = validateParameter(valid_602882, JString, required = false,
                                 default = nil)
  if valid_602882 != nil:
    section.add "X-Amz-Signature", valid_602882
  var valid_602883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "X-Amz-Content-Sha256", valid_602883
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Credential")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Credential", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Security-Token")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Security-Token", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Algorithm")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Algorithm", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-SignedHeaders", valid_602888
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  section = newJObject()
  var valid_602889 = formData.getOrDefault("DBSecurityGroupName")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "DBSecurityGroupName", valid_602889
  var valid_602890 = formData.getOrDefault("MaxRecords")
  valid_602890 = validateParameter(valid_602890, JInt, required = false, default = nil)
  if valid_602890 != nil:
    section.add "MaxRecords", valid_602890
  var valid_602891 = formData.getOrDefault("Marker")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "Marker", valid_602891
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602892: Call_PostDescribeDBSecurityGroups_602877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602892.validator(path, query, header, formData, body)
  let scheme = call_602892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602892.url(scheme.get, call_602892.host, call_602892.base,
                         call_602892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602892, url, valid)

proc call*(call_602893: Call_PostDescribeDBSecurityGroups_602877;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602894 = newJObject()
  var formData_602895 = newJObject()
  add(formData_602895, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_602895, "MaxRecords", newJInt(MaxRecords))
  add(formData_602895, "Marker", newJString(Marker))
  add(query_602894, "Action", newJString(Action))
  add(query_602894, "Version", newJString(Version))
  result = call_602893.call(nil, query_602894, nil, formData_602895, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_602877(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_602878, base: "/",
    url: url_PostDescribeDBSecurityGroups_602879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_602859 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSecurityGroups_602861(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSecurityGroups_602860(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBSecurityGroupName: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602862 = query.getOrDefault("Marker")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "Marker", valid_602862
  var valid_602863 = query.getOrDefault("DBSecurityGroupName")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "DBSecurityGroupName", valid_602863
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602864 = query.getOrDefault("Action")
  valid_602864 = validateParameter(valid_602864, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_602864 != nil:
    section.add "Action", valid_602864
  var valid_602865 = query.getOrDefault("Version")
  valid_602865 = validateParameter(valid_602865, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602865 != nil:
    section.add "Version", valid_602865
  var valid_602866 = query.getOrDefault("MaxRecords")
  valid_602866 = validateParameter(valid_602866, JInt, required = false, default = nil)
  if valid_602866 != nil:
    section.add "MaxRecords", valid_602866
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
  var valid_602867 = header.getOrDefault("X-Amz-Signature")
  valid_602867 = validateParameter(valid_602867, JString, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "X-Amz-Signature", valid_602867
  var valid_602868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "X-Amz-Content-Sha256", valid_602868
  var valid_602869 = header.getOrDefault("X-Amz-Date")
  valid_602869 = validateParameter(valid_602869, JString, required = false,
                                 default = nil)
  if valid_602869 != nil:
    section.add "X-Amz-Date", valid_602869
  var valid_602870 = header.getOrDefault("X-Amz-Credential")
  valid_602870 = validateParameter(valid_602870, JString, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "X-Amz-Credential", valid_602870
  var valid_602871 = header.getOrDefault("X-Amz-Security-Token")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Security-Token", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Algorithm")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Algorithm", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-SignedHeaders", valid_602873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602874: Call_GetDescribeDBSecurityGroups_602859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602874.validator(path, query, header, formData, body)
  let scheme = call_602874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602874.url(scheme.get, call_602874.host, call_602874.base,
                         call_602874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602874, url, valid)

proc call*(call_602875: Call_GetDescribeDBSecurityGroups_602859;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602876 = newJObject()
  add(query_602876, "Marker", newJString(Marker))
  add(query_602876, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602876, "Action", newJString(Action))
  add(query_602876, "Version", newJString(Version))
  add(query_602876, "MaxRecords", newJInt(MaxRecords))
  result = call_602875.call(nil, query_602876, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_602859(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_602860, base: "/",
    url: url_GetDescribeDBSecurityGroups_602861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_602916 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSnapshots_602918(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBSnapshots_602917(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602919 = query.getOrDefault("Action")
  valid_602919 = validateParameter(valid_602919, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602919 != nil:
    section.add "Action", valid_602919
  var valid_602920 = query.getOrDefault("Version")
  valid_602920 = validateParameter(valid_602920, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602920 != nil:
    section.add "Version", valid_602920
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
  var valid_602921 = header.getOrDefault("X-Amz-Signature")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Signature", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Content-Sha256", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Date")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Date", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Credential")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Credential", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Security-Token")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Security-Token", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Algorithm")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Algorithm", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-SignedHeaders", valid_602927
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_602928 = formData.getOrDefault("SnapshotType")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "SnapshotType", valid_602928
  var valid_602929 = formData.getOrDefault("MaxRecords")
  valid_602929 = validateParameter(valid_602929, JInt, required = false, default = nil)
  if valid_602929 != nil:
    section.add "MaxRecords", valid_602929
  var valid_602930 = formData.getOrDefault("Marker")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "Marker", valid_602930
  var valid_602931 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "DBInstanceIdentifier", valid_602931
  var valid_602932 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "DBSnapshotIdentifier", valid_602932
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602933: Call_PostDescribeDBSnapshots_602916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602933.validator(path, query, header, formData, body)
  let scheme = call_602933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602933.url(scheme.get, call_602933.host, call_602933.base,
                         call_602933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602933, url, valid)

proc call*(call_602934: Call_PostDescribeDBSnapshots_602916;
          SnapshotType: string = ""; MaxRecords: int = 0; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSnapshots
  ##   SnapshotType: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602935 = newJObject()
  var formData_602936 = newJObject()
  add(formData_602936, "SnapshotType", newJString(SnapshotType))
  add(formData_602936, "MaxRecords", newJInt(MaxRecords))
  add(formData_602936, "Marker", newJString(Marker))
  add(formData_602936, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602936, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602935, "Action", newJString(Action))
  add(query_602935, "Version", newJString(Version))
  result = call_602934.call(nil, query_602935, nil, formData_602936, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_602916(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_602917, base: "/",
    url: url_PostDescribeDBSnapshots_602918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_602896 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSnapshots_602898(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBSnapshots_602897(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   SnapshotType: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602899 = query.getOrDefault("Marker")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "Marker", valid_602899
  var valid_602900 = query.getOrDefault("DBInstanceIdentifier")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "DBInstanceIdentifier", valid_602900
  var valid_602901 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "DBSnapshotIdentifier", valid_602901
  var valid_602902 = query.getOrDefault("SnapshotType")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "SnapshotType", valid_602902
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602903 = query.getOrDefault("Action")
  valid_602903 = validateParameter(valid_602903, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602903 != nil:
    section.add "Action", valid_602903
  var valid_602904 = query.getOrDefault("Version")
  valid_602904 = validateParameter(valid_602904, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602904 != nil:
    section.add "Version", valid_602904
  var valid_602905 = query.getOrDefault("MaxRecords")
  valid_602905 = validateParameter(valid_602905, JInt, required = false, default = nil)
  if valid_602905 != nil:
    section.add "MaxRecords", valid_602905
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
  var valid_602906 = header.getOrDefault("X-Amz-Signature")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Signature", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Content-Sha256", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-Date")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Date", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Credential")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Credential", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Security-Token")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Security-Token", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Algorithm")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Algorithm", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-SignedHeaders", valid_602912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602913: Call_GetDescribeDBSnapshots_602896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602913.validator(path, query, header, formData, body)
  let scheme = call_602913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602913.url(scheme.get, call_602913.host, call_602913.base,
                         call_602913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602913, url, valid)

proc call*(call_602914: Call_GetDescribeDBSnapshots_602896; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          SnapshotType: string = ""; Action: string = "DescribeDBSnapshots";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSnapshots
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602915 = newJObject()
  add(query_602915, "Marker", newJString(Marker))
  add(query_602915, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602915, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602915, "SnapshotType", newJString(SnapshotType))
  add(query_602915, "Action", newJString(Action))
  add(query_602915, "Version", newJString(Version))
  add(query_602915, "MaxRecords", newJInt(MaxRecords))
  result = call_602914.call(nil, query_602915, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_602896(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_602897, base: "/",
    url: url_GetDescribeDBSnapshots_602898, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_602955 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSubnetGroups_602957(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_602956(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602958 = query.getOrDefault("Action")
  valid_602958 = validateParameter(valid_602958, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602958 != nil:
    section.add "Action", valid_602958
  var valid_602959 = query.getOrDefault("Version")
  valid_602959 = validateParameter(valid_602959, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602959 != nil:
    section.add "Version", valid_602959
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
  var valid_602960 = header.getOrDefault("X-Amz-Signature")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "X-Amz-Signature", valid_602960
  var valid_602961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "X-Amz-Content-Sha256", valid_602961
  var valid_602962 = header.getOrDefault("X-Amz-Date")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-Date", valid_602962
  var valid_602963 = header.getOrDefault("X-Amz-Credential")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "X-Amz-Credential", valid_602963
  var valid_602964 = header.getOrDefault("X-Amz-Security-Token")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "X-Amz-Security-Token", valid_602964
  var valid_602965 = header.getOrDefault("X-Amz-Algorithm")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "X-Amz-Algorithm", valid_602965
  var valid_602966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602966 = validateParameter(valid_602966, JString, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "X-Amz-SignedHeaders", valid_602966
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  section = newJObject()
  var valid_602967 = formData.getOrDefault("MaxRecords")
  valid_602967 = validateParameter(valid_602967, JInt, required = false, default = nil)
  if valid_602967 != nil:
    section.add "MaxRecords", valid_602967
  var valid_602968 = formData.getOrDefault("Marker")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "Marker", valid_602968
  var valid_602969 = formData.getOrDefault("DBSubnetGroupName")
  valid_602969 = validateParameter(valid_602969, JString, required = false,
                                 default = nil)
  if valid_602969 != nil:
    section.add "DBSubnetGroupName", valid_602969
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602970: Call_PostDescribeDBSubnetGroups_602955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602970.validator(path, query, header, formData, body)
  let scheme = call_602970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602970.url(scheme.get, call_602970.host, call_602970.base,
                         call_602970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602970, url, valid)

proc call*(call_602971: Call_PostDescribeDBSubnetGroups_602955;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_602972 = newJObject()
  var formData_602973 = newJObject()
  add(formData_602973, "MaxRecords", newJInt(MaxRecords))
  add(formData_602973, "Marker", newJString(Marker))
  add(query_602972, "Action", newJString(Action))
  add(formData_602973, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602972, "Version", newJString(Version))
  result = call_602971.call(nil, query_602972, nil, formData_602973, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_602955(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_602956, base: "/",
    url: url_PostDescribeDBSubnetGroups_602957,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_602937 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSubnetGroups_602939(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_602938(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602940 = query.getOrDefault("Marker")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "Marker", valid_602940
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602941 = query.getOrDefault("Action")
  valid_602941 = validateParameter(valid_602941, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602941 != nil:
    section.add "Action", valid_602941
  var valid_602942 = query.getOrDefault("DBSubnetGroupName")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "DBSubnetGroupName", valid_602942
  var valid_602943 = query.getOrDefault("Version")
  valid_602943 = validateParameter(valid_602943, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602943 != nil:
    section.add "Version", valid_602943
  var valid_602944 = query.getOrDefault("MaxRecords")
  valid_602944 = validateParameter(valid_602944, JInt, required = false, default = nil)
  if valid_602944 != nil:
    section.add "MaxRecords", valid_602944
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
  var valid_602945 = header.getOrDefault("X-Amz-Signature")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "X-Amz-Signature", valid_602945
  var valid_602946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "X-Amz-Content-Sha256", valid_602946
  var valid_602947 = header.getOrDefault("X-Amz-Date")
  valid_602947 = validateParameter(valid_602947, JString, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "X-Amz-Date", valid_602947
  var valid_602948 = header.getOrDefault("X-Amz-Credential")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "X-Amz-Credential", valid_602948
  var valid_602949 = header.getOrDefault("X-Amz-Security-Token")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-Security-Token", valid_602949
  var valid_602950 = header.getOrDefault("X-Amz-Algorithm")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-Algorithm", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-SignedHeaders", valid_602951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602952: Call_GetDescribeDBSubnetGroups_602937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602952.validator(path, query, header, formData, body)
  let scheme = call_602952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602952.url(scheme.get, call_602952.host, call_602952.base,
                         call_602952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602952, url, valid)

proc call*(call_602953: Call_GetDescribeDBSubnetGroups_602937; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602954 = newJObject()
  add(query_602954, "Marker", newJString(Marker))
  add(query_602954, "Action", newJString(Action))
  add(query_602954, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602954, "Version", newJString(Version))
  add(query_602954, "MaxRecords", newJInt(MaxRecords))
  result = call_602953.call(nil, query_602954, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_602937(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_602938, base: "/",
    url: url_GetDescribeDBSubnetGroups_602939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_602992 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEngineDefaultParameters_602994(protocol: Scheme; host: string;
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

proc validate_PostDescribeEngineDefaultParameters_602993(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602995 = query.getOrDefault("Action")
  valid_602995 = validateParameter(valid_602995, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602995 != nil:
    section.add "Action", valid_602995
  var valid_602996 = query.getOrDefault("Version")
  valid_602996 = validateParameter(valid_602996, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602996 != nil:
    section.add "Version", valid_602996
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
  var valid_602997 = header.getOrDefault("X-Amz-Signature")
  valid_602997 = validateParameter(valid_602997, JString, required = false,
                                 default = nil)
  if valid_602997 != nil:
    section.add "X-Amz-Signature", valid_602997
  var valid_602998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602998 = validateParameter(valid_602998, JString, required = false,
                                 default = nil)
  if valid_602998 != nil:
    section.add "X-Amz-Content-Sha256", valid_602998
  var valid_602999 = header.getOrDefault("X-Amz-Date")
  valid_602999 = validateParameter(valid_602999, JString, required = false,
                                 default = nil)
  if valid_602999 != nil:
    section.add "X-Amz-Date", valid_602999
  var valid_603000 = header.getOrDefault("X-Amz-Credential")
  valid_603000 = validateParameter(valid_603000, JString, required = false,
                                 default = nil)
  if valid_603000 != nil:
    section.add "X-Amz-Credential", valid_603000
  var valid_603001 = header.getOrDefault("X-Amz-Security-Token")
  valid_603001 = validateParameter(valid_603001, JString, required = false,
                                 default = nil)
  if valid_603001 != nil:
    section.add "X-Amz-Security-Token", valid_603001
  var valid_603002 = header.getOrDefault("X-Amz-Algorithm")
  valid_603002 = validateParameter(valid_603002, JString, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "X-Amz-Algorithm", valid_603002
  var valid_603003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603003 = validateParameter(valid_603003, JString, required = false,
                                 default = nil)
  if valid_603003 != nil:
    section.add "X-Amz-SignedHeaders", valid_603003
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_603004 = formData.getOrDefault("MaxRecords")
  valid_603004 = validateParameter(valid_603004, JInt, required = false, default = nil)
  if valid_603004 != nil:
    section.add "MaxRecords", valid_603004
  var valid_603005 = formData.getOrDefault("Marker")
  valid_603005 = validateParameter(valid_603005, JString, required = false,
                                 default = nil)
  if valid_603005 != nil:
    section.add "Marker", valid_603005
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_603006 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603006 = validateParameter(valid_603006, JString, required = true,
                                 default = nil)
  if valid_603006 != nil:
    section.add "DBParameterGroupFamily", valid_603006
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603007: Call_PostDescribeEngineDefaultParameters_602992;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603007.validator(path, query, header, formData, body)
  let scheme = call_603007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603007.url(scheme.get, call_603007.host, call_603007.base,
                         call_603007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603007, url, valid)

proc call*(call_603008: Call_PostDescribeEngineDefaultParameters_602992;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_603009 = newJObject()
  var formData_603010 = newJObject()
  add(formData_603010, "MaxRecords", newJInt(MaxRecords))
  add(formData_603010, "Marker", newJString(Marker))
  add(query_603009, "Action", newJString(Action))
  add(query_603009, "Version", newJString(Version))
  add(formData_603010, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_603008.call(nil, query_603009, nil, formData_603010, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_602992(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_602993, base: "/",
    url: url_PostDescribeEngineDefaultParameters_602994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_602974 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEngineDefaultParameters_602976(protocol: Scheme; host: string;
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

proc validate_GetDescribeEngineDefaultParameters_602975(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602977 = query.getOrDefault("Marker")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "Marker", valid_602977
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602978 = query.getOrDefault("DBParameterGroupFamily")
  valid_602978 = validateParameter(valid_602978, JString, required = true,
                                 default = nil)
  if valid_602978 != nil:
    section.add "DBParameterGroupFamily", valid_602978
  var valid_602979 = query.getOrDefault("Action")
  valid_602979 = validateParameter(valid_602979, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602979 != nil:
    section.add "Action", valid_602979
  var valid_602980 = query.getOrDefault("Version")
  valid_602980 = validateParameter(valid_602980, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602980 != nil:
    section.add "Version", valid_602980
  var valid_602981 = query.getOrDefault("MaxRecords")
  valid_602981 = validateParameter(valid_602981, JInt, required = false, default = nil)
  if valid_602981 != nil:
    section.add "MaxRecords", valid_602981
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
  var valid_602982 = header.getOrDefault("X-Amz-Signature")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "X-Amz-Signature", valid_602982
  var valid_602983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602983 = validateParameter(valid_602983, JString, required = false,
                                 default = nil)
  if valid_602983 != nil:
    section.add "X-Amz-Content-Sha256", valid_602983
  var valid_602984 = header.getOrDefault("X-Amz-Date")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "X-Amz-Date", valid_602984
  var valid_602985 = header.getOrDefault("X-Amz-Credential")
  valid_602985 = validateParameter(valid_602985, JString, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "X-Amz-Credential", valid_602985
  var valid_602986 = header.getOrDefault("X-Amz-Security-Token")
  valid_602986 = validateParameter(valid_602986, JString, required = false,
                                 default = nil)
  if valid_602986 != nil:
    section.add "X-Amz-Security-Token", valid_602986
  var valid_602987 = header.getOrDefault("X-Amz-Algorithm")
  valid_602987 = validateParameter(valid_602987, JString, required = false,
                                 default = nil)
  if valid_602987 != nil:
    section.add "X-Amz-Algorithm", valid_602987
  var valid_602988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "X-Amz-SignedHeaders", valid_602988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602989: Call_GetDescribeEngineDefaultParameters_602974;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602989.validator(path, query, header, formData, body)
  let scheme = call_602989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602989.url(scheme.get, call_602989.host, call_602989.base,
                         call_602989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602989, url, valid)

proc call*(call_602990: Call_GetDescribeEngineDefaultParameters_602974;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602991 = newJObject()
  add(query_602991, "Marker", newJString(Marker))
  add(query_602991, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602991, "Action", newJString(Action))
  add(query_602991, "Version", newJString(Version))
  add(query_602991, "MaxRecords", newJInt(MaxRecords))
  result = call_602990.call(nil, query_602991, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_602974(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_602975, base: "/",
    url: url_GetDescribeEngineDefaultParameters_602976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_603027 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEventCategories_603029(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_603028(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603030 = query.getOrDefault("Action")
  valid_603030 = validateParameter(valid_603030, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_603030 != nil:
    section.add "Action", valid_603030
  var valid_603031 = query.getOrDefault("Version")
  valid_603031 = validateParameter(valid_603031, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603031 != nil:
    section.add "Version", valid_603031
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
  var valid_603032 = header.getOrDefault("X-Amz-Signature")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Signature", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Content-Sha256", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Date")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Date", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Credential")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Credential", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Security-Token")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Security-Token", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Algorithm")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Algorithm", valid_603037
  var valid_603038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-SignedHeaders", valid_603038
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_603039 = formData.getOrDefault("SourceType")
  valid_603039 = validateParameter(valid_603039, JString, required = false,
                                 default = nil)
  if valid_603039 != nil:
    section.add "SourceType", valid_603039
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603040: Call_PostDescribeEventCategories_603027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603040.validator(path, query, header, formData, body)
  let scheme = call_603040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603040.url(scheme.get, call_603040.host, call_603040.base,
                         call_603040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603040, url, valid)

proc call*(call_603041: Call_PostDescribeEventCategories_603027;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603042 = newJObject()
  var formData_603043 = newJObject()
  add(formData_603043, "SourceType", newJString(SourceType))
  add(query_603042, "Action", newJString(Action))
  add(query_603042, "Version", newJString(Version))
  result = call_603041.call(nil, query_603042, nil, formData_603043, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_603027(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_603028, base: "/",
    url: url_PostDescribeEventCategories_603029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_603011 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEventCategories_603013(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_603012(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603014 = query.getOrDefault("SourceType")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "SourceType", valid_603014
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603015 = query.getOrDefault("Action")
  valid_603015 = validateParameter(valid_603015, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_603015 != nil:
    section.add "Action", valid_603015
  var valid_603016 = query.getOrDefault("Version")
  valid_603016 = validateParameter(valid_603016, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603016 != nil:
    section.add "Version", valid_603016
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
  var valid_603017 = header.getOrDefault("X-Amz-Signature")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "X-Amz-Signature", valid_603017
  var valid_603018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "X-Amz-Content-Sha256", valid_603018
  var valid_603019 = header.getOrDefault("X-Amz-Date")
  valid_603019 = validateParameter(valid_603019, JString, required = false,
                                 default = nil)
  if valid_603019 != nil:
    section.add "X-Amz-Date", valid_603019
  var valid_603020 = header.getOrDefault("X-Amz-Credential")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "X-Amz-Credential", valid_603020
  var valid_603021 = header.getOrDefault("X-Amz-Security-Token")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "X-Amz-Security-Token", valid_603021
  var valid_603022 = header.getOrDefault("X-Amz-Algorithm")
  valid_603022 = validateParameter(valid_603022, JString, required = false,
                                 default = nil)
  if valid_603022 != nil:
    section.add "X-Amz-Algorithm", valid_603022
  var valid_603023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603023 = validateParameter(valid_603023, JString, required = false,
                                 default = nil)
  if valid_603023 != nil:
    section.add "X-Amz-SignedHeaders", valid_603023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603024: Call_GetDescribeEventCategories_603011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603024.validator(path, query, header, formData, body)
  let scheme = call_603024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603024.url(scheme.get, call_603024.host, call_603024.base,
                         call_603024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603024, url, valid)

proc call*(call_603025: Call_GetDescribeEventCategories_603011;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603026 = newJObject()
  add(query_603026, "SourceType", newJString(SourceType))
  add(query_603026, "Action", newJString(Action))
  add(query_603026, "Version", newJString(Version))
  result = call_603025.call(nil, query_603026, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_603011(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_603012, base: "/",
    url: url_GetDescribeEventCategories_603013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_603062 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEventSubscriptions_603064(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventSubscriptions_603063(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603065 = query.getOrDefault("Action")
  valid_603065 = validateParameter(valid_603065, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_603065 != nil:
    section.add "Action", valid_603065
  var valid_603066 = query.getOrDefault("Version")
  valid_603066 = validateParameter(valid_603066, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603066 != nil:
    section.add "Version", valid_603066
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
  var valid_603067 = header.getOrDefault("X-Amz-Signature")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Signature", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Content-Sha256", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Date")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Date", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Credential")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Credential", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Security-Token")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Security-Token", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Algorithm")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Algorithm", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-SignedHeaders", valid_603073
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  section = newJObject()
  var valid_603074 = formData.getOrDefault("MaxRecords")
  valid_603074 = validateParameter(valid_603074, JInt, required = false, default = nil)
  if valid_603074 != nil:
    section.add "MaxRecords", valid_603074
  var valid_603075 = formData.getOrDefault("Marker")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "Marker", valid_603075
  var valid_603076 = formData.getOrDefault("SubscriptionName")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "SubscriptionName", valid_603076
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603077: Call_PostDescribeEventSubscriptions_603062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603077.validator(path, query, header, formData, body)
  let scheme = call_603077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603077.url(scheme.get, call_603077.host, call_603077.base,
                         call_603077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603077, url, valid)

proc call*(call_603078: Call_PostDescribeEventSubscriptions_603062;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603079 = newJObject()
  var formData_603080 = newJObject()
  add(formData_603080, "MaxRecords", newJInt(MaxRecords))
  add(formData_603080, "Marker", newJString(Marker))
  add(formData_603080, "SubscriptionName", newJString(SubscriptionName))
  add(query_603079, "Action", newJString(Action))
  add(query_603079, "Version", newJString(Version))
  result = call_603078.call(nil, query_603079, nil, formData_603080, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_603062(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_603063, base: "/",
    url: url_PostDescribeEventSubscriptions_603064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_603044 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEventSubscriptions_603046(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventSubscriptions_603045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603047 = query.getOrDefault("Marker")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "Marker", valid_603047
  var valid_603048 = query.getOrDefault("SubscriptionName")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "SubscriptionName", valid_603048
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603049 = query.getOrDefault("Action")
  valid_603049 = validateParameter(valid_603049, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_603049 != nil:
    section.add "Action", valid_603049
  var valid_603050 = query.getOrDefault("Version")
  valid_603050 = validateParameter(valid_603050, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603050 != nil:
    section.add "Version", valid_603050
  var valid_603051 = query.getOrDefault("MaxRecords")
  valid_603051 = validateParameter(valid_603051, JInt, required = false, default = nil)
  if valid_603051 != nil:
    section.add "MaxRecords", valid_603051
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
  var valid_603052 = header.getOrDefault("X-Amz-Signature")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Signature", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Content-Sha256", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Date")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Date", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Credential")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Credential", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-Security-Token")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-Security-Token", valid_603056
  var valid_603057 = header.getOrDefault("X-Amz-Algorithm")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Algorithm", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-SignedHeaders", valid_603058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603059: Call_GetDescribeEventSubscriptions_603044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603059.validator(path, query, header, formData, body)
  let scheme = call_603059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603059.url(scheme.get, call_603059.host, call_603059.base,
                         call_603059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603059, url, valid)

proc call*(call_603060: Call_GetDescribeEventSubscriptions_603044;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_603061 = newJObject()
  add(query_603061, "Marker", newJString(Marker))
  add(query_603061, "SubscriptionName", newJString(SubscriptionName))
  add(query_603061, "Action", newJString(Action))
  add(query_603061, "Version", newJString(Version))
  add(query_603061, "MaxRecords", newJInt(MaxRecords))
  result = call_603060.call(nil, query_603061, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_603044(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_603045, base: "/",
    url: url_GetDescribeEventSubscriptions_603046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_603104 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEvents_603106(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_603105(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603107 = query.getOrDefault("Action")
  valid_603107 = validateParameter(valid_603107, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_603107 != nil:
    section.add "Action", valid_603107
  var valid_603108 = query.getOrDefault("Version")
  valid_603108 = validateParameter(valid_603108, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603108 != nil:
    section.add "Version", valid_603108
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
  var valid_603109 = header.getOrDefault("X-Amz-Signature")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Signature", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Content-Sha256", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Date")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Date", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Security-Token")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Security-Token", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Algorithm")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Algorithm", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-SignedHeaders", valid_603115
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SourceIdentifier: JString
  ##   SourceType: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   StartTime: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_603116 = formData.getOrDefault("MaxRecords")
  valid_603116 = validateParameter(valid_603116, JInt, required = false, default = nil)
  if valid_603116 != nil:
    section.add "MaxRecords", valid_603116
  var valid_603117 = formData.getOrDefault("Marker")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "Marker", valid_603117
  var valid_603118 = formData.getOrDefault("SourceIdentifier")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "SourceIdentifier", valid_603118
  var valid_603119 = formData.getOrDefault("SourceType")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_603119 != nil:
    section.add "SourceType", valid_603119
  var valid_603120 = formData.getOrDefault("Duration")
  valid_603120 = validateParameter(valid_603120, JInt, required = false, default = nil)
  if valid_603120 != nil:
    section.add "Duration", valid_603120
  var valid_603121 = formData.getOrDefault("EndTime")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "EndTime", valid_603121
  var valid_603122 = formData.getOrDefault("StartTime")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "StartTime", valid_603122
  var valid_603123 = formData.getOrDefault("EventCategories")
  valid_603123 = validateParameter(valid_603123, JArray, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "EventCategories", valid_603123
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603124: Call_PostDescribeEvents_603104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603124.validator(path, query, header, formData, body)
  let scheme = call_603124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603124.url(scheme.get, call_603124.host, call_603124.base,
                         call_603124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603124, url, valid)

proc call*(call_603125: Call_PostDescribeEvents_603104; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Version: string = "2013-01-10"): Recallable =
  ## postDescribeEvents
  ##   MaxRecords: int
  ##   Marker: string
  ##   SourceIdentifier: string
  ##   SourceType: string
  ##   Duration: int
  ##   EndTime: string
  ##   StartTime: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603126 = newJObject()
  var formData_603127 = newJObject()
  add(formData_603127, "MaxRecords", newJInt(MaxRecords))
  add(formData_603127, "Marker", newJString(Marker))
  add(formData_603127, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_603127, "SourceType", newJString(SourceType))
  add(formData_603127, "Duration", newJInt(Duration))
  add(formData_603127, "EndTime", newJString(EndTime))
  add(formData_603127, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_603127.add "EventCategories", EventCategories
  add(query_603126, "Action", newJString(Action))
  add(query_603126, "Version", newJString(Version))
  result = call_603125.call(nil, query_603126, nil, formData_603127, nil)

var postDescribeEvents* = Call_PostDescribeEvents_603104(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_603105, base: "/",
    url: url_PostDescribeEvents_603106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_603081 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEvents_603083(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_603082(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   SourceType: JString
  ##   SourceIdentifier: JString
  ##   EventCategories: JArray
  ##   Action: JString (required)
  ##   StartTime: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603084 = query.getOrDefault("Marker")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "Marker", valid_603084
  var valid_603085 = query.getOrDefault("SourceType")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_603085 != nil:
    section.add "SourceType", valid_603085
  var valid_603086 = query.getOrDefault("SourceIdentifier")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "SourceIdentifier", valid_603086
  var valid_603087 = query.getOrDefault("EventCategories")
  valid_603087 = validateParameter(valid_603087, JArray, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "EventCategories", valid_603087
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603088 = query.getOrDefault("Action")
  valid_603088 = validateParameter(valid_603088, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_603088 != nil:
    section.add "Action", valid_603088
  var valid_603089 = query.getOrDefault("StartTime")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "StartTime", valid_603089
  var valid_603090 = query.getOrDefault("Duration")
  valid_603090 = validateParameter(valid_603090, JInt, required = false, default = nil)
  if valid_603090 != nil:
    section.add "Duration", valid_603090
  var valid_603091 = query.getOrDefault("EndTime")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "EndTime", valid_603091
  var valid_603092 = query.getOrDefault("Version")
  valid_603092 = validateParameter(valid_603092, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603092 != nil:
    section.add "Version", valid_603092
  var valid_603093 = query.getOrDefault("MaxRecords")
  valid_603093 = validateParameter(valid_603093, JInt, required = false, default = nil)
  if valid_603093 != nil:
    section.add "MaxRecords", valid_603093
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
  var valid_603094 = header.getOrDefault("X-Amz-Signature")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Signature", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Content-Sha256", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Date")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Date", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Security-Token")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Security-Token", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Algorithm")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Algorithm", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-SignedHeaders", valid_603100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603101: Call_GetDescribeEvents_603081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603101.validator(path, query, header, formData, body)
  let scheme = call_603101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603101.url(scheme.get, call_603101.host, call_603101.base,
                         call_603101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603101, url, valid)

proc call*(call_603102: Call_GetDescribeEvents_603081; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeEvents
  ##   Marker: string
  ##   SourceType: string
  ##   SourceIdentifier: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   StartTime: string
  ##   Duration: int
  ##   EndTime: string
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_603103 = newJObject()
  add(query_603103, "Marker", newJString(Marker))
  add(query_603103, "SourceType", newJString(SourceType))
  add(query_603103, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_603103.add "EventCategories", EventCategories
  add(query_603103, "Action", newJString(Action))
  add(query_603103, "StartTime", newJString(StartTime))
  add(query_603103, "Duration", newJInt(Duration))
  add(query_603103, "EndTime", newJString(EndTime))
  add(query_603103, "Version", newJString(Version))
  add(query_603103, "MaxRecords", newJInt(MaxRecords))
  result = call_603102.call(nil, query_603103, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_603081(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_603082,
    base: "/", url: url_GetDescribeEvents_603083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_603147 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOptionGroupOptions_603149(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroupOptions_603148(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603150 = query.getOrDefault("Action")
  valid_603150 = validateParameter(valid_603150, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_603150 != nil:
    section.add "Action", valid_603150
  var valid_603151 = query.getOrDefault("Version")
  valid_603151 = validateParameter(valid_603151, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603151 != nil:
    section.add "Version", valid_603151
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
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Date")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Date", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Credential")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Credential", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Security-Token")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Security-Token", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Algorithm")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Algorithm", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-SignedHeaders", valid_603158
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_603159 = formData.getOrDefault("MaxRecords")
  valid_603159 = validateParameter(valid_603159, JInt, required = false, default = nil)
  if valid_603159 != nil:
    section.add "MaxRecords", valid_603159
  var valid_603160 = formData.getOrDefault("Marker")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "Marker", valid_603160
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_603161 = formData.getOrDefault("EngineName")
  valid_603161 = validateParameter(valid_603161, JString, required = true,
                                 default = nil)
  if valid_603161 != nil:
    section.add "EngineName", valid_603161
  var valid_603162 = formData.getOrDefault("MajorEngineVersion")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "MajorEngineVersion", valid_603162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603163: Call_PostDescribeOptionGroupOptions_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603163.validator(path, query, header, formData, body)
  let scheme = call_603163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603163.url(scheme.get, call_603163.host, call_603163.base,
                         call_603163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603163, url, valid)

proc call*(call_603164: Call_PostDescribeOptionGroupOptions_603147;
          EngineName: string; MaxRecords: int = 0; Marker: string = "";
          MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603165 = newJObject()
  var formData_603166 = newJObject()
  add(formData_603166, "MaxRecords", newJInt(MaxRecords))
  add(formData_603166, "Marker", newJString(Marker))
  add(formData_603166, "EngineName", newJString(EngineName))
  add(formData_603166, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_603165, "Action", newJString(Action))
  add(query_603165, "Version", newJString(Version))
  result = call_603164.call(nil, query_603165, nil, formData_603166, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_603147(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_603148, base: "/",
    url: url_PostDescribeOptionGroupOptions_603149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_603128 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOptionGroupOptions_603130(protocol: Scheme; host: string;
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

proc validate_GetDescribeOptionGroupOptions_603129(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString (required)
  ##   Marker: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_603131 = query.getOrDefault("EngineName")
  valid_603131 = validateParameter(valid_603131, JString, required = true,
                                 default = nil)
  if valid_603131 != nil:
    section.add "EngineName", valid_603131
  var valid_603132 = query.getOrDefault("Marker")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "Marker", valid_603132
  var valid_603133 = query.getOrDefault("Action")
  valid_603133 = validateParameter(valid_603133, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_603133 != nil:
    section.add "Action", valid_603133
  var valid_603134 = query.getOrDefault("Version")
  valid_603134 = validateParameter(valid_603134, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603134 != nil:
    section.add "Version", valid_603134
  var valid_603135 = query.getOrDefault("MaxRecords")
  valid_603135 = validateParameter(valid_603135, JInt, required = false, default = nil)
  if valid_603135 != nil:
    section.add "MaxRecords", valid_603135
  var valid_603136 = query.getOrDefault("MajorEngineVersion")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "MajorEngineVersion", valid_603136
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
  var valid_603137 = header.getOrDefault("X-Amz-Signature")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Signature", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Date")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Date", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Credential")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Credential", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Security-Token")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Security-Token", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Algorithm")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Algorithm", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-SignedHeaders", valid_603143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_GetDescribeOptionGroupOptions_603128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603144, url, valid)

proc call*(call_603145: Call_GetDescribeOptionGroupOptions_603128;
          EngineName: string; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-01-10"; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   EngineName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_603146 = newJObject()
  add(query_603146, "EngineName", newJString(EngineName))
  add(query_603146, "Marker", newJString(Marker))
  add(query_603146, "Action", newJString(Action))
  add(query_603146, "Version", newJString(Version))
  add(query_603146, "MaxRecords", newJInt(MaxRecords))
  add(query_603146, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603145.call(nil, query_603146, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_603128(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_603129, base: "/",
    url: url_GetDescribeOptionGroupOptions_603130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_603187 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOptionGroups_603189(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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

proc validate_PostDescribeOptionGroups_603188(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603190 = query.getOrDefault("Action")
  valid_603190 = validateParameter(valid_603190, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_603190 != nil:
    section.add "Action", valid_603190
  var valid_603191 = query.getOrDefault("Version")
  valid_603191 = validateParameter(valid_603191, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603191 != nil:
    section.add "Version", valid_603191
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
  var valid_603192 = header.getOrDefault("X-Amz-Signature")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Signature", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Content-Sha256", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Date")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Date", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Credential")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Credential", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Algorithm")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Algorithm", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-SignedHeaders", valid_603198
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_603199 = formData.getOrDefault("MaxRecords")
  valid_603199 = validateParameter(valid_603199, JInt, required = false, default = nil)
  if valid_603199 != nil:
    section.add "MaxRecords", valid_603199
  var valid_603200 = formData.getOrDefault("Marker")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "Marker", valid_603200
  var valid_603201 = formData.getOrDefault("EngineName")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "EngineName", valid_603201
  var valid_603202 = formData.getOrDefault("MajorEngineVersion")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "MajorEngineVersion", valid_603202
  var valid_603203 = formData.getOrDefault("OptionGroupName")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "OptionGroupName", valid_603203
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_PostDescribeOptionGroups_603187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603204, url, valid)

proc call*(call_603205: Call_PostDescribeOptionGroups_603187; MaxRecords: int = 0;
          Marker: string = ""; EngineName: string = ""; MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeOptionGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_603206 = newJObject()
  var formData_603207 = newJObject()
  add(formData_603207, "MaxRecords", newJInt(MaxRecords))
  add(formData_603207, "Marker", newJString(Marker))
  add(formData_603207, "EngineName", newJString(EngineName))
  add(formData_603207, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_603206, "Action", newJString(Action))
  add(formData_603207, "OptionGroupName", newJString(OptionGroupName))
  add(query_603206, "Version", newJString(Version))
  result = call_603205.call(nil, query_603206, nil, formData_603207, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_603187(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_603188, base: "/",
    url: url_PostDescribeOptionGroups_603189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_603167 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOptionGroups_603169(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeOptionGroups_603168(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString
  ##   Marker: JString
  ##   Action: JString (required)
  ##   OptionGroupName: JString
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_603170 = query.getOrDefault("EngineName")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "EngineName", valid_603170
  var valid_603171 = query.getOrDefault("Marker")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "Marker", valid_603171
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603172 = query.getOrDefault("Action")
  valid_603172 = validateParameter(valid_603172, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_603172 != nil:
    section.add "Action", valid_603172
  var valid_603173 = query.getOrDefault("OptionGroupName")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "OptionGroupName", valid_603173
  var valid_603174 = query.getOrDefault("Version")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603174 != nil:
    section.add "Version", valid_603174
  var valid_603175 = query.getOrDefault("MaxRecords")
  valid_603175 = validateParameter(valid_603175, JInt, required = false, default = nil)
  if valid_603175 != nil:
    section.add "MaxRecords", valid_603175
  var valid_603176 = query.getOrDefault("MajorEngineVersion")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "MajorEngineVersion", valid_603176
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
  var valid_603177 = header.getOrDefault("X-Amz-Signature")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Signature", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Content-Sha256", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Date")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Date", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Credential")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Credential", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Algorithm")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Algorithm", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-SignedHeaders", valid_603183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603184: Call_GetDescribeOptionGroups_603167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603184.validator(path, query, header, formData, body)
  let scheme = call_603184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603184.url(scheme.get, call_603184.host, call_603184.base,
                         call_603184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603184, url, valid)

proc call*(call_603185: Call_GetDescribeOptionGroups_603167;
          EngineName: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-01-10"; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   EngineName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_603186 = newJObject()
  add(query_603186, "EngineName", newJString(EngineName))
  add(query_603186, "Marker", newJString(Marker))
  add(query_603186, "Action", newJString(Action))
  add(query_603186, "OptionGroupName", newJString(OptionGroupName))
  add(query_603186, "Version", newJString(Version))
  add(query_603186, "MaxRecords", newJInt(MaxRecords))
  add(query_603186, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603185.call(nil, query_603186, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_603167(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_603168, base: "/",
    url: url_GetDescribeOptionGroups_603169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_603230 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOrderableDBInstanceOptions_603232(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_603231(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603233 = query.getOrDefault("Action")
  valid_603233 = validateParameter(valid_603233, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_603233 != nil:
    section.add "Action", valid_603233
  var valid_603234 = query.getOrDefault("Version")
  valid_603234 = validateParameter(valid_603234, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603234 != nil:
    section.add "Version", valid_603234
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
  var valid_603235 = header.getOrDefault("X-Amz-Signature")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Signature", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Content-Sha256", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Date")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Date", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Credential")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Credential", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Security-Token")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Security-Token", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Algorithm")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Algorithm", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-SignedHeaders", valid_603241
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString (required)
  ##   Vpc: JBool
  ##   LicenseModel: JString
  section = newJObject()
  var valid_603242 = formData.getOrDefault("DBInstanceClass")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "DBInstanceClass", valid_603242
  var valid_603243 = formData.getOrDefault("MaxRecords")
  valid_603243 = validateParameter(valid_603243, JInt, required = false, default = nil)
  if valid_603243 != nil:
    section.add "MaxRecords", valid_603243
  var valid_603244 = formData.getOrDefault("EngineVersion")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "EngineVersion", valid_603244
  var valid_603245 = formData.getOrDefault("Marker")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "Marker", valid_603245
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603246 = formData.getOrDefault("Engine")
  valid_603246 = validateParameter(valid_603246, JString, required = true,
                                 default = nil)
  if valid_603246 != nil:
    section.add "Engine", valid_603246
  var valid_603247 = formData.getOrDefault("Vpc")
  valid_603247 = validateParameter(valid_603247, JBool, required = false, default = nil)
  if valid_603247 != nil:
    section.add "Vpc", valid_603247
  var valid_603248 = formData.getOrDefault("LicenseModel")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "LicenseModel", valid_603248
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_PostDescribeOrderableDBInstanceOptions_603230;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603249, url, valid)

proc call*(call_603250: Call_PostDescribeOrderableDBInstanceOptions_603230;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   DBInstanceClass: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string (required)
  ##   Vpc: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Version: string (required)
  var query_603251 = newJObject()
  var formData_603252 = newJObject()
  add(formData_603252, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603252, "MaxRecords", newJInt(MaxRecords))
  add(formData_603252, "EngineVersion", newJString(EngineVersion))
  add(formData_603252, "Marker", newJString(Marker))
  add(formData_603252, "Engine", newJString(Engine))
  add(formData_603252, "Vpc", newJBool(Vpc))
  add(query_603251, "Action", newJString(Action))
  add(formData_603252, "LicenseModel", newJString(LicenseModel))
  add(query_603251, "Version", newJString(Version))
  result = call_603250.call(nil, query_603251, nil, formData_603252, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_603230(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_603231, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_603232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_603208 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOrderableDBInstanceOptions_603210(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_603209(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   Engine: JString (required)
  ##   LicenseModel: JString
  ##   Vpc: JBool
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603211 = query.getOrDefault("Marker")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "Marker", valid_603211
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_603212 = query.getOrDefault("Engine")
  valid_603212 = validateParameter(valid_603212, JString, required = true,
                                 default = nil)
  if valid_603212 != nil:
    section.add "Engine", valid_603212
  var valid_603213 = query.getOrDefault("LicenseModel")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "LicenseModel", valid_603213
  var valid_603214 = query.getOrDefault("Vpc")
  valid_603214 = validateParameter(valid_603214, JBool, required = false, default = nil)
  if valid_603214 != nil:
    section.add "Vpc", valid_603214
  var valid_603215 = query.getOrDefault("EngineVersion")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "EngineVersion", valid_603215
  var valid_603216 = query.getOrDefault("Action")
  valid_603216 = validateParameter(valid_603216, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_603216 != nil:
    section.add "Action", valid_603216
  var valid_603217 = query.getOrDefault("Version")
  valid_603217 = validateParameter(valid_603217, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603217 != nil:
    section.add "Version", valid_603217
  var valid_603218 = query.getOrDefault("DBInstanceClass")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "DBInstanceClass", valid_603218
  var valid_603219 = query.getOrDefault("MaxRecords")
  valid_603219 = validateParameter(valid_603219, JInt, required = false, default = nil)
  if valid_603219 != nil:
    section.add "MaxRecords", valid_603219
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
  var valid_603220 = header.getOrDefault("X-Amz-Signature")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Signature", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Content-Sha256", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Date")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Date", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Credential")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Credential", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Security-Token")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Security-Token", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Algorithm")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Algorithm", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-SignedHeaders", valid_603226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603227: Call_GetDescribeOrderableDBInstanceOptions_603208;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603227.validator(path, query, header, formData, body)
  let scheme = call_603227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603227.url(scheme.get, call_603227.host, call_603227.base,
                         call_603227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603227, url, valid)

proc call*(call_603228: Call_GetDescribeOrderableDBInstanceOptions_603208;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
          MaxRecords: int = 0): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   Marker: string
  ##   Engine: string (required)
  ##   LicenseModel: string
  ##   Vpc: bool
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   MaxRecords: int
  var query_603229 = newJObject()
  add(query_603229, "Marker", newJString(Marker))
  add(query_603229, "Engine", newJString(Engine))
  add(query_603229, "LicenseModel", newJString(LicenseModel))
  add(query_603229, "Vpc", newJBool(Vpc))
  add(query_603229, "EngineVersion", newJString(EngineVersion))
  add(query_603229, "Action", newJString(Action))
  add(query_603229, "Version", newJString(Version))
  add(query_603229, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603229, "MaxRecords", newJInt(MaxRecords))
  result = call_603228.call(nil, query_603229, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_603208(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_603209, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_603210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_603277 = ref object of OpenApiRestCall_601373
proc url_PostDescribeReservedDBInstances_603279(protocol: Scheme; host: string;
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

proc validate_PostDescribeReservedDBInstances_603278(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603280 = query.getOrDefault("Action")
  valid_603280 = validateParameter(valid_603280, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_603280 != nil:
    section.add "Action", valid_603280
  var valid_603281 = query.getOrDefault("Version")
  valid_603281 = validateParameter(valid_603281, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603281 != nil:
    section.add "Version", valid_603281
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
  var valid_603282 = header.getOrDefault("X-Amz-Signature")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Signature", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Content-Sha256", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Date")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Date", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Credential")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Credential", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Algorithm")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Algorithm", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-SignedHeaders", valid_603288
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   MaxRecords: JInt
  ##   ReservedDBInstanceId: JString
  ##   Marker: JString
  ##   Duration: JString
  ##   OfferingType: JString
  ##   ProductDescription: JString
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_603289 = formData.getOrDefault("DBInstanceClass")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "DBInstanceClass", valid_603289
  var valid_603290 = formData.getOrDefault("MultiAZ")
  valid_603290 = validateParameter(valid_603290, JBool, required = false, default = nil)
  if valid_603290 != nil:
    section.add "MultiAZ", valid_603290
  var valid_603291 = formData.getOrDefault("MaxRecords")
  valid_603291 = validateParameter(valid_603291, JInt, required = false, default = nil)
  if valid_603291 != nil:
    section.add "MaxRecords", valid_603291
  var valid_603292 = formData.getOrDefault("ReservedDBInstanceId")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "ReservedDBInstanceId", valid_603292
  var valid_603293 = formData.getOrDefault("Marker")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "Marker", valid_603293
  var valid_603294 = formData.getOrDefault("Duration")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "Duration", valid_603294
  var valid_603295 = formData.getOrDefault("OfferingType")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "OfferingType", valid_603295
  var valid_603296 = formData.getOrDefault("ProductDescription")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "ProductDescription", valid_603296
  var valid_603297 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603297
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603298: Call_PostDescribeReservedDBInstances_603277;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603298.validator(path, query, header, formData, body)
  let scheme = call_603298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603298.url(scheme.get, call_603298.host, call_603298.base,
                         call_603298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603298, url, valid)

proc call*(call_603299: Call_PostDescribeReservedDBInstances_603277;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          ReservedDBInstanceId: string = ""; Marker: string = ""; Duration: string = "";
          OfferingType: string = ""; ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstances";
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postDescribeReservedDBInstances
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   MaxRecords: int
  ##   ReservedDBInstanceId: string
  ##   Marker: string
  ##   Duration: string
  ##   OfferingType: string
  ##   ProductDescription: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_603300 = newJObject()
  var formData_603301 = newJObject()
  add(formData_603301, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603301, "MultiAZ", newJBool(MultiAZ))
  add(formData_603301, "MaxRecords", newJInt(MaxRecords))
  add(formData_603301, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_603301, "Marker", newJString(Marker))
  add(formData_603301, "Duration", newJString(Duration))
  add(formData_603301, "OfferingType", newJString(OfferingType))
  add(formData_603301, "ProductDescription", newJString(ProductDescription))
  add(query_603300, "Action", newJString(Action))
  add(formData_603301, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603300, "Version", newJString(Version))
  result = call_603299.call(nil, query_603300, nil, formData_603301, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_603277(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_603278, base: "/",
    url: url_PostDescribeReservedDBInstances_603279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_603253 = ref object of OpenApiRestCall_601373
proc url_GetDescribeReservedDBInstances_603255(protocol: Scheme; host: string;
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

proc validate_GetDescribeReservedDBInstances_603254(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   ProductDescription: JString
  ##   OfferingType: JString
  ##   ReservedDBInstanceId: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   ReservedDBInstancesOfferingId: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603256 = query.getOrDefault("Marker")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "Marker", valid_603256
  var valid_603257 = query.getOrDefault("ProductDescription")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "ProductDescription", valid_603257
  var valid_603258 = query.getOrDefault("OfferingType")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "OfferingType", valid_603258
  var valid_603259 = query.getOrDefault("ReservedDBInstanceId")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "ReservedDBInstanceId", valid_603259
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603260 = query.getOrDefault("Action")
  valid_603260 = validateParameter(valid_603260, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_603260 != nil:
    section.add "Action", valid_603260
  var valid_603261 = query.getOrDefault("MultiAZ")
  valid_603261 = validateParameter(valid_603261, JBool, required = false, default = nil)
  if valid_603261 != nil:
    section.add "MultiAZ", valid_603261
  var valid_603262 = query.getOrDefault("Duration")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "Duration", valid_603262
  var valid_603263 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603263
  var valid_603264 = query.getOrDefault("Version")
  valid_603264 = validateParameter(valid_603264, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603264 != nil:
    section.add "Version", valid_603264
  var valid_603265 = query.getOrDefault("DBInstanceClass")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "DBInstanceClass", valid_603265
  var valid_603266 = query.getOrDefault("MaxRecords")
  valid_603266 = validateParameter(valid_603266, JInt, required = false, default = nil)
  if valid_603266 != nil:
    section.add "MaxRecords", valid_603266
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
  var valid_603267 = header.getOrDefault("X-Amz-Signature")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Signature", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Content-Sha256", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Date")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Date", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Credential")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Credential", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Algorithm")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Algorithm", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-SignedHeaders", valid_603273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603274: Call_GetDescribeReservedDBInstances_603253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603274.validator(path, query, header, formData, body)
  let scheme = call_603274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603274.url(scheme.get, call_603274.host, call_603274.base,
                         call_603274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603274, url, valid)

proc call*(call_603275: Call_GetDescribeReservedDBInstances_603253;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Action: string = "DescribeReservedDBInstances"; MultiAZ: bool = false;
          Duration: string = ""; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
          MaxRecords: int = 0): Recallable =
  ## getDescribeReservedDBInstances
  ##   Marker: string
  ##   ProductDescription: string
  ##   OfferingType: string
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   Duration: string
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   MaxRecords: int
  var query_603276 = newJObject()
  add(query_603276, "Marker", newJString(Marker))
  add(query_603276, "ProductDescription", newJString(ProductDescription))
  add(query_603276, "OfferingType", newJString(OfferingType))
  add(query_603276, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603276, "Action", newJString(Action))
  add(query_603276, "MultiAZ", newJBool(MultiAZ))
  add(query_603276, "Duration", newJString(Duration))
  add(query_603276, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603276, "Version", newJString(Version))
  add(query_603276, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603276, "MaxRecords", newJInt(MaxRecords))
  result = call_603275.call(nil, query_603276, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_603253(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_603254, base: "/",
    url: url_GetDescribeReservedDBInstances_603255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_603325 = ref object of OpenApiRestCall_601373
proc url_PostDescribeReservedDBInstancesOfferings_603327(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_603326(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603328 = query.getOrDefault("Action")
  valid_603328 = validateParameter(valid_603328, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_603328 != nil:
    section.add "Action", valid_603328
  var valid_603329 = query.getOrDefault("Version")
  valid_603329 = validateParameter(valid_603329, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603329 != nil:
    section.add "Version", valid_603329
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
  var valid_603330 = header.getOrDefault("X-Amz-Signature")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Signature", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Content-Sha256", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Date")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Date", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Credential")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Credential", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Security-Token")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Security-Token", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Algorithm")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Algorithm", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Duration: JString
  ##   OfferingType: JString
  ##   ProductDescription: JString
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_603337 = formData.getOrDefault("DBInstanceClass")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "DBInstanceClass", valid_603337
  var valid_603338 = formData.getOrDefault("MultiAZ")
  valid_603338 = validateParameter(valid_603338, JBool, required = false, default = nil)
  if valid_603338 != nil:
    section.add "MultiAZ", valid_603338
  var valid_603339 = formData.getOrDefault("MaxRecords")
  valid_603339 = validateParameter(valid_603339, JInt, required = false, default = nil)
  if valid_603339 != nil:
    section.add "MaxRecords", valid_603339
  var valid_603340 = formData.getOrDefault("Marker")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "Marker", valid_603340
  var valid_603341 = formData.getOrDefault("Duration")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "Duration", valid_603341
  var valid_603342 = formData.getOrDefault("OfferingType")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "OfferingType", valid_603342
  var valid_603343 = formData.getOrDefault("ProductDescription")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "ProductDescription", valid_603343
  var valid_603344 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603344
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603345: Call_PostDescribeReservedDBInstancesOfferings_603325;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603345.validator(path, query, header, formData, body)
  let scheme = call_603345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603345.url(scheme.get, call_603345.host, call_603345.base,
                         call_603345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603345, url, valid)

proc call*(call_603346: Call_PostDescribeReservedDBInstancesOfferings_603325;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          Marker: string = ""; Duration: string = ""; OfferingType: string = "";
          ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postDescribeReservedDBInstancesOfferings
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   MaxRecords: int
  ##   Marker: string
  ##   Duration: string
  ##   OfferingType: string
  ##   ProductDescription: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_603347 = newJObject()
  var formData_603348 = newJObject()
  add(formData_603348, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603348, "MultiAZ", newJBool(MultiAZ))
  add(formData_603348, "MaxRecords", newJInt(MaxRecords))
  add(formData_603348, "Marker", newJString(Marker))
  add(formData_603348, "Duration", newJString(Duration))
  add(formData_603348, "OfferingType", newJString(OfferingType))
  add(formData_603348, "ProductDescription", newJString(ProductDescription))
  add(query_603347, "Action", newJString(Action))
  add(formData_603348, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603347, "Version", newJString(Version))
  result = call_603346.call(nil, query_603347, nil, formData_603348, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_603325(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_603326,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_603327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_603302 = ref object of OpenApiRestCall_601373
proc url_GetDescribeReservedDBInstancesOfferings_603304(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_603303(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   ProductDescription: JString
  ##   OfferingType: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   ReservedDBInstancesOfferingId: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603305 = query.getOrDefault("Marker")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "Marker", valid_603305
  var valid_603306 = query.getOrDefault("ProductDescription")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "ProductDescription", valid_603306
  var valid_603307 = query.getOrDefault("OfferingType")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "OfferingType", valid_603307
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603308 = query.getOrDefault("Action")
  valid_603308 = validateParameter(valid_603308, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_603308 != nil:
    section.add "Action", valid_603308
  var valid_603309 = query.getOrDefault("MultiAZ")
  valid_603309 = validateParameter(valid_603309, JBool, required = false, default = nil)
  if valid_603309 != nil:
    section.add "MultiAZ", valid_603309
  var valid_603310 = query.getOrDefault("Duration")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "Duration", valid_603310
  var valid_603311 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603311
  var valid_603312 = query.getOrDefault("Version")
  valid_603312 = validateParameter(valid_603312, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603312 != nil:
    section.add "Version", valid_603312
  var valid_603313 = query.getOrDefault("DBInstanceClass")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "DBInstanceClass", valid_603313
  var valid_603314 = query.getOrDefault("MaxRecords")
  valid_603314 = validateParameter(valid_603314, JInt, required = false, default = nil)
  if valid_603314 != nil:
    section.add "MaxRecords", valid_603314
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
  var valid_603315 = header.getOrDefault("X-Amz-Signature")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Signature", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Content-Sha256", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Date")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Date", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Credential")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Credential", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Security-Token")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Security-Token", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Algorithm")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Algorithm", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603322: Call_GetDescribeReservedDBInstancesOfferings_603302;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603322.validator(path, query, header, formData, body)
  let scheme = call_603322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603322.url(scheme.get, call_603322.host, call_603322.base,
                         call_603322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603322, url, valid)

proc call*(call_603323: Call_GetDescribeReservedDBInstancesOfferings_603302;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          MultiAZ: bool = false; Duration: string = "";
          ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
          MaxRecords: int = 0): Recallable =
  ## getDescribeReservedDBInstancesOfferings
  ##   Marker: string
  ##   ProductDescription: string
  ##   OfferingType: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   Duration: string
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   MaxRecords: int
  var query_603324 = newJObject()
  add(query_603324, "Marker", newJString(Marker))
  add(query_603324, "ProductDescription", newJString(ProductDescription))
  add(query_603324, "OfferingType", newJString(OfferingType))
  add(query_603324, "Action", newJString(Action))
  add(query_603324, "MultiAZ", newJBool(MultiAZ))
  add(query_603324, "Duration", newJString(Duration))
  add(query_603324, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603324, "Version", newJString(Version))
  add(query_603324, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603324, "MaxRecords", newJInt(MaxRecords))
  result = call_603323.call(nil, query_603324, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_603302(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_603303, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_603304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_603365 = ref object of OpenApiRestCall_601373
proc url_PostListTagsForResource_603367(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_603366(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603368 = query.getOrDefault("Action")
  valid_603368 = validateParameter(valid_603368, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603368 != nil:
    section.add "Action", valid_603368
  var valid_603369 = query.getOrDefault("Version")
  valid_603369 = validateParameter(valid_603369, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603369 != nil:
    section.add "Version", valid_603369
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
  var valid_603370 = header.getOrDefault("X-Amz-Signature")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Signature", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Content-Sha256", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Date")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Date", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Credential")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Credential", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Security-Token")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Security-Token", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Algorithm")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Algorithm", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-SignedHeaders", valid_603376
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_603377 = formData.getOrDefault("ResourceName")
  valid_603377 = validateParameter(valid_603377, JString, required = true,
                                 default = nil)
  if valid_603377 != nil:
    section.add "ResourceName", valid_603377
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603378: Call_PostListTagsForResource_603365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603378.validator(path, query, header, formData, body)
  let scheme = call_603378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603378.url(scheme.get, call_603378.host, call_603378.base,
                         call_603378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603378, url, valid)

proc call*(call_603379: Call_PostListTagsForResource_603365; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_603380 = newJObject()
  var formData_603381 = newJObject()
  add(query_603380, "Action", newJString(Action))
  add(query_603380, "Version", newJString(Version))
  add(formData_603381, "ResourceName", newJString(ResourceName))
  result = call_603379.call(nil, query_603380, nil, formData_603381, nil)

var postListTagsForResource* = Call_PostListTagsForResource_603365(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_603366, base: "/",
    url: url_PostListTagsForResource_603367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_603349 = ref object of OpenApiRestCall_601373
proc url_GetListTagsForResource_603351(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_603350(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_603352 = query.getOrDefault("ResourceName")
  valid_603352 = validateParameter(valid_603352, JString, required = true,
                                 default = nil)
  if valid_603352 != nil:
    section.add "ResourceName", valid_603352
  var valid_603353 = query.getOrDefault("Action")
  valid_603353 = validateParameter(valid_603353, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603353 != nil:
    section.add "Action", valid_603353
  var valid_603354 = query.getOrDefault("Version")
  valid_603354 = validateParameter(valid_603354, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603354 != nil:
    section.add "Version", valid_603354
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
  var valid_603355 = header.getOrDefault("X-Amz-Signature")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Signature", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Content-Sha256", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Date")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Date", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Credential")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Credential", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Security-Token")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Security-Token", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Algorithm")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Algorithm", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-SignedHeaders", valid_603361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603362: Call_GetListTagsForResource_603349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603362.validator(path, query, header, formData, body)
  let scheme = call_603362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603362.url(scheme.get, call_603362.host, call_603362.base,
                         call_603362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603362, url, valid)

proc call*(call_603363: Call_GetListTagsForResource_603349; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603364 = newJObject()
  add(query_603364, "ResourceName", newJString(ResourceName))
  add(query_603364, "Action", newJString(Action))
  add(query_603364, "Version", newJString(Version))
  result = call_603363.call(nil, query_603364, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_603349(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_603350, base: "/",
    url: url_GetListTagsForResource_603351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_603415 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBInstance_603417(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_603416(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603418 = query.getOrDefault("Action")
  valid_603418 = validateParameter(valid_603418, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_603418 != nil:
    section.add "Action", valid_603418
  var valid_603419 = query.getOrDefault("Version")
  valid_603419 = validateParameter(valid_603419, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603419 != nil:
    section.add "Version", valid_603419
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
  var valid_603420 = header.getOrDefault("X-Amz-Signature")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Signature", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Content-Sha256", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Date")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Date", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Credential")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Credential", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Security-Token")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Security-Token", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Algorithm")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Algorithm", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-SignedHeaders", valid_603426
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredMaintenanceWindow: JString
  ##   DBInstanceClass: JString
  ##   PreferredBackupWindow: JString
  ##   MasterUserPassword: JString
  ##   MultiAZ: JBool
  ##   DBParameterGroupName: JString
  ##   EngineVersion: JString
  ##   VpcSecurityGroupIds: JArray
  ##   BackupRetentionPeriod: JInt
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   ApplyImmediately: JBool
  ##   Iops: JInt
  ##   AllowMajorVersionUpgrade: JBool
  ##   OptionGroupName: JString
  ##   NewDBInstanceIdentifier: JString
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: JInt
  section = newJObject()
  var valid_603427 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "PreferredMaintenanceWindow", valid_603427
  var valid_603428 = formData.getOrDefault("DBInstanceClass")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "DBInstanceClass", valid_603428
  var valid_603429 = formData.getOrDefault("PreferredBackupWindow")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "PreferredBackupWindow", valid_603429
  var valid_603430 = formData.getOrDefault("MasterUserPassword")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "MasterUserPassword", valid_603430
  var valid_603431 = formData.getOrDefault("MultiAZ")
  valid_603431 = validateParameter(valid_603431, JBool, required = false, default = nil)
  if valid_603431 != nil:
    section.add "MultiAZ", valid_603431
  var valid_603432 = formData.getOrDefault("DBParameterGroupName")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "DBParameterGroupName", valid_603432
  var valid_603433 = formData.getOrDefault("EngineVersion")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "EngineVersion", valid_603433
  var valid_603434 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603434 = validateParameter(valid_603434, JArray, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "VpcSecurityGroupIds", valid_603434
  var valid_603435 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603435 = validateParameter(valid_603435, JInt, required = false, default = nil)
  if valid_603435 != nil:
    section.add "BackupRetentionPeriod", valid_603435
  var valid_603436 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603436 = validateParameter(valid_603436, JBool, required = false, default = nil)
  if valid_603436 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603436
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603437 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603437 = validateParameter(valid_603437, JString, required = true,
                                 default = nil)
  if valid_603437 != nil:
    section.add "DBInstanceIdentifier", valid_603437
  var valid_603438 = formData.getOrDefault("ApplyImmediately")
  valid_603438 = validateParameter(valid_603438, JBool, required = false, default = nil)
  if valid_603438 != nil:
    section.add "ApplyImmediately", valid_603438
  var valid_603439 = formData.getOrDefault("Iops")
  valid_603439 = validateParameter(valid_603439, JInt, required = false, default = nil)
  if valid_603439 != nil:
    section.add "Iops", valid_603439
  var valid_603440 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_603440 = validateParameter(valid_603440, JBool, required = false, default = nil)
  if valid_603440 != nil:
    section.add "AllowMajorVersionUpgrade", valid_603440
  var valid_603441 = formData.getOrDefault("OptionGroupName")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "OptionGroupName", valid_603441
  var valid_603442 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "NewDBInstanceIdentifier", valid_603442
  var valid_603443 = formData.getOrDefault("DBSecurityGroups")
  valid_603443 = validateParameter(valid_603443, JArray, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "DBSecurityGroups", valid_603443
  var valid_603444 = formData.getOrDefault("AllocatedStorage")
  valid_603444 = validateParameter(valid_603444, JInt, required = false, default = nil)
  if valid_603444 != nil:
    section.add "AllocatedStorage", valid_603444
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603445: Call_PostModifyDBInstance_603415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603445.validator(path, query, header, formData, body)
  let scheme = call_603445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603445.url(scheme.get, call_603445.host, call_603445.base,
                         call_603445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603445, url, valid)

proc call*(call_603446: Call_PostModifyDBInstance_603415;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          MasterUserPassword: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          AutoMinorVersionUpgrade: bool = false; ApplyImmediately: bool = false;
          Iops: int = 0; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false; OptionGroupName: string = "";
          NewDBInstanceIdentifier: string = ""; Version: string = "2013-01-10";
          DBSecurityGroups: JsonNode = nil; AllocatedStorage: int = 0): Recallable =
  ## postModifyDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceClass: string
  ##   PreferredBackupWindow: string
  ##   MasterUserPassword: string
  ##   MultiAZ: bool
  ##   DBParameterGroupName: string
  ##   EngineVersion: string
  ##   VpcSecurityGroupIds: JArray
  ##   BackupRetentionPeriod: int
  ##   AutoMinorVersionUpgrade: bool
  ##   DBInstanceIdentifier: string (required)
  ##   ApplyImmediately: bool
  ##   Iops: int
  ##   Action: string (required)
  ##   AllowMajorVersionUpgrade: bool
  ##   OptionGroupName: string
  ##   NewDBInstanceIdentifier: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: int
  var query_603447 = newJObject()
  var formData_603448 = newJObject()
  add(formData_603448, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_603448, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603448, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603448, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603448, "MultiAZ", newJBool(MultiAZ))
  add(formData_603448, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603448, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_603448.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603448, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603448, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603448, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603448, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_603448, "Iops", newJInt(Iops))
  add(query_603447, "Action", newJString(Action))
  add(formData_603448, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_603448, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603448, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_603447, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_603448.add "DBSecurityGroups", DBSecurityGroups
  add(formData_603448, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_603446.call(nil, query_603447, nil, formData_603448, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_603415(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_603416, base: "/",
    url: url_PostModifyDBInstance_603417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_603382 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBInstance_603384(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_603383(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NewDBInstanceIdentifier: JString
  ##   DBParameterGroupName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   DBSecurityGroups: JArray
  ##   ApplyImmediately: JBool
  ##   VpcSecurityGroupIds: JArray
  ##   AllowMajorVersionUpgrade: JBool
  ##   MasterUserPassword: JString
  ##   OptionGroupName: JString
  ##   Version: JString (required)
  ##   AllocatedStorage: JInt
  ##   DBInstanceClass: JString
  ##   PreferredBackupWindow: JString
  ##   PreferredMaintenanceWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  var valid_603385 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "NewDBInstanceIdentifier", valid_603385
  var valid_603386 = query.getOrDefault("DBParameterGroupName")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "DBParameterGroupName", valid_603386
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603387 = query.getOrDefault("DBInstanceIdentifier")
  valid_603387 = validateParameter(valid_603387, JString, required = true,
                                 default = nil)
  if valid_603387 != nil:
    section.add "DBInstanceIdentifier", valid_603387
  var valid_603388 = query.getOrDefault("BackupRetentionPeriod")
  valid_603388 = validateParameter(valid_603388, JInt, required = false, default = nil)
  if valid_603388 != nil:
    section.add "BackupRetentionPeriod", valid_603388
  var valid_603389 = query.getOrDefault("EngineVersion")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "EngineVersion", valid_603389
  var valid_603390 = query.getOrDefault("Action")
  valid_603390 = validateParameter(valid_603390, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_603390 != nil:
    section.add "Action", valid_603390
  var valid_603391 = query.getOrDefault("MultiAZ")
  valid_603391 = validateParameter(valid_603391, JBool, required = false, default = nil)
  if valid_603391 != nil:
    section.add "MultiAZ", valid_603391
  var valid_603392 = query.getOrDefault("DBSecurityGroups")
  valid_603392 = validateParameter(valid_603392, JArray, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "DBSecurityGroups", valid_603392
  var valid_603393 = query.getOrDefault("ApplyImmediately")
  valid_603393 = validateParameter(valid_603393, JBool, required = false, default = nil)
  if valid_603393 != nil:
    section.add "ApplyImmediately", valid_603393
  var valid_603394 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603394 = validateParameter(valid_603394, JArray, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "VpcSecurityGroupIds", valid_603394
  var valid_603395 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_603395 = validateParameter(valid_603395, JBool, required = false, default = nil)
  if valid_603395 != nil:
    section.add "AllowMajorVersionUpgrade", valid_603395
  var valid_603396 = query.getOrDefault("MasterUserPassword")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "MasterUserPassword", valid_603396
  var valid_603397 = query.getOrDefault("OptionGroupName")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "OptionGroupName", valid_603397
  var valid_603398 = query.getOrDefault("Version")
  valid_603398 = validateParameter(valid_603398, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603398 != nil:
    section.add "Version", valid_603398
  var valid_603399 = query.getOrDefault("AllocatedStorage")
  valid_603399 = validateParameter(valid_603399, JInt, required = false, default = nil)
  if valid_603399 != nil:
    section.add "AllocatedStorage", valid_603399
  var valid_603400 = query.getOrDefault("DBInstanceClass")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "DBInstanceClass", valid_603400
  var valid_603401 = query.getOrDefault("PreferredBackupWindow")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "PreferredBackupWindow", valid_603401
  var valid_603402 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "PreferredMaintenanceWindow", valid_603402
  var valid_603403 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603403 = validateParameter(valid_603403, JBool, required = false, default = nil)
  if valid_603403 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603403
  var valid_603404 = query.getOrDefault("Iops")
  valid_603404 = validateParameter(valid_603404, JInt, required = false, default = nil)
  if valid_603404 != nil:
    section.add "Iops", valid_603404
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
  var valid_603405 = header.getOrDefault("X-Amz-Signature")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Signature", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Content-Sha256", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Date")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Date", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Credential")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Credential", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Security-Token")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Security-Token", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Algorithm")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Algorithm", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603412: Call_GetModifyDBInstance_603382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603412.validator(path, query, header, formData, body)
  let scheme = call_603412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603412.url(scheme.get, call_603412.host, call_603412.base,
                         call_603412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603412, url, valid)

proc call*(call_603413: Call_GetModifyDBInstance_603382;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          DBParameterGroupName: string = ""; BackupRetentionPeriod: int = 0;
          EngineVersion: string = ""; Action: string = "ModifyDBInstance";
          MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil;
          ApplyImmediately: bool = false; VpcSecurityGroupIds: JsonNode = nil;
          AllowMajorVersionUpgrade: bool = false; MasterUserPassword: string = "";
          OptionGroupName: string = ""; Version: string = "2013-01-10";
          AllocatedStorage: int = 0; DBInstanceClass: string = "";
          PreferredBackupWindow: string = "";
          PreferredMaintenanceWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getModifyDBInstance
  ##   NewDBInstanceIdentifier: string
  ##   DBParameterGroupName: string
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   DBSecurityGroups: JArray
  ##   ApplyImmediately: bool
  ##   VpcSecurityGroupIds: JArray
  ##   AllowMajorVersionUpgrade: bool
  ##   MasterUserPassword: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   AllocatedStorage: int
  ##   DBInstanceClass: string
  ##   PreferredBackupWindow: string
  ##   PreferredMaintenanceWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_603414 = newJObject()
  add(query_603414, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_603414, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603414, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603414, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603414, "EngineVersion", newJString(EngineVersion))
  add(query_603414, "Action", newJString(Action))
  add(query_603414, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_603414.add "DBSecurityGroups", DBSecurityGroups
  add(query_603414, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_603414.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603414, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_603414, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_603414, "OptionGroupName", newJString(OptionGroupName))
  add(query_603414, "Version", newJString(Version))
  add(query_603414, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_603414, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603414, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603414, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603414, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603414, "Iops", newJInt(Iops))
  result = call_603413.call(nil, query_603414, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_603382(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_603383, base: "/",
    url: url_GetModifyDBInstance_603384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_603466 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBParameterGroup_603468(protocol: Scheme; host: string;
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

proc validate_PostModifyDBParameterGroup_603467(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603469 = query.getOrDefault("Action")
  valid_603469 = validateParameter(valid_603469, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_603469 != nil:
    section.add "Action", valid_603469
  var valid_603470 = query.getOrDefault("Version")
  valid_603470 = validateParameter(valid_603470, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603470 != nil:
    section.add "Version", valid_603470
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
  var valid_603471 = header.getOrDefault("X-Amz-Signature")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Signature", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Content-Sha256", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Date")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Date", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Credential")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Credential", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Security-Token")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Security-Token", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Algorithm")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Algorithm", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-SignedHeaders", valid_603477
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603478 = formData.getOrDefault("DBParameterGroupName")
  valid_603478 = validateParameter(valid_603478, JString, required = true,
                                 default = nil)
  if valid_603478 != nil:
    section.add "DBParameterGroupName", valid_603478
  var valid_603479 = formData.getOrDefault("Parameters")
  valid_603479 = validateParameter(valid_603479, JArray, required = true, default = nil)
  if valid_603479 != nil:
    section.add "Parameters", valid_603479
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603480: Call_PostModifyDBParameterGroup_603466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603480.validator(path, query, header, formData, body)
  let scheme = call_603480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603480.url(scheme.get, call_603480.host, call_603480.base,
                         call_603480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603480, url, valid)

proc call*(call_603481: Call_PostModifyDBParameterGroup_603466;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_603482 = newJObject()
  var formData_603483 = newJObject()
  add(formData_603483, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603482, "Action", newJString(Action))
  if Parameters != nil:
    formData_603483.add "Parameters", Parameters
  add(query_603482, "Version", newJString(Version))
  result = call_603481.call(nil, query_603482, nil, formData_603483, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_603466(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_603467, base: "/",
    url: url_PostModifyDBParameterGroup_603468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_603449 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBParameterGroup_603451(protocol: Scheme; host: string;
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

proc validate_GetModifyDBParameterGroup_603450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_603452 = query.getOrDefault("DBParameterGroupName")
  valid_603452 = validateParameter(valid_603452, JString, required = true,
                                 default = nil)
  if valid_603452 != nil:
    section.add "DBParameterGroupName", valid_603452
  var valid_603453 = query.getOrDefault("Parameters")
  valid_603453 = validateParameter(valid_603453, JArray, required = true, default = nil)
  if valid_603453 != nil:
    section.add "Parameters", valid_603453
  var valid_603454 = query.getOrDefault("Action")
  valid_603454 = validateParameter(valid_603454, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_603454 != nil:
    section.add "Action", valid_603454
  var valid_603455 = query.getOrDefault("Version")
  valid_603455 = validateParameter(valid_603455, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603455 != nil:
    section.add "Version", valid_603455
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
  var valid_603456 = header.getOrDefault("X-Amz-Signature")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Signature", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Content-Sha256", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Date")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Date", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Credential")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Credential", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Security-Token")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Security-Token", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Algorithm")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Algorithm", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-SignedHeaders", valid_603462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603463: Call_GetModifyDBParameterGroup_603449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603463.validator(path, query, header, formData, body)
  let scheme = call_603463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603463.url(scheme.get, call_603463.host, call_603463.base,
                         call_603463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603463, url, valid)

proc call*(call_603464: Call_GetModifyDBParameterGroup_603449;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603465 = newJObject()
  add(query_603465, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_603465.add "Parameters", Parameters
  add(query_603465, "Action", newJString(Action))
  add(query_603465, "Version", newJString(Version))
  result = call_603464.call(nil, query_603465, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_603449(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_603450, base: "/",
    url: url_GetModifyDBParameterGroup_603451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_603502 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBSubnetGroup_603504(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_603503(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603505 = query.getOrDefault("Action")
  valid_603505 = validateParameter(valid_603505, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_603505 != nil:
    section.add "Action", valid_603505
  var valid_603506 = query.getOrDefault("Version")
  valid_603506 = validateParameter(valid_603506, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603506 != nil:
    section.add "Version", valid_603506
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
  var valid_603507 = header.getOrDefault("X-Amz-Signature")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Signature", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Content-Sha256", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Date")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Date", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Credential")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Credential", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Security-Token")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Security-Token", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Algorithm")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Algorithm", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-SignedHeaders", valid_603513
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_603514 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "DBSubnetGroupDescription", valid_603514
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603515 = formData.getOrDefault("DBSubnetGroupName")
  valid_603515 = validateParameter(valid_603515, JString, required = true,
                                 default = nil)
  if valid_603515 != nil:
    section.add "DBSubnetGroupName", valid_603515
  var valid_603516 = formData.getOrDefault("SubnetIds")
  valid_603516 = validateParameter(valid_603516, JArray, required = true, default = nil)
  if valid_603516 != nil:
    section.add "SubnetIds", valid_603516
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603517: Call_PostModifyDBSubnetGroup_603502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603517.validator(path, query, header, formData, body)
  let scheme = call_603517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603517.url(scheme.get, call_603517.host, call_603517.base,
                         call_603517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603517, url, valid)

proc call*(call_603518: Call_PostModifyDBSubnetGroup_603502;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_603519 = newJObject()
  var formData_603520 = newJObject()
  add(formData_603520, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603519, "Action", newJString(Action))
  add(formData_603520, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603519, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_603520.add "SubnetIds", SubnetIds
  result = call_603518.call(nil, query_603519, nil, formData_603520, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_603502(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_603503, base: "/",
    url: url_PostModifyDBSubnetGroup_603504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_603484 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBSubnetGroup_603486(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_603485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_603487 = query.getOrDefault("SubnetIds")
  valid_603487 = validateParameter(valid_603487, JArray, required = true, default = nil)
  if valid_603487 != nil:
    section.add "SubnetIds", valid_603487
  var valid_603488 = query.getOrDefault("Action")
  valid_603488 = validateParameter(valid_603488, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_603488 != nil:
    section.add "Action", valid_603488
  var valid_603489 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "DBSubnetGroupDescription", valid_603489
  var valid_603490 = query.getOrDefault("DBSubnetGroupName")
  valid_603490 = validateParameter(valid_603490, JString, required = true,
                                 default = nil)
  if valid_603490 != nil:
    section.add "DBSubnetGroupName", valid_603490
  var valid_603491 = query.getOrDefault("Version")
  valid_603491 = validateParameter(valid_603491, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603491 != nil:
    section.add "Version", valid_603491
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
  var valid_603492 = header.getOrDefault("X-Amz-Signature")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Signature", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Content-Sha256", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Date")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Date", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Credential")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Credential", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Security-Token")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Security-Token", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Algorithm")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Algorithm", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-SignedHeaders", valid_603498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603499: Call_GetModifyDBSubnetGroup_603484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603499.validator(path, query, header, formData, body)
  let scheme = call_603499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603499.url(scheme.get, call_603499.host, call_603499.base,
                         call_603499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603499, url, valid)

proc call*(call_603500: Call_GetModifyDBSubnetGroup_603484; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_603501 = newJObject()
  if SubnetIds != nil:
    query_603501.add "SubnetIds", SubnetIds
  add(query_603501, "Action", newJString(Action))
  add(query_603501, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603501, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603501, "Version", newJString(Version))
  result = call_603500.call(nil, query_603501, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_603484(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_603485, base: "/",
    url: url_GetModifyDBSubnetGroup_603486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_603541 = ref object of OpenApiRestCall_601373
proc url_PostModifyEventSubscription_603543(protocol: Scheme; host: string;
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

proc validate_PostModifyEventSubscription_603542(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603544 = query.getOrDefault("Action")
  valid_603544 = validateParameter(valid_603544, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_603544 != nil:
    section.add "Action", valid_603544
  var valid_603545 = query.getOrDefault("Version")
  valid_603545 = validateParameter(valid_603545, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603545 != nil:
    section.add "Version", valid_603545
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
  var valid_603546 = header.getOrDefault("X-Amz-Signature")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Signature", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Content-Sha256", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Date")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Date", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Credential")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Credential", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Security-Token")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Security-Token", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Algorithm")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Algorithm", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-SignedHeaders", valid_603552
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_603553 = formData.getOrDefault("SnsTopicArn")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "SnsTopicArn", valid_603553
  var valid_603554 = formData.getOrDefault("Enabled")
  valid_603554 = validateParameter(valid_603554, JBool, required = false, default = nil)
  if valid_603554 != nil:
    section.add "Enabled", valid_603554
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603555 = formData.getOrDefault("SubscriptionName")
  valid_603555 = validateParameter(valid_603555, JString, required = true,
                                 default = nil)
  if valid_603555 != nil:
    section.add "SubscriptionName", valid_603555
  var valid_603556 = formData.getOrDefault("SourceType")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "SourceType", valid_603556
  var valid_603557 = formData.getOrDefault("EventCategories")
  valid_603557 = validateParameter(valid_603557, JArray, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "EventCategories", valid_603557
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603558: Call_PostModifyEventSubscription_603541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603558.validator(path, query, header, formData, body)
  let scheme = call_603558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603558.url(scheme.get, call_603558.host, call_603558.base,
                         call_603558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603558, url, valid)

proc call*(call_603559: Call_PostModifyEventSubscription_603541;
          SubscriptionName: string; SnsTopicArn: string = ""; Enabled: bool = false;
          SourceType: string = ""; EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; Version: string = "2013-01-10"): Recallable =
  ## postModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603560 = newJObject()
  var formData_603561 = newJObject()
  add(formData_603561, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_603561, "Enabled", newJBool(Enabled))
  add(formData_603561, "SubscriptionName", newJString(SubscriptionName))
  add(formData_603561, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_603561.add "EventCategories", EventCategories
  add(query_603560, "Action", newJString(Action))
  add(query_603560, "Version", newJString(Version))
  result = call_603559.call(nil, query_603560, nil, formData_603561, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_603541(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_603542, base: "/",
    url: url_PostModifyEventSubscription_603543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_603521 = ref object of OpenApiRestCall_601373
proc url_GetModifyEventSubscription_603523(protocol: Scheme; host: string;
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

proc validate_GetModifyEventSubscription_603522(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   EventCategories: JArray
  ##   Action: JString (required)
  ##   SnsTopicArn: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_603524 = query.getOrDefault("SourceType")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "SourceType", valid_603524
  var valid_603525 = query.getOrDefault("Enabled")
  valid_603525 = validateParameter(valid_603525, JBool, required = false, default = nil)
  if valid_603525 != nil:
    section.add "Enabled", valid_603525
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_603526 = query.getOrDefault("SubscriptionName")
  valid_603526 = validateParameter(valid_603526, JString, required = true,
                                 default = nil)
  if valid_603526 != nil:
    section.add "SubscriptionName", valid_603526
  var valid_603527 = query.getOrDefault("EventCategories")
  valid_603527 = validateParameter(valid_603527, JArray, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "EventCategories", valid_603527
  var valid_603528 = query.getOrDefault("Action")
  valid_603528 = validateParameter(valid_603528, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_603528 != nil:
    section.add "Action", valid_603528
  var valid_603529 = query.getOrDefault("SnsTopicArn")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "SnsTopicArn", valid_603529
  var valid_603530 = query.getOrDefault("Version")
  valid_603530 = validateParameter(valid_603530, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603530 != nil:
    section.add "Version", valid_603530
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
  var valid_603531 = header.getOrDefault("X-Amz-Signature")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Signature", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Content-Sha256", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Date")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Date", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Credential")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Credential", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Security-Token")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Security-Token", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Algorithm")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Algorithm", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-SignedHeaders", valid_603537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603538: Call_GetModifyEventSubscription_603521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603538.validator(path, query, header, formData, body)
  let scheme = call_603538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603538.url(scheme.get, call_603538.host, call_603538.base,
                         call_603538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603538, url, valid)

proc call*(call_603539: Call_GetModifyEventSubscription_603521;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   Version: string (required)
  var query_603540 = newJObject()
  add(query_603540, "SourceType", newJString(SourceType))
  add(query_603540, "Enabled", newJBool(Enabled))
  add(query_603540, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_603540.add "EventCategories", EventCategories
  add(query_603540, "Action", newJString(Action))
  add(query_603540, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_603540, "Version", newJString(Version))
  result = call_603539.call(nil, query_603540, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_603521(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_603522, base: "/",
    url: url_GetModifyEventSubscription_603523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_603581 = ref object of OpenApiRestCall_601373
proc url_PostModifyOptionGroup_603583(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyOptionGroup_603582(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603584 = query.getOrDefault("Action")
  valid_603584 = validateParameter(valid_603584, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_603584 != nil:
    section.add "Action", valid_603584
  var valid_603585 = query.getOrDefault("Version")
  valid_603585 = validateParameter(valid_603585, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603585 != nil:
    section.add "Version", valid_603585
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
  var valid_603586 = header.getOrDefault("X-Amz-Signature")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Signature", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Content-Sha256", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Date")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Date", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Credential")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Credential", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Security-Token")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Security-Token", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Algorithm")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Algorithm", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-SignedHeaders", valid_603592
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_603593 = formData.getOrDefault("OptionsToRemove")
  valid_603593 = validateParameter(valid_603593, JArray, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "OptionsToRemove", valid_603593
  var valid_603594 = formData.getOrDefault("ApplyImmediately")
  valid_603594 = validateParameter(valid_603594, JBool, required = false, default = nil)
  if valid_603594 != nil:
    section.add "ApplyImmediately", valid_603594
  var valid_603595 = formData.getOrDefault("OptionsToInclude")
  valid_603595 = validateParameter(valid_603595, JArray, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "OptionsToInclude", valid_603595
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_603596 = formData.getOrDefault("OptionGroupName")
  valid_603596 = validateParameter(valid_603596, JString, required = true,
                                 default = nil)
  if valid_603596 != nil:
    section.add "OptionGroupName", valid_603596
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603597: Call_PostModifyOptionGroup_603581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603597.validator(path, query, header, formData, body)
  let scheme = call_603597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603597.url(scheme.get, call_603597.host, call_603597.base,
                         call_603597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603597, url, valid)

proc call*(call_603598: Call_PostModifyOptionGroup_603581; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_603599 = newJObject()
  var formData_603600 = newJObject()
  if OptionsToRemove != nil:
    formData_603600.add "OptionsToRemove", OptionsToRemove
  add(formData_603600, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_603600.add "OptionsToInclude", OptionsToInclude
  add(query_603599, "Action", newJString(Action))
  add(formData_603600, "OptionGroupName", newJString(OptionGroupName))
  add(query_603599, "Version", newJString(Version))
  result = call_603598.call(nil, query_603599, nil, formData_603600, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_603581(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_603582, base: "/",
    url: url_PostModifyOptionGroup_603583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_603562 = ref object of OpenApiRestCall_601373
proc url_GetModifyOptionGroup_603564(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyOptionGroup_603563(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ApplyImmediately: JBool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603565 = query.getOrDefault("Action")
  valid_603565 = validateParameter(valid_603565, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_603565 != nil:
    section.add "Action", valid_603565
  var valid_603566 = query.getOrDefault("ApplyImmediately")
  valid_603566 = validateParameter(valid_603566, JBool, required = false, default = nil)
  if valid_603566 != nil:
    section.add "ApplyImmediately", valid_603566
  var valid_603567 = query.getOrDefault("OptionsToRemove")
  valid_603567 = validateParameter(valid_603567, JArray, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "OptionsToRemove", valid_603567
  var valid_603568 = query.getOrDefault("OptionsToInclude")
  valid_603568 = validateParameter(valid_603568, JArray, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "OptionsToInclude", valid_603568
  var valid_603569 = query.getOrDefault("OptionGroupName")
  valid_603569 = validateParameter(valid_603569, JString, required = true,
                                 default = nil)
  if valid_603569 != nil:
    section.add "OptionGroupName", valid_603569
  var valid_603570 = query.getOrDefault("Version")
  valid_603570 = validateParameter(valid_603570, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603570 != nil:
    section.add "Version", valid_603570
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
  var valid_603571 = header.getOrDefault("X-Amz-Signature")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Signature", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Content-Sha256", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Date")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Date", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Credential")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Credential", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Security-Token")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Security-Token", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Algorithm")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Algorithm", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-SignedHeaders", valid_603577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603578: Call_GetModifyOptionGroup_603562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603578.validator(path, query, header, formData, body)
  let scheme = call_603578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603578.url(scheme.get, call_603578.host, call_603578.base,
                         call_603578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603578, url, valid)

proc call*(call_603579: Call_GetModifyOptionGroup_603562; OptionGroupName: string;
          Action: string = "ModifyOptionGroup"; ApplyImmediately: bool = false;
          OptionsToRemove: JsonNode = nil; OptionsToInclude: JsonNode = nil;
          Version: string = "2013-01-10"): Recallable =
  ## getModifyOptionGroup
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_603580 = newJObject()
  add(query_603580, "Action", newJString(Action))
  add(query_603580, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_603580.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_603580.add "OptionsToInclude", OptionsToInclude
  add(query_603580, "OptionGroupName", newJString(OptionGroupName))
  add(query_603580, "Version", newJString(Version))
  result = call_603579.call(nil, query_603580, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_603562(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_603563, base: "/",
    url: url_GetModifyOptionGroup_603564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_603619 = ref object of OpenApiRestCall_601373
proc url_PostPromoteReadReplica_603621(protocol: Scheme; host: string; base: string;
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

proc validate_PostPromoteReadReplica_603620(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603622 = query.getOrDefault("Action")
  valid_603622 = validateParameter(valid_603622, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_603622 != nil:
    section.add "Action", valid_603622
  var valid_603623 = query.getOrDefault("Version")
  valid_603623 = validateParameter(valid_603623, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603623 != nil:
    section.add "Version", valid_603623
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
  var valid_603624 = header.getOrDefault("X-Amz-Signature")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Signature", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Content-Sha256", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Date")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Date", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Credential")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Credential", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-Security-Token")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Security-Token", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Algorithm")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Algorithm", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-SignedHeaders", valid_603630
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603631 = formData.getOrDefault("PreferredBackupWindow")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "PreferredBackupWindow", valid_603631
  var valid_603632 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603632 = validateParameter(valid_603632, JInt, required = false, default = nil)
  if valid_603632 != nil:
    section.add "BackupRetentionPeriod", valid_603632
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603633 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603633 = validateParameter(valid_603633, JString, required = true,
                                 default = nil)
  if valid_603633 != nil:
    section.add "DBInstanceIdentifier", valid_603633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603634: Call_PostPromoteReadReplica_603619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603634.validator(path, query, header, formData, body)
  let scheme = call_603634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603634.url(scheme.get, call_603634.host, call_603634.base,
                         call_603634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603634, url, valid)

proc call*(call_603635: Call_PostPromoteReadReplica_603619;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-01-10"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603636 = newJObject()
  var formData_603637 = newJObject()
  add(formData_603637, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603637, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603637, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603636, "Action", newJString(Action))
  add(query_603636, "Version", newJString(Version))
  result = call_603635.call(nil, query_603636, nil, formData_603637, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_603619(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_603620, base: "/",
    url: url_PostPromoteReadReplica_603621, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_603601 = ref object of OpenApiRestCall_601373
proc url_GetPromoteReadReplica_603603(protocol: Scheme; host: string; base: string;
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

proc validate_GetPromoteReadReplica_603602(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603604 = query.getOrDefault("DBInstanceIdentifier")
  valid_603604 = validateParameter(valid_603604, JString, required = true,
                                 default = nil)
  if valid_603604 != nil:
    section.add "DBInstanceIdentifier", valid_603604
  var valid_603605 = query.getOrDefault("BackupRetentionPeriod")
  valid_603605 = validateParameter(valid_603605, JInt, required = false, default = nil)
  if valid_603605 != nil:
    section.add "BackupRetentionPeriod", valid_603605
  var valid_603606 = query.getOrDefault("Action")
  valid_603606 = validateParameter(valid_603606, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_603606 != nil:
    section.add "Action", valid_603606
  var valid_603607 = query.getOrDefault("Version")
  valid_603607 = validateParameter(valid_603607, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603607 != nil:
    section.add "Version", valid_603607
  var valid_603608 = query.getOrDefault("PreferredBackupWindow")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "PreferredBackupWindow", valid_603608
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
  var valid_603609 = header.getOrDefault("X-Amz-Signature")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Signature", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Content-Sha256", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Date")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Date", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-Credential")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Credential", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-Security-Token")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Security-Token", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Algorithm")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Algorithm", valid_603614
  var valid_603615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-SignedHeaders", valid_603615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603616: Call_GetPromoteReadReplica_603601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603616.validator(path, query, header, formData, body)
  let scheme = call_603616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603616.url(scheme.get, call_603616.host, call_603616.base,
                         call_603616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603616, url, valid)

proc call*(call_603617: Call_GetPromoteReadReplica_603601;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-01-10";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_603618 = newJObject()
  add(query_603618, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603618, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603618, "Action", newJString(Action))
  add(query_603618, "Version", newJString(Version))
  add(query_603618, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_603617.call(nil, query_603618, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_603601(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_603602, base: "/",
    url: url_GetPromoteReadReplica_603603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_603656 = ref object of OpenApiRestCall_601373
proc url_PostPurchaseReservedDBInstancesOffering_603658(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_603657(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603659 = query.getOrDefault("Action")
  valid_603659 = validateParameter(valid_603659, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_603659 != nil:
    section.add "Action", valid_603659
  var valid_603660 = query.getOrDefault("Version")
  valid_603660 = validateParameter(valid_603660, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603660 != nil:
    section.add "Version", valid_603660
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
  var valid_603661 = header.getOrDefault("X-Amz-Signature")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Signature", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Content-Sha256", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Date")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Date", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Credential")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Credential", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Security-Token")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Security-Token", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-Algorithm")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-Algorithm", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-SignedHeaders", valid_603667
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_603668 = formData.getOrDefault("ReservedDBInstanceId")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "ReservedDBInstanceId", valid_603668
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_603669 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603669 = validateParameter(valid_603669, JString, required = true,
                                 default = nil)
  if valid_603669 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603669
  var valid_603670 = formData.getOrDefault("DBInstanceCount")
  valid_603670 = validateParameter(valid_603670, JInt, required = false, default = nil)
  if valid_603670 != nil:
    section.add "DBInstanceCount", valid_603670
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603671: Call_PostPurchaseReservedDBInstancesOffering_603656;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603671.validator(path, query, header, formData, body)
  let scheme = call_603671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603671.url(scheme.get, call_603671.host, call_603671.base,
                         call_603671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603671, url, valid)

proc call*(call_603672: Call_PostPurchaseReservedDBInstancesOffering_603656;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-01-10"; DBInstanceCount: int = 0): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  var query_603673 = newJObject()
  var formData_603674 = newJObject()
  add(formData_603674, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603673, "Action", newJString(Action))
  add(formData_603674, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603673, "Version", newJString(Version))
  add(formData_603674, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_603672.call(nil, query_603673, nil, formData_603674, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_603656(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_603657, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_603658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_603638 = ref object of OpenApiRestCall_601373
proc url_GetPurchaseReservedDBInstancesOffering_603640(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_603639(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstanceId: JString
  ##   Action: JString (required)
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603641 = query.getOrDefault("DBInstanceCount")
  valid_603641 = validateParameter(valid_603641, JInt, required = false, default = nil)
  if valid_603641 != nil:
    section.add "DBInstanceCount", valid_603641
  var valid_603642 = query.getOrDefault("ReservedDBInstanceId")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "ReservedDBInstanceId", valid_603642
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603643 = query.getOrDefault("Action")
  valid_603643 = validateParameter(valid_603643, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_603643 != nil:
    section.add "Action", valid_603643
  var valid_603644 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603644 = validateParameter(valid_603644, JString, required = true,
                                 default = nil)
  if valid_603644 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603644
  var valid_603645 = query.getOrDefault("Version")
  valid_603645 = validateParameter(valid_603645, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603645 != nil:
    section.add "Version", valid_603645
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
  var valid_603646 = header.getOrDefault("X-Amz-Signature")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Signature", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Content-Sha256", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Date")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Date", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Credential")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Credential", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Security-Token")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Security-Token", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Algorithm")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Algorithm", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-SignedHeaders", valid_603652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603653: Call_GetPurchaseReservedDBInstancesOffering_603638;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603653.validator(path, query, header, formData, body)
  let scheme = call_603653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603653.url(scheme.get, call_603653.host, call_603653.base,
                         call_603653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603653, url, valid)

proc call*(call_603654: Call_GetPurchaseReservedDBInstancesOffering_603638;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-01-10"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_603655 = newJObject()
  add(query_603655, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_603655, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603655, "Action", newJString(Action))
  add(query_603655, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603655, "Version", newJString(Version))
  result = call_603654.call(nil, query_603655, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_603638(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_603639, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_603640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_603692 = ref object of OpenApiRestCall_601373
proc url_PostRebootDBInstance_603694(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_603693(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603695 = query.getOrDefault("Action")
  valid_603695 = validateParameter(valid_603695, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_603695 != nil:
    section.add "Action", valid_603695
  var valid_603696 = query.getOrDefault("Version")
  valid_603696 = validateParameter(valid_603696, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603696 != nil:
    section.add "Version", valid_603696
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
  var valid_603697 = header.getOrDefault("X-Amz-Signature")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Signature", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Content-Sha256", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Date")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Date", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Credential")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Credential", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Security-Token")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Security-Token", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Algorithm")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Algorithm", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-SignedHeaders", valid_603703
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603704 = formData.getOrDefault("ForceFailover")
  valid_603704 = validateParameter(valid_603704, JBool, required = false, default = nil)
  if valid_603704 != nil:
    section.add "ForceFailover", valid_603704
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603705 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603705 = validateParameter(valid_603705, JString, required = true,
                                 default = nil)
  if valid_603705 != nil:
    section.add "DBInstanceIdentifier", valid_603705
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603706: Call_PostRebootDBInstance_603692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603706.validator(path, query, header, formData, body)
  let scheme = call_603706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603706.url(scheme.get, call_603706.host, call_603706.base,
                         call_603706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603706, url, valid)

proc call*(call_603707: Call_PostRebootDBInstance_603692;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-01-10"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603708 = newJObject()
  var formData_603709 = newJObject()
  add(formData_603709, "ForceFailover", newJBool(ForceFailover))
  add(formData_603709, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603708, "Action", newJString(Action))
  add(query_603708, "Version", newJString(Version))
  result = call_603707.call(nil, query_603708, nil, formData_603709, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_603692(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_603693, base: "/",
    url: url_PostRebootDBInstance_603694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_603675 = ref object of OpenApiRestCall_601373
proc url_GetRebootDBInstance_603677(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_603676(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603678 = query.getOrDefault("ForceFailover")
  valid_603678 = validateParameter(valid_603678, JBool, required = false, default = nil)
  if valid_603678 != nil:
    section.add "ForceFailover", valid_603678
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603679 = query.getOrDefault("DBInstanceIdentifier")
  valid_603679 = validateParameter(valid_603679, JString, required = true,
                                 default = nil)
  if valid_603679 != nil:
    section.add "DBInstanceIdentifier", valid_603679
  var valid_603680 = query.getOrDefault("Action")
  valid_603680 = validateParameter(valid_603680, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_603680 != nil:
    section.add "Action", valid_603680
  var valid_603681 = query.getOrDefault("Version")
  valid_603681 = validateParameter(valid_603681, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603681 != nil:
    section.add "Version", valid_603681
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
  var valid_603682 = header.getOrDefault("X-Amz-Signature")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Signature", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Content-Sha256", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Date")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Date", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Credential")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Credential", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Security-Token")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Security-Token", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Algorithm")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Algorithm", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-SignedHeaders", valid_603688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603689: Call_GetRebootDBInstance_603675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603689.validator(path, query, header, formData, body)
  let scheme = call_603689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603689.url(scheme.get, call_603689.host, call_603689.base,
                         call_603689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603689, url, valid)

proc call*(call_603690: Call_GetRebootDBInstance_603675;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-01-10"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603691 = newJObject()
  add(query_603691, "ForceFailover", newJBool(ForceFailover))
  add(query_603691, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603691, "Action", newJString(Action))
  add(query_603691, "Version", newJString(Version))
  result = call_603690.call(nil, query_603691, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_603675(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_603676, base: "/",
    url: url_GetRebootDBInstance_603677, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_603727 = ref object of OpenApiRestCall_601373
proc url_PostRemoveSourceIdentifierFromSubscription_603729(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_603728(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603730 = query.getOrDefault("Action")
  valid_603730 = validateParameter(valid_603730, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_603730 != nil:
    section.add "Action", valid_603730
  var valid_603731 = query.getOrDefault("Version")
  valid_603731 = validateParameter(valid_603731, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603731 != nil:
    section.add "Version", valid_603731
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
  var valid_603732 = header.getOrDefault("X-Amz-Signature")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Signature", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Content-Sha256", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Date")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Date", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Credential")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Credential", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Security-Token")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Security-Token", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Algorithm")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Algorithm", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-SignedHeaders", valid_603738
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603739 = formData.getOrDefault("SubscriptionName")
  valid_603739 = validateParameter(valid_603739, JString, required = true,
                                 default = nil)
  if valid_603739 != nil:
    section.add "SubscriptionName", valid_603739
  var valid_603740 = formData.getOrDefault("SourceIdentifier")
  valid_603740 = validateParameter(valid_603740, JString, required = true,
                                 default = nil)
  if valid_603740 != nil:
    section.add "SourceIdentifier", valid_603740
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603741: Call_PostRemoveSourceIdentifierFromSubscription_603727;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603741.validator(path, query, header, formData, body)
  let scheme = call_603741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603741.url(scheme.get, call_603741.host, call_603741.base,
                         call_603741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603741, url, valid)

proc call*(call_603742: Call_PostRemoveSourceIdentifierFromSubscription_603727;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603743 = newJObject()
  var formData_603744 = newJObject()
  add(formData_603744, "SubscriptionName", newJString(SubscriptionName))
  add(formData_603744, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_603743, "Action", newJString(Action))
  add(query_603743, "Version", newJString(Version))
  result = call_603742.call(nil, query_603743, nil, formData_603744, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_603727(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_603728,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_603729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_603710 = ref object of OpenApiRestCall_601373
proc url_GetRemoveSourceIdentifierFromSubscription_603712(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_603711(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SourceIdentifier` field"
  var valid_603713 = query.getOrDefault("SourceIdentifier")
  valid_603713 = validateParameter(valid_603713, JString, required = true,
                                 default = nil)
  if valid_603713 != nil:
    section.add "SourceIdentifier", valid_603713
  var valid_603714 = query.getOrDefault("SubscriptionName")
  valid_603714 = validateParameter(valid_603714, JString, required = true,
                                 default = nil)
  if valid_603714 != nil:
    section.add "SubscriptionName", valid_603714
  var valid_603715 = query.getOrDefault("Action")
  valid_603715 = validateParameter(valid_603715, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_603715 != nil:
    section.add "Action", valid_603715
  var valid_603716 = query.getOrDefault("Version")
  valid_603716 = validateParameter(valid_603716, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603716 != nil:
    section.add "Version", valid_603716
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
  var valid_603717 = header.getOrDefault("X-Amz-Signature")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Signature", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Content-Sha256", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Date")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Date", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Credential")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Credential", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Security-Token")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Security-Token", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Algorithm")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Algorithm", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-SignedHeaders", valid_603723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603724: Call_GetRemoveSourceIdentifierFromSubscription_603710;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603724.validator(path, query, header, formData, body)
  let scheme = call_603724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603724.url(scheme.get, call_603724.host, call_603724.base,
                         call_603724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603724, url, valid)

proc call*(call_603725: Call_GetRemoveSourceIdentifierFromSubscription_603710;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603726 = newJObject()
  add(query_603726, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_603726, "SubscriptionName", newJString(SubscriptionName))
  add(query_603726, "Action", newJString(Action))
  add(query_603726, "Version", newJString(Version))
  result = call_603725.call(nil, query_603726, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_603710(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_603711,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_603712,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_603762 = ref object of OpenApiRestCall_601373
proc url_PostRemoveTagsFromResource_603764(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_603763(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603765 = query.getOrDefault("Action")
  valid_603765 = validateParameter(valid_603765, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603765 != nil:
    section.add "Action", valid_603765
  var valid_603766 = query.getOrDefault("Version")
  valid_603766 = validateParameter(valid_603766, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603766 != nil:
    section.add "Version", valid_603766
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
  var valid_603767 = header.getOrDefault("X-Amz-Signature")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Signature", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Content-Sha256", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Date")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Date", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Credential")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Credential", valid_603770
  var valid_603771 = header.getOrDefault("X-Amz-Security-Token")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-Security-Token", valid_603771
  var valid_603772 = header.getOrDefault("X-Amz-Algorithm")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Algorithm", valid_603772
  var valid_603773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-SignedHeaders", valid_603773
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_603774 = formData.getOrDefault("TagKeys")
  valid_603774 = validateParameter(valid_603774, JArray, required = true, default = nil)
  if valid_603774 != nil:
    section.add "TagKeys", valid_603774
  var valid_603775 = formData.getOrDefault("ResourceName")
  valid_603775 = validateParameter(valid_603775, JString, required = true,
                                 default = nil)
  if valid_603775 != nil:
    section.add "ResourceName", valid_603775
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603776: Call_PostRemoveTagsFromResource_603762; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603776.validator(path, query, header, formData, body)
  let scheme = call_603776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603776.url(scheme.get, call_603776.host, call_603776.base,
                         call_603776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603776, url, valid)

proc call*(call_603777: Call_PostRemoveTagsFromResource_603762; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_603778 = newJObject()
  var formData_603779 = newJObject()
  if TagKeys != nil:
    formData_603779.add "TagKeys", TagKeys
  add(query_603778, "Action", newJString(Action))
  add(query_603778, "Version", newJString(Version))
  add(formData_603779, "ResourceName", newJString(ResourceName))
  result = call_603777.call(nil, query_603778, nil, formData_603779, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_603762(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_603763, base: "/",
    url: url_PostRemoveTagsFromResource_603764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_603745 = ref object of OpenApiRestCall_601373
proc url_GetRemoveTagsFromResource_603747(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_603746(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##   TagKeys: JArray (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_603748 = query.getOrDefault("ResourceName")
  valid_603748 = validateParameter(valid_603748, JString, required = true,
                                 default = nil)
  if valid_603748 != nil:
    section.add "ResourceName", valid_603748
  var valid_603749 = query.getOrDefault("TagKeys")
  valid_603749 = validateParameter(valid_603749, JArray, required = true, default = nil)
  if valid_603749 != nil:
    section.add "TagKeys", valid_603749
  var valid_603750 = query.getOrDefault("Action")
  valid_603750 = validateParameter(valid_603750, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603750 != nil:
    section.add "Action", valid_603750
  var valid_603751 = query.getOrDefault("Version")
  valid_603751 = validateParameter(valid_603751, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603751 != nil:
    section.add "Version", valid_603751
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
  var valid_603752 = header.getOrDefault("X-Amz-Signature")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Signature", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Content-Sha256", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Date")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Date", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Credential")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Credential", valid_603755
  var valid_603756 = header.getOrDefault("X-Amz-Security-Token")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-Security-Token", valid_603756
  var valid_603757 = header.getOrDefault("X-Amz-Algorithm")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Algorithm", valid_603757
  var valid_603758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-SignedHeaders", valid_603758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603759: Call_GetRemoveTagsFromResource_603745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603759.validator(path, query, header, formData, body)
  let scheme = call_603759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603759.url(scheme.get, call_603759.host, call_603759.base,
                         call_603759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603759, url, valid)

proc call*(call_603760: Call_GetRemoveTagsFromResource_603745;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-01-10"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603761 = newJObject()
  add(query_603761, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_603761.add "TagKeys", TagKeys
  add(query_603761, "Action", newJString(Action))
  add(query_603761, "Version", newJString(Version))
  result = call_603760.call(nil, query_603761, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_603745(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_603746, base: "/",
    url: url_GetRemoveTagsFromResource_603747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_603798 = ref object of OpenApiRestCall_601373
proc url_PostResetDBParameterGroup_603800(protocol: Scheme; host: string;
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

proc validate_PostResetDBParameterGroup_603799(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603801 = query.getOrDefault("Action")
  valid_603801 = validateParameter(valid_603801, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_603801 != nil:
    section.add "Action", valid_603801
  var valid_603802 = query.getOrDefault("Version")
  valid_603802 = validateParameter(valid_603802, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603802 != nil:
    section.add "Version", valid_603802
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
  var valid_603803 = header.getOrDefault("X-Amz-Signature")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Signature", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Content-Sha256", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-Date")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-Date", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Credential")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Credential", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-Security-Token")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Security-Token", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-Algorithm")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-Algorithm", valid_603808
  var valid_603809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "X-Amz-SignedHeaders", valid_603809
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_603810 = formData.getOrDefault("ResetAllParameters")
  valid_603810 = validateParameter(valid_603810, JBool, required = false, default = nil)
  if valid_603810 != nil:
    section.add "ResetAllParameters", valid_603810
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603811 = formData.getOrDefault("DBParameterGroupName")
  valid_603811 = validateParameter(valid_603811, JString, required = true,
                                 default = nil)
  if valid_603811 != nil:
    section.add "DBParameterGroupName", valid_603811
  var valid_603812 = formData.getOrDefault("Parameters")
  valid_603812 = validateParameter(valid_603812, JArray, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "Parameters", valid_603812
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603813: Call_PostResetDBParameterGroup_603798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603813.validator(path, query, header, formData, body)
  let scheme = call_603813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603813.url(scheme.get, call_603813.host, call_603813.base,
                         call_603813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603813, url, valid)

proc call*(call_603814: Call_PostResetDBParameterGroup_603798;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-01-10"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_603815 = newJObject()
  var formData_603816 = newJObject()
  add(formData_603816, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_603816, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603815, "Action", newJString(Action))
  if Parameters != nil:
    formData_603816.add "Parameters", Parameters
  add(query_603815, "Version", newJString(Version))
  result = call_603814.call(nil, query_603815, nil, formData_603816, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_603798(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_603799, base: "/",
    url: url_PostResetDBParameterGroup_603800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_603780 = ref object of OpenApiRestCall_601373
proc url_GetResetDBParameterGroup_603782(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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

proc validate_GetResetDBParameterGroup_603781(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_603783 = query.getOrDefault("DBParameterGroupName")
  valid_603783 = validateParameter(valid_603783, JString, required = true,
                                 default = nil)
  if valid_603783 != nil:
    section.add "DBParameterGroupName", valid_603783
  var valid_603784 = query.getOrDefault("Parameters")
  valid_603784 = validateParameter(valid_603784, JArray, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "Parameters", valid_603784
  var valid_603785 = query.getOrDefault("ResetAllParameters")
  valid_603785 = validateParameter(valid_603785, JBool, required = false, default = nil)
  if valid_603785 != nil:
    section.add "ResetAllParameters", valid_603785
  var valid_603786 = query.getOrDefault("Action")
  valid_603786 = validateParameter(valid_603786, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_603786 != nil:
    section.add "Action", valid_603786
  var valid_603787 = query.getOrDefault("Version")
  valid_603787 = validateParameter(valid_603787, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603787 != nil:
    section.add "Version", valid_603787
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
  var valid_603788 = header.getOrDefault("X-Amz-Signature")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Signature", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Content-Sha256", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-Date")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-Date", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Credential")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Credential", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-Security-Token")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Security-Token", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Algorithm")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Algorithm", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-SignedHeaders", valid_603794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603795: Call_GetResetDBParameterGroup_603780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603795.validator(path, query, header, formData, body)
  let scheme = call_603795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603795.url(scheme.get, call_603795.host, call_603795.base,
                         call_603795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603795, url, valid)

proc call*(call_603796: Call_GetResetDBParameterGroup_603780;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603797 = newJObject()
  add(query_603797, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_603797.add "Parameters", Parameters
  add(query_603797, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_603797, "Action", newJString(Action))
  add(query_603797, "Version", newJString(Version))
  result = call_603796.call(nil, query_603797, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_603780(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_603781, base: "/",
    url: url_GetResetDBParameterGroup_603782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_603846 = ref object of OpenApiRestCall_601373
proc url_PostRestoreDBInstanceFromDBSnapshot_603848(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceFromDBSnapshot_603847(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603849 = query.getOrDefault("Action")
  valid_603849 = validateParameter(valid_603849, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603849 != nil:
    section.add "Action", valid_603849
  var valid_603850 = query.getOrDefault("Version")
  valid_603850 = validateParameter(valid_603850, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603850 != nil:
    section.add "Version", valid_603850
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
  var valid_603851 = header.getOrDefault("X-Amz-Signature")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Signature", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Content-Sha256", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Date")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Date", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Credential")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Credential", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Security-Token")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Security-Token", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Algorithm")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Algorithm", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-SignedHeaders", valid_603857
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   DBName: JString
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_603858 = formData.getOrDefault("Port")
  valid_603858 = validateParameter(valid_603858, JInt, required = false, default = nil)
  if valid_603858 != nil:
    section.add "Port", valid_603858
  var valid_603859 = formData.getOrDefault("DBInstanceClass")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "DBInstanceClass", valid_603859
  var valid_603860 = formData.getOrDefault("MultiAZ")
  valid_603860 = validateParameter(valid_603860, JBool, required = false, default = nil)
  if valid_603860 != nil:
    section.add "MultiAZ", valid_603860
  var valid_603861 = formData.getOrDefault("AvailabilityZone")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "AvailabilityZone", valid_603861
  var valid_603862 = formData.getOrDefault("Engine")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "Engine", valid_603862
  var valid_603863 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603863 = validateParameter(valid_603863, JBool, required = false, default = nil)
  if valid_603863 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603863
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603864 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603864 = validateParameter(valid_603864, JString, required = true,
                                 default = nil)
  if valid_603864 != nil:
    section.add "DBInstanceIdentifier", valid_603864
  var valid_603865 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603865 = validateParameter(valid_603865, JString, required = true,
                                 default = nil)
  if valid_603865 != nil:
    section.add "DBSnapshotIdentifier", valid_603865
  var valid_603866 = formData.getOrDefault("DBName")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "DBName", valid_603866
  var valid_603867 = formData.getOrDefault("Iops")
  valid_603867 = validateParameter(valid_603867, JInt, required = false, default = nil)
  if valid_603867 != nil:
    section.add "Iops", valid_603867
  var valid_603868 = formData.getOrDefault("PubliclyAccessible")
  valid_603868 = validateParameter(valid_603868, JBool, required = false, default = nil)
  if valid_603868 != nil:
    section.add "PubliclyAccessible", valid_603868
  var valid_603869 = formData.getOrDefault("LicenseModel")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "LicenseModel", valid_603869
  var valid_603870 = formData.getOrDefault("DBSubnetGroupName")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "DBSubnetGroupName", valid_603870
  var valid_603871 = formData.getOrDefault("OptionGroupName")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "OptionGroupName", valid_603871
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603872: Call_PostRestoreDBInstanceFromDBSnapshot_603846;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603872.validator(path, query, header, formData, body)
  let scheme = call_603872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603872.url(scheme.get, call_603872.host, call_603872.base,
                         call_603872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603872, url, valid)

proc call*(call_603873: Call_PostRestoreDBInstanceFromDBSnapshot_603846;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          LicenseModel: string = ""; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   DBName: string
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_603874 = newJObject()
  var formData_603875 = newJObject()
  add(formData_603875, "Port", newJInt(Port))
  add(formData_603875, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603875, "MultiAZ", newJBool(MultiAZ))
  add(formData_603875, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603875, "Engine", newJString(Engine))
  add(formData_603875, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603875, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603875, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_603875, "DBName", newJString(DBName))
  add(formData_603875, "Iops", newJInt(Iops))
  add(formData_603875, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603874, "Action", newJString(Action))
  add(formData_603875, "LicenseModel", newJString(LicenseModel))
  add(formData_603875, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603875, "OptionGroupName", newJString(OptionGroupName))
  add(query_603874, "Version", newJString(Version))
  result = call_603873.call(nil, query_603874, nil, formData_603875, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_603846(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_603847, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_603848,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_603817 = ref object of OpenApiRestCall_601373
proc url_GetRestoreDBInstanceFromDBSnapshot_603819(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceFromDBSnapshot_603818(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   Port: JInt
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  var valid_603820 = query.getOrDefault("DBName")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "DBName", valid_603820
  var valid_603821 = query.getOrDefault("Engine")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "Engine", valid_603821
  var valid_603822 = query.getOrDefault("LicenseModel")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "LicenseModel", valid_603822
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603823 = query.getOrDefault("DBInstanceIdentifier")
  valid_603823 = validateParameter(valid_603823, JString, required = true,
                                 default = nil)
  if valid_603823 != nil:
    section.add "DBInstanceIdentifier", valid_603823
  var valid_603824 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603824 = validateParameter(valid_603824, JString, required = true,
                                 default = nil)
  if valid_603824 != nil:
    section.add "DBSnapshotIdentifier", valid_603824
  var valid_603825 = query.getOrDefault("Action")
  valid_603825 = validateParameter(valid_603825, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603825 != nil:
    section.add "Action", valid_603825
  var valid_603826 = query.getOrDefault("MultiAZ")
  valid_603826 = validateParameter(valid_603826, JBool, required = false, default = nil)
  if valid_603826 != nil:
    section.add "MultiAZ", valid_603826
  var valid_603827 = query.getOrDefault("Port")
  valid_603827 = validateParameter(valid_603827, JInt, required = false, default = nil)
  if valid_603827 != nil:
    section.add "Port", valid_603827
  var valid_603828 = query.getOrDefault("AvailabilityZone")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "AvailabilityZone", valid_603828
  var valid_603829 = query.getOrDefault("OptionGroupName")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "OptionGroupName", valid_603829
  var valid_603830 = query.getOrDefault("DBSubnetGroupName")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "DBSubnetGroupName", valid_603830
  var valid_603831 = query.getOrDefault("Version")
  valid_603831 = validateParameter(valid_603831, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603831 != nil:
    section.add "Version", valid_603831
  var valid_603832 = query.getOrDefault("DBInstanceClass")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "DBInstanceClass", valid_603832
  var valid_603833 = query.getOrDefault("PubliclyAccessible")
  valid_603833 = validateParameter(valid_603833, JBool, required = false, default = nil)
  if valid_603833 != nil:
    section.add "PubliclyAccessible", valid_603833
  var valid_603834 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603834 = validateParameter(valid_603834, JBool, required = false, default = nil)
  if valid_603834 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603834
  var valid_603835 = query.getOrDefault("Iops")
  valid_603835 = validateParameter(valid_603835, JInt, required = false, default = nil)
  if valid_603835 != nil:
    section.add "Iops", valid_603835
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
  var valid_603836 = header.getOrDefault("X-Amz-Signature")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Signature", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Content-Sha256", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Date")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Date", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Credential")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Credential", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Security-Token")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Security-Token", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Algorithm")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Algorithm", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-SignedHeaders", valid_603842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603843: Call_GetRestoreDBInstanceFromDBSnapshot_603817;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603843.validator(path, query, header, formData, body)
  let scheme = call_603843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603843.url(scheme.get, call_603843.host, call_603843.base,
                         call_603843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603843, url, valid)

proc call*(call_603844: Call_GetRestoreDBInstanceFromDBSnapshot_603817;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          DBName: string = ""; Engine: string = ""; LicenseModel: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-01-10";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   DBName: string
  ##   Engine: string
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_603845 = newJObject()
  add(query_603845, "DBName", newJString(DBName))
  add(query_603845, "Engine", newJString(Engine))
  add(query_603845, "LicenseModel", newJString(LicenseModel))
  add(query_603845, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603845, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603845, "Action", newJString(Action))
  add(query_603845, "MultiAZ", newJBool(MultiAZ))
  add(query_603845, "Port", newJInt(Port))
  add(query_603845, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603845, "OptionGroupName", newJString(OptionGroupName))
  add(query_603845, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603845, "Version", newJString(Version))
  add(query_603845, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603845, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603845, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603845, "Iops", newJInt(Iops))
  result = call_603844.call(nil, query_603845, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_603817(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_603818, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_603819,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_603907 = ref object of OpenApiRestCall_601373
proc url_PostRestoreDBInstanceToPointInTime_603909(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceToPointInTime_603908(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603910 = query.getOrDefault("Action")
  valid_603910 = validateParameter(valid_603910, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603910 != nil:
    section.add "Action", valid_603910
  var valid_603911 = query.getOrDefault("Version")
  valid_603911 = validateParameter(valid_603911, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603911 != nil:
    section.add "Version", valid_603911
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
  var valid_603912 = header.getOrDefault("X-Amz-Signature")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Signature", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Content-Sha256", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Date")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Date", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Credential")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Credential", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-Security-Token")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Security-Token", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Algorithm")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Algorithm", valid_603917
  var valid_603918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-SignedHeaders", valid_603918
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   UseLatestRestorableTime: JBool
  ##   DBName: JString
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603919 = formData.getOrDefault("Port")
  valid_603919 = validateParameter(valid_603919, JInt, required = false, default = nil)
  if valid_603919 != nil:
    section.add "Port", valid_603919
  var valid_603920 = formData.getOrDefault("DBInstanceClass")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "DBInstanceClass", valid_603920
  var valid_603921 = formData.getOrDefault("MultiAZ")
  valid_603921 = validateParameter(valid_603921, JBool, required = false, default = nil)
  if valid_603921 != nil:
    section.add "MultiAZ", valid_603921
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_603922 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603922 = validateParameter(valid_603922, JString, required = true,
                                 default = nil)
  if valid_603922 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603922
  var valid_603923 = formData.getOrDefault("AvailabilityZone")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "AvailabilityZone", valid_603923
  var valid_603924 = formData.getOrDefault("Engine")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "Engine", valid_603924
  var valid_603925 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603925 = validateParameter(valid_603925, JBool, required = false, default = nil)
  if valid_603925 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603925
  var valid_603926 = formData.getOrDefault("UseLatestRestorableTime")
  valid_603926 = validateParameter(valid_603926, JBool, required = false, default = nil)
  if valid_603926 != nil:
    section.add "UseLatestRestorableTime", valid_603926
  var valid_603927 = formData.getOrDefault("DBName")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "DBName", valid_603927
  var valid_603928 = formData.getOrDefault("Iops")
  valid_603928 = validateParameter(valid_603928, JInt, required = false, default = nil)
  if valid_603928 != nil:
    section.add "Iops", valid_603928
  var valid_603929 = formData.getOrDefault("PubliclyAccessible")
  valid_603929 = validateParameter(valid_603929, JBool, required = false, default = nil)
  if valid_603929 != nil:
    section.add "PubliclyAccessible", valid_603929
  var valid_603930 = formData.getOrDefault("LicenseModel")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "LicenseModel", valid_603930
  var valid_603931 = formData.getOrDefault("DBSubnetGroupName")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "DBSubnetGroupName", valid_603931
  var valid_603932 = formData.getOrDefault("OptionGroupName")
  valid_603932 = validateParameter(valid_603932, JString, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "OptionGroupName", valid_603932
  var valid_603933 = formData.getOrDefault("RestoreTime")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "RestoreTime", valid_603933
  var valid_603934 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_603934 = validateParameter(valid_603934, JString, required = true,
                                 default = nil)
  if valid_603934 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603934
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603935: Call_PostRestoreDBInstanceToPointInTime_603907;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603935.validator(path, query, header, formData, body)
  let scheme = call_603935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603935.url(scheme.get, call_603935.host, call_603935.base,
                         call_603935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603935, url, valid)

proc call*(call_603936: Call_PostRestoreDBInstanceToPointInTime_603907;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false;
          UseLatestRestorableTime: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          LicenseModel: string = ""; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; RestoreTime: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   UseLatestRestorableTime: bool
  ##   DBName: string
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Version: string (required)
  var query_603937 = newJObject()
  var formData_603938 = newJObject()
  add(formData_603938, "Port", newJInt(Port))
  add(formData_603938, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603938, "MultiAZ", newJBool(MultiAZ))
  add(formData_603938, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603938, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603938, "Engine", newJString(Engine))
  add(formData_603938, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603938, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_603938, "DBName", newJString(DBName))
  add(formData_603938, "Iops", newJInt(Iops))
  add(formData_603938, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603937, "Action", newJString(Action))
  add(formData_603938, "LicenseModel", newJString(LicenseModel))
  add(formData_603938, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603938, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603938, "RestoreTime", newJString(RestoreTime))
  add(formData_603938, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_603937, "Version", newJString(Version))
  result = call_603936.call(nil, query_603937, nil, formData_603938, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_603907(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_603908, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_603909,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_603876 = ref object of OpenApiRestCall_601373
proc url_GetRestoreDBInstanceToPointInTime_603878(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceToPointInTime_603877(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
  ##   UseLatestRestorableTime: JBool
  ##   LicenseModel: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   MultiAZ: JBool
  ##   Port: JInt
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   RestoreTime: JString
  ##   DBInstanceClass: JString
  ##   PubliclyAccessible: JBool
  ##   Version: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  var valid_603879 = query.getOrDefault("DBName")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "DBName", valid_603879
  var valid_603880 = query.getOrDefault("Engine")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "Engine", valid_603880
  var valid_603881 = query.getOrDefault("UseLatestRestorableTime")
  valid_603881 = validateParameter(valid_603881, JBool, required = false, default = nil)
  if valid_603881 != nil:
    section.add "UseLatestRestorableTime", valid_603881
  var valid_603882 = query.getOrDefault("LicenseModel")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "LicenseModel", valid_603882
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_603883 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_603883 = validateParameter(valid_603883, JString, required = true,
                                 default = nil)
  if valid_603883 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603883
  var valid_603884 = query.getOrDefault("Action")
  valid_603884 = validateParameter(valid_603884, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603884 != nil:
    section.add "Action", valid_603884
  var valid_603885 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603885 = validateParameter(valid_603885, JString, required = true,
                                 default = nil)
  if valid_603885 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603885
  var valid_603886 = query.getOrDefault("MultiAZ")
  valid_603886 = validateParameter(valid_603886, JBool, required = false, default = nil)
  if valid_603886 != nil:
    section.add "MultiAZ", valid_603886
  var valid_603887 = query.getOrDefault("Port")
  valid_603887 = validateParameter(valid_603887, JInt, required = false, default = nil)
  if valid_603887 != nil:
    section.add "Port", valid_603887
  var valid_603888 = query.getOrDefault("AvailabilityZone")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "AvailabilityZone", valid_603888
  var valid_603889 = query.getOrDefault("OptionGroupName")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "OptionGroupName", valid_603889
  var valid_603890 = query.getOrDefault("DBSubnetGroupName")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "DBSubnetGroupName", valid_603890
  var valid_603891 = query.getOrDefault("RestoreTime")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "RestoreTime", valid_603891
  var valid_603892 = query.getOrDefault("DBInstanceClass")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "DBInstanceClass", valid_603892
  var valid_603893 = query.getOrDefault("PubliclyAccessible")
  valid_603893 = validateParameter(valid_603893, JBool, required = false, default = nil)
  if valid_603893 != nil:
    section.add "PubliclyAccessible", valid_603893
  var valid_603894 = query.getOrDefault("Version")
  valid_603894 = validateParameter(valid_603894, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603894 != nil:
    section.add "Version", valid_603894
  var valid_603895 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603895 = validateParameter(valid_603895, JBool, required = false, default = nil)
  if valid_603895 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603895
  var valid_603896 = query.getOrDefault("Iops")
  valid_603896 = validateParameter(valid_603896, JInt, required = false, default = nil)
  if valid_603896 != nil:
    section.add "Iops", valid_603896
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
  var valid_603897 = header.getOrDefault("X-Amz-Signature")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Signature", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Content-Sha256", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Date")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Date", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-Credential")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Credential", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Security-Token")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Security-Token", valid_603901
  var valid_603902 = header.getOrDefault("X-Amz-Algorithm")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Algorithm", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-SignedHeaders", valid_603903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603904: Call_GetRestoreDBInstanceToPointInTime_603876;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603904.validator(path, query, header, formData, body)
  let scheme = call_603904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603904.url(scheme.get, call_603904.host, call_603904.base,
                         call_603904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603904, url, valid)

proc call*(call_603905: Call_GetRestoreDBInstanceToPointInTime_603876;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          DBName: string = ""; Engine: string = "";
          UseLatestRestorableTime: bool = false; LicenseModel: string = "";
          Action: string = "RestoreDBInstanceToPointInTime"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; RestoreTime: string = "";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          Version: string = "2013-01-10"; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   DBName: string
  ##   Engine: string
  ##   UseLatestRestorableTime: bool
  ##   LicenseModel: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBInstanceIdentifier: string (required)
  ##   MultiAZ: bool
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   RestoreTime: string
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   Version: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_603906 = newJObject()
  add(query_603906, "DBName", newJString(DBName))
  add(query_603906, "Engine", newJString(Engine))
  add(query_603906, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_603906, "LicenseModel", newJString(LicenseModel))
  add(query_603906, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_603906, "Action", newJString(Action))
  add(query_603906, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603906, "MultiAZ", newJBool(MultiAZ))
  add(query_603906, "Port", newJInt(Port))
  add(query_603906, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603906, "OptionGroupName", newJString(OptionGroupName))
  add(query_603906, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603906, "RestoreTime", newJString(RestoreTime))
  add(query_603906, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603906, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603906, "Version", newJString(Version))
  add(query_603906, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603906, "Iops", newJInt(Iops))
  result = call_603905.call(nil, query_603906, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_603876(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_603877, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_603878,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_603959 = ref object of OpenApiRestCall_601373
proc url_PostRevokeDBSecurityGroupIngress_603961(protocol: Scheme; host: string;
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

proc validate_PostRevokeDBSecurityGroupIngress_603960(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603962 = query.getOrDefault("Action")
  valid_603962 = validateParameter(valid_603962, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603962 != nil:
    section.add "Action", valid_603962
  var valid_603963 = query.getOrDefault("Version")
  valid_603963 = validateParameter(valid_603963, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603963 != nil:
    section.add "Version", valid_603963
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
  var valid_603964 = header.getOrDefault("X-Amz-Signature")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "X-Amz-Signature", valid_603964
  var valid_603965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "X-Amz-Content-Sha256", valid_603965
  var valid_603966 = header.getOrDefault("X-Amz-Date")
  valid_603966 = validateParameter(valid_603966, JString, required = false,
                                 default = nil)
  if valid_603966 != nil:
    section.add "X-Amz-Date", valid_603966
  var valid_603967 = header.getOrDefault("X-Amz-Credential")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "X-Amz-Credential", valid_603967
  var valid_603968 = header.getOrDefault("X-Amz-Security-Token")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "X-Amz-Security-Token", valid_603968
  var valid_603969 = header.getOrDefault("X-Amz-Algorithm")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Algorithm", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-SignedHeaders", valid_603970
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603971 = formData.getOrDefault("DBSecurityGroupName")
  valid_603971 = validateParameter(valid_603971, JString, required = true,
                                 default = nil)
  if valid_603971 != nil:
    section.add "DBSecurityGroupName", valid_603971
  var valid_603972 = formData.getOrDefault("EC2SecurityGroupName")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "EC2SecurityGroupName", valid_603972
  var valid_603973 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603973
  var valid_603974 = formData.getOrDefault("EC2SecurityGroupId")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "EC2SecurityGroupId", valid_603974
  var valid_603975 = formData.getOrDefault("CIDRIP")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "CIDRIP", valid_603975
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603976: Call_PostRevokeDBSecurityGroupIngress_603959;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603976.validator(path, query, header, formData, body)
  let scheme = call_603976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603976.url(scheme.get, call_603976.host, call_603976.base,
                         call_603976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603976, url, valid)

proc call*(call_603977: Call_PostRevokeDBSecurityGroupIngress_603959;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-01-10"): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603978 = newJObject()
  var formData_603979 = newJObject()
  add(formData_603979, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_603979, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_603979, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_603979, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_603979, "CIDRIP", newJString(CIDRIP))
  add(query_603978, "Action", newJString(Action))
  add(query_603978, "Version", newJString(Version))
  result = call_603977.call(nil, query_603978, nil, formData_603979, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_603959(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_603960, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_603961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_603939 = ref object of OpenApiRestCall_601373
proc url_GetRevokeDBSecurityGroupIngress_603941(protocol: Scheme; host: string;
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

proc validate_GetRevokeDBSecurityGroupIngress_603940(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupName: JString
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupId: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   CIDRIP: JString
  section = newJObject()
  var valid_603942 = query.getOrDefault("EC2SecurityGroupName")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "EC2SecurityGroupName", valid_603942
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603943 = query.getOrDefault("DBSecurityGroupName")
  valid_603943 = validateParameter(valid_603943, JString, required = true,
                                 default = nil)
  if valid_603943 != nil:
    section.add "DBSecurityGroupName", valid_603943
  var valid_603944 = query.getOrDefault("EC2SecurityGroupId")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "EC2SecurityGroupId", valid_603944
  var valid_603945 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603945
  var valid_603946 = query.getOrDefault("Action")
  valid_603946 = validateParameter(valid_603946, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603946 != nil:
    section.add "Action", valid_603946
  var valid_603947 = query.getOrDefault("Version")
  valid_603947 = validateParameter(valid_603947, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603947 != nil:
    section.add "Version", valid_603947
  var valid_603948 = query.getOrDefault("CIDRIP")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "CIDRIP", valid_603948
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
  var valid_603949 = header.getOrDefault("X-Amz-Signature")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Signature", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Content-Sha256", valid_603950
  var valid_603951 = header.getOrDefault("X-Amz-Date")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-Date", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Credential")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Credential", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Security-Token")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Security-Token", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Algorithm")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Algorithm", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-SignedHeaders", valid_603955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603956: Call_GetRevokeDBSecurityGroupIngress_603939;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603956.validator(path, query, header, formData, body)
  let scheme = call_603956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603956.url(scheme.get, call_603956.host, call_603956.base,
                         call_603956.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603956, url, valid)

proc call*(call_603957: Call_GetRevokeDBSecurityGroupIngress_603939;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-01-10"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_603958 = newJObject()
  add(query_603958, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_603958, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603958, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_603958, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_603958, "Action", newJString(Action))
  add(query_603958, "Version", newJString(Version))
  add(query_603958, "CIDRIP", newJString(CIDRIP))
  result = call_603957.call(nil, query_603958, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_603939(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_603940, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_603941,
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
