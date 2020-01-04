
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2013-02-12
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"; CIDRIP: string = ""): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          CharacterSetName: string = ""; Version: string = "2013-02-12";
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
                                 default = newJString("2013-02-12"))
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
          DBInstanceClass: string; Version: string = "2013-02-12";
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
                                 default = newJString("2013-02-12"))
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
          OptionGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"; DBInstanceClass: string = "";
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateEventSubscription"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateOptionGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteDBInstance"; Version: string = "2013-02-12";
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"; DBParameterGroupFamily: string = ""): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          ListSupportedCharacterSets: bool = false; Version: string = "2013-02-12";
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DescribeDBInstances"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
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
  Call_PostDescribeDBLogFiles_602804 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBLogFiles_602806(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBLogFiles_602805(path: JsonNode; query: JsonNode;
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
  var valid_602807 = query.getOrDefault("Action")
  valid_602807 = validateParameter(valid_602807, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_602807 != nil:
    section.add "Action", valid_602807
  var valid_602808 = query.getOrDefault("Version")
  valid_602808 = validateParameter(valid_602808, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602808 != nil:
    section.add "Version", valid_602808
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
  var valid_602809 = header.getOrDefault("X-Amz-Signature")
  valid_602809 = validateParameter(valid_602809, JString, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "X-Amz-Signature", valid_602809
  var valid_602810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "X-Amz-Content-Sha256", valid_602810
  var valid_602811 = header.getOrDefault("X-Amz-Date")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "X-Amz-Date", valid_602811
  var valid_602812 = header.getOrDefault("X-Amz-Credential")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "X-Amz-Credential", valid_602812
  var valid_602813 = header.getOrDefault("X-Amz-Security-Token")
  valid_602813 = validateParameter(valid_602813, JString, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "X-Amz-Security-Token", valid_602813
  var valid_602814 = header.getOrDefault("X-Amz-Algorithm")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "X-Amz-Algorithm", valid_602814
  var valid_602815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602815 = validateParameter(valid_602815, JString, required = false,
                                 default = nil)
  if valid_602815 != nil:
    section.add "X-Amz-SignedHeaders", valid_602815
  result.add "header", section
  ## parameters in `formData` object:
  ##   FileSize: JInt
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FilenameContains: JString
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_602816 = formData.getOrDefault("FileSize")
  valid_602816 = validateParameter(valid_602816, JInt, required = false, default = nil)
  if valid_602816 != nil:
    section.add "FileSize", valid_602816
  var valid_602817 = formData.getOrDefault("MaxRecords")
  valid_602817 = validateParameter(valid_602817, JInt, required = false, default = nil)
  if valid_602817 != nil:
    section.add "MaxRecords", valid_602817
  var valid_602818 = formData.getOrDefault("Marker")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "Marker", valid_602818
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602819 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602819 = validateParameter(valid_602819, JString, required = true,
                                 default = nil)
  if valid_602819 != nil:
    section.add "DBInstanceIdentifier", valid_602819
  var valid_602820 = formData.getOrDefault("FilenameContains")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "FilenameContains", valid_602820
  var valid_602821 = formData.getOrDefault("FileLastWritten")
  valid_602821 = validateParameter(valid_602821, JInt, required = false, default = nil)
  if valid_602821 != nil:
    section.add "FileLastWritten", valid_602821
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602822: Call_PostDescribeDBLogFiles_602804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602822.validator(path, query, header, formData, body)
  let scheme = call_602822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602822.url(scheme.get, call_602822.host, call_602822.base,
                         call_602822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602822, url, valid)

proc call*(call_602823: Call_PostDescribeDBLogFiles_602804;
          DBInstanceIdentifier: string; FileSize: int = 0; MaxRecords: int = 0;
          Marker: string = ""; FilenameContains: string = "";
          Action: string = "DescribeDBLogFiles"; Version: string = "2013-02-12";
          FileLastWritten: int = 0): Recallable =
  ## postDescribeDBLogFiles
  ##   FileSize: int
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string (required)
  ##   FilenameContains: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FileLastWritten: int
  var query_602824 = newJObject()
  var formData_602825 = newJObject()
  add(formData_602825, "FileSize", newJInt(FileSize))
  add(formData_602825, "MaxRecords", newJInt(MaxRecords))
  add(formData_602825, "Marker", newJString(Marker))
  add(formData_602825, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602825, "FilenameContains", newJString(FilenameContains))
  add(query_602824, "Action", newJString(Action))
  add(query_602824, "Version", newJString(Version))
  add(formData_602825, "FileLastWritten", newJInt(FileLastWritten))
  result = call_602823.call(nil, query_602824, nil, formData_602825, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_602804(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_602805, base: "/",
    url: url_PostDescribeDBLogFiles_602806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_602783 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBLogFiles_602785(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBLogFiles_602784(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileLastWritten: JInt
  ##   Action: JString (required)
  ##   FilenameContains: JString
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  ##   FileSize: JInt
  section = newJObject()
  var valid_602786 = query.getOrDefault("Marker")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "Marker", valid_602786
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602787 = query.getOrDefault("DBInstanceIdentifier")
  valid_602787 = validateParameter(valid_602787, JString, required = true,
                                 default = nil)
  if valid_602787 != nil:
    section.add "DBInstanceIdentifier", valid_602787
  var valid_602788 = query.getOrDefault("FileLastWritten")
  valid_602788 = validateParameter(valid_602788, JInt, required = false, default = nil)
  if valid_602788 != nil:
    section.add "FileLastWritten", valid_602788
  var valid_602789 = query.getOrDefault("Action")
  valid_602789 = validateParameter(valid_602789, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_602789 != nil:
    section.add "Action", valid_602789
  var valid_602790 = query.getOrDefault("FilenameContains")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "FilenameContains", valid_602790
  var valid_602791 = query.getOrDefault("Version")
  valid_602791 = validateParameter(valid_602791, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602791 != nil:
    section.add "Version", valid_602791
  var valid_602792 = query.getOrDefault("MaxRecords")
  valid_602792 = validateParameter(valid_602792, JInt, required = false, default = nil)
  if valid_602792 != nil:
    section.add "MaxRecords", valid_602792
  var valid_602793 = query.getOrDefault("FileSize")
  valid_602793 = validateParameter(valid_602793, JInt, required = false, default = nil)
  if valid_602793 != nil:
    section.add "FileSize", valid_602793
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
  var valid_602794 = header.getOrDefault("X-Amz-Signature")
  valid_602794 = validateParameter(valid_602794, JString, required = false,
                                 default = nil)
  if valid_602794 != nil:
    section.add "X-Amz-Signature", valid_602794
  var valid_602795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602795 = validateParameter(valid_602795, JString, required = false,
                                 default = nil)
  if valid_602795 != nil:
    section.add "X-Amz-Content-Sha256", valid_602795
  var valid_602796 = header.getOrDefault("X-Amz-Date")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Date", valid_602796
  var valid_602797 = header.getOrDefault("X-Amz-Credential")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Credential", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-Security-Token")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Security-Token", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Algorithm")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Algorithm", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-SignedHeaders", valid_602800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602801: Call_GetDescribeDBLogFiles_602783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602801.validator(path, query, header, formData, body)
  let scheme = call_602801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602801.url(scheme.get, call_602801.host, call_602801.base,
                         call_602801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602801, url, valid)

proc call*(call_602802: Call_GetDescribeDBLogFiles_602783;
          DBInstanceIdentifier: string; Marker: string = ""; FileLastWritten: int = 0;
          Action: string = "DescribeDBLogFiles"; FilenameContains: string = "";
          Version: string = "2013-02-12"; MaxRecords: int = 0; FileSize: int = 0): Recallable =
  ## getDescribeDBLogFiles
  ##   Marker: string
  ##   DBInstanceIdentifier: string (required)
  ##   FileLastWritten: int
  ##   Action: string (required)
  ##   FilenameContains: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   FileSize: int
  var query_602803 = newJObject()
  add(query_602803, "Marker", newJString(Marker))
  add(query_602803, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602803, "FileLastWritten", newJInt(FileLastWritten))
  add(query_602803, "Action", newJString(Action))
  add(query_602803, "FilenameContains", newJString(FilenameContains))
  add(query_602803, "Version", newJString(Version))
  add(query_602803, "MaxRecords", newJInt(MaxRecords))
  add(query_602803, "FileSize", newJInt(FileSize))
  result = call_602802.call(nil, query_602803, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_602783(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_602784, base: "/",
    url: url_GetDescribeDBLogFiles_602785, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_602844 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBParameterGroups_602846(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameterGroups_602845(path: JsonNode; query: JsonNode;
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
  var valid_602847 = query.getOrDefault("Action")
  valid_602847 = validateParameter(valid_602847, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_602847 != nil:
    section.add "Action", valid_602847
  var valid_602848 = query.getOrDefault("Version")
  valid_602848 = validateParameter(valid_602848, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602848 != nil:
    section.add "Version", valid_602848
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
  var valid_602849 = header.getOrDefault("X-Amz-Signature")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-Signature", valid_602849
  var valid_602850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "X-Amz-Content-Sha256", valid_602850
  var valid_602851 = header.getOrDefault("X-Amz-Date")
  valid_602851 = validateParameter(valid_602851, JString, required = false,
                                 default = nil)
  if valid_602851 != nil:
    section.add "X-Amz-Date", valid_602851
  var valid_602852 = header.getOrDefault("X-Amz-Credential")
  valid_602852 = validateParameter(valid_602852, JString, required = false,
                                 default = nil)
  if valid_602852 != nil:
    section.add "X-Amz-Credential", valid_602852
  var valid_602853 = header.getOrDefault("X-Amz-Security-Token")
  valid_602853 = validateParameter(valid_602853, JString, required = false,
                                 default = nil)
  if valid_602853 != nil:
    section.add "X-Amz-Security-Token", valid_602853
  var valid_602854 = header.getOrDefault("X-Amz-Algorithm")
  valid_602854 = validateParameter(valid_602854, JString, required = false,
                                 default = nil)
  if valid_602854 != nil:
    section.add "X-Amz-Algorithm", valid_602854
  var valid_602855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602855 = validateParameter(valid_602855, JString, required = false,
                                 default = nil)
  if valid_602855 != nil:
    section.add "X-Amz-SignedHeaders", valid_602855
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  section = newJObject()
  var valid_602856 = formData.getOrDefault("MaxRecords")
  valid_602856 = validateParameter(valid_602856, JInt, required = false, default = nil)
  if valid_602856 != nil:
    section.add "MaxRecords", valid_602856
  var valid_602857 = formData.getOrDefault("DBParameterGroupName")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "DBParameterGroupName", valid_602857
  var valid_602858 = formData.getOrDefault("Marker")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "Marker", valid_602858
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602859: Call_PostDescribeDBParameterGroups_602844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602859.validator(path, query, header, formData, body)
  let scheme = call_602859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602859.url(scheme.get, call_602859.host, call_602859.base,
                         call_602859.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602859, url, valid)

proc call*(call_602860: Call_PostDescribeDBParameterGroups_602844;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602861 = newJObject()
  var formData_602862 = newJObject()
  add(formData_602862, "MaxRecords", newJInt(MaxRecords))
  add(formData_602862, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602862, "Marker", newJString(Marker))
  add(query_602861, "Action", newJString(Action))
  add(query_602861, "Version", newJString(Version))
  result = call_602860.call(nil, query_602861, nil, formData_602862, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_602844(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_602845, base: "/",
    url: url_PostDescribeDBParameterGroups_602846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_602826 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBParameterGroups_602828(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBParameterGroups_602827(path: JsonNode; query: JsonNode;
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
  var valid_602829 = query.getOrDefault("Marker")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "Marker", valid_602829
  var valid_602830 = query.getOrDefault("DBParameterGroupName")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "DBParameterGroupName", valid_602830
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602831 = query.getOrDefault("Action")
  valid_602831 = validateParameter(valid_602831, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_602831 != nil:
    section.add "Action", valid_602831
  var valid_602832 = query.getOrDefault("Version")
  valid_602832 = validateParameter(valid_602832, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602832 != nil:
    section.add "Version", valid_602832
  var valid_602833 = query.getOrDefault("MaxRecords")
  valid_602833 = validateParameter(valid_602833, JInt, required = false, default = nil)
  if valid_602833 != nil:
    section.add "MaxRecords", valid_602833
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
  var valid_602834 = header.getOrDefault("X-Amz-Signature")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Signature", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Content-Sha256", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-Date")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Date", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-Credential")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-Credential", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-Security-Token")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-Security-Token", valid_602838
  var valid_602839 = header.getOrDefault("X-Amz-Algorithm")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "X-Amz-Algorithm", valid_602839
  var valid_602840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "X-Amz-SignedHeaders", valid_602840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602841: Call_GetDescribeDBParameterGroups_602826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602841.validator(path, query, header, formData, body)
  let scheme = call_602841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602841.url(scheme.get, call_602841.host, call_602841.base,
                         call_602841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602841, url, valid)

proc call*(call_602842: Call_GetDescribeDBParameterGroups_602826;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602843 = newJObject()
  add(query_602843, "Marker", newJString(Marker))
  add(query_602843, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602843, "Action", newJString(Action))
  add(query_602843, "Version", newJString(Version))
  add(query_602843, "MaxRecords", newJInt(MaxRecords))
  result = call_602842.call(nil, query_602843, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_602826(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_602827, base: "/",
    url: url_GetDescribeDBParameterGroups_602828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_602882 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBParameters_602884(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameters_602883(path: JsonNode; query: JsonNode;
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
  var valid_602885 = query.getOrDefault("Action")
  valid_602885 = validateParameter(valid_602885, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_602885 != nil:
    section.add "Action", valid_602885
  var valid_602886 = query.getOrDefault("Version")
  valid_602886 = validateParameter(valid_602886, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602886 != nil:
    section.add "Version", valid_602886
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
  var valid_602887 = header.getOrDefault("X-Amz-Signature")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Signature", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Content-Sha256", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Date")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Date", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Credential")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Credential", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Security-Token")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Security-Token", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-Algorithm")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Algorithm", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-SignedHeaders", valid_602893
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  section = newJObject()
  var valid_602894 = formData.getOrDefault("Source")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "Source", valid_602894
  var valid_602895 = formData.getOrDefault("MaxRecords")
  valid_602895 = validateParameter(valid_602895, JInt, required = false, default = nil)
  if valid_602895 != nil:
    section.add "MaxRecords", valid_602895
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602896 = formData.getOrDefault("DBParameterGroupName")
  valid_602896 = validateParameter(valid_602896, JString, required = true,
                                 default = nil)
  if valid_602896 != nil:
    section.add "DBParameterGroupName", valid_602896
  var valid_602897 = formData.getOrDefault("Marker")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "Marker", valid_602897
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602898: Call_PostDescribeDBParameters_602882; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602898.validator(path, query, header, formData, body)
  let scheme = call_602898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602898.url(scheme.get, call_602898.host, call_602898.base,
                         call_602898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602898, url, valid)

proc call*(call_602899: Call_PostDescribeDBParameters_602882;
          DBParameterGroupName: string; Source: string = ""; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBParameters";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameters
  ##   Source: string
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602900 = newJObject()
  var formData_602901 = newJObject()
  add(formData_602901, "Source", newJString(Source))
  add(formData_602901, "MaxRecords", newJInt(MaxRecords))
  add(formData_602901, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602901, "Marker", newJString(Marker))
  add(query_602900, "Action", newJString(Action))
  add(query_602900, "Version", newJString(Version))
  result = call_602899.call(nil, query_602900, nil, formData_602901, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_602882(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_602883, base: "/",
    url: url_PostDescribeDBParameters_602884, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_602863 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBParameters_602865(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBParameters_602864(path: JsonNode; query: JsonNode;
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
  var valid_602866 = query.getOrDefault("Marker")
  valid_602866 = validateParameter(valid_602866, JString, required = false,
                                 default = nil)
  if valid_602866 != nil:
    section.add "Marker", valid_602866
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_602867 = query.getOrDefault("DBParameterGroupName")
  valid_602867 = validateParameter(valid_602867, JString, required = true,
                                 default = nil)
  if valid_602867 != nil:
    section.add "DBParameterGroupName", valid_602867
  var valid_602868 = query.getOrDefault("Source")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "Source", valid_602868
  var valid_602869 = query.getOrDefault("Action")
  valid_602869 = validateParameter(valid_602869, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_602869 != nil:
    section.add "Action", valid_602869
  var valid_602870 = query.getOrDefault("Version")
  valid_602870 = validateParameter(valid_602870, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602870 != nil:
    section.add "Version", valid_602870
  var valid_602871 = query.getOrDefault("MaxRecords")
  valid_602871 = validateParameter(valid_602871, JInt, required = false, default = nil)
  if valid_602871 != nil:
    section.add "MaxRecords", valid_602871
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
  var valid_602872 = header.getOrDefault("X-Amz-Signature")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Signature", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Content-Sha256", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Date")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Date", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Credential")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Credential", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Security-Token")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Security-Token", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Algorithm")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Algorithm", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-SignedHeaders", valid_602878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602879: Call_GetDescribeDBParameters_602863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602879.validator(path, query, header, formData, body)
  let scheme = call_602879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602879.url(scheme.get, call_602879.host, call_602879.base,
                         call_602879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602879, url, valid)

proc call*(call_602880: Call_GetDescribeDBParameters_602863;
          DBParameterGroupName: string; Marker: string = ""; Source: string = "";
          Action: string = "DescribeDBParameters"; Version: string = "2013-02-12";
          MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameters
  ##   Marker: string
  ##   DBParameterGroupName: string (required)
  ##   Source: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602881 = newJObject()
  add(query_602881, "Marker", newJString(Marker))
  add(query_602881, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602881, "Source", newJString(Source))
  add(query_602881, "Action", newJString(Action))
  add(query_602881, "Version", newJString(Version))
  add(query_602881, "MaxRecords", newJInt(MaxRecords))
  result = call_602880.call(nil, query_602881, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_602863(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_602864, base: "/",
    url: url_GetDescribeDBParameters_602865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_602920 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSecurityGroups_602922(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSecurityGroups_602921(path: JsonNode; query: JsonNode;
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
  var valid_602923 = query.getOrDefault("Action")
  valid_602923 = validateParameter(valid_602923, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_602923 != nil:
    section.add "Action", valid_602923
  var valid_602924 = query.getOrDefault("Version")
  valid_602924 = validateParameter(valid_602924, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602924 != nil:
    section.add "Version", valid_602924
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
  var valid_602925 = header.getOrDefault("X-Amz-Signature")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Signature", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Content-Sha256", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-Date")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-Date", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-Credential")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Credential", valid_602928
  var valid_602929 = header.getOrDefault("X-Amz-Security-Token")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-Security-Token", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-Algorithm")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Algorithm", valid_602930
  var valid_602931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-SignedHeaders", valid_602931
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  section = newJObject()
  var valid_602932 = formData.getOrDefault("DBSecurityGroupName")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "DBSecurityGroupName", valid_602932
  var valid_602933 = formData.getOrDefault("MaxRecords")
  valid_602933 = validateParameter(valid_602933, JInt, required = false, default = nil)
  if valid_602933 != nil:
    section.add "MaxRecords", valid_602933
  var valid_602934 = formData.getOrDefault("Marker")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "Marker", valid_602934
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602935: Call_PostDescribeDBSecurityGroups_602920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602935.validator(path, query, header, formData, body)
  let scheme = call_602935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602935.url(scheme.get, call_602935.host, call_602935.base,
                         call_602935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602935, url, valid)

proc call*(call_602936: Call_PostDescribeDBSecurityGroups_602920;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602937 = newJObject()
  var formData_602938 = newJObject()
  add(formData_602938, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_602938, "MaxRecords", newJInt(MaxRecords))
  add(formData_602938, "Marker", newJString(Marker))
  add(query_602937, "Action", newJString(Action))
  add(query_602937, "Version", newJString(Version))
  result = call_602936.call(nil, query_602937, nil, formData_602938, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_602920(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_602921, base: "/",
    url: url_PostDescribeDBSecurityGroups_602922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_602902 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSecurityGroups_602904(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSecurityGroups_602903(path: JsonNode; query: JsonNode;
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
  var valid_602905 = query.getOrDefault("Marker")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "Marker", valid_602905
  var valid_602906 = query.getOrDefault("DBSecurityGroupName")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "DBSecurityGroupName", valid_602906
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602907 = query.getOrDefault("Action")
  valid_602907 = validateParameter(valid_602907, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_602907 != nil:
    section.add "Action", valid_602907
  var valid_602908 = query.getOrDefault("Version")
  valid_602908 = validateParameter(valid_602908, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602908 != nil:
    section.add "Version", valid_602908
  var valid_602909 = query.getOrDefault("MaxRecords")
  valid_602909 = validateParameter(valid_602909, JInt, required = false, default = nil)
  if valid_602909 != nil:
    section.add "MaxRecords", valid_602909
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
  var valid_602910 = header.getOrDefault("X-Amz-Signature")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Signature", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Content-Sha256", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-Date")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Date", valid_602912
  var valid_602913 = header.getOrDefault("X-Amz-Credential")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Credential", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-Security-Token")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-Security-Token", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-Algorithm")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-Algorithm", valid_602915
  var valid_602916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-SignedHeaders", valid_602916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602917: Call_GetDescribeDBSecurityGroups_602902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602917.validator(path, query, header, formData, body)
  let scheme = call_602917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602917.url(scheme.get, call_602917.host, call_602917.base,
                         call_602917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602917, url, valid)

proc call*(call_602918: Call_GetDescribeDBSecurityGroups_602902;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602919 = newJObject()
  add(query_602919, "Marker", newJString(Marker))
  add(query_602919, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602919, "Action", newJString(Action))
  add(query_602919, "Version", newJString(Version))
  add(query_602919, "MaxRecords", newJInt(MaxRecords))
  result = call_602918.call(nil, query_602919, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_602902(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_602903, base: "/",
    url: url_GetDescribeDBSecurityGroups_602904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_602959 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSnapshots_602961(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBSnapshots_602960(path: JsonNode; query: JsonNode;
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
  var valid_602962 = query.getOrDefault("Action")
  valid_602962 = validateParameter(valid_602962, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602962 != nil:
    section.add "Action", valid_602962
  var valid_602963 = query.getOrDefault("Version")
  valid_602963 = validateParameter(valid_602963, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602963 != nil:
    section.add "Version", valid_602963
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
  var valid_602964 = header.getOrDefault("X-Amz-Signature")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "X-Amz-Signature", valid_602964
  var valid_602965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "X-Amz-Content-Sha256", valid_602965
  var valid_602966 = header.getOrDefault("X-Amz-Date")
  valid_602966 = validateParameter(valid_602966, JString, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "X-Amz-Date", valid_602966
  var valid_602967 = header.getOrDefault("X-Amz-Credential")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "X-Amz-Credential", valid_602967
  var valid_602968 = header.getOrDefault("X-Amz-Security-Token")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "X-Amz-Security-Token", valid_602968
  var valid_602969 = header.getOrDefault("X-Amz-Algorithm")
  valid_602969 = validateParameter(valid_602969, JString, required = false,
                                 default = nil)
  if valid_602969 != nil:
    section.add "X-Amz-Algorithm", valid_602969
  var valid_602970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602970 = validateParameter(valid_602970, JString, required = false,
                                 default = nil)
  if valid_602970 != nil:
    section.add "X-Amz-SignedHeaders", valid_602970
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_602971 = formData.getOrDefault("SnapshotType")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "SnapshotType", valid_602971
  var valid_602972 = formData.getOrDefault("MaxRecords")
  valid_602972 = validateParameter(valid_602972, JInt, required = false, default = nil)
  if valid_602972 != nil:
    section.add "MaxRecords", valid_602972
  var valid_602973 = formData.getOrDefault("Marker")
  valid_602973 = validateParameter(valid_602973, JString, required = false,
                                 default = nil)
  if valid_602973 != nil:
    section.add "Marker", valid_602973
  var valid_602974 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "DBInstanceIdentifier", valid_602974
  var valid_602975 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "DBSnapshotIdentifier", valid_602975
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602976: Call_PostDescribeDBSnapshots_602959; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602976.validator(path, query, header, formData, body)
  let scheme = call_602976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602976.url(scheme.get, call_602976.host, call_602976.base,
                         call_602976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602976, url, valid)

proc call*(call_602977: Call_PostDescribeDBSnapshots_602959;
          SnapshotType: string = ""; MaxRecords: int = 0; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSnapshots
  ##   SnapshotType: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602978 = newJObject()
  var formData_602979 = newJObject()
  add(formData_602979, "SnapshotType", newJString(SnapshotType))
  add(formData_602979, "MaxRecords", newJInt(MaxRecords))
  add(formData_602979, "Marker", newJString(Marker))
  add(formData_602979, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602979, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602978, "Action", newJString(Action))
  add(query_602978, "Version", newJString(Version))
  result = call_602977.call(nil, query_602978, nil, formData_602979, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_602959(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_602960, base: "/",
    url: url_PostDescribeDBSnapshots_602961, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_602939 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSnapshots_602941(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBSnapshots_602940(path: JsonNode; query: JsonNode;
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
  var valid_602942 = query.getOrDefault("Marker")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "Marker", valid_602942
  var valid_602943 = query.getOrDefault("DBInstanceIdentifier")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "DBInstanceIdentifier", valid_602943
  var valid_602944 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602944 = validateParameter(valid_602944, JString, required = false,
                                 default = nil)
  if valid_602944 != nil:
    section.add "DBSnapshotIdentifier", valid_602944
  var valid_602945 = query.getOrDefault("SnapshotType")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "SnapshotType", valid_602945
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602946 = query.getOrDefault("Action")
  valid_602946 = validateParameter(valid_602946, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602946 != nil:
    section.add "Action", valid_602946
  var valid_602947 = query.getOrDefault("Version")
  valid_602947 = validateParameter(valid_602947, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602947 != nil:
    section.add "Version", valid_602947
  var valid_602948 = query.getOrDefault("MaxRecords")
  valid_602948 = validateParameter(valid_602948, JInt, required = false, default = nil)
  if valid_602948 != nil:
    section.add "MaxRecords", valid_602948
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
  var valid_602949 = header.getOrDefault("X-Amz-Signature")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-Signature", valid_602949
  var valid_602950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-Content-Sha256", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-Date")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-Date", valid_602951
  var valid_602952 = header.getOrDefault("X-Amz-Credential")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-Credential", valid_602952
  var valid_602953 = header.getOrDefault("X-Amz-Security-Token")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-Security-Token", valid_602953
  var valid_602954 = header.getOrDefault("X-Amz-Algorithm")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "X-Amz-Algorithm", valid_602954
  var valid_602955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "X-Amz-SignedHeaders", valid_602955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602956: Call_GetDescribeDBSnapshots_602939; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602956.validator(path, query, header, formData, body)
  let scheme = call_602956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602956.url(scheme.get, call_602956.host, call_602956.base,
                         call_602956.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602956, url, valid)

proc call*(call_602957: Call_GetDescribeDBSnapshots_602939; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          SnapshotType: string = ""; Action: string = "DescribeDBSnapshots";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSnapshots
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602958 = newJObject()
  add(query_602958, "Marker", newJString(Marker))
  add(query_602958, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602958, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602958, "SnapshotType", newJString(SnapshotType))
  add(query_602958, "Action", newJString(Action))
  add(query_602958, "Version", newJString(Version))
  add(query_602958, "MaxRecords", newJInt(MaxRecords))
  result = call_602957.call(nil, query_602958, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_602939(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_602940, base: "/",
    url: url_GetDescribeDBSnapshots_602941, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_602998 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSubnetGroups_603000(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_602999(path: JsonNode; query: JsonNode;
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
  var valid_603001 = query.getOrDefault("Action")
  valid_603001 = validateParameter(valid_603001, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_603001 != nil:
    section.add "Action", valid_603001
  var valid_603002 = query.getOrDefault("Version")
  valid_603002 = validateParameter(valid_603002, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603002 != nil:
    section.add "Version", valid_603002
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
  var valid_603003 = header.getOrDefault("X-Amz-Signature")
  valid_603003 = validateParameter(valid_603003, JString, required = false,
                                 default = nil)
  if valid_603003 != nil:
    section.add "X-Amz-Signature", valid_603003
  var valid_603004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603004 = validateParameter(valid_603004, JString, required = false,
                                 default = nil)
  if valid_603004 != nil:
    section.add "X-Amz-Content-Sha256", valid_603004
  var valid_603005 = header.getOrDefault("X-Amz-Date")
  valid_603005 = validateParameter(valid_603005, JString, required = false,
                                 default = nil)
  if valid_603005 != nil:
    section.add "X-Amz-Date", valid_603005
  var valid_603006 = header.getOrDefault("X-Amz-Credential")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "X-Amz-Credential", valid_603006
  var valid_603007 = header.getOrDefault("X-Amz-Security-Token")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "X-Amz-Security-Token", valid_603007
  var valid_603008 = header.getOrDefault("X-Amz-Algorithm")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "X-Amz-Algorithm", valid_603008
  var valid_603009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603009 = validateParameter(valid_603009, JString, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "X-Amz-SignedHeaders", valid_603009
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  section = newJObject()
  var valid_603010 = formData.getOrDefault("MaxRecords")
  valid_603010 = validateParameter(valid_603010, JInt, required = false, default = nil)
  if valid_603010 != nil:
    section.add "MaxRecords", valid_603010
  var valid_603011 = formData.getOrDefault("Marker")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "Marker", valid_603011
  var valid_603012 = formData.getOrDefault("DBSubnetGroupName")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "DBSubnetGroupName", valid_603012
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603013: Call_PostDescribeDBSubnetGroups_602998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603013.validator(path, query, header, formData, body)
  let scheme = call_603013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603013.url(scheme.get, call_603013.host, call_603013.base,
                         call_603013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603013, url, valid)

proc call*(call_603014: Call_PostDescribeDBSubnetGroups_602998;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_603015 = newJObject()
  var formData_603016 = newJObject()
  add(formData_603016, "MaxRecords", newJInt(MaxRecords))
  add(formData_603016, "Marker", newJString(Marker))
  add(query_603015, "Action", newJString(Action))
  add(formData_603016, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603015, "Version", newJString(Version))
  result = call_603014.call(nil, query_603015, nil, formData_603016, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_602998(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_602999, base: "/",
    url: url_PostDescribeDBSubnetGroups_603000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_602980 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSubnetGroups_602982(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_602981(path: JsonNode; query: JsonNode;
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
  var valid_602983 = query.getOrDefault("Marker")
  valid_602983 = validateParameter(valid_602983, JString, required = false,
                                 default = nil)
  if valid_602983 != nil:
    section.add "Marker", valid_602983
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602984 = query.getOrDefault("Action")
  valid_602984 = validateParameter(valid_602984, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602984 != nil:
    section.add "Action", valid_602984
  var valid_602985 = query.getOrDefault("DBSubnetGroupName")
  valid_602985 = validateParameter(valid_602985, JString, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "DBSubnetGroupName", valid_602985
  var valid_602986 = query.getOrDefault("Version")
  valid_602986 = validateParameter(valid_602986, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602986 != nil:
    section.add "Version", valid_602986
  var valid_602987 = query.getOrDefault("MaxRecords")
  valid_602987 = validateParameter(valid_602987, JInt, required = false, default = nil)
  if valid_602987 != nil:
    section.add "MaxRecords", valid_602987
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
  var valid_602988 = header.getOrDefault("X-Amz-Signature")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "X-Amz-Signature", valid_602988
  var valid_602989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602989 = validateParameter(valid_602989, JString, required = false,
                                 default = nil)
  if valid_602989 != nil:
    section.add "X-Amz-Content-Sha256", valid_602989
  var valid_602990 = header.getOrDefault("X-Amz-Date")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "X-Amz-Date", valid_602990
  var valid_602991 = header.getOrDefault("X-Amz-Credential")
  valid_602991 = validateParameter(valid_602991, JString, required = false,
                                 default = nil)
  if valid_602991 != nil:
    section.add "X-Amz-Credential", valid_602991
  var valid_602992 = header.getOrDefault("X-Amz-Security-Token")
  valid_602992 = validateParameter(valid_602992, JString, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "X-Amz-Security-Token", valid_602992
  var valid_602993 = header.getOrDefault("X-Amz-Algorithm")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "X-Amz-Algorithm", valid_602993
  var valid_602994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602994 = validateParameter(valid_602994, JString, required = false,
                                 default = nil)
  if valid_602994 != nil:
    section.add "X-Amz-SignedHeaders", valid_602994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602995: Call_GetDescribeDBSubnetGroups_602980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602995.validator(path, query, header, formData, body)
  let scheme = call_602995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602995.url(scheme.get, call_602995.host, call_602995.base,
                         call_602995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602995, url, valid)

proc call*(call_602996: Call_GetDescribeDBSubnetGroups_602980; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_602997 = newJObject()
  add(query_602997, "Marker", newJString(Marker))
  add(query_602997, "Action", newJString(Action))
  add(query_602997, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602997, "Version", newJString(Version))
  add(query_602997, "MaxRecords", newJInt(MaxRecords))
  result = call_602996.call(nil, query_602997, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_602980(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_602981, base: "/",
    url: url_GetDescribeDBSubnetGroups_602982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_603035 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEngineDefaultParameters_603037(protocol: Scheme; host: string;
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

proc validate_PostDescribeEngineDefaultParameters_603036(path: JsonNode;
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
  var valid_603038 = query.getOrDefault("Action")
  valid_603038 = validateParameter(valid_603038, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_603038 != nil:
    section.add "Action", valid_603038
  var valid_603039 = query.getOrDefault("Version")
  valid_603039 = validateParameter(valid_603039, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603039 != nil:
    section.add "Version", valid_603039
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
  var valid_603040 = header.getOrDefault("X-Amz-Signature")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-Signature", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-Content-Sha256", valid_603041
  var valid_603042 = header.getOrDefault("X-Amz-Date")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Date", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Credential")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Credential", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Security-Token")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Security-Token", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Algorithm")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Algorithm", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-SignedHeaders", valid_603046
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_603047 = formData.getOrDefault("MaxRecords")
  valid_603047 = validateParameter(valid_603047, JInt, required = false, default = nil)
  if valid_603047 != nil:
    section.add "MaxRecords", valid_603047
  var valid_603048 = formData.getOrDefault("Marker")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "Marker", valid_603048
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_603049 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603049 = validateParameter(valid_603049, JString, required = true,
                                 default = nil)
  if valid_603049 != nil:
    section.add "DBParameterGroupFamily", valid_603049
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603050: Call_PostDescribeEngineDefaultParameters_603035;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603050.validator(path, query, header, formData, body)
  let scheme = call_603050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603050.url(scheme.get, call_603050.host, call_603050.base,
                         call_603050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603050, url, valid)

proc call*(call_603051: Call_PostDescribeEngineDefaultParameters_603035;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_603052 = newJObject()
  var formData_603053 = newJObject()
  add(formData_603053, "MaxRecords", newJInt(MaxRecords))
  add(formData_603053, "Marker", newJString(Marker))
  add(query_603052, "Action", newJString(Action))
  add(query_603052, "Version", newJString(Version))
  add(formData_603053, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_603051.call(nil, query_603052, nil, formData_603053, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_603035(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_603036, base: "/",
    url: url_PostDescribeEngineDefaultParameters_603037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_603017 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEngineDefaultParameters_603019(protocol: Scheme; host: string;
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

proc validate_GetDescribeEngineDefaultParameters_603018(path: JsonNode;
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
  var valid_603020 = query.getOrDefault("Marker")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "Marker", valid_603020
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_603021 = query.getOrDefault("DBParameterGroupFamily")
  valid_603021 = validateParameter(valid_603021, JString, required = true,
                                 default = nil)
  if valid_603021 != nil:
    section.add "DBParameterGroupFamily", valid_603021
  var valid_603022 = query.getOrDefault("Action")
  valid_603022 = validateParameter(valid_603022, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_603022 != nil:
    section.add "Action", valid_603022
  var valid_603023 = query.getOrDefault("Version")
  valid_603023 = validateParameter(valid_603023, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603023 != nil:
    section.add "Version", valid_603023
  var valid_603024 = query.getOrDefault("MaxRecords")
  valid_603024 = validateParameter(valid_603024, JInt, required = false, default = nil)
  if valid_603024 != nil:
    section.add "MaxRecords", valid_603024
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
  var valid_603025 = header.getOrDefault("X-Amz-Signature")
  valid_603025 = validateParameter(valid_603025, JString, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "X-Amz-Signature", valid_603025
  var valid_603026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-Content-Sha256", valid_603026
  var valid_603027 = header.getOrDefault("X-Amz-Date")
  valid_603027 = validateParameter(valid_603027, JString, required = false,
                                 default = nil)
  if valid_603027 != nil:
    section.add "X-Amz-Date", valid_603027
  var valid_603028 = header.getOrDefault("X-Amz-Credential")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "X-Amz-Credential", valid_603028
  var valid_603029 = header.getOrDefault("X-Amz-Security-Token")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-Security-Token", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-Algorithm")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-Algorithm", valid_603030
  var valid_603031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-SignedHeaders", valid_603031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603032: Call_GetDescribeEngineDefaultParameters_603017;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603032.validator(path, query, header, formData, body)
  let scheme = call_603032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603032.url(scheme.get, call_603032.host, call_603032.base,
                         call_603032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603032, url, valid)

proc call*(call_603033: Call_GetDescribeEngineDefaultParameters_603017;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_603034 = newJObject()
  add(query_603034, "Marker", newJString(Marker))
  add(query_603034, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_603034, "Action", newJString(Action))
  add(query_603034, "Version", newJString(Version))
  add(query_603034, "MaxRecords", newJInt(MaxRecords))
  result = call_603033.call(nil, query_603034, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_603017(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_603018, base: "/",
    url: url_GetDescribeEngineDefaultParameters_603019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_603070 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEventCategories_603072(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_603071(path: JsonNode; query: JsonNode;
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
  var valid_603073 = query.getOrDefault("Action")
  valid_603073 = validateParameter(valid_603073, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_603073 != nil:
    section.add "Action", valid_603073
  var valid_603074 = query.getOrDefault("Version")
  valid_603074 = validateParameter(valid_603074, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603074 != nil:
    section.add "Version", valid_603074
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
  var valid_603075 = header.getOrDefault("X-Amz-Signature")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Signature", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Content-Sha256", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Date")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Date", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Credential")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Credential", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Security-Token")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Security-Token", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Algorithm")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Algorithm", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_603082 = formData.getOrDefault("SourceType")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "SourceType", valid_603082
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603083: Call_PostDescribeEventCategories_603070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603083.validator(path, query, header, formData, body)
  let scheme = call_603083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603083.url(scheme.get, call_603083.host, call_603083.base,
                         call_603083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603083, url, valid)

proc call*(call_603084: Call_PostDescribeEventCategories_603070;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603085 = newJObject()
  var formData_603086 = newJObject()
  add(formData_603086, "SourceType", newJString(SourceType))
  add(query_603085, "Action", newJString(Action))
  add(query_603085, "Version", newJString(Version))
  result = call_603084.call(nil, query_603085, nil, formData_603086, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_603070(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_603071, base: "/",
    url: url_PostDescribeEventCategories_603072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_603054 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEventCategories_603056(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_603055(path: JsonNode; query: JsonNode;
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
  var valid_603057 = query.getOrDefault("SourceType")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "SourceType", valid_603057
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603058 = query.getOrDefault("Action")
  valid_603058 = validateParameter(valid_603058, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_603058 != nil:
    section.add "Action", valid_603058
  var valid_603059 = query.getOrDefault("Version")
  valid_603059 = validateParameter(valid_603059, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603059 != nil:
    section.add "Version", valid_603059
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
  var valid_603060 = header.getOrDefault("X-Amz-Signature")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Signature", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Content-Sha256", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Date")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Date", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Credential")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Credential", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Security-Token")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Security-Token", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Algorithm")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Algorithm", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-SignedHeaders", valid_603066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603067: Call_GetDescribeEventCategories_603054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603067.validator(path, query, header, formData, body)
  let scheme = call_603067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603067.url(scheme.get, call_603067.host, call_603067.base,
                         call_603067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603067, url, valid)

proc call*(call_603068: Call_GetDescribeEventCategories_603054;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603069 = newJObject()
  add(query_603069, "SourceType", newJString(SourceType))
  add(query_603069, "Action", newJString(Action))
  add(query_603069, "Version", newJString(Version))
  result = call_603068.call(nil, query_603069, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_603054(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_603055, base: "/",
    url: url_GetDescribeEventCategories_603056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_603105 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEventSubscriptions_603107(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventSubscriptions_603106(path: JsonNode;
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
  var valid_603108 = query.getOrDefault("Action")
  valid_603108 = validateParameter(valid_603108, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_603108 != nil:
    section.add "Action", valid_603108
  var valid_603109 = query.getOrDefault("Version")
  valid_603109 = validateParameter(valid_603109, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603109 != nil:
    section.add "Version", valid_603109
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
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Content-Sha256", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Date")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Date", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Credential")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Credential", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Security-Token")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Security-Token", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Algorithm")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Algorithm", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-SignedHeaders", valid_603116
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  section = newJObject()
  var valid_603117 = formData.getOrDefault("MaxRecords")
  valid_603117 = validateParameter(valid_603117, JInt, required = false, default = nil)
  if valid_603117 != nil:
    section.add "MaxRecords", valid_603117
  var valid_603118 = formData.getOrDefault("Marker")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "Marker", valid_603118
  var valid_603119 = formData.getOrDefault("SubscriptionName")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "SubscriptionName", valid_603119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603120: Call_PostDescribeEventSubscriptions_603105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603120.validator(path, query, header, formData, body)
  let scheme = call_603120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603120.url(scheme.get, call_603120.host, call_603120.base,
                         call_603120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603120, url, valid)

proc call*(call_603121: Call_PostDescribeEventSubscriptions_603105;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603122 = newJObject()
  var formData_603123 = newJObject()
  add(formData_603123, "MaxRecords", newJInt(MaxRecords))
  add(formData_603123, "Marker", newJString(Marker))
  add(formData_603123, "SubscriptionName", newJString(SubscriptionName))
  add(query_603122, "Action", newJString(Action))
  add(query_603122, "Version", newJString(Version))
  result = call_603121.call(nil, query_603122, nil, formData_603123, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_603105(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_603106, base: "/",
    url: url_PostDescribeEventSubscriptions_603107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_603087 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEventSubscriptions_603089(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventSubscriptions_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = query.getOrDefault("Marker")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "Marker", valid_603090
  var valid_603091 = query.getOrDefault("SubscriptionName")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "SubscriptionName", valid_603091
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603092 = query.getOrDefault("Action")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_603092 != nil:
    section.add "Action", valid_603092
  var valid_603093 = query.getOrDefault("Version")
  valid_603093 = validateParameter(valid_603093, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603093 != nil:
    section.add "Version", valid_603093
  var valid_603094 = query.getOrDefault("MaxRecords")
  valid_603094 = validateParameter(valid_603094, JInt, required = false, default = nil)
  if valid_603094 != nil:
    section.add "MaxRecords", valid_603094
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
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Content-Sha256", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Date")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Date", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Credential")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Credential", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Security-Token")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Security-Token", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Algorithm")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Algorithm", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-SignedHeaders", valid_603101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603102: Call_GetDescribeEventSubscriptions_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603102.validator(path, query, header, formData, body)
  let scheme = call_603102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603102.url(scheme.get, call_603102.host, call_603102.base,
                         call_603102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603102, url, valid)

proc call*(call_603103: Call_GetDescribeEventSubscriptions_603087;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_603104 = newJObject()
  add(query_603104, "Marker", newJString(Marker))
  add(query_603104, "SubscriptionName", newJString(SubscriptionName))
  add(query_603104, "Action", newJString(Action))
  add(query_603104, "Version", newJString(Version))
  add(query_603104, "MaxRecords", newJInt(MaxRecords))
  result = call_603103.call(nil, query_603104, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_603087(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_603088, base: "/",
    url: url_GetDescribeEventSubscriptions_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_603147 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEvents_603149(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_603148(path: JsonNode; query: JsonNode;
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
  var valid_603150 = query.getOrDefault("Action")
  valid_603150 = validateParameter(valid_603150, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_603150 != nil:
    section.add "Action", valid_603150
  var valid_603151 = query.getOrDefault("Version")
  valid_603151 = validateParameter(valid_603151, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   SourceIdentifier: JString
  ##   SourceType: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   StartTime: JString
  ##   EventCategories: JArray
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
  var valid_603161 = formData.getOrDefault("SourceIdentifier")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "SourceIdentifier", valid_603161
  var valid_603162 = formData.getOrDefault("SourceType")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_603162 != nil:
    section.add "SourceType", valid_603162
  var valid_603163 = formData.getOrDefault("Duration")
  valid_603163 = validateParameter(valid_603163, JInt, required = false, default = nil)
  if valid_603163 != nil:
    section.add "Duration", valid_603163
  var valid_603164 = formData.getOrDefault("EndTime")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "EndTime", valid_603164
  var valid_603165 = formData.getOrDefault("StartTime")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "StartTime", valid_603165
  var valid_603166 = formData.getOrDefault("EventCategories")
  valid_603166 = validateParameter(valid_603166, JArray, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "EventCategories", valid_603166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603167: Call_PostDescribeEvents_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603167.validator(path, query, header, formData, body)
  let scheme = call_603167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603167.url(scheme.get, call_603167.host, call_603167.base,
                         call_603167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603167, url, valid)

proc call*(call_603168: Call_PostDescribeEvents_603147; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Version: string = "2013-02-12"): Recallable =
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
  var query_603169 = newJObject()
  var formData_603170 = newJObject()
  add(formData_603170, "MaxRecords", newJInt(MaxRecords))
  add(formData_603170, "Marker", newJString(Marker))
  add(formData_603170, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_603170, "SourceType", newJString(SourceType))
  add(formData_603170, "Duration", newJInt(Duration))
  add(formData_603170, "EndTime", newJString(EndTime))
  add(formData_603170, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_603170.add "EventCategories", EventCategories
  add(query_603169, "Action", newJString(Action))
  add(query_603169, "Version", newJString(Version))
  result = call_603168.call(nil, query_603169, nil, formData_603170, nil)

var postDescribeEvents* = Call_PostDescribeEvents_603147(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_603148, base: "/",
    url: url_PostDescribeEvents_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_603124 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEvents_603126(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_603125(path: JsonNode; query: JsonNode;
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
  var valid_603127 = query.getOrDefault("Marker")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "Marker", valid_603127
  var valid_603128 = query.getOrDefault("SourceType")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_603128 != nil:
    section.add "SourceType", valid_603128
  var valid_603129 = query.getOrDefault("SourceIdentifier")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "SourceIdentifier", valid_603129
  var valid_603130 = query.getOrDefault("EventCategories")
  valid_603130 = validateParameter(valid_603130, JArray, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "EventCategories", valid_603130
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603131 = query.getOrDefault("Action")
  valid_603131 = validateParameter(valid_603131, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_603131 != nil:
    section.add "Action", valid_603131
  var valid_603132 = query.getOrDefault("StartTime")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "StartTime", valid_603132
  var valid_603133 = query.getOrDefault("Duration")
  valid_603133 = validateParameter(valid_603133, JInt, required = false, default = nil)
  if valid_603133 != nil:
    section.add "Duration", valid_603133
  var valid_603134 = query.getOrDefault("EndTime")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "EndTime", valid_603134
  var valid_603135 = query.getOrDefault("Version")
  valid_603135 = validateParameter(valid_603135, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603135 != nil:
    section.add "Version", valid_603135
  var valid_603136 = query.getOrDefault("MaxRecords")
  valid_603136 = validateParameter(valid_603136, JInt, required = false, default = nil)
  if valid_603136 != nil:
    section.add "MaxRecords", valid_603136
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

proc call*(call_603144: Call_GetDescribeEvents_603124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603144, url, valid)

proc call*(call_603145: Call_GetDescribeEvents_603124; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
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
  var query_603146 = newJObject()
  add(query_603146, "Marker", newJString(Marker))
  add(query_603146, "SourceType", newJString(SourceType))
  add(query_603146, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_603146.add "EventCategories", EventCategories
  add(query_603146, "Action", newJString(Action))
  add(query_603146, "StartTime", newJString(StartTime))
  add(query_603146, "Duration", newJInt(Duration))
  add(query_603146, "EndTime", newJString(EndTime))
  add(query_603146, "Version", newJString(Version))
  add(query_603146, "MaxRecords", newJInt(MaxRecords))
  result = call_603145.call(nil, query_603146, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_603124(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_603125,
    base: "/", url: url_GetDescribeEvents_603126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_603190 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOptionGroupOptions_603192(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroupOptions_603191(path: JsonNode;
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
  var valid_603193 = query.getOrDefault("Action")
  valid_603193 = validateParameter(valid_603193, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_603193 != nil:
    section.add "Action", valid_603193
  var valid_603194 = query.getOrDefault("Version")
  valid_603194 = validateParameter(valid_603194, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603194 != nil:
    section.add "Version", valid_603194
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
  var valid_603195 = header.getOrDefault("X-Amz-Signature")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Signature", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Content-Sha256", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Date")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Date", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Credential")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Credential", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Security-Token")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Security-Token", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Algorithm")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Algorithm", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_603202 = formData.getOrDefault("MaxRecords")
  valid_603202 = validateParameter(valid_603202, JInt, required = false, default = nil)
  if valid_603202 != nil:
    section.add "MaxRecords", valid_603202
  var valid_603203 = formData.getOrDefault("Marker")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "Marker", valid_603203
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_603204 = formData.getOrDefault("EngineName")
  valid_603204 = validateParameter(valid_603204, JString, required = true,
                                 default = nil)
  if valid_603204 != nil:
    section.add "EngineName", valid_603204
  var valid_603205 = formData.getOrDefault("MajorEngineVersion")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "MajorEngineVersion", valid_603205
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603206: Call_PostDescribeOptionGroupOptions_603190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603206.validator(path, query, header, formData, body)
  let scheme = call_603206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603206.url(scheme.get, call_603206.host, call_603206.base,
                         call_603206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603206, url, valid)

proc call*(call_603207: Call_PostDescribeOptionGroupOptions_603190;
          EngineName: string; MaxRecords: int = 0; Marker: string = "";
          MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603208 = newJObject()
  var formData_603209 = newJObject()
  add(formData_603209, "MaxRecords", newJInt(MaxRecords))
  add(formData_603209, "Marker", newJString(Marker))
  add(formData_603209, "EngineName", newJString(EngineName))
  add(formData_603209, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_603208, "Action", newJString(Action))
  add(query_603208, "Version", newJString(Version))
  result = call_603207.call(nil, query_603208, nil, formData_603209, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_603190(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_603191, base: "/",
    url: url_PostDescribeOptionGroupOptions_603192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_603171 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOptionGroupOptions_603173(protocol: Scheme; host: string;
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

proc validate_GetDescribeOptionGroupOptions_603172(path: JsonNode; query: JsonNode;
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
  var valid_603174 = query.getOrDefault("EngineName")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = nil)
  if valid_603174 != nil:
    section.add "EngineName", valid_603174
  var valid_603175 = query.getOrDefault("Marker")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "Marker", valid_603175
  var valid_603176 = query.getOrDefault("Action")
  valid_603176 = validateParameter(valid_603176, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_603176 != nil:
    section.add "Action", valid_603176
  var valid_603177 = query.getOrDefault("Version")
  valid_603177 = validateParameter(valid_603177, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603177 != nil:
    section.add "Version", valid_603177
  var valid_603178 = query.getOrDefault("MaxRecords")
  valid_603178 = validateParameter(valid_603178, JInt, required = false, default = nil)
  if valid_603178 != nil:
    section.add "MaxRecords", valid_603178
  var valid_603179 = query.getOrDefault("MajorEngineVersion")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "MajorEngineVersion", valid_603179
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
  var valid_603180 = header.getOrDefault("X-Amz-Signature")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Signature", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Content-Sha256", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Date")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Date", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Credential")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Credential", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Security-Token")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Security-Token", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Algorithm")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Algorithm", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603187: Call_GetDescribeOptionGroupOptions_603171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603187.validator(path, query, header, formData, body)
  let scheme = call_603187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603187.url(scheme.get, call_603187.host, call_603187.base,
                         call_603187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603187, url, valid)

proc call*(call_603188: Call_GetDescribeOptionGroupOptions_603171;
          EngineName: string; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-02-12"; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   EngineName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_603189 = newJObject()
  add(query_603189, "EngineName", newJString(EngineName))
  add(query_603189, "Marker", newJString(Marker))
  add(query_603189, "Action", newJString(Action))
  add(query_603189, "Version", newJString(Version))
  add(query_603189, "MaxRecords", newJInt(MaxRecords))
  add(query_603189, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603188.call(nil, query_603189, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_603171(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_603172, base: "/",
    url: url_GetDescribeOptionGroupOptions_603173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_603230 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOptionGroups_603232(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroups_603231(path: JsonNode; query: JsonNode;
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
  var valid_603233 = query.getOrDefault("Action")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_603233 != nil:
    section.add "Action", valid_603233
  var valid_603234 = query.getOrDefault("Version")
  valid_603234 = validateParameter(valid_603234, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_603242 = formData.getOrDefault("MaxRecords")
  valid_603242 = validateParameter(valid_603242, JInt, required = false, default = nil)
  if valid_603242 != nil:
    section.add "MaxRecords", valid_603242
  var valid_603243 = formData.getOrDefault("Marker")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "Marker", valid_603243
  var valid_603244 = formData.getOrDefault("EngineName")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "EngineName", valid_603244
  var valid_603245 = formData.getOrDefault("MajorEngineVersion")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "MajorEngineVersion", valid_603245
  var valid_603246 = formData.getOrDefault("OptionGroupName")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "OptionGroupName", valid_603246
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603247: Call_PostDescribeOptionGroups_603230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603247.validator(path, query, header, formData, body)
  let scheme = call_603247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603247.url(scheme.get, call_603247.host, call_603247.base,
                         call_603247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603247, url, valid)

proc call*(call_603248: Call_PostDescribeOptionGroups_603230; MaxRecords: int = 0;
          Marker: string = ""; EngineName: string = ""; MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeOptionGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_603249 = newJObject()
  var formData_603250 = newJObject()
  add(formData_603250, "MaxRecords", newJInt(MaxRecords))
  add(formData_603250, "Marker", newJString(Marker))
  add(formData_603250, "EngineName", newJString(EngineName))
  add(formData_603250, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_603249, "Action", newJString(Action))
  add(formData_603250, "OptionGroupName", newJString(OptionGroupName))
  add(query_603249, "Version", newJString(Version))
  result = call_603248.call(nil, query_603249, nil, formData_603250, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_603230(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_603231, base: "/",
    url: url_PostDescribeOptionGroups_603232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_603210 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOptionGroups_603212(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeOptionGroups_603211(path: JsonNode; query: JsonNode;
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
  var valid_603213 = query.getOrDefault("EngineName")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "EngineName", valid_603213
  var valid_603214 = query.getOrDefault("Marker")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "Marker", valid_603214
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603215 = query.getOrDefault("Action")
  valid_603215 = validateParameter(valid_603215, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_603215 != nil:
    section.add "Action", valid_603215
  var valid_603216 = query.getOrDefault("OptionGroupName")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "OptionGroupName", valid_603216
  var valid_603217 = query.getOrDefault("Version")
  valid_603217 = validateParameter(valid_603217, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603217 != nil:
    section.add "Version", valid_603217
  var valid_603218 = query.getOrDefault("MaxRecords")
  valid_603218 = validateParameter(valid_603218, JInt, required = false, default = nil)
  if valid_603218 != nil:
    section.add "MaxRecords", valid_603218
  var valid_603219 = query.getOrDefault("MajorEngineVersion")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "MajorEngineVersion", valid_603219
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

proc call*(call_603227: Call_GetDescribeOptionGroups_603210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603227.validator(path, query, header, formData, body)
  let scheme = call_603227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603227.url(scheme.get, call_603227.host, call_603227.base,
                         call_603227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603227, url, valid)

proc call*(call_603228: Call_GetDescribeOptionGroups_603210;
          EngineName: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-02-12"; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   EngineName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_603229 = newJObject()
  add(query_603229, "EngineName", newJString(EngineName))
  add(query_603229, "Marker", newJString(Marker))
  add(query_603229, "Action", newJString(Action))
  add(query_603229, "OptionGroupName", newJString(OptionGroupName))
  add(query_603229, "Version", newJString(Version))
  add(query_603229, "MaxRecords", newJInt(MaxRecords))
  add(query_603229, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603228.call(nil, query_603229, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_603210(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_603211, base: "/",
    url: url_GetDescribeOptionGroups_603212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_603273 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOrderableDBInstanceOptions_603275(protocol: Scheme;
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

proc validate_PostDescribeOrderableDBInstanceOptions_603274(path: JsonNode;
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
  var valid_603276 = query.getOrDefault("Action")
  valid_603276 = validateParameter(valid_603276, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_603276 != nil:
    section.add "Action", valid_603276
  var valid_603277 = query.getOrDefault("Version")
  valid_603277 = validateParameter(valid_603277, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603277 != nil:
    section.add "Version", valid_603277
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
  var valid_603278 = header.getOrDefault("X-Amz-Signature")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Signature", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Content-Sha256", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Date")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Date", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Credential")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Credential", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Security-Token")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Security-Token", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Algorithm")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Algorithm", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-SignedHeaders", valid_603284
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
  var valid_603285 = formData.getOrDefault("DBInstanceClass")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "DBInstanceClass", valid_603285
  var valid_603286 = formData.getOrDefault("MaxRecords")
  valid_603286 = validateParameter(valid_603286, JInt, required = false, default = nil)
  if valid_603286 != nil:
    section.add "MaxRecords", valid_603286
  var valid_603287 = formData.getOrDefault("EngineVersion")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "EngineVersion", valid_603287
  var valid_603288 = formData.getOrDefault("Marker")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "Marker", valid_603288
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603289 = formData.getOrDefault("Engine")
  valid_603289 = validateParameter(valid_603289, JString, required = true,
                                 default = nil)
  if valid_603289 != nil:
    section.add "Engine", valid_603289
  var valid_603290 = formData.getOrDefault("Vpc")
  valid_603290 = validateParameter(valid_603290, JBool, required = false, default = nil)
  if valid_603290 != nil:
    section.add "Vpc", valid_603290
  var valid_603291 = formData.getOrDefault("LicenseModel")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "LicenseModel", valid_603291
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603292: Call_PostDescribeOrderableDBInstanceOptions_603273;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603292.validator(path, query, header, formData, body)
  let scheme = call_603292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603292.url(scheme.get, call_603292.host, call_603292.base,
                         call_603292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603292, url, valid)

proc call*(call_603293: Call_PostDescribeOrderableDBInstanceOptions_603273;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Version: string = "2013-02-12"): Recallable =
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
  var query_603294 = newJObject()
  var formData_603295 = newJObject()
  add(formData_603295, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603295, "MaxRecords", newJInt(MaxRecords))
  add(formData_603295, "EngineVersion", newJString(EngineVersion))
  add(formData_603295, "Marker", newJString(Marker))
  add(formData_603295, "Engine", newJString(Engine))
  add(formData_603295, "Vpc", newJBool(Vpc))
  add(query_603294, "Action", newJString(Action))
  add(formData_603295, "LicenseModel", newJString(LicenseModel))
  add(query_603294, "Version", newJString(Version))
  result = call_603293.call(nil, query_603294, nil, formData_603295, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_603273(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_603274, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_603275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_603251 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOrderableDBInstanceOptions_603253(protocol: Scheme;
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

proc validate_GetDescribeOrderableDBInstanceOptions_603252(path: JsonNode;
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
  var valid_603254 = query.getOrDefault("Marker")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "Marker", valid_603254
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_603255 = query.getOrDefault("Engine")
  valid_603255 = validateParameter(valid_603255, JString, required = true,
                                 default = nil)
  if valid_603255 != nil:
    section.add "Engine", valid_603255
  var valid_603256 = query.getOrDefault("LicenseModel")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "LicenseModel", valid_603256
  var valid_603257 = query.getOrDefault("Vpc")
  valid_603257 = validateParameter(valid_603257, JBool, required = false, default = nil)
  if valid_603257 != nil:
    section.add "Vpc", valid_603257
  var valid_603258 = query.getOrDefault("EngineVersion")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "EngineVersion", valid_603258
  var valid_603259 = query.getOrDefault("Action")
  valid_603259 = validateParameter(valid_603259, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_603259 != nil:
    section.add "Action", valid_603259
  var valid_603260 = query.getOrDefault("Version")
  valid_603260 = validateParameter(valid_603260, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603260 != nil:
    section.add "Version", valid_603260
  var valid_603261 = query.getOrDefault("DBInstanceClass")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "DBInstanceClass", valid_603261
  var valid_603262 = query.getOrDefault("MaxRecords")
  valid_603262 = validateParameter(valid_603262, JInt, required = false, default = nil)
  if valid_603262 != nil:
    section.add "MaxRecords", valid_603262
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
  var valid_603263 = header.getOrDefault("X-Amz-Signature")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Signature", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Content-Sha256", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Date")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Date", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Credential")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Credential", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Security-Token")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Security-Token", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Algorithm")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Algorithm", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-SignedHeaders", valid_603269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603270: Call_GetDescribeOrderableDBInstanceOptions_603251;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603270.validator(path, query, header, formData, body)
  let scheme = call_603270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603270.url(scheme.get, call_603270.host, call_603270.base,
                         call_603270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603270, url, valid)

proc call*(call_603271: Call_GetDescribeOrderableDBInstanceOptions_603251;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2013-02-12"; DBInstanceClass: string = "";
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
  var query_603272 = newJObject()
  add(query_603272, "Marker", newJString(Marker))
  add(query_603272, "Engine", newJString(Engine))
  add(query_603272, "LicenseModel", newJString(LicenseModel))
  add(query_603272, "Vpc", newJBool(Vpc))
  add(query_603272, "EngineVersion", newJString(EngineVersion))
  add(query_603272, "Action", newJString(Action))
  add(query_603272, "Version", newJString(Version))
  add(query_603272, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603272, "MaxRecords", newJInt(MaxRecords))
  result = call_603271.call(nil, query_603272, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_603251(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_603252, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_603253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_603320 = ref object of OpenApiRestCall_601373
proc url_PostDescribeReservedDBInstances_603322(protocol: Scheme; host: string;
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

proc validate_PostDescribeReservedDBInstances_603321(path: JsonNode;
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
  var valid_603323 = query.getOrDefault("Action")
  valid_603323 = validateParameter(valid_603323, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_603323 != nil:
    section.add "Action", valid_603323
  var valid_603324 = query.getOrDefault("Version")
  valid_603324 = validateParameter(valid_603324, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603324 != nil:
    section.add "Version", valid_603324
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
  var valid_603325 = header.getOrDefault("X-Amz-Signature")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Signature", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Content-Sha256", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Date")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Date", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Credential")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Credential", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Security-Token")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Security-Token", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Algorithm")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Algorithm", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-SignedHeaders", valid_603331
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
  var valid_603332 = formData.getOrDefault("DBInstanceClass")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "DBInstanceClass", valid_603332
  var valid_603333 = formData.getOrDefault("MultiAZ")
  valid_603333 = validateParameter(valid_603333, JBool, required = false, default = nil)
  if valid_603333 != nil:
    section.add "MultiAZ", valid_603333
  var valid_603334 = formData.getOrDefault("MaxRecords")
  valid_603334 = validateParameter(valid_603334, JInt, required = false, default = nil)
  if valid_603334 != nil:
    section.add "MaxRecords", valid_603334
  var valid_603335 = formData.getOrDefault("ReservedDBInstanceId")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "ReservedDBInstanceId", valid_603335
  var valid_603336 = formData.getOrDefault("Marker")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "Marker", valid_603336
  var valid_603337 = formData.getOrDefault("Duration")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "Duration", valid_603337
  var valid_603338 = formData.getOrDefault("OfferingType")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "OfferingType", valid_603338
  var valid_603339 = formData.getOrDefault("ProductDescription")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "ProductDescription", valid_603339
  var valid_603340 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603340
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603341: Call_PostDescribeReservedDBInstances_603320;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603341.validator(path, query, header, formData, body)
  let scheme = call_603341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603341.url(scheme.get, call_603341.host, call_603341.base,
                         call_603341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603341, url, valid)

proc call*(call_603342: Call_PostDescribeReservedDBInstances_603320;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          ReservedDBInstanceId: string = ""; Marker: string = ""; Duration: string = "";
          OfferingType: string = ""; ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstances";
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-02-12"): Recallable =
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
  var query_603343 = newJObject()
  var formData_603344 = newJObject()
  add(formData_603344, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603344, "MultiAZ", newJBool(MultiAZ))
  add(formData_603344, "MaxRecords", newJInt(MaxRecords))
  add(formData_603344, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_603344, "Marker", newJString(Marker))
  add(formData_603344, "Duration", newJString(Duration))
  add(formData_603344, "OfferingType", newJString(OfferingType))
  add(formData_603344, "ProductDescription", newJString(ProductDescription))
  add(query_603343, "Action", newJString(Action))
  add(formData_603344, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603343, "Version", newJString(Version))
  result = call_603342.call(nil, query_603343, nil, formData_603344, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_603320(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_603321, base: "/",
    url: url_PostDescribeReservedDBInstances_603322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_603296 = ref object of OpenApiRestCall_601373
proc url_GetDescribeReservedDBInstances_603298(protocol: Scheme; host: string;
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

proc validate_GetDescribeReservedDBInstances_603297(path: JsonNode;
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
  var valid_603299 = query.getOrDefault("Marker")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "Marker", valid_603299
  var valid_603300 = query.getOrDefault("ProductDescription")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "ProductDescription", valid_603300
  var valid_603301 = query.getOrDefault("OfferingType")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "OfferingType", valid_603301
  var valid_603302 = query.getOrDefault("ReservedDBInstanceId")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "ReservedDBInstanceId", valid_603302
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603303 = query.getOrDefault("Action")
  valid_603303 = validateParameter(valid_603303, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_603303 != nil:
    section.add "Action", valid_603303
  var valid_603304 = query.getOrDefault("MultiAZ")
  valid_603304 = validateParameter(valid_603304, JBool, required = false, default = nil)
  if valid_603304 != nil:
    section.add "MultiAZ", valid_603304
  var valid_603305 = query.getOrDefault("Duration")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "Duration", valid_603305
  var valid_603306 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603306
  var valid_603307 = query.getOrDefault("Version")
  valid_603307 = validateParameter(valid_603307, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603307 != nil:
    section.add "Version", valid_603307
  var valid_603308 = query.getOrDefault("DBInstanceClass")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "DBInstanceClass", valid_603308
  var valid_603309 = query.getOrDefault("MaxRecords")
  valid_603309 = validateParameter(valid_603309, JInt, required = false, default = nil)
  if valid_603309 != nil:
    section.add "MaxRecords", valid_603309
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
  var valid_603310 = header.getOrDefault("X-Amz-Signature")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Signature", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Content-Sha256", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Date")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Date", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Credential")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Credential", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Security-Token")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Security-Token", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Algorithm")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Algorithm", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-SignedHeaders", valid_603316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603317: Call_GetDescribeReservedDBInstances_603296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603317.validator(path, query, header, formData, body)
  let scheme = call_603317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603317.url(scheme.get, call_603317.host, call_603317.base,
                         call_603317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603317, url, valid)

proc call*(call_603318: Call_GetDescribeReservedDBInstances_603296;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Action: string = "DescribeReservedDBInstances"; MultiAZ: bool = false;
          Duration: string = ""; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-02-12"; DBInstanceClass: string = "";
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
  var query_603319 = newJObject()
  add(query_603319, "Marker", newJString(Marker))
  add(query_603319, "ProductDescription", newJString(ProductDescription))
  add(query_603319, "OfferingType", newJString(OfferingType))
  add(query_603319, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603319, "Action", newJString(Action))
  add(query_603319, "MultiAZ", newJBool(MultiAZ))
  add(query_603319, "Duration", newJString(Duration))
  add(query_603319, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603319, "Version", newJString(Version))
  add(query_603319, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603319, "MaxRecords", newJInt(MaxRecords))
  result = call_603318.call(nil, query_603319, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_603296(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_603297, base: "/",
    url: url_GetDescribeReservedDBInstances_603298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_603368 = ref object of OpenApiRestCall_601373
proc url_PostDescribeReservedDBInstancesOfferings_603370(protocol: Scheme;
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

proc validate_PostDescribeReservedDBInstancesOfferings_603369(path: JsonNode;
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
  var valid_603371 = query.getOrDefault("Action")
  valid_603371 = validateParameter(valid_603371, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_603371 != nil:
    section.add "Action", valid_603371
  var valid_603372 = query.getOrDefault("Version")
  valid_603372 = validateParameter(valid_603372, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603372 != nil:
    section.add "Version", valid_603372
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
  var valid_603373 = header.getOrDefault("X-Amz-Signature")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Signature", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Content-Sha256", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Credential")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Credential", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Security-Token")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Security-Token", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Algorithm")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Algorithm", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-SignedHeaders", valid_603379
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
  var valid_603380 = formData.getOrDefault("DBInstanceClass")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "DBInstanceClass", valid_603380
  var valid_603381 = formData.getOrDefault("MultiAZ")
  valid_603381 = validateParameter(valid_603381, JBool, required = false, default = nil)
  if valid_603381 != nil:
    section.add "MultiAZ", valid_603381
  var valid_603382 = formData.getOrDefault("MaxRecords")
  valid_603382 = validateParameter(valid_603382, JInt, required = false, default = nil)
  if valid_603382 != nil:
    section.add "MaxRecords", valid_603382
  var valid_603383 = formData.getOrDefault("Marker")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "Marker", valid_603383
  var valid_603384 = formData.getOrDefault("Duration")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "Duration", valid_603384
  var valid_603385 = formData.getOrDefault("OfferingType")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "OfferingType", valid_603385
  var valid_603386 = formData.getOrDefault("ProductDescription")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "ProductDescription", valid_603386
  var valid_603387 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603387
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603388: Call_PostDescribeReservedDBInstancesOfferings_603368;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603388.validator(path, query, header, formData, body)
  let scheme = call_603388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603388.url(scheme.get, call_603388.host, call_603388.base,
                         call_603388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603388, url, valid)

proc call*(call_603389: Call_PostDescribeReservedDBInstancesOfferings_603368;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          Marker: string = ""; Duration: string = ""; OfferingType: string = "";
          ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-02-12"): Recallable =
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
  var query_603390 = newJObject()
  var formData_603391 = newJObject()
  add(formData_603391, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603391, "MultiAZ", newJBool(MultiAZ))
  add(formData_603391, "MaxRecords", newJInt(MaxRecords))
  add(formData_603391, "Marker", newJString(Marker))
  add(formData_603391, "Duration", newJString(Duration))
  add(formData_603391, "OfferingType", newJString(OfferingType))
  add(formData_603391, "ProductDescription", newJString(ProductDescription))
  add(query_603390, "Action", newJString(Action))
  add(formData_603391, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603390, "Version", newJString(Version))
  result = call_603389.call(nil, query_603390, nil, formData_603391, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_603368(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_603369,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_603370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_603345 = ref object of OpenApiRestCall_601373
proc url_GetDescribeReservedDBInstancesOfferings_603347(protocol: Scheme;
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

proc validate_GetDescribeReservedDBInstancesOfferings_603346(path: JsonNode;
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
  var valid_603348 = query.getOrDefault("Marker")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "Marker", valid_603348
  var valid_603349 = query.getOrDefault("ProductDescription")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "ProductDescription", valid_603349
  var valid_603350 = query.getOrDefault("OfferingType")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "OfferingType", valid_603350
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603351 = query.getOrDefault("Action")
  valid_603351 = validateParameter(valid_603351, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_603351 != nil:
    section.add "Action", valid_603351
  var valid_603352 = query.getOrDefault("MultiAZ")
  valid_603352 = validateParameter(valid_603352, JBool, required = false, default = nil)
  if valid_603352 != nil:
    section.add "MultiAZ", valid_603352
  var valid_603353 = query.getOrDefault("Duration")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "Duration", valid_603353
  var valid_603354 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603354
  var valid_603355 = query.getOrDefault("Version")
  valid_603355 = validateParameter(valid_603355, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603355 != nil:
    section.add "Version", valid_603355
  var valid_603356 = query.getOrDefault("DBInstanceClass")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "DBInstanceClass", valid_603356
  var valid_603357 = query.getOrDefault("MaxRecords")
  valid_603357 = validateParameter(valid_603357, JInt, required = false, default = nil)
  if valid_603357 != nil:
    section.add "MaxRecords", valid_603357
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
  var valid_603358 = header.getOrDefault("X-Amz-Signature")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Signature", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Content-Sha256", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Credential")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Credential", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Security-Token")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Security-Token", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Algorithm")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Algorithm", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-SignedHeaders", valid_603364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603365: Call_GetDescribeReservedDBInstancesOfferings_603345;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603365.validator(path, query, header, formData, body)
  let scheme = call_603365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603365.url(scheme.get, call_603365.host, call_603365.base,
                         call_603365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603365, url, valid)

proc call*(call_603366: Call_GetDescribeReservedDBInstancesOfferings_603345;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          MultiAZ: bool = false; Duration: string = "";
          ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-02-12"; DBInstanceClass: string = "";
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
  var query_603367 = newJObject()
  add(query_603367, "Marker", newJString(Marker))
  add(query_603367, "ProductDescription", newJString(ProductDescription))
  add(query_603367, "OfferingType", newJString(OfferingType))
  add(query_603367, "Action", newJString(Action))
  add(query_603367, "MultiAZ", newJBool(MultiAZ))
  add(query_603367, "Duration", newJString(Duration))
  add(query_603367, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603367, "Version", newJString(Version))
  add(query_603367, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603367, "MaxRecords", newJInt(MaxRecords))
  result = call_603366.call(nil, query_603367, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_603345(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_603346, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_603347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_603411 = ref object of OpenApiRestCall_601373
proc url_PostDownloadDBLogFilePortion_603413(protocol: Scheme; host: string;
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

proc validate_PostDownloadDBLogFilePortion_603412(path: JsonNode; query: JsonNode;
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
  var valid_603414 = query.getOrDefault("Action")
  valid_603414 = validateParameter(valid_603414, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_603414 != nil:
    section.add "Action", valid_603414
  var valid_603415 = query.getOrDefault("Version")
  valid_603415 = validateParameter(valid_603415, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603415 != nil:
    section.add "Version", valid_603415
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
  var valid_603416 = header.getOrDefault("X-Amz-Signature")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Signature", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Content-Sha256", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Date")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Date", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Credential")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Credential", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-Security-Token")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Security-Token", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Algorithm")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Algorithm", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-SignedHeaders", valid_603422
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603423 = formData.getOrDefault("NumberOfLines")
  valid_603423 = validateParameter(valid_603423, JInt, required = false, default = nil)
  if valid_603423 != nil:
    section.add "NumberOfLines", valid_603423
  var valid_603424 = formData.getOrDefault("Marker")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "Marker", valid_603424
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_603425 = formData.getOrDefault("LogFileName")
  valid_603425 = validateParameter(valid_603425, JString, required = true,
                                 default = nil)
  if valid_603425 != nil:
    section.add "LogFileName", valid_603425
  var valid_603426 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603426 = validateParameter(valid_603426, JString, required = true,
                                 default = nil)
  if valid_603426 != nil:
    section.add "DBInstanceIdentifier", valid_603426
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603427: Call_PostDownloadDBLogFilePortion_603411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603427.validator(path, query, header, formData, body)
  let scheme = call_603427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603427.url(scheme.get, call_603427.host, call_603427.base,
                         call_603427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603427, url, valid)

proc call*(call_603428: Call_PostDownloadDBLogFilePortion_603411;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-02-12"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   Marker: string
  ##   LogFileName: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603429 = newJObject()
  var formData_603430 = newJObject()
  add(formData_603430, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_603430, "Marker", newJString(Marker))
  add(formData_603430, "LogFileName", newJString(LogFileName))
  add(formData_603430, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603429, "Action", newJString(Action))
  add(query_603429, "Version", newJString(Version))
  result = call_603428.call(nil, query_603429, nil, formData_603430, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_603411(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_603412, base: "/",
    url: url_PostDownloadDBLogFilePortion_603413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_603392 = ref object of OpenApiRestCall_601373
proc url_GetDownloadDBLogFilePortion_603394(protocol: Scheme; host: string;
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

proc validate_GetDownloadDBLogFilePortion_603393(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   LogFileName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603395 = query.getOrDefault("Marker")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "Marker", valid_603395
  var valid_603396 = query.getOrDefault("NumberOfLines")
  valid_603396 = validateParameter(valid_603396, JInt, required = false, default = nil)
  if valid_603396 != nil:
    section.add "NumberOfLines", valid_603396
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603397 = query.getOrDefault("DBInstanceIdentifier")
  valid_603397 = validateParameter(valid_603397, JString, required = true,
                                 default = nil)
  if valid_603397 != nil:
    section.add "DBInstanceIdentifier", valid_603397
  var valid_603398 = query.getOrDefault("Action")
  valid_603398 = validateParameter(valid_603398, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_603398 != nil:
    section.add "Action", valid_603398
  var valid_603399 = query.getOrDefault("LogFileName")
  valid_603399 = validateParameter(valid_603399, JString, required = true,
                                 default = nil)
  if valid_603399 != nil:
    section.add "LogFileName", valid_603399
  var valid_603400 = query.getOrDefault("Version")
  valid_603400 = validateParameter(valid_603400, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603400 != nil:
    section.add "Version", valid_603400
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
  var valid_603401 = header.getOrDefault("X-Amz-Signature")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Signature", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Content-Sha256", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Date")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Date", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Credential")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Credential", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Security-Token")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Security-Token", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Algorithm")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Algorithm", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-SignedHeaders", valid_603407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603408: Call_GetDownloadDBLogFilePortion_603392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603408.validator(path, query, header, formData, body)
  let scheme = call_603408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603408.url(scheme.get, call_603408.host, call_603408.base,
                         call_603408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603408, url, valid)

proc call*(call_603409: Call_GetDownloadDBLogFilePortion_603392;
          DBInstanceIdentifier: string; LogFileName: string; Marker: string = "";
          NumberOfLines: int = 0; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-02-12"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   Marker: string
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_603410 = newJObject()
  add(query_603410, "Marker", newJString(Marker))
  add(query_603410, "NumberOfLines", newJInt(NumberOfLines))
  add(query_603410, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603410, "Action", newJString(Action))
  add(query_603410, "LogFileName", newJString(LogFileName))
  add(query_603410, "Version", newJString(Version))
  result = call_603409.call(nil, query_603410, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_603392(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_603393, base: "/",
    url: url_GetDownloadDBLogFilePortion_603394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_603447 = ref object of OpenApiRestCall_601373
proc url_PostListTagsForResource_603449(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_603448(path: JsonNode; query: JsonNode;
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
  var valid_603450 = query.getOrDefault("Action")
  valid_603450 = validateParameter(valid_603450, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603450 != nil:
    section.add "Action", valid_603450
  var valid_603451 = query.getOrDefault("Version")
  valid_603451 = validateParameter(valid_603451, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603451 != nil:
    section.add "Version", valid_603451
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
  var valid_603452 = header.getOrDefault("X-Amz-Signature")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Signature", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Content-Sha256", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Date")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Date", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Credential")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Credential", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Security-Token")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Security-Token", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Algorithm")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Algorithm", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-SignedHeaders", valid_603458
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_603459 = formData.getOrDefault("ResourceName")
  valid_603459 = validateParameter(valid_603459, JString, required = true,
                                 default = nil)
  if valid_603459 != nil:
    section.add "ResourceName", valid_603459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603460: Call_PostListTagsForResource_603447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603460.validator(path, query, header, formData, body)
  let scheme = call_603460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603460.url(scheme.get, call_603460.host, call_603460.base,
                         call_603460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603460, url, valid)

proc call*(call_603461: Call_PostListTagsForResource_603447; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_603462 = newJObject()
  var formData_603463 = newJObject()
  add(query_603462, "Action", newJString(Action))
  add(query_603462, "Version", newJString(Version))
  add(formData_603463, "ResourceName", newJString(ResourceName))
  result = call_603461.call(nil, query_603462, nil, formData_603463, nil)

var postListTagsForResource* = Call_PostListTagsForResource_603447(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_603448, base: "/",
    url: url_PostListTagsForResource_603449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_603431 = ref object of OpenApiRestCall_601373
proc url_GetListTagsForResource_603433(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_603432(path: JsonNode; query: JsonNode;
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
  var valid_603434 = query.getOrDefault("ResourceName")
  valid_603434 = validateParameter(valid_603434, JString, required = true,
                                 default = nil)
  if valid_603434 != nil:
    section.add "ResourceName", valid_603434
  var valid_603435 = query.getOrDefault("Action")
  valid_603435 = validateParameter(valid_603435, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603435 != nil:
    section.add "Action", valid_603435
  var valid_603436 = query.getOrDefault("Version")
  valid_603436 = validateParameter(valid_603436, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603436 != nil:
    section.add "Version", valid_603436
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
  var valid_603437 = header.getOrDefault("X-Amz-Signature")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Signature", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Content-Sha256", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Date")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Date", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Credential")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Credential", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Security-Token")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Security-Token", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Algorithm")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Algorithm", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-SignedHeaders", valid_603443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603444: Call_GetListTagsForResource_603431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603444.validator(path, query, header, formData, body)
  let scheme = call_603444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603444.url(scheme.get, call_603444.host, call_603444.base,
                         call_603444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603444, url, valid)

proc call*(call_603445: Call_GetListTagsForResource_603431; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603446 = newJObject()
  add(query_603446, "ResourceName", newJString(ResourceName))
  add(query_603446, "Action", newJString(Action))
  add(query_603446, "Version", newJString(Version))
  result = call_603445.call(nil, query_603446, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_603431(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_603432, base: "/",
    url: url_GetListTagsForResource_603433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_603497 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBInstance_603499(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_603498(path: JsonNode; query: JsonNode;
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
  var valid_603500 = query.getOrDefault("Action")
  valid_603500 = validateParameter(valid_603500, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_603500 != nil:
    section.add "Action", valid_603500
  var valid_603501 = query.getOrDefault("Version")
  valid_603501 = validateParameter(valid_603501, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603501 != nil:
    section.add "Version", valid_603501
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
  var valid_603502 = header.getOrDefault("X-Amz-Signature")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Signature", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Content-Sha256", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Date")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Date", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Credential")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Credential", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Security-Token")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Security-Token", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Algorithm")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Algorithm", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-SignedHeaders", valid_603508
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
  var valid_603509 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "PreferredMaintenanceWindow", valid_603509
  var valid_603510 = formData.getOrDefault("DBInstanceClass")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "DBInstanceClass", valid_603510
  var valid_603511 = formData.getOrDefault("PreferredBackupWindow")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "PreferredBackupWindow", valid_603511
  var valid_603512 = formData.getOrDefault("MasterUserPassword")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "MasterUserPassword", valid_603512
  var valid_603513 = formData.getOrDefault("MultiAZ")
  valid_603513 = validateParameter(valid_603513, JBool, required = false, default = nil)
  if valid_603513 != nil:
    section.add "MultiAZ", valid_603513
  var valid_603514 = formData.getOrDefault("DBParameterGroupName")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "DBParameterGroupName", valid_603514
  var valid_603515 = formData.getOrDefault("EngineVersion")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "EngineVersion", valid_603515
  var valid_603516 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603516 = validateParameter(valid_603516, JArray, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "VpcSecurityGroupIds", valid_603516
  var valid_603517 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603517 = validateParameter(valid_603517, JInt, required = false, default = nil)
  if valid_603517 != nil:
    section.add "BackupRetentionPeriod", valid_603517
  var valid_603518 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603518 = validateParameter(valid_603518, JBool, required = false, default = nil)
  if valid_603518 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603518
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603519 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603519 = validateParameter(valid_603519, JString, required = true,
                                 default = nil)
  if valid_603519 != nil:
    section.add "DBInstanceIdentifier", valid_603519
  var valid_603520 = formData.getOrDefault("ApplyImmediately")
  valid_603520 = validateParameter(valid_603520, JBool, required = false, default = nil)
  if valid_603520 != nil:
    section.add "ApplyImmediately", valid_603520
  var valid_603521 = formData.getOrDefault("Iops")
  valid_603521 = validateParameter(valid_603521, JInt, required = false, default = nil)
  if valid_603521 != nil:
    section.add "Iops", valid_603521
  var valid_603522 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_603522 = validateParameter(valid_603522, JBool, required = false, default = nil)
  if valid_603522 != nil:
    section.add "AllowMajorVersionUpgrade", valid_603522
  var valid_603523 = formData.getOrDefault("OptionGroupName")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "OptionGroupName", valid_603523
  var valid_603524 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "NewDBInstanceIdentifier", valid_603524
  var valid_603525 = formData.getOrDefault("DBSecurityGroups")
  valid_603525 = validateParameter(valid_603525, JArray, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "DBSecurityGroups", valid_603525
  var valid_603526 = formData.getOrDefault("AllocatedStorage")
  valid_603526 = validateParameter(valid_603526, JInt, required = false, default = nil)
  if valid_603526 != nil:
    section.add "AllocatedStorage", valid_603526
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603527: Call_PostModifyDBInstance_603497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603527.validator(path, query, header, formData, body)
  let scheme = call_603527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603527.url(scheme.get, call_603527.host, call_603527.base,
                         call_603527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603527, url, valid)

proc call*(call_603528: Call_PostModifyDBInstance_603497;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          MasterUserPassword: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          AutoMinorVersionUpgrade: bool = false; ApplyImmediately: bool = false;
          Iops: int = 0; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false; OptionGroupName: string = "";
          NewDBInstanceIdentifier: string = ""; Version: string = "2013-02-12";
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
  var query_603529 = newJObject()
  var formData_603530 = newJObject()
  add(formData_603530, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_603530, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603530, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603530, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603530, "MultiAZ", newJBool(MultiAZ))
  add(formData_603530, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603530, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_603530.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603530, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603530, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603530, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603530, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_603530, "Iops", newJInt(Iops))
  add(query_603529, "Action", newJString(Action))
  add(formData_603530, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_603530, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603530, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_603529, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_603530.add "DBSecurityGroups", DBSecurityGroups
  add(formData_603530, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_603528.call(nil, query_603529, nil, formData_603530, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_603497(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_603498, base: "/",
    url: url_PostModifyDBInstance_603499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_603464 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBInstance_603466(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_603465(path: JsonNode; query: JsonNode;
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
  var valid_603467 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "NewDBInstanceIdentifier", valid_603467
  var valid_603468 = query.getOrDefault("DBParameterGroupName")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "DBParameterGroupName", valid_603468
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603469 = query.getOrDefault("DBInstanceIdentifier")
  valid_603469 = validateParameter(valid_603469, JString, required = true,
                                 default = nil)
  if valid_603469 != nil:
    section.add "DBInstanceIdentifier", valid_603469
  var valid_603470 = query.getOrDefault("BackupRetentionPeriod")
  valid_603470 = validateParameter(valid_603470, JInt, required = false, default = nil)
  if valid_603470 != nil:
    section.add "BackupRetentionPeriod", valid_603470
  var valid_603471 = query.getOrDefault("EngineVersion")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "EngineVersion", valid_603471
  var valid_603472 = query.getOrDefault("Action")
  valid_603472 = validateParameter(valid_603472, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_603472 != nil:
    section.add "Action", valid_603472
  var valid_603473 = query.getOrDefault("MultiAZ")
  valid_603473 = validateParameter(valid_603473, JBool, required = false, default = nil)
  if valid_603473 != nil:
    section.add "MultiAZ", valid_603473
  var valid_603474 = query.getOrDefault("DBSecurityGroups")
  valid_603474 = validateParameter(valid_603474, JArray, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "DBSecurityGroups", valid_603474
  var valid_603475 = query.getOrDefault("ApplyImmediately")
  valid_603475 = validateParameter(valid_603475, JBool, required = false, default = nil)
  if valid_603475 != nil:
    section.add "ApplyImmediately", valid_603475
  var valid_603476 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603476 = validateParameter(valid_603476, JArray, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "VpcSecurityGroupIds", valid_603476
  var valid_603477 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_603477 = validateParameter(valid_603477, JBool, required = false, default = nil)
  if valid_603477 != nil:
    section.add "AllowMajorVersionUpgrade", valid_603477
  var valid_603478 = query.getOrDefault("MasterUserPassword")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "MasterUserPassword", valid_603478
  var valid_603479 = query.getOrDefault("OptionGroupName")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "OptionGroupName", valid_603479
  var valid_603480 = query.getOrDefault("Version")
  valid_603480 = validateParameter(valid_603480, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603480 != nil:
    section.add "Version", valid_603480
  var valid_603481 = query.getOrDefault("AllocatedStorage")
  valid_603481 = validateParameter(valid_603481, JInt, required = false, default = nil)
  if valid_603481 != nil:
    section.add "AllocatedStorage", valid_603481
  var valid_603482 = query.getOrDefault("DBInstanceClass")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "DBInstanceClass", valid_603482
  var valid_603483 = query.getOrDefault("PreferredBackupWindow")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "PreferredBackupWindow", valid_603483
  var valid_603484 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "PreferredMaintenanceWindow", valid_603484
  var valid_603485 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603485 = validateParameter(valid_603485, JBool, required = false, default = nil)
  if valid_603485 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603485
  var valid_603486 = query.getOrDefault("Iops")
  valid_603486 = validateParameter(valid_603486, JInt, required = false, default = nil)
  if valid_603486 != nil:
    section.add "Iops", valid_603486
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
  var valid_603487 = header.getOrDefault("X-Amz-Signature")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Signature", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Content-Sha256", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Date")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Date", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Credential")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Credential", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Security-Token")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Security-Token", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Algorithm")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Algorithm", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-SignedHeaders", valid_603493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603494: Call_GetModifyDBInstance_603464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603494.validator(path, query, header, formData, body)
  let scheme = call_603494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603494.url(scheme.get, call_603494.host, call_603494.base,
                         call_603494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603494, url, valid)

proc call*(call_603495: Call_GetModifyDBInstance_603464;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          DBParameterGroupName: string = ""; BackupRetentionPeriod: int = 0;
          EngineVersion: string = ""; Action: string = "ModifyDBInstance";
          MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil;
          ApplyImmediately: bool = false; VpcSecurityGroupIds: JsonNode = nil;
          AllowMajorVersionUpgrade: bool = false; MasterUserPassword: string = "";
          OptionGroupName: string = ""; Version: string = "2013-02-12";
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
  var query_603496 = newJObject()
  add(query_603496, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_603496, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603496, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603496, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603496, "EngineVersion", newJString(EngineVersion))
  add(query_603496, "Action", newJString(Action))
  add(query_603496, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_603496.add "DBSecurityGroups", DBSecurityGroups
  add(query_603496, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_603496.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603496, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_603496, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_603496, "OptionGroupName", newJString(OptionGroupName))
  add(query_603496, "Version", newJString(Version))
  add(query_603496, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_603496, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603496, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603496, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603496, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603496, "Iops", newJInt(Iops))
  result = call_603495.call(nil, query_603496, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_603464(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_603465, base: "/",
    url: url_GetModifyDBInstance_603466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_603548 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBParameterGroup_603550(protocol: Scheme; host: string;
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

proc validate_PostModifyDBParameterGroup_603549(path: JsonNode; query: JsonNode;
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
  var valid_603551 = query.getOrDefault("Action")
  valid_603551 = validateParameter(valid_603551, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_603551 != nil:
    section.add "Action", valid_603551
  var valid_603552 = query.getOrDefault("Version")
  valid_603552 = validateParameter(valid_603552, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603552 != nil:
    section.add "Version", valid_603552
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
  var valid_603553 = header.getOrDefault("X-Amz-Signature")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Signature", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Content-Sha256", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Date")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Date", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Credential")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Credential", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Security-Token")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Security-Token", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Algorithm")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Algorithm", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-SignedHeaders", valid_603559
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603560 = formData.getOrDefault("DBParameterGroupName")
  valid_603560 = validateParameter(valid_603560, JString, required = true,
                                 default = nil)
  if valid_603560 != nil:
    section.add "DBParameterGroupName", valid_603560
  var valid_603561 = formData.getOrDefault("Parameters")
  valid_603561 = validateParameter(valid_603561, JArray, required = true, default = nil)
  if valid_603561 != nil:
    section.add "Parameters", valid_603561
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603562: Call_PostModifyDBParameterGroup_603548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603562.validator(path, query, header, formData, body)
  let scheme = call_603562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603562.url(scheme.get, call_603562.host, call_603562.base,
                         call_603562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603562, url, valid)

proc call*(call_603563: Call_PostModifyDBParameterGroup_603548;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_603564 = newJObject()
  var formData_603565 = newJObject()
  add(formData_603565, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603564, "Action", newJString(Action))
  if Parameters != nil:
    formData_603565.add "Parameters", Parameters
  add(query_603564, "Version", newJString(Version))
  result = call_603563.call(nil, query_603564, nil, formData_603565, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_603548(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_603549, base: "/",
    url: url_PostModifyDBParameterGroup_603550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_603531 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBParameterGroup_603533(protocol: Scheme; host: string;
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

proc validate_GetModifyDBParameterGroup_603532(path: JsonNode; query: JsonNode;
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
  var valid_603534 = query.getOrDefault("DBParameterGroupName")
  valid_603534 = validateParameter(valid_603534, JString, required = true,
                                 default = nil)
  if valid_603534 != nil:
    section.add "DBParameterGroupName", valid_603534
  var valid_603535 = query.getOrDefault("Parameters")
  valid_603535 = validateParameter(valid_603535, JArray, required = true, default = nil)
  if valid_603535 != nil:
    section.add "Parameters", valid_603535
  var valid_603536 = query.getOrDefault("Action")
  valid_603536 = validateParameter(valid_603536, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_603536 != nil:
    section.add "Action", valid_603536
  var valid_603537 = query.getOrDefault("Version")
  valid_603537 = validateParameter(valid_603537, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603537 != nil:
    section.add "Version", valid_603537
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
  var valid_603538 = header.getOrDefault("X-Amz-Signature")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Signature", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Content-Sha256", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Date")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Date", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Credential")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Credential", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Security-Token")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Security-Token", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Algorithm")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Algorithm", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-SignedHeaders", valid_603544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603545: Call_GetModifyDBParameterGroup_603531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603545.validator(path, query, header, formData, body)
  let scheme = call_603545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603545.url(scheme.get, call_603545.host, call_603545.base,
                         call_603545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603545, url, valid)

proc call*(call_603546: Call_GetModifyDBParameterGroup_603531;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603547 = newJObject()
  add(query_603547, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_603547.add "Parameters", Parameters
  add(query_603547, "Action", newJString(Action))
  add(query_603547, "Version", newJString(Version))
  result = call_603546.call(nil, query_603547, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_603531(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_603532, base: "/",
    url: url_GetModifyDBParameterGroup_603533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_603584 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBSubnetGroup_603586(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_603585(path: JsonNode; query: JsonNode;
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
  var valid_603587 = query.getOrDefault("Action")
  valid_603587 = validateParameter(valid_603587, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_603587 != nil:
    section.add "Action", valid_603587
  var valid_603588 = query.getOrDefault("Version")
  valid_603588 = validateParameter(valid_603588, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603588 != nil:
    section.add "Version", valid_603588
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
  var valid_603589 = header.getOrDefault("X-Amz-Signature")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Signature", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Content-Sha256", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Date")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Date", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Credential")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Credential", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Security-Token")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Security-Token", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Algorithm")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Algorithm", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-SignedHeaders", valid_603595
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_603596 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "DBSubnetGroupDescription", valid_603596
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603597 = formData.getOrDefault("DBSubnetGroupName")
  valid_603597 = validateParameter(valid_603597, JString, required = true,
                                 default = nil)
  if valid_603597 != nil:
    section.add "DBSubnetGroupName", valid_603597
  var valid_603598 = formData.getOrDefault("SubnetIds")
  valid_603598 = validateParameter(valid_603598, JArray, required = true, default = nil)
  if valid_603598 != nil:
    section.add "SubnetIds", valid_603598
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603599: Call_PostModifyDBSubnetGroup_603584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603599.validator(path, query, header, formData, body)
  let scheme = call_603599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603599.url(scheme.get, call_603599.host, call_603599.base,
                         call_603599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603599, url, valid)

proc call*(call_603600: Call_PostModifyDBSubnetGroup_603584;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_603601 = newJObject()
  var formData_603602 = newJObject()
  add(formData_603602, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603601, "Action", newJString(Action))
  add(formData_603602, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603601, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_603602.add "SubnetIds", SubnetIds
  result = call_603600.call(nil, query_603601, nil, formData_603602, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_603584(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_603585, base: "/",
    url: url_PostModifyDBSubnetGroup_603586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_603566 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBSubnetGroup_603568(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_603567(path: JsonNode; query: JsonNode;
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
  var valid_603569 = query.getOrDefault("SubnetIds")
  valid_603569 = validateParameter(valid_603569, JArray, required = true, default = nil)
  if valid_603569 != nil:
    section.add "SubnetIds", valid_603569
  var valid_603570 = query.getOrDefault("Action")
  valid_603570 = validateParameter(valid_603570, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_603570 != nil:
    section.add "Action", valid_603570
  var valid_603571 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "DBSubnetGroupDescription", valid_603571
  var valid_603572 = query.getOrDefault("DBSubnetGroupName")
  valid_603572 = validateParameter(valid_603572, JString, required = true,
                                 default = nil)
  if valid_603572 != nil:
    section.add "DBSubnetGroupName", valid_603572
  var valid_603573 = query.getOrDefault("Version")
  valid_603573 = validateParameter(valid_603573, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603573 != nil:
    section.add "Version", valid_603573
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
  var valid_603574 = header.getOrDefault("X-Amz-Signature")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Signature", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Content-Sha256", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Date")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Date", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Credential")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Credential", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Security-Token")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Security-Token", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Algorithm")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Algorithm", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-SignedHeaders", valid_603580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603581: Call_GetModifyDBSubnetGroup_603566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603581.validator(path, query, header, formData, body)
  let scheme = call_603581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603581.url(scheme.get, call_603581.host, call_603581.base,
                         call_603581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603581, url, valid)

proc call*(call_603582: Call_GetModifyDBSubnetGroup_603566; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_603583 = newJObject()
  if SubnetIds != nil:
    query_603583.add "SubnetIds", SubnetIds
  add(query_603583, "Action", newJString(Action))
  add(query_603583, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603583, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603583, "Version", newJString(Version))
  result = call_603582.call(nil, query_603583, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_603566(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_603567, base: "/",
    url: url_GetModifyDBSubnetGroup_603568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_603623 = ref object of OpenApiRestCall_601373
proc url_PostModifyEventSubscription_603625(protocol: Scheme; host: string;
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

proc validate_PostModifyEventSubscription_603624(path: JsonNode; query: JsonNode;
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
  var valid_603626 = query.getOrDefault("Action")
  valid_603626 = validateParameter(valid_603626, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_603626 != nil:
    section.add "Action", valid_603626
  var valid_603627 = query.getOrDefault("Version")
  valid_603627 = validateParameter(valid_603627, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603627 != nil:
    section.add "Version", valid_603627
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
  var valid_603628 = header.getOrDefault("X-Amz-Signature")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Signature", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Content-Sha256", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-Date")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Date", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Credential")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Credential", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Security-Token")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Security-Token", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Algorithm")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Algorithm", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-SignedHeaders", valid_603634
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_603635 = formData.getOrDefault("SnsTopicArn")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "SnsTopicArn", valid_603635
  var valid_603636 = formData.getOrDefault("Enabled")
  valid_603636 = validateParameter(valid_603636, JBool, required = false, default = nil)
  if valid_603636 != nil:
    section.add "Enabled", valid_603636
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603637 = formData.getOrDefault("SubscriptionName")
  valid_603637 = validateParameter(valid_603637, JString, required = true,
                                 default = nil)
  if valid_603637 != nil:
    section.add "SubscriptionName", valid_603637
  var valid_603638 = formData.getOrDefault("SourceType")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "SourceType", valid_603638
  var valid_603639 = formData.getOrDefault("EventCategories")
  valid_603639 = validateParameter(valid_603639, JArray, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "EventCategories", valid_603639
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603640: Call_PostModifyEventSubscription_603623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603640.validator(path, query, header, formData, body)
  let scheme = call_603640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603640.url(scheme.get, call_603640.host, call_603640.base,
                         call_603640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603640, url, valid)

proc call*(call_603641: Call_PostModifyEventSubscription_603623;
          SubscriptionName: string; SnsTopicArn: string = ""; Enabled: bool = false;
          SourceType: string = ""; EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; Version: string = "2013-02-12"): Recallable =
  ## postModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603642 = newJObject()
  var formData_603643 = newJObject()
  add(formData_603643, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_603643, "Enabled", newJBool(Enabled))
  add(formData_603643, "SubscriptionName", newJString(SubscriptionName))
  add(formData_603643, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_603643.add "EventCategories", EventCategories
  add(query_603642, "Action", newJString(Action))
  add(query_603642, "Version", newJString(Version))
  result = call_603641.call(nil, query_603642, nil, formData_603643, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_603623(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_603624, base: "/",
    url: url_PostModifyEventSubscription_603625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_603603 = ref object of OpenApiRestCall_601373
proc url_GetModifyEventSubscription_603605(protocol: Scheme; host: string;
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

proc validate_GetModifyEventSubscription_603604(path: JsonNode; query: JsonNode;
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
  var valid_603606 = query.getOrDefault("SourceType")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "SourceType", valid_603606
  var valid_603607 = query.getOrDefault("Enabled")
  valid_603607 = validateParameter(valid_603607, JBool, required = false, default = nil)
  if valid_603607 != nil:
    section.add "Enabled", valid_603607
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_603608 = query.getOrDefault("SubscriptionName")
  valid_603608 = validateParameter(valid_603608, JString, required = true,
                                 default = nil)
  if valid_603608 != nil:
    section.add "SubscriptionName", valid_603608
  var valid_603609 = query.getOrDefault("EventCategories")
  valid_603609 = validateParameter(valid_603609, JArray, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "EventCategories", valid_603609
  var valid_603610 = query.getOrDefault("Action")
  valid_603610 = validateParameter(valid_603610, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_603610 != nil:
    section.add "Action", valid_603610
  var valid_603611 = query.getOrDefault("SnsTopicArn")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "SnsTopicArn", valid_603611
  var valid_603612 = query.getOrDefault("Version")
  valid_603612 = validateParameter(valid_603612, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603612 != nil:
    section.add "Version", valid_603612
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
  var valid_603613 = header.getOrDefault("X-Amz-Signature")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Signature", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Content-Sha256", valid_603614
  var valid_603615 = header.getOrDefault("X-Amz-Date")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Date", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Credential")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Credential", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Security-Token")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Security-Token", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Algorithm")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Algorithm", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-SignedHeaders", valid_603619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603620: Call_GetModifyEventSubscription_603603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603620.validator(path, query, header, formData, body)
  let scheme = call_603620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603620.url(scheme.get, call_603620.host, call_603620.base,
                         call_603620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603620, url, valid)

proc call*(call_603621: Call_GetModifyEventSubscription_603603;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   Version: string (required)
  var query_603622 = newJObject()
  add(query_603622, "SourceType", newJString(SourceType))
  add(query_603622, "Enabled", newJBool(Enabled))
  add(query_603622, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_603622.add "EventCategories", EventCategories
  add(query_603622, "Action", newJString(Action))
  add(query_603622, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_603622, "Version", newJString(Version))
  result = call_603621.call(nil, query_603622, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_603603(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_603604, base: "/",
    url: url_GetModifyEventSubscription_603605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_603663 = ref object of OpenApiRestCall_601373
proc url_PostModifyOptionGroup_603665(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyOptionGroup_603664(path: JsonNode; query: JsonNode;
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
  var valid_603666 = query.getOrDefault("Action")
  valid_603666 = validateParameter(valid_603666, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_603666 != nil:
    section.add "Action", valid_603666
  var valid_603667 = query.getOrDefault("Version")
  valid_603667 = validateParameter(valid_603667, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603667 != nil:
    section.add "Version", valid_603667
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
  var valid_603668 = header.getOrDefault("X-Amz-Signature")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Signature", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Content-Sha256", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Date")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Date", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Credential")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Credential", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Security-Token")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Security-Token", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Algorithm")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Algorithm", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-SignedHeaders", valid_603674
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_603675 = formData.getOrDefault("OptionsToRemove")
  valid_603675 = validateParameter(valid_603675, JArray, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "OptionsToRemove", valid_603675
  var valid_603676 = formData.getOrDefault("ApplyImmediately")
  valid_603676 = validateParameter(valid_603676, JBool, required = false, default = nil)
  if valid_603676 != nil:
    section.add "ApplyImmediately", valid_603676
  var valid_603677 = formData.getOrDefault("OptionsToInclude")
  valid_603677 = validateParameter(valid_603677, JArray, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "OptionsToInclude", valid_603677
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_603678 = formData.getOrDefault("OptionGroupName")
  valid_603678 = validateParameter(valid_603678, JString, required = true,
                                 default = nil)
  if valid_603678 != nil:
    section.add "OptionGroupName", valid_603678
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603679: Call_PostModifyOptionGroup_603663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603679.validator(path, query, header, formData, body)
  let scheme = call_603679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603679.url(scheme.get, call_603679.host, call_603679.base,
                         call_603679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603679, url, valid)

proc call*(call_603680: Call_PostModifyOptionGroup_603663; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_603681 = newJObject()
  var formData_603682 = newJObject()
  if OptionsToRemove != nil:
    formData_603682.add "OptionsToRemove", OptionsToRemove
  add(formData_603682, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_603682.add "OptionsToInclude", OptionsToInclude
  add(query_603681, "Action", newJString(Action))
  add(formData_603682, "OptionGroupName", newJString(OptionGroupName))
  add(query_603681, "Version", newJString(Version))
  result = call_603680.call(nil, query_603681, nil, formData_603682, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_603663(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_603664, base: "/",
    url: url_PostModifyOptionGroup_603665, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_603644 = ref object of OpenApiRestCall_601373
proc url_GetModifyOptionGroup_603646(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyOptionGroup_603645(path: JsonNode; query: JsonNode;
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
  var valid_603647 = query.getOrDefault("Action")
  valid_603647 = validateParameter(valid_603647, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_603647 != nil:
    section.add "Action", valid_603647
  var valid_603648 = query.getOrDefault("ApplyImmediately")
  valid_603648 = validateParameter(valid_603648, JBool, required = false, default = nil)
  if valid_603648 != nil:
    section.add "ApplyImmediately", valid_603648
  var valid_603649 = query.getOrDefault("OptionsToRemove")
  valid_603649 = validateParameter(valid_603649, JArray, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "OptionsToRemove", valid_603649
  var valid_603650 = query.getOrDefault("OptionsToInclude")
  valid_603650 = validateParameter(valid_603650, JArray, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "OptionsToInclude", valid_603650
  var valid_603651 = query.getOrDefault("OptionGroupName")
  valid_603651 = validateParameter(valid_603651, JString, required = true,
                                 default = nil)
  if valid_603651 != nil:
    section.add "OptionGroupName", valid_603651
  var valid_603652 = query.getOrDefault("Version")
  valid_603652 = validateParameter(valid_603652, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603652 != nil:
    section.add "Version", valid_603652
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
  var valid_603653 = header.getOrDefault("X-Amz-Signature")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Signature", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Content-Sha256", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Date")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Date", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Credential")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Credential", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Security-Token")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Security-Token", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Algorithm")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Algorithm", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-SignedHeaders", valid_603659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603660: Call_GetModifyOptionGroup_603644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603660.validator(path, query, header, formData, body)
  let scheme = call_603660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603660.url(scheme.get, call_603660.host, call_603660.base,
                         call_603660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603660, url, valid)

proc call*(call_603661: Call_GetModifyOptionGroup_603644; OptionGroupName: string;
          Action: string = "ModifyOptionGroup"; ApplyImmediately: bool = false;
          OptionsToRemove: JsonNode = nil; OptionsToInclude: JsonNode = nil;
          Version: string = "2013-02-12"): Recallable =
  ## getModifyOptionGroup
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_603662 = newJObject()
  add(query_603662, "Action", newJString(Action))
  add(query_603662, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_603662.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_603662.add "OptionsToInclude", OptionsToInclude
  add(query_603662, "OptionGroupName", newJString(OptionGroupName))
  add(query_603662, "Version", newJString(Version))
  result = call_603661.call(nil, query_603662, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_603644(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_603645, base: "/",
    url: url_GetModifyOptionGroup_603646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_603701 = ref object of OpenApiRestCall_601373
proc url_PostPromoteReadReplica_603703(protocol: Scheme; host: string; base: string;
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

proc validate_PostPromoteReadReplica_603702(path: JsonNode; query: JsonNode;
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
  var valid_603704 = query.getOrDefault("Action")
  valid_603704 = validateParameter(valid_603704, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_603704 != nil:
    section.add "Action", valid_603704
  var valid_603705 = query.getOrDefault("Version")
  valid_603705 = validateParameter(valid_603705, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603705 != nil:
    section.add "Version", valid_603705
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
  var valid_603706 = header.getOrDefault("X-Amz-Signature")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Signature", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Content-Sha256", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Date")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Date", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Credential")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Credential", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Security-Token")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Security-Token", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-Algorithm")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-Algorithm", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-SignedHeaders", valid_603712
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603713 = formData.getOrDefault("PreferredBackupWindow")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "PreferredBackupWindow", valid_603713
  var valid_603714 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603714 = validateParameter(valid_603714, JInt, required = false, default = nil)
  if valid_603714 != nil:
    section.add "BackupRetentionPeriod", valid_603714
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603715 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603715 = validateParameter(valid_603715, JString, required = true,
                                 default = nil)
  if valid_603715 != nil:
    section.add "DBInstanceIdentifier", valid_603715
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603716: Call_PostPromoteReadReplica_603701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603716.validator(path, query, header, formData, body)
  let scheme = call_603716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603716.url(scheme.get, call_603716.host, call_603716.base,
                         call_603716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603716, url, valid)

proc call*(call_603717: Call_PostPromoteReadReplica_603701;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-02-12"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603718 = newJObject()
  var formData_603719 = newJObject()
  add(formData_603719, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603719, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603719, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603718, "Action", newJString(Action))
  add(query_603718, "Version", newJString(Version))
  result = call_603717.call(nil, query_603718, nil, formData_603719, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_603701(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_603702, base: "/",
    url: url_PostPromoteReadReplica_603703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_603683 = ref object of OpenApiRestCall_601373
proc url_GetPromoteReadReplica_603685(protocol: Scheme; host: string; base: string;
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

proc validate_GetPromoteReadReplica_603684(path: JsonNode; query: JsonNode;
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
  var valid_603686 = query.getOrDefault("DBInstanceIdentifier")
  valid_603686 = validateParameter(valid_603686, JString, required = true,
                                 default = nil)
  if valid_603686 != nil:
    section.add "DBInstanceIdentifier", valid_603686
  var valid_603687 = query.getOrDefault("BackupRetentionPeriod")
  valid_603687 = validateParameter(valid_603687, JInt, required = false, default = nil)
  if valid_603687 != nil:
    section.add "BackupRetentionPeriod", valid_603687
  var valid_603688 = query.getOrDefault("Action")
  valid_603688 = validateParameter(valid_603688, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_603688 != nil:
    section.add "Action", valid_603688
  var valid_603689 = query.getOrDefault("Version")
  valid_603689 = validateParameter(valid_603689, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603689 != nil:
    section.add "Version", valid_603689
  var valid_603690 = query.getOrDefault("PreferredBackupWindow")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "PreferredBackupWindow", valid_603690
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
  var valid_603691 = header.getOrDefault("X-Amz-Signature")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Signature", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Content-Sha256", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Date")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Date", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Credential")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Credential", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Security-Token")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Security-Token", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-Algorithm")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Algorithm", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-SignedHeaders", valid_603697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603698: Call_GetPromoteReadReplica_603683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603698.validator(path, query, header, formData, body)
  let scheme = call_603698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603698.url(scheme.get, call_603698.host, call_603698.base,
                         call_603698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603698, url, valid)

proc call*(call_603699: Call_GetPromoteReadReplica_603683;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-02-12";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_603700 = newJObject()
  add(query_603700, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603700, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603700, "Action", newJString(Action))
  add(query_603700, "Version", newJString(Version))
  add(query_603700, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_603699.call(nil, query_603700, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_603683(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_603684, base: "/",
    url: url_GetPromoteReadReplica_603685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_603738 = ref object of OpenApiRestCall_601373
proc url_PostPurchaseReservedDBInstancesOffering_603740(protocol: Scheme;
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

proc validate_PostPurchaseReservedDBInstancesOffering_603739(path: JsonNode;
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
  var valid_603741 = query.getOrDefault("Action")
  valid_603741 = validateParameter(valid_603741, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_603741 != nil:
    section.add "Action", valid_603741
  var valid_603742 = query.getOrDefault("Version")
  valid_603742 = validateParameter(valid_603742, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603742 != nil:
    section.add "Version", valid_603742
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
  var valid_603743 = header.getOrDefault("X-Amz-Signature")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Signature", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Content-Sha256", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Date")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Date", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Credential")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Credential", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-Security-Token")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Security-Token", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Algorithm")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Algorithm", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-SignedHeaders", valid_603749
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_603750 = formData.getOrDefault("ReservedDBInstanceId")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "ReservedDBInstanceId", valid_603750
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_603751 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603751 = validateParameter(valid_603751, JString, required = true,
                                 default = nil)
  if valid_603751 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603751
  var valid_603752 = formData.getOrDefault("DBInstanceCount")
  valid_603752 = validateParameter(valid_603752, JInt, required = false, default = nil)
  if valid_603752 != nil:
    section.add "DBInstanceCount", valid_603752
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603753: Call_PostPurchaseReservedDBInstancesOffering_603738;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603753.validator(path, query, header, formData, body)
  let scheme = call_603753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603753.url(scheme.get, call_603753.host, call_603753.base,
                         call_603753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603753, url, valid)

proc call*(call_603754: Call_PostPurchaseReservedDBInstancesOffering_603738;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-02-12"; DBInstanceCount: int = 0): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  var query_603755 = newJObject()
  var formData_603756 = newJObject()
  add(formData_603756, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603755, "Action", newJString(Action))
  add(formData_603756, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603755, "Version", newJString(Version))
  add(formData_603756, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_603754.call(nil, query_603755, nil, formData_603756, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_603738(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_603739, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_603740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_603720 = ref object of OpenApiRestCall_601373
proc url_GetPurchaseReservedDBInstancesOffering_603722(protocol: Scheme;
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

proc validate_GetPurchaseReservedDBInstancesOffering_603721(path: JsonNode;
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
  var valid_603723 = query.getOrDefault("DBInstanceCount")
  valid_603723 = validateParameter(valid_603723, JInt, required = false, default = nil)
  if valid_603723 != nil:
    section.add "DBInstanceCount", valid_603723
  var valid_603724 = query.getOrDefault("ReservedDBInstanceId")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "ReservedDBInstanceId", valid_603724
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603725 = query.getOrDefault("Action")
  valid_603725 = validateParameter(valid_603725, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_603725 != nil:
    section.add "Action", valid_603725
  var valid_603726 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603726 = validateParameter(valid_603726, JString, required = true,
                                 default = nil)
  if valid_603726 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603726
  var valid_603727 = query.getOrDefault("Version")
  valid_603727 = validateParameter(valid_603727, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603727 != nil:
    section.add "Version", valid_603727
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
  var valid_603728 = header.getOrDefault("X-Amz-Signature")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Signature", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Content-Sha256", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Date")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Date", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Credential")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Credential", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Security-Token")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Security-Token", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Algorithm")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Algorithm", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-SignedHeaders", valid_603734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603735: Call_GetPurchaseReservedDBInstancesOffering_603720;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603735.validator(path, query, header, formData, body)
  let scheme = call_603735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603735.url(scheme.get, call_603735.host, call_603735.base,
                         call_603735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603735, url, valid)

proc call*(call_603736: Call_GetPurchaseReservedDBInstancesOffering_603720;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-02-12"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_603737 = newJObject()
  add(query_603737, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_603737, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603737, "Action", newJString(Action))
  add(query_603737, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603737, "Version", newJString(Version))
  result = call_603736.call(nil, query_603737, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_603720(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_603721, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_603722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_603774 = ref object of OpenApiRestCall_601373
proc url_PostRebootDBInstance_603776(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_603775(path: JsonNode; query: JsonNode;
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
  var valid_603777 = query.getOrDefault("Action")
  valid_603777 = validateParameter(valid_603777, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_603777 != nil:
    section.add "Action", valid_603777
  var valid_603778 = query.getOrDefault("Version")
  valid_603778 = validateParameter(valid_603778, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603778 != nil:
    section.add "Version", valid_603778
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
  var valid_603779 = header.getOrDefault("X-Amz-Signature")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Signature", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Content-Sha256", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Date")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Date", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-Credential")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Credential", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Security-Token")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Security-Token", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Algorithm")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Algorithm", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-SignedHeaders", valid_603785
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603786 = formData.getOrDefault("ForceFailover")
  valid_603786 = validateParameter(valid_603786, JBool, required = false, default = nil)
  if valid_603786 != nil:
    section.add "ForceFailover", valid_603786
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603787 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603787 = validateParameter(valid_603787, JString, required = true,
                                 default = nil)
  if valid_603787 != nil:
    section.add "DBInstanceIdentifier", valid_603787
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603788: Call_PostRebootDBInstance_603774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603788.validator(path, query, header, formData, body)
  let scheme = call_603788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603788.url(scheme.get, call_603788.host, call_603788.base,
                         call_603788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603788, url, valid)

proc call*(call_603789: Call_PostRebootDBInstance_603774;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-02-12"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603790 = newJObject()
  var formData_603791 = newJObject()
  add(formData_603791, "ForceFailover", newJBool(ForceFailover))
  add(formData_603791, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603790, "Action", newJString(Action))
  add(query_603790, "Version", newJString(Version))
  result = call_603789.call(nil, query_603790, nil, formData_603791, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_603774(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_603775, base: "/",
    url: url_PostRebootDBInstance_603776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_603757 = ref object of OpenApiRestCall_601373
proc url_GetRebootDBInstance_603759(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_603758(path: JsonNode; query: JsonNode;
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
  var valid_603760 = query.getOrDefault("ForceFailover")
  valid_603760 = validateParameter(valid_603760, JBool, required = false, default = nil)
  if valid_603760 != nil:
    section.add "ForceFailover", valid_603760
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603761 = query.getOrDefault("DBInstanceIdentifier")
  valid_603761 = validateParameter(valid_603761, JString, required = true,
                                 default = nil)
  if valid_603761 != nil:
    section.add "DBInstanceIdentifier", valid_603761
  var valid_603762 = query.getOrDefault("Action")
  valid_603762 = validateParameter(valid_603762, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_603762 != nil:
    section.add "Action", valid_603762
  var valid_603763 = query.getOrDefault("Version")
  valid_603763 = validateParameter(valid_603763, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603763 != nil:
    section.add "Version", valid_603763
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
  var valid_603764 = header.getOrDefault("X-Amz-Signature")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Signature", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Content-Sha256", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Date")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Date", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Credential")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Credential", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Security-Token")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Security-Token", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Algorithm")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Algorithm", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-SignedHeaders", valid_603770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603771: Call_GetRebootDBInstance_603757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603771.validator(path, query, header, formData, body)
  let scheme = call_603771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603771.url(scheme.get, call_603771.host, call_603771.base,
                         call_603771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603771, url, valid)

proc call*(call_603772: Call_GetRebootDBInstance_603757;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-02-12"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603773 = newJObject()
  add(query_603773, "ForceFailover", newJBool(ForceFailover))
  add(query_603773, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603773, "Action", newJString(Action))
  add(query_603773, "Version", newJString(Version))
  result = call_603772.call(nil, query_603773, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_603757(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_603758, base: "/",
    url: url_GetRebootDBInstance_603759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_603809 = ref object of OpenApiRestCall_601373
proc url_PostRemoveSourceIdentifierFromSubscription_603811(protocol: Scheme;
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

proc validate_PostRemoveSourceIdentifierFromSubscription_603810(path: JsonNode;
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
  var valid_603812 = query.getOrDefault("Action")
  valid_603812 = validateParameter(valid_603812, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_603812 != nil:
    section.add "Action", valid_603812
  var valid_603813 = query.getOrDefault("Version")
  valid_603813 = validateParameter(valid_603813, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603813 != nil:
    section.add "Version", valid_603813
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
  var valid_603814 = header.getOrDefault("X-Amz-Signature")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Signature", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Content-Sha256", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Date")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Date", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Credential")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Credential", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-Security-Token")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Security-Token", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-Algorithm")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Algorithm", valid_603819
  var valid_603820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-SignedHeaders", valid_603820
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603821 = formData.getOrDefault("SubscriptionName")
  valid_603821 = validateParameter(valid_603821, JString, required = true,
                                 default = nil)
  if valid_603821 != nil:
    section.add "SubscriptionName", valid_603821
  var valid_603822 = formData.getOrDefault("SourceIdentifier")
  valid_603822 = validateParameter(valid_603822, JString, required = true,
                                 default = nil)
  if valid_603822 != nil:
    section.add "SourceIdentifier", valid_603822
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603823: Call_PostRemoveSourceIdentifierFromSubscription_603809;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603823.validator(path, query, header, formData, body)
  let scheme = call_603823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603823.url(scheme.get, call_603823.host, call_603823.base,
                         call_603823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603823, url, valid)

proc call*(call_603824: Call_PostRemoveSourceIdentifierFromSubscription_603809;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603825 = newJObject()
  var formData_603826 = newJObject()
  add(formData_603826, "SubscriptionName", newJString(SubscriptionName))
  add(formData_603826, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_603825, "Action", newJString(Action))
  add(query_603825, "Version", newJString(Version))
  result = call_603824.call(nil, query_603825, nil, formData_603826, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_603809(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_603810,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_603811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_603792 = ref object of OpenApiRestCall_601373
proc url_GetRemoveSourceIdentifierFromSubscription_603794(protocol: Scheme;
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

proc validate_GetRemoveSourceIdentifierFromSubscription_603793(path: JsonNode;
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
  var valid_603795 = query.getOrDefault("SourceIdentifier")
  valid_603795 = validateParameter(valid_603795, JString, required = true,
                                 default = nil)
  if valid_603795 != nil:
    section.add "SourceIdentifier", valid_603795
  var valid_603796 = query.getOrDefault("SubscriptionName")
  valid_603796 = validateParameter(valid_603796, JString, required = true,
                                 default = nil)
  if valid_603796 != nil:
    section.add "SubscriptionName", valid_603796
  var valid_603797 = query.getOrDefault("Action")
  valid_603797 = validateParameter(valid_603797, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_603797 != nil:
    section.add "Action", valid_603797
  var valid_603798 = query.getOrDefault("Version")
  valid_603798 = validateParameter(valid_603798, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603798 != nil:
    section.add "Version", valid_603798
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
  var valid_603799 = header.getOrDefault("X-Amz-Signature")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Signature", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Content-Sha256", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Date")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Date", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Credential")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Credential", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Security-Token")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Security-Token", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Algorithm")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Algorithm", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-SignedHeaders", valid_603805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603806: Call_GetRemoveSourceIdentifierFromSubscription_603792;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603806.validator(path, query, header, formData, body)
  let scheme = call_603806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603806.url(scheme.get, call_603806.host, call_603806.base,
                         call_603806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603806, url, valid)

proc call*(call_603807: Call_GetRemoveSourceIdentifierFromSubscription_603792;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603808 = newJObject()
  add(query_603808, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_603808, "SubscriptionName", newJString(SubscriptionName))
  add(query_603808, "Action", newJString(Action))
  add(query_603808, "Version", newJString(Version))
  result = call_603807.call(nil, query_603808, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_603792(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_603793,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_603794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_603844 = ref object of OpenApiRestCall_601373
proc url_PostRemoveTagsFromResource_603846(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_603845(path: JsonNode; query: JsonNode;
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
  var valid_603847 = query.getOrDefault("Action")
  valid_603847 = validateParameter(valid_603847, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603847 != nil:
    section.add "Action", valid_603847
  var valid_603848 = query.getOrDefault("Version")
  valid_603848 = validateParameter(valid_603848, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603848 != nil:
    section.add "Version", valid_603848
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
  var valid_603849 = header.getOrDefault("X-Amz-Signature")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Signature", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Content-Sha256", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-Date")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Date", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Credential")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Credential", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Security-Token")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Security-Token", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Algorithm")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Algorithm", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-SignedHeaders", valid_603855
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_603856 = formData.getOrDefault("TagKeys")
  valid_603856 = validateParameter(valid_603856, JArray, required = true, default = nil)
  if valid_603856 != nil:
    section.add "TagKeys", valid_603856
  var valid_603857 = formData.getOrDefault("ResourceName")
  valid_603857 = validateParameter(valid_603857, JString, required = true,
                                 default = nil)
  if valid_603857 != nil:
    section.add "ResourceName", valid_603857
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603858: Call_PostRemoveTagsFromResource_603844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603858.validator(path, query, header, formData, body)
  let scheme = call_603858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603858.url(scheme.get, call_603858.host, call_603858.base,
                         call_603858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603858, url, valid)

proc call*(call_603859: Call_PostRemoveTagsFromResource_603844; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_603860 = newJObject()
  var formData_603861 = newJObject()
  if TagKeys != nil:
    formData_603861.add "TagKeys", TagKeys
  add(query_603860, "Action", newJString(Action))
  add(query_603860, "Version", newJString(Version))
  add(formData_603861, "ResourceName", newJString(ResourceName))
  result = call_603859.call(nil, query_603860, nil, formData_603861, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_603844(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_603845, base: "/",
    url: url_PostRemoveTagsFromResource_603846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_603827 = ref object of OpenApiRestCall_601373
proc url_GetRemoveTagsFromResource_603829(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_603828(path: JsonNode; query: JsonNode;
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
  var valid_603830 = query.getOrDefault("ResourceName")
  valid_603830 = validateParameter(valid_603830, JString, required = true,
                                 default = nil)
  if valid_603830 != nil:
    section.add "ResourceName", valid_603830
  var valid_603831 = query.getOrDefault("TagKeys")
  valid_603831 = validateParameter(valid_603831, JArray, required = true, default = nil)
  if valid_603831 != nil:
    section.add "TagKeys", valid_603831
  var valid_603832 = query.getOrDefault("Action")
  valid_603832 = validateParameter(valid_603832, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603832 != nil:
    section.add "Action", valid_603832
  var valid_603833 = query.getOrDefault("Version")
  valid_603833 = validateParameter(valid_603833, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603833 != nil:
    section.add "Version", valid_603833
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
  var valid_603834 = header.getOrDefault("X-Amz-Signature")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Signature", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Content-Sha256", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Date")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Date", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Credential")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Credential", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Security-Token")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Security-Token", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Algorithm")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Algorithm", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-SignedHeaders", valid_603840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603841: Call_GetRemoveTagsFromResource_603827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603841.validator(path, query, header, formData, body)
  let scheme = call_603841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603841.url(scheme.get, call_603841.host, call_603841.base,
                         call_603841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603841, url, valid)

proc call*(call_603842: Call_GetRemoveTagsFromResource_603827;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-02-12"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603843 = newJObject()
  add(query_603843, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_603843.add "TagKeys", TagKeys
  add(query_603843, "Action", newJString(Action))
  add(query_603843, "Version", newJString(Version))
  result = call_603842.call(nil, query_603843, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_603827(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_603828, base: "/",
    url: url_GetRemoveTagsFromResource_603829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_603880 = ref object of OpenApiRestCall_601373
proc url_PostResetDBParameterGroup_603882(protocol: Scheme; host: string;
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

proc validate_PostResetDBParameterGroup_603881(path: JsonNode; query: JsonNode;
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
  var valid_603883 = query.getOrDefault("Action")
  valid_603883 = validateParameter(valid_603883, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_603883 != nil:
    section.add "Action", valid_603883
  var valid_603884 = query.getOrDefault("Version")
  valid_603884 = validateParameter(valid_603884, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603884 != nil:
    section.add "Version", valid_603884
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
  var valid_603885 = header.getOrDefault("X-Amz-Signature")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Signature", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Content-Sha256", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Date")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Date", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Credential")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Credential", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Security-Token")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Security-Token", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-Algorithm")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-Algorithm", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-SignedHeaders", valid_603891
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_603892 = formData.getOrDefault("ResetAllParameters")
  valid_603892 = validateParameter(valid_603892, JBool, required = false, default = nil)
  if valid_603892 != nil:
    section.add "ResetAllParameters", valid_603892
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603893 = formData.getOrDefault("DBParameterGroupName")
  valid_603893 = validateParameter(valid_603893, JString, required = true,
                                 default = nil)
  if valid_603893 != nil:
    section.add "DBParameterGroupName", valid_603893
  var valid_603894 = formData.getOrDefault("Parameters")
  valid_603894 = validateParameter(valid_603894, JArray, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "Parameters", valid_603894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603895: Call_PostResetDBParameterGroup_603880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603895.validator(path, query, header, formData, body)
  let scheme = call_603895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603895.url(scheme.get, call_603895.host, call_603895.base,
                         call_603895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603895, url, valid)

proc call*(call_603896: Call_PostResetDBParameterGroup_603880;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-02-12"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_603897 = newJObject()
  var formData_603898 = newJObject()
  add(formData_603898, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_603898, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603897, "Action", newJString(Action))
  if Parameters != nil:
    formData_603898.add "Parameters", Parameters
  add(query_603897, "Version", newJString(Version))
  result = call_603896.call(nil, query_603897, nil, formData_603898, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_603880(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_603881, base: "/",
    url: url_PostResetDBParameterGroup_603882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_603862 = ref object of OpenApiRestCall_601373
proc url_GetResetDBParameterGroup_603864(protocol: Scheme; host: string;
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

proc validate_GetResetDBParameterGroup_603863(path: JsonNode; query: JsonNode;
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
  var valid_603865 = query.getOrDefault("DBParameterGroupName")
  valid_603865 = validateParameter(valid_603865, JString, required = true,
                                 default = nil)
  if valid_603865 != nil:
    section.add "DBParameterGroupName", valid_603865
  var valid_603866 = query.getOrDefault("Parameters")
  valid_603866 = validateParameter(valid_603866, JArray, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "Parameters", valid_603866
  var valid_603867 = query.getOrDefault("ResetAllParameters")
  valid_603867 = validateParameter(valid_603867, JBool, required = false, default = nil)
  if valid_603867 != nil:
    section.add "ResetAllParameters", valid_603867
  var valid_603868 = query.getOrDefault("Action")
  valid_603868 = validateParameter(valid_603868, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_603868 != nil:
    section.add "Action", valid_603868
  var valid_603869 = query.getOrDefault("Version")
  valid_603869 = validateParameter(valid_603869, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603869 != nil:
    section.add "Version", valid_603869
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
  var valid_603870 = header.getOrDefault("X-Amz-Signature")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Signature", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Content-Sha256", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Date")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Date", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Credential")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Credential", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Security-Token")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Security-Token", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Algorithm")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Algorithm", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-SignedHeaders", valid_603876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603877: Call_GetResetDBParameterGroup_603862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603877.validator(path, query, header, formData, body)
  let scheme = call_603877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603877.url(scheme.get, call_603877.host, call_603877.base,
                         call_603877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603877, url, valid)

proc call*(call_603878: Call_GetResetDBParameterGroup_603862;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603879 = newJObject()
  add(query_603879, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_603879.add "Parameters", Parameters
  add(query_603879, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_603879, "Action", newJString(Action))
  add(query_603879, "Version", newJString(Version))
  result = call_603878.call(nil, query_603879, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_603862(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_603863, base: "/",
    url: url_GetResetDBParameterGroup_603864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_603928 = ref object of OpenApiRestCall_601373
proc url_PostRestoreDBInstanceFromDBSnapshot_603930(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceFromDBSnapshot_603929(path: JsonNode;
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
  var valid_603931 = query.getOrDefault("Action")
  valid_603931 = validateParameter(valid_603931, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603931 != nil:
    section.add "Action", valid_603931
  var valid_603932 = query.getOrDefault("Version")
  valid_603932 = validateParameter(valid_603932, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603932 != nil:
    section.add "Version", valid_603932
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
  var valid_603933 = header.getOrDefault("X-Amz-Signature")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "X-Amz-Signature", valid_603933
  var valid_603934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Content-Sha256", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-Date")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Date", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-Credential")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Credential", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Security-Token")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Security-Token", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Algorithm")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Algorithm", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-SignedHeaders", valid_603939
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
  var valid_603940 = formData.getOrDefault("Port")
  valid_603940 = validateParameter(valid_603940, JInt, required = false, default = nil)
  if valid_603940 != nil:
    section.add "Port", valid_603940
  var valid_603941 = formData.getOrDefault("DBInstanceClass")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "DBInstanceClass", valid_603941
  var valid_603942 = formData.getOrDefault("MultiAZ")
  valid_603942 = validateParameter(valid_603942, JBool, required = false, default = nil)
  if valid_603942 != nil:
    section.add "MultiAZ", valid_603942
  var valid_603943 = formData.getOrDefault("AvailabilityZone")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "AvailabilityZone", valid_603943
  var valid_603944 = formData.getOrDefault("Engine")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "Engine", valid_603944
  var valid_603945 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603945 = validateParameter(valid_603945, JBool, required = false, default = nil)
  if valid_603945 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603945
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603946 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603946 = validateParameter(valid_603946, JString, required = true,
                                 default = nil)
  if valid_603946 != nil:
    section.add "DBInstanceIdentifier", valid_603946
  var valid_603947 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603947 = validateParameter(valid_603947, JString, required = true,
                                 default = nil)
  if valid_603947 != nil:
    section.add "DBSnapshotIdentifier", valid_603947
  var valid_603948 = formData.getOrDefault("DBName")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "DBName", valid_603948
  var valid_603949 = formData.getOrDefault("Iops")
  valid_603949 = validateParameter(valid_603949, JInt, required = false, default = nil)
  if valid_603949 != nil:
    section.add "Iops", valid_603949
  var valid_603950 = formData.getOrDefault("PubliclyAccessible")
  valid_603950 = validateParameter(valid_603950, JBool, required = false, default = nil)
  if valid_603950 != nil:
    section.add "PubliclyAccessible", valid_603950
  var valid_603951 = formData.getOrDefault("LicenseModel")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "LicenseModel", valid_603951
  var valid_603952 = formData.getOrDefault("DBSubnetGroupName")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "DBSubnetGroupName", valid_603952
  var valid_603953 = formData.getOrDefault("OptionGroupName")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "OptionGroupName", valid_603953
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603954: Call_PostRestoreDBInstanceFromDBSnapshot_603928;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603954.validator(path, query, header, formData, body)
  let scheme = call_603954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603954.url(scheme.get, call_603954.host, call_603954.base,
                         call_603954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603954, url, valid)

proc call*(call_603955: Call_PostRestoreDBInstanceFromDBSnapshot_603928;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          LicenseModel: string = ""; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
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
  var query_603956 = newJObject()
  var formData_603957 = newJObject()
  add(formData_603957, "Port", newJInt(Port))
  add(formData_603957, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603957, "MultiAZ", newJBool(MultiAZ))
  add(formData_603957, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603957, "Engine", newJString(Engine))
  add(formData_603957, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603957, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603957, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_603957, "DBName", newJString(DBName))
  add(formData_603957, "Iops", newJInt(Iops))
  add(formData_603957, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603956, "Action", newJString(Action))
  add(formData_603957, "LicenseModel", newJString(LicenseModel))
  add(formData_603957, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603957, "OptionGroupName", newJString(OptionGroupName))
  add(query_603956, "Version", newJString(Version))
  result = call_603955.call(nil, query_603956, nil, formData_603957, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_603928(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_603929, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_603930,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_603899 = ref object of OpenApiRestCall_601373
proc url_GetRestoreDBInstanceFromDBSnapshot_603901(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceFromDBSnapshot_603900(path: JsonNode;
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
  var valid_603902 = query.getOrDefault("DBName")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "DBName", valid_603902
  var valid_603903 = query.getOrDefault("Engine")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "Engine", valid_603903
  var valid_603904 = query.getOrDefault("LicenseModel")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "LicenseModel", valid_603904
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603905 = query.getOrDefault("DBInstanceIdentifier")
  valid_603905 = validateParameter(valid_603905, JString, required = true,
                                 default = nil)
  if valid_603905 != nil:
    section.add "DBInstanceIdentifier", valid_603905
  var valid_603906 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603906 = validateParameter(valid_603906, JString, required = true,
                                 default = nil)
  if valid_603906 != nil:
    section.add "DBSnapshotIdentifier", valid_603906
  var valid_603907 = query.getOrDefault("Action")
  valid_603907 = validateParameter(valid_603907, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603907 != nil:
    section.add "Action", valid_603907
  var valid_603908 = query.getOrDefault("MultiAZ")
  valid_603908 = validateParameter(valid_603908, JBool, required = false, default = nil)
  if valid_603908 != nil:
    section.add "MultiAZ", valid_603908
  var valid_603909 = query.getOrDefault("Port")
  valid_603909 = validateParameter(valid_603909, JInt, required = false, default = nil)
  if valid_603909 != nil:
    section.add "Port", valid_603909
  var valid_603910 = query.getOrDefault("AvailabilityZone")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "AvailabilityZone", valid_603910
  var valid_603911 = query.getOrDefault("OptionGroupName")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "OptionGroupName", valid_603911
  var valid_603912 = query.getOrDefault("DBSubnetGroupName")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "DBSubnetGroupName", valid_603912
  var valid_603913 = query.getOrDefault("Version")
  valid_603913 = validateParameter(valid_603913, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603913 != nil:
    section.add "Version", valid_603913
  var valid_603914 = query.getOrDefault("DBInstanceClass")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "DBInstanceClass", valid_603914
  var valid_603915 = query.getOrDefault("PubliclyAccessible")
  valid_603915 = validateParameter(valid_603915, JBool, required = false, default = nil)
  if valid_603915 != nil:
    section.add "PubliclyAccessible", valid_603915
  var valid_603916 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603916 = validateParameter(valid_603916, JBool, required = false, default = nil)
  if valid_603916 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603916
  var valid_603917 = query.getOrDefault("Iops")
  valid_603917 = validateParameter(valid_603917, JInt, required = false, default = nil)
  if valid_603917 != nil:
    section.add "Iops", valid_603917
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
  var valid_603918 = header.getOrDefault("X-Amz-Signature")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Signature", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Content-Sha256", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Date")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Date", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Credential")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Credential", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Security-Token")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Security-Token", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Algorithm")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Algorithm", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-SignedHeaders", valid_603924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603925: Call_GetRestoreDBInstanceFromDBSnapshot_603899;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603925.validator(path, query, header, formData, body)
  let scheme = call_603925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603925.url(scheme.get, call_603925.host, call_603925.base,
                         call_603925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603925, url, valid)

proc call*(call_603926: Call_GetRestoreDBInstanceFromDBSnapshot_603899;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          DBName: string = ""; Engine: string = ""; LicenseModel: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-02-12";
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
  var query_603927 = newJObject()
  add(query_603927, "DBName", newJString(DBName))
  add(query_603927, "Engine", newJString(Engine))
  add(query_603927, "LicenseModel", newJString(LicenseModel))
  add(query_603927, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603927, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603927, "Action", newJString(Action))
  add(query_603927, "MultiAZ", newJBool(MultiAZ))
  add(query_603927, "Port", newJInt(Port))
  add(query_603927, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603927, "OptionGroupName", newJString(OptionGroupName))
  add(query_603927, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603927, "Version", newJString(Version))
  add(query_603927, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603927, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603927, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603927, "Iops", newJInt(Iops))
  result = call_603926.call(nil, query_603927, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_603899(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_603900, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_603901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_603989 = ref object of OpenApiRestCall_601373
proc url_PostRestoreDBInstanceToPointInTime_603991(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceToPointInTime_603990(path: JsonNode;
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
  var valid_603992 = query.getOrDefault("Action")
  valid_603992 = validateParameter(valid_603992, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603992 != nil:
    section.add "Action", valid_603992
  var valid_603993 = query.getOrDefault("Version")
  valid_603993 = validateParameter(valid_603993, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603993 != nil:
    section.add "Version", valid_603993
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
  var valid_603994 = header.getOrDefault("X-Amz-Signature")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Signature", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-Content-Sha256", valid_603995
  var valid_603996 = header.getOrDefault("X-Amz-Date")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-Date", valid_603996
  var valid_603997 = header.getOrDefault("X-Amz-Credential")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-Credential", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-Security-Token")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Security-Token", valid_603998
  var valid_603999 = header.getOrDefault("X-Amz-Algorithm")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "X-Amz-Algorithm", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-SignedHeaders", valid_604000
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
  var valid_604001 = formData.getOrDefault("Port")
  valid_604001 = validateParameter(valid_604001, JInt, required = false, default = nil)
  if valid_604001 != nil:
    section.add "Port", valid_604001
  var valid_604002 = formData.getOrDefault("DBInstanceClass")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "DBInstanceClass", valid_604002
  var valid_604003 = formData.getOrDefault("MultiAZ")
  valid_604003 = validateParameter(valid_604003, JBool, required = false, default = nil)
  if valid_604003 != nil:
    section.add "MultiAZ", valid_604003
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_604004 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_604004 = validateParameter(valid_604004, JString, required = true,
                                 default = nil)
  if valid_604004 != nil:
    section.add "SourceDBInstanceIdentifier", valid_604004
  var valid_604005 = formData.getOrDefault("AvailabilityZone")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "AvailabilityZone", valid_604005
  var valid_604006 = formData.getOrDefault("Engine")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "Engine", valid_604006
  var valid_604007 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604007 = validateParameter(valid_604007, JBool, required = false, default = nil)
  if valid_604007 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604007
  var valid_604008 = formData.getOrDefault("UseLatestRestorableTime")
  valid_604008 = validateParameter(valid_604008, JBool, required = false, default = nil)
  if valid_604008 != nil:
    section.add "UseLatestRestorableTime", valid_604008
  var valid_604009 = formData.getOrDefault("DBName")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "DBName", valid_604009
  var valid_604010 = formData.getOrDefault("Iops")
  valid_604010 = validateParameter(valid_604010, JInt, required = false, default = nil)
  if valid_604010 != nil:
    section.add "Iops", valid_604010
  var valid_604011 = formData.getOrDefault("PubliclyAccessible")
  valid_604011 = validateParameter(valid_604011, JBool, required = false, default = nil)
  if valid_604011 != nil:
    section.add "PubliclyAccessible", valid_604011
  var valid_604012 = formData.getOrDefault("LicenseModel")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "LicenseModel", valid_604012
  var valid_604013 = formData.getOrDefault("DBSubnetGroupName")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "DBSubnetGroupName", valid_604013
  var valid_604014 = formData.getOrDefault("OptionGroupName")
  valid_604014 = validateParameter(valid_604014, JString, required = false,
                                 default = nil)
  if valid_604014 != nil:
    section.add "OptionGroupName", valid_604014
  var valid_604015 = formData.getOrDefault("RestoreTime")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "RestoreTime", valid_604015
  var valid_604016 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_604016 = validateParameter(valid_604016, JString, required = true,
                                 default = nil)
  if valid_604016 != nil:
    section.add "TargetDBInstanceIdentifier", valid_604016
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604017: Call_PostRestoreDBInstanceToPointInTime_603989;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604017.validator(path, query, header, formData, body)
  let scheme = call_604017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604017.url(scheme.get, call_604017.host, call_604017.base,
                         call_604017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604017, url, valid)

proc call*(call_604018: Call_PostRestoreDBInstanceToPointInTime_603989;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false;
          UseLatestRestorableTime: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          LicenseModel: string = ""; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; RestoreTime: string = "";
          Version: string = "2013-02-12"): Recallable =
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
  var query_604019 = newJObject()
  var formData_604020 = newJObject()
  add(formData_604020, "Port", newJInt(Port))
  add(formData_604020, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604020, "MultiAZ", newJBool(MultiAZ))
  add(formData_604020, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_604020, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_604020, "Engine", newJString(Engine))
  add(formData_604020, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604020, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_604020, "DBName", newJString(DBName))
  add(formData_604020, "Iops", newJInt(Iops))
  add(formData_604020, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_604019, "Action", newJString(Action))
  add(formData_604020, "LicenseModel", newJString(LicenseModel))
  add(formData_604020, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604020, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604020, "RestoreTime", newJString(RestoreTime))
  add(formData_604020, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_604019, "Version", newJString(Version))
  result = call_604018.call(nil, query_604019, nil, formData_604020, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_603989(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_603990, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_603991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_603958 = ref object of OpenApiRestCall_601373
proc url_GetRestoreDBInstanceToPointInTime_603960(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceToPointInTime_603959(path: JsonNode;
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
  var valid_603961 = query.getOrDefault("DBName")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "DBName", valid_603961
  var valid_603962 = query.getOrDefault("Engine")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "Engine", valid_603962
  var valid_603963 = query.getOrDefault("UseLatestRestorableTime")
  valid_603963 = validateParameter(valid_603963, JBool, required = false, default = nil)
  if valid_603963 != nil:
    section.add "UseLatestRestorableTime", valid_603963
  var valid_603964 = query.getOrDefault("LicenseModel")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "LicenseModel", valid_603964
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_603965 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_603965 = validateParameter(valid_603965, JString, required = true,
                                 default = nil)
  if valid_603965 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603965
  var valid_603966 = query.getOrDefault("Action")
  valid_603966 = validateParameter(valid_603966, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603966 != nil:
    section.add "Action", valid_603966
  var valid_603967 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603967 = validateParameter(valid_603967, JString, required = true,
                                 default = nil)
  if valid_603967 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603967
  var valid_603968 = query.getOrDefault("MultiAZ")
  valid_603968 = validateParameter(valid_603968, JBool, required = false, default = nil)
  if valid_603968 != nil:
    section.add "MultiAZ", valid_603968
  var valid_603969 = query.getOrDefault("Port")
  valid_603969 = validateParameter(valid_603969, JInt, required = false, default = nil)
  if valid_603969 != nil:
    section.add "Port", valid_603969
  var valid_603970 = query.getOrDefault("AvailabilityZone")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "AvailabilityZone", valid_603970
  var valid_603971 = query.getOrDefault("OptionGroupName")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "OptionGroupName", valid_603971
  var valid_603972 = query.getOrDefault("DBSubnetGroupName")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "DBSubnetGroupName", valid_603972
  var valid_603973 = query.getOrDefault("RestoreTime")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "RestoreTime", valid_603973
  var valid_603974 = query.getOrDefault("DBInstanceClass")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "DBInstanceClass", valid_603974
  var valid_603975 = query.getOrDefault("PubliclyAccessible")
  valid_603975 = validateParameter(valid_603975, JBool, required = false, default = nil)
  if valid_603975 != nil:
    section.add "PubliclyAccessible", valid_603975
  var valid_603976 = query.getOrDefault("Version")
  valid_603976 = validateParameter(valid_603976, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603976 != nil:
    section.add "Version", valid_603976
  var valid_603977 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603977 = validateParameter(valid_603977, JBool, required = false, default = nil)
  if valid_603977 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603977
  var valid_603978 = query.getOrDefault("Iops")
  valid_603978 = validateParameter(valid_603978, JInt, required = false, default = nil)
  if valid_603978 != nil:
    section.add "Iops", valid_603978
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
  var valid_603979 = header.getOrDefault("X-Amz-Signature")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "X-Amz-Signature", valid_603979
  var valid_603980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "X-Amz-Content-Sha256", valid_603980
  var valid_603981 = header.getOrDefault("X-Amz-Date")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "X-Amz-Date", valid_603981
  var valid_603982 = header.getOrDefault("X-Amz-Credential")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-Credential", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-Security-Token")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Security-Token", valid_603983
  var valid_603984 = header.getOrDefault("X-Amz-Algorithm")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Algorithm", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-SignedHeaders", valid_603985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603986: Call_GetRestoreDBInstanceToPointInTime_603958;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603986.validator(path, query, header, formData, body)
  let scheme = call_603986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603986.url(scheme.get, call_603986.host, call_603986.base,
                         call_603986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603986, url, valid)

proc call*(call_603987: Call_GetRestoreDBInstanceToPointInTime_603958;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          DBName: string = ""; Engine: string = "";
          UseLatestRestorableTime: bool = false; LicenseModel: string = "";
          Action: string = "RestoreDBInstanceToPointInTime"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; RestoreTime: string = "";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          Version: string = "2013-02-12"; AutoMinorVersionUpgrade: bool = false;
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
  var query_603988 = newJObject()
  add(query_603988, "DBName", newJString(DBName))
  add(query_603988, "Engine", newJString(Engine))
  add(query_603988, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_603988, "LicenseModel", newJString(LicenseModel))
  add(query_603988, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_603988, "Action", newJString(Action))
  add(query_603988, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603988, "MultiAZ", newJBool(MultiAZ))
  add(query_603988, "Port", newJInt(Port))
  add(query_603988, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603988, "OptionGroupName", newJString(OptionGroupName))
  add(query_603988, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603988, "RestoreTime", newJString(RestoreTime))
  add(query_603988, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603988, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603988, "Version", newJString(Version))
  add(query_603988, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603988, "Iops", newJInt(Iops))
  result = call_603987.call(nil, query_603988, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_603958(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_603959, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_603960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_604041 = ref object of OpenApiRestCall_601373
proc url_PostRevokeDBSecurityGroupIngress_604043(protocol: Scheme; host: string;
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

proc validate_PostRevokeDBSecurityGroupIngress_604042(path: JsonNode;
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
  var valid_604044 = query.getOrDefault("Action")
  valid_604044 = validateParameter(valid_604044, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_604044 != nil:
    section.add "Action", valid_604044
  var valid_604045 = query.getOrDefault("Version")
  valid_604045 = validateParameter(valid_604045, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604045 != nil:
    section.add "Version", valid_604045
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
  var valid_604046 = header.getOrDefault("X-Amz-Signature")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Signature", valid_604046
  var valid_604047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "X-Amz-Content-Sha256", valid_604047
  var valid_604048 = header.getOrDefault("X-Amz-Date")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "X-Amz-Date", valid_604048
  var valid_604049 = header.getOrDefault("X-Amz-Credential")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-Credential", valid_604049
  var valid_604050 = header.getOrDefault("X-Amz-Security-Token")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Security-Token", valid_604050
  var valid_604051 = header.getOrDefault("X-Amz-Algorithm")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-Algorithm", valid_604051
  var valid_604052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "X-Amz-SignedHeaders", valid_604052
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_604053 = formData.getOrDefault("DBSecurityGroupName")
  valid_604053 = validateParameter(valid_604053, JString, required = true,
                                 default = nil)
  if valid_604053 != nil:
    section.add "DBSecurityGroupName", valid_604053
  var valid_604054 = formData.getOrDefault("EC2SecurityGroupName")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "EC2SecurityGroupName", valid_604054
  var valid_604055 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_604055
  var valid_604056 = formData.getOrDefault("EC2SecurityGroupId")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "EC2SecurityGroupId", valid_604056
  var valid_604057 = formData.getOrDefault("CIDRIP")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "CIDRIP", valid_604057
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604058: Call_PostRevokeDBSecurityGroupIngress_604041;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604058.validator(path, query, header, formData, body)
  let scheme = call_604058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604058.url(scheme.get, call_604058.host, call_604058.base,
                         call_604058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604058, url, valid)

proc call*(call_604059: Call_PostRevokeDBSecurityGroupIngress_604041;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-02-12"): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604060 = newJObject()
  var formData_604061 = newJObject()
  add(formData_604061, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_604061, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_604061, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_604061, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_604061, "CIDRIP", newJString(CIDRIP))
  add(query_604060, "Action", newJString(Action))
  add(query_604060, "Version", newJString(Version))
  result = call_604059.call(nil, query_604060, nil, formData_604061, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_604041(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_604042, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_604043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_604021 = ref object of OpenApiRestCall_601373
proc url_GetRevokeDBSecurityGroupIngress_604023(protocol: Scheme; host: string;
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

proc validate_GetRevokeDBSecurityGroupIngress_604022(path: JsonNode;
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
  var valid_604024 = query.getOrDefault("EC2SecurityGroupName")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "EC2SecurityGroupName", valid_604024
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_604025 = query.getOrDefault("DBSecurityGroupName")
  valid_604025 = validateParameter(valid_604025, JString, required = true,
                                 default = nil)
  if valid_604025 != nil:
    section.add "DBSecurityGroupName", valid_604025
  var valid_604026 = query.getOrDefault("EC2SecurityGroupId")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "EC2SecurityGroupId", valid_604026
  var valid_604027 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_604027
  var valid_604028 = query.getOrDefault("Action")
  valid_604028 = validateParameter(valid_604028, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_604028 != nil:
    section.add "Action", valid_604028
  var valid_604029 = query.getOrDefault("Version")
  valid_604029 = validateParameter(valid_604029, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604029 != nil:
    section.add "Version", valid_604029
  var valid_604030 = query.getOrDefault("CIDRIP")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "CIDRIP", valid_604030
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
  var valid_604031 = header.getOrDefault("X-Amz-Signature")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Signature", valid_604031
  var valid_604032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "X-Amz-Content-Sha256", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-Date")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Date", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-Credential")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Credential", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-Security-Token")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Security-Token", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-Algorithm")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Algorithm", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-SignedHeaders", valid_604037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604038: Call_GetRevokeDBSecurityGroupIngress_604021;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604038.validator(path, query, header, formData, body)
  let scheme = call_604038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604038.url(scheme.get, call_604038.host, call_604038.base,
                         call_604038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604038, url, valid)

proc call*(call_604039: Call_GetRevokeDBSecurityGroupIngress_604021;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-02-12"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_604040 = newJObject()
  add(query_604040, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_604040, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_604040, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_604040, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_604040, "Action", newJString(Action))
  add(query_604040, "Version", newJString(Version))
  add(query_604040, "CIDRIP", newJString(CIDRIP))
  result = call_604039.call(nil, query_604040, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_604021(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_604022, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_604023,
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
